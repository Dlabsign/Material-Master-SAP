*----------------------------------------------------------------------*
* Event Handler : OnInputProcessing
* Description   : Handler Staging Material Part R&D (Bebas Syntax Error)
*----------------------------------------------------------------------*
DATA: event              TYPE string,
      lv_mtart           TYPE mtart,
      lv_matkl           TYPE matkl,
      lv_werks           TYPE werks_d,
      lv_prefix          TYPE string,
      lv_next_num        TYPE i,
      lv_candidate_matnr TYPE matnr,
      lv_alpha_matnr     TYPE matnr,
      lv_exists          TYPE abap_bool,
      lv_json_resp       TYPE string,
      lt_stg_input       TYPE TABLE OF zbom_stg_part,
      ls_stg_item        TYPE zbom_stg_part,
      lv_row_cnt         TYPE i,
      lv_idx_str         TYPE string,
      lv_posnr           TYPE posnr_acc,
      lt_mara_list       TYPE TABLE OF matnr,
      lv_m_item          TYPE matnr,
      lv_m_clean         TYPE string,
      lv_max_val         TYPE p LENGTH 16 DECIMALS 0,
      lv_curr_val        TYPE p LENGTH 16 DECIMALS 0,

      " Variable Batch Upload & History
      lv_upload_id       TYPE zbom_stg_part-upload_id,
      lv_filename        TYPE zbom_stg_part-filename.

event = event_id.

CASE event.



  " -------------------------------------------------------------------
  " 2. SIMPAN MULTI-LINE DATA STAGING KE ZBOM_STG_HDR & ZBOM_STG_PART
  " -------------------------------------------------------------------
  WHEN 'SAVE_STAGE'.
    req_id       = request->get_form_field( 'REQ_ID' ).
    lv_upload_id = request->get_form_field( 'UPLOAD_ID' ).
    lv_filename  = request->get_form_field( 'FILENAME' ).

    " Generasi REQ_ID otomatis jika masih kosong
    IF req_id IS INITIAL.
      TRY.
          req_id = cl_system_uuid=>create_uuid_c32_static( ).
        CATCH cx_uuid_error.
          req_id = |REQ-{ sy-datum }-{ sy-uzeit }|.
      ENDTRY.
    ENDIF.

    " Generasi UPLOAD_ID otomatis jika belum ada
    IF lv_upload_id IS INITIAL.
      TRY.
          lv_upload_id = cl_system_uuid=>create_uuid_c32_static( ).
        CATCH cx_uuid_error.
          lv_upload_id = |BOM-{ sy-datum }-{ sy-uzeit }|.
      ENDTRY.
    ENDIF.

    lv_row_cnt = request->get_form_field( 'ROW_COUNT' ).

    " 2A. SIMPAN HEADER BATCH UPLOAD KE ZBOM_STG_HDR
    DATA: ls_stg_hdr TYPE zbom_stg_hdr.
    CLEAR ls_stg_hdr.
    ls_stg_hdr-mandt          = sy-mandt.
    ls_stg_hdr-upload_id      = lv_upload_id.
    ls_stg_hdr-req_id         = req_id.
    ls_stg_hdr-filename       = lv_filename.
    ls_stg_hdr-total_items    = lv_row_cnt.
    ls_stg_hdr-status         = request->get_form_field( 'STATUS' ).
    IF ls_stg_hdr-status IS INITIAL.
      ls_stg_hdr-status = 'DRAFT'.
    ENDIF.
    ls_stg_hdr-ernam          = sy-uname.
    ls_stg_hdr-erdat          = sy-datum.
    ls_stg_hdr-ertim          = sy-uzeit.

    MODIFY zbom_stg_hdr FROM @ls_stg_hdr.

    " 2B. HAPUS & SIMPAN DETAIL LINE ITEMS KE ZBOM_STG_PART
    DELETE FROM zbom_stg_part WHERE upload_id = @lv_upload_id.

    DO lv_row_cnt TIMES.
      lv_idx_str = sy-index.
      CONDENSE lv_idx_str.

      CLEAR ls_stg_item.
      ls_stg_item-mandt       = sy-mandt.
      ls_stg_item-upload_id   = lv_upload_id.
      ls_stg_item-req_id      = req_id.

      lv_posnr                = sy-index * 10.
      ls_stg_item-posnr       = lv_posnr.

      ls_stg_item-code_num     = request->get_form_field( 'code_num_' && lv_idx_str ).
      ls_stg_item-parent_posnr = request->get_form_field( 'parent_posnr_' && lv_idx_str ).
      ls_stg_item-matnr        = request->get_form_field( 'matnr_' && lv_idx_str ).

      DATA(lv_line_maktx)      = request->get_form_field( 'maktx_' && lv_idx_str ).
      DATA(lv_line_desc)       = request->get_form_field( 'description_' && lv_idx_str ).
      IF lv_line_desc IS NOT INITIAL.
        ls_stg_item-maktx      = lv_line_desc.
      ELSE.
        ls_stg_item-maktx      = lv_line_maktx.
      ENDIF.

      ls_stg_item-groes        = request->get_form_field( 'groes_' && lv_idx_str ).       " Rough Size
      ls_stg_item-groes_fin    = request->get_form_field( 'groes_fin_' && lv_idx_str ).   " Finish Size

      " Pengisian Kuantitas ke Field CHAR20
      ls_stg_item-menge        = request->get_form_field( 'menge_' && lv_idx_str ).      " QTY Item
      ls_stg_item-menge_ord    = request->get_form_field( 'menge_ord_' && lv_idx_str ).  " QTY Order

      ls_stg_item-meins        = request->get_form_field( 'meins_' && lv_idx_str ).

      ls_stg_item-vol_m3       = request->get_form_field( 'vol_m3_' && lv_idx_str ).     " M3
      ls_stg_item-wrkst        = request->get_form_field( 'wrkst_' && lv_idx_str ).      " Material
      ls_stg_item-note         = request->get_form_field( 'note_' && lv_idx_str ).       " Note
      ls_stg_item-finishing    = request->get_form_field( 'finishing_' && lv_idx_str ).  " Finishing

      ls_stg_item-disgr        = request->get_form_field( 'disgr_' && lv_idx_str ).
      ls_stg_item-dispo        = request->get_form_field( 'dispo_' && lv_idx_str ).
      ls_stg_item-lgort1       = request->get_form_field( 'lgort1_' && lv_idx_str ).
      ls_stg_item-lgort2       = request->get_form_field( 'lgort2_' && lv_idx_str ).

      DATA(lv_line_werks) = request->get_form_field( 'werks_' && lv_idx_str ).
      IF lv_line_werks IS NOT INITIAL.
        ls_stg_item-werks = lv_line_werks.
      ELSE.
        ls_stg_item-werks = request->get_form_field( 'WERKS' ).
      ENDIF.

      ls_stg_item-area_m2      = request->get_form_field( 'area_m2_' && lv_idx_str ).
      ls_stg_item-activity     = request->get_form_field( 'activity_' && lv_idx_str ).
      ls_stg_item-umrez        = request->get_form_field( 'umrez_' && lv_idx_str ).
      ls_stg_item-meinh        = request->get_form_field( 'meinh_' && lv_idx_str ).
      ls_stg_item-sloc_def      = request->get_form_field( 'sloc_def_' && lv_idx_str ).

      DATA(lv_line_mtart) = request->get_form_field( 'mtart_' && lv_idx_str ).
      IF lv_line_mtart IS NOT INITIAL.
        ls_stg_item-mtart = lv_line_mtart.
      ENDIF.

      DATA(lv_line_matkl) = request->get_form_field( 'matkl_' && lv_idx_str ).
      IF lv_line_matkl IS NOT INITIAL.
        ls_stg_item-matkl = lv_line_matkl.
      ELSE.
        ls_stg_item-matkl = request->get_form_field( 'MATKL' ).
      ENDIF.

      ls_stg_item-postp        = request->get_form_field( 'postp_' && lv_idx_str ).
      ls_stg_item-peinh        = request->get_form_field( 'peinh_' && lv_idx_str ).

      IF ls_stg_item-maktx IS NOT INITIAL.
        APPEND ls_stg_item TO lt_stg_input.
      ENDIF.
    ENDDO.

    IF lt_stg_input IS NOT INITIAL.
      MODIFY zbom_stg_part FROM TABLE @lt_stg_input.
      COMMIT WORK.
    ENDIF.

    _m_response->set_header_field( name = 'Content-Type' value = 'application/json' ).
    _m_response->set_cdata( '{"status":"SUCCESS"}' ).
    navigation->response_complete( ).

  " -------------------------------------------------------------------
  " 3. GET RIWAYAT BATCH UPLOAD DARI ZBOM_STG_HDR
  " -------------------------------------------------------------------
  WHEN 'GET_HISTORY'.
    TYPES: BEGIN OF ty_history,
             upload_id     TYPE zbom_stg_hdr-upload_id,
             filename      TYPE zbom_stg_hdr-filename,
             erdat         TYPE zbom_stg_hdr-erdat,
             ertim         TYPE zbom_stg_hdr-ertim,
             ernam         TYPE zbom_stg_hdr-ernam,
             status        TYPE zbom_stg_hdr-status,
             approved_by   TYPE zbom_stg_hdr-approved_by,
             approved_at   TYPE zbom_stg_hdr-approved_at,
             reject_reason TYPE zbom_stg_hdr-reject_reason,
             sub_reason    TYPE zbom_stg_hdr-sub_reason,
             total_row     TYPE zbom_stg_hdr-total_items,
           END OF ty_history.

    DATA: lt_history  TYPE TABLE OF ty_history,
          lv_json_his TYPE string.

    SELECT upload_id, filename, erdat, ertim, ernam, status, approved_by,
           approved_at, reject_reason, sub_reason, total_items AS total_row
      FROM zbom_stg_hdr
      ORDER BY erdat DESCENDING, ertim DESCENDING
      INTO CORRESPONDING FIELDS OF TABLE @lt_history.

    /ui2/cl_json=>serialize(
      EXPORTING
        data        = lt_history
        pretty_name = /ui2/cl_json=>pretty_mode-low_case
      RECEIVING
        r_json      = lv_json_his ).

    _m_response->set_header_field( name = 'Content-Type' value = 'application/json' ).
    _m_response->set_cdata( lv_json_his ).
    navigation->response_complete( ).

  " -------------------------------------------------------------------
  " 4. GET DETAIL UPLOAD BERDASARKAN UPLOAD_ID
  " -------------------------------------------------------------------
  WHEN 'GET_UPLOAD_DETAIL'.
    DATA: lt_detail   TYPE TABLE OF zbom_stg_part,
          lv_json_det TYPE string.

    lv_upload_id = request->get_form_field( 'UPLOAD_ID' ).

    IF lv_upload_id IS NOT INITIAL.
      SELECT *
        FROM zbom_stg_part
        WHERE upload_id = @lv_upload_id
        ORDER BY posnr ASCENDING
        INTO TABLE @lt_detail.
    ENDIF.

    /ui2/cl_json=>serialize(
      EXPORTING
        data        = lt_detail
        pretty_name = /ui2/cl_json=>pretty_mode-low_case
      RECEIVING
        r_json      = lv_json_det ).

    _m_response->set_header_field( name = 'Content-Type' value = 'application/json' ).
    _m_response->set_cdata( lv_json_det ).
    navigation->response_complete( ).

  " -------------------------------------------------------------------
  " 5. UPDATE STATUS BATCH (HOLD / APPROVE / REJECT)
  " -------------------------------------------------------------------
  WHEN 'UPDATE_STATUS'.
    DATA: lv_new_st      TYPE string,
          lv_rej_rsn     TYPE string,
          lv_app_at      TYPE string.

    lv_upload_id  = request->get_form_field( 'UPLOAD_ID' ).
    lv_new_st     = request->get_form_field( 'STATUS' ).
    lv_rej_rsn    = request->get_form_field( 'REJECT_REASON' ).

    IF lv_upload_id IS NOT INITIAL AND lv_new_st IS NOT INITIAL.
      lv_app_at = |{ sy-datum }{ sy-uzeit }|.

      UPDATE zbom_stg_hdr
        SET status        = @lv_new_st,
            reject_reason = @lv_rej_rsn,
            approved_by   = @sy-uname,
            approved_at   = @lv_app_at
        WHERE upload_id   = @lv_upload_id.

      COMMIT WORK.
    ENDIF.

    _m_response->set_header_field( name = 'Content-Type' value = 'application/json' ).
    _m_response->set_cdata( '{"status":"SUCCESS"}' ).
    navigation->response_complete( ).

  " -------------------------------------------------------------------
  " 6. SEARCH MARA RECORDS
  " -------------------------------------------------------------------
  WHEN 'SEARCH_MARA'.
    DATA: lv_str_matnr     TYPE string,
          lv_str_maktx     TYPE string,
          lv_str_mtart     TYPE string,
          lv_str_matkl     TYPE string,
          lv_filter_matnr  TYPE char40,
          lv_filter_maktx  TYPE char40,
          lv_filter_mtart  TYPE mara-mtart,
          lv_filter_matkl  TYPE char10,
          lv_pattern_matnr TYPE char50,
          lv_pattern_maktx TYPE char50,
          lv_pattern_matkl TYPE char20,
          lv_matnr_padded  TYPE mara-matnr.

    TYPES: BEGIN OF ty_mara_res,
             matnr  TYPE mara-matnr,
             maktx  TYPE makt-maktx,
             werks  TYPE marc-werks,
             disgr  TYPE marc-disgr,
             dispo  TYPE marc-dispo,
             lgort1 TYPE marc-lgpro,
             lgort2 TYPE marc-lgfsb,
             mtart  TYPE mara-mtart,
             matkl  TYPE mara-matkl,
             meins  TYPE mara-meins,
             bismt  TYPE mara-bismt,
             mbrsh  TYPE mara-mbrsh,
             spart  TYPE mara-spart,
           END OF ty_mara_res.

    DATA: lt_mara_res TYPE TABLE OF ty_mara_res.

    lv_str_matnr = request->get_form_field( 'FILTER_MATNR' ).
    lv_str_maktx = request->get_form_field( 'FILTER_MAKTX' ).
    lv_str_mtart = request->get_form_field( 'FILTER_MTART' ).
    lv_str_matkl = request->get_form_field( 'FILTER_MATKL' ).

    TRANSLATE lv_str_matnr TO UPPER CASE.
    TRANSLATE lv_str_maktx TO UPPER CASE.
    TRANSLATE lv_str_mtart TO UPPER CASE.
    TRANSLATE lv_str_matkl TO UPPER CASE.

    CONDENSE lv_str_matnr.
    CONDENSE lv_str_maktx.
    CONDENSE lv_str_mtart.
    CONDENSE lv_str_matkl.

    lv_filter_matnr = lv_str_matnr.
    lv_filter_maktx = lv_str_maktx.
    lv_filter_mtart = lv_str_mtart.
    lv_filter_matkl = lv_str_matkl.

    IF lv_filter_matnr IS NOT INITIAL.
      CONCATENATE '%' lv_str_matnr '%' INTO lv_pattern_matnr.
      IF lv_str_matnr CO '0123456789'.
        lv_matnr_padded = lv_str_matnr.
        CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
          EXPORTING
            input  = lv_matnr_padded
          IMPORTING
            output = lv_matnr_padded.
      ENDIF.
    ENDIF.

    IF lv_filter_maktx IS NOT INITIAL.
      CONCATENATE '%' lv_str_maktx '%' INTO lv_pattern_maktx.
    ENDIF.

    IF lv_filter_matkl IS NOT INITIAL.
      CONCATENATE '%' lv_str_matkl '%' INTO lv_pattern_matkl.
    ENDIF.

    SELECT a~matnr, b~maktx, c~werks, c~disgr, c~dispo, c~lgpro AS lgort1, c~lgfsb AS lgort2,
           a~mtart, a~matkl, a~meins, a~bismt, a~mbrsh, a~spart
      FROM mara AS a
      LEFT OUTER JOIN makt AS b ON a~matnr = b~matnr AND b~spras = @sy-langu
      LEFT OUTER JOIN marc AS c ON a~matnr = c~matnr
      WHERE ( @lv_filter_matnr IS INITIAL OR a~matnr LIKE @lv_pattern_matnr OR ( @lv_matnr_padded IS NOT INITIAL AND a~matnr = @lv_matnr_padded ) )
        AND ( @lv_filter_maktx IS INITIAL OR b~maktx LIKE @lv_pattern_maktx )
        AND ( @lv_filter_mtart IS INITIAL OR a~mtart = @lv_filter_mtart )
        AND ( @lv_filter_matkl IS INITIAL OR a~matkl LIKE @lv_pattern_matkl )
      INTO TABLE @lt_mara_res
      UP TO 200 ROWS.

    DATA(lv_json_mara) = /ui2/cl_json=>serialize( data = lt_mara_res compress = 'X' pretty_name = /ui2/cl_json=>pretty_mode-low_case ).
    _m_response->set_header_field( name = 'Content-Type' value = 'application/json' ).
    _m_response->set_cdata( lv_json_mara ).
    navigation->response_complete( ).
 
  " -------------------------------------------------------------------
  " 7. LOGOUT
  " -------------------------------------------------------------------
  WHEN 'LOGOUT'.
    _m_response->redirect( url = '/sap/public/bc/icf/logoff' ).
    navigation->response_complete( ).

ENDCASE.