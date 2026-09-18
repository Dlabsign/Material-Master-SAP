*======================================================================*
* BSP ONINPUTPROCESSING: Business Partner Governance - Data Steward
* Application: ZBP_DATASTEWARD | Page: bp_datasteward.htm
* Schema: Database Staging Table ZMDG_BP_REQ (SE11)
* Workflow Stage: Stage 1 - BP Data Steward (General, Address, NPWP)
*======================================================================*

DATA: lv_action     TYPE string,
      lv_json       TYPE string,
      lv_req_no     TYPE string,
      lv_reason     TYPE string,
      lv_note       TYPE string,
      lv_auth_user  TYPE string.

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
  _m_response->set_cdata( '{"status":"ERROR","message":"Akses Terbatas: Anda tidak memiliki akses untuk aksi ini."}' ).
  _m_navigation->response_complete( ).
  RETURN.
ENDIF.

CASE lv_action.

  " ====================================================================
  " 1. GET PENDING LIST / ALL BP STAGING RECORDS
  " ====================================================================
  WHEN 'GET_PENDING_LIST' OR 'GET_REQUEST_LIST'.
    DATA: lt_bp_all TYPE TABLE OF zmdg_bp_req,
          ls_bp_rec TYPE zmdg_bp_req.

    TYPES: BEGIN OF ty_bp_item,
            req_no          TYPE string,
            req_type        TYPE string,
            bp_category     TYPE string,
            bp_role         TYPE string,
            bp_role_text    TYPE string,
            name1           TYPE string,
            name2           TYPE string,
            search_term     TYPE string,
            street          TYPE string,
            house_num       TYPE string,
            city            TYPE string,
            postal_code     TYPE string,
            country         TYPE string,
            region          TYPE string,
            telephone       TYPE string,
            fax             TYPE string,
            email           TYPE string,
            langu           TYPE string,
            tax_type        TYPE string,
            tax_num         TYPE string,
            banks           TYPE string,
            bankl           TYPE string,
            bankn           TYPE string,
            koinh           TYPE string,
            bank_name       TYPE string,
            bukrs           TYPE string,
            akont           TYPE string,
            zterm           TYPE string,
            waers           TYPE string,
            status          TYPE string,
            rejection_reason TYPE string,
            stw_data_status TYPE string,
            stw_data_by     TYPE string,
            stw_data_at     TYPE string,
            stw_data_note   TYPE string,
            stw_bank_status TYPE string,
            stw_bank_by     TYPE string,
            stw_bank_at     TYPE string,
            stw_bank_note   TYPE string,
            appr_final_status TYPE string,
            appr_final_by   TYPE string,
            appr_final_at   TYPE string,
            bp_number       TYPE string,
            requestor       TYPE string,
            req_date        TYPE string,
            req_time        TYPE string,
          END OF ty_bp_item.

    DATA: lt_out TYPE TABLE OF ty_bp_item,
          ls_out TYPE ty_bp_item,
          lv_d   TYPE d,
          lv_t   TYPE t,
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
      WHERE status <> 'DRAFT'
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
      ls_out-stw_bank_at       = CONV #( ls_bp_rec-stw_bank_at ).
      ls_out-stw_bank_note     = CONV #( ls_bp_rec-stw_bank_note ).
      ls_out-appr_final_status = CONV #( ls_bp_rec-appr_final_status ).
      ls_out-appr_final_by     = CONV #( ls_bp_rec-appr_final_by ).
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

    lv_json = /ui2/cl_json=>serialize(
      data        = lt_out
      compress    = abap_true
      pretty_name = /ui2/cl_json=>pretty_mode-low_case ).

    _m_response->set_content_type( 'application/json' ).
    _m_response->set_cdata( lv_json ).
    _m_navigation->response_complete( ).
    RETURN.

  " ====================================================================
  " 2. GET BP COUNTERS
  " ====================================================================
  WHEN 'GET_COUNTERS'.
    DATA: lv_c_all TYPE i,
          lv_c_p   TYPE i,
          lv_c_chk TYPE i,
          lv_c_rej TYPE i.

    SELECT COUNT( * ) FROM zmdg_bp_req
      WHERE status <> 'DRAFT' INTO @lv_c_all.

    " Permohonan aktif yang belum diverifikasi oleh Data Steward (Paralel)
    SELECT COUNT( * ) FROM zmdg_bp_req
      WHERE status <> 'DRAFT'
        AND status NOT IN ( 'REJECTED', 'FAILED', 'APPROVED' )
        AND ( stw_data_status = '' OR stw_data_status = ' ' )
      INTO @lv_c_p.

    SELECT COUNT( * ) FROM zmdg_bp_req
      WHERE stw_data_status = 'X'
         OR status IN ( 'DATA_CHECKED', 'CHECKED', 'APPROVED' )
      INTO @lv_c_chk.

    SELECT COUNT( * ) FROM zmdg_bp_req
      WHERE status IN ( 'REJECTED', 'FAILED' )
         OR stw_data_status = 'R'
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
  " 4. DATA STEWARD APPROVAL / CHECKED -> STATUS = 'DATA_CHECKED'
  " ====================================================================
  WHEN 'MARK_AS_CHECKED' OR 'CHECK_AND_FORWARD' OR 'SUBMIT_TO_APPROVAL'
    OR 'APPROVE_DATA'.
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
    IF lv_note IS INITIAL.
      lv_note = request->get_form_field( 'REMARKS' ).
    ENDIF.

    IF lv_req_no IS INITIAL.
      lv_json = '{"status":"ERROR","message":"Request ID wajib diisi."}'.
      _m_response->set_content_type( 'application/json' ).
      _m_response->set_cdata( lv_json ).
      _m_navigation->response_complete( ).
      RETURN.
    ENDIF.

    DATA: lv_bp_act_key TYPE char10,
          ls_bp_check   TYPE zmdg_bp_req.
    lv_bp_act_key = lv_req_no.

    SELECT SINGLE * FROM zmdg_bp_req INTO @ls_bp_check
      WHERE req_id = @lv_bp_act_key.

    IF sy-subrc <> 0.
      lv_json = |\{"status":"ERROR","message":"Permohonan { lv_bp_act_key } tidak ditemukan di tabel ZMDG_BP_REQ."\}|.
      _m_response->set_content_type( 'application/json' ).
      _m_response->set_cdata( lv_json ).
      _m_navigation->response_complete( ).
      RETURN.
    ENDIF.

    " Cegah approval jika permohonan sudah berstatus ditolak
    IF ls_bp_check-status = 'REJECTED' OR ls_bp_check-status = 'FAILED'
       OR ls_bp_check-stw_data_status = 'R'.
      lv_json = |\{"status":"ERROR","message":|
             && |"Permohonan { lv_bp_act_key } sudah berstatus ditolak."\}|.
      _m_response->set_content_type( 'application/json' ).
      _m_response->set_cdata( lv_json ).
      _m_navigation->response_complete( ).
      RETURN.
    ENDIF.

    " Cegah duplicate approval oleh Data Steward
    IF ls_bp_check-stw_data_status = 'X'.
      lv_json = |\{"status":"ERROR","message":|
             && |"Permohonan { lv_bp_act_key } sudah disetujui oleh Data Steward sebelumnya."\}|.
      _m_response->set_content_type( 'application/json' ).
      _m_response->set_cdata( lv_json ).
      _m_navigation->response_complete( ).
      RETURN.
    ENDIF.

    DATA: lv_new_status TYPE char20.
    " Logika Alur Kerja Paralel / Bersamaan:
    IF ls_bp_check-stw_bank_status = 'X'.
      " Kedua steward (Data & Bank) telah menyetujui -> Diteruskan ke Final Approval
      lv_new_status = 'CHECKED'.
    ELSE.
      " Data Steward telah menyetujui, masih menunggu Bank Steward
      lv_new_status = 'DATA_CHECKED'.
    ENDIF.

    DATA: lv_ts_act TYPE timestamp.
    GET TIME STAMP FIELD lv_ts_act.

    UPDATE zmdg_bp_req
      SET status           = @lv_new_status,
          rejection_reason = '',
          stw_data_status  = 'X',
          stw_data_by      = @sy-uname,
          stw_data_at      = @lv_ts_act,
          stw_data_note    = @lv_note,
          changed_by       = @sy-uname,
          changed_at       = @lv_ts_act
      WHERE req_id         = @lv_bp_act_key.
    COMMIT WORK.

    IF lv_new_status = 'CHECKED'.
      lv_json = |\{"status":"SUCCESS","message":|
             && |"Business Partner { lv_bp_act_key } berhasil di-Checked Data Steward! Kedua steward telah memverifikasi, diteruskan ke Final Approval."\}|.
    ELSE.
      lv_json = |\{"status":"SUCCESS","message":|
             && |"Business Partner { lv_bp_act_key } berhasil di-Checked Data Steward (menunggu verifikasi Bank Steward)."\}|.
    ENDIF.
    _m_response->set_content_type( 'application/json' ).
    _m_response->set_cdata( lv_json ).
    _m_navigation->response_complete( ).
    RETURN.

  " ====================================================================
  " 5. RETURN TO REQUESTOR / REJECT
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

    IF lv_req_no IS INITIAL.
      lv_json = '{"status":"ERROR","message":"Request ID wajib diisi."}'.
      _m_response->set_content_type( 'application/json' ).
      _m_response->set_cdata( lv_json ).
      _m_navigation->response_complete( ).
      RETURN.
    ENDIF.

    IF lv_reason IS INITIAL.
      lv_json = '{"status":"ERROR","message":"Alasan penolakan wajib diisi."}'.
      _m_response->set_content_type( 'application/json' ).
      _m_response->set_cdata( lv_json ).
      _m_navigation->response_complete( ).
      RETURN.
    ENDIF.

    DATA: lv_bp_rej_k TYPE char10.
    lv_bp_rej_k = lv_req_no.

    DATA: lv_ts_rej TYPE timestamp.
    GET TIME STAMP FIELD lv_ts_rej.

    UPDATE zmdg_bp_req
      SET status           = 'REJECTED',
          rejection_reason = @lv_reason,
          stw_data_status  = 'R',
          stw_data_by      = @sy-uname,
          stw_data_at      = @lv_ts_rej,
          stw_data_note    = @lv_reason,
          changed_by       = @sy-uname,
          changed_at       = @lv_ts_rej
      WHERE req_id         = @lv_bp_rej_k.
    COMMIT WORK.

    lv_json = |\{"status":"SUCCESS","message":"Business Partner Request { lv_bp_rej_k } telah ditolak."\}|.
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