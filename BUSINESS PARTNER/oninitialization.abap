*======================================================================*
* BSP EVENT HANDLER: OnInitialization
* Application: ZBP_REQUEST | Page: bp_request.htm
* Environment: SAP S/4HANA 1809
*======================================================================*

CLEAR: gt_messages, gt_duplicates, gv_show_dup_alert.

" 1. Retrieve URL Parameters
gv_req_id    = request->get_form_field( 'req_id' ).
gv_user_mode = request->get_form_field( 'mode' ).

TRANSLATE gv_user_mode TO UPPER CASE.

" 2. Load Existing Request if ID supplied
IF gv_req_id IS NOT INITIAL.
  SELECT SINGLE *
    FROM ztb_bp_req
    INTO CORRESPONDING FIELDS OF wa_req
   WHERE req_id = gv_req_id.

  IF sy-subrc = 0.
    " Automatically route to APPROVER view if status is SUBMITTED and mode not forced
    IF gv_user_mode IS INITIAL.
      IF wa_req-status = 'SUBMITTED'.
        gv_user_mode = 'APPROVER'.
      ELSE.
        gv_user_mode = 'DRAFTER'.
      ENDIF.
    ENDIF.
  ELSE.
    APPEND VALUE #( type = 'E' message = |Request ID { gv_req_id } not found.| ) TO gt_messages.
    gv_user_mode = 'DRAFTER'.
  ENDIF.
ELSE.
  " 3. Initialize Default Values for New Draft
  gv_user_mode = 'DRAFTER'.
  wa_req-bp_category = '2'.        " 2 = Organization
  wa_req-bp_role     = 'FLVN00'.   " Supplier (Financial Accounting)
  wa_req-country     = 'ID'.       " Indonesia
  wa_req-region      = '01'.       " DKI Jakarta
  wa_req-tax_type    = 'ID1'.      " Indonesian NPWP
  wa_req-waers       = 'IDR'.
  wa_req-bukrs       = '1000'.     " Default Company Code
  wa_req-akont       = '21110000'. " Default Trade Payable
  wa_req-zterm       = '0001'.     " Immediate Payment
  wa_req-status      = 'DRAFT'.
  wa_req-created_by  = sy-uname.
  GET TIME STAMP FIELD wa_req-created_at.
ENDIF.

" 4. Populate Dropdown Buffers
CLEAR: gt_roles, gt_countries, gt_regions.

" Roles
APPEND VALUE #( key = 'FLVN00' value = 'Vendor / Supplier (FI: FLVN00)' ) TO gt_roles.
APPEND VALUE #( key = 'FLCU00' value = 'Customer (FI: FLCU00)' )          TO gt_roles.
APPEND VALUE #( key = 'BUP000' value = 'General Business Partner (BUP000)' ) TO gt_roles.

" Countries
APPEND VALUE #( key = 'ID' value = 'Indonesia (ID)' ) TO gt_countries.
APPEND VALUE #( key = 'SG' value = 'Singapore (SG)' ) TO gt_countries.
APPEND VALUE #( key = 'MY' value = 'Malaysia (MY)' )  TO gt_countries.
APPEND VALUE #( key = 'JP' value = 'Japan (JP)' )      TO gt_countries.
APPEND VALUE #( key = 'US' value = 'United States (US)' ) TO gt_countries.

" Regions (Indonesian Provinces)
APPEND VALUE #( key = '01' value = 'DKI Jakarta' )     TO gt_regions.
APPEND VALUE #( key = '02' value = 'Jawa Barat' )      TO gt_regions.
APPEND VALUE #( key = '03' value = 'Jawa Tengah' )     TO gt_regions.
APPEND VALUE #( key = '04' value = 'DI Yogyakarta' )   TO gt_regions.
APPEND VALUE #( key = '05' value = 'Jawa Timur' )      TO gt_regions.
APPEND VALUE #( key = '06' value = 'Banten' )          TO gt_regions.
APPEND VALUE #( key = '07' value = 'Bali' )            TO gt_regions.
