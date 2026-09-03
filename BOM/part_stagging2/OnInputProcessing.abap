*----------------------------------------------------------------------*
* Event Handler : OnInputProcessing (Staging Process & Binding Engine)
*----------------------------------------------------------------------*
DATA: event              TYPE string,
      lv_upload_id       TYPE string,
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
  " 1. GET HISTORY BATCH UPLOAD DARI ZBOM_STG_HDR
  " -------------------------------------------------------------------
  WHEN 'GET_HISTORY'.
    TYPES: BEGIN OF ty_history,
             upload_id TYPE zbom_stg_hdr-upload_id,
             filename  TYPE zbom_stg_hdr-filename,
             erdat     TYPE zbom_stg_hdr-erdat,
             ertim     TYPE zbom_stg_hdr-ertim,
             ernam     TYPE zbom_stg_hdr-ernam,
             status    TYPE zbom_stg_hdr-status,
             total_row TYPE zbom_stg_hdr-total_items,
           END OF ty_history.

    DATA: lt_history  TYPE TABLE OF ty_history,
          lv_json_his TYPE string.

    SELECT upload_id, filename, erdat, ertim, ernam, status, total_items AS total_row
      FROM zbom_stg_hdr
      ORDER BY erdat DESCENDING, ertim DESCENDING
      INTO CORRESPONDING FIELDS OF TABLE @lt_history.

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

    IF lv_upload_id IS INITIAL.
      _m_response->set_header_field( name = 'Content-Type' value = 'application/json' ).
      _m_response->set_cdata( '{"status":"ERROR","message":"Batch Upload wajib diisi!"}' ).
      navigation->response_complete( ).
      RETURN.
    ENDIF.

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

    " C. BACA AKTUAL DB: BACA SELURUH KODE TERPAKAI DI MARA & STAGING LAIN
    DATA: lt_used_matnr TYPE HASHED TABLE OF string WITH UNIQUE KEY table_line,
          lv_matnr_ext  TYPE string.

    " Ambil nomor dari MARA
    SELECT matnr FROM mara
      INTO TABLE @DATA(lt_mara_exist).

    " Ambil nomor dari ZBOM_STG_PART
    SELECT matnr FROM zbom_stg_part
      WHERE upload_id <> @lv_upload_id
      INTO TABLE @DATA(lt_stg_exist).

    " Normalisasi ke String Clean
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

    " D. GENERATE KODE MATERIAL VIA FUNCTION MODULE ZFM_CHECK_MATERIAL
    TYPES: BEGIN OF ty_parent_map,
             posnr TYPE posnr_acc,
             matnr TYPE matnr,
           END OF ty_parent_map.

    DATA: lt_parent_map TYPE HASHED TABLE OF ty_parent_map WITH UNIQUE KEY posnr,
          ls_parent_map TYPE ty_parent_map,
          lv_seq        TYPE i,
          lv_first_code TYPE matnr,
          lv_found_code TYPE matnr,
          lv_cand_str   TYPE string,
          lv_row_mtart  TYPE mtart,
          lv_row_prefix TYPE string,
          lv_is_avail   TYPE char1,
          lv_next_num   TYPE matnr_ext,
          lt_chk_ret    TYPE TABLE OF bapiret2.

    LOOP AT lt_detail ASSIGNING FIELD-SYMBOL(<ls_row>).
      CLEAR: lv_found_code, lv_cand_str, lv_row_prefix, lv_is_avail, lv_next_num, lt_chk_ret.

      IF <ls_row>-mtart IS NOT INITIAL.
        lv_row_mtart = <ls_row>-mtart.
      ELSEIF lv_mtart IS NOT INITIAL.
        lv_row_mtart = lv_mtart.
      ELSE.
        lv_row_mtart = 'HALB'.
      ENDIF.

      " 1. PANGGIL FUNCTION MODULE ZFM_CHECK_MATERIAL UNTUK CHECK & GENERATE KODE
      CALL FUNCTION 'ZFM_CHECK_MATERIAL'
        EXPORTING
          iv_mtart        = lv_row_mtart
        IMPORTING
          ev_is_available = lv_is_avail
          ev_next_number  = lv_next_num
          et_return       = lt_chk_ret.

      IF lv_next_num IS NOT INITIAL.
        " Normalisasi nomor ke clean string jika diperlukan
        CALL FUNCTION 'CONVERSION_EXIT_MATN1_OUTPUT'
          EXPORTING input  = lv_next_num
          IMPORTING output = lv_cand_str
          EXCEPTIONS OTHERS = 1.
        IF sy-subrc <> 0 OR lv_cand_str IS INITIAL.
          lv_cand_str = lv_next_num.
        ENDIF.
        SHIFT lv_cand_str LEFT DELETING LEADING '0'.
        CONDENSE lv_cand_str NO-GAPS.
      ENDIF.

      " 2. SAFETY CHECK ANTI-DUPLIKASI TERHADAP BATCH & MARA
      IF lv_cand_str IS NOT INITIAL.
        DO 100 TIMES.
          READ TABLE lt_used_matnr WITH KEY table_line = lv_cand_str TRANSPORTING NO FIELDS.
          IF sy-subrc <> 0.
            " Nomor bebas & unik
            lv_found_code = lv_cand_str.
            INSERT lv_cand_str INTO TABLE lt_used_matnr.
            EXIT.
          ELSE.
            " Increment nomor 1 tingkat jika sudah terpakai di batch/MARA
            IF lv_cand_str CO '0123456789'.
              DATA: lv_int_val TYPE i,
                    lv_num_tmp TYPE string.
              lv_int_val = lv_cand_str.
              lv_int_val = lv_int_val + 1.
              lv_num_tmp = lv_int_val.
              CONDENSE lv_num_tmp.
              CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
                EXPORTING input  = lv_num_tmp
                IMPORTING output = lv_cand_str.
            ELSE.
              CALL FUNCTION 'ZFM_CHECK_MATERIAL'
                EXPORTING iv_mtart        = lv_row_mtart
                IMPORTING ev_is_available = lv_is_avail
                          ev_next_number  = lv_next_num
                          et_return       = lt_chk_ret.
              lv_cand_str = lv_next_num.
            ENDIF.
          ENDIF.
        ENDDO.
      ENDIF.

      " 3. FALLBACK GENERATOR JIKA FM TIDAK MENGEMBALIKAN NOMOR (E.G. MOCK/DEV ENV)
      IF lv_found_code IS INITIAL.
        lv_seq = 1.
        CASE lv_row_mtart.
          WHEN 'ZR01' OR 'ZR02' OR 'ROH'.  lv_row_prefix = '1000'.
          WHEN 'HALB'.                     lv_row_prefix = '2000'.
          WHEN 'FERT'.                     lv_row_prefix = '3000'.
          WHEN OTHERS.                     lv_row_prefix = '6000'.
        ENDCASE.

        DO 9999 TIMES.
          lv_cand_str = |{ lv_row_prefix }{ lv_seq WIDTH = 4 PAD = '0' }|.
          READ TABLE lt_used_matnr WITH KEY table_line = lv_cand_str TRANSPORTING NO FIELDS.
          IF sy-subrc <> 0.
            lv_found_code = lv_cand_str.
            INSERT lv_cand_str INTO TABLE lt_used_matnr.
            EXIT.
          ENDIF.
          lv_seq = lv_seq + 1.
        ENDDO.
      ENDIF.

      IF lv_found_code IS INITIAL.
        _m_response->set_header_field( name = 'Content-Type' value = 'application/json' ).
        _m_response->set_cdata( '{"status":"ERROR","message":"Gagal menggenerate nomor material dari ZFM_CHECK_MATERIAL!"}' ).
        navigation->response_complete( ).
        RETURN.
      ENDIF.

      IF lv_first_code IS INITIAL.
        lv_first_code = lv_found_code.
      ENDIF.

      " Assign Hasil Kode Material
      <ls_row>-matnr = lv_found_code.
      IF lv_werks IS NOT INITIAL AND <ls_row>-werks IS INITIAL. <ls_row>-werks = lv_werks. ENDIF.
      IF lv_matkl IS NOT INITIAL AND <ls_row>-matkl IS INITIAL. <ls_row>-matkl = lv_matkl. ENDIF.
      <ls_row>-mtart = lv_row_mtart.
      <ls_row>-postp = 'L'.
      <ls_row>-peinh = '1'.

      CASE lv_row_mtart.
        WHEN 'HALB'.
          <ls_row>-bklas = '7920'.
        WHEN 'ZR01' OR 'ZR02' OR 'ROH'.
          <ls_row>-bklas = '3000'.
        WHEN OTHERS.
          <ls_row>-bklas = '7920'.
      ENDCASE.

      IF <ls_row>-meins IS INITIAL. <ls_row>-meins = 'PC'. ENDIF.

      IF <ls_row>-code_num = 'PF'.
        ls_parent_map-posnr = <ls_row>-posnr.
        ls_parent_map-matnr = <ls_row>-matnr.
        INSERT ls_parent_map INTO TABLE lt_parent_map.
      ENDIF.
    ENDLOOP.

    " Assign PARENT_MATNR ke anak komponen (SF)
    LOOP AT lt_detail ASSIGNING FIELD-SYMBOL(<ls_child>).
      IF <ls_child>-code_num <> 'PF' AND <ls_child>-parent_posnr IS NOT INITIAL.
        READ TABLE lt_parent_map WITH KEY posnr = <ls_child>-parent_posnr INTO ls_parent_map.
        IF sy-subrc = 0.
          <ls_child>-parent_matnr = ls_parent_map-matnr.
        ENDIF.
      ENDIF.
    ENDLOOP.

    " E. Simpan Hasil Binding ke Database
    MODIFY zbom_stg_part FROM TABLE @lt_detail.

    " Update Status di ZBOM_STG_HDR
    UPDATE zbom_stg_hdr
       SET status      = 'CODE_BOUND'
     WHERE upload_id   = @lv_upload_id.

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
  " 4. SIAPKAN DATA & EKSEKUSI POSTING KE SAP MATERIAL MASTER (BAPI)
  " -------------------------------------------------------------------
  WHEN 'PREPARE_FOR_SAP'.
    lv_upload_id = request->get_form_field( 'UPLOAD_ID' ).

    IF lv_upload_id IS INITIAL.
      _m_response->set_header_field( name = 'Content-Type' value = 'application/json' ).
      _m_response->set_cdata( '{"status":"ERROR","message":"Upload ID wajib diisi!"}' ).
      navigation->response_complete( ).
      RETURN.
    ENDIF.

    " Ambil data item dari ZBOM_STG_PART
    SELECT * FROM zbom_stg_part
      WHERE upload_id = @lv_upload_id
      ORDER BY posnr ASCENDING
      INTO TABLE @lt_detail.

    IF lt_detail IS INITIAL.
      _m_response->set_header_field( name = 'Content-Type' value = 'application/json' ).
      _m_response->set_cdata( '{"status":"ERROR","message":"Data staging tidak ditemukan untuk diproses ke SAP!"}' ).
      navigation->response_complete( ).
      RETURN.
    ENDIF.

    TYPES: BEGIN OF ty_bapi_log,
             posnr   TYPE posnr_acc,
             matnr   TYPE string,
             status  TYPE string,
             type    TYPE string,
             message TYPE string,
           END OF ty_bapi_log.

    DATA: lt_bapi_logs  TYPE TABLE OF ty_bapi_log,
          ls_bapi_log   TYPE ty_bapi_log,
          lv_success_cnt TYPE i VALUE 0,
          lv_error_cnt   TYPE i VALUE 0,
          lv_skip_cnt    TYPE i VALUE 0,
          lv_total_cnt   TYPE i VALUE 0,
          lv_bapi_matnr  TYPE matnr,
          ls_headdata    TYPE bapimathead,
          ls_clientdata  TYPE bapi_mara,
          ls_clientdatax TYPE bapi_marax,
          ls_plantdata   TYPE bapi_marc,
          ls_plantdatax  TYPE bapi_marcx,
          ls_valdata     TYPE bapi_mbew,
          ls_valdatax    TYPE bapi_mbewx,
          ls_slocdata    TYPE bapi_mard,
          ls_slocdatax   TYPE bapi_mardx,
          ls_return      TYPE bapiret2,
          lt_makt        TYPE TABLE OF bapi_makt,
          ls_makt        TYPE bapi_makt,
          lt_returnmes   TYPE TABLE OF bapi_matreturn2.

    LOOP AT lt_detail ASSIGNING FIELD-SYMBOL(<ls_post>).
      lv_total_cnt = lv_total_cnt + 1.
      CLEAR ls_bapi_log.

      " Trim & Check Material Number
      DATA(lv_check_matnr) = <ls_post>-matnr.
      CONDENSE lv_check_matnr.

      IF lv_check_matnr IS INITIAL OR lv_check_matnr = '-'.
        lv_skip_cnt = lv_skip_cnt + 1.
        ls_bapi_log-posnr   = <ls_post>-posnr.
        ls_bapi_log-matnr   = <ls_post>-matnr.
        ls_bapi_log-status  = 'SKIPPED'.
        ls_bapi_log-type    = 'W'.
        ls_bapi_log-message = 'Kode Material (MATNR) belum terisi/ter-bind. Jalankan Generate Code & Auto Bind lebih dulu!'.
        APPEND ls_bapi_log TO lt_bapi_logs.
        CONTINUE.
      ENDIF.

      " Reset BAPI Structures
      CLEAR: ls_headdata, ls_clientdata, ls_clientdatax, ls_plantdata, ls_plantdatax,
             ls_valdata, ls_valdatax, ls_slocdata, ls_slocdatax, ls_return, lt_makt, lt_returnmes.

      " Material Number Input Normalization
      CALL FUNCTION 'CONVERSION_EXIT_MATN1_INPUT'
        EXPORTING  input  = lv_check_matnr
        IMPORTING  output = lv_bapi_matnr
        EXCEPTIONS OTHERS = 1.

      IF sy-subrc <> 0 OR lv_bapi_matnr IS INITIAL.
        lv_bapi_matnr = lv_check_matnr.
      ENDIF.

      " Header Data
      ls_headdata-material      = lv_bapi_matnr.
      ls_headdata-ind_sector    = 'F'.
      ls_headdata-matl_type     = COND #( WHEN <ls_post>-mtart IS NOT INITIAL THEN <ls_post>-mtart ELSE 'HALB' ).
      ls_headdata-basic_view    = 'X'.
      ls_headdata-purchase_view = 'X'.
      ls_headdata-mrp_view       = 'X'.
      ls_headdata-storage_view   = 'X'.
      ls_headdata-account_view   = 'X'.
      ls_headdata-cost_view      = 'X'.

      " Client Data (MARA)
      ls_clientdata-matl_group  = COND #( WHEN <ls_post>-matkl IS NOT INITIAL THEN <ls_post>-matkl ELSE 'HSF004' ).
      ls_clientdata-base_uom    = COND #( WHEN <ls_post>-meins IS NOT INITIAL THEN <ls_post>-meins ELSE 'PC' ).
      ls_clientdata-basic_matl  = <ls_post>-wrkst.
      ls_clientdatax-matl_group = 'X'.
      ls_clientdatax-base_uom    = 'X'.
      IF <ls_post>-wrkst IS NOT INITIAL. ls_clientdatax-basic_matl = 'X'. ENDIF.

      " Material Description (MAKT)
      ls_makt-langu     = sy-langu.
      ls_makt-matl_desc = <ls_post>-maktx.
      APPEND ls_makt TO lt_makt.

      " Plant Data (MARC)
      IF <ls_post>-werks IS NOT INITIAL.
        ls_plantdata-plant       = <ls_post>-werks.
        ls_plantdatax-plant      = <ls_post>-werks.
        ls_plantdata-mrp_group   = <ls_post>-disgr.
        ls_plantdatax-mrp_group  = 'X'.
        ls_plantdata-mrp_ctrler  = <ls_post>-dispo.
        ls_plantdatax-mrp_ctrler = 'X'.
        ls_plantdata-iss_st_loc  = <ls_post>-lgort1.
        ls_plantdatax-iss_st_loc = 'X'.
        ls_plantdata-sloc_exprc  = <ls_post>-lgort2.
        ls_plantdatax-sloc_exprc = 'X'.
      ENDIF.

      " Valuation Data (MBEW)
      IF <ls_post>-werks IS NOT INITIAL.
        ls_valdata-val_area    = <ls_post>-werks.
        ls_valdatax-val_area   = <ls_post>-werks.
        ls_valdata-val_class   = COND #( WHEN <ls_post>-bklas IS NOT INITIAL THEN <ls_post>-bklas ELSE '7920' ).
        ls_valdatax-val_class  = 'X'.
        ls_valdata-price_ctrl  = 'S'.
        ls_valdatax-price_ctrl = 'X'.
        ls_valdata-price_unit  = 1.
        ls_valdatax-price_unit = 'X'.
      ENDIF.

      " Call BAPI Material Save
      CALL FUNCTION 'BAPI_MATERIAL_SAVEDATA'
        EXPORTING
          headdata            = ls_headdata
          clientdata          = ls_clientdata
          clientdatax         = ls_clientdatax
          plantdata           = ls_plantdata
          plantdatax          = ls_plantdatax
          valuationdata       = ls_valdata
          valuationdatax      = ls_valdatax
        IMPORTING
          return              = ls_return
        TABLES
          materialdescription = lt_makt
          returnmessages      = lt_returnmes.

      IF ls_return-type <> 'E' AND ls_return-type <> 'A'.
        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = 'X'.
        <ls_post>-status = 'POSTED_SAP'.
        lv_success_cnt   = lv_success_cnt + 1.

        ls_bapi_log-posnr   = <ls_post>-posnr.
        ls_bapi_log-matnr   = <ls_post>-matnr.
        ls_bapi_log-status  = 'POSTED_SAP'.
        ls_bapi_log-type    = 'S'.
        ls_bapi_log-message = COND #( WHEN ls_return-message IS NOT INITIAL THEN ls_return-message ELSE 'Material berhasil dibuat di SAP.' ).
        APPEND ls_bapi_log TO lt_bapi_logs.
      ELSE.
        <ls_post>-status = 'ERROR_SAP'.
        lv_error_cnt     = lv_error_cnt + 1.

        DATA: lv_err_detail TYPE string.
        CLEAR lv_err_detail.
        IF ls_return-message IS NOT INITIAL.
          lv_err_detail = ls_return-message.
        ENDIF.
        LOOP AT lt_returnmes INTO DATA(ls_rm) WHERE type = 'E' OR type = 'A'.
          IF lv_err_detail IS NOT INITIAL. lv_err_detail = lv_err_detail && ' | '. ENDIF.
          lv_err_detail = lv_err_detail && ls_rm-message.
        ENDLOOP.
        IF lv_err_detail IS INITIAL. lv_err_detail = 'Gagal menyimpan ke SAP (BAPI Error).'. ENDIF.

        ls_bapi_log-posnr   = <ls_post>-posnr.
        ls_bapi_log-matnr   = <ls_post>-matnr.
        ls_bapi_log-status  = 'ERROR_SAP'.
        ls_bapi_log-type    = 'E'.
        ls_bapi_log-message = lv_err_detail.
        APPEND ls_bapi_log TO lt_bapi_logs.
      ENDIF.
    ENDLOOP.

    " Save Updated Status to ZBOM_STG_PART & ZBOM_STG_HDR
    MODIFY zbom_stg_part FROM TABLE @lt_detail.

    DATA: lv_approved_at TYPE string.
    lv_approved_at = |{ sy-datum }{ sy-uzeit }|.

    DATA: lv_hdr_status TYPE zbom_stg_hdr-status.
    IF lv_success_cnt > 0 AND lv_error_cnt = 0 AND lv_skip_cnt = 0.
      lv_hdr_status = 'POSTED_SAP'.
    ELSEIF lv_success_cnt > 0.
      lv_hdr_status = 'PARTIAL_SAP'.
    ELSE.
      lv_hdr_status = 'ERROR_SAP'.
    ENDIF.

    UPDATE zbom_stg_hdr
       SET status      = @lv_hdr_status,
           approved_by = @sy-uname,
           approved_at = @lv_approved_at
     WHERE upload_id   = @lv_upload_id.

    COMMIT WORK.

    DATA: lv_json_logs TYPE string,
          lv_resp_st  TYPE string,
          lv_succ_str TYPE string,
          lv_err_str  TYPE string,
          lv_skip_str TYPE string,
          lv_tot_str  TYPE string,
          lv_main_msg TYPE string.

    lv_succ_str = lv_success_cnt. CONDENSE lv_succ_str.
    lv_err_str  = lv_error_cnt.   CONDENSE lv_err_str.
    lv_skip_str = lv_skip_cnt.    CONDENSE lv_skip_str.
    lv_tot_str  = lv_total_cnt.   CONDENSE lv_tot_str.

    IF lv_success_cnt > 0 AND lv_error_cnt = 0 AND lv_skip_cnt = 0.
      lv_resp_st  = 'SUCCESS'.
      lv_main_msg = 'Berhasil memproses seluruh material ke SAP! Sukses: ' && lv_succ_str && ' item.'.
    ELSEIF lv_success_cnt > 0.
      lv_resp_st  = 'WARNING'.
      lv_main_msg = 'Proses posting SAP selesai parsial. Sukses: ' && lv_succ_str && ', Gagal: ' && lv_err_str && ', Dilewati: ' && lv_skip_str && '.'.
    ELSE.
      lv_resp_st  = 'ERROR'.
      IF lv_skip_cnt > 0 AND lv_error_cnt = 0.
        lv_main_msg = 'Gagal memproses ke SAP: Material Code (MATNR) belum terisi. Jalankan Generate & Auto Bind dahulu! (Dilewati: ' && lv_skip_str && ' item)'.
      ELSE.
        lv_main_msg = 'Gagal memproses material ke SAP. Sukses: ' && lv_succ_str && ', Gagal: ' && lv_err_str && ', Dilewati: ' && lv_skip_str && '. Lihat console F12 untuk detail log.'.
      ENDIF.
    ENDIF.

    /ui2/cl_json=>serialize(
      EXPORTING data = lt_bapi_logs pretty_name = /ui2/cl_json=>pretty_mode-low_case
      RECEIVING r_json = lv_json_logs ).
    IF lv_json_logs IS INITIAL. lv_json_logs = '[]'. ENDIF.

    _m_response->set_header_field( name = 'Content-Type' value = 'application/json' ).
    _m_response->set_cdata( '{"status":"' && lv_resp_st && '","message":"' && lv_main_msg && '","success_count":' && lv_succ_str && ',"error_count":' && lv_err_str && ',"skip_count":' && lv_skip_str && ',"total_count":' && lv_tot_str && ',"logs":' && lv_json_logs && '}' ).
    navigation->response_complete( ).

  " -------------------------------------------------------------------
  " 5. REJECT BATCH STAGING DARI MASTER DATA APPROVER
  " -------------------------------------------------------------------
  WHEN 'REJECT_STAGE'.
    lv_upload_id = request->get_form_field( 'UPLOAD_ID' ).
    DATA(lv_reject_reason) = request->get_form_field( 'REASON' ).

    IF lv_upload_id IS NOT INITIAL.
      UPDATE zbom_stg_hdr
         SET status        = 'REJECTED',
             rejected_by   = @sy-uname,
             reject_reason = @lv_reject_reason
       WHERE upload_id     = @lv_upload_id.
      COMMIT WORK.
    ENDIF.

    _m_response->set_header_field( name = 'Content-Type' value = 'application/json' ).
    _m_response->set_cdata( '{"status":"SUCCESS","message":"Batch upload telah ditolak (REJECTED) dan dikembalikan ke Drafter untuk revisi."}' ).
    navigation->response_complete( ).

  " -------------------------------------------------------------------
  " 6. LOGOUT
  " -------------------------------------------------------------------
  WHEN 'LOGOUT'.
    _m_response->redirect( url = '/sap/public/bc/icf/logoff' ).
    navigation->response_complete( ).
ENDCASE.