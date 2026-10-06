*======================================================================*
* SAP BSP EVENT HANDLER: OnInitialization                              *
* Target BSP Page: history_approved.htm                                *
* Application: MDG Unified History Log (MM & BP)                       *
*======================================================================*

TYPES: BEGIN OF ty_history_item,
         module_type   TYPE string,
         req_no        TYPE string,
         status        TYPE string,
         req_date      TYPE string,
         req_time      TYPE string,
         requestor     TYPE string,
         remarks       TYPE string,
         sub_reason    TYPE string,
         rej_reason    TYPE string,
         total_item    TYPE i,
         matnr_gen     TYPE string,
         maktx_desc    TYPE string,
         bp_number     TYPE string,
         bp_category   TYPE string,
         bp_role       TYPE string,
         name1         TYPE string,
         name2         TYPE string,
         search_term   TYPE string,
         street        TYPE string,
         house_num     TYPE string,
         city          TYPE string,
         postal_code   TYPE string,
         country       TYPE string,
         region        TYPE string,
         telephone     TYPE string,
         email         TYPE string,
         tax_num       TYPE string,
         banks         TYPE string,
         bankl         TYPE string,
         bankn         TYPE string,
         koinh         TYPE string,
         bank_name     TYPE string,
         bukrs         TYPE string,
         akont         TYPE string,
         zterm         TYPE string,
         waers         TYPE string,
         stw_data_by   TYPE string,
         stw_data_note TYPE string,
         stw_bank_by   TYPE string,
         stw_bank_note TYPE string,
         appr_final_by TYPE string,
         appr_final_at TYPE string,
       END OF ty_history_item.

DATA: lv_action_ha   TYPE string,
      lv_status_flt  TYPE string,
      lt_history     TYPE TABLE OF ty_history_item,
      ls_item        TYPE ty_history_item,
      lt_hdr         TYPE TABLE OF zmdg_req_hdr,
      ls_hdr         TYPE zmdg_req_hdr,
      lt_dtl_temp    TYPE TABLE OF zmdg_req_dtl,
      ls_dtl_temp    TYPE zmdg_req_dtl,
      lt_bp_db       TYPE TABLE OF zmdg_bp_req,
      ls_bp_db       TYPE zmdg_bp_req,
      lv_codes_str   TYPE string,
      lv_maktx_str   TYPE string,
      lv_clean_mat   TYPE string,
      lv_bp_date     TYPE d,
      lv_bp_time     TYPE t,
      lv_json_res    TYPE string,
      lv_req_no_ha   TYPE zmdg_req_hdr-req_no,
      lt_dtl_ha      TYPE TABLE OF zmdg_req_dtl,
      lv_cnt_mat_p   TYPE i,
      lv_cnt_bp_p    TYPE i,
      lv_cnt_p       TYPE i,
      lv_cnt_mat_a   TYPE i,
      lv_cnt_bp_a    TYPE i,
      lv_cnt_a       TYPE i,
      lv_cnt_mat_r   TYPE i,
      lv_cnt_bp_r    TYPE i,
      lv_cnt_r       TYPE i,
      lv_cnt_draft   TYPE i,
      lv_cnt_total   TYPE i.

IF sy-uname <> 'ABAPER04'.
  lv_action_ha = request->get_form_field( 'action' ).
  IF lv_action_ha IS INITIAL.
    lv_action_ha = request->get_form_field( 'OnInputProcessing' ).
  ENDIF.
  IF lv_action_ha IS NOT INITIAL.
    lv_json_res = '{"status":"ERROR","message":"Forbidden"}'.
    _m_response->set_status( code = 403 reason = 'Forbidden' ).
    _m_response->set_content_type( 'application/json' ).
    _m_response->set_cdata( lv_json_res ).
    _m_navigation->response_complete( ).
    RETURN.
  ENDIF.
ENDIF.

lv_action_ha = request->get_form_field( 'action' ).
IF lv_action_ha IS INITIAL.
  lv_action_ha = request->get_form_field( 'OnInputProcessing' ).
ENDIF.
TRANSLATE lv_action_ha TO UPPER CASE.

" 1. Handler AJAX: GET_COUNTERS
IF lv_action_ha = 'GET_COUNTERS'.
  SELECT COUNT( * ) FROM zmdg_req_hdr
    WHERE status IN ( 'CHECKED', 'CODED' )
    INTO @lv_cnt_mat_p.

  SELECT COUNT( * ) FROM zmdg_bp_req
    WHERE status = 'CHECKED'
      AND stw_data_status = 'X'
      AND stw_bank_status = 'X'
    INTO @lv_cnt_bp_p.
  lv_cnt_p = lv_cnt_mat_p + lv_cnt_bp_p.

  SELECT COUNT( * ) FROM zmdg_req_hdr
    WHERE status = 'APPROVED'
    INTO @lv_cnt_mat_a.

  SELECT COUNT( * ) FROM zmdg_bp_req
    WHERE status = 'APPROVED'
    INTO @lv_cnt_bp_a.
  lv_cnt_a = lv_cnt_mat_a + lv_cnt_bp_a.

  SELECT COUNT( * ) FROM zmdg_req_hdr
    WHERE status IN ( 'REJECTED', 'FAILED' )
    INTO @lv_cnt_mat_r.

  SELECT COUNT( * ) FROM zmdg_bp_req
    WHERE status IN ( 'REJECTED', 'FAILED' )
    INTO @lv_cnt_bp_r.
  lv_cnt_r = lv_cnt_mat_r + lv_cnt_bp_r.

  SELECT COUNT( * ) FROM zmdg_req_hdr
    WHERE status = 'DRAFT' OR status IS INITIAL OR status = ''
    INTO @lv_cnt_draft.
  lv_cnt_total = lv_cnt_a + lv_cnt_r.

  lv_json_res = '{"pending":' && lv_cnt_p &&
                ',"mat_pending":' && lv_cnt_mat_p &&
                ',"bp_pending":' && lv_cnt_bp_p &&
                ',"approved":' && lv_cnt_a &&
                ',"mat_approved":' && lv_cnt_mat_a &&
                ',"bp_approved":' && lv_cnt_bp_a &&
                ',"rejected":' && lv_cnt_r &&
                ',"mat_rejected":' && lv_cnt_mat_r &&
                ',"bp_rejected":' && lv_cnt_bp_r &&
                ',"draft":' && lv_cnt_draft &&
                ',"total_history":' && lv_cnt_total && '}'.

  _m_response->set_content_type( 'application/json' ).
  _m_response->set_cdata( lv_json_res ).
  _m_navigation->response_complete( ).
  RETURN.
ENDIF.

" 2. Handler AJAX: GET_HISTORY_LIST / GET_APPROVED_LIST / GET_REJECTED_LIST
IF lv_action_ha = 'GET_HISTORY_LIST' OR
   lv_action_ha = 'GET_APPROVED_LIST' OR
   lv_action_ha = 'GET_REJECTED_LIST'.

  lv_status_flt = request->get_form_field( 'status' ).
  TRANSLATE lv_status_flt TO UPPER CASE.

  IF lv_action_ha = 'GET_APPROVED_LIST' AND lv_status_flt IS INITIAL.
    lv_status_flt = 'APPROVED'.
  ELSEIF lv_action_ha = 'GET_REJECTED_LIST' AND lv_status_flt IS INITIAL.
    lv_status_flt = 'REJECTED'.
  ENDIF.
  IF lv_status_flt IS INITIAL.
    lv_status_flt = 'ALL'.
  ENDIF.

  CLEAR: lt_history, lt_hdr, lt_bp_db.

  " MM Records
  IF lv_status_flt = 'APPROVED'.
    SELECT * FROM zmdg_req_hdr
      INTO TABLE @lt_hdr
      WHERE status = 'APPROVED'
      ORDER BY req_date DESCENDING, req_time DESCENDING.
  ELSEIF lv_status_flt = 'REJECTED'.
    SELECT * FROM zmdg_req_hdr
      INTO TABLE @lt_hdr
      WHERE status IN ( 'REJECTED', 'FAILED' )
      ORDER BY req_date DESCENDING, req_time DESCENDING.
  ELSE.
    SELECT * FROM zmdg_req_hdr
      INTO TABLE @lt_hdr
      WHERE status IN ( 'APPROVED', 'REJECTED', 'FAILED' )
      ORDER BY req_date DESCENDING, req_time DESCENDING.
  ENDIF.

  LOOP AT lt_hdr INTO ls_hdr.
    CLEAR ls_item.
    ls_item-module_type = 'MM'.
    ls_item-req_no      = CONV #( ls_hdr-req_no ).
    ls_item-status      = CONV #( ls_hdr-status ).
    ls_item-req_date    = CONV #( ls_hdr-req_date ).
    ls_item-req_time    = CONV #( ls_hdr-req_time ).
    ls_item-requestor   = CONV #( ls_hdr-requestor ).
    ls_item-remarks     = CONV #( ls_hdr-remarks ).
    ls_item-sub_reason    = CONV #( ls_hdr-sub_reason ).
    ls_item-rej_reason    = CONV #( ls_hdr-rej_reason ).
    ls_item-appr_final_by = CONV #( ls_hdr-approver ).
    IF ls_hdr-app_date IS NOT INITIAL.
      ls_item-appr_final_at = |{ ls_hdr-app_date+6(2) }/{ ls_hdr-app_date+4(2) }/{ ls_hdr-app_date+0(4) }|.
    ENDIF.

    SELECT COUNT( * ) FROM zmdg_req_dtl
      WHERE req_no = @ls_hdr-req_no INTO @ls_item-total_item.

    CLEAR: lt_dtl_temp, lv_codes_str, lv_maktx_str.
    SELECT * FROM zmdg_req_dtl
      WHERE req_no = @ls_hdr-req_no INTO TABLE @lt_dtl_temp.
    LOOP AT lt_dtl_temp INTO ls_dtl_temp.
      IF ls_dtl_temp-maktx IS NOT INITIAL.
        IF lv_maktx_str IS INITIAL.
          lv_maktx_str = ls_dtl_temp-maktx.
        ELSE.
          lv_maktx_str = lv_maktx_str && ', ' && ls_dtl_temp-maktx.
        ENDIF.
      ENDIF.
      IF ls_dtl_temp-matnr_ext IS NOT INITIAL.
        lv_clean_mat = ls_dtl_temp-matnr_ext.
        SHIFT lv_clean_mat LEFT DELETING LEADING '0'.
        IF lv_clean_mat IS INITIAL.
          lv_clean_mat = '0'.
        ENDIF.
        IF lv_codes_str IS INITIAL.
          lv_codes_str = lv_clean_mat.
        ELSE.
          lv_codes_str = lv_codes_str && ', ' && lv_clean_mat.
        ENDIF.
      ENDIF.
    ENDLOOP.
    ls_item-matnr_gen  = lv_codes_str.
    ls_item-maktx_desc = lv_maktx_str.

    APPEND ls_item TO lt_history.
  ENDLOOP.

  " BP Records
  IF lv_status_flt = 'APPROVED'.
    SELECT * FROM zmdg_bp_req
      INTO TABLE @lt_bp_db
      WHERE status = 'APPROVED'
      ORDER BY req_id DESCENDING.
  ELSEIF lv_status_flt = 'REJECTED'.
    SELECT * FROM zmdg_bp_req
      INTO TABLE @lt_bp_db
      WHERE status IN ( 'REJECTED', 'FAILED' )
      ORDER BY req_id DESCENDING.
  ELSE.
    SELECT * FROM zmdg_bp_req
      INTO TABLE @lt_bp_db
      WHERE status IN ( 'APPROVED', 'REJECTED', 'FAILED' )
      ORDER BY req_id DESCENDING.
  ENDIF.

  LOOP AT lt_bp_db INTO ls_bp_db.
    CLEAR ls_item.
    ls_item-module_type   = 'BP'.
    ls_item-req_no        = CONV #( ls_bp_db-req_id ).
    ls_item-status        = CONV #( ls_bp_db-status ).
    ls_item-bp_number     = CONV #( ls_bp_db-bp_number ).
    ls_item-bp_category   = CONV #( ls_bp_db-bp_category ).
    ls_item-bp_role       = CONV #( ls_bp_db-bp_role ).
    ls_item-name1         = CONV #( ls_bp_db-name1 ).
    ls_item-name2         = CONV #( ls_bp_db-name2 ).
    ls_item-search_term   = CONV #( ls_bp_db-search_term ).
    ls_item-street        = CONV #( ls_bp_db-street ).
    ls_item-house_num     = CONV #( ls_bp_db-house_num ).
    ls_item-city          = CONV #( ls_bp_db-city ).
    ls_item-postal_code   = CONV #( ls_bp_db-postal_code ).
    ls_item-country       = CONV #( ls_bp_db-country ).
    ls_item-region        = CONV #( ls_bp_db-region ).
    ls_item-telephone     = CONV #( ls_bp_db-telephone ).
    ls_item-email         = CONV #( ls_bp_db-email ).
    ls_item-tax_num       = CONV #( ls_bp_db-tax_num ).
    ls_item-banks         = CONV #( ls_bp_db-banks ).
    ls_item-bankl         = CONV #( ls_bp_db-bankl ).
    ls_item-bankn         = CONV #( ls_bp_db-bankn ).
    ls_item-koinh         = CONV #( ls_bp_db-koinh ).
    ls_item-bank_name     = CONV #( ls_bp_db-bank_name ).
    ls_item-bukrs         = CONV #( ls_bp_db-bukrs ).
    ls_item-akont         = CONV #( ls_bp_db-akont ).
    ls_item-zterm         = CONV #( ls_bp_db-zterm ).
    ls_item-waers         = CONV #( ls_bp_db-waers ).
    ls_item-rej_reason    = CONV #( ls_bp_db-rejection_reason ).
    ls_item-remarks       = CONV #( ls_bp_db-name1 ).
    ls_item-sub_reason    = |BP: { ls_bp_db-name1 } ({ ls_bp_db-search_term })|.
    ls_item-requestor     = CONV #( ls_bp_db-created_by ).
    ls_item-total_item    = 1.
    ls_item-stw_data_by   = CONV #( ls_bp_db-stw_data_by ).
    ls_item-stw_data_note = CONV #( ls_bp_db-stw_data_note ).
    ls_item-stw_bank_by   = CONV #( ls_bp_db-stw_bank_by ).
    ls_item-stw_bank_note = CONV #( ls_bp_db-stw_bank_note ).
    ls_item-appr_final_by = CONV #( ls_bp_db-appr_final_by ).
    ls_item-appr_final_at = CONV #( ls_bp_db-appr_final_at ).

    IF ls_bp_db-created_at IS NOT INITIAL.
      CONVERT TIME STAMP ls_bp_db-created_at TIME ZONE sy-zonlo
        INTO DATE lv_bp_date TIME lv_bp_time.
      ls_item-req_date = lv_bp_date.
      ls_item-req_time = lv_bp_time.
    ELSE.
      ls_item-req_date = sy-datum.
      ls_item-req_time = sy-uzeit.
    ENDIF.

    APPEND ls_item TO lt_history.
  ENDLOOP.

  lv_json_res = /ui2/cl_json=>serialize(
    data        = lt_history
    compress    = 'X'
    pretty_name = /ui2/cl_json=>pretty_mode-low_case ).

  _m_response->set_content_type( 'application/json' ).
  _m_response->set_cdata( lv_json_res ).
  _m_navigation->response_complete( ).
  RETURN.
ENDIF.

" 3. Handler AJAX: GET_UPLOAD_DETAIL (for Material Master items)
IF lv_action_ha = 'GET_UPLOAD_DETAIL'.
  lv_req_no_ha = request->get_form_field( 'REQ_NO' ).
  IF lv_req_no_ha IS INITIAL.
    lv_req_no_ha = request->get_form_field( 'UPLOAD_ID' ).
  ENDIF.
  SELECT * FROM zmdg_req_dtl
    WHERE req_no = @lv_req_no_ha INTO TABLE @lt_dtl_ha.

  lv_json_res = /ui2/cl_json=>serialize(
    data        = lt_dtl_ha
    compress    = 'X'
    pretty_name = /ui2/cl_json=>pretty_mode-low_case ).

  _m_response->set_content_type( 'application/json' ).
  _m_response->set_cdata( lv_json_res ).
  _m_navigation->response_complete( ).
  RETURN.
ENDIF.