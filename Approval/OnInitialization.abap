DATA: lv_action   TYPE string,
      lv_json     TYPE string,
      lv_req_no   TYPE string,
      lv_req_nos  TYPE string,
      lv_reason   TYPE string.

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
      lv_matnr_chk    TYPE matnr.

" Struktur & Variabel BAPI Material Master
TYPES: BEGIN OF ty_bapi_meinspect,
         plant     TYPE werks_d,
         insp_type TYPE c LENGTH 2,
         active    TYPE c LENGTH 1,
       END OF ty_bapi_meinspect.

DATA: lt_inspectiontype       TYPE TABLE OF ty_bapi_meinspect,
      ls_inspectiontype       TYPE ty_bapi_meinspect,
      ls_headdata             TYPE bapimathead,
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
      lt_taxclassifications   TYPE TABLE OF bapi_mlan,
      ls_taxclassifications   TYPE bapi_mlan,
      lt_unitsofmeasure       TYPE TABLE OF bapi_marm,
      ls_unitsofmeasure       TYPE bapi_marm,
      lt_unitsofmeasurex      TYPE TABLE OF bapi_marmx,
      ls_unitsofmeasurex      TYPE bapi_marmx,

      lt_materiallongtext     TYPE TABLE OF bapi_mltx,
      ls_materiallongtext     TYPE bapi_mltx,
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

" Remove sy-uname hardcoded restriction to allow all authorized SAP users to approve requests
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
        ls_list-sub_reason = CONV #( ls_hdr_db-sub_reason ).
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

          " A. AUTOMATIC MATERIAL NUMBER RESOLUTION (18-CHAR MATN1 CONVERSION CHECK)
          CLEAR lv_exist_mara.
          IF ls_dtl_db-matnr_ext IS NOT INITIAL.
            CLEAR lv_matnr_chk.
            CALL FUNCTION 'CONVERSION_EXIT_MATN1_INPUT'
              EXPORTING
                input        = ls_dtl_db-matnr_ext
              IMPORTING
                output       = lv_matnr_chk
              EXCEPTIONS
                OTHERS       = 1.
            IF lv_matnr_chk IS INITIAL.
              lv_matnr_chk = ls_dtl_db-matnr_ext.
            ENDIF.
            SELECT SINGLE matnr FROM mara INTO @lv_exist_mara WHERE matnr = @lv_matnr_chk.
          ENDIF.

          IF ls_dtl_db-matnr_ext IS INITIAL OR ls_dtl_db-matnr_ext CO '0 ' OR ls_dtl_db-matnr_ext = '0' OR sy-subrc = 0.
            " Jika nomor belum ada ATAU bernilai 0 ATAU nomor lama sudah terdaftar di MARA, cari nomor baru
            CLEAR: lv_is_available, lv_next_number, lt_check_return.

            IF ls_dtl_db-mtart IS INITIAL.
              ls_dtl_db-mtart = 'ZOS3'.
            ENDIF.

            CALL FUNCTION 'ZFM_CHECK_MATERIAL'
              EXPORTING
                iv_mtart        = ls_dtl_db-mtart
              IMPORTING
                ev_is_available = lv_is_available
                ev_next_number  = lv_next_number
                et_return       = lt_check_return
              EXCEPTIONS
                OTHERS          = 1.

            IF ( lv_next_number IS INITIAL OR lv_next_number CO '0 ' ) AND ls_dtl_db-matnr_ext IS NOT INITIAL AND ls_dtl_db-matnr_ext CN '0 '.
              lv_next_number = ls_dtl_db-matnr_ext.
            ENDIF.

            " Pastikan lv_next_number belum terdaftar di MARA (menggunakan konversi MATN1 18-digit)
            IF lv_next_number IS NOT INITIAL.
              DO 100 TIMES.
                CLEAR: lv_exist_mara, lv_matnr_chk.
                CALL FUNCTION 'CONVERSION_EXIT_MATN1_INPUT'
                  EXPORTING
                    input        = lv_next_number
                  IMPORTING
                    output       = lv_matnr_chk
                  EXCEPTIONS
                    OTHERS       = 1.
                IF lv_matnr_chk IS INITIAL.
                  lv_matnr_chk = lv_next_number.
                ENDIF.

                SELECT SINGLE matnr FROM mara INTO @lv_exist_mara WHERE matnr = @lv_matnr_chk.
                IF sy-subrc <> 0.
                  " Nomor ini BEBAS (belum terdaftar di MARA)
                  EXIT.
                ELSE.
                  " Jika nomor sudah ada di MARA, increment nomor 1 tingkat secara aman tanpa integer overflow
                  IF lv_next_number IS NOT INITIAL AND lv_next_number CO '0123456789'.
                    DATA: lv_num_num TYPE n LENGTH 18.
                    lv_num_num = lv_next_number.
                    lv_num_num = lv_num_num + 1.
                    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
                      EXPORTING
                        input  = lv_num_num
                      IMPORTING
                        output = lv_next_number.
                  ELSE.
                    CALL FUNCTION 'ZFM_CHECK_MATERIAL'
                      EXPORTING
                        iv_mtart        = ls_dtl_db-mtart
                      IMPORTING
                        ev_is_available = lv_is_available
                        ev_next_number  = lv_next_number
                        et_return       = lt_check_return
                      EXCEPTIONS
                        OTHERS          = 1.
                  ENDIF.
                ENDIF.
              ENDDO.

              ls_dtl_db-matnr_ext = lv_next_number.

              " Update nomor baru ke tabel staging detail
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

          " B. VALIDASI & DEFAULT MANDATORY FIELDS
          IF ls_dtl_db-mbrsh IS INITIAL.
            ls_dtl_db-mbrsh = 'M'.
          ENDIF.

          IF ls_dtl_db-mtart IS INITIAL.
            ls_dtl_db-mtart = 'ZOS3'.
          ENDIF.

          IF ls_dtl_db-werks IS INITIAL.
            ls_dtl_db-werks = '1200'.
          ENDIF.

          IF ls_dtl_db-lgort IS INITIAL.
            ls_dtl_db-lgort = '1201'.
          ENDIF.

          IF ls_dtl_db-vkorg IS INITIAL.
            ls_dtl_db-vkorg = '1000'.
          ENDIF.

          IF ls_dtl_db-vtweg IS INITIAL.
            ls_dtl_db-vtweg = '10'.
          ENDIF.

          IF ls_dtl_db-dwerk IS INITIAL.
            ls_dtl_db-dwerk = ls_dtl_db-werks.
          ENDIF.

          IF ls_dtl_db-herkl IS INITIAL.
            ls_dtl_db-herkl = 'ID'.
          ENDIF.

          IF ls_dtl_db-taxkm IS INITIAL.
            ls_dtl_db-taxkm = '1'.
          ENDIF.

          IF ls_dtl_db-tatyp IS INITIAL.
            ls_dtl_db-tatyp = 'MWST'.
          ENDIF.

          IF sy-mandt = '300' AND ls_dtl_db-prctr IS INITIAL.
            ls_dtl_db-prctr = '200201'.
          ENDIF.

          " C. VERIFIKASI AKHIR DUPLIKASI KODE DI TABEL MARA (DENGAN KONVERSI MATN1 18-DIGIT)
          CLEAR: lv_exist_mara, lv_matnr_chk.
          CALL FUNCTION 'CONVERSION_EXIT_MATN1_INPUT'
            EXPORTING
              input        = ls_dtl_db-matnr_ext
            IMPORTING
              output       = lv_matnr_chk
            EXCEPTIONS
              OTHERS       = 1.
          IF lv_matnr_chk IS INITIAL.
            lv_matnr_chk = ls_dtl_db-matnr_ext.
          ENDIF.

          SELECT SINGLE matnr FROM mara INTO @lv_exist_mara WHERE matnr = @lv_matnr_chk.
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
                 ls_bapireturn, lt_materialdesc, lt_taxclassifications,
                 lt_unitsofmeasure, lt_unitsofmeasurex,
                 lt_inspectiontype, lt_materiallongtext, lt_returnmes.

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
          ls_headdata-material_long = ls_dtl_db-matnr_ext.

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
            ls_headdata-cost_view    = 'X'.
            IF ls_dtl_db-dismm IS NOT INITIAL OR ls_dtl_db-beskz IS NOT INITIAL OR ls_dtl_db-mtvfp IS NOT INITIAL.
              ls_headdata-mrp_view = 'X'.
            ENDIF.
          ENDIF.

          IF ls_dtl_db-vkorg IS NOT INITIAL AND ls_dtl_db-vtweg IS NOT INITIAL.
            ls_headdata-sales_view = 'X'.
          ENDIF.

          IF ls_dtl_db-ssqss IS NOT INITIAL OR ls_dtl_db-insptype IS NOT INITIAL OR ls_dtl_db-werks IS NOT INITIAL.
            ls_headdata-quality_view = 'X'.
          ENDIF.

          " MARA Client Data Mapping
          IF ls_dtl_db-matkl IS NOT INITIAL.
            ls_clientdata-matl_group  = ls_dtl_db-matkl.
            ls_clientdatax-matl_group = 'X'.
          ENDIF.

          IF ls_dtl_db-mtpos_mara IS NOT INITIAL.
            ls_clientdata-item_cat  = ls_dtl_db-mtpos_mara.
            ls_clientdatax-item_cat = 'X'.
          ENDIF.

          IF ls_dtl_db-spart IS NOT INITIAL.
            ls_clientdata-division  = ls_dtl_db-spart.
            ls_clientdatax-division = 'X'.
          ENDIF.

          IF ls_dtl_db-bismt IS NOT INITIAL.
            ls_clientdata-old_mat_no  = ls_dtl_db-bismt.
            ls_clientdatax-old_mat_no = 'X'.
          ENDIF.

          IF ls_dtl_db-ferth IS NOT INITIAL.
            ls_clientdata-prod_memo  = ls_dtl_db-ferth.
            ls_clientdatax-prod_memo = 'X'.
          ENDIF.

          IF ls_dtl_db-zeinr IS NOT INITIAL.
            ls_clientdata-document  = ls_dtl_db-zeinr.
            ls_clientdatax-document = 'X'.
          ENDIF.

          IF ls_dtl_db-normt IS NOT INITIAL.
            ls_clientdata-std_descr  = ls_dtl_db-normt.
            ls_clientdatax-std_descr = 'X'.
          ENDIF.

          IF ls_dtl_db-groes IS NOT INITIAL.
            ls_clientdata-size_dim  = ls_dtl_db-groes.
            ls_clientdatax-size_dim = 'X'.
          ENDIF.



          IF ls_dtl_db-magrv IS NOT INITIAL.
            ls_clientdata-mat_grp_sm  = ls_dtl_db-magrv.
            ls_clientdatax-mat_grp_sm = 'X'.
          ENDIF.

          IF ls_dtl_db-tragr IS NOT INITIAL.
            ls_clientdata-trans_grp  = ls_dtl_db-tragr.
            ls_clientdatax-trans_grp = 'X'.
          ELSE.
            ls_clientdata-trans_grp  = '0001'.
            ls_clientdatax-trans_grp = 'X'.
          ENDIF.

          IF ls_dtl_db-xchpf = 'X' OR ls_dtl_db-xchpf IS INITIAL.
            ls_clientdata-batch_mgmt  = 'X'.
            ls_clientdatax-batch_mgmt = 'X'.
          ELSE.
            ls_clientdata-batch_mgmt  = ls_dtl_db-xchpf.
            ls_clientdatax-batch_mgmt = 'X'.
          ENDIF.

          IF ls_dtl_db-gewei IS NOT INITIAL.
            CALL FUNCTION 'CONVERSION_EXIT_CUNIT_INPUT'
              EXPORTING
                input  = ls_dtl_db-gewei
              IMPORTING
                output = ls_clientdata-unit_of_wt
              EXCEPTIONS
                OTHERS = 1.
            IF ls_clientdata-unit_of_wt IS INITIAL.
              ls_clientdata-unit_of_wt = ls_dtl_db-gewei.
            ENDIF.
            ls_clientdata-unit_of_wt_iso  = ls_clientdata-unit_of_wt.
            ls_clientdatax-unit_of_wt     = 'X'.
            ls_clientdatax-unit_of_wt_iso = 'X'.
          ENDIF.

          IF ls_dtl_db-ntgew IS NOT INITIAL.
            ls_clientdata-net_weight  = ls_dtl_db-ntgew.
            ls_clientdatax-net_weight = 'X'.
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

          " MARC Plant Data Mapping
          ls_plantdata-plant     = ls_dtl_db-werks.
          ls_plantdatax-plant    = ls_dtl_db-werks.

          " 1. MRP Type (MARC-DISMM)
          IF ls_dtl_db-dismm IS NOT INITIAL.
            ls_plantdata-mrp_type  = ls_dtl_db-dismm.
          ELSE.
            ls_plantdata-mrp_type  = 'PD'.
          ENDIF.
          ls_plantdatax-mrp_type = 'X'.

          " 2. Availability Check (MARC-MTVFP)
          IF ls_dtl_db-mtvfp IS NOT INITIAL.
            ls_plantdata-availcheck  = ls_dtl_db-mtvfp.
          ELSE.
            ls_plantdata-availcheck  = 'KP'.
          ENDIF.
          ls_plantdatax-availcheck = 'X'.

          " 3. Purchasing Group (MARC-EKGRP)
          IF ls_dtl_db-ekgrp IS NOT INITIAL.
            ls_plantdata-pur_group  = ls_dtl_db-ekgrp.
            ls_plantdatax-pur_group = 'X'.
          ENDIF.

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

          " Additional Plant Level Mappings
          IF ls_dtl_db-sobsl IS NOT INITIAL.
            ls_plantdata-specprocty  = ls_dtl_db-sobsl.
            ls_plantdatax-specprocty = 'X'.
          ENDIF.

          IF ls_dtl_db-dzeit IS NOT INITIAL AND ls_dtl_db-dzeit <> 0.
            ls_plantdata-inhseprodt  = ls_dtl_db-dzeit.
            ls_plantdatax-inhseprodt = 'X'.
          ENDIF.

          IF ls_dtl_db-plifz IS NOT INITIAL AND ls_dtl_db-plifz <> 0.
            ls_plantdata-plnd_delry  = ls_dtl_db-plifz.
            ls_plantdatax-plnd_delry = 'X'.
          ENDIF.

          IF ls_dtl_db-webaz IS NOT INITIAL AND ls_dtl_db-webaz <> 0.
            ls_plantdata-gr_pr_time  = ls_dtl_db-webaz.
            ls_plantdatax-gr_pr_time = 'X'.
          ENDIF.

          IF ls_dtl_db-eisbe IS NOT INITIAL AND ls_dtl_db-eisbe <> 0.
            ls_plantdata-safety_stk  = ls_dtl_db-eisbe.
            ls_plantdatax-safety_stk = 'X'.
          ENDIF.

          IF ls_dtl_db-lgpro IS NOT INITIAL.
            ls_plantdata-iss_st_loc  = ls_dtl_db-lgpro.
            ls_plantdatax-iss_st_loc = 'X'.
          ENDIF.

          IF ls_dtl_db-lgpro_ep IS NOT INITIAL AND ls_dtl_db-lgpro_ep <> '0'.
            ls_plantdata-sloc_exprc  = ls_dtl_db-lgpro_ep.
            ls_plantdatax-sloc_exprc = 'X'.
          ENDIF.

          IF ls_dtl_db-rgekz IS NOT INITIAL.
            ls_plantdata-backflush  = ls_dtl_db-rgekz.
            ls_plantdatax-backflush = 'X'.
          ENDIF.

          IF ls_dtl_db-fhori IS NOT INITIAL.
            ls_plantdata-sm_key  = ls_dtl_db-fhori.
            ls_plantdatax-sm_key = 'X'.
          ENDIF.

          IF ls_dtl_db-eprio IS NOT INITIAL.
            ls_plantdata-determ_grp  = ls_dtl_db-eprio.
            ls_plantdatax-determ_grp = 'X'.
          ENDIF.

          IF ls_dtl_db-strgr IS NOT INITIAL.
            ls_plantdata-plan_strgp  = ls_dtl_db-strgr.
            ls_plantdatax-plan_strgp = 'X'.
          ENDIF.

          IF ls_dtl_db-kzkst IS NOT INITIAL.
            ls_plantdata-dep_req_id  = ls_dtl_db-kzkst.
            ls_plantdatax-dep_req_id = 'X'.
          ENDIF.

          IF ls_dtl_db-sfpro IS NOT INITIAL 
             AND ls_dtl_db-sfpro <> '0' 
             AND ls_dtl_db-sfpro <> '00' 
             AND ls_dtl_db-sfpro <> '000000' 
             AND ls_dtl_db-sfpro CN '0 '.
            ls_plantdata-prodprof  = ls_dtl_db-sfpro.
            ls_plantdatax-prodprof = 'X'.
          ENDIF.

          IF ls_dtl_db-xchpf = 'X' OR ls_dtl_db-xchpf IS INITIAL.
            ls_plantdata-batch_mgmt  = 'X'.
            ls_plantdatax-batch_mgmt = 'X'.
          ELSE.
            ls_plantdata-batch_mgmt  = ls_dtl_db-xchpf.
            ls_plantdatax-batch_mgmt = 'X'.
          ENDIF.

          IF ls_dtl_db-ueeto IS NOT INITIAL.
            ls_plantdata-over_tol  = ls_dtl_db-ueeto.
            ls_plantdatax-over_tol = 'X'.
          ENDIF.

          IF ls_dtl_db-ueetk IS NOT INITIAL.
            ls_plantdata-unlimited  = ls_dtl_db-ueetk.
            ls_plantdatax-unlimited = 'X'.
          ENDIF.

          IF ls_dtl_db-uneto IS NOT INITIAL.
            ls_plantdata-under_tol  = ls_dtl_db-uneto.
            ls_plantdatax-under_tol = 'X'.
          ENDIF.

          IF ls_dtl_db-sernp IS NOT INITIAL.
            ls_plantdata-serno_prof  = ls_dtl_db-sernp.
            ls_plantdatax-serno_prof = 'X'.
          ENDIF.

          IF ls_dtl_db-mmsta IS NOT INITIAL.
            ls_plantdata-pur_status  = ls_dtl_db-mmsta.
            ls_plantdatax-pur_status = 'X'.
          ENDIF.

          FIELD-SYMBOLS: <fs_stawn_val> TYPE any.
          ASSIGN COMPONENT 'STAWN' OF STRUCTURE ls_dtl_db TO <fs_stawn_val>.
          IF sy-subrc = 0 AND <fs_stawn_val> IS ASSIGNED AND <fs_stawn_val> IS NOT INITIAL.
            ls_plantdata-comm_code  = <fs_stawn_val>.
            ls_plantdatax-comm_code = 'X'.
          ENDIF.

          IF ls_dtl_db-bstmi IS NOT INITIAL.
            ls_plantdata-minlotsize  = ls_dtl_db-bstmi.
            ls_plantdatax-minlotsize = 'X'.
          ENDIF.

          IF ls_dtl_db-ncost = 'X' OR ls_dtl_db-ncost = '1'.
            ls_plantdata-no_costing  = 'X'.
            ls_plantdatax-no_costing = 'X'.
          ELSEIF ls_dtl_db-ekalr IS NOT INITIAL.
            ls_plantdata-no_costing  = ls_dtl_db-ekalr.
            ls_plantdatax-no_costing = 'X'.
          ENDIF.

          IF ls_dtl_db-hkmat IS NOT INITIAL.
            FIELD-SYMBOLS: <fs_mat_orig> TYPE any, <fs_mat_origx> TYPE any.
            ASSIGN COMPONENT 'ORIGIN_MAT' OF STRUCTURE ls_plantdata TO <fs_mat_orig>.
            IF sy-subrc <> 0.
              ASSIGN COMPONENT 'MAT_ORIGIN' OF STRUCTURE ls_plantdata TO <fs_mat_orig>.
            ENDIF.
            IF sy-subrc <> 0.
              ASSIGN COMPONENT 'HKMAT' OF STRUCTURE ls_plantdata TO <fs_mat_orig>.
            ENDIF.
            IF sy-subrc = 0 AND <fs_mat_orig> IS ASSIGNED.
              <fs_mat_orig> = ls_dtl_db-hkmat.
              ASSIGN COMPONENT 'ORIGIN_MAT' OF STRUCTURE ls_plantdatax TO <fs_mat_origx>.
              IF sy-subrc <> 0.
                ASSIGN COMPONENT 'MAT_ORIGIN' OF STRUCTURE ls_plantdatax TO <fs_mat_origx>.
              ENDIF.
              IF sy-subrc <> 0.
                ASSIGN COMPONENT 'HKMAT' OF STRUCTURE ls_plantdatax TO <fs_mat_origx>.
              ENDIF.
              IF sy-subrc = 0 AND <fs_mat_origx> IS ASSIGNED.
                <fs_mat_origx> = 'X'.
              ENDIF.
            ENDIF.
          ENDIF.

          IF ls_dtl_db-losgr IS NOT INITIAL AND ls_dtl_db-losgr <> 0.
            ls_plantdata-lot_size  = ls_dtl_db-losgr.
            ls_plantdatax-lot_size = 'X'.
          ELSE.
            ls_plantdata-lot_size  = 100.
            ls_plantdatax-lot_size = 'X'.
          ENDIF.

          IF ls_dtl_db-klrab = 'X'.
            ls_plantdata-variance_key  = '000001'.
            ls_plantdatax-variance_key = 'X'.
          ELSEIF ls_dtl_db-klrab IS NOT INITIAL AND ls_dtl_db-klrab <> '0' AND ls_dtl_db-klrab <> '000000'.
            ls_plantdata-variance_key  = ls_dtl_db-klrab.
            ls_plantdatax-variance_key = 'X'.
          ENDIF.

          IF ls_dtl_db-herkl IS NOT INITIAL.
            ls_plantdata-countryori  = ls_dtl_db-herkl.
            ls_plantdatax-countryori = 'X'.
          ENDIF.

          " Quality Management Plant Level Mappings
          FIELD-SYMBOLS: <fs_qm_proc> TYPE any, <fs_cat_prof> TYPE any.
          ASSIGN COMPONENT 'QM_CONTROL' OF STRUCTURE ls_plantdata TO <fs_qm_proc>.
          IF sy-subrc <> 0.
            ASSIGN COMPONENT 'SSQSS' OF STRUCTURE ls_plantdata TO <fs_qm_proc>.
          ENDIF.
          IF sy-subrc = 0 AND <fs_qm_proc> IS ASSIGNED AND ls_dtl_db-ssqss IS NOT INITIAL.
            <fs_qm_proc> = ls_dtl_db-ssqss.
          ENDIF.

          ASSIGN COMPONENT 'COVPROFILE' OF STRUCTURE ls_plantdata TO <fs_cat_prof>.
          IF sy-subrc <> 0.
            ASSIGN COMPONENT 'CAT_PROFILE' OF STRUCTURE ls_plantdata TO <fs_cat_prof>.
          ENDIF.
          IF sy-subrc = 0 AND <fs_cat_prof> IS ASSIGNED AND ls_dtl_db-qssys IS NOT INITIAL.
            <fs_cat_prof> = ls_dtl_db-qssys.
          ENDIF.

          " MVKE Sales Data Mapping
          IF ls_dtl_db-vkorg IS NOT INITIAL AND ls_dtl_db-vtweg IS NOT INITIAL.
            ls_salesdata-sales_org   = ls_dtl_db-vkorg.
            ls_salesdata-distr_chan  = ls_dtl_db-vtweg.
            ls_salesdatax-sales_org  = ls_dtl_db-vkorg.
            ls_salesdatax-distr_chan = ls_dtl_db-vtweg.

            IF ls_dtl_db-dwerk IS NOT INITIAL.
              ls_salesdata-delyg_plnt  = ls_dtl_db-dwerk.
              ls_salesdatax-delyg_plnt = 'X'.
            ENDIF.

            IF ls_dtl_db-vrkme IS NOT INITIAL.
              CALL FUNCTION 'CONVERSION_EXIT_CUNIT_INPUT'
                EXPORTING input = ls_dtl_db-vrkme
                IMPORTING output = ls_salesdata-sales_unit
                EXCEPTIONS OTHERS = 1.
              IF ls_salesdata-sales_unit IS INITIAL.
                ls_salesdata-sales_unit = ls_dtl_db-vrkme.
              ENDIF.
              ls_salesdatax-sales_unit = 'X'.
            ENDIF.

            IF ls_dtl_db-mtpos IS NOT INITIAL.
              ls_salesdata-item_cat  = ls_dtl_db-mtpos.
              ls_salesdatax-item_cat = 'X'.
            ENDIF.

            IF ls_dtl_db-ktgrm IS NOT INITIAL.
              ls_salesdata-acct_assgt  = ls_dtl_db-ktgrm.
              ls_salesdatax-acct_assgt = 'X'.
            ENDIF.

            IF ls_dtl_db-mvgr1 IS NOT INITIAL.
              ls_salesdata-matl_grp_1  = ls_dtl_db-mvgr1.
              ls_salesdatax-matl_grp_1 = 'X'.
            ENDIF.

            IF ls_dtl_db-mvgr2 IS NOT INITIAL.
              ls_salesdata-matl_grp_2  = ls_dtl_db-mvgr2.
              ls_salesdatax-matl_grp_2 = 'X'.
            ENDIF.

            IF ls_dtl_db-mvgr3 IS NOT INITIAL.
              ls_salesdata-matl_grp_3  = ls_dtl_db-mvgr3.
              ls_salesdatax-matl_grp_3 = 'X'.
            ENDIF.

            IF ls_dtl_db-mvgr4 IS NOT INITIAL.
              ls_salesdata-matl_grp_4  = ls_dtl_db-mvgr4.
              ls_salesdatax-matl_grp_4 = 'X'.
            ENDIF.

            IF ls_dtl_db-mvgr5 IS NOT INITIAL.
              ls_salesdata-matl_grp_5  = ls_dtl_db-mvgr5.
              ls_salesdatax-matl_grp_5 = 'X'.
            ENDIF.

            IF ls_dtl_db-versg IS NOT INITIAL.
              FIELD-SYMBOLS: <fs_stat_grp> TYPE any, <fs_stat_grpx> TYPE any.
              ASSIGN COMPONENT 'STAT_GRP' OF STRUCTURE ls_salesdata TO <fs_stat_grp>.
              IF sy-subrc <> 0.
                ASSIGN COMPONENT 'STAT_GROUP' OF STRUCTURE ls_salesdata TO <fs_stat_grp>.
              ENDIF.
              IF sy-subrc <> 0.
                ASSIGN COMPONENT 'VERSG' OF STRUCTURE ls_salesdata TO <fs_stat_grp>.
              ENDIF.
              IF sy-subrc = 0 AND <fs_stat_grp> IS ASSIGNED.
                <fs_stat_grp> = ls_dtl_db-versg.
                ASSIGN COMPONENT 'STAT_GRP' OF STRUCTURE ls_salesdatax TO <fs_stat_grpx>.
                IF sy-subrc <> 0.
                  ASSIGN COMPONENT 'STAT_GROUP' OF STRUCTURE ls_salesdatax TO <fs_stat_grpx>.
                ENDIF.
                IF sy-subrc <> 0.
                  ASSIGN COMPONENT 'VERSG' OF STRUCTURE ls_salesdatax TO <fs_stat_grpx>.
                ENDIF.
                IF sy-subrc = 0 AND <fs_stat_grpx> IS ASSIGNED.
                  <fs_stat_grpx> = 'X'.
                ENDIF.
              ENDIF.
            ENDIF.
          ENDIF.

          " Tax Classifications Mapping (Crucial for Sales Org 1 & Export View activation)
          CLEAR: ls_taxclassifications, lt_taxclassifications.
          DATA: lv_depcountry TYPE land1.
          IF ls_dtl_db-herkl IS NOT INITIAL.
            lv_depcountry = ls_dtl_db-herkl.
          ELSE.
            lv_depcountry = 'ID'.
          ENDIF.

          IF ls_dtl_db-taxkm IS NOT INITIAL AND ls_dtl_db-tatyp IS NOT INITIAL.
            ls_taxclassifications-depcountry     = lv_depcountry.
            ls_taxclassifications-depcountry_iso = lv_depcountry.
            ls_taxclassifications-tax_type_1     = ls_dtl_db-tatyp.
            ls_taxclassifications-taxclass_1     = ls_dtl_db-taxkm.
            APPEND ls_taxclassifications TO lt_taxclassifications.
          ELSEIF ls_dtl_db-vkorg IS NOT INITIAL.
            ls_taxclassifications-depcountry     = 'ID'.
            ls_taxclassifications-depcountry_iso = 'ID'.
            ls_taxclassifications-tax_type_1     = 'MWST'.
            ls_taxclassifications-taxclass_1     = '1'.
            APPEND ls_taxclassifications TO lt_taxclassifications.
          ENDIF.

          " Inspection Types Mapping (QM View Activation)
          CLEAR: ls_inspectiontype, lt_inspectiontype.
          IF ls_dtl_db-insptype IS NOT INITIAL.
            ls_inspectiontype-plant     = ls_dtl_db-werks.
            ls_inspectiontype-insp_type = ls_dtl_db-insptype.
            ls_inspectiontype-active    = 'X'.
            APPEND ls_inspectiontype TO lt_inspectiontype.
          ELSEIF ls_dtl_db-ssqss IS NOT INITIAL OR ls_dtl_db-qssys IS NOT INITIAL.
            ls_inspectiontype-plant     = ls_dtl_db-werks.
            ls_inspectiontype-insp_type = '01'.
            ls_inspectiontype-active    = 'X'.
            APPEND ls_inspectiontype TO lt_inspectiontype.
          ENDIF.

          " Sales Text Mapping
          CLEAR: ls_materiallongtext, lt_materiallongtext.
          FIELD-SYMBOLS: <fs_stext_val> TYPE any.
          ASSIGN COMPONENT 'SALES_TEXT' OF STRUCTURE ls_dtl_db TO <fs_stext_val>.
          IF sy-subrc = 0 AND <fs_stext_val> IS ASSIGNED AND <fs_stext_val> IS NOT INITIAL.
            IF ls_dtl_db-vkorg IS NOT INITIAL AND ls_dtl_db-vtweg IS NOT INITIAL.
              ls_materiallongtext-applobject = 'MATERIAL'.
              ls_materiallongtext-text_id    = '0001'.
              ls_materiallongtext-langu      = sy-langu.
              ls_materiallongtext-text_line  = <fs_stext_val>.
              APPEND ls_materiallongtext TO lt_materiallongtext.
            ENDIF.
          ELSEIF ls_dtl_db-ferth IS NOT INITIAL AND ls_dtl_db-vkorg IS NOT INITIAL AND ls_dtl_db-vtweg IS NOT INITIAL.
            ls_materiallongtext-applobject = 'MATERIAL'.
            ls_materiallongtext-text_id    = '0001'.
            ls_materiallongtext-langu      = sy-langu.
            ls_materiallongtext-text_line  = ls_dtl_db-ferth.
            APPEND ls_materiallongtext TO lt_materiallongtext.
          ENDIF.

          " Alternative Units of Measure Mapping
          CLEAR: ls_unitsofmeasure, lt_unitsofmeasure, ls_unitsofmeasurex, lt_unitsofmeasurex.
          IF ls_dtl_db-meinh IS NOT INITIAL AND ls_dtl_db-umrez IS NOT INITIAL AND ls_dtl_db-umren IS NOT INITIAL.
            CALL FUNCTION 'CONVERSION_EXIT_CUNIT_INPUT'
              EXPORTING input = ls_dtl_db-meinh
              IMPORTING output = ls_unitsofmeasure-alt_unit
              EXCEPTIONS OTHERS = 1.
            IF ls_unitsofmeasure-alt_unit IS INITIAL.
              ls_unitsofmeasure-alt_unit = ls_dtl_db-meinh.
            ENDIF.
            ls_unitsofmeasure-alt_unit_iso = ls_unitsofmeasure-alt_unit.
            ls_unitsofmeasure-numerator    = ls_dtl_db-umrez.
            ls_unitsofmeasure-denominatr   = ls_dtl_db-umren.
            IF ls_dtl_db-brgew IS NOT INITIAL AND ls_dtl_db-brgew <> 0.
              ls_unitsofmeasure-gross_wt   = ls_dtl_db-brgew.
            ENDIF.
            IF ls_dtl_db-volum IS NOT INITIAL AND ls_dtl_db-volum <> 0.
              ls_unitsofmeasure-volume     = ls_dtl_db-volum.
            ENDIF.
            APPEND ls_unitsofmeasure TO lt_unitsofmeasure.

            ls_unitsofmeasurex-alt_unit     = ls_unitsofmeasure-alt_unit.
            ls_unitsofmeasurex-alt_unit_iso = ls_unitsofmeasure-alt_unit.
            ls_unitsofmeasurex-numerator    = 'X'.
            ls_unitsofmeasurex-denominatr   = 'X'.
            APPEND ls_unitsofmeasurex TO lt_unitsofmeasurex.
          ENDIF.

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

          IF ls_dtl_db-vprsv IS NOT INITIAL.
            ls_valuationdata-price_ctrl  = ls_dtl_db-vprsv.
            ls_valuationdatax-price_ctrl = 'X'.
          ELSE.
            ls_valuationdata-price_ctrl  = 'V'.
            ls_valuationdatax-price_ctrl = 'X'.
          ENDIF.

          IF ls_dtl_db-stprs IS NOT INITIAL AND ls_dtl_db-stprs <> 0.
            ls_valuationdata-std_price  = ls_dtl_db-stprs.
            ls_valuationdatax-std_price = 'X'.
          ENDIF.

          IF ls_dtl_db-verpr IS NOT INITIAL AND ls_dtl_db-verpr <> 0.
            ls_valuationdata-moving_pr  = ls_dtl_db-verpr.
            ls_valuationdatax-moving_pr = 'X'.
          ENDIF.

          IF ls_dtl_db-peinh IS NOT INITIAL AND ls_dtl_db-peinh <> 0.
            ls_valuationdata-price_unit  = ls_dtl_db-peinh.
            ls_valuationdatax-price_unit = 'X'.
          ELSE.
            ls_valuationdata-price_unit  = 1.
            ls_valuationdatax-price_unit = 'X'.
          ENDIF.

          IF ls_dtl_db-hkmat IS NOT INITIAL.
            ls_valuationdata-qty_struct  = ls_dtl_db-hkmat.
            ls_valuationdatax-qty_struct = 'X'.
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
              taxclassifications   = lt_taxclassifications
              unitsofmeasure       = lt_unitsofmeasure
              unitsofmeasurex      = lt_unitsofmeasurex
              inspectiontype       = lt_inspectiontype
              materiallongtext     = lt_materiallongtext
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