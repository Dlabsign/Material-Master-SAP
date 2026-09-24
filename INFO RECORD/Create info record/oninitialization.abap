*"----------------------------------------------------------------------*
*" BSP ONINITIALIZATION FOR INFO RECORD (ME11) CREATE REQUEST
*"----------------------------------------------------------------------*

DATA: lv_usr_bapi  TYPE bapiaddr3,
      lt_usr_ret   TYPE TABLE OF bapiret2,
      lv_usr_pers  TYPE usr21-persnumber,
      lv_usr_fn    TYPE adrp-name_first,
      lv_usr_ln    TYPE adrp-name_last,
      ls_hdr       TYPE zmdg_req_pir,
      lt_hdr       TYPE TABLE OF zmdg_req_pir,
      ls_hist      TYPE ty_history,
      lt_hist_tab  TYPE TABLE OF ty_history,
      ls_adt       TYPE zmdg_pir_adt,
      lt_adt_tmp   TYPE TABLE OF zmdg_pir_adt,
      lv_cnt       TYPE i.

gv_user_id = sy-uname.
gv_mandt   = sy-mandt.

" 1. Retrieve User Full Name
CALL FUNCTION 'BAPI_USER_GET_DETAIL'
  EXPORTING
    username = sy-uname
  IMPORTING
    address  = lv_usr_bapi
  TABLES
    return   = lt_usr_ret.

IF lv_usr_bapi-firstname IS NOT INITIAL OR
   lv_usr_bapi-lastname IS NOT INITIAL.
  CONCATENATE lv_usr_bapi-firstname lv_usr_bapi-lastname
    INTO gv_user_fullname SEPARATED BY space.
ELSEIF lv_usr_bapi-fullname IS NOT INITIAL.
  gv_user_fullname = lv_usr_bapi-fullname.
ELSE.
  SELECT SINGLE persnumber FROM usr21
    INTO lv_usr_pers WHERE bname = sy-uname.
  IF sy-subrc = 0.
    SELECT SINGLE name_first name_last FROM adrp
      INTO (lv_usr_fn, lv_usr_ln)
      WHERE persnumber = lv_usr_pers.
    IF lv_usr_fn IS NOT INITIAL OR lv_usr_ln IS NOT INITIAL.
      CONCATENATE lv_usr_fn lv_usr_ln
        INTO gv_user_fullname SEPARATED BY space.
    ENDIF.
  ENDIF.
ENDIF.

IF gv_user_fullname IS INITIAL.
  gv_user_fullname = sy-uname.
ENDIF.

" 2. Populate Initial History Data for Current User
CLEAR: lt_hist_tab, gt_history.
SELECT * FROM zmdg_req_pir INTO TABLE lt_hdr
  WHERE ernam = sy-uname.

SORT lt_hdr BY erdat DESCENDING erzet DESCENDING.

DATA: lv_vname_init TYPE name1_gp,
      lv_date_fmt   TYPE string.

LOOP AT lt_hdr INTO ls_hdr.
  CLEAR ls_hist.
  ls_hist-req_id     = ls_hdr-req_id.
  ls_hist-lifnr      = ls_hdr-lifnr.

  IF ls_hdr-lifnr IS NOT INITIAL.
    CLEAR lv_vname_init.
    DATA: lv_valpha_init TYPE lifnr.
    lv_valpha_init = ls_hdr-lifnr.
    IF lv_valpha_init IS NOT INITIAL AND lv_valpha_init CO '0123456789 '.
      UNPACK ls_hdr-lifnr TO lv_valpha_init.
    ENDIF.
    SELECT SINGLE name1 FROM lfa1 INTO lv_vname_init
      WHERE lifnr = ls_hdr-lifnr OR lifnr = lv_valpha_init.
    ls_hist-lifnr_name = lv_vname_init.
  ENDIF.

  ls_hist-matnr      = ls_hdr-matnr.
  ls_hist-txz01      = ls_hdr-txz01.

  IF ls_hdr-erdat IS NOT INITIAL.
    CONCATENATE ls_hdr-erdat+6(2) '.' ls_hdr-erdat+4(2) '.' ls_hdr-erdat(4) INTO lv_date_fmt.
    ls_hist-erdat    = lv_date_fmt.
  ELSE.
    ls_hist-erdat    = ''.
  ENDIF.

  ls_hist-erzet      = ls_hdr-erzet.
  ls_hist-ernam      = ls_hdr-ernam.
  ls_hist-ernam_name = gv_user_fullname.
  ls_hist-status     = ls_hdr-status.

  CASE ls_hdr-status.
    WHEN '00'. ls_hist-status_desc = 'Draft'.
    WHEN '01'. ls_hist-status_desc = 'Submitted / In Review'.
    WHEN '02'. ls_hist-status_desc = 'Approved'.
    WHEN '03'. ls_hist-status_desc = 'Rejected'.
    WHEN '04'. ls_hist-status_desc = 'Posted to SAP'.
    WHEN OTHERS. ls_hist-status_desc = 'In Progress'.
  ENDCASE.

  " Count items
  SELECT COUNT( * ) FROM zmdg_pir_itm
    INTO lv_cnt WHERE req_id = ls_hdr-req_id.
  ls_hist-item_count = lv_cnt.

  " Get latest audit comment
  SELECT * FROM zmdg_pir_adt INTO TABLE lt_adt_tmp
    WHERE req_id = ls_hdr-req_id.
  SORT lt_adt_tmp BY log_id DESCENDING.
  READ TABLE lt_adt_tmp INTO ls_adt INDEX 1.
  IF sy-subrc = 0.
    ls_hist-comments = ls_adt-comments.
  ENDIF.

  APPEND ls_hist TO lt_hist_tab.
ENDLOOP.

" Convert History Table to JSON String for Page Attribute
TRY.
    gt_history = /ui2/cl_json=>serialize(
      data        = lt_hist_tab
      compress    = 'X'
      pretty_name = /ui2/cl_json=>pretty_mode-low_case
    ).
  CATCH cx_root.
    gt_history = '[]'.
ENDTRY.
