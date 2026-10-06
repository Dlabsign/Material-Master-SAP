DATA: lv_req_id      TYPE string,
      ls_header      TYPE zmdg_req_hdr,
      lt_detail_list TYPE TABLE OF zmdg_req_dtl.

lv_req_id = request->get_form_field( 'req_id' ).

IF lv_req_id IS NOT INITIAL.
  " Baca data header dan detail dari database jika req_id dikirim
  SELECT SINGLE * FROM zmdg_req_hdr INTO ls_header WHERE req_no = lv_req_id.
  SELECT * FROM zmdg_req_dtl INTO TABLE lt_detail_list WHERE req_no = lv_req_id.
ENDIF.