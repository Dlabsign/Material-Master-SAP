    DATA: lv_action   TYPE string,
          lv_json     TYPE string,
          lv_req_no   TYPE string,
          lv_req_nos  TYPE string,
          lv_reason   TYPE string,
          lv_auth_user TYPE string.

    TYPES: BEGIN OF ty_staging_list,
            req_no         TYPE string,
            remarks        TYPE string,
            sub_reason     TYPE string,
            req_date       TYPE string,
            req_time       TYPE string,
            requestor      TYPE string,
            requestor_name TYPE string,
            status         TYPE string,
            total_item     TYPE i,
            rej_reason     TYPE string,
          END OF ty_staging_list.

    DATA: lt_list TYPE TABLE OF ty_staging_list,
          ls_list TYPE ty_staging_list.

    DATA: lt_hdr_db TYPE TABLE OF zmdg_stg_hdr,
          ls_hdr_db TYPE zmdg_stg_hdr,
          lt_dtl_db TYPE TABLE OF zmdg_stg_part,
          ls_dtl_db TYPE zmdg_stg_part.

    DATA: lt_req_split TYPE TABLE OF string,
          lv_req_item  TYPE string.

    " Variabel Pengecekan & Auto-Generate
    DATA: lv_is_available TYPE char1,
          lv_next_number  TYPE matnr_ext,
          lt_check_return TYPE TABLE OF bapiret2,
          ls_check_return TYPE bapiret2,
          lv_exist_mara   TYPE mara-matnr,
          lv_exist_stage  TYPE zmdg_stg_hdr-status,
          lt_used_matnr   TYPE TABLE OF string,
          lv_cand_matnr   TYPE string,
          lv_check_matnr  TYPE matnr,
          lv_alpha_matnr  TYPE mara-matnr,
          lv_exist_mtart  TYPE mara-mtart,
          lv_in_batch     TYPE char1.

    " Struktur & Variabel BAPI Material Master
    DATA: ls_headdata            TYPE bapimathead,
          ls_clientdata           TYPE bapi_mara,
          ls_clientdatax          TYPE bapi_marax,
          ls_plantdata            TYPE bapi_marc,
          ls_plantdatax           TYPE bapi_marcx,
          ls_storagelocationdata  TYPE bapi_mard,
          ls_storagelocationdatax TYPE bapi_mardx,
          ls_valuationdata        TYPE bapi_mbew,
          ls_valuationdatax       TYPE bapi_mbewx,
          ls_salesdata            TYPE bapi_mvke,
          ls_salesdatax           TYPE bapi_mvkex,
          ls_warehousenumberdata  TYPE bapi_mlgn,
          ls_warehousenumberdatax TYPE bapi_mlgnx,
          ls_storagetypedata      TYPE bapi_mlgt,
          ls_storagetypedatax     TYPE bapi_mlgtx,
          lt_materialdesc         TYPE TABLE OF bapi_makt,
          ls_materialdesc         TYPE bapi_makt,
          lt_unitsofmeasure       TYPE TABLE OF bapi_marm,
          ls_unitsofmeasure       TYPE bapi_marm,
          lt_unitsofmeasurex      TYPE TABLE OF bapi_marmx,
          ls_unitsofmeasurex      TYPE bapi_marmx,
          ls_bapireturn           TYPE bapiret2,
          lt_taxclassifications   TYPE TABLE OF bapi_mlan,
          ls_taxclassification    TYPE bapi_mlan,
          lt_returnmes            TYPE TABLE OF bapi_matreturn2,
          ls_returnmes            TYPE bapi_matreturn2.

    " Variabel Material Ledger (Hard Currency) & Numeric Sanitization
    DATA: lt_ml_prices    TYPE TABLE OF bapi_matval_prices,
          ls_ml_price     TYPE bapi_matval_prices,
          lt_ml_return    TYPE TABLE OF bapiret2,
          ls_ml_return    TYPE bapiret2,
          lv_ml_matnr     TYPE matnr,
          lv_ml_pricedate TYPE bapi_matval_pricedate,
          lv_app_bukrs    TYPE t001k-bukrs,
          lv_app_kokrs    TYPE tka02-kokrs,
          lv_app_hrkft    TYPE tkkh1-hrkft,
          lv_herbl_sub    TYPE tkkh1-hrkft,
          lv_hard_curr    TYPE waers,
          lv_clean_moving TYPE string,
          lv_clean_std    TYPE string,
          lv_clean_unit   TYPE string,
          lv_clean_unit_2 TYPE string,
          lv_work_num     TYPE string,
          lv_num_tmp      TYPE string,
          lv_num_int      TYPE p DECIMALS 0,
          lv_disp_matnr   TYPE string,
          lv_dot_cnt      TYPE i,
          lv_pos_dot      TYPE i,
          lv_pos_com      TYPE i,
          lv_len          TYPE i,
          lv_dec_len      TYPE i,
          lv_valid_tatyp  TYPE tatyp,
          lv_uom_iso      TYPE t006-isocode.

    DATA: lv_has_error   TYPE sap_bool,
          lv_err_msg     TYPE string,
          lv_last_err    TYPE string,
          lv_coded_cnt   TYPE i,
          lv_success_cnt TYPE i,
          lv_fail_cnt    TYPE i,
          lv_curr_stat   TYPE zmdg_stg_hdr-status.

    TYPES: BEGIN OF ty_bapi_msg,
             type       TYPE string,
             id         TYPE string,
             number     TYPE string,
             message    TYPE string,
             message_v1 TYPE string,
             message_v2 TYPE string,
           END OF ty_bapi_msg.

    TYPES: BEGIN OF ty_resp,
            status          TYPE string,
            message         TYPE string,
            matnr           TYPE string,
            matnr_ext       TYPE string,
            materials       TYPE TABLE OF string WITH DEFAULT KEY,
            return_messages TYPE TABLE OF ty_bapi_msg WITH DEFAULT KEY,
          END OF ty_resp.
    DATA: ls_resp TYPE ty_resp.

    lv_action = request->get_form_field( 'action' ).
    IF lv_action IS INITIAL.
      lv_action = request->get_form_field( 'OnInputProcessing' ).
    ENDIF.
    TRANSLATE lv_action TO UPPER CASE.

    lv_auth_user = sy-uname.
    TRANSLATE lv_auth_user TO UPPER CASE.
    CONDENSE lv_auth_user NO-GAPS.

    IF lv_auth_user <> 'ABAPER04' AND
       lv_auth_user <> 'BASIS' AND
       lv_auth_user <> 'KMI-BOD' AND
       lv_auth_user <> 'KMI-U163' AND
       lv_auth_user <> 'ADMINISTRATOR' AND
       lv_auth_user <> 'TOTOK' AND
       lv_auth_user <> 'DEFAULT'.
      IF lv_action IS NOT INITIAL.
        _m_response->set_status( code = 403 reason = 'Forbidden' ).
        _m_response->set_content_type( 'application/json' ).
        _m_response->set_cdata( '{"status":"ERROR","message":"Akses Terbatas: Anda tidak memiliki akses untuk masuk ke halaman ini, silahkan hubungi core tim."}' ).
        _m_navigation->response_complete( ).
        RETURN.
      ENDIF.
    ENDIF.

    IF lv_action IS NOT INITIAL.

      CASE lv_action.

        " ------------------------------------------------------------------
        " GET COUNTERS FOR SIDEBAR BADGES
        " ------------------------------------------------------------------
        WHEN 'GET_COUNTERS'.
          DATA: lv_cnt_mat_p TYPE i,
                lv_cnt_bp_p  TYPE i,
                lv_cnt_ir_p  TYPE i,
                lv_cnt_mat_a TYPE i,
                lv_cnt_bp_a  TYPE i,
                lv_cnt_ir_a  TYPE i,
                lv_cnt_mat_r TYPE i,
                lv_cnt_bp_r  TYPE i,
                lv_cnt_ir_r  TYPE i,
                lv_cnt_tot_a TYPE i,
                lv_cnt_tot_r TYPE i.

          SELECT COUNT( * ) FROM zmdg_stg_hdr
            WHERE status IN ( 'CHECKED', 'CODED', 'SUBMITTED' )
            INTO @lv_cnt_mat_p.

          SELECT COUNT( * ) FROM zmdg_bp_req
            WHERE status IN ( 'SUBMITTED', 'CHECKED' )
            INTO @lv_cnt_bp_p.

          SELECT COUNT( * ) FROM zmdg_req_pir
            WHERE status = '01'
            INTO @lv_cnt_ir_p.

          SELECT COUNT( * ) FROM zmdg_stg_hdr
            WHERE status = 'APPROVED'
            INTO @lv_cnt_mat_a.

          SELECT COUNT( * ) FROM zmdg_bp_req
            WHERE status IN ( 'SD_APPROVED', 'MM_APPROVED', 'APPROVED' )
            INTO @lv_cnt_bp_a.

          SELECT COUNT( * ) FROM zmdg_req_pir
            WHERE status IN ( '02', '04' )
            INTO @lv_cnt_ir_a.

          lv_cnt_tot_a = lv_cnt_mat_a + lv_cnt_bp_a + lv_cnt_ir_a.

          SELECT COUNT( * ) FROM zmdg_stg_hdr
            WHERE status IN ( 'REJECTED', 'FAILED' )
            INTO @lv_cnt_mat_r.

          SELECT COUNT( * ) FROM zmdg_bp_req
            WHERE status IN ( 'REJECTED', 'FAILED' )
            INTO @lv_cnt_bp_r.

          SELECT COUNT( * ) FROM zmdg_req_pir
            WHERE status = '03'
            INTO @lv_cnt_ir_r.

          lv_cnt_tot_r = lv_cnt_mat_r + lv_cnt_bp_r + lv_cnt_ir_r.

          lv_json = '{"pending":' && lv_cnt_mat_p &&
                    ',"mat_pending":' && lv_cnt_mat_p &&
                    ',"bp_pending":' && lv_cnt_bp_p &&
                    ',"ir_pending":' && lv_cnt_ir_p &&
                    ',"approved":' && lv_cnt_tot_a &&
                    ',"rejected":' && lv_cnt_tot_r && '}'.
          _m_response->set_content_type( 'application/json' ).
          _m_response->set_cdata( lv_json ).
          _m_navigation->response_complete( ).
          RETURN.

        " ------------------------------------------------------------------
        " 1. GET ALL STAGING REQUEST LIST
        " ------------------------------------------------------------------
        WHEN 'GET_STAGING_LIST'.
          CLEAR: lt_hdr_db, lt_list.

          SELECT * FROM zmdg_stg_hdr
            INTO TABLE @lt_hdr_db
            WHERE status IN ('CHECKED', 'CODED', 'SUBMITTED')
            ORDER BY req_date DESCENDING, req_time DESCENDING.

          LOOP AT lt_hdr_db INTO ls_hdr_db.
            CLEAR ls_list.
            ls_list-req_no     = ls_hdr_db-req_no.
            ls_list-remarks    = ls_hdr_db-remarks.
            ls_list-sub_reason = ls_hdr_db-sub_reason.
            ls_list-req_date   = ls_hdr_db-req_date.
            ls_list-req_time   = ls_hdr_db-req_time.
            ls_list-requestor  = ls_hdr_db-requestor.
            ls_list-status     = ls_hdr_db-status.
            ls_list-rej_reason = ls_hdr_db-rej_reason.

            SELECT COUNT( * ) FROM zmdg_stg_part INTO @ls_list-total_item WHERE req_no = @ls_hdr_db-req_no.

            APPEND ls_list TO lt_list.
          ENDLOOP.

          " Populate requestor_name with First Name + Last Name via BAPI_USER_GET_DETAIL / USR21+ADRP
          TYPES: BEGIN OF ty_user_map,
                   uname    TYPE sy-uname,
                   fullname TYPE string,
                 END OF ty_user_map.
          DATA: lt_user_map  TYPE HASHED TABLE OF ty_user_map WITH UNIQUE KEY uname,
                ls_user_map  TYPE ty_user_map,
                ls_bapi_addr TYPE bapiaddr3,
                lt_bapi_ret  TYPE TABLE OF bapiret2,
                lv_persnum   TYPE usr21-persnumber,
                lv_fname     TYPE adrp-name_first,
                lv_lname     TYPE adrp-name_last,
                lv_uname_tmp TYPE bapibname-bapibname.

          LOOP AT lt_list ASSIGNING FIELD-SYMBOL(<fs_list>).
            IF <fs_list>-requestor IS NOT INITIAL.
              READ TABLE lt_user_map INTO ls_user_map WITH KEY uname = <fs_list>-requestor.
              IF sy-subrc <> 0.
                CLEAR: ls_user_map, ls_bapi_addr, lt_bapi_ret.
                ls_user_map-uname = <fs_list>-requestor.
                lv_uname_tmp = CONV #( <fs_list>-requestor ).
                CALL FUNCTION 'BAPI_USER_GET_DETAIL'
                  EXPORTING
                    username = lv_uname_tmp
                  IMPORTING
                    address  = ls_bapi_addr
                  TABLES
                    return   = lt_bapi_ret.
                IF ls_bapi_addr-firstname IS NOT INITIAL OR ls_bapi_addr-lastname IS NOT INITIAL.
                  CONCATENATE ls_bapi_addr-firstname ls_bapi_addr-lastname INTO ls_user_map-fullname SEPARATED BY space.
                ELSEIF ls_bapi_addr-fullname IS NOT INITIAL.
                  ls_user_map-fullname = ls_bapi_addr-fullname.
                ELSE.
                  SELECT SINGLE persnumber FROM usr21 INTO lv_persnum WHERE bname = <fs_list>-requestor.
                  IF sy-subrc = 0.
                    SELECT SINGLE name_first name_last FROM adrp INTO (lv_fname, lv_lname) WHERE persnumber = lv_persnum.
                    IF lv_fname IS NOT INITIAL OR lv_lname IS NOT INITIAL.
                      CONCATENATE lv_fname lv_lname INTO ls_user_map-fullname SEPARATED BY space.
                    ENDIF.
                  ENDIF.
                ENDIF.
                IF ls_user_map-fullname IS INITIAL.
                  ls_user_map-fullname = <fs_list>-requestor.
                ENDIF.
                INSERT ls_user_map INTO TABLE lt_user_map.
              ENDIF.
              <fs_list>-requestor_name = ls_user_map-fullname.
            ENDIF.
          ENDLOOP.

          lv_json = /ui2/cl_json=>serialize( data = lt_list compress = 'X' pretty_name = /ui2/cl_json=>pretty_mode-low_case ).

          _m_response->set_content_type( 'application/json' ).
          _m_response->set_cdata( lv_json ).
          _m_navigation->response_complete( ).
          RETURN.

        " ------------------------------------------------------------------
        " 2. FETCH BATCH UPLOAD DETAIL
        " ------------------------------------------------------------------
        WHEN 'GET_UPLOAD_DETAIL'.
          lv_req_no = request->get_form_field( 'REQ_NO' ).
          IF lv_req_no IS INITIAL.
            lv_req_no = request->get_form_field( 'UPLOAD_ID' ).
          ENDIF.
          CLEAR: lt_dtl_db.

          SELECT * FROM zmdg_stg_part
            INTO TABLE @lt_dtl_db
            WHERE req_no = @lv_req_no
            ORDER BY item_no ASCENDING.

          TYPES: BEGIN OF ty_att_json,
                   att_no      TYPE i,
                   file_name   TYPE string,
                   file_type   TYPE string,
                   file_size   TYPE i,
                   description TYPE string,
                   file_base64 TYPE string,
                 END OF ty_att_json.
          DATA: lt_att_db   TYPE TABLE OF zmdg_req_att,
                ls_att_db   TYPE zmdg_req_att,
                lt_att_json TYPE TABLE OF ty_att_json,
                ls_att_json TYPE ty_att_json.

          CLEAR: lt_att_db, lt_att_json.
          SELECT * FROM zmdg_req_att
            INTO TABLE @lt_att_db
            WHERE req_no = @lv_req_no
            ORDER BY att_no ASCENDING.

          LOOP AT lt_att_db INTO ls_att_db.
            CLEAR ls_att_json.
            ls_att_json-att_no      = ls_att_db-att_no.
            ls_att_json-file_name   = ls_att_db-file_name.
            ls_att_json-file_type   = ls_att_db-file_type.
            ls_att_json-file_size   = ls_att_db-file_size.
            ls_att_json-description = ls_att_db-description.
            IF ls_att_db-file_data IS NOT INITIAL.
              TRY.
                  ls_att_json-file_base64 = cl_http_utility=>encode_x_base64( unencoded = ls_att_db-file_data ).
                CATCH cx_root.
                  CLEAR ls_att_json-file_base64.
              ENDTRY.
            ENDIF.
            APPEND ls_att_json TO lt_att_json.
          ENDLOOP.

          TYPES: BEGIN OF ty_upload_detail_resp,
                   items       TYPE TABLE OF zmdg_stg_part WITH DEFAULT KEY,
                   attachments TYPE TABLE OF ty_att_json WITH DEFAULT KEY,
                 END OF ty_upload_detail_resp.
          DATA: ls_upload_detail_resp TYPE ty_upload_detail_resp.
          ls_upload_detail_resp-items       = lt_dtl_db.
          ls_upload_detail_resp-attachments = lt_att_json.

          lv_json = /ui2/cl_json=>serialize( data = ls_upload_detail_resp compress = 'X' pretty_name = /ui2/cl_json=>pretty_mode-low_case ).

          _m_response->set_content_type( 'application/json' ).
          _m_response->set_cdata( lv_json ).
          _m_navigation->response_complete( ).
          RETURN.

        " ------------------------------------------------------------------
        " 3. QUICK / BULK APPROVE (GENERATE -> VALIDATE -> CREATE SAP)
        " ------------------------------------------------------------------
        WHEN 'QUICK_APPROVE' OR 'BULK_APPROVE'.
          lv_req_nos = request->get_form_field( 'REQ_NOS' ).
          IF lv_req_nos IS INITIAL.
            lv_req_nos = request->get_form_field( 'REQ_NO' ).
          ENDIF.

          SPLIT lv_req_nos AT ',' INTO TABLE lt_req_split.
          lv_has_error   = abap_false.
          lv_success_cnt = 0.
          lv_fail_cnt    = 0.
          CLEAR lv_last_err.

          LOOP AT lt_req_split INTO lv_req_item.
            CONDENSE lv_req_item.
            CHECK lv_req_item IS NOT INITIAL.

            CLEAR lv_curr_stat.
            SELECT SINGLE status FROM zmdg_stg_hdr INTO @lv_curr_stat WHERE req_no = @lv_req_item.
            IF sy-subrc = 0 AND ( lv_curr_stat = 'APPROVED' OR lv_curr_stat = 'REJECTED' ).
              CONTINUE.
            ENDIF.

            UPDATE zmdg_stg_hdr
              SET status   = 'VALIDATING',
                  approver = @sy-uname,
                  app_date = @sy-datum,
                  app_time = @sy-uzeit
              WHERE req_no = @lv_req_item.

            SELECT * FROM zmdg_stg_part
              INTO TABLE @lt_dtl_db
              WHERE req_no = @lv_req_item
              ORDER BY item_no ASCENDING.

            IF lt_dtl_db IS INITIAL.
              lv_has_error = abap_true.
              lv_last_err  = 'Tidak ada data item untuk Request ' && lv_req_item.
              UPDATE zmdg_stg_hdr
                SET status     = 'FAILED',
                    rej_reason = @lv_last_err
                WHERE req_no   = @lv_req_item.
              CONTINUE.
            ENDIF.

            CLEAR lv_err_msg.
            CLEAR lt_used_matnr.

            " LOOP UNTUK EDIT/VALIDASI SETIAP ITEM IN BATCH
            LOOP AT lt_dtl_db INTO ls_dtl_db.

              " Clean up & normalize Material Type per item (remove spaces & uppercase)
              IF ls_dtl_db-mtart IS NOT INITIAL.
                CONDENSE ls_dtl_db-mtart NO-GAPS.
                TRANSLATE ls_dtl_db-mtart TO UPPER CASE.
                " Fix common typo: digit '0' vs letter 'O' for ZOS material types
                IF ls_dtl_db-mtart = 'Z0S1'. ls_dtl_db-mtart = 'ZOS1'. ENDIF.
                IF ls_dtl_db-mtart = 'Z0S2'. ls_dtl_db-mtart = 'ZOS2'. ENDIF.
                IF ls_dtl_db-mtart = 'Z0S3'. ls_dtl_db-mtart = 'ZOS3'. ENDIF.
              ELSE.
                ls_dtl_db-mtart = 'HALB'.
              ENDIF.

              IF ls_dtl_db-mbrsh IS INITIAL.
                ls_dtl_db-mbrsh = 'F'.
              ENDIF.

              " B. VALIDASI MANDATORY FIELDS PER ITEM
              IF ls_dtl_db-mbrsh IS INITIAL OR ls_dtl_db-mtart IS INITIAL.
                lv_err_msg = 'Industry Sector dan Material Type wajib diisi (Item ' && ls_dtl_db-item_no && ')'.
                EXIT.
              ENDIF.

              IF ls_dtl_db-matkl IS INITIAL.
                lv_err_msg = 'Material Group wajib diisi (Item ' && ls_dtl_db-item_no && ')'.
                EXIT.
              ENDIF.

              IF ls_dtl_db-werks IS INITIAL.
                lv_err_msg = 'Plant wajib diisi (Item ' && ls_dtl_db-item_no && ')'.
                EXIT.
              ENDIF.

              IF ls_dtl_db-lgort IS INITIAL.
                lv_err_msg = 'Storage Location wajib diisi (Item ' && ls_dtl_db-item_no && ')'.
                EXIT.
              ENDIF.

              IF ls_dtl_db-prctr IS INITIAL.
                ls_dtl_db-prctr = '200201'.
              ENDIF.

                  " A. GENERATE KODE MATERIAL AUTOMATIC PER ITEM BERDASARKAN MTART SEBAGAI NUMBER RANGE
              CLEAR: lv_exist_mara, lv_exist_mtart, lv_check_matnr, lv_alpha_matnr, lv_in_batch.
              IF ls_dtl_db-matnr_ext IS NOT INITIAL.
                CONDENSE ls_dtl_db-matnr_ext NO-GAPS.
                CALL FUNCTION 'CONVERSION_EXIT_MATN1_INPUT'
                  EXPORTING
                    input        = ls_dtl_db-matnr_ext
                  IMPORTING
                    output       = lv_check_matnr
                  EXCEPTIONS
                    OTHERS       = 1.
                IF lv_check_matnr IS INITIAL.
                  lv_check_matnr = ls_dtl_db-matnr_ext.
                ENDIF.

                lv_alpha_matnr = |{ ls_dtl_db-matnr_ext ALPHA = IN }|.

                SELECT SINGLE matnr, mtart FROM mara INTO (@lv_exist_mara, @lv_exist_mtart)
                  WHERE matnr = @lv_alpha_matnr OR matnr = @lv_check_matnr OR matnr = @ls_dtl_db-matnr_ext.

                READ TABLE lt_used_matnr WITH KEY table_line = ls_dtl_db-matnr_ext TRANSPORTING NO FIELDS.
                IF sy-subrc = 0.
                  lv_in_batch = 'X'.
                ELSEIF lv_check_matnr IS NOT INITIAL.
                  READ TABLE lt_used_matnr WITH KEY table_line = lv_check_matnr TRANSPORTING NO FIELDS.
                  IF sy-subrc = 0.
                    lv_in_batch = 'X'.
                  ELSEIF lv_alpha_matnr IS NOT INITIAL.
                    READ TABLE lt_used_matnr WITH KEY table_line = lv_alpha_matnr TRANSPORTING NO FIELDS.
                    IF sy-subrc = 0.
                      lv_in_batch = 'X'.
                    ENDIF.
                  ENDIF.
                ENDIF.
              ENDIF.

              IF ls_dtl_db-matnr_ext IS INITIAL OR lv_exist_mara IS NOT INITIAL OR lv_in_batch = 'X'.
                " Jika nomor belum ada ATAU nomor lama sudah terdaftar di MARA/batch, generate nomor baru per MTART item
                CLEAR: lv_is_available, lv_next_number, lt_check_return.

                CALL FUNCTION 'ZFM_CHECK_MATERIAL'
                  EXPORTING
                    iv_mtart        = ls_dtl_db-mtart
                  IMPORTING
                    ev_is_available = lv_is_available
                    ev_next_number  = lv_next_number
                    et_return       = lt_check_return
                  EXCEPTIONS
                    OTHERS          = 1.

                " Fallback: Jika iv_mtart tidak mengembalikan nomor (misal SAP pake Z0S1 tapi di-call ZOS1, atau sebaliknya)
                IF ( lv_is_available IS INITIAL OR lv_next_number IS INITIAL ) AND ls_dtl_db-mtart CS 'Z'.
                  DATA: lv_alt_mtart TYPE string.
                  CLEAR lv_alt_mtart.
                  IF ls_dtl_db-mtart = 'ZOS1'. lv_alt_mtart = 'Z0S1'.
                  ELSEIF ls_dtl_db-mtart = 'Z0S1'. lv_alt_mtart = 'ZOS1'.
                  ELSEIF ls_dtl_db-mtart = 'ZOS2'. lv_alt_mtart = 'Z0S2'.
                  ELSEIF ls_dtl_db-mtart = 'Z0S2'. lv_alt_mtart = 'ZOS2'.
                  ELSEIF ls_dtl_db-mtart = 'ZOS3'. lv_alt_mtart = 'Z0S3'.
                  ELSEIF ls_dtl_db-mtart = 'Z0S3'. lv_alt_mtart = 'ZOS3'.
                  ENDIF.
                  IF lv_alt_mtart IS NOT INITIAL AND lv_alt_mtart <> ls_dtl_db-mtart.
                    CLEAR: lv_is_available, lv_next_number, lt_check_return.
                    CALL FUNCTION 'ZFM_CHECK_MATERIAL'
                      EXPORTING
                        iv_mtart        = lv_alt_mtart
                      IMPORTING
                        ev_is_available = lv_is_available
                        ev_next_number  = lv_next_number
                        et_return       = lt_check_return
                      EXCEPTIONS
                        OTHERS          = 1.
                    IF lv_is_available = 'X' AND lv_next_number IS NOT INITIAL.
                      ls_dtl_db-mtart = lv_alt_mtart.
                    ENDIF.
                  ENDIF.
                ENDIF.

                IF lv_is_available = 'X' AND lv_next_number IS NOT INITIAL.
                  lv_cand_matnr = lv_next_number.
                  CONDENSE lv_cand_matnr NO-GAPS.

                  " Safety check: Pastikan lv_cand_matnr belum dipakai di MARA maupun lt_used_matnr (untuk batch multi-item dengan MTART sama)
                  DO 1000 TIMES.
                    CLEAR: lv_exist_mara, lv_exist_mtart, lv_check_matnr, lv_alpha_matnr, lv_in_batch.
                    CONDENSE lv_cand_matnr NO-GAPS.

                    lv_alpha_matnr = |{ lv_cand_matnr ALPHA = IN }|.

                    CALL FUNCTION 'CONVERSION_EXIT_MATN1_INPUT'
                      EXPORTING
                        input        = lv_cand_matnr
                      IMPORTING
                        output       = lv_check_matnr
                      EXCEPTIONS
                        OTHERS       = 1.
                    IF lv_check_matnr IS INITIAL.
                      lv_check_matnr = lv_cand_matnr.
                    ENDIF.

                    SELECT SINGLE matnr, mtart FROM mara INTO (@lv_exist_mara, @lv_exist_mtart)
                      WHERE matnr = @lv_alpha_matnr OR matnr = @lv_check_matnr OR matnr = @lv_cand_matnr.

                    READ TABLE lt_used_matnr WITH KEY table_line = lv_cand_matnr TRANSPORTING NO FIELDS.
                    IF sy-subrc = 0.
                      lv_in_batch = 'X'.
                    ELSEIF lv_check_matnr IS NOT INITIAL.
                      READ TABLE lt_used_matnr WITH KEY table_line = lv_check_matnr TRANSPORTING NO FIELDS.
                      IF sy-subrc = 0.
                        lv_in_batch = 'X'.
                      ELSEIF lv_alpha_matnr IS NOT INITIAL.
                        READ TABLE lt_used_matnr WITH KEY table_line = lv_alpha_matnr TRANSPORTING NO FIELDS.
                        IF sy-subrc = 0.
                          lv_in_batch = 'X'.
                        ENDIF.
                      ENDIF.
                    ENDIF.

                    IF lv_in_batch IS INITIAL AND lv_exist_mara IS INITIAL.
                      " Nomor bebas & unik
                      EXIT.
                    ELSE.
                      " Increment +1 per iterasi secara sekuensial (Aman & terurut di SAP)
                      CONDENSE lv_cand_matnr NO-GAPS.
                      IF lv_cand_matnr CO '0123456789'.
                        CLEAR: lv_num_tmp, lv_num_int.
                        lv_num_int = lv_cand_matnr + 1.
                        lv_num_tmp = |{ lv_num_int }|.
                        CONDENSE lv_num_tmp NO-GAPS.
                        lv_cand_matnr = lv_num_tmp.
                      ELSE.
                        EXIT.
                      ENDIF.
                    ENDIF.
                  ENDDO.

                  ls_dtl_db-matnr_ext = lv_cand_matnr.
                  CLEAR lv_check_matnr.
                  CALL FUNCTION 'CONVERSION_EXIT_MATN1_INPUT'
                    EXPORTING
                      input        = ls_dtl_db-matnr_ext
                    IMPORTING
                      output       = lv_check_matnr
                    EXCEPTIONS
                      OTHERS       = 1.
                  APPEND ls_dtl_db-matnr_ext TO lt_used_matnr.
                  IF lv_check_matnr IS NOT INITIAL AND lv_check_matnr <> ls_dtl_db-matnr_ext.
                    APPEND lv_check_matnr TO lt_used_matnr.
                  ENDIF.
                  DATA: lv_alpha_tmp TYPE string.
                  lv_alpha_tmp = |{ ls_dtl_db-matnr_ext ALPHA = IN }|.
                  IF lv_alpha_tmp IS NOT INITIAL AND lv_alpha_tmp <> ls_dtl_db-matnr_ext.
                    APPEND lv_alpha_tmp TO lt_used_matnr.
                  ENDIF.

                  " Update nomor baru ke tabel staging detail
                  UPDATE zmdg_stg_part
                    SET matnr_ext = @ls_dtl_db-matnr_ext
                    WHERE req_no  = @ls_dtl_db-req_no
                      AND item_no = @ls_dtl_db-item_no.
                ELSE.
                  READ TABLE lt_check_return INTO ls_check_return WITH KEY type = 'E'.
                  IF sy-subrc = 0 AND ls_check_return-message IS NOT INITIAL.
                    lv_err_msg = |Item { ls_dtl_db-item_no }: Auto-gen gagal - { ls_check_return-message }|.
                  ELSE.
                    lv_err_msg = |Item { ls_dtl_db-item_no }: Auto-gen gagal - Gagal mengambil Number Range otomatis untuk Material Type { ls_dtl_db-mtart }.|.
                  ENDIF.
                  EXIT.
                ENDIF.
              ELSE.
                APPEND ls_dtl_db-matnr_ext TO lt_used_matnr.
                DATA: lv_alpha_tmp2 TYPE string.
                lv_alpha_tmp2 = |{ ls_dtl_db-matnr_ext ALPHA = IN }|.
                IF lv_alpha_tmp2 IS NOT INITIAL AND lv_alpha_tmp2 <> ls_dtl_db-matnr_ext.
                  APPEND lv_alpha_tmp2 TO lt_used_matnr.
                ENDIF.
              ENDIF.

              " Format VTWEG (Distribution Channel): Ensure 2 characters (e.g. '1' -> '01')
              IF ls_dtl_db-vtweg IS NOT INITIAL.
                CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
                  EXPORTING
                    input  = ls_dtl_db-vtweg
                  IMPORTING
                    output = ls_dtl_db-vtweg.
              ENDIF.

              " Clear invalid Variance Key ('X' is NOT a valid variance key in SAP)
              IF ls_dtl_db-klrab = 'X' OR ls_dtl_db-klrab = 'x'.
                CLEAR ls_dtl_db-klrab.
              ENDIF.

              " C. VERIFIKASI AKHIR DUPLIKASI KODE DI TABEL MARA BERDASARKAN KODE DAN MATERIAL TYPE
              CLEAR: lv_exist_mara, lv_exist_mtart, lv_check_matnr, lv_alpha_matnr.
              CALL FUNCTION 'CONVERSION_EXIT_MATN1_INPUT'
                EXPORTING
                  input        = ls_dtl_db-matnr_ext
                IMPORTING
                  output       = lv_check_matnr
                EXCEPTIONS
                  OTHERS       = 1.
              IF lv_check_matnr IS INITIAL.
                lv_check_matnr = ls_dtl_db-matnr_ext.
              ENDIF.

              lv_alpha_matnr = |{ ls_dtl_db-matnr_ext ALPHA = IN }|.

              SELECT SINGLE matnr, mtart FROM mara INTO (@lv_exist_mara, @lv_exist_mtart)
                WHERE matnr = @lv_alpha_matnr OR matnr = @lv_check_matnr OR matnr = @ls_dtl_db-matnr_ext.

              IF lv_exist_mara IS NOT INITIAL.
                lv_err_msg = |Kode Material { ls_dtl_db-matnr_ext } sudah terdaftar di MARA SAP (Material Type MARA: { lv_exist_mtart }, Input: { ls_dtl_db-mtart }) (Item { ls_dtl_db-item_no })|.
                EXIT.
              ENDIF.

              " D. DEFAULT FALLBACK VALUES FOR SAP MANDATORY & STANDARD FIELDS (25 FIELDS)
              IF ls_dtl_db-periv IS INITIAL. ls_dtl_db-periv = 'C1'. ENDIF.
              IF ls_dtl_db-mtvfp IS INITIAL. ls_dtl_db-mtvfp = 'KP'. ENDIF.
              IF ls_dtl_db-xchpf IS INITIAL. ls_dtl_db-xchpf = 'X'. ENDIF.
              IF ls_dtl_db-hkmat IS INITIAL. ls_dtl_db-hkmat = 'X'. ENDIF.
              IF ls_dtl_db-spart IS INITIAL. ls_dtl_db-spart = 'M6'. ENDIF.
              IF ls_dtl_db-mtpos_mara IS INITIAL OR ls_dtl_db-mtpos_mara = 'NOR'. ls_dtl_db-mtpos_mara = 'NORM'. ENDIF.
              IF ls_dtl_db-herkl IS INITIAL. ls_dtl_db-herkl = 'ID'. ENDIF.
              IF ls_dtl_db-taxkm IS INITIAL. ls_dtl_db-taxkm = '1'. ENDIF.
              IF ls_dtl_db-tatyp IS INITIAL. ls_dtl_db-tatyp = 'MWST'. ENDIF.
              IF ls_dtl_db-mtpos IS INITIAL OR ls_dtl_db-mtpos = 'NOR'. ls_dtl_db-mtpos = 'NORM'. ENDIF.
              IF ls_dtl_db-tragr IS INITIAL. ls_dtl_db-tragr = '0001'. ENDIF.
              IF ls_dtl_db-ladgr IS INITIAL. ls_dtl_db-ladgr = '0001'. ENDIF.
              IF ls_dtl_db-bklas IS INITIAL. ls_dtl_db-bklas = 'RW02'. ENDIF.
              IF ls_dtl_db-vprsv IS INITIAL. ls_dtl_db-vprsv = 'S'. ENDIF.
              IF ls_dtl_db-ekgrp IS INITIAL. ls_dtl_db-ekgrp = 'K02'. ENDIF.
              IF ls_dtl_db-dismm IS INITIAL. ls_dtl_db-dismm = 'PD'. ENDIF.
              IF ls_dtl_db-beskz IS INITIAL. ls_dtl_db-beskz = 'F'. ENDIF.
              IF ls_dtl_db-rgekz IS INITIAL. ls_dtl_db-rgekz = '1'. ENDIF.
              IF ls_dtl_db-fhori IS INITIAL. ls_dtl_db-fhori = '0'. ENDIF.
              IF ls_dtl_db-perkz IS INITIAL. ls_dtl_db-perkz = 'M'. ENDIF.
              IF ls_dtl_db-bstrf IS INITIAL. ls_dtl_db-bstrf = '100.000'. ENDIF.
              IF ls_dtl_db-disls IS INITIAL. ls_dtl_db-disls = 'EX'. ENDIF.
              IF ls_dtl_db-vtweg IS INITIAL. ls_dtl_db-vtweg = '10'. ENDIF.
              IF ls_dtl_db-ktgrm IS INITIAL. ls_dtl_db-ktgrm = 'M6'. ENDIF.
              IF ls_dtl_db-prctr IS INITIAL. ls_dtl_db-prctr = '200301'. ENDIF.
              IF ls_dtl_db-disgr IS INITIAL. ls_dtl_db-disgr = 'ZWH4'. ENDIF.
              IF ls_dtl_db-dispo IS INITIAL. ls_dtl_db-dispo = 'RW7'. ENDIF.
              IF ls_dtl_db-qssys IS INITIAL. ls_dtl_db-qssys = '04'. ENDIF.
              IF ls_dtl_db-qssys IS INITIAL. ls_dtl_db-qssys = '04'. ENDIF.
              IF ls_dtl_db-insptype IS INITIAL. ls_dtl_db-insptype = 'X'. ENDIF.

              " D. MAPPING BAPI PARAMETERS
              CLEAR: ls_headdata, ls_clientdata, ls_clientdatax,
                    ls_plantdata, ls_plantdatax,
                    ls_storagelocationdata, ls_storagelocationdatax,
                    ls_valuationdata, ls_valuationdatax,
                    ls_salesdata, ls_salesdatax,
                    ls_warehousenumberdata, ls_warehousenumberdatax,
                    ls_storagetypedata, ls_storagetypedatax,
                    ls_bapireturn, lt_materialdesc, lt_unitsofmeasure,
                    lt_unitsofmeasurex, lt_taxclassifications, lt_returnmes.

              CALL FUNCTION 'CONVERSION_EXIT_MATN1_INPUT'
                EXPORTING
                  input        = ls_dtl_db-matnr_ext
                IMPORTING
                  output       = ls_headdata-material
                EXCEPTIONS
                  OTHERS       = 1.

              IF ls_headdata-material IS INITIAL.
                ls_headdata-material = ls_dtl_db-matnr_ext.
              ENDIF.
              ls_headdata-material_long = ls_headdata-material.

              " Fallback default values jika data staging kosong
              IF ls_dtl_db-mbrsh IS INITIAL. ls_dtl_db-mbrsh = 'F'. ENDIF.
              IF ls_dtl_db-mtart IS INITIAL. ls_dtl_db-mtart = 'HALB'. ENDIF.
              IF ls_dtl_db-matkl IS INITIAL. ls_dtl_db-matkl = 'ESP018'. ENDIF.
              IF ls_dtl_db-vkorg IS INITIAL. ls_dtl_db-vkorg = '1000'. ENDIF.
              IF ls_dtl_db-vtweg IS INITIAL. ls_dtl_db-vtweg = '10'. ENDIF.
              IF ls_dtl_db-spart IS INITIAL. ls_dtl_db-spart = 'M6'. ENDIF.
              IF ls_dtl_db-werks IS INITIAL. ls_dtl_db-werks = '1000'. ENDIF.
              IF ls_dtl_db-lgort IS INITIAL. ls_dtl_db-lgort = '1000'. ENDIF.
              IF ls_dtl_db-bklas IS INITIAL. ls_dtl_db-bklas = 'SF01'. ENDIF.
              IF ls_dtl_db-vprsv IS INITIAL. ls_dtl_db-vprsv = 'V'. ENDIF.

              ls_headdata-ind_sector      = ls_dtl_db-mbrsh.
              ls_headdata-matl_type       = ls_dtl_db-mtart.

              " Base Unit of Measure (MARA-MEINS / BAPI_MARA-BASE_UOM)
              IF ls_dtl_db-meins IS INITIAL.
                ls_dtl_db-meins = 'M3'.
              ENDIF.

              CLEAR: ls_clientdata-base_uom, ls_clientdata-base_uom_iso, lv_uom_iso.

              CALL FUNCTION 'CONVERSION_EXIT_CUNIT_INPUT'
                EXPORTING
                  input          = ls_dtl_db-meins
                IMPORTING
                  output         = ls_clientdata-base_uom
                EXCEPTIONS
                  OTHERS         = 1.

              IF ls_clientdata-base_uom IS INITIAL.
                ls_clientdata-base_uom = ls_dtl_db-meins.
              ENDIF.
              ls_clientdatax-base_uom = 'X'.

              SELECT SINGLE isocode FROM t006 INTO lv_uom_iso
                WHERE msehi = ls_clientdata-base_uom.

              IF lv_uom_iso IS NOT INITIAL.
                ls_clientdata-base_uom_iso  = lv_uom_iso.
                ls_clientdatax-base_uom_iso = 'X'.
              ELSE.
                CLEAR: ls_clientdata-base_uom_iso, ls_clientdatax-base_uom_iso.
              ENDIF.

              " Aktifkan Material Master Views
              ls_headdata-basic_view      = 'X'. " Basic Data 1 & 2
              ls_headdata-purchase_view   = 'X'. " Purchasing, Import, PO Text

              IF ls_dtl_db-sfpro IS NOT INITIAL OR ls_dtl_db-beskz = 'E'.
                ls_headdata-work_sched_view = 'X'. " Advanced Planning / Work Sched
              ENDIF.

              IF ls_dtl_db-vkorg IS NOT INITIAL AND ls_dtl_db-vtweg IS NOT INITIAL.
                ls_headdata-sales_view   = 'X'.
              ENDIF.

              IF ls_dtl_db-werks IS NOT INITIAL.
                ls_headdata-storage_view   = 'X'.
                ls_headdata-account_view   = 'X'.
                ls_headdata-cost_view      = 'X'.
                ls_headdata-mrp_view       = 'X'.
                ls_headdata-warehouse_view = 'X'.

                IF ls_dtl_db-lgnum IS NOT INITIAL.
                  ls_warehousenumberdata-whse_no = ls_dtl_db-lgnum.
                ELSE.
                  ls_warehousenumberdata-whse_no = '100'.
                ENDIF.
                ls_warehousenumberdatax-whse_no   = ls_warehousenumberdata-whse_no.
                CLEAR: ls_warehousenumberdata-ref_unit, ls_warehousenumberdatax-ref_unit.

                ls_storagetypedata-whse_no        = ls_warehousenumberdata-whse_no.
                ls_storagetypedata-stge_type      = '001'.
                ls_storagetypedatax-whse_no       = ls_warehousenumberdata-whse_no.
                ls_storagetypedatax-stge_type      = '001'.
              ENDIF.

              IF ls_dtl_db-insptype IS NOT INITIAL OR ls_dtl_db-qssys IS NOT INITIAL.
                ls_headdata-quality_view = 'X'.
              ENDIF.

              " Mapping Quality Management (MARC-INSMK & Control Key SSQSS / Plant Level)
              ls_plantdata-ind_post_to_insp_stock  = 'X'.
              ls_plantdatax-ind_post_to_insp_stock = 'X'.

              " Mapping Country of Origin (HERKL) untuk Plant View
              IF ls_dtl_db-herkl IS NOT INITIAL.
                ls_plantdata-countryori      = ls_dtl_db-herkl.
                ls_plantdata-countryori_iso  = ls_dtl_db-herkl.
                ls_plantdatax-countryori     = 'X'.
                ls_plantdatax-countryori_iso = 'X'.
              ENDIF.

              " Sales View & Tax Classifications Data
              ls_salesdata-sales_org   = ls_dtl_db-vkorg.
              ls_salesdatax-sales_org  = ls_dtl_db-vkorg.
              ls_salesdata-distr_chan  = ls_dtl_db-vtweg.
              ls_salesdatax-distr_chan = ls_dtl_db-vtweg.

              IF ls_dtl_db-mtpos IS NOT INITIAL.
                ls_salesdata-item_cat  = ls_dtl_db-mtpos.
              ELSE.
                ls_salesdata-item_cat  = 'NORM'.
              ENDIF.
              ls_salesdatax-item_cat   = 'X'.

              " Mapping Tax Classifications (Mandatory untuk SAP Sales View)
              CLEAR: lt_taxclassifications, ls_taxclassification, lv_valid_tatyp.

              IF ls_dtl_db-tatyp IS NOT INITIAL.
                SELECT SINGLE tatyp FROM tstl INTO lv_valid_tatyp
                  WHERE talnd = 'ID' AND tatyp = ls_dtl_db-tatyp.
              ENDIF.

              IF lv_valid_tatyp IS INITIAL.
                SELECT SINGLE tatyp FROM tstl INTO lv_valid_tatyp
                  WHERE talnd = 'ID'.
              ENDIF.

              IF lv_valid_tatyp IS INITIAL.
                lv_valid_tatyp = 'ZPPN'.
              ENDIF.

              IF lv_valid_tatyp IS NOT INITIAL.
                ls_taxclassification-depcountry     = 'ID'.
                ls_taxclassification-depcountry_iso = 'ID'.
                ls_taxclassification-tax_type_1     = lv_valid_tatyp.

                IF ls_dtl_db-taxkm IS NOT INITIAL.
                  ls_taxclassification-taxclass_1 = ls_dtl_db-taxkm.
                ELSE.
                  ls_taxclassification-taxclass_1 = '1'.
                ENDIF.

                APPEND ls_taxclassification TO lt_taxclassifications.
              ENDIF.

              IF ls_dtl_db-matkl IS NOT INITIAL.
                ls_clientdata-matl_group  = ls_dtl_db-matkl.
                ls_clientdatax-matl_group = 'X'.
              ENDIF.

              IF ls_dtl_db-mtpos_mara IS NOT INITIAL.
                ls_clientdata-item_cat  = ls_dtl_db-mtpos_mara.
              ELSE.
                ls_clientdata-item_cat  = 'NORM'.
              ENDIF.
              ls_clientdatax-item_cat   = 'X'.

              " Division (SPART)
              IF ls_dtl_db-spart IS NOT INITIAL.
                ls_clientdata-division  = ls_dtl_db-spart.
                ls_clientdatax-division = 'X'.
              ENDIF.

              " Size/dimension (MARA-GROES)
              IF ls_dtl_db-groes IS NOT INITIAL.
                ls_clientdata-size_dim  = ls_dtl_db-groes.
                ls_clientdatax-size_dim = 'X'.
              ENDIF.

              " Batch Management (MARA-XCHPF / MARC-XCHPF)
              IF ls_dtl_db-xchpf IS NOT INITIAL.
                ls_clientdata-batch_mgmt  = ls_dtl_db-xchpf.
                ls_clientdatax-batch_mgmt = 'X'.
                ls_plantdata-batch_mgmt   = ls_dtl_db-xchpf.
                ls_plantdatax-batch_mgmt  = 'X'.
              ENDIF.

              " Prod./insp. memo (FERTH)
              IF ls_dtl_db-ferth IS NOT INITIAL.
                ls_clientdata-basic_matl  = ls_dtl_db-ferth.
                ls_clientdatax-basic_matl = 'X'.
              ENDIF.

              " Material Package (MAGRV)
              IF ls_dtl_db-magrv IS NOT INITIAL AND ls_dtl_db-magrv <> '0001' AND ls_dtl_db-magrv <> '1'.
                ls_clientdata-mat_grp_sm  = ls_dtl_db-magrv.
                ls_clientdatax-mat_grp_sm = 'X'.
              ENDIF.

              CLEAR ls_materialdesc.
              ls_materialdesc-langu     = sy-langu.
              ls_materialdesc-matl_desc = ls_dtl_db-maktx.
              APPEND ls_materialdesc TO lt_materialdesc.

              ls_plantdata-plant     = ls_dtl_db-werks.
              ls_plantdatax-plant    = ls_dtl_db-werks.


              " 1. MRP Type (MARC-DISMM) - Mandatory in SAP Plant View
              IF ls_dtl_db-dismm IS NOT INITIAL.
                ls_plantdata-mrp_type  = ls_dtl_db-dismm.
              ELSE.
                ls_plantdata-mrp_type  = 'PD'.
              ENDIF.
              ls_plantdatax-mrp_type = 'X'.

              " 2. Availability Check (MARC-MTVFP) - Mandatory in SAP Plant View
              IF ls_dtl_db-mtvfp IS NOT INITIAL.
                ls_plantdata-availcheck  = ls_dtl_db-mtvfp.
              ELSE.
                ls_plantdata-availcheck  = 'KP'.
              ENDIF.
              ls_plantdatax-availcheck = 'X'.

              " 3. Purchasing Group (MARC-EKGRP)
              IF ls_dtl_db-ekgrp IS NOT INITIAL.
                ls_plantdata-pur_group  = ls_dtl_db-ekgrp.
              ELSE.
                ls_plantdata-pur_group  = 'K01'.
              ENDIF.
              ls_plantdatax-pur_group = 'X'.

              " 4. MRP Controller (MARC-DISPO)
              IF ls_dtl_db-dispo IS NOT INITIAL.
                ls_plantdata-mrp_ctrler  = ls_dtl_db-dispo.
              ELSE.
                ls_plantdata-mrp_ctrler  = 'RW8'.
              ENDIF.
              ls_plantdatax-mrp_ctrler = 'X'.

              " 5. MRP Group (MARC-DISGR)
              IF ls_dtl_db-disgr IS NOT INITIAL.
                ls_plantdata-mrp_group  = ls_dtl_db-disgr.
                ls_plantdatax-mrp_group = 'X'.
              ENDIF.

              " 6. Lot Size (MARC-DISLS) - Default 'EX' (Lot-for-lot) to avoid PERIV requirement
              IF ls_dtl_db-disls IS NOT INITIAL AND ls_dtl_db-disls <> 'PB' AND ls_dtl_db-disls <> 'MB'.
                ls_plantdata-lotsizekey  = ls_dtl_db-disls.
              ELSE.
                ls_plantdata-lotsizekey  = 'EX'.
              ENDIF.
              ls_plantdatax-lotsizekey = 'X'.

              " 7. Procurement Type (MARC-BESKZ)
              IF ls_dtl_db-beskz IS NOT INITIAL.
                ls_plantdata-proc_type  = ls_dtl_db-beskz.
              ELSE.
                ls_plantdata-proc_type  = 'F'.
              ENDIF.
              ls_plantdatax-proc_type = 'X'.

              " Transportation Group (MARA-TRAGR)
              IF ls_dtl_db-tragr IS NOT INITIAL.
                CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
                  EXPORTING
                    input  = ls_dtl_db-tragr
                  IMPORTING
                    output = ls_clientdata-trans_grp.
                ls_clientdatax-trans_grp = 'X'.
              ENDIF.

              " 8. Loading Group (MARC-LADGR)
              IF ls_dtl_db-ladgr IS NOT INITIAL.
                CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
                  EXPORTING
                    input  = ls_dtl_db-ladgr
                  IMPORTING
                    output = ls_plantdata-loadinggrp.
                ls_plantdatax-loadinggrp = 'X'.
              ENDIF.

              " Backflush Indicator (MARC-RGEKZ)
              IF ls_dtl_db-rgekz IS NOT INITIAL.
                ls_plantdata-backflush  = ls_dtl_db-rgekz.
                ls_plantdatax-backflush = 'X'.
              ENDIF.

              " Strategy Group (MARC-STRGR)
              IF ls_dtl_db-strgr IS NOT INITIAL.
                ls_plantdata-plan_strgp  = ls_dtl_db-strgr.
                ls_plantdatax-plan_strgp = 'X'.
              ENDIF.

              " Scheduling Margin Key (MARC-FHORI)
              IF ls_dtl_db-fhori IS NOT INITIAL.
                CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
                  EXPORTING
                    input  = ls_dtl_db-fhori
                  IMPORTING
                    output = ls_plantdata-sm_key.
                ls_plantdatax-sm_key = 'X'.
              ENDIF.

              " Production Storage Location (MARC-LGPRO)
              IF ls_dtl_db-lgpro IS NOT INITIAL.
                ls_plantdata-iss_st_loc  = ls_dtl_db-lgpro.
                ls_plantdatax-iss_st_loc = 'X'.
              ENDIF.

              " Prod. Scheduling Profile (MARC-SFPRO)
              IF ls_dtl_db-sfpro IS NOT INITIAL.
                CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
                  EXPORTING
                    input  = ls_dtl_db-sfpro
                  IMPORTING
                    output = ls_plantdata-prodprof.
                ls_plantdatax-prodprof = 'X'.
              ENDIF.

              " Costing Lot Size (MARC-LOSGR)
              IF ls_dtl_db-losgr IS NOT INITIAL.
                ls_plantdata-lot_size  = ls_dtl_db-losgr.
                ls_plantdatax-lot_size = 'X'.
              ENDIF.

              " Stock Determination Group (MARC-EPRIO)
              IF ls_dtl_db-eprio IS NOT INITIAL.
                CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
                  EXPORTING
                    input  = ls_dtl_db-eprio
                  IMPORTING
                    output = ls_plantdata-determ_grp.
                ls_plantdatax-determ_grp = 'X'.
              ENDIF.

              " Variance Key (MARC-AWSLS / KLRAB)
              IF ls_dtl_db-klrab IS NOT INITIAL AND ls_dtl_db-klrab <> 'X' AND ls_dtl_db-klrab <> 'x'.
                ls_plantdata-variance_key  = ls_dtl_db-klrab.
                ls_plantdatax-variance_key = 'X'.
              ENDIF.

              " Storage Location (MARD-LGORT)
              IF ls_dtl_db-lgort IS NOT INITIAL.
                ls_storagelocationdata-plant     = ls_dtl_db-werks.
                ls_storagelocationdata-stge_loc  = ls_dtl_db-lgort.
                ls_storagelocationdatax-plant    = ls_dtl_db-werks.
                ls_storagelocationdatax-stge_loc = ls_dtl_db-lgort.
              ELSE.
                CLEAR: ls_storagelocationdata, ls_storagelocationdatax.
              ENDIF.

              IF ls_dtl_db-prctr IS NOT INITIAL.
                CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
                  EXPORTING
                    input  = ls_dtl_db-prctr
                  IMPORTING
                    output = ls_plantdata-profit_ctr.
                ls_plantdatax-profit_ctr = 'X'.
              ENDIF.

              " Sanitasi & Normalisasi Moving Average Price (VERPR)
              CLEAR: lv_clean_moving, lv_work_num.
              IF ls_dtl_db-verpr IS NOT INITIAL.
                lv_work_num = ls_dtl_db-verpr.
                CONDENSE lv_work_num NO-GAPS.
                IF lv_work_num CS '.' AND lv_work_num CS ','.
                  FIND FIRST OCCURRENCE OF '.' IN lv_work_num MATCH OFFSET lv_pos_dot.
                  FIND FIRST OCCURRENCE OF ',' IN lv_work_num MATCH OFFSET lv_pos_com.
                  IF lv_pos_dot < lv_pos_com.
                    REPLACE ALL OCCURRENCES OF '.' IN lv_work_num WITH ''.
                    REPLACE ALL OCCURRENCES OF ',' IN lv_work_num WITH '.'.
                  ELSE.
                    REPLACE ALL OCCURRENCES OF ',' IN lv_work_num WITH ''.
                  ENDIF.
                ELSEIF lv_work_num CS ','.
                  REPLACE ALL OCCURRENCES OF ',' IN lv_work_num WITH '.'.
                ELSEIF lv_work_num CS '.'.
                  FIND ALL OCCURRENCES OF '.' IN lv_work_num MATCH COUNT lv_dot_cnt.
                  IF lv_dot_cnt > 1.
                    REPLACE ALL OCCURRENCES OF '.' IN lv_work_num WITH ''.
                  ELSE.
                    FIND FIRST OCCURRENCE OF '.' IN lv_work_num MATCH OFFSET lv_pos_dot.
                    lv_len = strlen( lv_work_num ).
                    lv_dec_len = lv_len - lv_pos_dot - 1.
                    IF lv_dec_len = 3.
                      REPLACE ALL OCCURRENCES OF '.' IN lv_work_num WITH ''.
                    ENDIF.
                  ENDIF.
                ENDIF.
                lv_clean_moving = lv_work_num.
              ENDIF.

              " Sanitasi & Normalisasi Standard Price (STPRS)
              CLEAR: lv_clean_std, lv_work_num.
              IF ls_dtl_db-stprs IS NOT INITIAL.
                lv_work_num = ls_dtl_db-stprs.
                CONDENSE lv_work_num NO-GAPS.
                IF lv_work_num CS '.' AND lv_work_num CS ','.
                  FIND FIRST OCCURRENCE OF '.' IN lv_work_num MATCH OFFSET lv_pos_dot.
                  FIND FIRST OCCURRENCE OF ',' IN lv_work_num MATCH OFFSET lv_pos_com.
                  IF lv_pos_dot < lv_pos_com.
                    REPLACE ALL OCCURRENCES OF '.' IN lv_work_num WITH ''.
                    REPLACE ALL OCCURRENCES OF ',' IN lv_work_num WITH '.'.
                  ELSE.
                    REPLACE ALL OCCURRENCES OF ',' IN lv_work_num WITH ''.
                  ENDIF.
                ELSEIF lv_work_num CS ','.
                  REPLACE ALL OCCURRENCES OF ',' IN lv_work_num WITH '.'.
                ELSEIF lv_work_num CS '.'.
                  FIND ALL OCCURRENCES OF '.' IN lv_work_num MATCH COUNT lv_dot_cnt.
                  IF lv_dot_cnt > 1.
                    REPLACE ALL OCCURRENCES OF '.' IN lv_work_num WITH ''.
                  ELSE.
                    FIND FIRST OCCURRENCE OF '.' IN lv_work_num MATCH OFFSET lv_pos_dot.
                    lv_len = strlen( lv_work_num ).
                    lv_dec_len = lv_len - lv_pos_dot - 1.
                    IF lv_dec_len = 3.
                      REPLACE ALL OCCURRENCES OF '.' IN lv_work_num WITH ''.
                    ENDIF.
                  ENDIF.
                ENDIF.
                lv_clean_std = lv_work_num.
              ENDIF.

              " Sanitasi Price Unit (PEINH)
              CLEAR: lv_clean_unit, lv_work_num.
              IF ls_dtl_db-peinh IS NOT INITIAL.
                lv_work_num = ls_dtl_db-peinh.
                CONDENSE lv_work_num NO-GAPS.
                REPLACE ALL OCCURRENCES OF '.' IN lv_work_num WITH ''.
                REPLACE ALL OCCURRENCES OF ',' IN lv_work_num WITH ''.
                lv_clean_unit = lv_work_num.
              ELSE.
                lv_clean_unit = '1'.
              ENDIF.

              " Sanitasi Price Unit Hard Currency (PEINH_2)
              CLEAR: lv_clean_unit_2, lv_work_num.
              IF ls_dtl_db-peinh_2 IS NOT INITIAL.
                lv_work_num = ls_dtl_db-peinh_2.
                CONDENSE lv_work_num NO-GAPS.
                REPLACE ALL OCCURRENCES OF '.' IN lv_work_num WITH ''.
                REPLACE ALL OCCURRENCES OF ',' IN lv_work_num WITH ''.
                lv_clean_unit_2 = lv_work_num.
              ENDIF.

              ls_valuationdata-val_area  = ls_dtl_db-werks.
              ls_valuationdatax-val_area = ls_dtl_db-werks.

              IF ls_dtl_db-bklas IS NOT INITIAL.
                ls_valuationdata-val_class  = ls_dtl_db-bklas.
                ls_valuationdatax-val_class = 'X'.
              ENDIF.

              " Price Control (MBEW-VPRSV)
              IF ls_dtl_db-vprsv IS NOT INITIAL.
                ls_valuationdata-price_ctrl  = ls_dtl_db-vprsv.
                ls_valuationdatax-price_ctrl = 'X'.
              ENDIF.

              " Standard Price (MBEW-STPRS)
              IF lv_clean_std IS NOT INITIAL.
                ls_valuationdata-std_price  = lv_clean_std.
                ls_valuationdatax-std_price = 'X'.
              ENDIF.

              " Moving Average Price (MBEW-VERPR)
              IF ls_dtl_db-vprsv = 'S'.
                " Untuk Price Control 'S', Moving Price harus setara dengan Standard Price
                " Mencegah error konversi valas (SG 105) jika data Moving Price masih berisi IDR pada Company Code USD
                IF lv_clean_std IS NOT INITIAL.
                  ls_valuationdata-moving_pr  = lv_clean_std.
                  ls_valuationdatax-moving_pr = 'X'.
                ELSEIF lv_clean_moving IS NOT INITIAL.
                  ls_valuationdata-moving_pr  = lv_clean_moving.
                  ls_valuationdatax-moving_pr = 'X'.
                ENDIF.
              ELSE.
                " Untuk Price Control 'V', Moving Price adalah harga valuasi utama
                IF lv_clean_moving IS NOT INITIAL.
                  ls_valuationdata-moving_pr  = lv_clean_moving.
                  ls_valuationdatax-moving_pr = 'X'.
                ENDIF.
              ENDIF.

              " Price Unit (MBEW-PEINH)
              IF lv_clean_unit IS NOT INITIAL.
                ls_valuationdata-price_unit  = lv_clean_unit.
                ls_valuationdatax-price_unit = 'X'.
              ENDIF.

              " Material-related Origin Ind. (MBEW-HKMAT)
              IF ls_dtl_db-hkmat IS NOT INITIAL.
                ls_valuationdata-orig_mat  = ls_dtl_db-hkmat.
                ls_valuationdatax-orig_mat = 'X'.
              ENDIF.

              " Qty Structure Indicator (MBEW-EKALR)
              IF ls_dtl_db-ekalr IS NOT INITIAL.
                ls_valuationdata-qty_struct  = ls_dtl_db-ekalr.
                ls_valuationdatax-qty_struct = 'X'.
              ENDIF.

              " Origin Group (MBEW-HERBL / HRKFT) validation in TKKH1
              IF ls_dtl_db-herbl IS NOT INITIAL.
                CLEAR: lv_app_bukrs, lv_app_kokrs, lv_app_hrkft, lv_herbl_sub.

                IF strlen( ls_dtl_db-herbl ) >= 2.
                  lv_herbl_sub = ls_dtl_db-herbl(2).
                ELSE.
                  lv_herbl_sub = ls_dtl_db-herbl.
                ENDIF.

                IF ls_dtl_db-werks IS NOT INITIAL.
                  SELECT SINGLE bukrs FROM t001k INTO @lv_app_bukrs
                    WHERE bwkey = @ls_dtl_db-werks.
                  IF lv_app_bukrs IS NOT INITIAL.
                    SELECT SINGLE kokrs FROM tka02 INTO @lv_app_kokrs
                      WHERE bukrs = @lv_app_bukrs.
                  ENDIF.
                ENDIF.

                IF lv_app_kokrs IS NOT INITIAL.
                  SELECT SINGLE hrkft FROM tkkh1 INTO @lv_app_hrkft
                    WHERE kokrs = @lv_app_kokrs
                      AND ( hrkft = @ls_dtl_db-herbl OR hrkft = @lv_herbl_sub ).
                ELSE.
                  SELECT SINGLE hrkft FROM tkkh1 INTO @lv_app_hrkft
                    WHERE hrkft = @ls_dtl_db-herbl.
                ENDIF.

                IF lv_app_hrkft IS INITIAL.
                  IF lv_app_kokrs IS NOT INITIAL.
                    lv_err_msg = |Origin Group { ls_dtl_db-herbl } tidak terdaftar di Controlling Area | &&
                                 |{ lv_app_kokrs } (Tabel TKKH1 Plant { ls_dtl_db-werks })|.
                  ELSE.
                    lv_err_msg = |The value { ls_dtl_db-herbl } is not allowed for the field MBEW-HRKFT/BAPI_MBEW-ORIG_GROUP (Origin Group tidak terdaftar di tabel SAP TKKH1)|.
                  ENDIF.
                  EXIT.
                ENDIF.

                ls_valuationdata-orig_group  = ls_dtl_db-herbl.
                ls_valuationdatax-orig_group = 'X'.
              ENDIF.

              " E. EKSEKUSI BAPI SAVEDATA
              CALL FUNCTION 'BAPI_MATERIAL_SAVEDATA'
                EXPORTING
                  headdata             = ls_headdata
                  clientdata           = ls_clientdata
                  clientdatax          = ls_clientdatax
                  plantdata            = ls_plantdata
                  plantdatax           = ls_plantdatax
                  storagelocationdata  = ls_storagelocationdata
                  storagelocationdatax = ls_storagelocationdatax
                  valuationdata        = ls_valuationdata
                  valuationdatax       = ls_valuationdatax
                  salesdata            = ls_salesdata
                  salesdatax           = ls_salesdatax
                  warehousenumberdata  = ls_warehousenumberdata
                  warehousenumberdatax = ls_warehousenumberdatax
                  storagetypedata      = ls_storagetypedata
                  storagetypedatax     = ls_storagetypedatax
                IMPORTING
                  return               = ls_bapireturn
                TABLES
                  materialdescription  = lt_materialdesc
                  taxclassifications   = lt_taxclassifications
                  returnmessages       = lt_returnmes.

              IF ls_bapireturn-type = 'E' OR ls_bapireturn-type = 'A'.
                CLEAR: lv_err_msg, ls_resp-return_messages.
                DATA: ls_bapi_msg_item TYPE ty_bapi_msg.
                LOOP AT lt_returnmes INTO ls_returnmes.
                  CLEAR ls_bapi_msg_item.
                  ls_bapi_msg_item-type       = ls_returnmes-type.
                  ls_bapi_msg_item-id         = ls_returnmes-id.
                  ls_bapi_msg_item-number     = ls_returnmes-number.
                  ls_bapi_msg_item-message    = ls_returnmes-message.
                  ls_bapi_msg_item-message_v1 = ls_returnmes-message_v1.
                  ls_bapi_msg_item-message_v2 = ls_returnmes-message_v2.
                  APPEND ls_bapi_msg_item TO ls_resp-return_messages.

                  IF ls_returnmes-type = 'E' OR ls_returnmes-type = 'A'.
                    IF lv_err_msg IS INITIAL.
                      lv_err_msg = ls_returnmes-message.
                    ELSE.
                      CONCATENATE lv_err_msg ls_returnmes-message INTO lv_err_msg SEPARATED BY ' | '.
                    ENDIF.
                  ENDIF.
                ENDLOOP.
                IF lv_err_msg IS INITIAL.
                  lv_err_msg = ls_bapireturn-message.
                ENDIF.
                EXIT.
              ENDIF.

              " Commit material ke MARA database agar BAPI_OBJCL_CREATE & ML dapat membaca MARA
              CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = 'X'.

              " Aktifkan Classification View via BAPI_OBJCL_CREATE jika ada Class '001' di SAP
              DATA: lv_objkey_class TYPE bapi1003_key-object,
                    lv_class_found  TYPE klah-class,
                    lt_ret_class    TYPE TABLE OF bapiret2,
                    lv_matnr_conv   TYPE matnr.

              CLEAR: lv_objkey_class, lv_class_found, lt_ret_class, lv_matnr_conv.
              CALL FUNCTION 'CONVERSION_EXIT_MATN1_INPUT'
                EXPORTING
                  input        = ls_headdata-material
                IMPORTING
                  output       = lv_matnr_conv
                EXCEPTIONS
                  OTHERS       = 1.
              IF lv_matnr_conv IS INITIAL.
                lv_matnr_conv = ls_headdata-material.
              ENDIF.

              lv_objkey_class = CONV bapi1003_key-object( lv_matnr_conv ).

              SELECT SINGLE class FROM klah INTO @lv_class_found
                WHERE klart = '001'.

              IF lv_class_found IS NOT INITIAL AND lv_objkey_class IS NOT INITIAL.
                CALL FUNCTION 'BAPI_OBJCL_CREATE'
                  EXPORTING
                    objectkeynew   = lv_objkey_class
                    objecttablenew = 'MARA'
                    classnumnew    = lv_class_found
                    classtypenew   = '001'
                    status         = '1'
                  TABLES
                    return         = lt_ret_class.
                CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = 'X'.
              ENDIF.

              " Material Ledger Hard Currency (Price Unit PEINH_2) via CKML_MATVAL_PRICE_CHANGE
              " Hanya berlaku jika Plant 1000 (Local IDR, Hard USD) dan PEINH_2 bukan default '1'
              IF ls_dtl_db-werks = '1000' AND lv_clean_unit_2 IS NOT INITIAL AND lv_clean_unit_2 <> '1'.
                CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = 'X'.

                lv_hard_curr = 'USD'.

                IF lv_hard_curr IS NOT INITIAL.
                  REFRESH: lt_ml_prices, lt_ml_return.
                  CLEAR: ls_ml_price, lv_ml_matnr.

                  CALL FUNCTION 'CONVERSION_EXIT_MATN1_INPUT'
                    EXPORTING
                      input        = ls_dtl_db-matnr_ext
                    IMPORTING
                      output       = lv_ml_matnr
                    EXCEPTIONS
                      length_error = 1
                      OTHERS       = 2.
                  IF sy-subrc = 0.
                    ls_ml_price-curr_type    = '40'.
                    ls_ml_price-currency     = lv_hard_curr.
                    ls_ml_price-currency_iso = lv_hard_curr.
                    ls_ml_price-price_unit   = lv_clean_unit_2.
                    APPEND ls_ml_price TO lt_ml_prices.

                    CLEAR lv_ml_pricedate.
                    lv_ml_pricedate-price_date = sy-datum.

                    CALL FUNCTION 'CKML_MATVAL_PRICE_CHANGE'
                      EXPORTING
                        material      = lv_ml_matnr
                        valuationarea = ls_dtl_db-werks
                        pricedate     = lv_ml_pricedate
                      TABLES
                        prices        = lt_ml_prices
                        return        = lt_ml_return
                      EXCEPTIONS
                        OTHERS        = 1.

                    LOOP AT lt_ml_return INTO ls_ml_return WHERE type = 'E' OR type = 'A'.
                      " Abaikan error non-kritis Material Ledger (C+ 020, FG 002, CKML, fiscal year variant)
                      IF ls_ml_return-id = 'C+' OR ls_ml_return-id = 'FG' OR ls_ml_return-id = 'CK'.
                        CONTINUE.
                      ENDIF.
                      IF ls_ml_return-message CS 'not activated' OR ls_ml_return-message CS 'does not exist' OR ls_ml_return-message CS 'fiscal year variant'.
                        CONTINUE.
                      ENDIF.
                      IF lv_err_msg IS INITIAL.
                        lv_err_msg = ls_ml_return-message.
                      ELSE.
                        CONCATENATE lv_err_msg ls_ml_return-message INTO lv_err_msg SEPARATED BY ' | '.
                      ENDIF.
                    ENDLOOP.

                    IF lv_err_msg IS NOT INITIAL.
                      EXIT.
                    ELSE.
                      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = 'X'.
                    ENDIF.
                  ENDIF.
                ENDIF.
              ENDIF.

            ENDLOOP.

            " F. HANDLER COMMIT / ROLLBACK PER REQUEST
            IF lv_err_msg IS NOT INITIAL.
              CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
              lv_has_error = abap_true.
              lv_last_err  = lv_err_msg.
              lv_fail_cnt  = lv_fail_cnt + 1.

              UPDATE zmdg_stg_hdr
                SET status     = 'FAILED',
                    rej_reason = @lv_err_msg,
                    approver   = @sy-uname,
                    app_date   = @sy-datum,
                    app_time   = @sy-uzeit
                WHERE req_no   = @lv_req_item.
            ELSE.
              CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = 'X'.
              lv_success_cnt = lv_success_cnt + 1.

              UPDATE zmdg_stg_hdr
                SET status     = 'APPROVED',
                    rej_reason = '',
                    approver   = @sy-uname,
                    app_date   = @sy-datum,
                    app_time   = @sy-uzeit
                WHERE req_no   = @lv_req_item.
            ENDIF.

          ENDLOOP.

          IF lv_fail_cnt > 0 AND lv_success_cnt = 0.
            CLEAR ls_resp.
            ls_resp-status  = 'ERROR'.
            ls_resp-message = 'Proses approval gagal: ' && lv_last_err.
            lv_json = /ui2/cl_json=>serialize( data = ls_resp compress = 'X' pretty_name = /ui2/cl_json=>pretty_mode-low_case ).
          ELSEIF lv_fail_cnt > 0 AND lv_success_cnt > 0.
            CLEAR ls_resp.
            ls_resp-status  = 'PARTIAL'.
            ls_resp-message = lv_success_cnt && ' request BERHASIL di-approve & di-upload ke SAP, ' && lv_fail_cnt && ' request GAGAL. Error: ' && lv_last_err.
            lv_json = /ui2/cl_json=>serialize( data = ls_resp compress = 'X' pretty_name = /ui2/cl_json=>pretty_mode-low_case ).
          ELSE.
            DATA: lt_disp_materials TYPE TABLE OF string,
                  lv_m_raw          TYPE string,
                  lv_m_clean        TYPE string,
                  lv_mat_list_str   TYPE string.

            CLEAR: ls_resp, lt_disp_materials, lv_mat_list_str.
            LOOP AT lt_used_matnr INTO lv_m_raw.
              lv_m_clean = lv_m_raw.
              SHIFT lv_m_clean LEFT DELETING LEADING '0'.
              CONDENSE lv_m_clean.
              IF lv_m_clean IS NOT INITIAL.
                READ TABLE lt_disp_materials WITH KEY table_line = lv_m_clean TRANSPORTING NO FIELDS.
                IF sy-subrc <> 0.
                  APPEND lv_m_clean TO lt_disp_materials.
                  IF lv_mat_list_str IS INITIAL.
                    lv_mat_list_str = lv_m_clean.
                  ELSE.
                    lv_mat_list_str = |{ lv_mat_list_str }, { lv_m_clean }|.
                  ENDIF.
                ENDIF.
              ENDIF.
            ENDLOOP.

            ls_resp-status    = 'SUCCESS'.
            ls_resp-materials = lt_disp_materials.
            ls_resp-matnr     = lv_mat_list_str.
            ls_resp-matnr_ext = lv_mat_list_str.
            IF lv_mat_list_str IS NOT INITIAL.
              ls_resp-message = 'Data berhasil disimpan. (Kode Material: ' && lv_mat_list_str && ')'.
            ELSE.
              ls_resp-message = 'Data berhasil disimpan.'.
            ENDIF.
            lv_json = /ui2/cl_json=>serialize( data = ls_resp compress = 'X' pretty_name = /ui2/cl_json=>pretty_mode-low_case ).
          ENDIF.

          _m_response->set_content_type( 'application/json' ).
          _m_response->set_cdata( lv_json ).
          _m_navigation->response_complete( ).
          RETURN.

        " ------------------------------------------------------------------
        " 4. BULK / SINGLE REJECT WITH REASON
        " ------------------------------------------------------------------
        WHEN 'BULK_REJECT' OR 'QUICK_REJECT'.
          lv_req_nos = request->get_form_field( 'REQ_NOS' ).
          IF lv_req_nos IS INITIAL.
            lv_req_nos = request->get_form_field( 'REQ_NO' ).
          ENDIF.

          lv_reason = request->get_form_field( 'REJ_REASON' ).

          SPLIT lv_req_nos AT ',' INTO TABLE lt_req_split.

          LOOP AT lt_req_split INTO lv_req_item.
            CONDENSE lv_req_item.
            CHECK lv_req_item IS NOT INITIAL.

            UPDATE zmdg_stg_hdr
              SET status     = 'REJECTED',
                  rej_reason = @lv_reason,
                  approver   = @sy-uname,
                  app_date   = @sy-datum,
                  app_time   = @sy-uzeit
              WHERE req_no   = @lv_req_item.
          ENDLOOP.

          lv_json = '{"status":"SUCCESS","message":"Data berhasil ditolak!"}'.
          _m_response->set_content_type( 'application/json' ).
          _m_response->set_cdata( lv_json ).
          _m_navigation->response_complete( ).
          RETURN.

        " ------------------------------------------------------------------
        " 5. DELETE DRAFT REQUEST
        " ------------------------------------------------------------------
        WHEN 'DELETE_DRAFT'.
          lv_req_no = request->get_form_field( 'REQ_NO' ).

          DELETE FROM zmdg_stg_hdr WHERE req_no = @lv_req_no.
          DELETE FROM zmdg_stg_part WHERE req_no = @lv_req_no.

          lv_json = '{"status":"SUCCESS","message":"Draft deleted!"}'.
          _m_response->set_content_type( 'application/json' ).
          _m_response->set_cdata( lv_json ).
          _m_navigation->response_complete( ).
          RETURN.

        WHEN 'LOGOUT'.
          _m_navigation->exit( ).
          RETURN.

      ENDCASE.

    ENDIF.