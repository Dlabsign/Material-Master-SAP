DATA: lv_req_id         TYPE string,
      header            TYPE zmdg_req_hdr,
      detail_list       TYPE TABLE OF zmdg_req_dtl,
      chg_header        TYPE zmdg_chg_hdr,
      chg_detail_list   TYPE TABLE OF zmdg_chg_dtl,
      lv_action_init    TYPE string,
      lv_auth_user      TYPE string,
      gv_user_fullname TYPE string,
      ls_bapi_addr     TYPE bapiaddr3,
      lt_bapi_ret      TYPE TABLE OF bapiret2,
      lv_persnum       TYPE usr21-persnumber,
      lv_fname         TYPE adrp-name_first,
      lv_lname         TYPE adrp-name_last.

lv_action_init = request->get_form_field( 'action' ).
IF lv_action_init IS INITIAL.
  lv_action_init = request->get_form_field( 'OnInputProcessing' ).
ENDIF.

lv_auth_user = sy-uname.
TRANSLATE lv_auth_user TO UPPER CASE.
CONDENSE lv_auth_user NO-GAPS.

IF lv_auth_user <> 'ABAPER04' AND lv_auth_user <> 'KMI-BOD' AND lv_auth_user <> 'KMI-U163'.
  IF lv_action_init IS NOT INITIAL.
    _m_response->set_status( code = 403 reason = 'Forbidden' ).
    _m_response->set_content_type( 'application/json' ).
    _m_response->set_cdata( '{"status":"ERROR","message":"Akses Terbatas: Anda tidak memiliki akses untuk masuk ke halaman ini, silahkan hubungi core tim."}' ).
    _m_navigation->response_complete( ).
    RETURN.
  ENDIF.
  RETURN.
ENDIF.

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
IF lv_req_id IS INITIAL.
  lv_req_id = request->get_form_field( 'req_no' ).
ENDIF.

IF lv_req_id IS NOT INITIAL.
  " Baca data header dan detail dari database zmdg jika req_id dikirim
  SELECT SINGLE * FROM zmdg_req_hdr INTO @header WHERE req_no = @lv_req_id.
  IF sy-subrc = 0.
    SELECT * FROM zmdg_req_dtl INTO TABLE @detail_list WHERE req_no = @lv_req_id.
  ELSE.
    SELECT SINGLE * FROM zmdg_chg_hdr INTO @chg_header WHERE chg_req_no = @lv_req_id.
    IF sy-subrc = 0.
      SELECT * FROM zmdg_chg_dtl INTO TABLE @chg_detail_list WHERE chg_req_no = @lv_req_id.
    ENDIF.
  ENDIF.
ENDIF.