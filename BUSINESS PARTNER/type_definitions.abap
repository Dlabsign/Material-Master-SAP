TYPES:
  "----------------------------------------------------------------------
  " 1. Request Workarea Structure
  "----------------------------------------------------------------------
  BEGIN OF ty_bp_request,
    req_id           TYPE char10,
    bp_category      TYPE bu_type,         " 1 = Person, 2 = Organization
    bp_role          TYPE bu_partnerrole,  " FLVN00 (Vendor), FLCU00 (Customer)
    name1            TYPE bu_nameor1,
    name2            TYPE bu_nameor2,
    search_term      TYPE bu_sort1,
    street           TYPE ad_street,
    house_num        TYPE ad_hsnm1,
    city             TYPE ad_city1,
    postal_code      TYPE ad_pstcd1,
    country          TYPE land1,
    region           TYPE regio,
    tax_type         TYPE bptaxtype,       " e.g., 'ID1' for Indonesian NPWP
    tax_num          TYPE bptaxnum,        " NPWP Raw or Formatted
    bukrs            TYPE bukrs,           " Company Code
    akont            TYPE akont,           " Recon Account
    zterm            TYPE dzterm,          " Payment Terms
    waers            TYPE waers,           " Currency
    status           TYPE char20,          " DRAFT, SUBMITTED, APPROVED, REJECTED
    rejection_reason TYPE string,
    bp_number        TYPE bu_partner,      " Generated SAP BP Number
    created_by       TYPE uname,
    created_at       TYPE timestamp,
  END OF ty_bp_request,
  ty_t_bp_request TYPE STANDARD TABLE OF ty_bp_request WITH DEFAULT KEY,

  "----------------------------------------------------------------------
  " 2. Duplicate Detection Result Structure
  "----------------------------------------------------------------------
  BEGIN OF ty_duplicate,
    bp_number    TYPE bu_partner,
    name         TYPE bu_nameor1,
    tax_num      TYPE bptaxnum,
    city         TYPE ad_city1,
    country      TYPE land1,
    source_table TYPE char10,             " DFKKBPTAXNUM, BUT000, LFA1, KNA1
    match_reason TYPE string,             " Exact NPWP, Name Similarity, etc.
  END OF ty_duplicate,
  ty_t_duplicates TYPE STANDARD TABLE OF ty_duplicate WITH DEFAULT KEY,

  "----------------------------------------------------------------------
  " 3. UI Alert and Message Structure
  "----------------------------------------------------------------------
  BEGIN OF ty_message,
    type         TYPE char1,              " 'S' = Success, 'E' = Error, 'W' = Warning, 'I' = Info
    message      TYPE string,
  END OF ty_message,
  ty_t_messages TYPE STANDARD TABLE OF ty_message WITH DEFAULT KEY,

  "----------------------------------------------------------------------
  " 4. Dropdown Select Option Buffer Structure
  "----------------------------------------------------------------------
  BEGIN OF ty_dropdown,
    key          TYPE string,
    value        TYPE string,
  END OF ty_dropdown,
  ty_t_dropdown TYPE STANDARD TABLE OF ty_dropdown WITH DEFAULT KEY.
