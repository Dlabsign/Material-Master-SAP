  DATA: lv_action   TYPE string,
        lv_json     TYPE string,
        lv_req_no   TYPE string,
        lv_req_nos  TYPE string,
        lv_reason   TYPE string.

  TYPES: BEGIN OF ty_staging_list,
          req_no     TYPE string,
          remarks    TYPE string,
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
        lv_exist_stage  TYPE zmdg_req_hdr-status.

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

  DATA: lv_has_error TYPE sap_bool,
        lv_err_msg   TYPE string,
        lv_last_err  TYPE string,
        lv_coded_cnt TYPE i.

  TYPES: BEGIN OF ty_resp,
          status  TYPE string,
          message TYPE string,
        END OF ty_resp.
  DATA: ls_resp TYPE ty_resp.

  lv_action = request->get_form_field( 'action' ).
  IF lv_action IS INITIAL.
    lv_action = request->get_form_field( 'OnInputProcessing' ).
  ENDIF.
  TRANSLATE lv_action TO UPPER CASE.

  IF lv_action IS NOT INITIAL.

    CASE lv_action.

      " ------------------------------------------------------------------
      " GET COUNTERS FOR SIDEBAR BADGES
      " ------------------------------------------------------------------
      WHEN 'GET_COUNTERS'.
        DATA: lv_cnt_p TYPE i, lv_cnt_a TYPE i, lv_cnt_r TYPE i.
        SELECT COUNT( * ) FROM zmdg_req_hdr WHERE status IN ( 'CHECKED', 'CODED', 'SUBMITTED' ) INTO @lv_cnt_p.
        SELECT COUNT( * ) FROM zmdg_req_hdr WHERE status = 'APPROVED' INTO @lv_cnt_a.
        SELECT COUNT( * ) FROM zmdg_req_hdr WHERE status IN ( 'REJECTED', 'FAILED' ) INTO @lv_cnt_r.

        lv_json = '{"pending":' && lv_cnt_p && ',"approved":' && lv_cnt_a && ',"rejected":' && lv_cnt_r && '}'.
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
          ls_list-req_no     = CONV #( ls_hdr_db-req_no ).
          ls_list-remarks    = CONV #( ls_hdr_db-remarks ).
          ls_list-req_date   = CONV #( ls_hdr_db-req_date ).
          ls_list-req_time   = CONV #( ls_hdr_db-req_time ).
          ls_list-requestor  = CONV #( ls_hdr_db-requestor ).
          ls_list-status     = CONV #( ls_hdr_db-status ).
          ls_list-rej_reason = CONV #( ls_hdr_db-rej_reason ).

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
        lv_has_error = abap_false.
        CLEAR lv_last_err.

        LOOP AT lt_req_split INTO lv_req_item.
          CONDENSE lv_req_item.
          CHECK lv_req_item IS NOT INITIAL.

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

          " LOOP UNTUK EDIT/VALIDASI SETIAP ITEM IN BATCH
          LOOP AT lt_dtl_db INTO ls_dtl_db.

            " A. GENERATE KODE MATERIAL JIKA MATNR MASIH KOSONG
            IF ls_dtl_db-matnr_ext IS INITIAL.
              CLEAR: lv_is_available, lv_next_number, lt_check_return.

              CALL FUNCTION 'ZFM_CHECK_MATERIAL'
                EXPORTING
                  iv_mtart        = ls_dtl_db-mtart
                IMPORTING
                  ev_is_available = lv_is_available
                  ev_next_number  = lv_next_number
                  et_return       = lt_check_return.

              IF lv_is_available = 'X' AND lv_next_number IS NOT INITIAL.
                ls_dtl_db-matnr_ext = lv_next_number.

                " Update nomor yang dihasilkan ke tabel staging detail
                UPDATE zmdg_req_dtl
                  SET matnr_ext = @ls_dtl_db-matnr_ext
                  WHERE req_no  = @ls_dtl_db-req_no
                    AND item_no = @ls_dtl_db-item_no.
              ELSE.
                READ TABLE lt_check_return INTO ls_check_return WITH KEY type = 'E'.
                IF sy-subrc = 0.
                  lv_err_msg = |Item { ls_dtl_db-item_no }: Auto-gen gagal - { ls_check_return-message }|.
                ELSE.
                  lv_err_msg = |Item { ls_dtl_db-item_no }: Gagal generate nomor material untuk MTART { ls_dtl_db-mtart }|.
                ENDIF.
                EXIT.
              ENDIF.
            ENDIF.

            " B. VALIDASI MANDATORY FIELD
            IF ls_dtl_db-mbrsh IS INITIAL OR ls_dtl_db-mtart IS INITIAL.
              lv_err_msg = 'Industry Sector dan Material Type wajib diisi (Item ' && ls_dtl_db-item_no && ')'.
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

            " C. CHECK DUPLIKASI KODE DI TABEL MARA (SAP MASTER DATA)
            CLEAR lv_exist_mara.
            SELECT SINGLE matnr FROM mara INTO @lv_exist_mara WHERE matnr = @ls_dtl_db-matnr_ext.
            IF sy-subrc = 0.
              lv_err_msg = |Kode Material { ls_dtl_db-matnr_ext } sudah terdaftar di MARA SAP|.
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
                output       = ls_headdata-material_long
              EXCEPTIONS
                OTHERS       = 1.

            ls_headdata-ind_sector      = ls_dtl_db-mbrsh.
            ls_headdata-matl_type       = ls_dtl_db-mtart.
            ls_headdata-basic_view      = 'X'.
            ls_headdata-purchase_view   = 'X'.
            ls_headdata-work_sched_view = 'X'.

            IF ls_dtl_db-werks IS NOT INITIAL AND ls_dtl_db-lgort IS NOT INITIAL.
              ls_headdata-storage_view = 'X'.
            ENDIF.

            IF ls_dtl_db-werks IS NOT INITIAL.
              ls_headdata-account_view = 'X'.
              IF ls_dtl_db-dismm IS NOT INITIAL OR ls_dtl_db-beskz IS NOT INITIAL OR ls_dtl_db-mtvfp IS NOT INITIAL.
                ls_headdata-mrp_view = 'X'.
              ENDIF.
            ENDIF.

            IF ls_dtl_db-matkl IS NOT INITIAL.
              ls_clientdata-matl_group  = ls_dtl_db-matkl.
              ls_clientdatax-matl_group = 'X'.
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

            " 8. Loading Group (MARC-LADGR)
            IF ls_dtl_db-ladgr IS NOT INITIAL.
              ls_plantdata-loadinggrp  = ls_dtl_db-ladgr.
            ELSE.
              ls_plantdata-loadinggrp  = '0001'.
            ENDIF.
            ls_plantdatax-loadinggrp = 'X'.

            ls_storagelocationdata-plant     = ls_dtl_db-werks.
            ls_storagelocationdata-stge_loc  = ls_dtl_db-lgort.
            ls_storagelocationdatax-plant    = ls_dtl_db-werks.
            ls_storagelocationdatax-stge_loc = ls_dtl_db-lgort.

            IF ls_dtl_db-prctr IS NOT INITIAL.
              CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
                EXPORTING
                  input  = ls_dtl_db-prctr
                IMPORTING
                  output = ls_plantdata-profit_ctr.
              ls_plantdatax-profit_ctr = 'X'.
            ENDIF.

            ls_valuationdata-val_area  = ls_dtl_db-werks.
            ls_valuationdatax-val_area = ls_dtl_db-werks.

            IF ls_dtl_db-bklas IS NOT INITIAL.
              ls_valuationdata-val_class  = ls_dtl_db-bklas.
              ls_valuationdatax-val_class = 'X'.
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

          ENDLOOP.

          " F. HANDLER COMMIT / ROLLBACK PER REQUEST
          IF lv_err_msg IS NOT INITIAL.
            CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
            lv_has_error = abap_true.
            lv_last_err  = lv_err_msg.

            UPDATE zmdg_req_hdr
              SET status     = 'FAILED',
                  rej_reason = @lv_err_msg,
                  approver   = @sy-uname,
                  app_date   = @sy-datum,
                  app_time   = @sy-uzeit
              WHERE req_no   = @lv_req_item.
          ELSE.
            CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = 'X'.

            UPDATE zmdg_req_hdr
              SET status     = 'APPROVED',
                  rej_reason = '',
                  approver   = @sy-uname,
                  app_date   = @sy-datum,
                  app_time   = @sy-uzeit
              WHERE req_no   = @lv_req_item.
          ENDIF.

        ENDLOOP.

        IF lv_has_error = abap_true.
          CLEAR ls_resp.
          ls_resp-status  = 'ERROR'.
          ls_resp-message = 'Proses gagal: ' && lv_last_err.
          lv_json = /ui2/cl_json=>serialize( data = ls_resp compress = 'X' pretty_name = /ui2/cl_json=>pretty_mode-low_case ).
        ELSE.
          CLEAR ls_resp.
          ls_resp-status  = 'SUCCESS'.
          ls_resp-message = 'Seluruh data berhasil divalidasi dan di-upload ke SAP S/4HANA!'.
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