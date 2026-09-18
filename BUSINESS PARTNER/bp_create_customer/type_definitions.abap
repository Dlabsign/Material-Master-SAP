*======================================================================*
* BSP TYPE DEFINITIONS: MDG Business Partner (Organization & Vendor)
* Application: ZBP_REQUEST | Page: bp_create_request.htm
* Schema: Matches Database Staging Table ZMDG_BP_REQ (SE11)
*======================================================================*

TYPES:
  "----------------------------------------------------------------------
  " 1. Request Staging Workarea Structure (Mirrors Table ZMDG_BP_REQ)
  "----------------------------------------------------------------------
  BEGIN OF ty_bp_request,
    mandt             TYPE mandt,          " Client
    req_id            TYPE char10,         " Request Key ID (e.g. BP26091401)
    bp_category       TYPE bu_type,        " 1 = Person, 2 = Organization
    bp_role           TYPE bu_partnerrole, " BP Role (e.g. 000000, FLVN00, FLVN01)
    bu_group          TYPE bu_group,       " BP Grouping (e.g. 0001 - Internal)
    name1             TYPE bu_nameor1,     " Name 1 (Mandatory, max 40)
    name2             TYPE bu_nameor2,     " Name 2 (Optional, max 40)
    search_term       TYPE bu_sort1,       " Search Term 1 (BU_SORT1, max 20)
    street            TYPE ad_street,      " Street (max 60)
    house_num         TYPE ad_hsnm1,       " House Number (max 10)
    city              TYPE ad_city1,       " City (Mandatory, max 40)
    postal_code       TYPE ad_pstcd1,      " Postal Code (max 10)
    country           TYPE land1,          " Country (Mandatory, default 'ID')
    region            TYPE regio,          " Region / Province (e.g. '08')
    telephone         TYPE ad_tlnmbr,      " Telephone (max 30)
    fax               TYPE char30,         " Fax Number (max 30)
    email             TYPE ad_smtpadr,     " E-Mail Address (max 241)
    langu             TYPE laiso,          " Language Key (Mandatory, default 'ID')
    tax_type          TYPE bptaxtype,      " Tax Category (e.g. 'ID1')
    tax_num           TYPE bptaxnum,       " NPWP / Tax Number
    banks             TYPE banks,          " Bank Country Key (e.g. 'ID')
    bankl             TYPE bankk,          " Bank Key (Kliring Bank)
    bankn             TYPE bankn,          " Bank Account Number
    koinh             TYPE text60,         " Account Holder Name
    bank_name         TYPE banka,          " Bank Name resolved from BNKA
    bukrs             TYPE bukrs,          " Company Code (Default: '1000')
    akont             TYPE akont,          " Reconciliation Account
    zterm             TYPE dzterm,         " Payment Terms
    waers             TYPE waers,          " Currency (Default: 'IDR')
    ekorg             TYPE ekorg,          " Purchasing Organization (e.g. '1000')
    webre             TYPE webre,          " GR-Based Inv. Verif. ('X')
    lebre             TYPE lebre,          " Srv.-Based Inv. Ver. ('X')
    status            TYPE char20,         " DRAFT, PENDING_REVIEW, POSTED, REJECTED
    rejection_reason  TYPE text255,        " Reason for Rejection
    stw_bank_status   TYPE char1,          " Steward Bank Status
    stw_bank_by       TYPE uname,          " Steward Bank User
    stw_bank_at       TYPE timestamp,      " Steward Bank Timestamp
    stw_bank_note     TYPE text255,        " Steward Bank Note
    stw_data_status   TYPE char1,          " Steward Data Status
    stw_data_by       TYPE uname,          " Steward Data User
    stw_data_at       TYPE timestamp,      " Steward Data Timestamp
    stw_data_note     TYPE text255,        " Steward Data Note
    appr_final_status TYPE char1,          " Final Approver Status
    appr_final_by     TYPE uname,          " Final Approver User
    appr_final_at     TYPE timestamp,      " Final Approver Timestamp
    appr_final_note   TYPE text255,        " Final Approver Note
    bp_number         TYPE bu_partner,     " Generated SAP BP Number
    error_log         TYPE text255,        " Technical / BAPI Error Log
    created_by        TYPE uname,          " Requester / Drafter User
    created_at        TYPE timestamp,      " Submission Timestamp
    changed_by        TYPE uname,          " Last Modifier User
    changed_at        TYPE timestamp,      " Modification Timestamp
  END OF ty_bp_request,
  ty_t_bp_request TYPE STANDARD TABLE OF ty_bp_request WITH DEFAULT KEY,

  "----------------------------------------------------------------------
  " 2. SAP Standard Country Table (T005T)
  "----------------------------------------------------------------------
  BEGIN OF ty_country,
    land1             TYPE land1,          " Country Key (2 Char ISO)
    landx             TYPE landx,          " Country Name Text
    key               TYPE string,
    value             TYPE string,
  END OF ty_country,
  ty_t_country TYPE STANDARD TABLE OF ty_country WITH DEFAULT KEY,
  ty_t_countries TYPE ty_t_country,

  "----------------------------------------------------------------------
  " 3. SAP Standard Region Table (T005U)
  "----------------------------------------------------------------------
  BEGIN OF ty_region,
    land1             TYPE land1,          " Country Key (2 Char ISO)
    bland             TYPE regio,          " Region / Province Key
    bezei             TYPE bezei20,        " Region Description Text
    key               TYPE string,
    value             TYPE string,
  END OF ty_region,
  ty_t_region TYPE STANDARD TABLE OF ty_region WITH DEFAULT KEY,
  ty_t_regions TYPE ty_t_region,

  "----------------------------------------------------------------------
  " 4. UI Dropdown Buffer Structure (Kompatibel dengan T005T & T005U)
  "----------------------------------------------------------------------
  BEGIN OF ty_dropdown,
    key               TYPE string,
    value             TYPE string,
    land1             TYPE land1,
    landx             TYPE landx,
    bland             TYPE regio,
    bezei             TYPE bezei20,
    role              TYPE bu_partnerrole,
    rltxt             TYPE tb003t-rltxt,
    bu_group          TYPE bu_group,
    txt40             TYPE tb002-txt40,
  END OF ty_dropdown,
  ty_t_dropdown TYPE STANDARD TABLE OF ty_dropdown WITH DEFAULT KEY,

  "----------------------------------------------------------------------
  " 5. UI Alert & Notification Structure
  "----------------------------------------------------------------------
  BEGIN OF ty_message,
    type              TYPE char1,          " 'S'=Success, 'E'=Error, 'W'=Warning, 'I'=Info
    message           TYPE string,
  END OF ty_message,
  ty_t_messages TYPE STANDARD TABLE OF ty_message WITH DEFAULT KEY,

  "----------------------------------------------------------------------
  " 6. Duplicate Check Buffer Structure (SE80 Page Attribute: GT_DUPLICATES)
  "----------------------------------------------------------------------
  BEGIN OF ty_duplicate,
    partner           TYPE bu_partner,     " Business Partner Number
    name1             TYPE bu_nameor1,     " Partner Name
    city              TYPE ad_city1,       " City
    street            TYPE ad_street,      " Street
    tax_num           TYPE bptaxnum,       " Tax Number / NPWP
    score             TYPE i,              " Similarity Match Score (%)
  END OF ty_duplicate,
  ty_t_duplicates TYPE STANDARD TABLE OF ty_duplicate WITH DEFAULT KEY,

  "----------------------------------------------------------------------
  " 7. BP Roles Buffer Structure (TB003 & TB003T)
  "----------------------------------------------------------------------
  BEGIN OF ty_bp_role,
    role              TYPE bu_partnerrole, " BP Role Key (e.g. FLVN01)
    rltxt             TYPE tb003t-rltxt,   " BP Role Text (e.g. MM Supplier)
  END OF ty_bp_role,
  ty_t_bp_roles TYPE STANDARD TABLE OF ty_bp_role WITH DEFAULT KEY,

  "----------------------------------------------------------------------
  " 8. BP Grouping Buffer Structure (TB001 & TB002)
  "----------------------------------------------------------------------
  BEGIN OF ty_bp_grouping,
    bu_group          TYPE bu_group,       " BP Grouping Key (e.g. 0001)
    txt40             TYPE tb002-txt40,    " BP Grouping Text
  END OF ty_bp_grouping,
  ty_t_bp_grouping TYPE STANDARD TABLE OF ty_bp_grouping WITH DEFAULT KEY,

  "----------------------------------------------------------------------
  " 9. SAP Standard Language Table (T002 & T002T)
  "----------------------------------------------------------------------
  BEGIN OF ty_language,
    spras             TYPE spras,          " SAP Internal 1-Char Language Key
    laiso             TYPE laiso,          " ISO 2-Char Language Key
    sptxt             TYPE sptxt,          " Language Name Description
    key               TYPE string,         " ISO Key for UI Selection
    value             TYPE string,         " UI Display Text (ISO - Name)
  END OF ty_language,
  ty_t_language TYPE STANDARD TABLE OF ty_language WITH DEFAULT KEY,
  ty_t_languages TYPE ty_t_language.
