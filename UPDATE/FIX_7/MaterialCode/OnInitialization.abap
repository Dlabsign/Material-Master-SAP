DATA: lv_req_id      TYPE string,
      header         TYPE zmdg_req_hdr,
      detail_list    TYPE TABLE OF zmdg_req_dtl,
      lv_action_init TYPE string.

lv_action_init = request->get_form_field( 'action' ).
IF lv_action_init IS INITIAL.
  lv_action_init = request->get_form_field( 'OnInputProcessing' ).
ENDIF.

lv_req_id = request->get_form_field( 'req_id' ).
IF lv_req_id IS INITIAL.
  lv_req_id = request->get_form_field( 'req_no' ).
ENDIF.

IF lv_req_id IS NOT INITIAL.
  " Baca data header dan detail dari database zmdg jika req_id dikirim
  SELECT SINGLE * FROM zmdg_req_hdr INTO @header WHERE req_no = @lv_req_id.
  SELECT * FROM zmdg_req_dtl INTO TABLE @detail_list WHERE req_no = @lv_req_id.
ENDIF.
