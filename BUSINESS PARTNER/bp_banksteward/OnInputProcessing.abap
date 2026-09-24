*======================================================================*
* BSP ONINPUTPROCESSING: Business Partner Governance - Bank Steward
* Application: ZBP_BANKSTEWARD | Page: bp_banksteward.htm
* Schema: Database Staging Table ZMDG_BP_REQ (SE11)
* Workflow Stage: Stage 2 - BP Bank Steward (Bank Details & FI Roles)
*======================================================================*

DATA: lv_action    TYPE string,
      lv_json      TYPE string,
      lv_req_no    TYPE string,
      lv_reason    TYPE string,
      lv_note      TYPE string,
      lv_auth_user TYPE string.

lv_action = request->get_form_field( 'action' ).
IF lv_action IS INITIAL.
  lv_action = request->get_form_field( 'OnInputProcessing' ).
ENDIF.
TRANSLATE lv_action TO UPPER CASE.

lv_auth_user = sy-uname.
TRANSLATE lv_auth_user TO UPPER CASE.
CONDENSE lv_auth_user NO-GAPS.

IF lv_auth_user <> 'ABAPER04' AND lv_auth_user <> 'KMI-BOD' AND lv_auth_user <> 'KMI-U163'.
  _m_response->set_status( code = 403 reason = 'Forbidden' ).
  _m_response->set_content_type( 'application/json' ).
  _m_response->set_cdata(
    '{"status":"ERROR","message":"Akses Terbatas: Anda tidak memiliki akses."}'
  ).
  _m_navigation->response_complete( ).
  RETURN.
ENDIF.

CASE lv_action.

  " ====================================================================
  " 1. GET PENDING BANK STEWARD QUEUE / REQUEST LIST
  " ====================================================================
  WHEN 'GET_PENDING_LIST' OR 'GET_REQUEST_LIST'.
    DATA: lt_bp_all TYPE TABLE OF zmdg_bp_req,
          ls_bp_rec TYPE zmdg_bp_req.

    TYPES: BEGIN OF ty_bp_item,
            req_no            TYPE string,
            req_type          TYPE string,
            bp_category       TYPE string,
            bp_role           TYPE string,
            bp_role_text      TYPE string,
            name1             TYPE string,
            name2             TYPE string,
            search_term       TYPE string,
            street            TYPE string,
            house_num         TYPE string,
            city              TYPE string,
            postal_code       TYPE string,
            country           TYPE string,
            region            TYPE string,
            telephone         TYPE string,
            fax               TYPE string,
            email             TYPE string,
            langu             TYPE string,
            tax_type          TYPE string,
            tax_num           TYPE string,
            banks             TYPE string,
            bankl             TYPE string,
            bankn             TYPE string,
            koinh             TYPE string,
            bank_name         TYPE string,
            bukrs             TYPE string,
            akont             TYPE string,
            zterm             TYPE string,
            waers             TYPE string,
            status            TYPE string,
            rejection_reason  TYPE string,
            stw_data_status   TYPE string,
            stw_data_by       TYPE string,
            stw_data_at       TYPE string,
            stw_data_note     TYPE string,
            stw_bank_status   TYPE string,
            stw_bank_by       TYPE string,
            stw_bank_at       TYPE string,
            stw_bank_note     TYPE string,
            appr_final_status TYPE string,
            appr_final_by     TYPE string,
            appr_final_at     TYPE string,
            bp_number         TYPE string,
            requestor         TYPE string,
            req_date          TYPE string,
            req_time          TYPE string,
          END OF ty_bp_item.

    DATA: lt_out    TYPE TABLE OF ty_bp_item,
          ls_out    TYPE ty_bp_item,
          lv_d      TYPE d,
          lv_t      TYPE t,
          lt_tb003t TYPE TABLE OF tb003t,
          ls_tb003t TYPE tb003t.

    SELECT role, rltxt FROM tb003t
      INTO CORRESPONDING FIELDS OF TABLE @lt_tb003t
      WHERE spras = @sy-langu.

    IF lt_tb003t IS INITIAL.
      SELECT role, rltxt FROM tb003t
        INTO CORRESPONDING FIELDS OF TABLE @lt_tb003t
        WHERE spras = 'E'.
    ENDIF.

    SELECT * FROM zmdg_bp_req
      INTO TABLE @lt_bp_all
      WHERE status IN ( 'SD_APPROVED', 'MM_APPROVED', 'CHECKED', 'SUBMITTED', 'APPROVED', 'REJECTED', 'FAILED' )
         OR stw_bank_status = 'R'
      ORDER BY req_id DESCENDING.

    LOOP AT lt_bp_all INTO ls_bp_rec.
      CLEAR: ls_out, ls_tb003t.
      ls_out-req_no           = CONV #( ls_bp_rec-req_id ).
      ls_out-req_type         = 'BP'.
      ls_out-bp_category      = CONV #( ls_bp_rec-bp_category ).
      ls_out-bp_role          = CONV #( ls_bp_rec-bp_role ).

      READ TABLE lt_tb003t INTO ls_tb003t WITH KEY role = ls_bp_rec-bp_role.
      IF sy-subrc = 0.
        ls_out-bp_role_text   = CONV #( ls_tb003t-rltxt ).
      ENDIF.
      ls_out-name1            = CONV #( ls_bp_rec-name1 ).
      ls_out-name2            = CONV #( ls_bp_rec-name2 ).
      ls_out-search_term      = CONV #( ls_bp_rec-search_term ).
      ls_out-street           = CONV #( ls_bp_rec-street ).
      ls_out-house_num        = CONV #( ls_bp_rec-house_num ).
      ls_out-city             = CONV #( ls_bp_rec-city ).
      ls_out-postal_code      = CONV #( ls_bp_rec-postal_code ).
      ls_out-country          = CONV #( ls_bp_rec-country ).
      ls_out-region           = CONV #( ls_bp_rec-region ).
      ls_out-telephone        = CONV #( ls_bp_rec-telephone ).
      ls_out-fax              = CONV #( ls_bp_rec-fax ).
      ls_out-email            = CONV #( ls_bp_rec-email ).
      ls_out-langu            = CONV #( ls_bp_rec-langu ).
      ls_out-tax_type         = CONV #( ls_bp_rec-tax_type ).
      ls_out-tax_num          = CONV #( ls_bp_rec-tax_num ).
      ls_out-banks            = CONV #( ls_bp_rec-banks ).
      ls_out-bankl            = CONV #( ls_bp_rec-bankl ).
      ls_out-bankn            = CONV #( ls_bp_rec-bankn ).
      ls_out-koinh            = CONV #( ls_bp_rec-koinh ).
      ls_out-bank_name        = CONV #( ls_bp_rec-bank_name ).
      ls_out-bukrs            = CONV #( ls_bp_rec-bukrs ).
      ls_out-akont            = CONV #( ls_bp_rec-akont ).
      ls_out-zterm            = CONV #( ls_bp_rec-zterm ).
      ls_out-waers            = CONV #( ls_bp_rec-waers ).
      ls_out-status           = CONV #( ls_bp_rec-status ).
      ls_out-rejection_reason = CONV #( ls_bp_rec-rejection_reason ).
      ls_out-stw_data_status  = CONV #( ls_bp_rec-stw_data_status ).
      ls_out-stw_data_by      = CONV #( ls_bp_rec-stw_data_by ).
      ls_out-stw_data_at      = CONV #( ls_bp_rec-stw_data_at ).
      ls_out-stw_data_note    = CONV #( ls_bp_rec-stw_data_note ).
      ls_out-stw_bank_status  = CONV #( ls_bp_rec-stw_bank_status ).
      ls_out-stw_bank_by      = CONV #( ls_bp_rec-stw_bank_by ).
      ls_out-stw_bank_at      = CONV #( ls_bp_rec-stw_bank_at ).
      ls_out-stw_bank_note    = CONV #( ls_bp_rec-stw_bank_note ).
      ls_out-appr_final_status = CONV #( ls_bp_rec-appr_final_status ).
      ls_out-appr_final_by    = CONV #( ls_bp_rec-appr_final_by ).
      ls_out-appr_final_at    = CONV #( ls_bp_rec-appr_final_at ).
      ls_out-bp_number        = CONV #( ls_bp_rec-bp_number ).
      ls_out-requestor        = CONV #( ls_bp_rec-created_by ).

      CLEAR: lv_d, lv_t.
      IF ls_bp_rec-created_at IS NOT INITIAL.
        CONVERT TIME STAMP ls_bp_rec-created_at TIME ZONE 'UTC'
          INTO DATE lv_d TIME lv_t.
        ls_out-req_date = CONV #( lv_d ).
        ls_out-req_time = CONV #( lv_t ).
      ENDIF.

      APPEND ls_out TO lt_out.
    ENDLOOP.

    " Format requestor with First Name + Last Name
    TYPES: BEGIN OF ty_usr_map,
             uname    TYPE sy-uname,
             fullname TYPE string,
           END OF ty_usr_map.
    DATA: lt_usr_map  TYPE HASHED TABLE OF ty_usr_map WITH UNIQUE KEY uname,
          ls_usr_map  TYPE ty_usr_map,
          ls_usr_addr TYPE bapiaddr3,
          lt_usr_ret  TYPE TABLE OF bapiret2,
          lv_u_pers   TYPE usr21-persnumber,
          lv_u_fn     TYPE adrp-name_first,
          lv_u_ln     TYPE adrp-name_last,
          lv_u_tmp    TYPE bapibname-bapibname.

    LOOP AT lt_out ASSIGNING FIELD-SYMBOL(<fs_o>).
      IF <fs_o>-requestor IS NOT INITIAL.
        READ TABLE lt_usr_map INTO ls_usr_map WITH KEY uname = <fs_o>-requestor.
        IF sy-subrc <> 0.
          CLEAR: ls_usr_map, ls_usr_addr, lt_usr_ret.
          ls_usr_map-uname = <fs_o>-requestor.
          lv_u_tmp = CONV #( <fs_o>-requestor ).
          CALL FUNCTION 'BAPI_USER_GET_DETAIL'
            EXPORTING
              username = lv_u_tmp
            IMPORTING
              address  = ls_usr_addr
            TABLES
              return   = lt_usr_ret.
          IF ls_usr_addr-firstname IS NOT INITIAL OR ls_usr_addr-lastname IS NOT INITIAL.
            CONCATENATE ls_usr_addr-firstname ls_usr_addr-lastname INTO ls_usr_map-fullname SEPARATED BY space.
          ELSEIF ls_usr_addr-fullname IS NOT INITIAL.
            ls_usr_map-fullname = ls_usr_addr-fullname.
          ELSE.
            SELECT SINGLE persnumber FROM usr21 INTO lv_u_pers WHERE bname = <fs_o>-requestor.
            IF sy-subrc = 0.
              SELECT SINGLE name_first name_last FROM adrp INTO (lv_u_fn, lv_u_ln) WHERE persnumber = lv_u_pers.
              IF lv_u_fn IS NOT INITIAL OR lv_u_ln IS NOT INITIAL.
                CONCATENATE lv_u_fn lv_u_ln INTO ls_usr_map-fullname SEPARATED BY space.
              ENDIF.
            ENDIF.
          ENDIF.
          IF ls_usr_map-fullname IS INITIAL.
            ls_usr_map-fullname = <fs_o>-requestor.
          ENDIF.
          INSERT ls_usr_map INTO TABLE lt_usr_map.
        ENDIF.
        <fs_o>-requestor = ls_usr_map-fullname.
      ENDIF.
    ENDLOOP.

    lv_json = /ui2/cl_json=>serialize(
      data        = lt_out
      compress    = abap_true
      pretty_name = /ui2/cl_json=>pretty_mode-low_case ).

    _m_response->set_content_type( 'application/json' ).
    _m_response->set_cdata( lv_json ).
    _m_navigation->response_complete( ).
    RETURN.

  " ====================================================================
  " 2. GET BP COUNTERS FOR BANK STEWARD
  " ====================================================================
  WHEN 'GET_COUNTERS'.
    DATA: lv_c_all TYPE i,
          lv_c_p   TYPE i,
          lv_c_chk TYPE i,
          lv_c_rej TYPE i.

    SELECT COUNT( * ) FROM zmdg_bp_req
      WHERE status <> 'DRAFT' INTO @lv_c_all.

    SELECT COUNT( * ) FROM zmdg_bp_req
      WHERE status IN ( 'SD_APPROVED', 'MM_APPROVED', 'CHECKED' )
        AND ( stw_bank_status = '' OR stw_bank_status = ' ' )
      INTO @lv_c_p.

    SELECT COUNT( * ) FROM zmdg_bp_req
      WHERE stw_bank_status = 'X' OR status = 'APPROVED'
      INTO @lv_c_chk.

    SELECT COUNT( * ) FROM zmdg_bp_req
      WHERE status IN ( 'REJECTED', 'FAILED' ) OR stw_bank_status = 'R'
      INTO @lv_c_rej.

    lv_json = |\{"total":{ lv_c_all },"pending":{ lv_c_p },"checked":{ lv_c_chk },"rejected":{ lv_c_rej }\}|.
    _m_response->set_content_type( 'application/json' ).
    _m_response->set_cdata( lv_json ).
    _m_navigation->response_complete( ).
    RETURN.

  " ====================================================================
  " 3. GET SINGLE BP DETAIL
  " ====================================================================
  WHEN 'GET_BP_DETAIL'.
    lv_req_no = request->get_form_field( 'REQ_NO' ).
    IF lv_req_no IS INITIAL.
      lv_req_no = request->get_form_field( 'REQ_ID' ).
    ENDIF.
    CONDENSE lv_req_no NO-GAPS.
    TRANSLATE lv_req_no TO UPPER CASE.

    DATA: lv_bp_k TYPE char10,
          ls_bp_d TYPE zmdg_bp_req.
    lv_bp_k = lv_req_no.

    SELECT SINGLE * FROM zmdg_bp_req INTO @ls_bp_d
      WHERE req_id = @lv_bp_k.

    IF sy-subrc = 0.
      DATA: lv_ser TYPE string.
      lv_ser = /ui2/cl_json=>serialize(
        data        = ls_bp_d
        compress    = abap_true
        pretty_name = /ui2/cl_json=>pretty_mode-low_case ).
      lv_json = |\{"status":"SUCCESS","data":{ lv_ser }\}|.
    ELSE.
      lv_json = |\{"status":"ERROR","message":"Permohonan { lv_bp_k } tidak ditemukan di tabel ZMDG_BP_REQ."\}|.
    ENDIF.

    _m_response->set_content_type( 'application/json' ).
    _m_response->set_cdata( lv_json ).
    _m_navigation->response_complete( ).
    RETURN.

  " ====================================================================
  " 4. BANK STEWARD APPROVAL (AKTIVASI ROLE FI & DATA BANK)
  " Vendor -> FLVN00 (FI Supplier) | Customer -> FLCU00 (FI Customer)
  " ====================================================================
  WHEN 'MARK_AS_CHECKED' OR 'APPROVE_BANK' OR 'CHECK_AND_FORWARD'.
    lv_req_no = request->get_form_field( 'REQ_NO' ).
    IF lv_req_no IS INITIAL.
      lv_req_no = request->get_form_field( 'REQ_ID' ).
    ENDIF.
    CONDENSE lv_req_no NO-GAPS.
    TRANSLATE lv_req_no TO UPPER CASE.

    lv_note = request->get_form_field( 'NOTE' ).
    IF lv_note IS INITIAL.
      lv_note = request->get_form_field( 'NOTES' ).
    ENDIF.

    IF lv_req_no IS INITIAL.
      lv_json = '{"status":"ERROR","message":"Request ID wajib diisi."}'.
      _m_response->set_content_type( 'application/json' ).
      _m_response->set_cdata( lv_json ).
      _m_navigation->response_complete( ).
      RETURN.
    ENDIF.

    DATA: lv_bp_act_k TYPE char10,
          ls_bp_check TYPE zmdg_bp_req.
    lv_bp_act_k = lv_req_no.

    SELECT SINGLE * FROM zmdg_bp_req INTO @ls_bp_check
      WHERE req_id = @lv_bp_act_k.

    IF sy-subrc <> 0.
      lv_json = |\{"status":"ERROR","message":"Permohonan { lv_bp_act_k } tidak ditemukan."\}|.
      _m_response->set_content_type( 'application/json' ).
      _m_response->set_cdata( lv_json ).
      _m_navigation->response_complete( ).
      RETURN.
    ENDIF.

    IF ls_bp_check-status = 'REJECTED' OR ls_bp_check-status = 'FAILED'
       OR ls_bp_check-stw_bank_status = 'R'.
      lv_json = |\{"status":"ERROR","message":"Permohonan { lv_bp_act_k } telah ditolak."\}|.
      _m_response->set_content_type( 'application/json' ).
      _m_response->set_cdata( lv_json ).
      _m_navigation->response_complete( ).
      RETURN.
    ENDIF.

    " Pastikan Nomor BP SAP sudah ada dari tahap Approval Manager
    DATA: lv_bp_target TYPE bu_partner.
    lv_bp_target = ls_bp_check-bp_number.

    IF lv_bp_target IS INITIAL.
      lv_json = |\{"status":"ERROR","message":|
             && |"Nomor BP SAP belum terdaftar untuk permohonan { lv_bp_act_k }."\}|.
      _m_response->set_content_type( 'application/json' ).
      _m_response->set_cdata( lv_json ).
      _m_navigation->response_complete( ).
      RETURN.
    ENDIF.

    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING input  = lv_bp_target
      IMPORTING output = lv_bp_target.

    " ------------------------------------------------------------------
    " AKTIVASI ROLE FI PADA SAP (FLVN00 UNTUK VENDOR, FLCU00 UNTUK CUSTOMER)
    " ------------------------------------------------------------------
    DATA: lv_fi_role  TYPE bu_partnerrole,
          lt_role_ret TYPE TABLE OF bapiret2.

    IF ls_bp_check-bp_role CS 'VN' OR ls_bp_check-bu_group CP 'V*'
       OR ls_bp_check-status = 'MM_APPROVED'.
      lv_fi_role = 'FLVN00'.
    ELSE.
      lv_fi_role = 'FLCU00'.
    ENDIF.

    CALL FUNCTION 'BAPI_BUPA_ROLE_ADD_2'
      EXPORTING
        businesspartner     = lv_bp_target
        businesspartnerrole = lv_fi_role
      TABLES return = lt_role_ret.

    " Pastikan Role FLVN01 (MM Supplier) & 000000 (General) juga terdaftar
    IF lv_fi_role = 'FLVN00'.
      CALL FUNCTION 'BAPI_BUPA_ROLE_ADD_2'
        EXPORTING
          businesspartner     = lv_bp_target
          businesspartnerrole = 'FLVN01'
        TABLES return = lt_role_ret.
    ELSE.
      CALL FUNCTION 'BAPI_BUPA_ROLE_ADD_2'
        EXPORTING
          businesspartner     = lv_bp_target
          businesspartnerrole = 'FLCU01'
        TABLES return = lt_role_ret.
    ENDIF.

    CALL FUNCTION 'BAPI_BUPA_ROLE_ADD_2'
      EXPORTING
        businesspartner     = lv_bp_target
        businesspartnerrole = '000000'
      TABLES return = lt_role_ret.

    " ------------------------------------------------------------------
    " SIMPAN DATA KE TABEL CVI SAP (LFA1, LFB1 COMPANY CODE, LFM1)
    " ------------------------------------------------------------------
    IF lv_fi_role = 'FLVN00'.
      DATA: lv_cvi_lifnr TYPE lifnr,
            ls_lfa1_ins  TYPE lfa1,
            ls_lfb1_ins  TYPE lfb1,
            ls_lfm1_ins  TYPE lfm1,
            ls_cvi_link  TYPE cvi_vend_link,
            lv_bp_guid   TYPE bu_partner_guid,
            lv_bukrs_val TYPE bukrs,
            lv_ekorg_val TYPE ekorg,
            lv_waers_val TYPE waers.

      lv_cvi_lifnr = lv_bp_target.
      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
        EXPORTING input  = lv_cvi_lifnr
        IMPORTING output = lv_cvi_lifnr.

      lv_bukrs_val = COND #( WHEN ls_bp_check-bukrs IS NOT INITIAL THEN ls_bp_check-bukrs ELSE '1000' ).
      lv_ekorg_val = COND #( WHEN ls_bp_check-ekorg IS NOT INITIAL THEN ls_bp_check-ekorg ELSE '1000' ).
      lv_waers_val = COND #( WHEN ls_bp_check-waers IS NOT INITIAL THEN ls_bp_check-waers ELSE 'IDR' ).

      " 1. Mapping CVI (CVI_VEND_LINK)
      SELECT SINGLE partner_guid FROM but000 INTO @lv_bp_guid WHERE partner = @lv_bp_target.
      IF sy-subrc = 0 AND lv_bp_guid IS NOT INITIAL.
        SELECT SINGLE vendor FROM cvi_vend_link INTO @lv_cvi_lifnr WHERE partner_guid = @lv_bp_guid.
        IF sy-subrc <> 0 OR lv_cvi_lifnr IS INITIAL.
          lv_cvi_lifnr = lv_bp_target.
          CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
            EXPORTING input  = lv_cvi_lifnr
            IMPORTING output = lv_cvi_lifnr.

          ls_cvi_link-client       = sy-mandt.
          ls_cvi_link-partner_guid = lv_bp_guid.
          ls_cvi_link-vendor       = lv_cvi_lifnr.
          MODIFY cvi_vend_link FROM @ls_cvi_link.
        ENDIF.
      ENDIF.

      " 2. Header Vendor (LFA1)
      SELECT SINGLE * FROM lfa1 INTO @ls_lfa1_ins WHERE lifnr = @lv_cvi_lifnr.
      ls_lfa1_ins-mandt = sy-mandt.
      ls_lfa1_ins-lifnr = lv_cvi_lifnr.
      ls_lfa1_ins-name1 = ls_bp_check-name1.
      ls_lfa1_ins-name2 = ls_bp_check-name2.
      ls_lfa1_ins-sortl = ls_bp_check-search_term.
      ls_lfa1_ins-stras = ls_bp_check-street.
      ls_lfa1_ins-ort01 = ls_bp_check-city.
      ls_lfa1_ins-pstlz = ls_bp_check-postal_code.
      ls_lfa1_ins-land1 = COND #( WHEN ls_bp_check-country IS NOT INITIAL THEN ls_bp_check-country ELSE 'ID' ).
      ls_lfa1_ins-regio = ls_bp_check-region.
      ls_lfa1_ins-telf1 = ls_bp_check-telephone.
      ls_lfa1_ins-telfx = ls_bp_check-fax.
      IF ls_lfa1_ins-ktokk IS INITIAL.
        ls_lfa1_ins-ktokk = COND #( WHEN ls_bp_check-bu_group IS NOT INITIAL THEN ls_bp_check-bu_group ELSE '0001' ).
      ENDIF.
      IF ls_lfa1_ins-erdat IS INITIAL.
        ls_lfa1_ins-erdat = sy-datum.
        ls_lfa1_ins-ernam = sy-uname.
      ENDIF.
      MODIFY lfa1 FROM @ls_lfa1_ins.

      " 3. Company Code Data (LFB1) - PENTING UNTUK ROLE FLVN00 FI SUPPLIER
      SELECT SINGLE * FROM lfb1 INTO @ls_lfb1_ins WHERE lifnr = @lv_cvi_lifnr AND bukrs = @lv_bukrs_val.
      ls_lfb1_ins-mandt = sy-mandt.
      ls_lfb1_ins-lifnr = lv_cvi_lifnr.
      ls_lfb1_ins-bukrs = lv_bukrs_val.
      ls_lfb1_ins-akont = ls_bp_check-akont.
      ls_lfb1_ins-zterm = ls_bp_check-zterm.
      IF ls_lfb1_ins-erdat IS INITIAL.
        ls_lfb1_ins-erdat = sy-datum.
        ls_lfb1_ins-ernam = sy-uname.
      ENDIF.
      MODIFY lfb1 FROM @ls_lfb1_ins.

      " 4. Purchasing Data (LFM1) - UNTUK ROLE FLVN01 MM SUPPLIER
      SELECT SINGLE * FROM lfm1 INTO @ls_lfm1_ins WHERE lifnr = @lv_cvi_lifnr AND ekorg = @lv_ekorg_val.
      ls_lfm1_ins-mandt = sy-mandt.
      ls_lfm1_ins-lifnr = lv_cvi_lifnr.
      ls_lfm1_ins-ekorg = lv_ekorg_val.
      ls_lfm1_ins-waers = lv_waers_val.
      ls_lfm1_ins-webre = COND #( WHEN ls_bp_check-webre IS NOT INITIAL THEN ls_bp_check-webre ELSE 'X' ).
      ls_lfm1_ins-lebre = COND #( WHEN ls_bp_check-lebre IS NOT INITIAL THEN ls_bp_check-lebre ELSE 'X' ).
      IF ls_lfm1_ins-erdat IS INITIAL.
        ls_lfm1_ins-erdat = sy-datum.
        ls_lfm1_ins-ernam = sy-uname.
      ENDIF.
      MODIFY lfm1 FROM @ls_lfm1_ins.
    ENDIF.

    " ------------------------------------------------------------------
    " SIMPAN DATA REKENING BANK JIKA TERSEDIA
    " ------------------------------------------------------------------
    IF ls_bp_check-bankn IS NOT INITIAL AND ls_bp_check-bankl IS NOT INITIAL.
      DATA: ls_bank_p   TYPE bapibus1006_bankdetail,
            lt_bank_ret TYPE TABLE OF bapiret2.
      ls_bank_p-bank_ctry     = COND #( WHEN ls_bp_check-banks IS NOT INITIAL THEN ls_bp_check-banks ELSE 'ID' ).
      ls_bank_p-bank_key      = ls_bp_check-bankl.
      ls_bank_p-bank_acct     = ls_bp_check-bankn.
      ls_bank_p-accountholder = COND #( WHEN ls_bp_check-koinh IS NOT INITIAL THEN ls_bp_check-koinh ELSE ls_bp_check-name1 ).

      CALL FUNCTION 'BAPI_BUPA_BANKDETAIL_ADD'
        EXPORTING
          businesspartner = lv_bp_target
          bankdetailid    = '0001'
          bankdetaildata  = ls_bank_p
        TABLES return = lt_bank_ret.
    ENDIF.

    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING wait = 'X'.

    DATA: lv_ts_act TYPE timestamp.
    GET TIME STAMP FIELD lv_ts_act.

    UPDATE zmdg_bp_req
      SET status            = 'APPROVED',
          rejection_reason  = '',
          stw_bank_status   = 'X',
          stw_bank_by       = @sy-uname,
          stw_bank_at       = @lv_ts_act,
          stw_bank_note     = @lv_note,
          appr_final_status = 'X',
          appr_final_by     = @sy-uname,
          appr_final_at     = @lv_ts_act,
          changed_by        = @sy-uname,
          changed_at        = @lv_ts_act
      WHERE req_id          = @lv_bp_act_k.
    COMMIT WORK.

    lv_json = |\{"status":"SUCCESS","message":|
           && |"Data Bank & Role FI ({ lv_fi_role }) untuk BP SAP { lv_bp_target } berhasil diaktifkan!"\}|.
    _m_response->set_content_type( 'application/json' ).
    _m_response->set_cdata( lv_json ).
    _m_navigation->response_complete( ).
    RETURN.

  " ====================================================================
  " 5. RETURN TO REQUESTOR / REJECT BY BANK STEWARD
  " ====================================================================
  WHEN 'RETURN_TO_REQUESTOR' OR 'REJECT'.
    lv_req_no = request->get_form_field( 'REQ_NO' ).
    IF lv_req_no IS INITIAL.
      lv_req_no = request->get_form_field( 'REQ_ID' ).
    ENDIF.
    CONDENSE lv_req_no NO-GAPS.
    TRANSLATE lv_req_no TO UPPER CASE.

    lv_reason = request->get_form_field( 'REJ_REASON' ).
    IF lv_reason IS INITIAL.
      lv_reason = request->get_form_field( 'REASON' ).
    ENDIF.
    IF lv_reason IS INITIAL.
      lv_reason = request->get_form_field( 'REJECTION_REASON' ).
    ENDIF.

    IF lv_req_no IS INITIAL OR lv_reason IS INITIAL.
      lv_json = '{"status":"ERROR","message":"Request ID dan alasan penolakan wajib diisi."}'.
      _m_response->set_content_type( 'application/json' ).
      _m_response->set_cdata( lv_json ).
      _m_navigation->response_complete( ).
      RETURN.
    ENDIF.

    DATA: lv_bp_rej_k TYPE char10,
          lv_ts_rej   TYPE timestamp.
    lv_bp_rej_k = lv_req_no.
    GET TIME STAMP FIELD lv_ts_rej.

    UPDATE zmdg_bp_req
      SET status           = 'REJECTED',
          rejection_reason = @lv_reason,
          stw_bank_status  = 'R',
          stw_bank_by      = @sy-uname,
          stw_bank_at      = @lv_ts_rej,
          stw_bank_note    = @lv_reason,
          changed_by       = @sy-uname,
          changed_at       = @lv_ts_rej
      WHERE req_id         = @lv_bp_rej_k.
    COMMIT WORK.

    lv_json = |\{"status":"SUCCESS","message":"Permohonan { lv_bp_rej_k } telah ditolak oleh Bank Steward."\}|.
    _m_response->set_content_type( 'application/json' ).
    _m_response->set_cdata( lv_json ).
    _m_navigation->response_complete( ).
    RETURN.

  WHEN OTHERS.
    lv_json = |\{"status":"ERROR","message":"Aksi { lv_action } tidak dikenal."\}|.
    _m_response->set_content_type( 'application/json' ).
    _m_response->set_cdata( lv_json ).
    _m_navigation->response_complete( ).
    RETURN.

ENDCASE.
