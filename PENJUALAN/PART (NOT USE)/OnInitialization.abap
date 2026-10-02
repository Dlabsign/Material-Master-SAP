DATA: lv_req_id        TYPE string,
      ls_header        TYPE zmdg_stg_hdr,
      lt_detail_list   TYPE TABLE OF zmdg_stg_part,
      gv_user_fullname TYPE string,
      ls_bapi_addr     TYPE bapiaddr3,
      lt_bapi_ret      TYPE TABLE OF bapiret2,
      lv_persnum       TYPE usr21-persnumber,
      lv_fname         TYPE adrp-name_first,
      lv_lname         TYPE adrp-name_last.

TYPES: BEGIN OF ty_drop_item,
         code TYPE string,
         text TYPE string,
       END OF ty_drop_item.

TYPES: BEGIN OF ty_lgort_item,
         werks TYPE string,
         code  TYPE string,
         text  TYPE string,
       END OF ty_lgort_item.

TYPES: BEGIN OF ty_sap_dropdowns,
         mtart TYPE TABLE OF ty_drop_item WITH DEFAULT KEY,
         matkl TYPE TABLE OF ty_drop_item WITH DEFAULT KEY,
         ekorg TYPE TABLE OF ty_drop_item WITH DEFAULT KEY,
         ekgrp TYPE TABLE OF ty_drop_item WITH DEFAULT KEY,
         werks TYPE TABLE OF ty_drop_item WITH DEFAULT KEY,
         meins TYPE TABLE OF ty_drop_item WITH DEFAULT KEY,
         lgort TYPE TABLE OF ty_lgort_item WITH DEFAULT KEY,
       END OF ty_sap_dropdowns.

DATA: ls_dropdowns TYPE ty_sap_dropdowns.

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

" ------------------------------------------------------------------
" FETCH SAP DROPDOWN DATA FROM SAP MASTER TABLES
" ------------------------------------------------------------------
" 1. Material Type (T134T)
SELECT mtart AS code, mtbez AS text
  FROM t134t
  INTO TABLE @ls_dropdowns-mtart
  WHERE spras = @sy-langu
  ORDER BY mtart.

IF ls_dropdowns-mtart IS INITIAL.
  SELECT mtart AS code, mtbez AS text
    FROM t134t
    INTO TABLE @ls_dropdowns-mtart
    WHERE spras = 'E' OR spras = 'I'
    ORDER BY mtart.
ENDIF.

" 2. Material Group (T023T)
SELECT matkl AS code, wgbez AS text
  FROM t023t
  INTO TABLE @ls_dropdowns-matkl
  WHERE spras = @sy-langu
  ORDER BY matkl.

IF ls_dropdowns-matkl IS INITIAL.
  SELECT matkl AS code, wgbez AS text
    FROM t023t
    INTO TABLE @ls_dropdowns-matkl
    WHERE spras = 'E' OR spras = 'I'
    ORDER BY matkl.
ENDIF.

" 3. Purchasing Org (T024E) & Purchasing Group (T024)
SELECT ekorg AS code, ekotx AS text
  FROM t024e
  INTO TABLE @ls_dropdowns-ekorg
  ORDER BY ekorg.

SELECT ekgrp AS code, eknam AS text
  FROM t024
  INTO TABLE @ls_dropdowns-ekgrp
  ORDER BY ekgrp.

" 4. Plant (T001W)
SELECT werks AS code, name1 AS text
  FROM t001w
  INTO TABLE @ls_dropdowns-werks
  ORDER BY werks.

" 5. UoM (T006A)
DATA: lt_t006a    TYPE TABLE OF t006a,
      ls_t006a    TYPE t006a,
      ls_uom_item TYPE ty_drop_item.

SELECT * FROM t006a
  INTO TABLE @lt_t006a
  WHERE spras = @sy-langu
  ORDER BY msehi.

IF lt_t006a IS INITIAL.
  SELECT * FROM t006a
    INTO TABLE @lt_t006a
    WHERE spras = 'E' OR spras = 'I'
    ORDER BY msehi.
ENDIF.

LOOP AT lt_t006a INTO ls_t006a.
  CLEAR ls_uom_item.
  IF ls_t006a-mseh3 IS NOT INITIAL.
    ls_uom_item-code = ls_t006a-mseh3.
  ELSEIF ls_t006a-mseh6 IS NOT INITIAL.
    ls_uom_item-code = ls_t006a-mseh6.
  ELSE.
    ls_uom_item-code = ls_t006a-msehi.
  ENDIF.
  ls_uom_item-text = ls_t006a-mseht.
  IF ls_uom_item-code IS NOT INITIAL.
    READ TABLE ls_dropdowns-meins WITH KEY code = ls_uom_item-code TRANSPORTING NO FIELDS.
    IF sy-subrc <> 0.
      APPEND ls_uom_item TO ls_dropdowns-meins.
    ENDIF.
  ENDIF.
ENDLOOP.

" 6. Storage Location (T001L)
SELECT werks, lgort AS code, lgobe AS text
  FROM t001l
  INTO TABLE @ls_dropdowns-lgort
  ORDER BY werks, lgort.

" Serialize dropdowns to JSON
gv_sap_dropdowns_json = /ui2/cl_json=>serialize(
  data        = ls_dropdowns
  compress    = 'X'
  pretty_name = /ui2/cl_json=>pretty_mode-low_case ).

lv_req_id = request->get_form_field( 'req_id' ).

IF lv_req_id IS NOT INITIAL.
  " Baca data header dan detail dari database jika req_id dikirim
  SELECT SINGLE * FROM zmdg_stg_hdr INTO ls_header WHERE req_no = lv_req_id.
  SELECT * FROM zmdg_stg_part INTO TABLE lt_detail_list WHERE req_no = lv_req_id.
ENDIF.