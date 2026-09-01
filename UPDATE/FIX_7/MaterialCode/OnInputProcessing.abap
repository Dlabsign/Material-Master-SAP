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
  IF lv_action IS INITIAL.
    lv_action = request->get_form_field( 'action' ).
  ENDIF.

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
      " EXCEL.ABAP & SAP BAPI SIMULATION ENGINE FOR DATA STEWARD CHECK
      " ==================================================================
      DATA: lt_check_dtl   TYPE TABLE OF zmdg_req_dtl,
            ls_check_dtl   TYPE zmdg_req_dtl,
            lv_err_log     TYPE string,
            lv_item_err    TYPE string,
            lv_has_val_err TYPE sap_bool VALUE abap_false.

      DATA: lv_exist_m_c TYPE mara-matnr.

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

        " A. FORMAT & SANITIZE USER INPUTS
        " Format VTWEG (Distribution Channel): Ensure 2 characters (e.g. '1' -> '01')
        IF ls_check_dtl-vtweg IS NOT INITIAL.
          CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
            EXPORTING
              input  = ls_check_dtl-vtweg
            IMPORTING
              output = ls_check_dtl-vtweg.
        ENDIF.

        " B. EXCEL.ABAP & SAP MANDATORY VALIDATION RULES
        " Rule 1 (E01): Classification & UoM Usage (KZWSM) Conflict
        IF ( ls_check_dtl-class IS NOT INITIAL AND ( ls_check_dtl-warna IS NOT INITIAL OR ls_check_dtl-vol_prod IS NOT INITIAL ) )
           AND ls_check_dtl-kzwsm IS NOT INITIAL.
          IF lv_item_err IS NOT INITIAL. lv_item_err = |{ lv_item_err }; |. ENDIF.
          lv_item_err = |{ lv_item_err }[E01] Data Classification & KZWSM tdk boleh diisi bersamaan|.
        ENDIF.

        " Rule 2 (E03): Mandatory Material Type (MTART) & Industry Sector (MBRSH)
        IF ls_check_dtl-mbrsh IS INITIAL OR ls_check_dtl-mtart IS INITIAL.
          IF lv_item_err IS NOT INITIAL. lv_item_err = |{ lv_item_err }; |. ENDIF.
          lv_item_err = |{ lv_item_err }[E03] Material Type (MTART) & Industry Sector (MBRSH) wajib diisi|.
        ENDIF.

        " Rule 3 (E04): Mandatory Plant (WERKS)
        IF ls_check_dtl-werks IS INITIAL.
          IF lv_item_err IS NOT INITIAL. lv_item_err = |{ lv_item_err }; |. ENDIF.
          lv_item_err = |{ lv_item_err }[E04] Plant (WERKS) wajib diisi|.
        ENDIF.

        " Rule 4 (E05): Mandatory Storage Location (LGORT)
        IF ls_check_dtl-lgort IS INITIAL.
          IF lv_item_err IS NOT INITIAL. lv_item_err = |{ lv_item_err }; |. ENDIF.
          lv_item_err = |{ lv_item_err }[E05] Storage Location (LGORT) wajib diisi|.
        ENDIF.

        " Rule 5 (E06): Mandatory Profit Center (PRCTR)
        IF ls_check_dtl-prctr IS INITIAL AND sy-mandt = '300'.
          IF lv_item_err IS NOT INITIAL. lv_item_err = |{ lv_item_err }; |. ENDIF.
          lv_item_err = |{ lv_item_err }[E06] Profit Center (PRCTR) wajib diisi|.
        ENDIF.

        " Rule 6 (E07): Mandatory Material Description (MAKTX)
        IF ls_check_dtl-maktx IS INITIAL.
          IF lv_item_err IS NOT INITIAL. lv_item_err = |{ lv_item_err }; |. ENDIF.
          lv_item_err = |{ lv_item_err }[E07] Material Description (MAKTX) wajib diisi|.
        ENDIF.

        " Rule 7 (E08): Mandatory Base Unit of Measure (MEINS)
        IF ls_check_dtl-meins IS INITIAL.
          IF lv_item_err IS NOT INITIAL. lv_item_err = |{ lv_item_err }; |. ENDIF.
          lv_item_err = |{ lv_item_err }[E08] Base UoM (MEINS) wajib diisi|.
        ENDIF.

        " C. SAP MASTER DATA & TABLE EXISTENCE VALIDATION
        " C1. Table Existence Check - T001W (Plant Master)
        IF ls_check_dtl-werks IS NOT INITIAL.
          IF ls_check_dtl-werks CS '*'.
            IF lv_item_err IS NOT INITIAL. lv_item_err = |{ lv_item_err }; |. ENDIF.
            lv_item_err = |{ lv_item_err }Plant '{ ls_check_dtl-werks }' mengandung karakter tidak valid ('*')|.
          ELSE.
            SELECT SINGLE werks FROM t001w INTO @DATA(lv_dummy_w) WHERE werks = @ls_check_dtl-werks.
            IF sy-subrc <> 0.
              IF lv_item_err IS NOT INITIAL. lv_item_err = |{ lv_item_err }; |. ENDIF.
              lv_item_err = |{ lv_item_err }Plant '{ ls_check_dtl-werks }' tdk ada di master SAP (T001W)|.
            ENDIF.
          ENDIF.
        ENDIF.

        " C2. Table Existence Check - T001L (Storage Location Master)
        IF ls_check_dtl-werks IS NOT INITIAL AND ls_check_dtl-lgort IS NOT INITIAL.
          IF ls_check_dtl-lgort CS '*'.
            IF lv_item_err IS NOT INITIAL. lv_item_err = |{ lv_item_err }; |. ENDIF.
            lv_item_err = |{ lv_item_err }S.Loc '{ ls_check_dtl-lgort }' mengandung karakter tidak valid ('*')|.
          ELSE.
            SELECT SINGLE lgort FROM t001l INTO @DATA(lv_dummy_l) WHERE werks = @ls_check_dtl-werks AND lgort = @ls_check_dtl-lgort.
            IF sy-subrc <> 0.
              IF lv_item_err IS NOT INITIAL. lv_item_err = |{ lv_item_err }; |. ENDIF.
              lv_item_err = |{ lv_item_err }S.Loc '{ ls_check_dtl-lgort }' tdk valid utk Plant '{ ls_check_dtl-werks }' (T001L)|.
            ENDIF.
          ENDIF.
        ENDIF.

        " C3. Base UoM (MEINS) validity & conversion check via CONVERSION_EXIT_CUNIT_INPUT
        IF ls_check_dtl-meins IS NOT INITIAL.
          DATA: lv_meins_conv TYPE mara-meins.
          CLEAR lv_meins_conv.
          CALL FUNCTION 'CONVERSION_EXIT_CUNIT_INPUT'
            EXPORTING
              input          = ls_check_dtl-meins
            IMPORTING
              output         = lv_meins_conv
            EXCEPTIONS
              UNIT_NOT_FOUND = 1
              OTHERS         = 2.
          IF sy-subrc <> 0 OR lv_meins_conv IS INITIAL.
            IF lv_item_err IS NOT INITIAL. lv_item_err = |{ lv_item_err }; |. ENDIF.
            lv_item_err = |{ lv_item_err }Base UoM '{ ls_check_dtl-meins }' tdk terdaftar di master SAP (T006)|.
          ENDIF.
        ENDIF.

        " C4. Material Group (MATKL) existence check in T023
        IF ls_check_dtl-matkl IS NOT INITIAL.
          IF ls_check_dtl-matkl CS '*'.
            IF lv_item_err IS NOT INITIAL. lv_item_err = |{ lv_item_err }; |. ENDIF.
            lv_item_err = |{ lv_item_err }Material Group '{ ls_check_dtl-matkl }' mengandung karakter tidak valid ('*')|.
          ELSE.
            SELECT SINGLE matkl FROM t023 INTO @DATA(lv_dum_matkl) WHERE matkl = @ls_check_dtl-matkl.
            IF sy-subrc <> 0.
              IF lv_item_err IS NOT INITIAL. lv_item_err = |{ lv_item_err }; |. ENDIF.
              lv_item_err = |{ lv_item_err }Material Group '{ ls_check_dtl-matkl }' tdk terdaftar di SAP (T023)|.
            ENDIF.
          ENDIF.
        ENDIF.

        " C5. Distribution Channel (VTWEG) existence check in TVTW
        IF ls_check_dtl-vtweg IS NOT INITIAL.
          SELECT SINGLE vtweg FROM tvtw INTO @DATA(lv_dum_vtweg) WHERE vtweg = @ls_check_dtl-vtweg.
          IF sy-subrc <> 0.
            IF lv_item_err IS NOT INITIAL. lv_item_err = |{ lv_item_err }; |. ENDIF.
            lv_item_err = |{ lv_item_err }Distribution Channel '{ ls_check_dtl-vtweg }' tdk terdaftar di SAP (TVTW)|.
          ENDIF.
        ENDIF.

        " C6. Sales Org (VKORG) existence check in TVKO
        IF ls_check_dtl-vkorg IS NOT INITIAL.
          SELECT SINGLE vkorg FROM tvko INTO @DATA(lv_dum_vkorg) WHERE vkorg = @ls_check_dtl-vkorg.
          IF sy-subrc <> 0.
            IF lv_item_err IS NOT INITIAL. lv_item_err = |{ lv_item_err }; |. ENDIF.
            lv_item_err = |{ lv_item_err }Sales Org '{ ls_check_dtl-vkorg }' tdk terdaftar di SAP (TVKO)|.
          ENDIF.
        ENDIF.

        " C7. Valuation Class (BKLAS) existence check in T025
        IF ls_check_dtl-bklas IS NOT INITIAL.
          IF ls_check_dtl-bklas CS '*'.
            IF lv_item_err IS NOT INITIAL. lv_item_err = |{ lv_item_err }; |. ENDIF.
            lv_item_err = |{ lv_item_err }Valuation Class '{ ls_check_dtl-bklas }' mengandung karakter tidak valid ('*')|.
          ELSE.
            SELECT SINGLE bklas FROM t025 INTO @DATA(lv_dum_bklas) WHERE bklas = @ls_check_dtl-bklas.
            IF sy-subrc <> 0.
              IF lv_item_err IS NOT INITIAL. lv_item_err = |{ lv_item_err }; |. ENDIF.
              lv_item_err = |{ lv_item_err }Valuation Class '{ ls_check_dtl-bklas }' tdk terdaftar di SAP (T025)|.
            ENDIF.
          ENDIF.
        ENDIF.

        " C8. Purchasing Group (EKGRP) existence check in T024
        IF ls_check_dtl-ekgrp IS NOT INITIAL.
          SELECT SINGLE ekgrp FROM t024 INTO @DATA(lv_dum_ekgrp) WHERE ekgrp = @ls_check_dtl-ekgrp.
          IF sy-subrc <> 0.
            IF lv_item_err IS NOT INITIAL. lv_item_err = |{ lv_item_err }; |. ENDIF.
            lv_item_err = |{ lv_item_err }Purchasing Group '{ ls_check_dtl-ekgrp }' tdk terdaftar di SAP (T024)|.
          ENDIF.
        ENDIF.

        " C9. MRP Controller (DISPO) existence check in T024D for Plant
        IF ls_check_dtl-dispo IS NOT INITIAL AND ls_check_dtl-werks IS NOT INITIAL.
          SELECT SINGLE dispo FROM t024d INTO @DATA(lv_dum_dispo) WHERE werks = @ls_check_dtl-werks AND dispo = @ls_check_dtl-dispo.
          IF sy-subrc <> 0.
            IF lv_item_err IS NOT INITIAL. lv_item_err = |{ lv_item_err }; |. ENDIF.
            lv_item_err = |{ lv_item_err }MRP Controller '{ ls_check_dtl-dispo }' tdk terdaftar utk Plant '{ ls_check_dtl-werks }' (T024D)|.
          ENDIF.
        ENDIF.

        " C10. Variance Key (KLRAB / MARC-AWSLS) validity check
        IF ls_check_dtl-klrab IS NOT INITIAL.
          IF ls_check_dtl-klrab = 'X' OR ls_check_dtl-klrab = 'x'.
            CLEAR ls_check_dtl-klrab.
          ELSEIF strlen( ls_check_dtl-klrab ) < 2.
            IF lv_item_err IS NOT INITIAL. lv_item_err = |{ lv_item_err }; |. ENDIF.
            lv_item_err = |{ lv_item_err }Variance Key '{ ls_check_dtl-klrab }' tidak valid untuk field MARC-AWSLS|.
          ENDIF.
        ENDIF.

        " C11. Masked/Corrupted Field Check ('*')
        IF ls_check_dtl-matnr_ext CS '*' OR ls_check_dtl-maktx CS '*'.
          IF lv_item_err IS NOT INITIAL. lv_item_err = |{ lv_item_err }; |. ENDIF.
          lv_item_err = |{ lv_item_err }Field mengandung karakter tidak valid/terdistorsi ('*')|.
        ENDIF.

        " C12. Prod. Storage Location (LGPRO) check in T001L for Plant
        IF ls_check_dtl-lgpro IS NOT INITIAL AND ls_check_dtl-werks IS NOT INITIAL.
          SELECT SINGLE lgort FROM t001l INTO @DATA(lv_dum_lgpro) WHERE werks = @ls_check_dtl-werks AND lgort = @ls_check_dtl-lgpro.
          IF sy-subrc <> 0.
            IF lv_item_err IS NOT INITIAL. lv_item_err = |{ lv_item_err }; |. ENDIF.
            lv_item_err = |{ lv_item_err }Prod. S.Loc '{ ls_check_dtl-lgpro }' tdk terdaftar utk Plant '{ ls_check_dtl-werks }' (T001L)|.
          ENDIF.
        ENDIF.

        " C13. MRP Group (DISGR) check in T438M for Plant
        IF ls_check_dtl-disgr IS NOT INITIAL AND ls_check_dtl-werks IS NOT INITIAL.
          SELECT SINGLE disgr FROM t438m INTO @DATA(lv_dum_disgr) WHERE werks = @ls_check_dtl-werks AND disgr = @ls_check_dtl-disgr.
          IF sy-subrc <> 0.
            IF lv_item_err IS NOT INITIAL. lv_item_err = |{ lv_item_err }; |. ENDIF.
            lv_item_err = |{ lv_item_err }MRP Group '{ ls_check_dtl-disgr }' tdk terdaftar utk Plant '{ ls_check_dtl-werks }' (T438M)|.
          ENDIF.
        ENDIF.

        " C14. Origin Group (HERBL / HRKFT) check in TKOF for Plant
        IF ls_check_dtl-herbl IS NOT INITIAL AND ls_check_dtl-werks IS NOT INITIAL.
          SELECT SINGLE hrkft FROM tkof INTO @DATA(lv_dum_herbl) WHERE bwkey = @ls_check_dtl-werks AND hrkft = @ls_check_dtl-herbl.
          IF sy-subrc <> 0.
            IF lv_item_err IS NOT INITIAL. lv_item_err = |{ lv_item_err }; |. ENDIF.
            lv_item_err = |{ lv_item_err }Origin Group '{ ls_check_dtl-herbl }' tdk terdaftar utk Plant '{ ls_check_dtl-werks }' (TKOF)|.
          ENDIF.
        ENDIF.

        " C12. Manual Material Code MARA Duplicate Check
        IF ls_check_dtl-matnr_ext IS NOT INITIAL AND NOT ls_check_dtl-matnr_ext CS '*'.
          CLEAR lv_exist_m_c.
          SELECT SINGLE matnr FROM mara INTO @lv_exist_m_c WHERE matnr = @ls_check_dtl-matnr_ext.
          IF sy-subrc = 0.
            IF lv_item_err IS NOT INITIAL. lv_item_err = |{ lv_item_err }; |. ENDIF.
            lv_item_err = |{ lv_item_err }Kode Material '{ ls_check_dtl-matnr_ext }' sudah terdaftar di MARA SAP|.
          ENDIF.
        ENDIF.

        " Accumulate Item Error
        IF lv_item_err IS NOT INITIAL.
          lv_has_val_err = abap_true.
          IF lv_err_log IS NOT INITIAL.
            lv_err_log = |{ lv_err_log } \n |.
          ENDIF.
          lv_err_log = |{ lv_err_log }Item #{ lv_item_num } ({ ls_check_dtl-maktx }): { lv_item_err }|.
        ELSE.
          " D. PRESERVE EXACT EXCEL INPUT DATA WITHOUT OVERRIDING WITH HARDCODED DEFAULTS
          " Clear invalid Variance Key if present ('X' is not a valid SAP variance key)
          IF ls_check_dtl-klrab = 'X' OR ls_check_dtl-klrab = 'x'. CLEAR ls_check_dtl-klrab. ENDIF.

          " Format TRAGR & LADGR (e.g. '1' -> '0001')
          IF ls_check_dtl-tragr IS NOT INITIAL.
            CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
              EXPORTING input = ls_check_dtl-tragr
              IMPORTING output = ls_check_dtl-tragr.
          ENDIF.
          IF ls_check_dtl-ladgr IS NOT INITIAL.
            CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
              EXPORTING input = ls_check_dtl-ladgr
              IMPORTING output = ls_check_dtl-ladgr.
          ENDIF.

          " Save sanitized fields back to database
          UPDATE zmdg_req_dtl
            SET mbrsh     = @ls_check_dtl-mbrsh,
                mtart     = @ls_check_dtl-mtart,
                werks     = @ls_check_dtl-werks,
                lgort     = @ls_check_dtl-lgort,
                prctr     = @ls_check_dtl-prctr,
                dismm     = @ls_check_dtl-dismm,
                mtvfp     = @ls_check_dtl-mtvfp,
                ekgrp     = @ls_check_dtl-ekgrp,
                dispo     = @ls_check_dtl-dispo,
                disls     = @ls_check_dtl-disls,
                beskz     = @ls_check_dtl-beskz,
                ladgr     = @ls_check_dtl-ladgr,
                tragr     = @ls_check_dtl-tragr,
                bklas     = @ls_check_dtl-bklas,
                vtweg     = @ls_check_dtl-vtweg,
                klrab     = @ls_check_dtl-klrab
            WHERE req_no  = @ls_check_dtl-req_no
              AND item_no = @ls_check_dtl-item_no.
        ENDIF.
      ENDLOOP.

      " IF ANY ITEM FAILS VALIDATION -> HOLD IN SYSTEM
      IF lv_has_val_err = abap_true.
        DATA: lv_auto_hold_reason TYPE string.
        lv_auto_hold_reason = |[HOLD VALIDASI MASTER SAP] { lv_err_log }|.

        " Update Header Status to HOLD
        UPDATE zmdg_req_hdr
          SET status     = 'HOLD',
              rej_reason = @lv_auto_hold_reason,
              approver   = @sy-uname,
              app_date   = @sy-datum,
              app_time   = @sy-uzeit
          WHERE req_no   = @lv_req_no.

        TYPES: BEGIN OF ty_err_json,
                 status     TYPE string,
                 message    TYPE string,
                 rej_reason TYPE string,
               END OF ty_err_json.
        DATA: ls_err_json TYPE ty_err_json.

        ls_err_json-status     = 'HOLD'.
        ls_err_json-message    = |Dokumen { lv_req_no } di-hold pada sistem karena terdapat data yang tidak sesuai validasi master SAP.|.
        ls_err_json-rej_reason = lv_auto_hold_reason.

        lv_json = /ui2/cl_json=>serialize( data = ls_err_json compress = 'X' pretty_name = /ui2/cl_json=>pretty_mode-low_case ).
        _m_response->set_content_type( 'application/json' ).
        _m_response->set_cdata( lv_json ).
        navigation->goto_page( '' ).
        RETURN.
      ENDIF.

      " IF ALL ITEMS ARE VALID -> MARK AS CHECKED & FORWARD TO APPROVAL
      UPDATE zmdg_req_hdr
        SET status     = 'CHECKED',
            rej_reason = ''
        WHERE req_no   = @lv_req_no.

      lv_json = |\{"status":"SUCCESS","message":"Request { lv_req_no } telah berhasil lolos seluruh validasi master SAP dan diteruskan ke Approval (stagging_list.htm)!"\}|.
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

      lv_requestor = ls_hdr-requestor.

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
    " 6. SEARCH SAP MARA RECORDS
    " ==================================================================
    WHEN 'SEARCH_MARA'.
      DATA: lv_str_matnr     TYPE string,
            lv_str_maktx     TYPE string,
            lv_str_mtart     TYPE string,
            lv_str_matkl     TYPE string,
            lv_filter_matnr  TYPE char40,
            lv_filter_maktx  TYPE char40,
            lv_filter_mtart  TYPE mara-mtart,
            lv_filter_matkl  TYPE char10,
            lv_pattern_matnr TYPE char50,
            lv_pattern_maktx TYPE char50,
            lv_pattern_matkl TYPE char20,
            lv_matnr_padded  TYPE mara-matnr.

      TYPES: BEGIN OF ty_mara_res,
               matnr TYPE mara-matnr,
               maktx TYPE makt-maktx,
               mtart TYPE mara-mtart,
               matkl TYPE mara-matkl,
               meins TYPE mara-meins,
               bismt TYPE mara-bismt,
               mbrsh TYPE mara-mbrsh,
               spart TYPE mara-spart,
             END OF ty_mara_res.

      DATA: lt_mara_res TYPE TABLE OF ty_mara_res,
            ls_mara_res TYPE ty_mara_res.

      lv_str_matnr = request->get_form_field( 'FILTER_MATNR' ).
      lv_str_maktx = request->get_form_field( 'FILTER_MAKTX' ).
      lv_str_mtart = request->get_form_field( 'FILTER_MTART' ).
      lv_str_matkl = request->get_form_field( 'FILTER_MATKL' ).

      TRANSLATE lv_str_matnr TO UPPER CASE.
      TRANSLATE lv_str_maktx TO UPPER CASE.
      TRANSLATE lv_str_mtart TO UPPER CASE.
      TRANSLATE lv_str_matkl TO UPPER CASE.

      CONDENSE lv_str_matnr.
      CONDENSE lv_str_maktx.
      CONDENSE lv_str_mtart.
      CONDENSE lv_str_matkl.

      lv_filter_matnr = lv_str_matnr.
      lv_filter_maktx = lv_str_maktx.
      lv_filter_mtart = lv_str_mtart.
      lv_filter_matkl = lv_str_matkl.

      IF lv_filter_matnr IS NOT INITIAL.
        CONCATENATE '%' lv_str_matnr '%' INTO lv_pattern_matnr.
        IF lv_str_matnr CO '0123456789'.
          lv_matnr_padded = lv_str_matnr.
          CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
            EXPORTING
              input  = lv_matnr_padded
            IMPORTING
              output = lv_matnr_padded.
        ENDIF.
      ENDIF.

      IF lv_filter_maktx IS NOT INITIAL.
        CONCATENATE '%' lv_str_maktx '%' INTO lv_pattern_maktx.
      ENDIF.

      IF lv_filter_matkl IS NOT INITIAL.
        CONCATENATE '%' lv_str_matkl '%' INTO lv_pattern_matkl.
      ENDIF.

      SELECT a~matnr, b~maktx, a~mtart, a~matkl, a~meins, a~bismt, a~mbrsh, a~spart
        FROM mara AS a
        LEFT OUTER JOIN makt AS b ON a~matnr = b~matnr AND b~spras = @sy-langu
        WHERE ( @lv_filter_matnr IS INITIAL OR a~matnr LIKE @lv_pattern_matnr OR ( @lv_matnr_padded IS NOT INITIAL AND a~matnr = @lv_matnr_padded ) )
          AND ( @lv_filter_maktx IS INITIAL OR b~maktx LIKE @lv_pattern_maktx )
          AND ( @lv_filter_mtart IS INITIAL OR a~mtart = @lv_filter_mtart )
          AND ( @lv_filter_matkl IS INITIAL OR a~matkl LIKE @lv_pattern_matkl )
        INTO TABLE @lt_mara_res
        UP TO 200 ROWS.

      lv_json = /ui2/cl_json=>serialize( data = lt_mara_res compress = 'X' pretty_name = /ui2/cl_json=>pretty_mode-low_case ).
      _m_response->set_content_type( 'application/json' ).
      _m_response->set_cdata( lv_json ).
      navigation->goto_page( '' ).
      RETURN.

    " ==================================================================
    " 7. LOGOUT
    " ==================================================================
    WHEN 'LOGOUT'.
      navigation->exit( ).
      RETURN.

  ENDCASE.
