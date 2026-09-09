*&---------------------------------------------------------------------*
*& BSP Page: REQUEST_CHANGE.HTM - Event Handler: OnInitialization
*& Module  : SAP Master Data Governance (MDG) - Request Change Material
*& Author  : Master Data Governance Team
*& System  : SAP S/4HANA 1809 On-Premise
*&---------------------------------------------------------------------*

DATA: lv_req_id      TYPE string,
      lv_matnr_param TYPE string,
      ls_chg_hdr     TYPE zmdg_chg_hdr,
      lt_chg_dtl     TYPE TABLE OF zmdg_chg_dtl,
      ls_chg_dtl     TYPE zmdg_chg_dtl.

DATA: lv_user_name   TYPE string,
      lv_curr_date   TYPE string,
      lv_curr_time   TYPE string.

" Ambil parameter URL jika ada
lv_req_id      = request->get_form_field( 'req_id' ).
lv_matnr_param = request->get_form_field( 'matnr' ).

lv_user_name = sy-uname.
lv_curr_date = |{ sy-datum+6(2) }.{ sy-datum+4(2) }.{ sy-datum(4) }|.
lv_curr_time = |{ sy-uzeit(2) }:{ sy-uzeit+2(2) }:{ sy-uzeit+4(2) }|.

" 1. Jika membawa nomor permohonan perubahan (req_id)
IF lv_req_id IS NOT INITIAL.
  SELECT SINGLE * FROM zmdg_chg_hdr
    INTO CORRESPONDING FIELDS OF @ls_chg_hdr
    WHERE chg_req_no = @lv_req_id.

  IF sy-subrc = 0.
    SELECT * FROM zmdg_chg_dtl
      INTO CORRESPONDING FIELDS OF TABLE @lt_chg_dtl
      WHERE chg_req_no = @lv_req_id
      ORDER BY item_no ASCENDING.
  ENDIF.
ENDIF.

" 2. Jika membawa nomor material langsung dari query parameter
IF lv_matnr_param IS NOT INITIAL AND ls_chg_hdr IS INITIAL.
  DATA: lv_matnr_conv TYPE mara-matnr.
  lv_matnr_conv = lv_matnr_param.

  IF lv_matnr_conv CO '0123456789 '.
    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING
        input  = lv_matnr_conv
      IMPORTING
        output = lv_matnr_conv.
  ENDIF.

  SELECT SINGLE a~matnr, a~mtart, a~mbrsh, b~maktx
    FROM mara AS a
    LEFT OUTER JOIN makt AS b
      ON a~matnr = b~matnr AND b~spras = @sy-langu
    WHERE a~matnr = @lv_matnr_conv
    INTO ( @ls_chg_hdr-matnr, @ls_chg_hdr-mtart, @ls_chg_hdr-mbrsh,
           @ls_chg_hdr-old_maktx ).
ENDIF.
