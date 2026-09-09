*======================================================================*
* BSP EVENT HANDLER: OnInputProcessing
* Application: ZBP_REQUEST | Page: bp_request.htm
* Environment: SAP S/4HANA 1809
*======================================================================*

DATA: lv_action     TYPE string,
      lv_tax_clean  TYPE string,
      lv_dup_count  TYPE i,
      lv_msg        TYPE string,
      lv_partner    TYPE bu_partner,
      lt_return     TYPE bapiret2_t,
      ls_return     TYPE bapiret2,
      ls_db_req     TYPE ztb_bp_req.

CLEAR: gt_messages, gt_duplicates, gv_show_dup_alert.

" 1. Retrieve Action Name and State
lv_action    = request->get_form_field( 'onInputProcessing(action)' ).
gv_user_mode = request->get_form_field( 'mode' ).

" 2. Capture Form Inputs into Workarea
wa_req-req_id           = request->get_form_field( 'req_id' ).
wa_req-bp_category      = request->get_form_field( 'bp_category' ).
wa_req-bp_role          = request->get_form_field( 'bp_role' ).
wa_req-name1            = request->get_form_field( 'name1' ).
wa_req-name2            = request->get_form_field( 'name2' ).
wa_req-search_term      = request->get_form_field( 'search_term' ).
wa_req-tax_num          = request->get_form_field( 'tax_num' ).
wa_req-street           = request->get_form_field( 'street' ).
wa_req-house_num        = request->get_form_field( 'house_num' ).
wa_req-city             = request->get_form_field( 'city' ).
wa_req-postal_code      = request->get_form_field( 'postal_code' ).
wa_req-country          = request->get_form_field( 'country' ).
wa_req-region           = request->get_form_field( 'region' ).
wa_req-bukrs            = request->get_form_field( 'bukrs' ).
wa_req-akont            = request->get_form_field( 'akont' ).
wa_req-zterm            = request->get_form_field( 'zterm' ).
wa_req-rejection_reason = request->get_form_field( 'rejection_reason' ).

" Normalize Tax Number (remove spaces, dots, dashes for exact clean lookup)
lv_tax_clean = wa_req-tax_num.
REPLACE ALL OCCURRENCES OF REGEX '[^0-9A-Za-z]' IN lv_tax_clean WITH ''.

"----------------------------------------------------------------------
" ACTION: CHECK_DUP or SUBMIT (Validation & Deduplication Engine)
"----------------------------------------------------------------------
IF lv_action = 'CHECK_DUP' OR lv_action = 'SUBMIT'.

  " A. Mandatory Fields Validation
  IF lv_action = 'SUBMIT'.
    IF wa_req-name1 IS INITIAL.
      APPEND VALUE #( type = 'E' message = 'Legal Name 1 is mandatory.' ) TO gt_messages.
    ENDIF.
    IF wa_req-tax_num IS INITIAL.
      APPEND VALUE #( type = 'E' message = 'Tax ID / NPWP is mandatory.' ) TO gt_messages.
    ENDIF.
    IF wa_req-city IS INITIAL.
      APPEND VALUE #( type = 'E' message = 'City is mandatory.' ) TO gt_messages.
    ENDIF.
    IF wa_req-country IS INITIAL.
      APPEND VALUE #( type = 'E' message = 'Country is mandatory.' ) TO gt_messages.
    ENDIF.
  ELSEIF lv_action = 'CHECK_DUP'.
    " For Search & Duplicate Check, at least NPWP or Name must be specified
    IF wa_req-tax_num IS INITIAL AND wa_req-name1 IS INITIAL.
      APPEND VALUE #( type = 'E' message = 'Specify Tax Number / NPWP or Partner Name to search.' ) TO gt_messages.
    ENDIF.
  ENDIF.

  IF gt_messages IS NOT INITIAL.
    RETURN.
  ENDIF.

  " B. Multi-Table Duplicate Search Engine
  CLEAR gt_duplicates.

  " Check 1: DFKKBPTAXNUM (Active Business Partner Tax Registry)
  IF lv_tax_clean IS NOT INITIAL.
    SELECT partner, taxnum
      FROM dfkkbptaxnum
      INTO TABLE @DATA(lt_tax_hits)
      UP TO 10 ROWS
     WHERE taxnum = @wa_req-tax_num
        OR taxnum = @lv_tax_clean.

    DATA: lv_dup_name    TYPE bu_nameor1,
          lv_dup_city    TYPE ad_city1,
          lv_dup_country TYPE land1.

    LOOP AT lt_tax_hits INTO DATA(ls_tax_hit).
      CLEAR: lv_dup_name, lv_dup_city, lv_dup_country.

      " 1. Retrieve Legal Entity Name from BUT000
      SELECT SINGLE name_org1
        FROM but000
       WHERE partner = @ls_tax_hit-partner
        INTO @lv_dup_name.

      " 2. Retrieve Address via link table BUT020 (BP: Addresses) and ADRC
      SELECT SINGLE adrc~city1, adrc~country
        FROM but020
        INNER JOIN adrc ON but020~addrnumber = adrc~addrnumber
       WHERE but020~partner = @ls_tax_hit-partner
        INTO (@lv_dup_city, @lv_dup_country).

      APPEND VALUE #(
        bp_number    = ls_tax_hit-partner
        name         = lv_dup_name
        tax_num      = ls_tax_hit-taxnum
        city         = lv_dup_city
        country      = lv_dup_country
        source_table = 'DFKKBPTAX'
        match_reason = 'Exact Match on NPWP (DFKKBPTAXNUM)'
      ) TO gt_duplicates.
    ENDLOOP.
  ENDIF.

  " Check 2: BUT000 (Central BP Organization Name Search)
  DATA: lv_mc_name TYPE but000-mc_name1.
  lv_mc_name = wa_req-name1.
  TRANSLATE lv_mc_name TO UPPER CASE.

  SELECT partner, name_org1
    FROM but000
    INTO TABLE @DATA(lt_name_hits)
    UP TO 5 ROWS
   WHERE mc_name1 = @lv_mc_name.

  LOOP AT lt_name_hits INTO DATA(ls_name_hit).
    " Prevent duplicate entries if already caught by Tax Number check
    IF NOT line_exists( gt_duplicates[ bp_number = ls_name_hit-partner ] ).
      APPEND VALUE #(
        bp_number    = ls_name_hit-partner
        name         = ls_name_hit-name_org1
        tax_num      = 'N/A'
        city         = wa_req-city
        country      = wa_req-country
        source_table = 'BUT000'
        match_reason = 'Exact Match on Organization Name (BUT000)'
      ) TO gt_duplicates.
    ENDIF.
  ENDLOOP.

  " Check 3: LFA1 (Legacy / Synchronized Vendors by STCEG)
  IF lv_tax_clean IS NOT INITIAL.
    SELECT lifnr, name1, stceg, ort01, land1
      FROM lfa1
      INTO TABLE @DATA(lt_lfa1_hits)
      UP TO 5 ROWS
     WHERE stceg = @wa_req-tax_num
        OR stceg = @lv_tax_clean.

    LOOP AT lt_lfa1_hits INTO DATA(ls_lfa1).
      APPEND VALUE #(
        bp_number    = |V-{ ls_lfa1-lifnr }|
        name         = ls_lfa1-name1
        tax_num      = ls_lfa1-stceg
        city         = ls_lfa1-ort01
        country      = ls_lfa1-land1
        source_table = 'LFA1'
        match_reason = 'Exact Match on Vendor VAT Reg. (LFA1)'
      ) TO gt_duplicates.
    ENDLOOP.
  ENDIF.

  " Duplicate Evaluation
  DESCRIBE TABLE gt_duplicates LINES lv_dup_count.
  IF lv_dup_count > 0.
    gv_show_dup_alert = 'X'.
    APPEND VALUE #(
      type    = 'W'
      message = |{ lv_dup_count } potential duplicate record(s) found in active SAP tables.|
    ) TO gt_messages.

    " If user clicked 'CHECK_DUP', stop here so they can inspect matches
    IF lv_action = 'CHECK_DUP'.
      RETURN.
    ENDIF.
  ENDIF.

  " If Action = 'SUBMIT' and no hard validation errors:
  IF lv_action = 'SUBMIT'.
    IF wa_req-req_id IS INITIAL.
      " Generate unique 10-character Request ID
      DATA: lv_guid TYPE sysuuid_c32.
      CALL FUNCTION 'GUID_CREATE'
        IMPORTING
          ev_guid_32 = lv_guid.
      wa_req-req_id = lv_guid(10).
    ENDIF.

    wa_req-status     = 'SUBMITTED'.
    wa_req-created_by = sy-uname.
    GET TIME STAMP FIELD wa_req-created_at.

    MOVE-CORRESPONDING wa_req TO ls_db_req.
    ls_db_req-mandt = sy-mandt.
    MODIFY ztb_bp_req FROM @ls_db_req.
    IF sy-subrc = 0.
      COMMIT WORK AND WAIT.
      APPEND VALUE #(
        type    = 'S'
        message = |Request { wa_req-req_id } submitted successfully. Awaiting Steward approval.|
      ) TO gt_messages.
      gv_user_mode = 'APPROVER'.
    ELSE.
      ROLLBACK WORK.
      APPEND VALUE #( type = 'E' message = 'Database error while saving staging request.' ) TO gt_messages.
    ENDIF.
  ENDIF.

"----------------------------------------------------------------------
" ACTION: SAVE_DRAFT
"----------------------------------------------------------------------
ELSEIF lv_action = 'SAVE_DRAFT'.
  IF wa_req-req_id IS INITIAL.
    DATA: lv_temp_guid TYPE sysuuid_c32.
    CALL FUNCTION 'GUID_CREATE'
      IMPORTING
        ev_guid_32 = lv_temp_guid.
    wa_req-req_id = lv_temp_guid(10).
  ENDIF.

  wa_req-status     = 'DRAFT'.
  wa_req-created_by = sy-uname.
  GET TIME STAMP FIELD wa_req-created_at.

  MOVE-CORRESPONDING wa_req TO ls_db_req.
  ls_db_req-mandt = sy-mandt.
  MODIFY ztb_bp_req FROM @ls_db_req.
  IF sy-subrc = 0.
    COMMIT WORK.
    APPEND VALUE #( type = 'S' message = |Draft { wa_req-req_id } saved successfully.| ) TO gt_messages.
  ENDIF.

"----------------------------------------------------------------------
" ACTION: APPROVE (Master Data Steward: CVI & BAPI Activation)
"----------------------------------------------------------------------
ELSEIF lv_action = 'APPROVE'.

  DATA: ls_central_org TYPE bapibus1006_central_organ,
        ls_central     TYPE bapibus1006_central,
        ls_address     TYPE bapibus1006_address,
        lt_ret_bapi    TYPE bapiret2_t,
        lv_new_bp      TYPE bu_partner.

  " Prepare Organization Header
  ls_central_org-name1   = wa_req-name1.
  ls_central_org-name2   = wa_req-name2.

  " Prepare Central Data (Search Term 1 belongs to Central Data)
  ls_central-searchterm1 = wa_req-search_term.

  " Prepare Standard Address Data
  ls_address-street     = wa_req-street.
  ls_address-house_no   = wa_req-house_num.
  ls_address-city       = wa_req-city.
  ls_address-postl_cod1 = wa_req-postal_code.
  ls_address-country    = wa_req-country.
  ls_address-region     = wa_req-region.

  " Step 1: Create Business Partner (Organization Category = '2')
  CALL FUNCTION 'BAPI_BUPA_CREATE_FROM_DATA'
    EXPORTING
      partnercategory         = '2'
      centraldata             = ls_central
      centraldataorganization = ls_central_org
      addressdata             = ls_address
    IMPORTING
      businesspartner         = lv_new_bp
    TABLES
      return                  = lt_ret_bapi.

  READ TABLE lt_ret_bapi INTO ls_return WITH KEY type = 'E'.
  IF sy-subrc = 0.
    ROLLBACK WORK.
    APPEND VALUE #( type = 'E' message = |BAPI Error: { ls_return-message }| ) TO gt_messages.
    RETURN.
  ENDIF.

  " Step 2: Add Tax Number / NPWP (Tax Type: 'ID1')
  IF wa_req-tax_num IS NOT INITIAL.
    CALL FUNCTION 'BAPI_BUPA_TAX_ADD'
      EXPORTING
        businesspartner = lv_new_bp
        taxtype         = 'ID1'
        taxnumber       = wa_req-tax_num
      TABLES
        return          = lt_ret_bapi.
  ENDIF.

  " Step 3: Add Primary Role (e.g. FLVN00 = Supplier FI, FLCU00 = Customer FI)
  CALL FUNCTION 'BAPI_BUPA_ROLE_ADD_2'
    EXPORTING
      businesspartner             = lv_new_bp
      businesspartnerrolecategory = wa_req-bp_role
      businesspartnerrole         = wa_req-bp_role
    TABLES
      return                      = lt_ret_bapi.

  " Step 4: CVI Vendor Company Code Synchronization (via VMD_EI_API)
  IF wa_req-bp_role = 'FLVN00' AND wa_req-bukrs IS NOT INITIAL.
    DATA: ls_vmd_main  TYPE vmds_ei_main,
          ls_vendor    TYPE vmds_ei_extern,
          ls_cpi_def   TYPE cvis_message,
          ls_cpi_corr  TYPE cvis_message.

    " Use LIFNR (vendor instance key) instead of non-existent BPARTNER
    ls_vendor-header-object_instance-lifnr = lv_new_bp.
    ls_vendor-header-object_task           = 'M'. " Maintain

    " Company Code Data
    APPEND INITIAL LINE TO ls_vendor-company_data-company ASSIGNING FIELD-SYMBOL(<fs_comp>).
    <fs_comp>-task          = 'I'. " Insert
    <fs_comp>-data_key-bukrs = wa_req-bukrs.
    <fs_comp>-data-akont    = wa_req-akont.
    <fs_comp>-data-zterm    = wa_req-zterm.
    <fs_comp>-datax-akont   = 'X'.
    <fs_comp>-datax-zterm   = 'X'.

    APPEND ls_vendor TO ls_vmd_main-vendors.

    CALL METHOD vmd_ei_api=>maintain_bapi
      EXPORTING
        is_master_data       = ls_vmd_main
      IMPORTING
        es_message_correct   = ls_cpi_corr
        es_message_defective = ls_cpi_def.

    IF ls_cpi_def-is_error = abap_true.
      LOOP AT ls_cpi_def-messages INTO DATA(ls_cvi_err) WHERE type = 'E'.
        APPEND VALUE #( type = 'W' message = |CVI Company Code Notice: { ls_cvi_err-message }| ) TO gt_messages.
      ENDLOOP.
    ENDIF.
  ENDIF.

  " Step 5: Final Commit to S/4HANA Master Data Database
  CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
    EXPORTING
      wait = 'X'.

  " Step 6: Update Staging Table Record
  wa_req-status    = 'APPROVED'.
  wa_req-bp_number = lv_new_bp.
  MOVE-CORRESPONDING wa_req TO ls_db_req.
  ls_db_req-mandt = sy-mandt.
  MODIFY ztb_bp_req FROM @ls_db_req.
  COMMIT WORK.

  APPEND VALUE #(
    type    = 'S'
    message = |Business Partner { lv_new_bp } activated & synchronized successfully in BUT000/LFA1!|
  ) TO gt_messages.

"----------------------------------------------------------------------
" ACTION: REJECT
"----------------------------------------------------------------------
ELSEIF lv_action = 'REJECT'.
  IF wa_req-rejection_reason IS INITIAL.
    APPEND VALUE #( type = 'E' message = 'Rejection reason is required.' ) TO gt_messages.
    RETURN.
  ENDIF.

  wa_req-status = 'REJECTED'.
  MOVE-CORRESPONDING wa_req TO ls_db_req.
  ls_db_req-mandt = sy-mandt.
  MODIFY ztb_bp_req FROM @ls_db_req.
  COMMIT WORK.

  APPEND VALUE #(
    type    = 'W'
    message = |Request { wa_req-req_id } rejected. Drafter has been notified.|
  ) TO gt_messages.

"----------------------------------------------------------------------
" ACTION: SWITCH_DRAFTER
"----------------------------------------------------------------------
ELSEIF lv_action = 'SWITCH_DRAFTER'.
  gv_user_mode = 'DRAFTER'.
ENDIF.
