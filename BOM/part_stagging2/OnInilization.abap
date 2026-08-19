*----------------------------------------------------------------------*
* Event Handler : OnInitialization (Staging Preparation Page)
*----------------------------------------------------------------------*
TYPES: BEGIN OF ty_json_item,
         code TYPE string,
         name TYPE string,
       END OF ty_json_item.

DATA: lt_plants     TYPE TABLE OF t001w,
      ls_plant      TYPE t001w,
      lt_matkl_tab  TYPE TABLE OF t023t,
      ls_matkl_item TYPE t023t,
      lt_mtart_tab  TYPE TABLE OF t134t,
      ls_mtart_item TYPE t134t,
      lt_plant_json TYPE TABLE OF ty_json_item,
      lt_matkl_json TYPE TABLE OF ty_json_item,
      lt_mtart_json TYPE TABLE OF ty_json_item,
      ls_json_item  TYPE ty_json_item.

" 1. Master Data Plants (T001W)
CLEAR: lt_plants, lt_plant_json.
SELECT werks, name1 FROM t001w INTO CORRESPONDING FIELDS OF TABLE @lt_plants.
LOOP AT lt_plants INTO ls_plant.
  CLEAR ls_json_item.
  ls_json_item-code = ls_plant-werks.
  ls_json_item-name = COND #( WHEN ls_plant-name1 IS NOT INITIAL THEN ls_plant-name1 ELSE ls_plant-werks ).
  APPEND ls_json_item TO lt_plant_json.
ENDLOOP.

gt_plant_json = /ui2/cl_json=>serialize( data = lt_plant_json compress = abap_true pretty_name = /ui2/cl_json=>pretty_mode-low_case ).
IF gt_plant_json IS INITIAL. gt_plant_json = '[]'. ENDIF.

" 2. Master Data Material Group (T023T)
CLEAR: lt_matkl_tab, lt_matkl_json.
SELECT matkl, wgbez FROM t023t WHERE spras = @sy-langu INTO CORRESPONDING FIELDS OF TABLE @lt_matkl_tab.
LOOP AT lt_matkl_tab INTO ls_matkl_item.
  CLEAR ls_json_item.
  ls_json_item-code = ls_matkl_item-matkl.
  ls_json_item-name = COND #( WHEN ls_matkl_item-wgbez IS NOT INITIAL THEN ls_matkl_item-wgbez ELSE ls_matkl_item-matkl ).
  APPEND ls_json_item TO lt_matkl_json.
ENDLOOP.

gt_matkl_json = /ui2/cl_json=>serialize( data = lt_matkl_json compress = abap_true pretty_name = /ui2/cl_json=>pretty_mode-low_case ).
IF gt_matkl_json IS INITIAL. gt_matkl_json = '[]'. ENDIF.

" 3. Master Data Material Type (T134T)
CLEAR: lt_mtart_tab, lt_mtart_json.
SELECT mtart, mtbez FROM t134t WHERE spras = @sy-langu INTO CORRESPONDING FIELDS OF TABLE @lt_mtart_tab.
LOOP AT lt_mtart_tab INTO ls_mtart_item.
  CLEAR ls_json_item.
  ls_json_item-code = ls_mtart_item-mtart.
  ls_json_item-name = COND #( WHEN ls_mtart_item-mtbez IS NOT INITIAL THEN ls_mtart_item-mtbez ELSE ls_mtart_item-mtart ).
  APPEND ls_json_item TO lt_mtart_json.
ENDLOOP.

gt_mtart_json = /ui2/cl_json=>serialize( data = lt_mtart_json compress = abap_true pretty_name = /ui2/cl_json=>pretty_mode-low_case ).
IF gt_mtart_json IS INITIAL. gt_mtart_json = '[]'. ENDIF.