*----------------------------------------------------------------------*
* Event Handler: OnInitialization
*----------------------------------------------------------------------*
TYPES: BEGIN OF ty_json_item,
         code TYPE string,
         name TYPE string,
       END OF ty_json_item.

DATA: lv_req_id     TYPE sysuuid_c32,
      lt_plants     TYPE TABLE OF t001w,
      ls_plant      TYPE t001w,
      lt_raw_mats   TYPE TABLE OF makt,
      ls_raw        TYPE makt,
      lt_matkl_tab  TYPE TABLE OF t023t,
      ls_matkl_item TYPE t023t,
      lt_plant_json TYPE TABLE OF ty_json_item,
      lt_raw_json   TYPE TABLE OF ty_json_item,
      lt_matkl_json TYPE TABLE OF ty_json_item,
      ls_json_item  TYPE ty_json_item.


" 6. Read Data Staging Existing
DATA: lv_upload_id_param TYPE string.
lv_upload_id_param = request->get_form_field( 'upload_id' ).
IF lv_upload_id_param IS INITIAL.
  lv_upload_id_param = request->get_form_field( 'UPLOAD_ID' ).
ENDIF.

IF lv_upload_id_param IS NOT INITIAL.
  SELECT *
    FROM zbom_stg_part
    WHERE upload_id = @lv_upload_id_param
    ORDER BY posnr ASCENDING
    INTO TABLE @gt_part_stg.
ELSEIF req_id IS NOT INITIAL.
  SELECT *
    FROM zbom_stg_part
    WHERE req_id = @req_id
    ORDER BY posnr ASCENDING
    INTO TABLE @gt_part_stg.
ENDIF.