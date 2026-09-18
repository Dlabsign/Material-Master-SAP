    DATA: lv_action   TYPE string,
          lv_json     TYPE string,
          lv_req_no   TYPE string,
          lv_req_nos  TYPE string,
          lv_reason   TYPE string,
          lv_auth_user TYPE string.

    TYPES: BEGIN OF ty_staging_list,
            req_no     TYPE string,
            remarks    TYPE string,
            sub_reason TYPE string,
            req_date   TYPE string,
            req_time   TYPE string,
            requestor  TYPE string,
            status     TYPE string,
            total_item TYPE i,
            rej_reason TYPE string,
          END OF ty_staging_list.

    DATA: lt_list TYPE TABLE OF ty_staging_list,
          ls_list TYPE ty_staging_list.

    DATA: lt_hdr_db TYPE TABLE OF zmdg_req_hdr,
          ls_hdr_db TYPE zmdg_req_hdr,
          lt_dtl_db TYPE TABLE OF zmdg_req_dtl,
          ls_dtl_db TYPE zmdg_req_dtl.

    DATA: lt_req_split TYPE TABLE OF string,
          lv_req_item  TYPE string.

    " Variabel Pengecekan & Auto-Generate
    DATA: lv_is_available TYPE char1,
          lv_next_number  TYPE matnr_ext,
          lt_check_return TYPE TABLE OF bapiret2,
          ls_check_return TYPE bapiret2,
          lv_exist_mara   TYPE mara-matnr,
          lv_exist_stage  TYPE zmdg_req_hdr-status,
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
          lt_materialdesc         TYPE TABLE OF bapi_makt,
          ls_materialdesc         TYPE bapi_makt,
          lt_unitsofmeasure       TYPE TABLE OF bapi_marm,
          ls_unitsofmeasure       TYPE bapi_marm,
          lt_unitsofmeasurex      TYPE TABLE OF bapi_marmx,
          ls_unitsofmeasurex      TYPE bapi_marmx,
          ls_bapireturn           TYPE bapiret2,
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
          lv_dec_len      TYPE i.

    DATA: lv_has_error   TYPE sap_bool,
          lv_err_msg     TYPE string,
          lv_last_err    TYPE string,
          lv_coded_cnt   TYPE i,
          lv_success_cnt TYPE i,
          lv_fail_cnt    TYPE i,
          lv_curr_stat   TYPE zmdg_req_hdr-status.

    TYPES: BEGIN OF ty_resp,
            status    TYPE string,
            message   TYPE string,
            matnr     TYPE string,
            matnr_ext TYPE string,
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

    IF lv_auth_user <> 'ABAPER04' AND lv_auth_user <> 'KMI-BOD' AND lv_auth_user <> 'KMI-U163'.
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
          DATA: lv_cnt_p    TYPE i,
                lv_cnt_a    TYPE i,
                lv_cnt_r    TYPE i,
                lv_cnt_bp_p TYPE i.
          SELECT COUNT( * ) FROM zmdg_req_hdr WHERE status IN ( 'CHECKED', 'CODED' ) INTO @lv_cnt_p.
          SELECT COUNT( * ) FROM zmdg_req_hdr WHERE status = 'APPROVED' INTO @lv_cnt_a.
          SELECT COUNT( * ) FROM zmdg_req_hdr WHERE status IN ( 'REJECTED', 'FAILED' ) INTO @lv_cnt_r.
          SELECT COUNT( * ) FROM zmdg_bp_req
            WHERE status = 'CHECKED'
              AND stw_data_status = 'X'
              AND stw_bank_status = 'X'
            INTO @lv_cnt_bp_p.

          lv_json = '{"pending":' && lv_cnt_p &&
                    ',"mat_pending":' && lv_cnt_p &&
                    ',"bp_pending":' && lv_cnt_bp_p &&
                    ',"approved":' && lv_cnt_a &&
                    ',"rejected":' && lv_cnt_r && '}'.
          _m_response->set_content_type( 'application/json' ).
          _m_response->set_cdata( lv_json ).
          _m_navigation->response_complete( ).
          RETURN.

        " ------------------------------------------------------------------
        " 1. GET ALL STAGING REQUEST LIST
        " ------------------------------------------------------------------
        WHEN 'GET_STAGING_LIST'.
          CLEAR: lt_hdr_db, lt_list.

          SELECT * FROM zmdg_req_hdr
            INTO TABLE @lt_hdr_db
            WHERE status IN ('CHECKED', 'CODED')
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

            SELECT COUNT( * ) FROM zmdg_req_dtl INTO @ls_list-total_item WHERE req_no = @ls_hdr_db-req_no.

            APPEND ls_list TO lt_list.
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

          SELECT * FROM zmdg_req_dtl
            INTO TABLE @lt_dtl_db
            WHERE req_no = @lv_req_no
            ORDER BY item_no ASCENDING.

          lv_json = /ui2/cl_json=>serialize( data = lt_dtl_db compress = 'X' pretty_name = /ui2/cl_json=>pretty_mode-low_case ).

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
            SELECT SINGLE status FROM zmdg_req_hdr INTO @lv_curr_stat WHERE req_no = @lv_req_item.
            IF sy-subrc = 0 AND ( lv_curr_stat = 'APPROVED' OR lv_curr_stat = 'REJECTED' ).
              CONTINUE.
            ENDIF.

            UPDATE zmdg_req_hdr
              SET status   = 'VALIDATING',
                  approver = @sy-uname,
                  app_date = @sy-datum,
                  app_time = @sy-uzeit
              WHERE req_no = @lv_req_item.

            SELECT * FROM zmdg_req_dtl
              INTO TABLE @lt_dtl_db
              WHERE req_no = @lv_req_item
              ORDER BY item_no ASCENDING.

            IF lt_dtl_db IS INITIAL.
              lv_has_error = abap_true.
              lv_last_err  = 'Tidak ada data item untuk Request ' && lv_req_item.
              UPDATE zmdg_req_hdr
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

              IF sy-mandt = '300' AND ls_dtl_db-prctr IS INITIAL.
                lv_err_msg = 'Profit Center wajib diisi untuk Mandant 300 (Item ' && ls_dtl_db-item_no && ')'.
                EXIT.
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
                  UPDATE zmdg_req_dtl
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

              " D. MAPPING BAPI PARAMETERS
              CLEAR: ls_headdata, ls_clientdata, ls_clientdatax,
                    ls_plantdata, ls_plantdatax,
                    ls_storagelocationdata, ls_storagelocationdatax,
                    ls_valuationdata, ls_valuationdatax,
                    ls_salesdata, ls_salesdatax,
                    ls_bapireturn, lt_materialdesc, lt_unitsofmeasure,
                    lt_unitsofmeasurex, lt_returnmes.

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

              ls_headdata-ind_sector      = ls_dtl_db-mbrsh.
              ls_headdata-matl_type       = ls_dtl_db-mtart.
              ls_headdata-basic_view      = 'X'.
              ls_headdata-purchase_view   = 'X'.
              ls_headdata-work_sched_view = 'X'.
              ls_headdata-sales_view      = 'X'.

              IF ls_dtl_db-vkorg IS NOT INITIAL AND ls_dtl_db-vtweg IS NOT INITIAL.
                ls_salesdata-sales_org   = ls_dtl_db-vkorg.
                ls_salesdatax-sales_org  = ls_dtl_db-vkorg.
                ls_salesdata-distr_chan  = ls_dtl_db-vtweg.
                ls_salesdatax-distr_chan = ls_dtl_db-vtweg.
              ENDIF.

              IF ls_dtl_db-werks IS NOT INITIAL.
                ls_headdata-storage_view = 'X'.
                ls_headdata-account_view = 'X'.
                ls_headdata-cost_view    = 'X'.
                ls_headdata-mrp_view     = 'X'.
              ENDIF.

              IF ls_dtl_db-insptype IS NOT INITIAL OR ls_dtl_db-qssys IS NOT INITIAL OR ls_dtl_db-ssqss IS NOT INITIAL.
                ls_headdata-quality_view = 'X'.
              ENDIF.

              IF ls_dtl_db-matkl IS NOT INITIAL.
                ls_clientdata-matl_group  = ls_dtl_db-matkl.
                ls_clientdatax-matl_group = 'X'.
              ENDIF.

              " Division (SPART)
              IF ls_dtl_db-spart IS NOT INITIAL.
                ls_clientdata-division  = ls_dtl_db-spart.
                ls_clientdatax-division = 'X'.
              ENDIF.

              " Prod./insp. memo (FERTH)
              IF ls_dtl_db-ferth IS NOT INITIAL.
                ls_clientdata-basic_matl  = ls_dtl_db-ferth.
                ls_clientdatax-basic_matl = 'X'.
              ENDIF.

              " Material Package (MAGRV)
              IF ls_dtl_db-magrv IS NOT INITIAL.
                ls_clientdata-mat_grp_sm  = ls_dtl_db-magrv.
                ls_clientdatax-mat_grp_sm = 'X'.
              ENDIF.

              IF ls_dtl_db-meins IS NOT INITIAL.
                CALL FUNCTION 'CONVERSION_EXIT_CUNIT_INPUT'
                  EXPORTING
                    input          = ls_dtl_db-meins
                  IMPORTING
                    output         = ls_clientdata-base_uom
                  EXCEPTIONS
                    OTHERS         = 1.
                ls_clientdata-base_uom_iso  = ls_clientdata-base_uom.
                ls_clientdatax-base_uom     = 'X'.
                ls_clientdatax-base_uom_iso = 'X'.
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

              " 6. Lot Size (MARC-DISLS)
              IF ls_dtl_db-disls IS NOT INITIAL AND ls_dtl_db-disls <> 'PB'.
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
                    lv_err_msg = |The value { ls_dtl_db-herbl } is not allowed for the field MBEW-HRKFT/BAPI_MBEW-ORIG_GROUP (Origin Group tidak terdaftar pada Controlling Area { lv_app_kokrs } di tabel SAP TKKH1 untuk Plant { ls_dtl_db-werks })|.
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
                IMPORTING
                  return               = ls_bapireturn
                TABLES
                  materialdescription  = lt_materialdesc
                  returnmessages       = lt_returnmes.

              IF ls_bapireturn-type = 'E' OR ls_bapireturn-type = 'A'.
                CLEAR lv_err_msg.
                LOOP AT lt_returnmes INTO ls_returnmes WHERE type = 'E' OR type = 'A'.
                  IF lv_err_msg IS INITIAL.
                    lv_err_msg = ls_returnmes-message.
                  ELSE.
                    CONCATENATE lv_err_msg ls_returnmes-message INTO lv_err_msg SEPARATED BY ' | '.
                  ENDIF.
                ENDLOOP.
                IF lv_err_msg IS INITIAL.
                  lv_err_msg = ls_bapireturn-message.
                ENDIF.
                EXIT.
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

              UPDATE zmdg_req_hdr
                SET status     = 'FAILED',
                    rej_reason = @lv_err_msg,
                    approver   = @sy-uname,
                    app_date   = @sy-datum,
                    app_time   = @sy-uzeit
                WHERE req_no   = @lv_req_item.
            ELSE.
              CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = 'X'.
              lv_success_cnt = lv_success_cnt + 1.

              UPDATE zmdg_req_hdr
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
            CLEAR ls_resp.
            CLEAR lv_disp_matnr.
            lv_disp_matnr = ls_dtl_db-matnr_ext.
            SHIFT lv_disp_matnr LEFT DELETING LEADING '0'.
            ls_resp-status    = 'SUCCESS'.
            ls_resp-matnr     = lv_disp_matnr.
            ls_resp-matnr_ext = lv_disp_matnr.
            IF lv_success_cnt > 1.
              ls_resp-message = lv_success_cnt && ' request berhasil divalidasi dan di-upload ke SAP S/4HANA!'.
            ELSEIF lv_disp_matnr IS NOT INITIAL.
              ls_resp-message = 'Data berhasil divalidasi dan di-upload ke SAP S/4HANA! (Nomor Material: ' && lv_disp_matnr && ')'.
            ELSE.
              ls_resp-message = 'Data berhasil divalidasi dan di-upload ke SAP S/4HANA!'.
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

            UPDATE zmdg_req_hdr
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

          DELETE FROM zmdg_req_hdr WHERE req_no = @lv_req_no.
          DELETE FROM zmdg_req_dtl WHERE req_no = @lv_req_no.

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