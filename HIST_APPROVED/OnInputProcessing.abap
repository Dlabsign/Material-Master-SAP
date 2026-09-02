*======================================================================*
* SAP BSP EVENT HANDLER: OnInputProcessing                            *
* Target BSP Page: history_approved.htm                                *
*======================================================================*

TYPES: BEGIN OF ty_staging_list,
         req_no     TYPE string,
         remarks    TYPE string,
         sub_reason TYPE string,
         req_date   TYPE string,
         req_time   TYPE string,
         requestor  TYPE string,
         status     TYPE string,
         total_item TYPE i,
         rej_reason TYPE string,
       END OF ty_staging_list.

DATA: lv_action_ha TYPE string,
      lt_hdr_app   TYPE TABLE OF zmdg_req_hdr,
      ls_hdr_app   TYPE zmdg_req_hdr,
      lt_list_app  TYPE TABLE OF ty_staging_list,
      ls_list_app  TYPE ty_staging_list,
      lv_json_app  TYPE string,
      lv_req_no_ha TYPE zmdg_req_hdr-req_no,
      lt_dtl_ha    TYPE TABLE OF zmdg_req_dtl.

IF sy-uname <> 'ABAPER04'.
  lv_action_ha = request->get_form_field( 'action' ).
  IF lv_action_ha IS INITIAL.
    lv_action_ha = request->get_form_field( 'OnInputProcessing' ).
  ENDIF.
  IF lv_action_ha IS NOT INITIAL.
    lv_json_app = '{"status":"ERROR","message":"User cannot access this page."}'.
    _m_response->set_status( code = 403 reason = 'Forbidden' ).
    _m_response->set_content_type( 'application/json' ).
    _m_response->set_cdata( lv_json_app ).
    _m_navigation->response_complete( ).
    RETURN.
  ENDIF.
ENDIF.

lv_action_ha = request->get_form_field( 'action' ).
IF lv_action_ha IS INITIAL.
  lv_action_ha = request->get_form_field( 'OnInputProcessing' ).
ENDIF.
TRANSLATE lv_action_ha TO UPPER CASE.

IF lv_action_ha IS NOT INITIAL.

  CASE lv_action_ha.

    " ------------------------------------------------------------------
    " 1. GET COUNTERS FOR SIDEBAR BADGES
    " ------------------------------------------------------------------
    WHEN 'GET_COUNTERS'.
      DATA: lv_cnt_p TYPE i, lv_cnt_a TYPE i, lv_cnt_r TYPE i, lv_json_cnt TYPE string.
      SELECT COUNT( * ) FROM zmdg_req_hdr WHERE status IN ( 'CHECKED', 'CODED' ) INTO @lv_cnt_p.
      SELECT COUNT( * ) FROM zmdg_req_hdr WHERE status = 'APPROVED' INTO @lv_cnt_a.
      SELECT COUNT( * ) FROM zmdg_req_hdr WHERE status IN ( 'REJECTED', 'FAILED' ) INTO @lv_cnt_r.

      lv_json_cnt = '{"pending":' && lv_cnt_p && ',"approved":' && lv_cnt_a && ',"rejected":' && lv_cnt_r && '}'.
      _m_response->set_content_type( 'application/json' ).
      _m_response->set_cdata( lv_json_cnt ).
      _m_navigation->response_complete( ).
      RETURN.

    " ------------------------------------------------------------------
    " 2. GET APPROVED REQUEST LIST
    " ------------------------------------------------------------------
    WHEN 'GET_APPROVED_LIST'.
      CLEAR: lt_hdr_app, lt_list_app.
      SELECT * FROM zmdg_req_hdr
        INTO TABLE @lt_hdr_app
        WHERE status = 'APPROVED'
        ORDER BY req_date DESCENDING, req_time DESCENDING.

      LOOP AT lt_hdr_app INTO ls_hdr_app.
        CLEAR ls_list_app.
        ls_list_app-req_no     = CONV #( ls_hdr_app-req_no ).
        ls_list_app-remarks    = CONV #( ls_hdr_app-remarks ).
        ls_list_app-sub_reason = CONV #( ls_hdr_app-sub_reason ).
        ls_list_app-req_date   = CONV #( ls_hdr_app-req_date ).
        ls_list_app-req_time   = CONV #( ls_hdr_app-req_time ).
        ls_list_app-requestor  = CONV #( ls_hdr_app-requestor ).
        ls_list_app-status     = CONV #( ls_hdr_app-status ).
        ls_list_app-rej_reason = CONV #( ls_hdr_app-rej_reason ).

        SELECT COUNT( * ) FROM zmdg_req_dtl WHERE req_no = @ls_hdr_app-req_no INTO @ls_list_app-total_item.
        APPEND ls_list_app TO lt_list_app.
      ENDLOOP.

      lv_json_app = /ui2/cl_json=>serialize( data = lt_list_app compress = 'X' pretty_name = /ui2/cl_json=>pretty_mode-low_case ).
      _m_response->set_content_type( 'application/json' ).
      _m_response->set_cdata( lv_json_app ).
      _m_navigation->response_complete( ).
      RETURN.

    " ------------------------------------------------------------------
    " 3. GET UPLOAD DETAIL
    " ------------------------------------------------------------------
    WHEN 'GET_UPLOAD_DETAIL'.
      lv_req_no_ha = request->get_form_field( 'REQ_NO' ).
      IF lv_req_no_ha IS INITIAL.
        lv_req_no_ha = request->get_form_field( 'UPLOAD_ID' ).
      ENDIF.
      SELECT * FROM zmdg_req_dtl WHERE req_no = @lv_req_no_ha INTO TABLE @lt_dtl_ha.

      lv_json_app = /ui2/cl_json=>serialize( data = lt_dtl_ha compress = 'X' pretty_name = /ui2/cl_json=>pretty_mode-low_case ).
      _m_response->set_content_type( 'application/json' ).
      _m_response->set_cdata( lv_json_app ).
      _m_navigation->response_complete( ).
      RETURN.

    WHEN 'LOGOUT'.
      _m_navigation->exit( ).
      RETURN.

  ENDCASE.

ENDIF.