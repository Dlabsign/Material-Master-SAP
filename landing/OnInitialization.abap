*====================================================================*
* SAP BSP EVENT HANDLER: OnInitialization.abap                        *
* Page: landing_page.htm                                             *
* PT Kayu Mebel Indonesia - Master Data Governance                   *
*====================================================================*

DATA: lv_user_display   TYPE string,
      lv_total_mat_num  TYPE i VALUE 0,
      lv_total_mat      TYPE string,
      lv_total_bp_num   TYPE i VALUE 0,
      lv_total_bp       TYPE string,
      lv_total_fin      TYPE string VALUE '7,215',
      lv_total_ent      TYPE string VALUE '29,158'.

TYPES: BEGIN OF ty_mtart_stat,
         mtart TYPE mara-mtart,
         cnt   TYPE i,
       END OF ty_mtart_stat.

DATA: lt_mtart_stat TYPE TABLE OF ty_mtart_stat,
      ls_mtart_stat TYPE ty_mtart_stat,
      lv_cnt_str    TYPE string.

TYPES: BEGIN OF ty_t134t_desc,
         mtart TYPE t134t-mtart,
         mtbez TYPE t134t-mtbez,
       END OF ty_t134t_desc.

DATA: lt_t134t_desc TYPE TABLE OF ty_t134t_desc,
      ls_t134t_desc TYPE ty_t134t_desc,
      lv_mtbez_val  TYPE string.

DATA: lv_mtart_json TYPE string,
      lv_sep        TYPE string.

TYPES: BEGIN OF ty_but000_raw,
         partner    TYPE but000-partner,
         name_org1  TYPE but000-name_org1,
         name_first TYPE but000-name_first,
         name_last  TYPE but000-name_last,
         xdele      TYPE but000-xdele,
       END OF ty_but000_raw.

DATA: lt_but000_raw TYPE TABLE OF ty_but000_raw,
      ls_but000_raw TYPE ty_but000_raw.

TYPES: BEGIN OF ty_but0bk_raw,
         partner TYPE but0bk-partner,
         banks   TYPE but0bk-banks,
         bankl   TYPE but0bk-bankl,
         bankn   TYPE but0bk-bankn,
       END OF ty_but0bk_raw.

DATA: lt_but0bk_raw TYPE TABLE OF ty_but0bk_raw,
      ls_but0bk_raw TYPE ty_but0bk_raw.

TYPES: BEGIN OF ty_lfa1_raw,
         lifnr TYPE lfa1-lifnr,
         name1 TYPE lfa1-name1,
         loevm TYPE lfa1-loevm,
       END OF ty_lfa1_raw.

DATA: lt_lfa1_raw TYPE TABLE OF ty_lfa1_raw,
      ls_lfa1_raw TYPE ty_lfa1_raw.

TYPES: BEGIN OF ty_lfbk_raw,
         lifnr TYPE lfbk-lifnr,
         banks TYPE lfbk-banks,
         bankl TYPE lfbk-bankl,
         bankn TYPE lfbk-bankn,
       END OF ty_lfbk_raw.

DATA: lt_lfbk_raw TYPE TABLE OF ty_lfbk_raw,
      ls_lfbk_raw TYPE ty_lfbk_raw.

TYPES: BEGIN OF ty_bnka_raw,
         banks TYPE bnka-banks,
         bankl TYPE bnka-bankl,
         banka TYPE bnka-banka,
       END OF ty_bnka_raw.

DATA: lt_bnka_raw TYPE TABLE OF ty_bnka_raw,
      ls_bnka_raw TYPE ty_bnka_raw.

DATA: lv_bp_json    TYPE string,
      lv_bp_sep     TYPE string,
      lv_name_upper TYPE string,
      lv_bank_name  TYPE string,
      lv_has_bank   TYPE c.

lv_user_display = sy-uname.
IF lv_user_display IS INITIAL OR lv_user_display = 'DEFAULT'.
  lv_user_display = 'Totok Michael'.
ENDIF.

SELECT COUNT( * ) FROM mara INTO lv_total_mat_num.
lv_total_mat = lv_total_mat_num.
CONDENSE lv_total_mat.

SELECT mtart COUNT( * ) AS cnt
  FROM mara
  INTO TABLE lt_mtart_stat
  GROUP BY mtart.

SORT lt_mtart_stat BY cnt DESCENDING.

SELECT mtart mtbez FROM t134t INTO TABLE lt_t134t_desc WHERE spras = sy-langu.
SORT lt_t134t_desc BY mtart.

lv_mtart_json = '['.
lv_sep = ''.
LOOP AT lt_mtart_stat INTO ls_mtart_stat.
  lv_cnt_str = ls_mtart_stat-cnt.
  CONDENSE lv_cnt_str.

  CLEAR lv_mtbez_val.
  READ TABLE lt_t134t_desc INTO ls_t134t_desc WITH KEY mtart = ls_mtart_stat-mtart BINARY SEARCH.
  IF sy-subrc = 0.
    lv_mtbez_val = ls_t134t_desc-mtbez.
    REPLACE ALL OCCURRENCES OF '\' IN lv_mtbez_val WITH '\\'.
    REPLACE ALL OCCURRENCES OF '"' IN lv_mtbez_val WITH '\"'.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf IN lv_mtbez_val WITH ' '.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>newline IN lv_mtbez_val WITH ' '.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>horizontal_tab IN lv_mtbez_val WITH ' '.
  ENDIF.
  CONCATENATE lv_mtart_json lv_sep '{"mtart":"' ls_mtart_stat-mtart '","desc":"'
              lv_mtbez_val '","cnt":' lv_cnt_str '}' INTO lv_mtart_json.
  lv_sep = ','.
ENDLOOP.
CONCATENATE lv_mtart_json ']' INTO lv_mtart_json.
IF lv_mtart_json = '[' OR lv_mtart_json IS INITIAL.
  lv_mtart_json = '[]'.
ENDIF.

SELECT partner name_org1 name_first name_last xdele FROM but000 INTO TABLE lt_but000_raw WHERE xdele = ' '.
IF lt_but000_raw IS NOT INITIAL.
  SELECT partner banks bankl bankn FROM but0bk INTO TABLE lt_but0bk_raw FOR ALL ENTRIES IN lt_but000_raw WHERE partner = lt_but000_raw-partner.
  IF lt_but0bk_raw IS NOT INITIAL.
    SELECT banks bankl banka FROM bnka INTO TABLE lt_bnka_raw FOR ALL ENTRIES IN lt_but0bk_raw WHERE banks = lt_but0bk_raw-banks AND bankl = lt_but0bk_raw-bankl.
  ENDIF.
ELSE.
  SELECT lifnr name1 loevm FROM lfa1 INTO TABLE lt_lfa1_raw WHERE loevm = ' '.
  IF lt_lfa1_raw IS NOT INITIAL.
    SELECT lifnr banks bankl bankn FROM lfbk INTO TABLE lt_lfbk_raw FOR ALL ENTRIES IN lt_lfa1_raw WHERE lifnr = lt_lfa1_raw-lifnr.
    IF lt_lfbk_raw IS NOT INITIAL.
      SELECT banks bankl banka FROM bnka INTO TABLE lt_bnka_raw FOR ALL ENTRIES IN lt_lfbk_raw WHERE banks = lt_lfbk_raw-banks AND bankl = lt_lfbk_raw-bankl.
    ENDIF.
  ENDIF.
ENDIF.

lv_bp_json = '['.
lv_bp_sep = ''.
lv_total_bp_num = 0.

IF lt_but000_raw IS NOT INITIAL.
  LOOP AT lt_but000_raw INTO ls_but000_raw.
    DATA: lv_bp_fullname TYPE string.
    IF ls_but000_raw-name_org1 IS NOT INITIAL.
      lv_bp_fullname = ls_but000_raw-name_org1.
    ELSE.
      CONCATENATE ls_but000_raw-name_first ls_but000_raw-name_last
                  INTO lv_bp_fullname SEPARATED BY space.
    ENDIF.

    lv_name_upper = lv_bp_fullname.
    TRANSLATE lv_name_upper TO UPPER CASE.

    IF lv_name_upper CS 'NOT USED' OR
       lv_name_upper CS 'NOT-USED' OR
       lv_name_upper CS 'DO NOT USE' OR
       lv_name_upper CS 'DUMMY' OR
       lv_name_upper IS INITIAL.
      CONTINUE.
    ENDIF.

    lv_total_bp_num = lv_total_bp_num + 1.
    lv_has_bank = ' '.

    REPLACE ALL OCCURRENCES OF '\' IN lv_bp_fullname WITH '\\'.
    REPLACE ALL OCCURRENCES OF '"' IN lv_bp_fullname WITH '\"'.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf IN lv_bp_fullname WITH ' '.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>newline IN lv_bp_fullname WITH ' '.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>horizontal_tab IN lv_bp_fullname WITH ' '.

    LOOP AT lt_but0bk_raw INTO ls_but0bk_raw WHERE partner = ls_but000_raw-partner.
      lv_has_bank = 'X'.
      lv_bank_name = '-'.

      READ TABLE lt_bnka_raw INTO ls_bnka_raw
        WITH KEY banks = ls_but0bk_raw-banks
                 bankl = ls_but0bk_raw-bankl.
      IF sy-subrc = 0 AND ls_bnka_raw-banka IS NOT INITIAL.
        lv_bank_name = ls_bnka_raw-banka.
        REPLACE ALL OCCURRENCES OF '\' IN lv_bank_name WITH '\\'.
        REPLACE ALL OCCURRENCES OF '"' IN lv_bank_name WITH '\"'.
        REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf IN lv_bank_name WITH ' '.
        REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>newline IN lv_bank_name WITH ' '.
        REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>horizontal_tab IN lv_bank_name WITH ' '.
      ENDIF.

      DATA: lv_bankn_str TYPE string.
      lv_bankn_str = ls_but0bk_raw-bankn.
      REPLACE ALL OCCURRENCES OF '\' IN lv_bankn_str WITH '\\'.
      REPLACE ALL OCCURRENCES OF '"' IN lv_bankn_str WITH '\"'.
      REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf IN lv_bankn_str WITH ' '.
      REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>newline IN lv_bankn_str WITH ' '.
      REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>horizontal_tab IN lv_bankn_str WITH ' '.

      CONCATENATE lv_bp_json lv_bp_sep
                  '{"lifnr":"' ls_but000_raw-partner
                  '","name":"' lv_bp_fullname
                  '","bankn":"' lv_bankn_str
                  '","bank":"' lv_bank_name '"}'
                  INTO lv_bp_json.
      lv_bp_sep = ','.
    ENDLOOP.

    IF lv_has_bank = ' '.
      CONCATENATE lv_bp_json lv_bp_sep
                  '{"lifnr":"' ls_but000_raw-partner
                  '","name":"' lv_bp_fullname
                  '","bankn":"-","bank":"-"}'
                  INTO lv_bp_json.
      lv_bp_sep = ','.
    ENDIF.
  ENDLOOP.
ELSE.
  LOOP AT lt_lfa1_raw INTO ls_lfa1_raw.
    lv_name_upper = ls_lfa1_raw-name1.
    TRANSLATE lv_name_upper TO UPPER CASE.

    IF lv_name_upper CS 'NOT USED' OR
       lv_name_upper CS 'NOT-USED' OR
       lv_name_upper CS 'DO NOT USE' OR
       lv_name_upper CS 'DUMMY' OR
       lv_name_upper IS INITIAL.
      CONTINUE.
    ENDIF.

    lv_total_bp_num = lv_total_bp_num + 1.
    lv_has_bank = ' '.

    DATA: lv_lfa1_name TYPE string.
    lv_lfa1_name = ls_lfa1_raw-name1.
    REPLACE ALL OCCURRENCES OF '\' IN lv_lfa1_name WITH '\\'.
    REPLACE ALL OCCURRENCES OF '"' IN lv_lfa1_name WITH '\"'.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf IN lv_lfa1_name WITH ' '.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>newline IN lv_lfa1_name WITH ' '.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>horizontal_tab IN lv_lfa1_name WITH ' '.

    LOOP AT lt_lfbk_raw INTO ls_lfbk_raw WHERE lifnr = ls_lfa1_raw-lifnr.
      lv_has_bank = 'X'.
      lv_bank_name = '-'.

      READ TABLE lt_bnka_raw INTO ls_bnka_raw
        WITH KEY banks = ls_lfbk_raw-banks
                 bankl = ls_lfbk_raw-bankl.
      IF sy-subrc = 0 AND ls_bnka_raw-banka IS NOT INITIAL.
        lv_bank_name = ls_bnka_raw-banka.
        REPLACE ALL OCCURRENCES OF '\' IN lv_bank_name WITH '\\'.
        REPLACE ALL OCCURRENCES OF '"' IN lv_bank_name WITH '\"'.
        REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf IN lv_bank_name WITH ' '.
        REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>newline IN lv_bank_name WITH ' '.
        REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>horizontal_tab IN lv_bank_name WITH ' '.
      ENDIF.

      lv_bankn_str = ls_lfbk_raw-bankn.
      REPLACE ALL OCCURRENCES OF '\' IN lv_bankn_str WITH '\\'.
      REPLACE ALL OCCURRENCES OF '"' IN lv_bankn_str WITH '\"'.
      REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf IN lv_bankn_str WITH ' '.
      REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>newline IN lv_bankn_str WITH ' '.
      REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>horizontal_tab IN lv_bankn_str WITH ' '.

      CONCATENATE lv_bp_json lv_bp_sep
                  '{"lifnr":"' ls_lfa1_raw-lifnr
                  '","name":"' lv_lfa1_name
                  '","bankn":"' lv_bankn_str
                  '","bank":"' lv_bank_name '"}'
                  INTO lv_bp_json.
      lv_bp_sep = ','.
    ENDLOOP.

    IF lv_has_bank = ' '.
      CONCATENATE lv_bp_json lv_bp_sep
                  '{"lifnr":"' ls_lfa1_raw-lifnr
                  '","name":"' lv_lfa1_name
                  '","bankn":"-","bank":"-"}'
                  INTO lv_bp_json.
      lv_bp_sep = ','.
    ENDIF.
  ENDLOOP.
ENDIF.
CONCATENATE lv_bp_json ']' INTO lv_bp_json.
IF lv_bp_json = '[' OR lv_bp_json IS INITIAL.
  lv_bp_json = '[]'.
ENDIF.

lv_total_bp = lv_total_bp_num.
CONDENSE lv_total_bp.

" 4. FLOW DATA CUSTOMER: Ambil data Customer dari KNA1 / KNBK / BNKA / KNVI
TYPES: BEGIN OF ty_kna1_raw,
         kunnr TYPE kna1-kunnr,
         name1 TYPE kna1-name1,
         stras TYPE kna1-stras,
         ort01 TYPE kna1-ort01,
         pstlz TYPE kna1-pstlz,
         land1 TYPE kna1-land1,
         stcd1 TYPE kna1-stcd1,
         stcd2 TYPE kna1-stcd2,
         stkzn TYPE kna1-stkzn,
         loevm TYPE kna1-loevm,
       END OF ty_kna1_raw.

DATA: lt_kna1_raw       TYPE TABLE OF ty_kna1_raw,
      ls_kna1_raw       TYPE ty_kna1_raw,
      lv_total_cust_num TYPE i VALUE 0,
      lv_total_cust     TYPE string,
      lv_cust_json      TYPE string,
      lv_cust_sep       TYPE string,
      lv_c_name_upper   TYPE string,
      lv_c_name_clean   TYPE string,
      lv_c_address      TYPE string,
      lv_c_has_bank     TYPE c,
      lv_cbankn_str     TYPE string,
      lv_c_stras        TYPE string,
      lv_c_ort01        TYPE string,
      lv_c_pstlz        TYPE string,
      lv_c_land1        TYPE string,
      lv_c_stcd1        TYPE string,
      lv_c_banks        TYPE string,
      lv_c_bankl        TYPE string,
      lv_c_koinh        TYPE string,
      lv_c_tatyp        TYPE string,
      lv_c_taxkd        TYPE string.

TYPES: BEGIN OF ty_knbk_raw,
         kunnr TYPE knbk-kunnr,
         banks TYPE knbk-banks,
         bankl TYPE knbk-bankl,
         bankn TYPE knbk-bankn,
         koinh TYPE knbk-koinh,
       END OF ty_knbk_raw.

DATA: lt_knbk_raw TYPE TABLE OF ty_knbk_raw,
      ls_knbk_raw TYPE ty_knbk_raw.

TYPES: BEGIN OF ty_knvi_raw,
         kunnr TYPE knvi-kunnr,
         tatyp TYPE knvi-tatyp,
         taxkd TYPE knvi-taxkd,
       END OF ty_knvi_raw.

DATA: lt_knvi_raw TYPE TABLE OF ty_knvi_raw,
      ls_knvi_raw TYPE ty_knvi_raw.

SELECT COUNT( * ) FROM kna1 INTO lv_total_cust_num WHERE loevm = ' '.
IF lv_total_cust_num = 0.
  SELECT COUNT( * ) FROM kna1 INTO lv_total_cust_num.
ENDIF.
lv_total_cust = lv_total_cust_num.
CONDENSE lv_total_cust.

SELECT kunnr name1 stras ort01 pstlz land1 stcd1 stcd2 stkzn loevm FROM kna1 INTO TABLE lt_kna1_raw WHERE loevm = ' '.
IF lt_kna1_raw IS INITIAL.
  SELECT kunnr name1 stras ort01 pstlz land1 stcd1 stcd2 stkzn loevm FROM kna1 INTO TABLE lt_kna1_raw.
ENDIF.

IF lt_kna1_raw IS NOT INITIAL.
  SELECT kunnr banks bankl bankn koinh FROM knbk INTO TABLE lt_knbk_raw FOR ALL ENTRIES IN lt_kna1_raw WHERE kunnr = lt_kna1_raw-kunnr.
  IF lt_knbk_raw IS NOT INITIAL.
    SELECT banks bankl banka FROM bnka INTO TABLE lt_bnka_raw FOR ALL ENTRIES IN lt_knbk_raw WHERE banks = lt_knbk_raw-banks AND bankl = lt_knbk_raw-bankl.
  ENDIF.
  SELECT kunnr tatyp taxkd FROM knvi INTO TABLE lt_knvi_raw FOR ALL ENTRIES IN lt_kna1_raw WHERE kunnr = lt_kna1_raw-kunnr.
ENDIF.

lv_cust_json = '['.
lv_cust_sep = ''.

IF lt_kna1_raw IS NOT INITIAL.
  LOOP AT lt_kna1_raw INTO ls_kna1_raw.
    lv_c_name_upper = ls_kna1_raw-name1.
    TRANSLATE lv_c_name_upper TO UPPER CASE.

    IF lv_c_name_upper CS 'NOT USED' OR
       lv_c_name_upper CS 'NOT-USED' OR
       lv_c_name_upper CS 'DO NOT USE' OR
       lv_c_name_upper CS 'DUMMY' OR
       lv_c_name_upper IS INITIAL.
      CONTINUE.
    ENDIF.

    " Alamat Components
    lv_c_stras = ls_kna1_raw-stras.
    lv_c_ort01 = ls_kna1_raw-ort01.
    lv_c_pstlz = ls_kna1_raw-pstlz.
    lv_c_land1 = ls_kna1_raw-land1.

    CLEAR lv_c_address.
    IF lv_c_stras IS NOT INITIAL.
      lv_c_address = lv_c_stras.
    ENDIF.
    IF lv_c_ort01 IS NOT INITIAL.
      IF lv_c_address IS INITIAL.
        lv_c_address = lv_c_ort01.
      ELSE.
        CONCATENATE lv_c_address ', ' lv_c_ort01 INTO lv_c_address.
      ENDIF.
    ENDIF.
    IF lv_c_pstlz IS NOT INITIAL.
      IF lv_c_address IS INITIAL.
        lv_c_address = lv_c_pstlz.
      ELSE.
        CONCATENATE lv_c_address ' ' lv_c_pstlz INTO lv_c_address.
      ENDIF.
    ENDIF.
    IF lv_c_land1 IS NOT INITIAL.
      IF lv_c_address IS INITIAL.
        lv_c_address = lv_c_land1.
      ELSE.
        CONCATENATE lv_c_address ', ' lv_c_land1 INTO lv_c_address.
      ENDIF.
    ENDIF.
    IF lv_c_address IS INITIAL.
      lv_c_address = '-'.
    ENDIF.

    " Tax Info
    lv_c_stcd1 = ls_kna1_raw-stcd1.
    IF lv_c_stcd1 IS INITIAL.
      lv_c_stcd1 = ls_kna1_raw-stcd2.
    ENDIF.

    CLEAR: lv_c_tatyp, lv_c_taxkd.
    READ TABLE lt_knvi_raw INTO ls_knvi_raw WITH KEY kunnr = ls_kna1_raw-kunnr.
    IF sy-subrc = 0.
      lv_c_tatyp = ls_knvi_raw-tatyp.
      lv_c_taxkd = ls_knvi_raw-taxkd.
    ENDIF.

    " Comprehensive String Sanitization for Customer Data
    lv_c_name_clean = ls_kna1_raw-name1.
    REPLACE ALL OCCURRENCES OF '\' IN lv_c_name_clean WITH '\\'.
    REPLACE ALL OCCURRENCES OF '"' IN lv_c_name_clean WITH '\"'.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf IN lv_c_name_clean WITH ' '.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>newline IN lv_c_name_clean WITH ' '.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>horizontal_tab IN lv_c_name_clean WITH ' '.

    REPLACE ALL OCCURRENCES OF '\' IN lv_c_address WITH '\\'.
    REPLACE ALL OCCURRENCES OF '"' IN lv_c_address WITH '\"'.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf IN lv_c_address WITH ' '.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>newline IN lv_c_address WITH ' '.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>horizontal_tab IN lv_c_address WITH ' '.

    REPLACE ALL OCCURRENCES OF '\' IN lv_c_stras WITH '\\'.
    REPLACE ALL OCCURRENCES OF '"' IN lv_c_stras WITH '\"'.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf IN lv_c_stras WITH ' '.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>newline IN lv_c_stras WITH ' '.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>horizontal_tab IN lv_c_stras WITH ' '.

    REPLACE ALL OCCURRENCES OF '\' IN lv_c_ort01 WITH '\\'.
    REPLACE ALL OCCURRENCES OF '"' IN lv_c_ort01 WITH '\"'.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf IN lv_c_ort01 WITH ' '.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>newline IN lv_c_ort01 WITH ' '.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>horizontal_tab IN lv_c_ort01 WITH ' '.

    REPLACE ALL OCCURRENCES OF '\' IN lv_c_pstlz WITH '\\'.
    REPLACE ALL OCCURRENCES OF '"' IN lv_c_pstlz WITH '\"'.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf IN lv_c_pstlz WITH ' '.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>newline IN lv_c_pstlz WITH ' '.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>horizontal_tab IN lv_c_pstlz WITH ' '.

    REPLACE ALL OCCURRENCES OF '\' IN lv_c_land1 WITH '\\'.
    REPLACE ALL OCCURRENCES OF '"' IN lv_c_land1 WITH '\"'.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf IN lv_c_land1 WITH ' '.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>newline IN lv_c_land1 WITH ' '.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>horizontal_tab IN lv_c_land1 WITH ' '.

    REPLACE ALL OCCURRENCES OF '\' IN lv_c_stcd1 WITH '\\'.
    REPLACE ALL OCCURRENCES OF '"' IN lv_c_stcd1 WITH '\"'.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf IN lv_c_stcd1 WITH ' '.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>newline IN lv_c_stcd1 WITH ' '.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>horizontal_tab IN lv_c_stcd1 WITH ' '.

    REPLACE ALL OCCURRENCES OF '\' IN lv_c_tatyp WITH '\\'.
    REPLACE ALL OCCURRENCES OF '"' IN lv_c_tatyp WITH '\"'.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf IN lv_c_tatyp WITH ' '.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>newline IN lv_c_tatyp WITH ' '.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>horizontal_tab IN lv_c_tatyp WITH ' '.

    REPLACE ALL OCCURRENCES OF '\' IN lv_c_taxkd WITH '\\'.
    REPLACE ALL OCCURRENCES OF '"' IN lv_c_taxkd WITH '\"'.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf IN lv_c_taxkd WITH ' '.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>newline IN lv_c_taxkd WITH ' '.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>horizontal_tab IN lv_c_taxkd WITH ' '.

    lv_c_has_bank = ' '.

    LOOP AT lt_knbk_raw INTO ls_knbk_raw WHERE kunnr = ls_kna1_raw-kunnr.
      lv_c_has_bank = 'X'.
      lv_bank_name = '-'.

      READ TABLE lt_bnka_raw INTO ls_bnka_raw
        WITH KEY banks = ls_knbk_raw-banks
                 bankl = ls_knbk_raw-bankl.
      IF sy-subrc = 0 AND ls_bnka_raw-banka IS NOT INITIAL.
        lv_bank_name = ls_bnka_raw-banka.
        REPLACE ALL OCCURRENCES OF '\' IN lv_bank_name WITH '\\'.
        REPLACE ALL OCCURRENCES OF '"' IN lv_bank_name WITH '\"'.
        REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf IN lv_bank_name WITH ' '.
        REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>newline IN lv_bank_name WITH ' '.
        REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>horizontal_tab IN lv_bank_name WITH ' '.
      ENDIF.

      lv_cbankn_str = ls_knbk_raw-bankn.
      REPLACE ALL OCCURRENCES OF '\' IN lv_cbankn_str WITH '\\'.
      REPLACE ALL OCCURRENCES OF '"' IN lv_cbankn_str WITH '\"'.
      REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf IN lv_cbankn_str WITH ' '.
      REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>newline IN lv_cbankn_str WITH ' '.
      REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>horizontal_tab IN lv_cbankn_str WITH ' '.

      lv_c_banks = ls_knbk_raw-banks.
      lv_c_bankl = ls_knbk_raw-bankl.
      lv_c_koinh = ls_knbk_raw-koinh.
      IF lv_c_koinh IS INITIAL.
        lv_c_koinh = lv_c_name_clean.
      ENDIF.

      REPLACE ALL OCCURRENCES OF '\' IN lv_c_banks WITH '\\'.
      REPLACE ALL OCCURRENCES OF '"' IN lv_c_banks WITH '\"'.
      REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf IN lv_c_banks WITH ' '.
      REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>newline IN lv_c_banks WITH ' '.
      REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>horizontal_tab IN lv_c_banks WITH ' '.

      REPLACE ALL OCCURRENCES OF '\' IN lv_c_bankl WITH '\\'.
      REPLACE ALL OCCURRENCES OF '"' IN lv_c_bankl WITH '\"'.
      REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf IN lv_c_bankl WITH ' '.
      REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>newline IN lv_c_bankl WITH ' '.
      REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>horizontal_tab IN lv_c_bankl WITH ' '.

      REPLACE ALL OCCURRENCES OF '\' IN lv_c_koinh WITH '\\'.
      REPLACE ALL OCCURRENCES OF '"' IN lv_c_koinh WITH '\"'.
      REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf IN lv_c_koinh WITH ' '.
      REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>newline IN lv_c_koinh WITH ' '.
      REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>horizontal_tab IN lv_c_koinh WITH ' '.

      CONCATENATE lv_cust_json lv_cust_sep
                  '{"kunnr":"' ls_kna1_raw-kunnr
                  '","name":"' lv_c_name_clean
                  '","address":"' lv_c_address
                  '","stras":"' lv_c_stras
                  '","ort01":"' lv_c_ort01
                  '","pstlz":"' lv_c_pstlz
                  '","land1":"' lv_c_land1
                  '","banks":"' lv_c_banks
                  '","bankl":"' lv_c_bankl
                  '","bankn":"' lv_cbankn_str
                  '","bank":"' lv_bank_name
                  '","koinh":"' lv_c_koinh
                  '","stcd1":"' lv_c_stcd1
                  '","tatyp":"' lv_c_tatyp
                  '","taxkd":"' lv_c_taxkd '"}'
                  INTO lv_cust_json.
      lv_cust_sep = ','.
    ENDLOOP.

    IF lv_c_has_bank = ' '.
      CONCATENATE lv_cust_json lv_cust_sep
                  '{"kunnr":"' ls_kna1_raw-kunnr
                  '","name":"' lv_c_name_clean
                  '","address":"' lv_c_address
                  '","stras":"' lv_c_stras
                  '","ort01":"' lv_c_ort01
                  '","pstlz":"' lv_c_pstlz
                  '","land1":"' lv_c_land1
                  '","banks":"-","bankl":"-","bankn":"-","bank":"-","koinh":"' lv_c_name_clean
                  '","stcd1":"' lv_c_stcd1
                  '","tatyp":"' lv_c_tatyp
                  '","taxkd":"' lv_c_taxkd '"}'
                  INTO lv_cust_json.
      lv_cust_sep = ','.
    ENDIF.
  ENDLOOP.
ENDIF.
CONCATENATE lv_cust_json ']' INTO lv_cust_json.
IF lv_cust_json = '[' OR lv_cust_json IS INITIAL.
  lv_cust_json = '[]'.
ENDIF.

" Total Entities dinamis (Material + BP + Cust + Fin)
DATA: lv_total_ent_num TYPE i.
lv_total_ent_num = lv_total_mat_num + lv_total_bp_num + lv_total_cust_num + 7215.
lv_total_ent = lv_total_ent_num.
CONDENSE lv_total_ent.
