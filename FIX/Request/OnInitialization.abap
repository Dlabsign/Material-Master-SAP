DATA: lv_req_id TYPE string.

lv_req_id = request->get_form_field( 'req_id' ).

IF lv_req_id IS INITIAL.
  req_id = |REQ-{ sy-datum }-{ sy-uzeit }|.
ELSE.
  req_id = lv_req_id.

  " Baca data header dan detail dari database jika req_id dikirim
  SELECT SINGLE * FROM zmdg_req_hdr INTO @header WHERE req_no = @req_id.
  SELECT * FROM zmdg_req_dtl INTO TABLE @detail_list WHERE req_no = @req_id.
ENDIF.