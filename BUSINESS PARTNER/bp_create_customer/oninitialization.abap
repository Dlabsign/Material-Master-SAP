*======================================================================*
* BSP EVENT HANDLER: OnInitialization
* Application: ZBP_REQUEST | Page: bp_create_request.htm
* Standard T-Code: BP (Create Organization - Address & General Data)
* Staging Table: ZMDG_BP_REQ
*======================================================================*

CLEAR: gt_messages.

" ----------------------------------------------------------------------
" 0. INTERCEPT AJAX / API ACTIONS (SEARCH_BANKS untuk Dialog Find Bank SAP)
" ----------------------------------------------------------------------
DATA: lv_init_action TYPE string.
lv_init_action = request->get_form_field( 'action' ).
IF lv_init_action IS INITIAL.
  lv_init_action = request->get_form_field( 'OnInputProcessing' ).
ENDIF.
IF lv_init_action IS INITIAL.
  lv_init_action = request->get_form_field( 'onInputProcessing' ).
ENDIF.
TRANSLATE lv_init_action TO UPPER CASE.

IF lv_init_action = 'SEARCH_BANKS' OR lv_init_action = 'FIND_BANK'.
  DATA: lv_s_banks   TYPE string,
        lv_s_bankk   TYPE string,
        lv_s_banka   TYPE string,
        lv_s_ort01   TYPE string,
        lv_s_bnklz   TYPE string,
        lv_s_swift   TYPE string,
        lv_s_brnch   TYPE string,
        lv_s_stras   TYPE string,
        lv_s_max_str TYPE string,
        lv_max_rows  TYPE i VALUE 500.

  lv_s_banks   = request->get_form_field( 'banks' ).
  lv_s_bankk   = request->get_form_field( 'bankk' ).
  IF lv_s_bankk IS INITIAL.
    lv_s_bankk = request->get_form_field( 'bankl' ).
  ENDIF.
  lv_s_banka   = request->get_form_field( 'banka' ).
  lv_s_ort01   = request->get_form_field( 'ort01' ).
  lv_s_bnklz   = request->get_form_field( 'bnklz' ).
  IF lv_s_bnklz IS INITIAL.
    lv_s_bnklz = request->get_form_field( 'bank_number' ).
  ENDIF.
  lv_s_swift   = request->get_form_field( 'swift' ).
  lv_s_brnch   = request->get_form_field( 'brnch' ).
  lv_s_stras   = request->get_form_field( 'stras' ).
  lv_s_max_str = request->get_form_field( 'max_rows' ).

  IF lv_s_max_str IS NOT INITIAL.
    lv_max_rows = CONV #( lv_s_max_str ).
  ENDIF.
  IF lv_max_rows <= 0 OR lv_max_rows > 500.
    lv_max_rows = 500.
  ENDIF.

  IF lv_s_banks IS INITIAL.
    lv_s_banks = 'ID'.
  ENDIF.
  TRANSLATE lv_s_banks TO UPPER CASE.
  TRANSLATE lv_s_bankk TO UPPER CASE.
  TRANSLATE lv_s_swift TO UPPER CASE.

  TYPES: BEGIN OF ty_bnka_res_item,
           banks TYPE bnka-banks,
           bankl TYPE bnka-bankl,
           banka TYPE bnka-banka,
           ort01 TYPE bnka-ort01,
           bnklz TYPE bnka-bnklz,
           swift TYPE bnka-swift,
           brnch TYPE bnka-brnch,
           stras TYPE bnka-stras,
         END OF ty_bnka_res_item.

  DATA: lt_bnka_res TYPE STANDARD TABLE OF ty_bnka_res_item,
        ls_bnka_res TYPE ty_bnka_res_item.

  DATA: lv_p_banks TYPE string,
        lv_p_bankl TYPE string,
        lv_p_banka TYPE string,
        lv_p_ort01 TYPE string,
        lv_p_bnklz TYPE string,
        lv_p_swift TYPE string,
        lv_p_brnch TYPE string,
        lv_p_stras TYPE string.

  lv_p_banks = lv_s_banks.
  IF lv_s_bankk IS NOT INITIAL.
    lv_p_bankl = |%{ lv_s_bankk }%|.
  ELSE.
    lv_p_bankl = '%'.
  ENDIF.

  IF lv_s_banka IS NOT INITIAL.
    lv_p_banka = |%{ lv_s_banka }%|.
  ELSE.
    lv_p_banka = '%'.
  ENDIF.

  IF lv_s_ort01 IS NOT INITIAL.
    lv_p_ort01 = |%{ lv_s_ort01 }%|.
  ELSE.
    lv_p_ort01 = '%'.
  ENDIF.

  IF lv_s_bnklz IS NOT INITIAL.
    lv_p_bnklz = |%{ lv_s_bnklz }%|.
  ELSE.
    lv_p_bnklz = '%'.
  ENDIF.

  IF lv_s_swift IS NOT INITIAL.
    lv_p_swift = |%{ lv_s_swift }%|.
  ELSE.
    lv_p_swift = '%'.
  ENDIF.

  IF lv_s_brnch IS NOT INITIAL.
    lv_p_brnch = |%{ lv_s_brnch }%|.
  ELSE.
    lv_p_brnch = '%'.
  ENDIF.

  IF lv_s_stras IS NOT INITIAL.
    lv_p_stras = |%{ lv_s_stras }%|.
  ELSE.
    lv_p_stras = '%'.
  ENDIF.

  SELECT banks, bankl, banka, ort01, bnklz, swift, brnch, stras
    FROM bnka
   WHERE banks = @lv_p_banks
     AND bankl LIKE @lv_p_bankl
     AND banka LIKE @lv_p_banka
     AND ort01 LIKE @lv_p_ort01
     AND bnklz LIKE @lv_p_bnklz
     AND swift LIKE @lv_p_swift
     AND brnch LIKE @lv_p_brnch
     AND stras LIKE @lv_p_stras
   ORDER BY banks, bankl
    INTO CORRESPONDING FIELDS OF TABLE @lt_bnka_res
   UP TO @lv_max_rows ROWS.

  DATA: lv_res_json TYPE string.
  TRY.
      lv_res_json = /ui2/cl_json=>serialize(
        data        = lt_bnka_res
        compress    = abap_true
        pretty_name = /ui2/cl_json=>pretty_mode-low_case ).
    CATCH cx_root.
      DATA: lv_items_json TYPE string,
            lv_esc_a      TYPE string,
            lv_esc_o      TYPE string,
            lv_esc_s      TYPE string,
            lv_esc_b      TYPE string,
            lv_esc_st     TYPE string.
      LOOP AT lt_bnka_res INTO ls_bnka_res.
        lv_esc_a  = ls_bnka_res-banka.
        REPLACE ALL OCCURRENCES OF '"' IN lv_esc_a WITH '\"'.
        lv_esc_o  = ls_bnka_res-ort01.
        REPLACE ALL OCCURRENCES OF '"' IN lv_esc_o WITH '\"'.
        lv_esc_s  = ls_bnka_res-swift.
        REPLACE ALL OCCURRENCES OF '"' IN lv_esc_s WITH '\"'.
        lv_esc_b  = ls_bnka_res-brnch.
        REPLACE ALL OCCURRENCES OF '"' IN lv_esc_b WITH '\"'.
        lv_esc_st = ls_bnka_res-stras.
        REPLACE ALL OCCURRENCES OF '"' IN lv_esc_st WITH '\"'.

        IF lv_items_json IS NOT INITIAL.
          lv_items_json = lv_items_json && ','.
        ENDIF.
        lv_items_json = lv_items_json &&
          |\{"banks":"{ ls_bnka_res-banks }","bankl":"{ ls_bnka_res-bankl }",|
          && |"banka":"{ lv_esc_a }","ort01":"{ lv_esc_o }",|
          && |"bnklz":"{ ls_bnka_res-bnklz }","swift":"{ lv_esc_s }",|
          && |"brnch":"{ lv_esc_b }","stras":"{ lv_esc_st }"\}|.
      ENDLOOP.
      lv_res_json = |[{ lv_items_json }]|.
  ENDTRY.

  DATA: lv_resp_full TYPE string.
  lv_resp_full = |\{"status":"SUCCESS","count":{ lines( lt_bnka_res ) },"data":{ lv_res_json }\}|.

  _m_response->set_content_type( 'application/json' ).
  _m_response->set_cdata( lv_resp_full ).
  _m_navigation->response_complete( ).
  RETURN.
ENDIF.

" 1. Retrieve URL Request ID Parameter (jika membuka request sebelumnya)
gv_req_id = request->get_form_field( 'req_id' ).

" 2. Load Existing Request jika ID dikirim
IF gv_req_id IS NOT INITIAL.
  SELECT SINGLE *
    FROM zmdg_bp_req
    INTO CORRESPONDING FIELDS OF @wa_req
   WHERE req_id = @gv_req_id.

  IF sy-subrc <> 0.
    APPEND VALUE #(
      type    = 'E'
      message = |Request ID { gv_req_id } tidak ditemukan dalam database staging ZMDG_BP_REQ.|
    ) TO gt_messages.
  ENDIF.

ELSE.
  " 3. Initialize Default Staging Values untuk Permohonan Baru
  CLEAR wa_req.
  wa_req-bp_category = '2'.        " 2 = Organization
  wa_req-bp_role     = 'FLVN01'.   " Default: FLVN01 (MM Supplier)
  wa_req-country     = 'ID'.       " Default: Indonesia (ISO: ID)
  wa_req-city        = 'JAKARTA'.  " Default: JAKARTA
  wa_req-postal_code = '61292'.    " Default: 61292
  wa_req-region      = '01'.       " Default: DKI Jakarta
  wa_req-tax_type    = 'ID1'.      " Default: NPWP Indonesia
  wa_req-banks       = 'ID'.       " Default Bank: Indonesia
  wa_req-bukrs       = '1000'.     " Default Company Code: 1000
  wa_req-waers       = 'IDR'.      " Default Currency: IDR
  wa_req-bu_group    = 'C001'.     " Default: C001 (Export Customer)
  wa_req-ekorg       = '1000'.     " Default Purchasing Org: 1000
  wa_req-webre       = 'X'.        " Default: GR-Based Inv. Verif
  wa_req-lebre       = 'X'.        " Default: Service-Based Inv. Verif
  wa_req-status      = 'DRAFT'.
  wa_req-created_by  = sy-uname.
  GET TIME STAMP FIELD wa_req-created_at.
ENDIF.

" 4. Load User Request History (Semua status untuk audit trail & tab filtering)
SELECT *
  FROM zmdg_bp_req
 WHERE created_by = @sy-uname
  ORDER BY created_at DESCENDING
  INTO CORRESPONDING FIELDS OF TABLE @gt_my_requests
 UP TO 100 ROWS.

" 5. Populate BP Roles Dropdown langsung dari tabel standar SAP TB003 & TB003T
CLEAR: gt_bp_roles, gt_roles.
SELECT a~role, b~rltxt
  FROM tb003 AS a
 INNER JOIN tb003t AS b ON a~role = b~role
 WHERE b~spras = @sy-langu
 ORDER BY a~role
  INTO CORRESPONDING FIELDS OF TABLE @gt_bp_roles.

IF gt_bp_roles IS INITIAL.
  SELECT a~role, b~rltxt
    FROM tb003 AS a
   INNER JOIN tb003t AS b ON a~role = b~role
   WHERE b~spras = 'E'
   ORDER BY a~role
    INTO CORRESPONDING FIELDS OF TABLE @gt_bp_roles.
ENDIF.

IF gt_bp_roles IS INITIAL.
  APPEND VALUE #( role = 'FLVN01' rltxt = 'MM Supplier' )             TO gt_bp_roles.
  APPEND VALUE #( role = 'FLVN00' rltxt = 'FI Supplier' )             TO gt_bp_roles.
  APPEND VALUE #( role = 'FLCU01' rltxt = 'SD Customer' )             TO gt_bp_roles.
  APPEND VALUE #( role = 'FLCU00' rltxt = 'FI Customer' )             TO gt_bp_roles.
ENDIF.

DATA: ls_role_fill TYPE ty_bp_role.
LOOP AT gt_bp_roles INTO ls_role_fill.
  APPEND VALUE #(
    key   = ls_role_fill-role
    value = |{ ls_role_fill-role } - { ls_role_fill-rltxt }|
  ) TO gt_roles.
ENDLOOP.

" 6. Populate BP Grouping Dropdown langsung dari tabel standar SAP TB001 & TB002
CLEAR: gt_bp_grouping.
SELECT a~bu_group, b~txt40
  FROM tb001 AS a
 INNER JOIN tb002 AS b ON a~bu_group = b~bu_group
 WHERE b~spras = @sy-langu
   AND a~bu_group IN ( 'C001', 'C002', 'C003', 'S001', 'S002' )
 ORDER BY a~bu_group
  INTO CORRESPONDING FIELDS OF TABLE @gt_bp_grouping.

IF gt_bp_grouping IS INITIAL.
  SELECT a~bu_group, b~txt40
    FROM tb001 AS a
   INNER JOIN tb002 AS b ON a~bu_group = b~bu_group
   WHERE b~spras = 'E'
     AND a~bu_group IN ( 'C001', 'C002', 'C003', 'S001', 'S002' )
   ORDER BY a~bu_group
    INTO CORRESPONDING FIELDS OF TABLE @gt_bp_grouping.
ENDIF.

IF gt_bp_grouping IS INITIAL.
  APPEND VALUE #( bu_group = 'C001' txt40 = 'Export Customer' )  TO gt_bp_grouping.
  APPEND VALUE #( bu_group = 'C002' txt40 = 'Local Customer' )   TO gt_bp_grouping.
  APPEND VALUE #( bu_group = 'C003' txt40 = 'Employee Customer' ) TO gt_bp_grouping.
  APPEND VALUE #( bu_group = 'S001' txt40 = 'Import Trade' )      TO gt_bp_grouping.
  APPEND VALUE #( bu_group = 'S002' txt40 = 'Local Trade' )       TO gt_bp_grouping.
ENDIF.

" 7. Query Countries langsung dari tabel standar SAP T005T
CLEAR: gt_countries.
SELECT land1, landx
  FROM t005t
 WHERE spras = @sy-langu
 ORDER BY landx
  INTO CORRESPONDING FIELDS OF TABLE @gt_countries.

IF gt_countries IS INITIAL.
  SELECT land1, landx
    FROM t005t
   WHERE spras = 'E'
   ORDER BY landx
    INTO CORRESPONDING FIELDS OF TABLE @gt_countries.
ENDIF.

IF gt_countries IS INITIAL.
  APPEND VALUE #( land1 = 'ID' landx = 'Indonesia' )     TO gt_countries.
  APPEND VALUE #( land1 = 'SG' landx = 'Singapore' )     TO gt_countries.
  APPEND VALUE #( land1 = 'MY' landx = 'Malaysia' )      TO gt_countries.
  APPEND VALUE #( land1 = 'JP' landx = 'Japan' )         TO gt_countries.
  APPEND VALUE #( land1 = 'US' landx = 'United States' ) TO gt_countries.
  APPEND VALUE #( land1 = 'DE' landx = 'Germany' )       TO gt_countries.
  APPEND VALUE #( land1 = 'CN' landx = 'China' )         TO gt_countries.
ENDIF.

" 7. Query Regions / Wilayah langsung dari tabel standar SAP T005U
CLEAR: gt_regions.
SELECT land1, bland, bezei
  FROM t005u
 WHERE spras = @sy-langu
 ORDER BY bezei
  INTO CORRESPONDING FIELDS OF TABLE @gt_regions.

IF gt_regions IS INITIAL.
  SELECT land1, bland, bezei
    FROM t005u
   WHERE spras = 'E'
   ORDER BY bezei
    INTO CORRESPONDING FIELDS OF TABLE @gt_regions.
ENDIF.

IF gt_regions IS INITIAL.
  APPEND VALUE #( land1 = 'ID' bland = '08' bezei = 'Jawa Timur' )       TO gt_regions.
  APPEND VALUE #( land1 = 'ID' bland = '01' bezei = 'DKI Jakarta' )      TO gt_regions.
  APPEND VALUE #( land1 = 'ID' bland = '02' bezei = 'Jawa Barat' )       TO gt_regions.
  APPEND VALUE #( land1 = 'ID' bland = '03' bezei = 'Jawa Tengah' )      TO gt_regions.
  APPEND VALUE #( land1 = 'ID' bland = '04' bezei = 'DI Yogyakarta' )    TO gt_regions.
  APPEND VALUE #( land1 = 'ID' bland = '06' bezei = 'Banten' )           TO gt_regions.
  APPEND VALUE #( land1 = 'ID' bland = '07' bezei = 'Bali' )             TO gt_regions.
  APPEND VALUE #( land1 = 'ID' bland = '09' bezei = 'Sumatera Selatan' ) TO gt_regions.
  APPEND VALUE #( land1 = 'ID' bland = '10' bezei = 'Sulawesi Selatan' ) TO gt_regions.
ENDIF.

" 8. Query Master Bahasa langsung dari tabel standar SAP T002T & T002
CLEAR: gt_languages.
SELECT a~spras, b~laiso, a~sptxt
  FROM t002t AS a
 INNER JOIN t002 AS b ON a~spras = b~spras
 WHERE a~sprsl = @sy-langu
 ORDER BY a~sptxt ASCENDING
  INTO CORRESPONDING FIELDS OF TABLE @gt_languages.

IF gt_languages IS INITIAL.
  SELECT a~spras, b~laiso, a~sptxt
    FROM t002t AS a
   INNER JOIN t002 AS b ON a~spras = b~spras
   WHERE a~sprsl = 'E'
   ORDER BY a~sptxt ASCENDING
    INTO CORRESPONDING FIELDS OF TABLE @gt_languages.
ENDIF.

IF gt_languages IS INITIAL.
  APPEND VALUE #( spras = 'I' laiso = 'ID' sptxt = 'Indonesian' ) TO gt_languages.
  APPEND VALUE #( spras = 'E' laiso = 'EN' sptxt = 'English' )    TO gt_languages.
  APPEND VALUE #( spras = 'D' laiso = 'DE' sptxt = 'German' )     TO gt_languages.
  APPEND VALUE #( spras = 'J' laiso = 'JA' sptxt = 'Japanese' )   TO gt_languages.
ENDIF.

DATA: ls_lang_init TYPE ty_language.
LOOP AT gt_languages INTO ls_lang_init.
  ls_lang_init-key   = ls_lang_init-laiso.
  ls_lang_init-value = |{ ls_lang_init-laiso } - { ls_lang_init-sptxt }|.
  MODIFY gt_languages FROM ls_lang_init.
ENDLOOP.
