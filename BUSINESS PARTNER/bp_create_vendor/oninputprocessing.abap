*======================================================================*
* BSP EVENT HANDLER: OnInputProcessing
* Application: ZBP_REQUEST | Page: bp_create_request.htm
* Standard T-Code: BP (Create Organization - Address & General Data)
* Target Staging: ZMDG_BP_REQ
*======================================================================*

DATA: lv_action        TYPE string,
      lv_target_id     TYPE string,
      lv_has_error     TYPE abap_bool VALUE abap_false,
      lv_num_part      TYPE i,
      lv_time_str      TYPE string,
      ls_db_req        TYPE zmdg_bp_req,
      lv_title_key     TYPE string,
      lv_bp_grouping   TYPE string,
      lv_natural_pers  TYPE string,
      lv_external_bp   TYPE string,
      lv_legal_form    TYPE string,
      lv_legal_entity  TYPE string,
      lv_date_founded  TYPE string,
      lv_liquid_date   TYPE string,
      lv_loc_no_1      TYPE string,
      lv_loc_no_2      TYPE string,
      lv_check_digit   TYPE string,
      lv_vbund         TYPE string,
      lv_begru         TYPE string,
      lv_bp_type       TYPE string,
      lv_origin_source TYPE string,
      lv_origin_key    TYPE string,
      lv_internal_note TYPE string,
      lv_json_bank     TYPE string,
      lv_json_cards    TYPE string,
      lv_json_id_nums  TYPE string,
      lv_json_texts    TYPE string,
      lv_bu_group      TYPE bu_group VALUE '0001',
      lv_langu         TYPE laiso    VALUE 'ID',
      lv_ekorg         TYPE ekorg    VALUE '1000',
      lv_webre         TYPE webre    VALUE 'X',
      lv_lebre         TYPE lebre    VALUE 'X'.

CLEAR: gt_messages.

" ----------------------------------------------------------------------
" 1. RETRIEVE ACTION CODE (MULTI-TIER FALLBACK)
" ----------------------------------------------------------------------
lv_action = request->get_form_field( 'action' ).
IF lv_action IS INITIAL.
  lv_action = request->get_form_field( 'OnInputProcessing' ).
ENDIF.
IF lv_action IS INITIAL.
  lv_action = request->get_form_field( 'onInputProcessing' ).
ENDIF.

" Fallback: Scan semua form field jika tombol atau parameter terlewat
IF lv_action IS INITIAL.
  DATA: lt_raw_fields TYPE tihttpnvp,
        ls_raw_field  TYPE ihttpnvp.
  request->get_form_fields( CHANGING fields = lt_raw_fields ).
  LOOP AT lt_raw_fields INTO ls_raw_field.
    TRANSLATE ls_raw_field-name TO UPPER CASE.
    IF ( ls_raw_field-name = 'ACTION' OR ls_raw_field-name = 'ONINPUTPROCESSING' )
       AND ls_raw_field-value IS NOT INITIAL.
      lv_action = ls_raw_field-value.
      EXIT.
    ENDIF.
  ENDLOOP.
ENDIF.
TRANSLATE lv_action TO UPPER CASE.

" ----------------------------------------------------------------------
" 1B. INTERCEPT AJAX / API ACTIONS (SEARCH_BANKS)
" ----------------------------------------------------------------------
IF lv_action = 'SEARCH_BANKS' OR lv_action = 'FIND_BANK'.
  DATA: lv_ip_banks   TYPE string,
        lv_ip_bankk   TYPE string,
        lv_ip_banka   TYPE string,
        lv_ip_ort01   TYPE string,
        lv_ip_bnklz   TYPE string,
        lv_ip_swift   TYPE string,
        lv_ip_brnch   TYPE string,
        lv_ip_stras   TYPE string,
        lv_ip_max_str TYPE string,
        lv_ip_max_row TYPE i VALUE 500.

  lv_ip_banks   = request->get_form_field( 'banks' ).
  lv_ip_bankk   = request->get_form_field( 'bankk' ).
  IF lv_ip_bankk IS INITIAL.
    lv_ip_bankk = request->get_form_field( 'bankl' ).
  ENDIF.
  lv_ip_banka   = request->get_form_field( 'banka' ).
  lv_ip_ort01   = request->get_form_field( 'ort01' ).
  lv_ip_bnklz   = request->get_form_field( 'bnklz' ).
  IF lv_ip_bnklz IS INITIAL.
    lv_ip_bnklz = request->get_form_field( 'bank_number' ).
  ENDIF.
  lv_ip_swift   = request->get_form_field( 'swift' ).
  lv_ip_brnch   = request->get_form_field( 'brnch' ).
  lv_ip_stras   = request->get_form_field( 'stras' ).
  lv_ip_max_str = request->get_form_field( 'max_rows' ).

  IF lv_ip_max_str IS NOT INITIAL.
    lv_ip_max_row = CONV #( lv_ip_max_str ).
  ENDIF.
  IF lv_ip_max_row <= 0 OR lv_ip_max_row > 500.
    lv_ip_max_row = 500.
  ENDIF.

  IF lv_ip_banks IS INITIAL.
    lv_ip_banks = 'ID'.
  ENDIF.
  TRANSLATE lv_ip_banks TO UPPER CASE.
  TRANSLATE lv_ip_bankk TO UPPER CASE.
  TRANSLATE lv_ip_swift TO UPPER CASE.

  TYPES: BEGIN OF ty_bnka_item_ip,
           banks TYPE bnka-banks,
           bankl TYPE bnka-bankl,
           banka TYPE bnka-banka,
           ort01 TYPE bnka-ort01,
           bnklz TYPE bnka-bnklz,
           swift TYPE bnka-swift,
           brnch TYPE bnka-brnch,
           stras TYPE bnka-stras,
         END OF ty_bnka_item_ip.

  DATA: lt_bnka_ip TYPE STANDARD TABLE OF ty_bnka_item_ip,
        ls_bnka_ip TYPE ty_bnka_item_ip.

  DATA: lv_w_banks TYPE string,
        lv_w_bankl TYPE string,
        lv_w_banka TYPE string,
        lv_w_ort01 TYPE string,
        lv_w_bnklz TYPE string,
        lv_w_swift TYPE string,
        lv_w_brnch TYPE string,
        lv_w_stras TYPE string.

  lv_w_banks = lv_ip_banks.
  IF lv_ip_bankk IS NOT INITIAL.
    lv_w_bankl = |%{ lv_ip_bankk }%|.
  ELSE.
    lv_w_bankl = '%'.
  ENDIF.

  IF lv_ip_banka IS NOT INITIAL.
    lv_w_banka = |%{ lv_ip_banka }%|.
  ELSE.
    lv_w_banka = '%'.
  ENDIF.

  IF lv_ip_ort01 IS NOT INITIAL.
    lv_w_ort01 = |%{ lv_ip_ort01 }%|.
  ELSE.
    lv_w_ort01 = '%'.
  ENDIF.

  IF lv_ip_bnklz IS NOT INITIAL.
    lv_w_bnklz = |%{ lv_ip_bnklz }%|.
  ELSE.
    lv_w_bnklz = '%'.
  ENDIF.

  IF lv_ip_swift IS NOT INITIAL.
    lv_w_swift = |%{ lv_ip_swift }%|.
  ELSE.
    lv_w_swift = '%'.
  ENDIF.

  IF lv_ip_brnch IS NOT INITIAL.
    lv_w_brnch = |%{ lv_ip_brnch }%|.
  ELSE.
    lv_w_brnch = '%'.
  ENDIF.

  IF lv_ip_stras IS NOT INITIAL.
    lv_w_stras = |%{ lv_ip_stras }%|.
  ELSE.
    lv_w_stras = '%'.
  ENDIF.

  SELECT banks, bankl, banka, ort01, bnklz, swift, brnch, stras
    FROM bnka
   WHERE banks = @lv_w_banks
     AND bankl LIKE @lv_w_bankl
     AND banka LIKE @lv_w_banka
     AND ort01 LIKE @lv_w_ort01
     AND bnklz LIKE @lv_w_bnklz
     AND swift LIKE @lv_w_swift
     AND brnch LIKE @lv_w_brnch
     AND stras LIKE @lv_w_stras
   ORDER BY banks, bankl
    INTO CORRESPONDING FIELDS OF TABLE @lt_bnka_ip
   UP TO @lv_ip_max_row ROWS.

  DATA: lv_ip_json TYPE string.
  TRY.
      lv_ip_json = /ui2/cl_json=>serialize(
        data        = lt_bnka_ip
        compress    = abap_true
        pretty_name = /ui2/cl_json=>pretty_mode-low_case ).
    CATCH cx_root.
      DATA: lv_buf_json TYPE string,
            lv_b_a      TYPE string,
            lv_b_o      TYPE string,
            lv_b_s      TYPE string,
            lv_b_b      TYPE string,
            lv_b_st     TYPE string.
      LOOP AT lt_bnka_ip INTO ls_bnka_ip.
        lv_b_a  = ls_bnka_ip-banka.
        REPLACE ALL OCCURRENCES OF '"' IN lv_b_a WITH '\"'.
        lv_b_o  = ls_bnka_ip-ort01.
        REPLACE ALL OCCURRENCES OF '"' IN lv_b_o WITH '\"'.
        lv_b_s  = ls_bnka_ip-swift.
        REPLACE ALL OCCURRENCES OF '"' IN lv_b_s WITH '\"'.
        lv_b_b  = ls_bnka_ip-brnch.
        REPLACE ALL OCCURRENCES OF '"' IN lv_b_b WITH '\"'.
        lv_b_st = ls_bnka_ip-stras.
        REPLACE ALL OCCURRENCES OF '"' IN lv_b_st WITH '\"'.

        IF lv_buf_json IS NOT INITIAL.
          lv_buf_json = lv_buf_json && ','.
        ENDIF.
        lv_buf_json = lv_buf_json &&
          |\{"banks":"{ ls_bnka_ip-banks }","bankl":"{ ls_bnka_ip-bankl }",|
          && |"banka":"{ lv_b_a }","ort01":"{ lv_b_o }",|
          && |"bnklz":"{ ls_bnka_ip-bnklz }","swift":"{ lv_b_s }",|
          && |"brnch":"{ lv_b_b }","stras":"{ lv_b_st }"\}|.
      ENDLOOP.
      lv_ip_json = |[{ lv_buf_json }]|.
  ENDTRY.

  DATA: lv_ip_resp_full TYPE string.
  lv_ip_resp_full = |\{"status":"SUCCESS","count":{ lines( lt_bnka_ip ) },"data":{ lv_ip_json }\}|.

  _m_response->set_content_type( 'application/json' ).
  _m_response->set_cdata( lv_ip_resp_full ).
  _m_navigation->response_complete( ).
  RETURN.
ENDIF.

" ----------------------------------------------------------------------
" 2. ACTION: LOAD EXISTING REQUEST RECORD
" ----------------------------------------------------------------------
IF lv_action = 'LOAD_REQ'.
  lv_target_id = request->get_form_field( 'target_req_id' ).
  IF lv_target_id IS NOT INITIAL.
    SELECT SINGLE *
      FROM zmdg_bp_req
      INTO CORRESPONDING FIELDS OF @wa_req
     WHERE req_id = @lv_target_id.

    IF sy-subrc = 0.
      gv_req_id = wa_req-req_id.
      APPEND VALUE #(
        type    = 'S'
        message = |Request { wa_req-req_id } berhasil dimuat ke formulir.|
      ) TO gt_messages.
    ELSE.
      APPEND VALUE #(
        type    = 'E'
        message = |Request ID { lv_target_id } tidak ditemukan|
                  & | dalam database staging ZMDG_BP_REQ.|
      ) TO gt_messages.
    ENDIF.
  ENDIF.
  RETURN.
ENDIF.

" ----------------------------------------------------------------------
" 3. READ FORM FIELDS DARI HTML KE WORKAREA
" ----------------------------------------------------------------------
lv_bp_grouping      = request->get_form_field( 'bp_grouping' ).
IF lv_bp_grouping IS INITIAL.
  lv_bp_grouping    = request->get_form_field( 'bu_group' ).
ENDIF.
IF lv_bp_grouping IS NOT INITIAL.
  lv_bu_group       = lv_bp_grouping.
ELSE.
  lv_bu_group       = '0001'.
ENDIF.

lv_title_key        = request->get_form_field( 'title_key' ).
lv_natural_pers     = request->get_form_field( 'natural_person' ).
lv_external_bp      = request->get_form_field( 'external_bp_num' ).
lv_legal_form       = request->get_form_field( 'legal_form' ).
lv_legal_entity     = request->get_form_field( 'legal_entity' ).
lv_date_founded     = request->get_form_field( 'date_founded' ).
lv_liquid_date      = request->get_form_field( 'liquidation_date' ).
lv_loc_no_1         = request->get_form_field( 'loc_no_1' ).
lv_loc_no_2         = request->get_form_field( 'loc_no_2' ).
lv_check_digit      = request->get_form_field( 'check_digit' ).
lv_vbund            = request->get_form_field( 'vbund' ).
lv_begru            = request->get_form_field( 'begru' ).
lv_bp_type          = request->get_form_field( 'bp_type' ).
lv_origin_source    = request->get_form_field( 'origin_source' ).
lv_origin_key       = request->get_form_field( 'origin_ref_key' ).
lv_internal_note    = request->get_form_field( 'internal_notes' ).

lv_json_bank        = request->get_form_field( 'json_bank_details' ).
lv_json_cards       = request->get_form_field( 'json_payment_cards' ).
lv_json_id_nums     = request->get_form_field( 'json_id_numbers' ).
lv_json_texts       = request->get_form_field( 'json_additional_texts' ).

wa_req-req_id       = request->get_form_field( 'req_id' ).
wa_req-bp_category  = '2'. " 2 = Organization
wa_req-bp_role      = request->get_form_field( 'bp_role' ).
IF wa_req-bp_role IS INITIAL.
  wa_req-bp_role    = request->get_form_field( 'rltyp' ).
ENDIF.

" Section: Name (NAME_ORG1, NAME_ORG2)
wa_req-name1        = request->get_form_field( 'name1' ).
wa_req-name2        = request->get_form_field( 'name2' ).

" Section: Search Terms (BU_SORT1)
wa_req-search_term  = request->get_form_field( 'search_term' ).

" Section: Street Address (ADRC / Standard Address)
wa_req-street       = request->get_form_field( 'street' ).
wa_req-house_num    = request->get_form_field( 'house_num' ).
wa_req-postal_code  = request->get_form_field( 'postal_code' ).
wa_req-city         = request->get_form_field( 'city' ).
wa_req-country      = request->get_form_field( 'country' ).
wa_req-region       = request->get_form_field( 'region' ).

" Section: Communication (LANGU, Telephone, E_MAIL)
lv_langu            = request->get_form_field( 'langu' ).
IF lv_langu IS INITIAL.
  lv_langu          = request->get_form_field( 'language_key' ).
ENDIF.
IF lv_langu IS INITIAL.
  lv_langu          = 'ID'.
ENDIF.
wa_req-langu        = lv_langu.
wa_req-telephone    = request->get_form_field( 'telephone' ).
wa_req-email        = request->get_form_field( 'email' ).
DATA: lv_fax TYPE char30.
lv_fax              = request->get_form_field( 'fax' ).
wa_req-fax          = lv_fax.

" Section: Tax Data & Identification (NPWP)
wa_req-tax_type     = request->get_form_field( 'tax_type' ).
wa_req-tax_num      = request->get_form_field( 'tax_num' ).

" Section: Bank Details
wa_req-banks        = request->get_form_field( 'banks' ).
wa_req-bankl        = request->get_form_field( 'bankl' ).
wa_req-bankn        = request->get_form_field( 'bankn' ).
wa_req-koinh        = request->get_form_field( 'koinh' ).
wa_req-bank_name    = request->get_form_field( 'bank_name' ).

" Fallback dari JSON Bank Details jika form field individual kosong
IF wa_req-bankl IS INITIAL AND lv_json_bank IS NOT INITIAL AND lv_json_bank CS 'bank_key'.
  DATA: lv_match_key  TYPE string,
        lv_match_ctry TYPE string,
        lv_match_acct TYPE string,
        lv_match_name TYPE string.
  FIND REGEX '"bank_key"\s*:\s*"([^"]*)"' IN lv_json_bank SUBMATCHES lv_match_key.
  IF lv_match_key IS NOT INITIAL.
    wa_req-bankl = lv_match_key.
  ENDIF.
  FIND REGEX '"ctry"\s*:\s*"([^"]*)"' IN lv_json_bank SUBMATCHES lv_match_ctry.
  IF lv_match_ctry IS NOT INITIAL.
    wa_req-banks = lv_match_ctry.
  ENDIF.
  FIND REGEX '"bank_acct"\s*:\s*"([^"]*)"' IN lv_json_bank SUBMATCHES lv_match_acct.
  IF lv_match_acct IS NOT INITIAL.
    wa_req-bankn = lv_match_acct.
  ENDIF.
  FIND REGEX '"bank_name"\s*:\s*"([^"]*)"' IN lv_json_bank SUBMATCHES lv_match_name.
  IF lv_match_name IS NOT INITIAL.
    wa_req-bank_name = lv_match_name.
  ENDIF.
ENDIF.

" Section: Company Code Data (Accounting View)
wa_req-bukrs        = request->get_form_field( 'bukrs' ).
wa_req-akont        = request->get_form_field( 'akont' ).
wa_req-zterm        = request->get_form_field( 'zterm' ).

" Section: Purchasing View & Purchasing Data (EKORG, WAERS, WEBRE, LEBRE)
lv_ekorg            = request->get_form_field( 'ekorg' ).
IF lv_ekorg IS INITIAL.
  lv_ekorg          = '1000'.
ENDIF.
wa_req-waers        = request->get_form_field( 'waers' ).
lv_webre            = request->get_form_field( 'webre' ).
lv_lebre            = request->get_form_field( 'lebre' ).
wa_req-bu_group     = lv_bu_group.
wa_req-ekorg        = lv_ekorg.
wa_req-webre        = lv_webre.
wa_req-lebre        = lv_lebre.

" Simpan catatan internal ke catatan steward jika belum ada
IF lv_internal_note IS NOT INITIAL AND wa_req-stw_data_note IS INITIAL.
  wa_req-stw_data_note = lv_internal_note.
ENDIF.

" Format / Trim Strings
TRANSLATE wa_req-search_term TO UPPER CASE.
CONDENSE wa_req-name1.
CONDENSE wa_req-search_term NO-GAPS.
CONDENSE wa_req-city.
CONDENSE wa_req-country NO-GAPS.
TRANSLATE wa_req-country TO UPPER CASE.
CONDENSE wa_req-postal_code NO-GAPS.
CONDENSE lv_langu NO-GAPS.
TRANSLATE lv_langu TO UPPER CASE.
CONDENSE wa_req-tax_num NO-GAPS.
CONDENSE wa_req-bankl NO-GAPS.
CONDENSE wa_req-bankn NO-GAPS.
TRANSLATE wa_req-banks TO UPPER CASE.
CONDENSE wa_req-banks NO-GAPS.
CONDENSE lv_ekorg NO-GAPS.
TRANSLATE lv_ekorg TO UPPER CASE.
CONDENSE wa_req-waers NO-GAPS.
TRANSLATE wa_req-waers TO UPPER CASE.

" Default Fallbacks jika kosong
IF wa_req-bp_role IS INITIAL.
  wa_req-bp_role = 'FLVN01'. " Default: FLVN01 (Vendor: FLVN01 & FLVN00)
ENDIF.
IF lv_bu_group IS INITIAL.
  IF wa_req-bp_role CS 'CU'.
    lv_bu_group = 'C002'.      " Default Customer: C002 (Local Customer)
  ELSE.
    lv_bu_group = 'S001'.      " Default Vendor: S001 (Import Trade)
  ENDIF.
ENDIF.
IF wa_req-country IS INITIAL.
  wa_req-country = 'ID'.
ENDIF.
IF lv_langu IS INITIAL.
  lv_langu = 'ID'.
ENDIF.
IF wa_req-banks IS INITIAL.
  wa_req-banks = 'ID'.
ENDIF.
IF wa_req-bukrs IS INITIAL.
  wa_req-bukrs = '1000'.
ENDIF.
IF lv_ekorg IS INITIAL.
  lv_ekorg = '1000'.
ENDIF.
wa_req-bu_group = lv_bu_group.
wa_req-ekorg    = lv_ekorg.
IF wa_req-webre IS INITIAL.
  wa_req-webre  = 'X'.
ENDIF.
IF wa_req-lebre IS INITIAL.
  wa_req-lebre  = 'X'.
ENDIF.
IF wa_req-waers IS INITIAL.
  wa_req-waers = 'IDR'.
ENDIF.

" Auto-resolve Bank Name dari tabel BNKA SAP jika belum terisi
IF wa_req-bankl IS NOT INITIAL AND wa_req-bank_name IS INITIAL.
  SELECT SINGLE banka FROM bnka
    INTO @wa_req-bank_name
   WHERE banks = @wa_req-banks
     AND bankl = @wa_req-bankl.
ENDIF.

" Auto-default Account Holder (KOINH) ke Name 1 jika kosong
IF wa_req-koinh IS INITIAL AND wa_req-name1 IS NOT INITIAL.
  wa_req-koinh = wa_req-name1.
ENDIF.

" ----------------------------------------------------------------------
" 4. VALIDASI MANDATORY FIELD (STANDAR T-CODE BP & BAPI)
" ----------------------------------------------------------------------
IF lv_action = 'SUBMIT' OR lv_action = 'CHECK'.

  " 1. Name 1 Wajib diisi (NAME_ORG1, Maks 40 Karakter)
  IF wa_req-name1 IS INITIAL.
    APPEND VALUE #(
      type    = 'E'
      message = 'Name 1 (NAME_ORG1 / Nama Legal Entitas Vendor) wajib diisi.'
    ) TO gt_messages.
    lv_has_error = abap_true.
  ELSEIF strlen( wa_req-name1 ) > 40.
    APPEND VALUE #( type = 'E' message = 'Name 1 maksimal 40 karakter.' ) TO gt_messages.
    lv_has_error = abap_true.
  ENDIF.

  " 2. Search Term 1 Wajib diisi (BU_SORT1, Maks 20 Karakter)
  IF wa_req-search_term IS INITIAL.
    APPEND VALUE #(
      type    = 'E'
      message = 'Search Term 1 (BU_SORT1) wajib diisi sebagai kata kunci pencarian.'
    ) TO gt_messages.
    lv_has_error = abap_true.
  ELSEIF strlen( wa_req-search_term ) > 20.
    APPEND VALUE #(
      type    = 'E'
      message = 'Search Term 1 maksimal 20 karakter.'
    ) TO gt_messages.
    lv_has_error = abap_true.
  ENDIF.

  " 3. City Wajib diisi (CITY1, Maks 40 Karakter)
  IF wa_req-city IS INITIAL.
    APPEND VALUE #( type = 'E' message = 'City (CITY1 / Kota Domisili) wajib diisi (contoh: JAKARTA).' ) TO gt_messages.
    lv_has_error = abap_true.
  ELSEIF strlen( wa_req-city ) > 40.
    APPEND VALUE #( type = 'E' message = 'City maksimal 40 karakter.' ) TO gt_messages.
    lv_has_error = abap_true.
  ENDIF.

  " 4. Country Wajib diisi (COUNTRY, 2 Karakter ISO)
  IF wa_req-country IS INITIAL.
    APPEND VALUE #(
      type    = 'E'
      message = 'Country (COUNTRY / Kode Negara) wajib dipilih (contoh: ID).'
    ) TO gt_messages.
    lv_has_error = abap_true.
  ELSEIF strlen( wa_req-country ) <> 2.
    APPEND VALUE #(
      type    = 'E'
      message = 'Country harus berupa kode ISO 2 karakter (misal: ID).'
    ) TO gt_messages.
    lv_has_error = abap_true.
  ENDIF.

  " 5. Postal Code Wajib diisi (POST_CODE1)
  IF wa_req-postal_code IS INITIAL.
    APPEND VALUE #(
      type    = 'E'
      message = 'Postal Code (POST_CODE1) wajib diisi (contoh: 61292).'
    ) TO gt_messages.
    lv_has_error = abap_true.
  ELSEIF strlen( wa_req-postal_code ) > 10.
    APPEND VALUE #( type = 'E' message = 'Postal Code maksimal 10 karakter.' ) TO gt_messages.
    lv_has_error = abap_true.
  ENDIF.

  " 6. Language Key Wajib diisi (LANGU - Mandatori untuk mencegah error sistem SAP)
  IF lv_langu IS INITIAL.
    APPEND VALUE #(
      type    = 'E'
      message = 'Language Key (LANGU) wajib diisi (contoh: ID / Indonesian) guna mencegah error sistem.'
    ) TO gt_messages.
    lv_has_error = abap_true.
  ENDIF.

  " 7. Purchasing Organization Wajib diisi (EKORG)
  IF lv_ekorg IS INITIAL.
    APPEND VALUE #(
      type    = 'E'
      message = 'Purchasing Organization (EKORG) wajib diisi pada Purchasing View (contoh: 1000).'
    ) TO gt_messages.
    lv_has_error = abap_true.
  ENDIF.

  " 8. Order Currency Wajib diisi (WAERS)
  IF wa_req-waers IS INITIAL.
    APPEND VALUE #(
      type    = 'E'
      message = 'Order Currency (WAERS) wajib diisi pada Purchasing Data (contoh: IDR).'
    ) TO gt_messages.
    lv_has_error = abap_true.
  ENDIF.

  " 9. Validasi Format Email jika diisi (Opsional)
  IF wa_req-email IS NOT INITIAL AND NOT ( wa_req-email CS '@' AND wa_req-email CS '.' ).
    APPEND VALUE #(
      type    = 'E'
      message = 'Format E-Mail Address tidak valid (cek @ dan domain).'
    ) TO gt_messages.
    lv_has_error = abap_true.
  ENDIF.

  " 10. Validasi Tanggal Pendirian (Date Founded)
  IF lv_date_founded IS NOT INITIAL.
    DATA: lv_df_check TYPE string.
    lv_df_check = lv_date_founded.
    REPLACE ALL OCCURRENCES OF '-' IN lv_df_check WITH ''.
    IF strlen( lv_df_check ) = 8 AND lv_df_check > sy-datum.
      APPEND VALUE #(
        type    = 'W'
        message = 'Peringatan: Tanggal Pendirian melebihi tanggal hari ini.'
      ) TO gt_messages.
    ENDIF.
  ENDIF.

ENDIF.

" Jika hanya klik tombol CHECK
IF lv_action = 'CHECK'.
  IF lv_has_error = abap_false.
    APPEND VALUE #(
      type    = 'S'
      message = '[VALIDASI BERHASIL] Seluruh field mandatory standar SAP BP & Purchasing View (FLVN01) telah valid!'
    ) TO gt_messages.
  ENDIF.
ENDIF.

" ----------------------------------------------------------------------
" 5. ACTION: SIMPAN DRAFT KE STAGING ZMDG_BP_REQ
" ----------------------------------------------------------------------
IF lv_action = 'SAVE_DRAFT'.

  IF wa_req-req_id IS INITIAL.
    GET TIME.
    lv_time_str = sy-uzeit.
    wa_req-req_id = |BP{ sy-datum+6(2) }{ lv_time_str }|.
  ENDIF.

  wa_req-status     = 'DRAFT'.
  wa_req-created_by = sy-uname.
  GET TIME STAMP FIELD wa_req-created_at.
  wa_req-changed_by = sy-uname.
  GET TIME STAMP FIELD wa_req-changed_at.

  CLEAR ls_db_req.
  MOVE-CORRESPONDING wa_req TO ls_db_req.
  ls_db_req-mandt = sy-mandt.

  MODIFY zmdg_bp_req FROM @ls_db_req.
  IF sy-subrc = 0.
    COMMIT WORK AND WAIT.
    gv_req_id = wa_req-req_id.
    APPEND VALUE #(
      type    = 'S'
      message = |[DRAFT TERSIMPAN] Draft berhasil disimpan ke tabel ZMDG_BP_REQ (ID: { wa_req-req_id }).|
    ) TO gt_messages.
  ELSE.
    ROLLBACK WORK.
    APPEND VALUE #(
      type    = 'E'
      message = |Gagal menyimpan draft ke tabel ZMDG_BP_REQ (SY-SUBRC = { sy-subrc }).|
    ) TO gt_messages.
  ENDIF.

" ----------------------------------------------------------------------
" 6. ACTION: SUBMIT PERMOHONAN KE TABEL STAGING ZMDG_BP_REQ
" ----------------------------------------------------------------------
ELSEIF lv_action = 'SUBMIT'.

  IF lv_has_error = abap_true.
    APPEND VALUE #(
      type    = 'E'
      message = 'Permohonan gagal. Lengkapi seluruh field mandatory (*).'
    ) TO gt_messages.
  ELSE.

    IF wa_req-req_id IS INITIAL.
      GET TIME.
      lv_time_str = sy-uzeit.
      wa_req-req_id = |BP{ sy-datum+6(2) }{ lv_time_str }|.
    ENDIF.

    DATA: lv_ts_submit TYPE timestamp.
    GET TIME STAMP FIELD lv_ts_submit.

    CLEAR: wa_req-bp_number,
           wa_req-error_log,
           wa_req-rejection_reason,
           wa_req-stw_data_status,
           wa_req-stw_data_by,
           wa_req-stw_data_at,
           wa_req-stw_data_note,
           wa_req-stw_bank_status,
           wa_req-stw_bank_by,
           wa_req-stw_bank_at,
           wa_req-stw_bank_note,
           wa_req-appr_final_status,
           wa_req-appr_final_by,
           wa_req-appr_final_at,
           wa_req-appr_final_note.

    wa_req-status = 'SUBMITTED'.

    IF wa_req-created_by IS INITIAL.
      wa_req-created_by = sy-uname.
    ENDIF.
    IF wa_req-created_at IS INITIAL.
      wa_req-created_at = lv_ts_submit.
    ENDIF.
    wa_req-changed_by = sy-uname.
    wa_req-changed_at = lv_ts_submit.

    CLEAR ls_db_req.
    MOVE-CORRESPONDING wa_req TO ls_db_req.
    ls_db_req-mandt = sy-mandt.

    MODIFY zmdg_bp_req FROM @ls_db_req.
    IF sy-subrc = 0.
      COMMIT WORK AND WAIT.
      gv_req_id = wa_req-req_id.
      APPEND VALUE #(
        type    = 'S'
        message = |[PERMOHONAN BERHASIL DISUBMIT] Permohonan Business Partner dengan Request ID { wa_req-req_id }|
                  & | telah berhasil disimpan ke tabel staging ZMDG_BP_REQ (Status: SUBMITTED).|
                  & | Permohonan akan melalui alur verifikasi Data Steward & Bank Steward terlebih dahulu sebelum diposting ke SAP.|
      ) TO gt_messages.
    ELSE.
      ROLLBACK WORK.
      APPEND VALUE #(
        type    = 'E'
        message = |Gagal menyimpan permohonan ke tabel staging ZMDG_BP_REQ (SY-SUBRC = { sy-subrc }).|
      ) TO gt_messages.
    ENDIF.

  ENDIF.

ENDIF.

" ----------------------------------------------------------------------
" 7. REFRESH RIWAYAT PERMOHONAN USER
" ----------------------------------------------------------------------
SELECT *
  FROM zmdg_bp_req
 WHERE created_by = @sy-uname
  ORDER BY created_at DESCENDING
  INTO CORRESPONDING FIELDS OF TABLE @gt_my_requests
 UP TO 100 ROWS.

" ----------------------------------------------------------------------
" 8. ENSURE DROPDOWN BUFFERS ARE POPULATED AFTER POST
" ----------------------------------------------------------------------
IF gt_bp_roles IS INITIAL.
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
    APPEND VALUE #( role = '000000' rltxt = 'Business Partner (Gen.)' ) TO gt_bp_roles.
    APPEND VALUE #( role = 'FLVN00' rltxt = 'Vendor FI (Accounting)' )  TO gt_bp_roles.
    APPEND VALUE #( role = 'FLVN01' rltxt = 'MM Supplier' )             TO gt_bp_roles.
    APPEND VALUE #( role = 'BBP001' rltxt = 'Bidder' )                  TO gt_bp_roles.
    APPEND VALUE #( role = 'FLCU00' rltxt = 'FI Customer' )             TO gt_bp_roles.
    APPEND VALUE #( role = 'FLCU01' rltxt = 'Customer' )                TO gt_bp_roles.
  ENDIF.
ENDIF.

IF gt_roles IS INITIAL.
  DATA: ls_role_post TYPE ty_bp_role.
  LOOP AT gt_bp_roles INTO ls_role_post.
    APPEND VALUE #(
      key   = ls_role_post-role
      value = |{ ls_role_post-role } - { ls_role_post-rltxt }|
    ) TO gt_roles.
  ENDLOOP.
ENDIF.

IF gt_bp_grouping IS INITIAL.
  SELECT a~bu_group, b~txt40
    FROM tb001 AS a
   INNER JOIN tb002 AS b ON a~bu_group = b~bu_group
   WHERE b~spras = @sy-langu
     AND a~bu_group IN ( 'C001', 'C002', 'C003', 'S001', 'S002', 'S003', 'S004', 'S005' )
   ORDER BY a~bu_group
    INTO CORRESPONDING FIELDS OF TABLE @gt_bp_grouping.

  IF gt_bp_grouping IS INITIAL.
    SELECT a~bu_group, b~txt40
      FROM tb001 AS a
     INNER JOIN tb002 AS b ON a~bu_group = b~bu_group
     WHERE b~spras = 'E'
       AND a~bu_group IN ( 'C001', 'C002', 'C003', 'S001', 'S002', 'S003', 'S004', 'S005' )
     ORDER BY a~bu_group
      INTO CORRESPONDING FIELDS OF TABLE @gt_bp_grouping.
  ENDIF.

  IF gt_bp_grouping IS INITIAL.
    APPEND VALUE #( bu_group = 'C001' txt40 = 'Export Customer' )  TO gt_bp_grouping.
    APPEND VALUE #( bu_group = 'C002' txt40 = 'Local Customer' )   TO gt_bp_grouping.
    APPEND VALUE #( bu_group = 'C003' txt40 = 'Employee Customer' ) TO gt_bp_grouping.
    APPEND VALUE #( bu_group = 'S001' txt40 = 'Import Trade' )      TO gt_bp_grouping.
    APPEND VALUE #( bu_group = 'S002' txt40 = 'Local Trade' )       TO gt_bp_grouping.
    APPEND VALUE #( bu_group = 'S003' txt40 = 'Leasing Trade' )     TO gt_bp_grouping.
    APPEND VALUE #( bu_group = 'S004' txt40 = 'Service Trade' )     TO gt_bp_grouping.
    APPEND VALUE #( bu_group = 'S005' txt40 = 'Service Non Trade' ) TO gt_bp_grouping.
  ENDIF.
ENDIF.

IF gt_countries IS INITIAL.
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
ENDIF.

IF gt_regions IS INITIAL.
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
ENDIF.

IF gt_languages IS INITIAL.
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

  DATA: ls_lang_proc TYPE ty_language.
  LOOP AT gt_languages INTO ls_lang_proc.
    ls_lang_proc-key   = ls_lang_proc-laiso.
    ls_lang_proc-value = |{ ls_lang_proc-laiso } - { ls_lang_proc-sptxt }|.
    MODIFY gt_languages FROM ls_lang_proc.
  ENDLOOP.
ENDIF.
