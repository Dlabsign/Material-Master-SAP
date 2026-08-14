*======================================================================*
* SAP BSP EVENT HANDLER: OnInputProcessing                             *
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

lv_action_h = request->get_form_field( 'OnInputProcessing' ).
IF lv_action_h IS INITIAL.
  lv_action_h = request->get_form_field( 'action' ).
ENDIF.
TRANSLATE lv_action_h TO UPPER CASE.

" 1. Handler AJAX GET_REJECTED_LIST
IF lv_action_h = 'GET_REJECTED_LIST'.
  CLEAR: lt_hdr_rej, lt_list_rej.
  SELECT * FROM zmdg_req_hdr
    INTO TABLE @lt_hdr_rej
    WHERE status = 'REJECTED' OR status = 'FAILED'
    ORDER BY app_date DESCENDING, app_time DESCENDING, req_date DESCENDING.

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

" 2. Handler AJAX GET_UPLOAD_DETAIL
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
