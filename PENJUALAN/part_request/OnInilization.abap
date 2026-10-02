*----------------------------------------------------------------------*
* Event Handler: OnInitialization (Material Part Request Staging)
*----------------------------------------------------------------------*
TYPES: BEGIN OF ty_json_item,
         code TYPE string,
         name TYPE string,
       END OF ty_json_item.

DATA: req_id             TYPE string,
      gt_part_stg        TYPE TABLE OF zmdg_stg_part,
      lv_req_id          TYPE char10,
      lt_plants          TYPE TABLE OF t001w,
      ls_plant           TYPE t001w,
      lt_raw_mats        TYPE TABLE OF makt,
      ls_raw             TYPE makt,
      lt_matkl_tab       TYPE TABLE OF t023t,
      ls_matkl_item      TYPE t023t,
      lt_plant_json      TYPE TABLE OF ty_json_item,
      lt_raw_json        TYPE TABLE OF ty_json_item,
      lt_matkl_json      TYPE TABLE OF ty_json_item,
      ls_json_item       TYPE ty_json_item.

req_id = request->get_form_field( 'req_id' ).
IF req_id IS INITIAL.
  req_id = request->get_form_field( 'REQ_ID' ).
ENDIF.

" Read Existing Data Staging from ZMDG_STG_PART
DATA: lv_upload_id_param TYPE string.
lv_upload_id_param = request->get_form_field( 'upload_id' ).
IF lv_upload_id_param IS INITIAL.
  lv_upload_id_param = request->get_form_field( 'UPLOAD_ID' ).
ENDIF.

IF lv_upload_id_param IS NOT INITIAL.
  SELECT *
    FROM zmdg_stg_part
    WHERE req_no = @lv_upload_id_param
    ORDER BY item_no ASCENDING
    INTO TABLE @gt_part_stg.
ELSEIF req_id IS NOT INITIAL.
  SELECT *
    FROM zmdg_stg_part
    WHERE req_no = @req_id
    ORDER BY item_no ASCENDING
    INTO TABLE @gt_part_stg.
ENDIF.