*======================================================================*
* SAP BSP EVENT HANDLER: OnInitialization                              *
* Target BSP Page: history_rejected.htm                                *
*======================================================================*

TYPES: BEGIN OF ty_staging_list,
         req_no     TYPE string,
         remarks    TYPE string,
         req_date   TYPE string,
         req_time   TYPE string,
         requestor  TYPE string,
         status     TYPE string,
         total_item TYPE i,
         rej_reason TYPE string,
       END OF ty_staging_list.

DATA: lv_action_h  TYPE string,
      lt_hdr_rej   TYPE TABLE OF zmdg_req_hdr,
      ls_hdr_rej   TYPE zmdg_req_hdr,
      lt_list_rej  TYPE TABLE OF ty_staging_list,
      ls_list_rej  TYPE ty_staging_list,
      lv_json_rej  TYPE string,
      lv_req_no_h  TYPE zmdg_req_hdr-req_no,
      lt_dtl_h     TYPE TABLE OF zmdg_req_dtl.

IF sy-uname <> 'ABAPER04'.
  lv_action_h = request->get_form_field( 'action' ).
  IF lv_action_h IS INITIAL.
    lv_action_h = request->get_form_field( 'OnInputProcessing' ).
  ENDIF.
  IF lv_action_h IS NOT INITIAL.
    lv_json_rej = '{"status":"ERROR","message":"User cannot access this page."}'.
    _m_response->set_status( code = 403 reason = 'Forbidden' ).
    _m_response->set_content_type( 'application/json' ).
    _m_response->set_cdata( lv_json_rej ).
    _m_navigation->response_complete( ).
    RETURN.
  ENDIF.
ENDIF.

lv_action_h = request->get_form_field( 'action' ).
IF lv_action_h IS INITIAL.
  lv_action_h = request->get_form_field( 'OnInputProcessing' ).
ENDIF.
TRANSLATE lv_action_h TO UPPER CASE.

" 1. Handler AJAX GET_COUNTERS
IF lv_action_h = 'GET_COUNTERS'.
  DATA: lv_cnt_p TYPE i, lv_cnt_a TYPE i, lv_cnt_r TYPE i.
  SELECT COUNT( * ) FROM zmdg_req_hdr WHERE status IN ( 'CHECKED', 'CODED' ) INTO @lv_cnt_p.
  SELECT COUNT( * ) FROM zmdg_req_hdr WHERE status = 'APPROVED' INTO @lv_cnt_a.
  SELECT COUNT( * ) FROM zmdg_req_hdr WHERE status IN ( 'REJECTED', 'FAILED' ) INTO @lv_cnt_r.

  lv_json_rej = '{"pending":' && lv_cnt_p && ',"approved":' && lv_cnt_a && ',"rejected":' && lv_cnt_r && '}'.
  _m_response->set_content_type( 'application/json' ).
  _m_response->set_cdata( lv_json_rej ).
  _m_navigation->response_complete( ).
  RETURN.
ENDIF.

" 2. Handler AJAX GET_REJECTED_LIST
IF lv_action_h = 'GET_REJECTED_LIST'.
  CLEAR: lt_hdr_rej, lt_list_rej.
  SELECT * FROM zmdg_req_hdr
    INTO TABLE @lt_hdr_rej
    WHERE status = 'REJECTED' OR status = 'FAILED'
    ORDER BY req_date DESCENDING, req_time DESCENDING.

  LOOP AT lt_hdr_rej INTO ls_hdr_rej.
    CLEAR ls_list_rej.
    ls_list_rej-req_no     = CONV #( ls_hdr_rej-req_no ).
    ls_list_rej-remarks    = CONV #( ls_hdr_rej-remarks ).
    ls_list_rej-req_date   = CONV #( ls_hdr_rej-req_date ).
    ls_list_rej-req_time   = CONV #( ls_hdr_rej-req_time ).
    ls_list_rej-requestor  = CONV #( ls_hdr_rej-requestor ).
    ls_list_rej-status     = CONV #( ls_hdr_rej-status ).
    ls_list_rej-rej_reason = CONV #( ls_hdr_rej-rej_reason ).

    SELECT COUNT( * ) FROM zmdg_req_dtl WHERE req_no = @ls_hdr_rej-req_no INTO @ls_list_rej-total_item.
    APPEND ls_list_rej TO lt_list_rej.
  ENDLOOP.

  lv_json_rej = /ui2/cl_json=>serialize( data = lt_list_rej compress = 'X' pretty_name = /ui2/cl_json=>pretty_mode-low_case ).
  _m_response->set_content_type( 'application/json' ).
  _m_response->set_cdata( lv_json_rej ).
  _m_navigation->response_complete( ).
  RETURN.
ENDIF.

" 3. Handler AJAX GET_UPLOAD_DETAIL
IF lv_action_h = 'GET_UPLOAD_DETAIL'.
  lv_req_no_h = request->get_form_field( 'REQ_NO' ).
  IF lv_req_no_h IS INITIAL.
    lv_req_no_h = request->get_form_field( 'UPLOAD_ID' ).
  ENDIF.
  SELECT * FROM zmdg_req_dtl WHERE req_no = @lv_req_no_h INTO TABLE @lt_dtl_h.

  lv_json_rej = /ui2/cl_json=>serialize( data = lt_dtl_h compress = 'X' pretty_name = /ui2/cl_json=>pretty_mode-low_case ).
  _m_response->set_content_type( 'application/json' ).
  _m_response->set_cdata( lv_json_rej ).
  _m_navigation->response_complete( ).
  RETURN.
ENDIF.

" 4. Pre-load data saat halaman dibuka di browser
CLEAR: lt_hdr_rej, lt_list_rej.
SELECT * FROM zmdg_req_hdr
  INTO TABLE @lt_hdr_rej
  WHERE status = 'REJECTED' OR status = 'FAILED'
  ORDER BY req_date DESCENDING, req_time DESCENDING.

LOOP AT lt_hdr_rej INTO ls_hdr_rej.
  CLEAR ls_list_rej.
  ls_list_rej-req_no     = CONV #( ls_hdr_rej-req_no ).
  ls_list_rej-remarks    = CONV #( ls_hdr_rej-remarks ).
  ls_list_rej-req_date   = CONV #( ls_hdr_rej-req_date ).
  ls_list_rej-req_time   = CONV #( ls_hdr_rej-req_time ).
  ls_list_rej-requestor  = CONV #( ls_hdr_rej-requestor ).
  ls_list_rej-status     = CONV #( ls_hdr_rej-status ).
  ls_list_rej-rej_reason = CONV #( ls_hdr_rej-rej_reason ).

  SELECT COUNT( * ) FROM zmdg_req_dtl WHERE req_no = @ls_hdr_rej-req_no INTO @ls_list_rej-total_item.
  APPEND ls_list_rej TO lt_list_rej.
ENDLOOP.

lv_json_rej = /ui2/cl_json=>serialize( data = lt_list_rej compress = 'X' pretty_name = /ui2/cl_json=>pretty_mode-low_case ).
IF lv_json_rej IS INITIAL OR lv_json_rej = 'null'.
  lv_json_rej = '[]'.
ENDIF.