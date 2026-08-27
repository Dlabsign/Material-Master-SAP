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
  " 2. SIMPAN MULTI-LINE DATA STAGING KE ZBOM_STG_PART
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
          lv_upload_id = |UPL-{ sy-datum }-{ sy-uzeit }|.
      ENDTRY.
    ENDIF.

    DELETE FROM zbom_stg_part WHERE req_id = @req_id.

    lv_row_cnt = request->get_form_field( 'ROW_COUNT' ).

    DO lv_row_cnt TIMES.
      lv_idx_str = sy-index.
      CONDENSE lv_idx_str.

      CLEAR ls_stg_item.
      ls_stg_item-mandt     = sy-mandt.
      ls_stg_item-req_id    = req_id.
      ls_stg_item-upload_id = lv_upload_id.

      lv_posnr              = sy-index * 10.
      ls_stg_item-posnr     = lv_posnr.

      ls_stg_item-code_num     = request->get_form_field( 'code_num_' && lv_idx_str ).
      ls_stg_item-parent_posnr = request->get_form_field( 'parent_posnr_' && lv_idx_str ).
      ls_stg_item-matnr        = request->get_form_field( 'matnr_' && lv_idx_str ).
      ls_stg_item-maktx        = request->get_form_field( 'maktx_' && lv_idx_str ).
      ls_stg_item-groes        = request->get_form_field( 'groes_' && lv_idx_str ).       " Rough Size
      ls_stg_item-groes_fin    = request->get_form_field( 'groes_fin_' && lv_idx_str ).   " Finish Size

      " Pengisian Kuantitas ke Field CHAR20
      ls_stg_item-menge        = request->get_form_field( 'menge_' && lv_idx_str ).      " QTY Item
      ls_stg_item-menge_ord    = request->get_form_field( 'menge_ord_' && lv_idx_str ).  " QTY Order

      ls_stg_item-meins        = request->get_form_field( 'meins_' && lv_idx_str ).
      IF ls_stg_item-meins IS INITIAL.
        ls_stg_item-meins = 'PC'.
      ENDIF.

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

      ls_stg_item-postp        = 'L'.
      ls_stg_item-peinh        = '1'.
      ls_stg_item-filename     = lv_filename.
      ls_stg_item-status       = request->get_form_field( 'STATUS' ).
      IF ls_stg_item-status IS INITIAL.
        ls_stg_item-status = 'DRAFT'.
      ENDIF.
      ls_stg_item-ernam        = sy-uname.
      ls_stg_item-erdat        = sy-datum.
      ls_stg_item-ertim        = sy-uzeit.

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
  " 3. GET RIWAYAT BATCH UPLOAD (WITH STATUS & REASON)
  " -------------------------------------------------------------------
  WHEN 'GET_HISTORY'.
    TYPES: BEGIN OF ty_history,
             upload_id     TYPE zbom_stg_part-upload_id,
             filename      TYPE zbom_stg_part-filename,
             erdat         TYPE zbom_stg_part-erdat,
             ertim         TYPE zbom_stg_part-ertim,
             ernam         TYPE zbom_stg_part-ernam,
             status        TYPE zbom_stg_part-status,
             sub_reason    TYPE string,
             approved_by   TYPE zbom_stg_part-approved_by,
             approved_at   TYPE zbom_stg_part-approved_at,
             reject_reason TYPE zbom_stg_part-reject_reason,
             total_row     TYPE i,
           END OF ty_history.

    DATA: lt_history  TYPE TABLE OF ty_history,
          lv_json_his TYPE string.

    SELECT upload_id, filename, erdat, ertim, ernam, status,
           approved_by, approved_at, reject_reason,
           MIN( note ) AS sub_reason,
           COUNT( * ) AS total_row
      FROM zbom_stg_part
      WHERE upload_id IS NOT INITIAL AND upload_id <> ''
      GROUP BY upload_id, filename, erdat, ertim, ernam, status, approved_by, approved_at, reject_reason
      ORDER BY erdat DESCENDING, ertim DESCENDING
      INTO TABLE @lt_history.

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
  " 4. GET DETAIL UPLOAD BERDASARKAN UPLOAD_ID (FIX SINTAKS SQL: ASC)
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

      UPDATE zbom_stg_part
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
  " 6. LOGOUT
  " -------------------------------------------------------------------
  WHEN 'LOGOUT'.
    _m_response->redirect( url = '/sap/public/bc/icf/logoff' ).
    navigation->response_complete( ).

ENDCASE.