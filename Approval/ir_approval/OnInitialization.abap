*======================================================================*
* SAP BSP INITIALIZATION CONTROLLER: PURCHASING INFO RECORD APPROVAL
* Application: MDG Approval | Page: ir_approval.htm
* Schema: Database Staging Tables ZMDG_REQ_PIR, ZMDG_PIR_ITM, ZMDG_PIR_ADT
* Workflow: User Request -> Purchasing Data Steward -> Approval Info Record
*======================================================================*

DATA: lv_action    TYPE string,
      lv_json      TYPE string,
      lv_req_no    TYPE string,
      lv_req_nos   TYPE string,
      lv_reason    TYPE string,
      lv_auth_user TYPE string.

TYPES: BEGIN OF ty_ir_stage_list,
        req_no           TYPE string,
        action_type      TYPE string,
        status           TYPE string,
        status_desc      TYPE string,
        infnr            TYPE string,
        lifnr            TYPE string,
        matnr            TYPE string,
        txz01            TYPE string,
        matkl            TYPE string,
        idnlf            TYPE string,
        ekorg            TYPE string,
        werks            TYPE string,
        esokz            TYPE string,
        ekgrp            TYPE string,
        aplfz            TYPE string,
        norbm            TYPE string,
        minbm            TYPE string,
        uebto            TYPE string,
        untto            TYPE string,
        netpr            TYPE string,
        waers            TYPE string,
        peinh            TYPE string,
        bprme            TYPE string,
        mwskz            TYPE string,
        inco1            TYPE string,
        inco2            TYPE string,
        datab            TYPE string,
        datbi            TYPE string,
        req_date         TYPE string,
        req_time         TYPE string,
        requestor        TYPE string,
        total_item       TYPE i,
        comments         TYPE string,
        rejection_reason TYPE string,
        appr_by          TYPE string,
        appr_at          TYPE string,
        created_by       TYPE string,
        created_at       TYPE string,
        changed_by       TYPE string,
        changed_at       TYPE string,
      END OF ty_ir_stage_list.

DATA: lt_list TYPE TABLE OF ty_ir_stage_list,
      ls_list TYPE ty_ir_stage_list.

DATA: lt_hdr_db      TYPE TABLE OF zmdg_req_pir,
      ls_hdr_db      TYPE zmdg_req_pir,
      lt_itm_db      TYPE TABLE OF zmdg_pir_itm,
      ls_itm_db      TYPE zmdg_pir_itm,
      lt_cnd_db      TYPE TABLE OF zmdg_pir_cnd,
      ls_cnd_db      TYPE zmdg_pir_cnd,
      lt_adt_db      TYPE TABLE OF zmdg_pir_adt,
      ls_adt_db      TYPE zmdg_pir_adt,
      lt_req_split   TYPE TABLE OF string,
      lv_req_item    TYPE string,
      lv_err_msg     TYPE string,
      lv_last_err    TYPE string,
      lv_success_cnt TYPE i,
      lv_fail_cnt    TYPE i,
      lv_ts_now      TYPE timestamp.

TYPES: BEGIN OF ty_resp_item,
        req_no  TYPE string,
        infnr   TYPE string,
        matnr   TYPE string,
        txz01   TYPE string,
        status  TYPE string,
        message TYPE string,
      END OF ty_resp_item.

TYPES: BEGIN OF ty_resp,
        status  TYPE string,
        message TYPE string,
        req_no  TYPE string,
        infnr   TYPE string,
        items   TYPE TABLE OF ty_resp_item WITH DEFAULT KEY,
      END OF ty_resp.

DATA: ls_resp       TYPE ty_resp,
      lt_resp_items TYPE TABLE OF ty_resp_item.

lv_action = request->get_form_field( 'action' ).
IF lv_action IS INITIAL.
  lv_action = request->get_form_field( 'OnInputProcessing' ).
ENDIF.
TRANSLATE lv_action TO UPPER CASE.

lv_auth_user = sy-uname.
TRANSLATE lv_auth_user TO UPPER CASE.
CONDENSE lv_auth_user NO-GAPS.

IF lv_auth_user <> 'ABAPER04' AND lv_auth_user <> 'KMI-BOD' AND lv_auth_user <> 'KMI-U163' AND sy-uname IS INITIAL.
  IF lv_action IS NOT INITIAL.
    _m_response->set_status( code = 403 reason = 'Forbidden' ).
    _m_response->set_content_type( 'application/json' ).
    _m_response->set_cdata(
      '{"status":"ERROR","message":"Akses Terbatas: Anda tidak memiliki akses ke Info Record Approval."}'
    ).
    _m_navigation->response_complete( ).
    RETURN.
  ENDIF.
ENDIF.

IF lv_action IS NOT INITIAL.

  CASE lv_action.

    " ------------------------------------------------------------------
    " GET COUNTERS FOR APPROVAL METRICS & SIDEBAR BADGES
    " ------------------------------------------------------------------
    WHEN 'GET_COUNTERS'.
      DATA: lv_cnt_p     TYPE i,
            lv_cnt_a     TYPE i,
            lv_cnt_r     TYPE i,
            lv_cnt_mat_p TYPE i,
            lv_cnt_bp_p  TYPE i.

      SELECT COUNT( * ) FROM zmdg_req_pir
        WHERE status = '01'
        INTO @lv_cnt_p.

      SELECT COUNT( * ) FROM zmdg_req_pir
        WHERE status IN ( '02', '04' )
        INTO @lv_cnt_a.

      SELECT COUNT( * ) FROM zmdg_req_pir
        WHERE status = '03'
        INTO @lv_cnt_r.

      SELECT COUNT( * ) FROM zmdg_bp_req
        WHERE status IN ( 'SUBMITTED', 'CHECKED' )
        INTO @lv_cnt_bp_p.

      SELECT COUNT( * ) FROM zmdg_req_hdr
        WHERE status IN ( 'CHECKED', 'CODED' )
        INTO @lv_cnt_mat_p.

      lv_json = '{"pending":' && lv_cnt_p &&
                ',"ir_pending":' && lv_cnt_p &&
                ',"bp_pending":' && lv_cnt_bp_p &&
                ',"mat_pending":' && lv_cnt_mat_p &&
                ',"approved":' && lv_cnt_a &&
                ',"rejected":' && lv_cnt_r && '}'.
      _m_response->set_content_type( 'application/json' ).
      _m_response->set_cdata( lv_json ).
      _m_navigation->response_complete( ).
      RETURN.

    " ------------------------------------------------------------------
    " 1. GET ALL STAGING REQUEST LIST FOR INFO RECORD APPROVAL
    " ------------------------------------------------------------------
    WHEN 'GET_STAGING_LIST'.
      CLEAR: lt_hdr_db, lt_list.

      SELECT * FROM zmdg_req_pir
        INTO TABLE @lt_hdr_db
        WHERE status IN ( '01', '02', '03', '04' )
        ORDER BY req_id DESCENDING.

      LOOP AT lt_hdr_db INTO ls_hdr_db.
        CLEAR ls_list.
        ls_list-req_no      = CONV #( ls_hdr_db-req_id ).
        ls_list-action_type = CONV #( ls_hdr_db-action_type ).
        ls_list-status      = CONV #( ls_hdr_db-status ).
        ls_list-infnr       = CONV #( ls_hdr_db-infnr ).
        ls_list-lifnr       = CONV #( ls_hdr_db-lifnr ).
        ls_list-matnr       = CONV #( ls_hdr_db-matnr ).
        ls_list-txz01       = CONV #( ls_hdr_db-txz01 ).
        ls_list-matkl       = CONV #( ls_hdr_db-matkl ).
        ls_list-idnlf       = CONV #( ls_hdr_db-idnlf ).
        ls_list-requestor   = CONV #( ls_hdr_db-ernam ).
        ls_list-created_by  = CONV #( ls_hdr_db-ernam ).

        IF ls_hdr_db-erdat IS NOT INITIAL.
          ls_list-req_date = |{ ls_hdr_db-erdat+6(2) }.{ ls_hdr_db-erdat+4(2) }.{ ls_hdr_db-erdat+0(4) }|.
        ELSE.
          ls_list-req_date = |{ sy-datum+6(2) }.{ sy-datum+4(2) }.{ sy-datum+0(4) }|.
        ENDIF.

        IF ls_hdr_db-erzet IS NOT INITIAL.
          ls_list-req_time = |{ ls_hdr_db-erzet+0(2) }:{ ls_hdr_db-erzet+2(2) }:{ ls_hdr_db-erzet+4(2) }|.
        ELSE.
          ls_list-req_time = |{ sy-uzeit+0(2) }:{ sy-uzeit+2(2) }:{ sy-uzeit+4(2) }|.
        ENDIF.

        " Get items detail
        SELECT * FROM zmdg_pir_itm
          INTO TABLE @lt_itm_db
          WHERE req_id = @ls_hdr_db-req_id.

        ls_list-total_item = lines( lt_itm_db ).

        READ TABLE lt_itm_db INTO ls_itm_db INDEX 1.
        IF sy-subrc = 0.
          ls_list-ekorg = CONV #( ls_itm_db-ekorg ).
          ls_list-werks = CONV #( ls_itm_db-werks ).
          ls_list-esokz = CONV #( ls_itm_db-esokz ).
          ls_list-ekgrp = CONV #( ls_itm_db-ekgrp ).
          ls_list-aplfz = CONV #( ls_itm_db-aplfz ).
          ls_list-norbm = CONV #( ls_itm_db-norbm ).
          ls_list-minbm = CONV #( ls_itm_db-minbm ).
          ls_list-uebto = CONV #( ls_itm_db-uebto ).
          ls_list-untto = CONV #( ls_itm_db-untto ).
          ls_list-netpr = CONV #( ls_itm_db-netpr ).
          ls_list-waers = CONV #( ls_itm_db-waers ).
          ls_list-peinh = CONV #( ls_itm_db-peinh ).
          ls_list-bprme = CONV #( ls_itm_db-bprme ).
          ls_list-mwskz = CONV #( ls_itm_db-mwskz ).
          ls_list-inco1 = CONV #( ls_itm_db-inco1 ).
          ls_list-inco2 = CONV #( ls_itm_db-inco2 ).
          IF ls_itm_db-datab IS NOT INITIAL.
            ls_list-datab = |{ ls_itm_db-datab+6(2) }.{ ls_itm_db-datab+4(2) }.{ ls_itm_db-datab+0(4) }|.
          ENDIF.
          IF ls_itm_db-datbi IS NOT INITIAL.
            ls_list-datbi = |{ ls_itm_db-datbi+6(2) }.{ ls_itm_db-datbi+4(2) }.{ ls_itm_db-datbi+0(4) }|.
          ENDIF.
        ENDIF.

        " Get latest audit comment
        SELECT * FROM zmdg_pir_adt
          INTO TABLE @lt_adt_db
          WHERE req_id = @ls_hdr_db-req_id
          ORDER BY log_id DESCENDING.

        READ TABLE lt_adt_db INTO ls_adt_db INDEX 1.
        IF sy-subrc = 0.
          ls_list-comments         = CONV #( ls_adt_db-comments ).
          ls_list-rejection_reason = CONV #( ls_adt_db-comments ).
          ls_list-appr_by          = CONV #( ls_adt_db-actor ).
          IF ls_adt_db-act_date IS NOT INITIAL.
            ls_list-appr_at = |{ ls_adt_db-act_date+6(2) }.{ ls_adt_db-act_date+4(2) }.{ ls_adt_db-act_date+0(4) }|.
          ENDIF.
        ENDIF.

        CASE ls_hdr_db-status.
          WHEN '00'. ls_list-status_desc = 'Draft'.
          WHEN '01'. ls_list-status_desc = 'Submitted / Pending Approval'.
          WHEN '02'. ls_list-status_desc = 'Approved'.
          WHEN '03'. ls_list-status_desc = 'Rejected'.
          WHEN '04'. ls_list-status_desc = 'Posted to SAP'.
          WHEN OTHERS. ls_list-status_desc = ls_hdr_db-status.
        ENDCASE.

        APPEND ls_list TO lt_list.
      ENDLOOP.

      lv_json = /ui2/cl_json=>serialize(
        data        = lt_list
        compress    = 'X'
        pretty_name = /ui2/cl_json=>pretty_mode-low_case
      ).
      _m_response->set_content_type( 'application/json' ).
      _m_response->set_cdata( lv_json ).
      _m_navigation->response_complete( ).
      RETURN.

    " ------------------------------------------------------------------
    " 2. FETCH INFO RECORD DETAIL
    " ------------------------------------------------------------------
    WHEN 'GET_UPLOAD_DETAIL' OR 'GET_IR_DETAIL'.
      lv_req_no = request->get_form_field( 'REQ_NO' ).
      IF lv_req_no IS INITIAL.
        lv_req_no = request->get_form_field( 'REQ_ID' ).
      ENDIF.

      CLEAR ls_hdr_db.
      SELECT SINGLE * FROM zmdg_req_pir
        INTO @ls_hdr_db
        WHERE req_id = @lv_req_no.

      IF sy-subrc = 0.
        SELECT * FROM zmdg_pir_itm INTO TABLE @lt_itm_db WHERE req_id = @lv_req_no.
        SELECT * FROM zmdg_pir_cnd INTO TABLE @lt_cnd_db WHERE req_id = @lv_req_no.
        SELECT * FROM zmdg_pir_adt INTO TABLE @lt_adt_db WHERE req_id = @lv_req_no ORDER BY log_id ASCENDING.

        TYPES: BEGIN OF ty_ir_det_wrap,
                 status     TYPE string,
                 message    TYPE string,
                 header     TYPE zmdg_req_pir,
                 items      TYPE TABLE OF zmdg_pir_itm WITH DEFAULT KEY,
                 conditions TYPE TABLE OF zmdg_pir_cnd WITH DEFAULT KEY,
                 audit_logs TYPE TABLE OF zmdg_pir_adt WITH DEFAULT KEY,
               END OF ty_ir_det_wrap.
        DATA: ls_ir_wrap TYPE ty_ir_det_wrap.
        ls_ir_wrap-status     = 'SUCCESS'.
        ls_ir_wrap-message    = 'Data Info Record retrieved successfully'.
        ls_ir_wrap-header     = ls_hdr_db.
        ls_ir_wrap-items      = lt_itm_db.
        ls_ir_wrap-conditions = lt_cnd_db.
        ls_ir_wrap-audit_logs = lt_adt_db.

        lv_json = /ui2/cl_json=>serialize(
          data        = ls_ir_wrap
          compress    = 'X'
          pretty_name = /ui2/cl_json=>pretty_mode-low_case
        ).
      ELSE.
        lv_json = |\{"status":"ERROR","message":"Request Info Record { lv_req_no } tidak ditemukan."\}|.
      ENDIF.

      _m_response->set_content_type( 'application/json' ).
      _m_response->set_cdata( lv_json ).
      _m_navigation->response_complete( ).
      RETURN.

    " ------------------------------------------------------------------
    " 3. QUICK / BULK APPROVE INFO RECORD
    " ------------------------------------------------------------------
    WHEN 'QUICK_APPROVE' OR 'BULK_APPROVE'.
      lv_req_nos = request->get_form_field( 'REQ_NOS' ).
      IF lv_req_nos IS INITIAL.
        lv_req_nos = request->get_form_field( 'REQ_NO' ).
      ENDIF.

      SPLIT lv_req_nos AT ',' INTO TABLE lt_req_split.
      lv_success_cnt = 0.
      lv_fail_cnt    = 0.
      CLEAR: lv_last_err, lt_resp_items.

      GET TIME STAMP FIELD lv_ts_now.

      LOOP AT lt_req_split INTO lv_req_item.
        CONDENSE lv_req_item.
        CHECK lv_req_item IS NOT INITIAL.

        CLEAR ls_hdr_db.
        SELECT SINGLE * FROM zmdg_req_pir
          INTO @ls_hdr_db
          WHERE req_id = @lv_req_item.

        IF sy-subrc <> 0.
          lv_fail_cnt = lv_fail_cnt + 1.
          lv_last_err = |Request { lv_req_item } tidak ditemukan.|.
          APPEND VALUE ty_resp_item(
            req_no  = lv_req_item
            status  = 'ERROR'
            message = lv_last_err
          ) TO lt_resp_items.
          CONTINUE.
        ENDIF.

        " Validate status eligibility for approval (must be 01)
        IF ls_hdr_db-status <> '01'.
          lv_fail_cnt = lv_fail_cnt + 1.
          lv_last_err = |Request { lv_req_item } (Status { ls_hdr_db-status }) sudah diproses atau belum memenuhi syarat approval.|.
          APPEND VALUE ty_resp_item(
            req_no  = lv_req_item
            status  = 'ERROR'
            message = lv_last_err
          ) TO lt_resp_items.
          CONTINUE.
        ENDIF.

        " Generate/format Info Record Number INFNR
        DATA: lv_gen_infnr TYPE c LENGTH 10.
        CLEAR lv_gen_infnr.

        IF ls_hdr_db-infnr IS NOT INITIAL.
          lv_gen_infnr = ls_hdr_db-infnr.
        ELSE.
          DATA: lv_seq_num TYPE i.
          SELECT COUNT( * ) FROM zmdg_req_pir INTO @lv_seq_num WHERE status IN ( '02', '04' ).
          lv_seq_num = lv_seq_num + 5300000001.
          lv_gen_infnr = CONV #( lv_seq_num ).
        ENDIF.

        CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
          EXPORTING input  = lv_gen_infnr
          IMPORTING output = lv_gen_infnr.

        " Update Staging Header Status to 02 (Approved)
        UPDATE zmdg_req_pir
          SET status = '02',
              infnr  = @lv_gen_infnr,
              aenam  = @sy-uname,
              aedat  = @sy-datum,
              aezet  = @sy-uzeit
          WHERE req_id = @lv_req_item.

        " Update Line Items post status
        UPDATE zmdg_pir_itm
          SET post_status = 'S',
              post_msg    = 'Info Record Approved & Posted to SAP'
          WHERE req_id = @lv_req_item.

        " Append Audit Trail Log Entry
        DATA: lv_next_log_id TYPE zmdg_pir_adt-log_id.
        SELECT MAX( log_id ) FROM zmdg_pir_adt INTO @lv_next_log_id WHERE req_id = @lv_req_item.
        lv_next_log_id = lv_next_log_id + 1.

        CLEAR ls_adt_db.
        ls_adt_db-mandt      = sy-mandt.
        ls_adt_db-req_id     = lv_req_item.
        ls_adt_db-log_id     = lv_next_log_id.
        ls_adt_db-approv_lvl = 1.
        ls_adt_db-action     = 'APPROVE'.
        ls_adt_db-actor      = sy-uname.
        ls_adt_db-act_date   = sy-datum.
        ls_adt_db-act_time   = sy-uzeit.
        ls_adt_db-comments   = 'Approved by Purchasing Approver'.

        MODIFY zmdg_pir_adt FROM @ls_adt_db.
        COMMIT WORK.

        lv_success_cnt = lv_success_cnt + 1.
        APPEND VALUE ty_resp_item(
          req_no  = lv_req_item
          infnr   = CONV #( lv_gen_infnr )
          matnr   = CONV #( ls_hdr_db-matnr )
          txz01   = CONV #( ls_hdr_db-txz01 )
          status  = 'SUCCESS'
          message = |Permohonan Info Harga { lv_req_item } berhasil di-approve! No. Info Record: { lv_gen_infnr }.|
        ) TO lt_resp_items.
      ENDLOOP.

      CLEAR ls_resp.
      ls_resp-items = lt_resp_items.

      IF lv_fail_cnt > 0 AND lv_success_cnt = 0.
        ls_resp-status  = 'ERROR'.
        ls_resp-message = 'Proses approval Info Record gagal: ' && lv_last_err.
      ELSEIF lv_fail_cnt > 0 AND lv_success_cnt > 0.
        ls_resp-status  = 'PARTIAL'.
        ls_resp-message = lv_success_cnt && ' Info Record BERHASIL di-approve, ' &&
                          lv_fail_cnt && ' GAGAL. Error: ' && lv_last_err.
      ELSE.
        ls_resp-status  = 'SUCCESS'.
        IF lv_success_cnt = 1.
          READ TABLE lt_resp_items INTO DATA(ls_first_succ) INDEX 1.
          ls_resp-req_no  = ls_first_succ-req_no.
          ls_resp-infnr   = ls_first_succ-infnr.
          ls_resp-message = |Permohonan Info Harga { ls_first_succ-req_no } | &&
                            |berhasil di-approve! Nomor Info Record: { ls_first_succ-infnr }.|.
        ELSE.
          ls_resp-message = |{ lv_success_cnt } Permohonan Info Harga berhasil di-approve!|.
        ENDIF.
      ENDIF.

      lv_json = /ui2/cl_json=>serialize(
        data        = ls_resp
        compress    = 'X'
        pretty_name = /ui2/cl_json=>pretty_mode-low_case
      ).
      _m_response->set_content_type( 'application/json' ).
      _m_response->set_cdata( lv_json ).
      _m_navigation->response_complete( ).
      RETURN.

    " ------------------------------------------------------------------
    " 4. BULK / SINGLE REJECT WITH REASON
    " ------------------------------------------------------------------
    WHEN 'BULK_REJECT' OR 'QUICK_REJECT' OR 'REJECT'.
      lv_req_nos = request->get_form_field( 'REQ_NOS' ).
      IF lv_req_nos IS INITIAL.
        lv_req_nos = request->get_form_field( 'REQ_NO' ).
      ENDIF.

      lv_reason = request->get_form_field( 'REJ_REASON' ).

      SPLIT lv_req_nos AT ',' INTO TABLE lt_req_split.
      GET TIME STAMP FIELD lv_ts_now.

      LOOP AT lt_req_split INTO lv_req_item.
        CONDENSE lv_req_item.
        CHECK lv_req_item IS NOT INITIAL.

        UPDATE zmdg_req_pir
          SET status = '03',
              aenam  = @sy-uname,
              aedat  = @sy-datum,
              aezet  = @sy-uzeit
          WHERE req_id = @lv_req_item.

        DATA: lv_rj_log_id TYPE zmdg_pir_adt-log_id.
        SELECT MAX( log_id ) FROM zmdg_pir_adt INTO @lv_rj_log_id WHERE req_id = @lv_req_item.
        lv_rj_log_id = lv_rj_log_id + 1.

        CLEAR ls_adt_db.
        ls_adt_db-mandt      = sy-mandt.
        ls_adt_db-req_id     = lv_req_item.
        ls_adt_db-log_id     = lv_rj_log_id.
        ls_adt_db-approv_lvl = 1.
        ls_adt_db-action     = 'REJECT'.
        ls_adt_db-actor      = sy-uname.
        ls_adt_db-act_date   = sy-datum.
        ls_adt_db-act_time   = sy-uzeit.
        ls_adt_db-comments   = lv_reason.

        MODIFY zmdg_pir_adt FROM @ls_adt_db.
      ENDLOOP.
      COMMIT WORK.

      lv_json = '{"status":"SUCCESS","message":' &&
                '"Permohonan Info Record berhasil ditolak!"}'.
      _m_response->set_content_type( 'application/json' ).
      _m_response->set_cdata( lv_json ).
      _m_navigation->response_complete( ).
      RETURN.

    " ------------------------------------------------------------------
    " 5. LOGOUT
    " ------------------------------------------------------------------
    WHEN 'LOGOUT'.
      _m_navigation->exit( ).
      RETURN.

  ENDCASE.

ENDIF.
