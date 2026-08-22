  DATA: lv_action     TYPE string,
        lv_json       TYPE string,
        lv_req_no     TYPE string,
        lv_status     TYPE string,
        lv_reason     TYPE string,
        lv_count_str  TYPE string,
        lv_count      TYPE i,
        idx_str       TYPE string,
        lv_matnr_val  TYPE string,
        lv_missing    TYPE sap_bool.

  DATA: ls_hdr TYPE zmdg_req_hdr,
        lt_dtl TYPE TABLE OF zmdg_req_dtl,
        ls_dtl TYPE zmdg_req_dtl.

  TYPES: BEGIN OF ty_req_list,
          req_no      TYPE string,
          remarks     TYPE string,
          sub_reason  TYPE string,
          req_date    TYPE string,
          req_time    TYPE string,
          requestor   TYPE string,
          status      TYPE string,
          total_item  TYPE i,
          coded_count TYPE i,
          rej_reason  TYPE string,
        END OF ty_req_list.

  DATA: lt_req_list TYPE TABLE OF ty_req_list,
        ls_req_list TYPE ty_req_list.

  DATA: lt_hdr_db TYPE TABLE OF zmdg_req_hdr,
        ls_hdr_db TYPE zmdg_req_hdr,
        lt_dtl_db TYPE TABLE OF zmdg_req_dtl,
        ls_dtl_db TYPE zmdg_req_dtl.

  TYPES: BEGIN OF ty_resp,
          status  TYPE string,
          message TYPE string,
        END OF ty_resp.
  DATA: ls_resp TYPE ty_resp.

  lv_action = request->get_form_field( 'OnInputProcessing' ).

  CASE lv_action.

    " ==================================================================
    " 1. GET ALL REQUESTS FOR MATERIAL CODE ASSIGNMENT
    " ==================================================================
    WHEN 'GET_PENDING_LIST'.
      CLEAR: lt_hdr_db, lt_req_list.

      SELECT * FROM zmdg_req_hdr
        INTO TABLE @lt_hdr_db
        ORDER BY req_date DESCENDING, req_time DESCENDING.

      LOOP AT lt_hdr_db INTO ls_hdr_db.
        CLEAR ls_req_list.
        ls_req_list-req_no     = CONV #( ls_hdr_db-req_no ).
        ls_req_list-remarks    = CONV #( ls_hdr_db-remarks ).
        ls_req_list-sub_reason = CONV #( ls_hdr_db-sub_reason ).
        ls_req_list-req_date   = CONV #( ls_hdr_db-req_date ).
        ls_req_list-req_time   = CONV #( ls_hdr_db-req_time ).
        ls_req_list-requestor  = CONV #( ls_hdr_db-requestor ).
        ls_req_list-status     = CONV #( ls_hdr_db-status ).
        ls_req_list-rej_reason = CONV #( ls_hdr_db-rej_reason ).

        SELECT COUNT( * ) FROM zmdg_req_dtl INTO @ls_req_list-total_item WHERE req_no = @ls_hdr_db-req_no.

        SELECT COUNT( * ) FROM zmdg_req_dtl WHERE req_no = @ls_hdr_db-req_no AND matnr_ext IS NOT INITIAL INTO @ls_req_list-coded_count.

        APPEND ls_req_list TO lt_req_list.
      ENDLOOP.

      lv_json = /ui2/cl_json=>serialize( data = lt_req_list compress = 'X' pretty_name = /ui2/cl_json=>pretty_mode-low_case ).
      _m_response->set_content_type( 'application/json' ).
      _m_response->set_cdata( lv_json ).
      navigation->goto_page( '' ).
      RETURN.

    " ==================================================================
    " 2. GET REQUEST ITEMS DETAIL
    " ==================================================================
    WHEN 'GET_REQUEST_DETAIL'.
      lv_req_no = request->get_form_field( 'REQ_NO' ).
      IF lv_req_no IS INITIAL.
        lv_req_no = request->get_form_field( 'UPLOAD_ID' ).
      ENDIF.
      CLEAR: lt_dtl_db.

      SELECT * FROM zmdg_req_dtl
        INTO TABLE @lt_dtl_db
        WHERE req_no = @lv_req_no
        ORDER BY item_no ASCENDING.

      lv_json = /ui2/cl_json=>serialize( data = lt_dtl_db compress = 'X' pretty_name = /ui2/cl_json=>pretty_mode-low_case ).
      _m_response->set_content_type( 'application/json' ).
      _m_response->set_cdata( lv_json ).
      navigation->goto_page( '' ).
      RETURN.

    " ==================================================================
    " 3. SAVE MATERIAL CODES (DRAFT / IN-PROGRESS)
    " ==================================================================
    WHEN 'SAVE_MATERIAL_CODES'.
      lv_req_no    = request->get_form_field( 'REQ_NO' ).
      lv_count_str = request->get_form_field( 'ROW_COUNT' ).
      lv_count     = lv_count_str.

      IF lv_req_no IS INITIAL OR lv_count <= 0.
        lv_json = '{"status":"ERROR","message":"Invalid Request ID or empty item count."}'.
        _m_response->set_content_type( 'application/json' ).
        _m_response->set_cdata( lv_json ).
        navigation->goto_page( '' ).
        RETURN.
      ENDIF.

      DO lv_count TIMES.
        idx_str = sy-index.
        CONDENSE idx_str.
        lv_matnr_val = request->get_form_field( |matnr_{ idx_str }| ).

        UPDATE zmdg_req_dtl
          SET matnr_ext = @lv_matnr_val
          WHERE req_no  = @lv_req_no
            AND item_no = @sy-index.
      ENDDO.

      lv_json = |\{"status":"SUCCESS","message":"Material Codes draft saved successfully for Request { lv_req_no }."\}|.
      _m_response->set_content_type( 'application/json' ).
      _m_response->set_cdata( lv_json ).
      navigation->goto_page( '' ).
      RETURN.

    " ==================================================================
    " 4. MARK AS CHECKED BY DATA STEWARD -> STATUS = 'CHECKED'
    " ==================================================================
    WHEN 'SUBMIT_TO_APPROVAL' OR 'CHECK_AND_FORWARD'.
      lv_req_no = request->get_form_field( 'REQ_NO' ).
      IF lv_req_no IS INITIAL.
        lv_req_no = request->get_form_field( 'UPLOAD_ID' ).
      ENDIF.

      IF lv_req_no IS INITIAL.
        lv_json = '{"status":"ERROR","message":"Request ID is required."}'.
        _m_response->set_content_type( 'application/json' ).
        _m_response->set_cdata( lv_json ).
        navigation->goto_page( '' ).
        RETURN.
      ENDIF.

      " ==================================================================
      " EXCEL.ABAP VALIDATION ENGINE FOR DATA STEWARD CHECK
      " ==================================================================
      DATA: lt_check_dtl   TYPE TABLE OF zmdg_req_dtl,
            ls_check_dtl   TYPE zmdg_req_dtl,
            lv_err_log     TYPE string,
            lv_item_err    TYPE string,
            lv_has_val_err TYPE sap_bool VALUE abap_false.

      SELECT * FROM zmdg_req_dtl
        INTO TABLE @lt_check_dtl
        WHERE req_no = @lv_req_no
        ORDER BY item_no ASCENDING.

      IF lt_check_dtl IS INITIAL.
        lv_json = '{"status":"ERROR","message":"Detail item request tidak ditemukan."}'.
        _m_response->set_content_type( 'application/json' ).
        _m_response->set_cdata( lv_json ).
        navigation->goto_page( '' ).
        RETURN.
      ENDIF.

      CLEAR: lv_err_log, lv_has_val_err.

      LOOP AT lt_check_dtl INTO ls_check_dtl.
        CLEAR lv_item_err.
        DATA: lv_item_num TYPE i.
        lv_item_num = CONV i( ls_check_dtl-item_no ).

        " 1. Rule E01: Classification & UoM Usage (KZWSM) Conflict
        IF ( ls_check_dtl-class IS NOT INITIAL AND ( ls_check_dtl-warna IS NOT INITIAL OR ls_check_dtl-vol_prod IS NOT INITIAL ) )
           AND ls_check_dtl-kzwsm IS NOT INITIAL.
          IF lv_item_err IS NOT INITIAL. lv_item_err = |{ lv_item_err }; |. ENDIF.
          lv_item_err = |{ lv_item_err }[E01] Data Classification & KZWSM tdk boleh diisi bersamaan|.
        ENDIF.

        " 2. Rule E03: Mandatory Material Type (MTART) & Industry Sector (MBRSH)
        IF ls_check_dtl-mbrsh IS INITIAL OR ls_check_dtl-mtart IS INITIAL.
          IF lv_item_err IS NOT INITIAL. lv_item_err = |{ lv_item_err }; |. ENDIF.
          lv_item_err = |{ lv_item_err }[E03] MTART & MBRSH wajib diisi|.
        ENDIF.

        " 3. Rule E04: Mandatory Plant (WERKS)
        IF ls_check_dtl-werks IS INITIAL.
          IF lv_item_err IS NOT INITIAL. lv_item_err = |{ lv_item_err }; |. ENDIF.
          lv_item_err = |{ lv_item_err }[E04] Plant (WERKS) wajib diisi|.
        ENDIF.

        " 4. Rule E05: Mandatory Storage Location (LGORT)
        IF ls_check_dtl-lgort IS INITIAL.
          IF lv_item_err IS NOT INITIAL. lv_item_err = |{ lv_item_err }; |. ENDIF.
          lv_item_err = |{ lv_item_err }[E05] Storage Location (LGORT) wajib diisi|.
        ENDIF.

        " 5. Rule E06: Mandatory Profit Center (PRCTR)
        IF ls_check_dtl-prctr IS INITIAL.
          IF lv_item_err IS NOT INITIAL. lv_item_err = |{ lv_item_err }; |. ENDIF.
          lv_item_err = |{ lv_item_err }[E06] Profit Center (PRCTR) wajib diisi|.
        ENDIF.

        " 6. Rule E07: Mandatory Material Description (MAKTX)
        IF ls_check_dtl-maktx IS INITIAL.
          IF lv_item_err IS NOT INITIAL. lv_item_err = |{ lv_item_err }; |. ENDIF.
          lv_item_err = |{ lv_item_err }[E07] Material Description (MAKTX) wajib diisi|.
        ENDIF.

        " 7. Rule E08: Mandatory Base Unit of Measure (MEINS)
        IF ls_check_dtl-meins IS INITIAL.
          IF lv_item_err IS NOT INITIAL. lv_item_err = |{ lv_item_err }; |. ENDIF.
          lv_item_err = |{ lv_item_err }[E08] Base UoM (MEINS) wajib diisi|.
        ENDIF.

        " 8. Table Existence Check - T001W (Plant Master)
        IF ls_check_dtl-werks IS NOT INITIAL.
          SELECT SINGLE werks FROM t001w INTO @DATA(lv_dummy_w) WHERE werks = @ls_check_dtl-werks.
          IF sy-subrc <> 0.
            IF lv_item_err IS NOT INITIAL. lv_item_err = |{ lv_item_err }; |. ENDIF.
            lv_item_err = |{ lv_item_err }Plant '{ ls_check_dtl-werks }' tdk ada di master SAP (T001W)|.
          ENDIF.
        ENDIF.

        " 9. Table Existence Check - T001L (Storage Location Master)
        IF ls_check_dtl-werks IS NOT INITIAL AND ls_check_dtl-lgort IS NOT INITIAL.
          SELECT SINGLE lgort FROM t001l INTO @DATA(lv_dummy_l) WHERE werks = @ls_check_dtl-werks AND lgort = @ls_check_dtl-lgort.
          IF sy-subrc <> 0.
            IF lv_item_err IS NOT INITIAL. lv_item_err = |{ lv_item_err }; |. ENDIF.
            lv_item_err = |{ lv_item_err }S.Loc '{ ls_check_dtl-lgort }' tdk valid utk Plant '{ ls_check_dtl-werks }' (T001L)|.
          ENDIF.
        ENDIF.

        IF lv_item_err IS NOT INITIAL.
          lv_has_val_err = abap_true.
          IF lv_err_log IS NOT INITIAL.
            lv_err_log = |{ lv_err_log } \n |.
          ENDIF.
          lv_err_log = |{ lv_err_log }Item #{ lv_item_num } ({ ls_check_dtl-maktx }): { lv_item_err }|.
        ENDIF.
      ENDLOOP.

      " IF ANY ITEM FAILS VALIDATION -> AUTO REJECT
      IF lv_has_val_err = abap_true.
        DATA: lv_auto_rej_reason TYPE string.
        lv_auto_rej_reason = |[AUTO-REJECT EXCEL.ABAP] { lv_err_log }|.

        " Fetch Header & Requestor Info
        CLEAR ls_hdr.
        SELECT SINGLE * FROM zmdg_req_hdr INTO @ls_hdr WHERE req_no = @lv_req_no.

        " Update Header Status to REJECTED
        UPDATE zmdg_req_hdr
          SET status     = 'REJECTED',
              rej_reason = @lv_auto_rej_reason,
              approver   = @sy-uname,
              app_date   = @sy-datum,
              app_time   = @sy-uzeit
          WHERE req_no   = @lv_req_no.

        " Send Rejection Email Notification to Requestor
        DATA: lv_req_usr TYPE usr21-bname,
              lt_smtp_a  TYPE TABLE OF bapiadsmtp,
              ls_smtp_a  TYPE bapiadsmtp,
              lt_ret_u   TYPE TABLE OF bapiret2,
              lv_em_addr TYPE string.

        lv_req_usr = CONV #( ls_hdr-requestor ).
        IF lv_req_usr IS NOT INITIAL.
          CALL FUNCTION 'BAPI_USER_GET_DETAIL'
            EXPORTING username = lv_req_usr
            TABLES return = lt_ret_u addsmtp = lt_smtp_a.
          READ TABLE lt_smtp_a INTO ls_smtp_a INDEX 1.
          IF sy-subrc = 0 AND ls_smtp_a-e_mail IS NOT INITIAL.
            lv_em_addr = ls_smtp_a-e_mail.
          ENDIF.
        ENDIF.

        IF lv_em_addr IS NOT INITIAL.
          TRY.
              DATA: lo_send_r  TYPE REF TO cl_bcs,
                    lo_doc_r   TYPE REF TO cl_document_bcs,
                    lo_rec_r   TYPE REF TO if_recipient_bcs,
                    lt_body_r  TYPE bcsy_text,
                    lv_subj_r  TYPE so_obj_des,
                    lv_sent_r  TYPE abap_bool.

              lo_send_r = cl_bcs=>create_persistent( ).
              lv_subj_r = |[MDG AUTO-REJECT] Request { lv_req_no } Gagal Validasi excel.abap|.

              APPEND |Yth. { ls_hdr-requestor },| TO lt_body_r.
              APPEND | | TO lt_body_r.
              APPEND |Pengajuan Material Master Anda (Request ID: { lv_req_no }) DITOLAK OTOMATIS saat pemeriksaan Data Steward.| TO lt_body_r.
              APPEND |Alasan: Terdapat data/kolom yang tidak memenuhi aturan validasi excel.abap.| TO lt_body_r.
              APPEND |----------------------------------------------------------------------| TO lt_body_r.
              APPEND |RINCIAN KESALAHAN VALIDASI:| TO lt_body_r.
              APPEND |{ lv_err_log }| TO lt_body_r.
              APPEND |----------------------------------------------------------------------| TO lt_body_r.
              APPEND |Silakan perbaiki data pada sistem SAP MDG dan lakukan submit ulang.| TO lt_body_r.
              APPEND | | TO lt_body_r.
              APPEND |Salam,| TO lt_body_r.
              APPEND |SAP MDG Data Steward Validation System| TO lt_body_r.

              lo_doc_r = cl_document_bcs=>create_document(
                          i_type    = 'RAW'
                          i_text    = lt_body_r
                          i_subject = lv_subj_r ).
              lo_send_r->set_document( lo_doc_r ).
              lo_rec_r = cl_cam_address_bcs=>create_internet_address( CONV #( lv_em_addr ) ).
              lo_send_r->add_recipient( lo_rec_r ).
              lo_send_r->set_send_immediately( abap_true ).
              lv_sent_r = lo_send_r->send( i_with_error_screen = abap_false ).
              COMMIT WORK.
            CATCH cx_bcs.
          ENDTRY.
        ENDIF.

        TYPES: BEGIN OF ty_err_json,
                 status     TYPE string,
                 message    TYPE string,
                 rej_reason TYPE string,
               END OF ty_err_json.
        DATA: ls_err_json TYPE ty_err_json.

        ls_err_json-status     = 'REJECTED'.
        ls_err_json-message    = |Dokumen { lv_req_no } gagal validasi excel.abap dan OTOMATIS DITOLAK (REJECTED).|.
        ls_err_json-rej_reason = lv_auto_rej_reason.

        lv_json = /ui2/cl_json=>serialize( data = ls_err_json compress = 'X' pretty_name = /ui2/cl_json=>pretty_mode-low_case ).
        _m_response->set_content_type( 'application/json' ).
        _m_response->set_cdata( lv_json ).
        navigation->goto_page( '' ).
        RETURN.
      ENDIF.

      " IF ALL ITEMS ARE VALID -> MARK AS CHECKED & FORWARD TO APPROVAL
      UPDATE zmdg_req_hdr
        SET status = 'CHECKED'
        WHERE req_no = @lv_req_no.

      lv_json = |\{"status":"SUCCESS","message":"Request { lv_req_no } telah berhasil lolos seluruh validasi excel.abap dan diteruskan ke Approval (stagging_list.htm)!"\}|.
      _m_response->set_content_type( 'application/json' ).
      _m_response->set_cdata( lv_json ).
      navigation->goto_page( '' ).
      RETURN.

    " ==================================================================
    " 5. RETURN / REJECT REQUEST TO PURCHASING (DATA STEWARD)
    " ==================================================================
    WHEN 'RETURN_TO_REQUESTOR' OR 'REJECT'.
      lv_req_no = request->get_form_field( 'REQ_NO' ).
      IF lv_req_no IS INITIAL.
        lv_req_no = request->get_form_field( 'UPLOAD_ID' ).
      ENDIF.

      lv_reason = request->get_form_field( 'REJ_REASON' ).
      IF lv_reason IS INITIAL.
        lv_reason = request->get_form_field( 'REASON' ).
      ENDIF.

      IF lv_req_no IS INITIAL.
        lv_json = '{"status":"ERROR","message":"Nomor Request ID wajib diisi."}'.
        _m_response->set_content_type( 'application/json' ).
        _m_response->set_cdata( lv_json ).
        navigation->goto_page( '' ).
        RETURN.
      ENDIF.

      IF lv_reason IS INITIAL.
        lv_json = '{"status":"ERROR","message":"Alasan Penolakan (Rejection Reason) wajib diisi."}'.
        _m_response->set_content_type( 'application/json' ).
        _m_response->set_cdata( lv_json ).
        navigation->goto_page( '' ).
        RETURN.
      ENDIF.

      " Ambil data Request Header untuk mendapatkan data Requestor
      CLEAR ls_hdr.
      SELECT SINGLE * FROM zmdg_req_hdr INTO @ls_hdr WHERE req_no = @lv_req_no.

      " Update Header: Status, Rejection Reason, dan Execution Log
      UPDATE zmdg_req_hdr
        SET status     = 'REJECTED',
            rej_reason = @lv_reason,
            approver   = @sy-uname,
            app_date   = @sy-datum,
            app_time   = @sy-uzeit
        WHERE req_no   = @lv_req_no.

      " Cari alamat email user requestor
      DATA: lv_requestor TYPE usr21-bname,
            lt_smtp      TYPE TABLE OF bapiadsmtp,
            ls_smtp      TYPE bapiadsmtp,
            lt_return_u  TYPE TABLE OF bapiret2,
            lv_email     TYPE string.

      lv_requestor = CONV #( ls_hdr-requestor ).

      IF lv_requestor IS NOT INITIAL.
        " Method 1: BAPI_USER_GET_DETAIL
        CALL FUNCTION 'BAPI_USER_GET_DETAIL'
          EXPORTING
            username = lv_requestor
          TABLES
            return   = lt_return_u
            addsmtp  = lt_smtp.

        READ TABLE lt_smtp INTO ls_smtp INDEX 1.
        IF sy-subrc = 0 AND ls_smtp-e_mail IS NOT INITIAL.
          lv_email = ls_smtp-e_mail.
        ENDIF.

        " Method 2: Lookup via USR21 & ADR6 jika BAPI tidak mengembalikan email
        IF lv_email IS INITIAL.
          DATA: lv_persno TYPE usr21-persnumber,
                lv_addrno TYPE usr21-addrnumber.
          SELECT SINGLE persnumber, addrnumber
            FROM usr21
            INTO (@lv_persno, @lv_addrno)
            WHERE bname = @lv_requestor.
          IF sy-subrc = 0.
            SELECT SINGLE smtp_addr
              FROM adr6
              INTO @lv_email
              WHERE persnumber = @lv_persno
                AND addrnumber = @lv_addrno.
          ENDIF.
        ENDIF.
      ENDIF.

      " Kirim Notifikasi Email Penolakan ke Requestor via CL_BCS
      IF lv_email IS NOT INITIAL.
        TRY.
            DATA: lo_send_req  TYPE REF TO cl_bcs,
                  lo_doc       TYPE REF TO cl_document_bcs,
                  lo_recipient TYPE REF TO if_recipient_bcs,
                  lt_body      TYPE bcsy_text,
                  lv_subject   TYPE so_obj_des,
                  lv_sent      TYPE abap_bool.

            lo_send_req = cl_bcs=>create_persistent( ).

            lv_subject = |[MDG REJECTED] Request { lv_req_no } telah Ditolak|.

            APPEND |Yth. { ls_hdr-requestor },| TO lt_body.
            APPEND | | TO lt_body.
            APPEND |Pengajuan Material Master Anda dengan rincian berikut telah DITOLAK oleh Data Steward:| TO lt_body.
            APPEND |----------------------------------------------------------------------| TO lt_body.
            APPEND |Nomor Request    : { lv_req_no }| TO lt_body.
            APPEND |Status           : REJECTED| TO lt_body.
            APPEND |Alasan Penolakan : { lv_reason }| TO lt_body.
            APPEND |Data Steward     : { sy-uname }| TO lt_body.
            APPEND |Tanggal Penolakan: { sy-datum+6(2) }/{ sy-datum+4(2) }/{ sy-datum(4) } { sy-uzeit(2) }:{ sy-uzeit+2(2) }:{ sy-uzeit+4(2) }| TO lt_body.
            APPEND |----------------------------------------------------------------------| TO lt_body.
            APPEND |Silakan akses sistem SAP MDG untuk melakukan perbaikan dan submit kembali.| TO lt_body.
            APPEND | | TO lt_body.
            APPEND |Salam,| TO lt_body.
            APPEND |SAP MDG Data Steward System| TO lt_body.

            lo_doc = cl_document_bcs=>create_document(
                        i_type    = 'RAW'
                        i_text    = lt_body
                        i_subject = lv_subject ).

            lo_send_req->set_document( lo_doc ).

            lo_recipient = cl_cam_address_bcs=>create_internet_address( CONV #( lv_email ) ).
            lo_send_req->add_recipient( lo_recipient ).

            lo_send_req->set_send_immediately( abap_true ).
            lv_sent = lo_send_req->send( i_with_error_screen = abap_false ).
            COMMIT WORK.
          CATCH cx_bcs INTO DATA(lx_bcs).
            " Silently catch exception
        ENDTRY.
      ENDIF.

      lv_json = |\{"status":"SUCCESS","message":"Request { lv_req_no } telah berhasil ditolak dan notifikasi dikirimkan ke Requestor."\}|.
      _m_response->set_content_type( 'application/json' ).
      _m_response->set_cdata( lv_json ).
      navigation->goto_page( '' ).
      RETURN.

    " ==================================================================
    " 6. LOGOUT
    " ==================================================================
    WHEN 'LOGOUT'.
      navigation->exit( ).
      RETURN.

  ENDCASE.
