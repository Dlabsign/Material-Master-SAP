*----------------------------------------------------------------------*
* Event Handler : OnInputProcessing (Staging Process & Binding Engine)
*----------------------------------------------------------------------*
DATA: event              TYPE string,
      lv_upload_id       TYPE zbom_stg_part-upload_id,
      lv_mtart           TYPE mtart,
      lv_matkl           TYPE matkl,
      lv_werks           TYPE werks_d,
      lv_prefix          TYPE string,
      lv_candidate_matnr TYPE matnr,
      lv_json_resp       TYPE string,
      lt_detail          TYPE TABLE OF zbom_stg_part.

event = event_id.

CASE event.

  " -------------------------------------------------------------------
  " 1. GET HISTORY BATCH UPLOAD
  " -------------------------------------------------------------------
  WHEN 'GET_HISTORY'.
    TYPES: BEGIN OF ty_history,
             upload_id TYPE zbom_stg_part-upload_id,
             filename  TYPE zbom_stg_part-filename,
             erdat     TYPE zbom_stg_part-erdat,
             ertim     TYPE zbom_stg_part-ertim,
             ernam     TYPE zbom_stg_part-ernam,
             status    TYPE zbom_stg_part-status,
             total_row TYPE i,
           END OF ty_history.

    DATA: lt_history  TYPE TABLE OF ty_history,
          lv_json_his TYPE string.

    SELECT upload_id, filename, erdat, ertim, ernam, status, COUNT( * ) AS total_row
      FROM zbom_stg_part
      WHERE upload_id IS NOT INITIAL AND upload_id <> ''
      GROUP BY upload_id, filename, erdat, ertim, ernam, status
      ORDER BY erdat DESCENDING, ertim DESCENDING
      INTO TABLE @lt_history.

    _m_response->set_header_field( name = 'Content-Type' value = 'application/json' ).
    /ui2/cl_json=>serialize(
      EXPORTING data = lt_history pretty_name = /ui2/cl_json=>pretty_mode-low_case
      RECEIVING r_json = lv_json_his ).

    _m_response->set_cdata( lv_json_his ).
    navigation->response_complete( ).

  " -------------------------------------------------------------------
  " 2. GET DETAIL STAGING DARI ZBOM_STG_PART
  " -------------------------------------------------------------------
  WHEN 'GET_UPLOAD_DETAIL'.
    lv_upload_id = request->get_form_field( 'UPLOAD_ID' ).

    IF lv_upload_id IS NOT INITIAL.
      SELECT * FROM zbom_stg_part
        WHERE upload_id = @lv_upload_id
        ORDER BY posnr ASCENDING
        INTO TABLE @lt_detail.
    ENDIF.

    _m_response->set_header_field( name = 'Content-Type' value = 'application/json' ).
    /ui2/cl_json=>serialize(
      EXPORTING data = lt_detail pretty_name = /ui2/cl_json=>pretty_mode-low_case
      RECEIVING r_json = lv_json_resp ).

    _m_response->set_cdata( lv_json_resp ).
    navigation->response_complete( ).

  " -------------------------------------------------------------------
  " 3. GENERATE KODE MATERIAL (PURE GAP-FILLING & SEQUENTIAL +1 - FIXED)
  " -------------------------------------------------------------------
  WHEN 'GENERATE_AND_BIND_MATNR'.
    lv_upload_id = request->get_form_field( 'UPLOAD_ID' ).
    lv_mtart     = request->get_form_field( 'MTART' ).
    lv_matkl     = request->get_form_field( 'MATKL' ).
    lv_werks     = request->get_form_field( 'WERKS' ).

    IF lv_upload_id IS INITIAL OR lv_mtart IS INITIAL OR lv_matkl IS INITIAL OR lv_werks IS INITIAL.
      _m_response->set_header_field( name = 'Content-Type' value = 'application/json' ).
      _m_response->set_cdata( '{"status":"ERROR","message":"Batch Upload, Material Type, Group, dan Plant wajib diisi!"}' ).
      navigation->response_complete( ).
      RETURN.
    ENDIF.

    " A. PENENTUAN KODE PREFIX BERDASARKAN MATERIAL TYPE (MTART)
    CLEAR lv_prefix.

    CASE lv_mtart.
      " KODE DEPAN 1000...
      WHEN 'ZR01' OR 'ZR02'.
        lv_prefix = '1000'.

      " KODE DEPAN 2000...
      WHEN 'HALB'.
        lv_prefix = '2000'.

      " KODE DEPAN 3000...
      WHEN 'FERT'.
        lv_prefix = '3000'.

      " KODE DEPAN 4000...
      WHEN 'ZR03' OR 'ZR04' OR 'ZR05' OR 'ZR06' OR 'ZR07' OR 'ZR08' OR 'ZR09'.
        lv_prefix = '4000'.

      " KODE DEPAN 5000...
      WHEN 'ZOS1' OR 'ZOS2' OR 'ZOS3' OR 'VERP'.
        lv_prefix = '5000'.

      " KODE DEPAN 6000...
      WHEN 'ERSA' OR 'FHMI'.
        lv_prefix = '6000'.

      " KODE DEPAN 7000...
      WHEN 'NLAG'.
        lv_prefix = '7000'.

      WHEN OTHERS.
        lv_prefix = '6000'.
    ENDCASE.

    " B. Fetch Data Staging Batch Saat Ini
    SELECT * FROM zbom_stg_part
      WHERE upload_id = @lv_upload_id
      ORDER BY posnr ASCENDING
      INTO TABLE @lt_detail.

    IF lt_detail IS INITIAL.
      _m_response->set_header_field( name = 'Content-Type' value = 'application/json' ).
      _m_response->set_cdata( '{"status":"ERROR","message":"Data Staging tidak ditemukan!"}' ).
      navigation->response_complete( ).
      RETURN.
    ENDIF.

    " C. BACA AKTUAL DB: BACA SELURUH KODE TERPAKAI DI MARA & STAGING LAIN (PERBAIKAN TYPE & QUERY)
    DATA: lt_used_matnr TYPE HASHED TABLE OF string WITH UNIQUE KEY table_line,
          lv_like_mara  TYPE string,
          lv_like_stg   TYPE string,
          lv_matnr_ext  TYPE string.

    lv_like_mara = '%0000' && lv_prefix && '%'.
    lv_like_stg  = lv_prefix && '%'.

    " 1. Ambil nomor dari MARA
    SELECT matnr FROM mara
      WHERE matnr LIKE @lv_like_mara OR matnr LIKE @lv_like_stg
      INTO TABLE @DATA(lt_mara_exist).

    " 2. Ambil nomor dari ZBOM_STG_PART (Hanya batch aktif, mengabaikan status CANCEL/REJECT/DRAFT)
    SELECT matnr FROM zbom_stg_part
      WHERE upload_id <> @lv_upload_id
        AND matnr LIKE @lv_like_stg
        AND status IN ( 'CODE_BOUND', 'READY_SAP', 'SUCCESS', 'COMPLETED' )
      INTO TABLE @DATA(lt_stg_exist).

    " 3. Normalisasi ke String Clean (Mencegah mismatch padding spasi)
    LOOP AT lt_mara_exist INTO DATA(ls_m).
      CLEAR lv_matnr_ext.
      CALL FUNCTION 'CONVERSION_EXIT_MATN1_OUTPUT'
        EXPORTING
          input  = ls_m-matnr
        IMPORTING
          output = lv_matnr_ext
        EXCEPTIONS
          OTHERS = 1.

      IF sy-subrc <> 0 OR lv_matnr_ext IS INITIAL.
        lv_matnr_ext = ls_m-matnr.
      ENDIF.

      SHIFT lv_matnr_ext LEFT DELETING LEADING '0'.
      CONDENSE lv_matnr_ext NO-GAPS.

      IF lv_matnr_ext IS NOT INITIAL.
        INSERT lv_matnr_ext INTO TABLE lt_used_matnr.
      ENDIF.
    ENDLOOP.

    LOOP AT lt_stg_exist INTO DATA(ls_s).
      CLEAR lv_matnr_ext.
      CALL FUNCTION 'CONVERSION_EXIT_MATN1_OUTPUT'
        EXPORTING
          input  = ls_s-matnr
        IMPORTING
          output = lv_matnr_ext
        EXCEPTIONS
          OTHERS = 1.

      IF sy-subrc <> 0 OR lv_matnr_ext IS INITIAL.
        lv_matnr_ext = ls_s-matnr.
      ENDIF.

      SHIFT lv_matnr_ext LEFT DELETING LEADING '0'.
      CONDENSE lv_matnr_ext NO-GAPS.

      IF lv_matnr_ext IS NOT INITIAL.
        INSERT lv_matnr_ext INTO TABLE lt_used_matnr.
      ENDIF.
    ENDLOOP.

    " D. GAP FILLING ENGINE (+1 INCREMENTAL DARI KODE TERKECIL)
    DATA: lv_seq        TYPE i,
          lv_first_code TYPE matnr,
          lv_found_code TYPE matnr,
          lv_cand_str   TYPE string.

    LOOP AT lt_detail ASSIGNING FIELD-SYMBOL(<ls_row>).
      CLEAR: lv_found_code, lv_cand_str.

      lv_seq = 1.

      DO 9999 TIMES.
        " Format kandidat 8-digit murni (Contoh: 40000001)
        lv_cand_str = |{ lv_prefix }{ lv_seq WIDTH = 4 PAD = '0' }|.

        " Pengecekan O(1) di Hash Table Memori
        READ TABLE lt_used_matnr WITH KEY table_line = lv_cand_str TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
          " Nomor kosong terkecil ditemukan!
          lv_found_code = lv_cand_str.

          " Daftarkan ke Hash Table agar baris berikutnya memakai urutan +1
          INSERT lv_cand_str INTO TABLE lt_used_matnr.
          EXIT.
        ENDIF.

        lv_seq = lv_seq + 1.
      ENDDO.

      IF lv_found_code IS INITIAL.
        _m_response->set_header_field( name = 'Content-Type' value = 'application/json' ).
        _m_response->set_cdata( '{"status":"ERROR","message":"Rentang Nomor Material SAP Sudah Penuh!"}' ).
        navigation->response_complete( ).
        RETURN.
      ENDIF.

      IF lv_first_code IS INITIAL.
        lv_first_code = lv_found_code.
      ENDIF.

      " Assign Hasil Kode Material
      <ls_row>-matnr = lv_found_code.
      <ls_row>-werks = lv_werks.
      <ls_row>-matkl = lv_matkl.

      IF <ls_row>-meins IS INITIAL. <ls_row>-meins = 'PC'. ENDIF.
      <ls_row>-status = 'CODE_BOUND'.
    ENDLOOP.

    " E. Simpan Hasil Binding ke Database
    MODIFY zbom_stg_part FROM TABLE @lt_detail.
    COMMIT WORK.

    " F. Return Result Payload JSON
    _m_response->set_header_field( name = 'Content-Type' value = 'application/json' ).
    /ui2/cl_json=>serialize(
      EXPORTING data = lt_detail pretty_name = /ui2/cl_json=>pretty_mode-low_case
      RECEIVING r_json = lv_json_resp ).

    lv_json_resp = '{"status":"SUCCESS","base_matnr":"' && lv_first_code && '","data":' && lv_json_resp && '}'.
    _m_response->set_cdata( lv_json_resp ).
    navigation->response_complete( ).

  " -------------------------------------------------------------------
  " 4. SIAPKAN DATA UNTUK INTEGRASI FABRIKASI SAP
  " -------------------------------------------------------------------
  WHEN 'PREPARE_FOR_SAP'.
    lv_upload_id = request->get_form_field( 'UPLOAD_ID' ).

    IF lv_upload_id IS NOT INITIAL.
      UPDATE zbom_stg_part
         SET status = 'READY_SAP'
       WHERE upload_id = @lv_upload_id.
      COMMIT WORK.
    ENDIF.

    _m_response->set_header_field( name = 'Content-Type' value = 'application/json' ).
    _m_response->set_cdata( '{"status":"SUCCESS","message":"Data staging berhasil disiapkan & dikunci untuk proses SAP Material Master!"}' ).
    navigation->response_complete( ).

  " -------------------------------------------------------------------
  " 5. LOGOUT
  " -------------------------------------------------------------------
  WHEN 'LOGOUT'.
    _m_response->redirect( url = '/sap/public/bc/icf/logoff' ).
    navigation->response_complete( ).
ENDCASE.