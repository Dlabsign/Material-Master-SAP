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
      lt_used_matnr   TYPE TABLE OF string,
      lv_cand_matnr   TYPE string.

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

IF lv_action IS NOT INITIAL.

  CASE lv_action.

    " ------------------------------------------------------------------
    " GET COUNTERS FOR SIDEBAR BADGES
    " ------------------------------------------------------------------
    WHEN 'GET_COUNTERS'.
      DATA: lv_cnt_p TYPE i, lv_cnt_a TYPE i, lv_cnt_r TYPE i.
      SELECT COUNT( * ) FROM zmdg_req_hdr WHERE status IN ( 'CHECKED', 'CODED' ) INTO @lv_cnt_p.
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

        " Pre-populate lt_used_matnr dengan nomor material yang sudah terisi di staging batch
        LOOP AT lt_dtl_db INTO ls_dtl_db WHERE matnr_ext IS NOT INITIAL.
          APPEND ls_dtl_db-matnr_ext TO lt_used_matnr.
        ENDLOOP.

        " LOOP UNTUK EDIT/VALIDASI SETIAP ITEM IN BATCH
        LOOP AT lt_dtl_db INTO ls_dtl_db.

          " Clean up & normalize Material Type per item (remove spaces & uppercase)
          IF ls_dtl_db-mtart IS NOT INITIAL.
            CONDENSE ls_dtl_db-mtart NO-GAPS.
            TRANSLATE ls_dtl_db-mtart TO UPPER CASE.
          ENDIF.

          " B. VALIDASI MANDATORY FIELDS PER ITEM
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

          " A. GENERATE KODE MATERIAL AUTOMATIC PER ITEM BERDASARKAN MTART SEBAGAI NUMBER RANGE
          CLEAR lv_exist_mara.
          IF ls_dtl_db-matnr_ext IS NOT INITIAL.
            SELECT SINGLE matnr FROM mara INTO @lv_exist_mara WHERE matnr = @ls_dtl_db-matnr_ext.
          ENDIF.

          IF ls_dtl_db-matnr_ext IS INITIAL OR sy-subrc = 0.
            " Jika nomor belum ada ATAU nomor lama sudah terdaftar di MARA, generate nomor baru per MTART item
            CLEAR: lv_is_available, lv_next_number, lt_check_return.

            CALL FUNCTION 'ZFM_CHECK_MATERIAL'
              EXPORTING
                iv_mtart        = ls_dtl_db-mtart
              IMPORTING
                ev_is_available = lv_is_available
                ev_next_number  = lv_next_number
                et_return       = lt_check_return.

            IF lv_is_available = 'X' AND lv_next_number IS NOT INITIAL.
              lv_cand_matnr = lv_next_number.

              " Safety check: Pastikan lv_cand_matnr belum dipakai di MARA maupun lt_used_matnr (untuk batch multi-item dengan MTART sama)
              DO 100 TIMES.
                CLEAR lv_exist_mara.
                SELECT SINGLE matnr FROM mara INTO @lv_exist_mara WHERE matnr = @lv_cand_matnr.
                READ TABLE lt_used_matnr WITH KEY table_line = lv_cand_matnr TRANSPORTING NO FIELDS.

                IF sy-subrc <> 0 AND lv_exist_mara IS INITIAL.
                  " Nomor bebas & unik
                  EXIT.
                ELSE.
                  " Jika nomor sudah terpakai di batch/MARA, increment 1 tingkat
                  IF lv_cand_matnr CO '0123456789'.
                    DATA: lv_num_tmp TYPE string,
                          lv_num_int TYPE i.
                    lv_num_int = lv_cand_matnr + 1.
                    lv_num_tmp = lv_num_int.
                    CONDENSE lv_num_tmp.
                    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
                      EXPORTING
                        input  = lv_num_tmp
                      IMPORTING
                        output = lv_cand_matnr.
                  ELSE.
                    EXIT.
                  ENDIF.
                ENDIF.
              ENDDO.

              ls_dtl_db-matnr_ext = lv_cand_matnr.
              APPEND ls_dtl_db-matnr_ext TO lt_used_matnr.

              " Update nomor yang dihasilkan ke tabel staging detail
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
          ENDIF.

          " C. CHECK DUPLIKASI KODE DI TABEL MARA (SAP MASTER DATA)
          CLEAR lv_exist_mara.
          SELECT SINGLE matnr FROM mara INTO @lv_exist_mara WHERE matnr = @ls_dtl_db-matnr_ext.
          IF sy-subrc = 0.
            lv_err_msg = |Kode Material { ls_dtl_db-matnr_ext } sudah terdaftar di MARA SAP (Item { ls_dtl_db-item_no })|.
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

          ls_valuationdata-val_area  = ls_dtl_db-werks.
          ls_valuationdatax-val_area = ls_dtl_db-werks.

          IF ls_dtl_db-bklas IS NOT INITIAL.
            ls_valuationdata-val_class  = ls_dtl_db-bklas.
            ls_valuationdatax-val_class = 'X'.
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

          " Origin Group (MBEW-HERBL)
          IF ls_dtl_db-herbl IS NOT INITIAL.
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
        DATA: lv_disp_matnr TYPE string.
        lv_disp_matnr = ls_dtl_db-matnr_ext.
        SHIFT lv_disp_matnr LEFT DELETING LEADING '0'.
        ls_resp-status    = 'SUCCESS'.
<<<<<<< HEAD
        ls_resp-matnr     = ls_dtl_db-matnr_ext.
        ls_resp-matnr_ext = ls_dtl_db-matnr_ext.
        IF lv_success_cnt > 1.
          ls_resp-message = lv_success_cnt && ' request berhasil divalidasi dan di-upload ke SAP S/4HANA!'.
        ELSEIF ls_dtl_db-matnr_ext IS NOT INITIAL.
          ls_resp-message = 'Data berhasil divalidasi dan di-upload ke SAP S/4HANA! (Nomor Material: ' && ls_dtl_db-matnr_ext && ')'.
=======
        ls_resp-matnr     = lv_disp_matnr.
        ls_resp-matnr_ext = lv_disp_matnr.
        IF lv_success_cnt > 1.
          ls_resp-message = lv_success_cnt && ' request berhasil divalidasi dan di-upload ke SAP S/4HANA!'.
        ELSEIF lv_disp_matnr IS NOT INITIAL.
          ls_resp-message = 'Data berhasil divalidasi dan di-upload ke SAP S/4HANA! (Nomor Material: ' && lv_disp_matnr && ')'.
>>>>>>> 06a1222de42d14524631c8826658989956385189
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