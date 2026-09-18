*======================================================================*
* BSP ONINITIALIZATION: Business Partner Governance - Bank Steward
* Application: ZBP_BANKSTEWARD | Page: bp_banksteward.htm
* Schema: Database Staging Table ZMDG_BP_REQ (SE11)
* Workflow Stage: Stage 2 - BP Bank Steward (Bank Details & Payment Terms)
*======================================================================*

DATA: lv_auth_user   TYPE string,
      lv_action_init TYPE string,
      lv_req_id      TYPE string,
      lv_json        TYPE string.

lv_action_init = request->get_form_field( 'action' ).
IF lv_action_init IS INITIAL.
  lv_action_init = request->get_form_field( 'OnInputProcessing' ).
ENDIF.
TRANSLATE lv_action_init TO UPPER CASE.

lv_auth_user = sy-uname.
TRANSLATE lv_auth_user TO UPPER CASE.
CONDENSE lv_auth_user NO-GAPS.

IF lv_auth_user <> 'ABAPER04' AND lv_auth_user <> 'KMI-BOD' AND lv_auth_user <> 'KMI-U163'.
  IF lv_action_init IS NOT INITIAL.
    _m_response->set_status( code = 403 reason = 'Forbidden' ).
    _m_response->set_content_type( 'application/json' ).
    lv_json = '{"status":"ERROR","message":'
           && '"Akses Terbatas: Anda tidak memiliki akses untuk masuk ke halaman ini, silahkan hubungi core tim."}'.
    _m_response->set_cdata( lv_json ).
    _m_navigation->response_complete( ).
    RETURN.
  ENDIF.
  RETURN.
ENDIF.

IF lv_action_init IS NOT INITIAL.
  CASE lv_action_init.
    WHEN 'GET_COUNTERS'.
      DATA: lv_cnt_all TYPE i,
            lv_cnt_p   TYPE i,
            lv_cnt_chk TYPE i,
            lv_cnt_rej TYPE i.

      SELECT COUNT( * ) FROM zmdg_bp_req
        WHERE status <> 'DRAFT' INTO @lv_cnt_all.

      " Permohonan aktif yang belum diverifikasi oleh Bank Steward (Paralel)
      SELECT COUNT( * ) FROM zmdg_bp_req
        WHERE status <> 'DRAFT'
          AND status NOT IN ( 'REJECTED', 'FAILED', 'APPROVED' )
          AND ( stw_bank_status = '' OR stw_bank_status = ' ' )
        INTO @lv_cnt_p.

      SELECT COUNT( * ) FROM zmdg_bp_req
        WHERE stw_bank_status = 'X'
           OR status IN ( 'CHECKED', 'APPROVED' )
        INTO @lv_cnt_chk.

      SELECT COUNT( * ) FROM zmdg_bp_req
        WHERE status IN ( 'REJECTED', 'FAILED' )
           OR stw_bank_status = 'R'
        INTO @lv_cnt_rej.

      lv_json = |\{"total":{ lv_cnt_all },"pending":{ lv_cnt_p },"checked":{ lv_cnt_chk },"rejected":{ lv_cnt_rej }\}|.
      _m_response->set_content_type( 'application/json' ).
      _m_response->set_cdata( lv_json ).
      _m_navigation->response_complete( ).
      RETURN.

    WHEN 'GET_BP_DETAIL'.
      lv_req_id = request->get_form_field( 'REQ_NO' ).
      IF lv_req_id IS INITIAL.
        lv_req_id = request->get_form_field( 'REQ_ID' ).
      ENDIF.
      CONDENSE lv_req_id NO-GAPS.
      TRANSLATE lv_req_id TO UPPER CASE.

      DATA: lv_key_dtl TYPE char10,
            ls_bp_dtl  TYPE zmdg_bp_req.
      lv_key_dtl = lv_req_id.

      SELECT SINGLE * FROM zmdg_bp_req INTO @ls_bp_dtl
        WHERE req_id = @lv_key_dtl.

      IF sy-subrc = 0.
        DATA: lv_dtl_json TYPE string.
        lv_dtl_json = /ui2/cl_json=>serialize(
          data        = ls_bp_dtl
          compress    = abap_true
          pretty_name = /ui2/cl_json=>pretty_mode-low_case ).
        lv_json = |\{"status":"SUCCESS","data":{ lv_dtl_json }\}|.
      ELSE.
        lv_json = |\{"status":"ERROR","message":"Permohonan { lv_key_dtl } tidak ditemukan di tabel ZMDG_BP_REQ."\}|.
      ENDIF.

      _m_response->set_content_type( 'application/json' ).
      _m_response->set_cdata( lv_json ).
      _m_navigation->response_complete( ).
      RETURN.
  ENDCASE.
ENDIF.