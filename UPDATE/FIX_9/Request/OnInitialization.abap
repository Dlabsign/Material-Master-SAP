DATA: lv_req_id        TYPE string,
      ls_header        TYPE zmdg_req_hdr,
      lt_detail_list   TYPE TABLE OF zmdg_req_dtl,
      gv_user_fullname TYPE string,
      ls_bapi_addr     TYPE bapiaddr3,
      lt_bapi_ret      TYPE TABLE OF bapiret2,
      lv_persnum       TYPE usr21-persnumber,
      lv_fname         TYPE adrp-name_first,
      lv_lname         TYPE adrp-name_last.

" Ambil Nama Depan & Nama Belakang dari Master User SAP (sy-uname)
CALL FUNCTION 'BAPI_USER_GET_DETAIL'
  EXPORTING
    username = sy-uname
  IMPORTING
    address  = ls_bapi_addr
  TABLES
    return   = lt_bapi_ret.

IF ls_bapi_addr-firstname IS NOT INITIAL OR ls_bapi_addr-lastname IS NOT INITIAL.
  CONCATENATE ls_bapi_addr-firstname ls_bapi_addr-lastname INTO gv_user_fullname SEPARATED BY space.
ELSEIF ls_bapi_addr-fullname IS NOT INITIAL.
  gv_user_fullname = ls_bapi_addr-fullname.
ELSE.
  " Fallback: Query tabel USR21 & ADRP
  SELECT SINGLE persnumber FROM usr21 INTO lv_persnum WHERE bname = sy-uname.
  IF sy-subrc = 0.
    SELECT SINGLE name_first name_last FROM adrp INTO (lv_fname, lv_lname) WHERE persnumber = lv_persnum.
    IF lv_fname IS NOT INITIAL OR lv_lname IS NOT INITIAL.
      CONCATENATE lv_fname lv_lname INTO gv_user_fullname SEPARATED BY space.
    ENDIF.
  ENDIF.
ENDIF.

IF gv_user_fullname IS INITIAL.
  gv_user_fullname = sy-uname.
ENDIF.

lv_req_id = request->get_form_field( 'req_id' ).

IF lv_req_id IS NOT INITIAL.
  " Baca data header dan detail dari database jika req_id dikirim
  SELECT SINGLE * FROM zmdg_req_hdr INTO ls_header WHERE req_no = lv_req_id.
  SELECT * FROM zmdg_req_dtl INTO TABLE lt_detail_list WHERE req_no = lv_req_id.
ENDIF.