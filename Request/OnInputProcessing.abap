DATA: lv_action     TYPE string,
      lv_json       TYPE string,
      lv_req_id     TYPE string,
      lv_upload_id  TYPE string,
      lv_filename   TYPE string,
      lv_status     TYPE string,
      lv_sub_reason TYPE string,
      lv_count_str  TYPE string,
      lv_count      TYPE i,
      idx_str       TYPE string,
      lv_losgr_raw  TYPE string.

DATA: ls_hdr TYPE zmdg_req_hdr,
      lt_dtl TYPE TABLE OF zmdg_req_dtl,
      ls_dtl TYPE zmdg_req_dtl.

TYPES: BEGIN OF ty_hdr_db,
         req_no     TYPE zmdg_req_hdr-req_no,
         remarks    TYPE zmdg_req_hdr-remarks,
         req_date   TYPE zmdg_req_hdr-req_date,
         req_time   TYPE zmdg_req_hdr-req_time,
         requestor  TYPE zmdg_req_hdr-requestor,
         status     TYPE zmdg_req_hdr-status,
         rej_reason TYPE zmdg_req_hdr-rej_reason,
         sub_reason TYPE zmdg_req_hdr-sub_reason,
         approver   TYPE zmdg_req_hdr-approver,
         app_date   TYPE zmdg_req_hdr-app_date,
         app_time   TYPE zmdg_req_hdr-app_time,
       END OF ty_hdr_db.

DATA: lt_hdr_db TYPE TABLE OF ty_hdr_db,
      ls_hdr_db TYPE ty_hdr_db.

DATA: lt_dtl_db TYPE TABLE OF zmdg_req_dtl,
      ls_dtl_db TYPE zmdg_req_dtl.

TYPES: BEGIN OF ty_history,
         upload_id  TYPE string,
         filename   TYPE string,
         erdat      TYPE string,
         ertim      TYPE string,
         total_row  TYPE i,
         ernam      TYPE string,
         status     TYPE string,
         rej_reason TYPE string,
         sub_reason TYPE string,
         approver   TYPE string,
         app_date   TYPE string,
         app_time   TYPE string,
       END OF ty_history.
DATA: lt_history TYPE TABLE OF ty_history,
      ls_history TYPE ty_history.

TYPES: BEGIN OF ty_detail_json,
         matnr                  TYPE string,
         bismt                  TYPE string,
         maktx                  TYPE string,
         mtart                  TYPE string,
         mbrsh                  TYPE string,
         matkl                  TYPE string,
         meins                  TYPE string,
         spart                  TYPE string,
         mtpos_mara             TYPE string,
         ferth                  TYPE string,
         zeinr                  TYPE string,
         normt                  TYPE string,
         groes                  TYPE string,
         werks                  TYPE string,
         lgort                  TYPE string,
         vkorg                  TYPE string,
         vtweg                  TYPE string,
         dwerk                  TYPE string,
         vrkme                  TYPE string,
         herkl                  TYPE string,
         taxkm                  TYPE string,
         tatyp                  TYPE string,
         mtpos                  TYPE string,
         ktgrm                  TYPE string,
         mvgr1                  TYPE string,
         mvgr2                  TYPE string,
         mvgr3                  TYPE string,
         mvgr4                  TYPE string,
         mvgr5                  TYPE string,
         tragr                  TYPE string,
         ladgr                  TYPE string,
         magrv                  TYPE string,
         vhart                  TYPE string,
         xchpf                  TYPE string,
         prctr                  TYPE string,
         bklas                  TYPE string,
         stprs                  TYPE string,
         verpr                  TYPE string,
         peinh                  TYPE string,
         vprsv                  TYPE string,
         peinh_2                TYPE string,
         umren                  TYPE string,
         meinh                  TYPE string,
         umrez                  TYPE string,
         laeng                  TYPE string,
         breit                  TYPE string,
         hoehe                  TYPE string,
         meabm                  TYPE string,
         brgew                  TYPE string,
         gewei                  TYPE string,
         ntgew                  TYPE string,
         volum                  TYPE string,
         ekgrp                  TYPE string,
         voleh                  TYPE string,
         kzwsm                  TYPE string,
         class                  TYPE string,
         warna                  TYPE string,
         vol_prod               TYPE string,
         dismm                  TYPE string,
         disgr                  TYPE string,
         dispo                  TYPE string,
         disls                  TYPE string,
         bstmi                  TYPE string,
         bstma                  TYPE string,
         bstrf                  TYPE string,
         beskz                  TYPE string,
         sobsl                  TYPE string,
         rgekz                  TYPE string,
         dzeit                  TYPE string,
         plifz                  TYPE string,
         webaz                  TYPE string,
         fhori                  TYPE string,
         eisbe                  TYPE string,
         strgr                  TYPE string,
         vrmod                  TYPE string,
         vint1                  TYPE string,
         vint2                  TYPE string,
         perkz                  TYPE string,
         periv                  TYPE string,
         mtvfp                  TYPE string,
         altsl                  TYPE string,
         kzkst                  TYPE string,
         ausme                  TYPE string,
         lgpro                  TYPE string,
         lgpro_ep               TYPE string,
         sfpro                  TYPE string,
         uneto                  TYPE string,
         ueeto                  TYPE string,
         ueetk                  TYPE string,
         hkmat                  TYPE string,
         ekalr                  TYPE string,
         losgr                  TYPE string,
         ncost                  TYPE string,
         mmsta                  TYPE string,
         eprio                  TYPE string,
         herbl                  TYPE string,
         klrab                  TYPE string,
         verid                  TYPE string,
         perkz_2                TYPE string,
         bwkey                  TYPE string,
         versg                  TYPE string,
         ssqss                  TYPE string,
         qssys                  TYPE string,
         insptype               TYPE string,
         sernp                  TYPE string,
         stawn                  TYPE string,
         sales_text             TYPE string,
       END OF ty_detail_json.
DATA: lt_detail_json TYPE TABLE OF ty_detail_json,
      ls_detail_json TYPE ty_detail_json.

lv_action = request->get_form_field( 'OnInputProcessing' ).

CASE lv_action.

  " ==================================================================
  " 1. SAVE STAGING DATA FROM JS FETCH API
  " ==================================================================
  WHEN 'SAVE_STAGE'.
    lv_req_id     = request->get_form_field( 'REQ_ID' ).
    lv_upload_id  = request->get_form_field( 'UPLOAD_ID' ).
    lv_filename   = request->get_form_field( 'FILENAME' ).
    lv_status     = request->get_form_field( 'STATUS' ).
    lv_sub_reason = request->get_form_field( 'SUB_REASON' ).
    lv_count_str  = request->get_form_field( 'ROW_COUNT' ).
    lv_count      = lv_count_str.

    IF lv_count <= 0.
      lv_json = '{"status":"ERROR","message":"PROSES DIHENTIKAN: Template/Data Excel tidak valid. Tidak ada baris material yang dikirim."}'.
      _m_response->set_content_type( 'application/json' ).
      _m_response->set_cdata( lv_json ).
      navigation->goto_page( '' ).
      RETURN.
    ENDIF.

    IF lv_upload_id IS INITIAL.
      IF lv_req_id IS NOT INITIAL.
        lv_upload_id = lv_req_id.
      ELSE.
        lv_upload_id = |UPL-{ sy-datum }-{ sy-uzeit }|.
      ENDIF.
    ENDIF.

    ls_hdr-req_no     = CONV #( lv_upload_id ).
    ls_hdr-status     = CONV #( lv_status ).
    ls_hdr-requestor  = sy-uname.
    ls_hdr-req_date   = sy-datum.
    ls_hdr-req_time   = sy-uzeit.
    ls_hdr-remarks    = CONV #( lv_filename ).
    ls_hdr-sub_reason = CONV #( lv_sub_reason ).
    MODIFY zmdg_req_hdr FROM @ls_hdr.

    CLEAR lt_dtl.
    DO lv_count TIMES.
      idx_str = sy-index.
      CONDENSE idx_str.
      CLEAR ls_dtl.

      ls_dtl-req_no     = ls_hdr-req_no.
      ls_dtl-item_no    = sy-index.
      ls_dtl-matnr_ext  = request->get_form_field( |matnr_{ idx_str }| ).
      ls_dtl-bismt      = request->get_form_field( |bismt_{ idx_str }| ).
      ls_dtl-maktx      = request->get_form_field( |maktx_{ idx_str }| ).
      ls_dtl-mtart      = request->get_form_field( |mtart_{ idx_str }| ).
      ls_dtl-mbrsh      = request->get_form_field( |mbrsh_{ idx_str }| ).
      ls_dtl-matkl      = request->get_form_field( |matkl_{ idx_str }| ).
      ls_dtl-meins      = request->get_form_field( |meins_{ idx_str }| ).
      ls_dtl-spart      = request->get_form_field( |spart_{ idx_str }| ).
      ls_dtl-mtpos_mara = request->get_form_field( |mtpos_mara_{ idx_str }| ).
      ls_dtl-ferth      = request->get_form_field( |ferth_{ idx_str }| ).
      ls_dtl-zeinr      = request->get_form_field( |zeinr_{ idx_str }| ).
      ls_dtl-normt      = request->get_form_field( |normt_{ idx_str }| ).
      ls_dtl-groes      = request->get_form_field( |groes_{ idx_str }| ).
      ls_dtl-werks      = request->get_form_field( |werks_{ idx_str }| ).
      ls_dtl-lgort      = request->get_form_field( |lgort_{ idx_str }| ).
      ls_dtl-vkorg      = request->get_form_field( |vkorg_{ idx_str }| ).
      ls_dtl-vtweg      = request->get_form_field( |vtweg_{ idx_str }| ).
      ls_dtl-dwerk      = request->get_form_field( |dwerk_{ idx_str }| ).
      ls_dtl-vrkme      = request->get_form_field( |vrkme_{ idx_str }| ).
      ls_dtl-herkl      = request->get_form_field( |herkl_{ idx_str }| ).
      ls_dtl-taxkm      = request->get_form_field( |taxkm_{ idx_str }| ).
      ls_dtl-tatyp      = request->get_form_field( |tatyp_{ idx_str }| ).
      ls_dtl-mtpos      = request->get_form_field( |mtpos_{ idx_str }| ).
      ls_dtl-ktgrm      = request->get_form_field( |ktgrm_{ idx_str }| ).
      ls_dtl-mvgr1      = request->get_form_field( |mvgr1_{ idx_str }| ).
      ls_dtl-mvgr2      = request->get_form_field( |mvgr2_{ idx_str }| ).
      ls_dtl-mvgr3      = request->get_form_field( |mvgr3_{ idx_str }| ).
      ls_dtl-mvgr4      = request->get_form_field( |mvgr4_{ idx_str }| ).
      ls_dtl-mvgr5      = request->get_form_field( |mvgr5_{ idx_str }| ).
      ls_dtl-tragr      = request->get_form_field( |tragr_{ idx_str }| ).
      ls_dtl-ladgr      = request->get_form_field( |ladgr_{ idx_str }| ).
      ls_dtl-magrv      = request->get_form_field( |magrv_{ idx_str }| ).
      ls_dtl-xchpf      = request->get_form_field( |xchpf_{ idx_str }| ).
      IF ls_dtl-xchpf = 'X' OR ls_dtl-xchpf = 'x' OR ls_dtl-xchpf = 'O' OR ls_dtl-xchpf = 'o' OR ls_dtl-xchpf = 'on' OR ls_dtl-xchpf = 'ON' OR ls_dtl-xchpf = '1'.
        ls_dtl-xchpf = 'X'.
      ELSE.
        ls_dtl-xchpf = ''.
      ENDIF.
      ls_dtl-prctr      = request->get_form_field( |prctr_{ idx_str }| ).
      IF ls_dtl-prctr IS NOT INITIAL AND ls_dtl-prctr CO '0123456789 '.
        CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
          EXPORTING input  = ls_dtl-prctr
          IMPORTING output = ls_dtl-prctr.
      ENDIF.
      ls_dtl-bklas      = request->get_form_field( |bklas_{ idx_str }| ).
      ls_dtl-stprs      = request->get_form_field( |stprs_{ idx_str }| ).
      ls_dtl-verpr      = request->get_form_field( |verpr_{ idx_str }| ).
      ls_dtl-peinh      = request->get_form_field( |peinh_{ idx_str }| ).
      ls_dtl-vprsv      = request->get_form_field( |vprsv_{ idx_str }| ).
      ls_dtl-peinh_2    = request->get_form_field( |peinh_2_{ idx_str }| ).
      ls_dtl-umren      = request->get_form_field( |umren_{ idx_str }| ).
      ls_dtl-meinh      = request->get_form_field( |meinh_{ idx_str }| ).
      ls_dtl-umrez      = request->get_form_field( |umrez_{ idx_str }| ).
      ls_dtl-laeng      = request->get_form_field( |laeng_{ idx_str }| ).
      ls_dtl-breit      = request->get_form_field( |breit_{ idx_str }| ).
      ls_dtl-hoehe      = request->get_form_field( |hoehe_{ idx_str }| ).
      ls_dtl-meabm      = request->get_form_field( |meabm_{ idx_str }| ).
      ls_dtl-brgew      = request->get_form_field( |brgew_{ idx_str }| ).
      ls_dtl-gewei      = request->get_form_field( |gewei_{ idx_str }| ).
      ls_dtl-ntgew      = request->get_form_field( |ntgew_{ idx_str }| ).
      ls_dtl-volum      = request->get_form_field( |volum_{ idx_str }| ).
      ls_dtl-ekgrp      = request->get_form_field( |ekgrp_{ idx_str }| ).
      ls_dtl-voleh      = request->get_form_field( |voleh_{ idx_str }| ).
      ls_dtl-kzwsm      = request->get_form_field( |kzwsm_{ idx_str }| ).
      ls_dtl-class      = request->get_form_field( |class_{ idx_str }| ).
      ls_dtl-warna      = request->get_form_field( |warna_{ idx_str }| ).
      ls_dtl-vol_prod   = request->get_form_field( |vol_prod_{ idx_str }| ).
      ls_dtl-dismm      = request->get_form_field( |dismm_{ idx_str }| ).
      ls_dtl-disgr      = request->get_form_field( |disgr_{ idx_str }| ).
      ls_dtl-dispo      = request->get_form_field( |dispo_{ idx_str }| ).
      ls_dtl-disls      = request->get_form_field( |disls_{ idx_str }| ).
      ls_dtl-bstmi      = request->get_form_field( |bstmi_{ idx_str }| ).
      ls_dtl-bstma      = request->get_form_field( |bstma_{ idx_str }| ).
      ls_dtl-bstrf      = request->get_form_field( |bstrf_{ idx_str }| ).
      ls_dtl-beskz      = request->get_form_field( |beskz_{ idx_str }| ).
      ls_dtl-sobsl      = request->get_form_field( |sobsl_{ idx_str }| ).
      ls_dtl-rgekz      = request->get_form_field( |rgekz_{ idx_str }| ).
      ls_dtl-dzeit      = request->get_form_field( |dzeit_{ idx_str }| ).
      ls_dtl-plifz      = request->get_form_field( |plifz_{ idx_str }| ).
      ls_dtl-webaz      = request->get_form_field( |webaz_{ idx_str }| ).
      ls_dtl-fhori      = request->get_form_field( |fhori_{ idx_str }| ).
      ls_dtl-eisbe      = request->get_form_field( |eisbe_{ idx_str }| ).
      ls_dtl-strgr      = request->get_form_field( |strgr_{ idx_str }| ).
      ls_dtl-vrmod      = request->get_form_field( |vrmod_{ idx_str }| ).
      ls_dtl-vint1      = request->get_form_field( |vint1_{ idx_str }| ).
      ls_dtl-vint2      = request->get_form_field( |vint2_{ idx_str }| ).
      ls_dtl-perkz      = request->get_form_field( |perkz_{ idx_str }| ).
      ls_dtl-periv      = request->get_form_field( |periv_{ idx_str }| ).
      ls_dtl-mtvfp      = request->get_form_field( |mtvfp_{ idx_str }| ).
      ls_dtl-altsl      = request->get_form_field( |altsl_{ idx_str }| ).
      ls_dtl-kzkst      = request->get_form_field( |kzkst_{ idx_str }| ).
      ls_dtl-ausme      = request->get_form_field( |ausme_{ idx_str }| ).
      ls_dtl-lgpro      = request->get_form_field( |lgpro_{ idx_str }| ).
      ls_dtl-lgpro_ep   = request->get_form_field( |lgpro_ep_{ idx_str }| ).
      ls_dtl-sfpro      = request->get_form_field( |sfpro_{ idx_str }| ).
      ls_dtl-uneto      = request->get_form_field( |uneto_{ idx_str }| ).
      ls_dtl-ueeto      = request->get_form_field( |ueeto_{ idx_str }| ).
      ls_dtl-ueetk      = request->get_form_field( |ueetk_{ idx_str }| ).
      ls_dtl-hkmat      = request->get_form_field( |hkmat_{ idx_str }| ).
      ls_dtl-ekalr      = request->get_form_field( |ekalr_{ idx_str }| ).
      ls_dtl-ncost      = request->get_form_field( |ncost_{ idx_str }| ).
      ls_dtl-mmsta      = request->get_form_field( |mmsta_{ idx_str }| ).
      ls_dtl-eprio      = request->get_form_field( |eprio_{ idx_str }| ).
      ls_dtl-herbl      = request->get_form_field( |herbl_{ idx_str }| ).
      ls_dtl-klrab      = request->get_form_field( |klrab_{ idx_str }| ).
      ls_dtl-verid      = request->get_form_field( |verid_{ idx_str }| ).
      ls_dtl-perkz_2    = request->get_form_field( |perkz_2_{ idx_str }| ).
      ls_dtl-bwkey      = request->get_form_field( |bwkey_{ idx_str }| ).
      ls_dtl-versg      = request->get_form_field( |versg_{ idx_str }| ).
      ls_dtl-ssqss      = request->get_form_field( |ssqss_{ idx_str }| ).
      ls_dtl-qssys      = request->get_form_field( |qssys_{ idx_str }| ).
      ls_dtl-insptype   = request->get_form_field( |insptype_{ idx_str }| ).
      ls_dtl-sernp      = request->get_form_field( |sernp_{ idx_str }| ).
      ls_dtl-stawn      = request->get_form_field( |stawn_{ idx_str }| ).
      ls_dtl-sales_text = request->get_form_field( |sales_text_{ idx_str }| ).

      lv_losgr_raw      = request->get_form_field( |losgr_{ idx_str }| ).
      REPLACE ALL OCCURRENCES OF ',' IN lv_losgr_raw WITH '.'.
      ls_dtl-losgr      = CONV #( lv_losgr_raw ).

      " Format TRAGR & LADGR (e.g. '1' -> '0001')
      IF ls_dtl-tragr IS NOT INITIAL.
        CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
          EXPORTING input = ls_dtl-tragr
          IMPORTING output = ls_dtl-tragr.
      ENDIF.
      IF ls_dtl-ladgr IS NOT INITIAL.
        CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
          EXPORTING input = ls_dtl-ladgr
          IMPORTING output = ls_dtl-ladgr.
      ENDIF.

      APPEND ls_dtl TO lt_dtl.
    ENDDO.

    IF lt_dtl IS NOT INITIAL.
      MODIFY zmdg_req_dtl FROM TABLE @lt_dtl.
    ENDIF.

    " ==================================================================
    " AUTOMATIC SAP MASTER DATA VALIDATION ON REQUESTER SUBMIT
    " ==================================================================
    DATA: lv_has_val_err  TYPE abap_bool VALUE abap_false,
          lv_err_log      TYPE string,
          ls_check_dtl    TYPE zmdg_req_dtl,
          lv_item_num     TYPE i VALUE 0.

    IF lv_status = 'SUBMITTED' AND lt_dtl IS NOT INITIAL.
      LOOP AT lt_dtl INTO ls_check_dtl.
        lv_item_num = lv_item_num + 1.
        DATA(lv_item_err) = ` `.
        CLEAR lv_item_err.

        " 1. Mandatory Material Type (MTART) & Industry Sector (MBRSH)
        IF ls_check_dtl-mbrsh IS INITIAL OR ls_check_dtl-mtart IS INITIAL.
          IF lv_item_err IS NOT INITIAL. lv_item_err = |{ lv_item_err }; |. ENDIF.
          lv_item_err = |{ lv_item_err }[E03] Material Type (MTART) & Industry Sector (MBRSH) wajib diisi|.
        ENDIF.

        " 2. Mandatory Plant (WERKS)
        IF ls_check_dtl-werks IS INITIAL.
          IF lv_item_err IS NOT INITIAL. lv_item_err = |{ lv_item_err }; |. ENDIF.
          lv_item_err = |{ lv_item_err }[E04] Plant (WERKS) wajib diisi|.
        ENDIF.

        " 3. Mandatory Storage Location (LGORT)
        IF ls_check_dtl-lgort IS INITIAL.
          IF lv_item_err IS NOT INITIAL. lv_item_err = |{ lv_item_err }; |. ENDIF.
          lv_item_err = |{ lv_item_err }[E05] Storage Location (LGORT) wajib diisi|.
        ENDIF.

        " 4. Mandatory Profit Center (PRCTR)
        IF ls_check_dtl-prctr IS INITIAL AND sy-mandt = '300'.
          IF lv_item_err IS NOT INITIAL. lv_item_err = |{ lv_item_err }; |. ENDIF.
          lv_item_err = |{ lv_item_err }[E06] Profit Center (PRCTR) wajib diisi|.
        ENDIF.

        " 5. Mandatory Material Description (MAKTX)
        IF ls_check_dtl-maktx IS INITIAL.
          IF lv_item_err IS NOT INITIAL. lv_item_err = |{ lv_item_err }; |. ENDIF.
          lv_item_err = |{ lv_item_err }[E07] Material Description (MAKTX) wajib diisi|.
        ENDIF.

        " 6. Mandatory Base Unit of Measure (MEINS)
        IF ls_check_dtl-meins IS INITIAL.
          IF lv_item_err IS NOT INITIAL. lv_item_err = |{ lv_item_err }; |. ENDIF.
          lv_item_err = |{ lv_item_err }[E08] Base UoM (MEINS) wajib diisi|.
        ENDIF.

        " 7. Table Check - T001W (Plant Master)
        IF ls_check_dtl-werks IS NOT INITIAL.
          SELECT SINGLE werks FROM t001w INTO @DATA(lv_dummy_w) WHERE werks = @ls_check_dtl-werks.
          IF sy-subrc <> 0.
            IF lv_item_err IS NOT INITIAL. lv_item_err = |{ lv_item_err }; |. ENDIF.
            lv_item_err = |{ lv_item_err }Plant '{ ls_check_dtl-werks }' tdk ada di master SAP (T001W)|.
          ENDIF.
        ENDIF.

        " 8. Table Check - T001L (Storage Location Master)
        IF ls_check_dtl-werks IS NOT INITIAL AND ls_check_dtl-lgort IS NOT INITIAL.
          SELECT SINGLE lgort FROM t001l INTO @DATA(lv_dummy_l) WHERE werks = @ls_check_dtl-werks AND lgort = @ls_check_dtl-lgort.
          IF sy-subrc <> 0.
            IF lv_item_err IS NOT INITIAL. lv_item_err = |{ lv_item_err }; |. ENDIF.
            lv_item_err = |{ lv_item_err }S.Loc '{ ls_check_dtl-lgort }' tdk valid utk Plant '{ ls_check_dtl-werks }' (T001L)|.
          ENDIF.
        ENDIF.

        " 9. Base UoM Check (T006)
        IF ls_check_dtl-meins IS NOT INITIAL.
          DATA: lv_meins_conv TYPE mara-meins.
          CLEAR lv_meins_conv.
          CALL FUNCTION 'CONVERSION_EXIT_CUNIT_INPUT'
            EXPORTING input = ls_check_dtl-meins
            IMPORTING output = lv_meins_conv
            EXCEPTIONS OTHERS = 1.
          IF sy-subrc <> 0 OR lv_meins_conv IS INITIAL.
            IF lv_item_err IS NOT INITIAL. lv_item_err = |{ lv_item_err }; |. ENDIF.
            lv_item_err = |{ lv_item_err }Base UoM '{ ls_check_dtl-meins }' tdk terdaftar di master SAP (T006)|.
          ENDIF.
        ENDIF.

        " 10. Valuation Class (T025)
        IF ls_check_dtl-bklas IS NOT INITIAL.
          SELECT SINGLE bklas FROM t025 INTO @DATA(lv_dum_bklas) WHERE bklas = @ls_check_dtl-bklas.
          IF sy-subrc <> 0.
            IF lv_item_err IS NOT INITIAL. lv_item_err = |{ lv_item_err }; |. ENDIF.
            lv_item_err = |{ lv_item_err }Valuation Class '{ ls_check_dtl-bklas }' tdk terdaftar di SAP (T025)|.
          ENDIF.
        ENDIF.

        " Accumulate Item Error
        IF lv_item_err IS NOT INITIAL.
          lv_has_val_err = abap_true.
          IF lv_err_log IS NOT INITIAL. lv_err_log = |{ lv_err_log } \n |. ENDIF.
          lv_err_log = |{ lv_err_log }Item #{ lv_item_num } ({ ls_check_dtl-maktx }): { lv_item_err }|.
        ENDIF.
      ENDLOOP.

      " IF ANY ITEM FAILS VALIDATION -> SET STATUS TO HOLD AUTOMATICALLY
      IF lv_has_val_err = abap_true.
        DATA: lv_auto_hold_reason TYPE string.
        lv_auto_hold_reason = |[HOLD VALIDASI MASTER SAP] { lv_err_log }|.
        lv_status = 'HOLD'.

        UPDATE zmdg_req_hdr
          SET status     = 'HOLD',
              rej_reason = @lv_auto_hold_reason,
              approver   = @sy-uname,
              app_date   = @sy-datum,
              app_time   = @sy-uzeit
          WHERE req_no   = @ls_hdr-req_no.
      ENDIF.
    ENDIF.

    DATA: lv_email_sent TYPE abap_bool VALUE abap_false,
          lv_email_err  TYPE string.

    IF lv_status = 'SUBMITTED' OR lv_status = 'HOLD'.
      lv_email_sent = abap_true.
      COMMIT WORK AND WAIT.
    ENDIF.

    DATA: lv_sub_reason_esc TYPE string,
          lv_email_err_esc  TYPE string,
          lv_msg_resp       TYPE string.
    lv_sub_reason_esc = lv_sub_reason.
    REPLACE ALL OCCURRENCES OF '\' IN lv_sub_reason_esc WITH '\\'.
    REPLACE ALL OCCURRENCES OF '"' IN lv_sub_reason_esc WITH '\"'.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf IN lv_sub_reason_esc WITH '\n'.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>newline IN lv_sub_reason_esc WITH '\n'.

    lv_email_err_esc = lv_email_err.
    REPLACE ALL OCCURRENCES OF '\' IN lv_email_err_esc WITH '\\'.
    REPLACE ALL OCCURRENCES OF '"' IN lv_email_err_esc WITH '\"'.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf IN lv_email_err_esc WITH ' '.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>newline IN lv_email_err_esc WITH ' '.

    IF lv_status = 'SUBMITTED'.
      IF lv_email_sent = abap_true.
        lv_msg_resp = |Request { lv_upload_id } berhasil disimpan dan email notifikasi telah dikirim ke Data Steward.|.
      ELSE.
        lv_msg_resp = |Request { lv_upload_id } berhasil disimpan, namun notifikasi email gagal dikirim.|.
      ENDIF.
    ELSE.
      lv_msg_resp = |Staging data draft berhasil disimpan.|.
    ENDIF.

    IF lv_email_sent = abap_true.
      lv_json = |\{"status":"SUCCESS","upload_id":"{ lv_upload_id }","email_sent":true,"sub_reason":"{ lv_sub_reason_esc }","message":"{ lv_msg_resp }","email_err":""\}|.
    ELSE.
      lv_json = |\{"status":"SUCCESS","upload_id":"{ lv_upload_id }","email_sent":false,"sub_reason":"{ lv_sub_reason_esc }","message":"{ lv_msg_resp }","email_err":"{ lv_email_err_esc }"\}|.
    ENDIF.

    _m_response->set_content_type( 'application/json' ).
    _m_response->set_cdata( lv_json ).
    navigation->goto_page( '' ).        " FIXED: cegah BSP merender layout setelah JSON
    RETURN.


  " ==================================================================
  " 2. FETCH BATCH HISTORY
  " ==================================================================
  WHEN 'GET_HISTORY'.
    CLEAR: lt_hdr_db, lt_history.

    SELECT req_no, remarks, req_date, req_time, requestor, status, rej_reason, sub_reason, approver, app_date, app_time
      FROM zmdg_req_hdr
      INTO TABLE @lt_hdr_db
      ORDER BY req_date DESCENDING, req_time DESCENDING.

    LOOP AT lt_hdr_db INTO ls_hdr_db.
      CLEAR ls_history.
      ls_history-upload_id  = ls_hdr_db-req_no.
      ls_history-filename   = ls_hdr_db-remarks.
      ls_history-erdat      = ls_hdr_db-req_date.
      ls_history-ertim      = ls_hdr_db-req_time.
      ls_history-ernam      = ls_hdr_db-requestor.
      ls_history-status     = ls_hdr_db-status.
      ls_history-rej_reason = ls_hdr_db-rej_reason.
      ls_history-sub_reason = ls_hdr_db-sub_reason.
      ls_history-approver   = ls_hdr_db-approver.
      ls_history-app_date   = ls_hdr_db-app_date.
      ls_history-app_time   = ls_hdr_db-app_time.

      SELECT COUNT( * ) FROM zmdg_req_dtl INTO @ls_history-total_row WHERE req_no = @ls_hdr_db-req_no.

      APPEND ls_history TO lt_history.
    ENDLOOP.

    lv_json = /ui2/cl_json=>serialize( data = lt_history compress = 'X' pretty_name = /ui2/cl_json=>pretty_mode-low_case ).
    _m_response->set_content_type( 'application/json' ).
    _m_response->set_cdata( lv_json ).
    navigation->goto_page( '' ).        " FIXED
    RETURN.


  " ==================================================================
  " 3. FETCH BATCH DETAIL
  " ==================================================================
  WHEN 'GET_UPLOAD_DETAIL'.
    lv_upload_id = request->get_form_field( 'UPLOAD_ID' ).
    CLEAR: lt_dtl_db, lt_detail_json.

    SELECT * FROM zmdg_req_dtl
      INTO TABLE @lt_dtl_db
      WHERE req_no = @lv_upload_id
      ORDER BY item_no ASCENDING.

    LOOP AT lt_dtl_db INTO ls_dtl_db.
      CLEAR ls_detail_json.
      ls_detail_json-matnr      = ls_dtl_db-matnr_ext.
      ls_detail_json-bismt      = ls_dtl_db-bismt.
      ls_detail_json-maktx      = ls_dtl_db-maktx.
      ls_detail_json-mtart      = ls_dtl_db-mtart.
      ls_detail_json-mbrsh      = ls_dtl_db-mbrsh.
      ls_detail_json-matkl      = ls_dtl_db-matkl.
      ls_detail_json-meins      = ls_dtl_db-meins.
      ls_detail_json-spart      = ls_dtl_db-spart.
      ls_detail_json-mtpos_mara = ls_dtl_db-mtpos_mara.
      ls_detail_json-ferth      = ls_dtl_db-ferth.
      ls_detail_json-zeinr      = ls_dtl_db-zeinr.
      ls_detail_json-normt      = ls_dtl_db-normt.
      ls_detail_json-groes      = ls_dtl_db-groes.
      ls_detail_json-werks      = ls_dtl_db-werks.
      ls_detail_json-lgort      = ls_dtl_db-lgort.
      ls_detail_json-vkorg      = ls_dtl_db-vkorg.
      ls_detail_json-vtweg      = ls_dtl_db-vtweg.
      ls_detail_json-dwerk      = ls_dtl_db-dwerk.
      ls_detail_json-vrkme      = ls_dtl_db-vrkme.
      ls_detail_json-herkl      = ls_dtl_db-herkl.
      ls_detail_json-taxkm      = ls_dtl_db-taxkm.
      ls_detail_json-tatyp      = ls_dtl_db-tatyp.
      ls_detail_json-mtpos      = ls_dtl_db-mtpos.
      ls_detail_json-ktgrm      = ls_dtl_db-ktgrm.
      ls_detail_json-mvgr1      = ls_dtl_db-mvgr1.
      ls_detail_json-mvgr2      = ls_dtl_db-mvgr2.
      ls_detail_json-mvgr3      = ls_dtl_db-mvgr3.
      ls_detail_json-mvgr4      = ls_dtl_db-mvgr4.
      ls_detail_json-mvgr5      = ls_dtl_db-mvgr5.
      ls_detail_json-tragr      = ls_dtl_db-tragr.
      ls_detail_json-ladgr      = ls_dtl_db-ladgr.
      ls_detail_json-magrv      = ls_dtl_db-magrv.
      ls_detail_json-vhart      = ls_dtl_db-vhart.
      ls_detail_json-xchpf      = ls_dtl_db-xchpf.
      ls_detail_json-prctr      = ls_dtl_db-prctr.
      ls_detail_json-bklas      = ls_dtl_db-bklas.
      ls_detail_json-stprs      = CONV #( ls_dtl_db-stprs ).
      ls_detail_json-verpr      = CONV #( ls_dtl_db-verpr ).
      ls_detail_json-peinh      = CONV #( ls_dtl_db-peinh ).
      ls_detail_json-vprsv      = ls_dtl_db-vprsv.
      ls_detail_json-peinh_2    = CONV #( ls_dtl_db-peinh_2 ).
      ls_detail_json-umren      = CONV #( ls_dtl_db-umren ).
      ls_detail_json-meinh      = ls_dtl_db-meinh.
      ls_detail_json-umrez      = CONV #( ls_dtl_db-umrez ).
      ls_detail_json-laeng      = CONV #( ls_dtl_db-laeng ).
      ls_detail_json-breit      = CONV #( ls_dtl_db-breit ).
      ls_detail_json-hoehe      = CONV #( ls_dtl_db-hoehe ).
      ls_detail_json-meabm      = ls_dtl_db-meabm.
      ls_detail_json-brgew      = CONV #( ls_dtl_db-brgew ).
      ls_detail_json-gewei      = ls_dtl_db-gewei.
      ls_detail_json-ntgew      = CONV #( ls_dtl_db-ntgew ).
      ls_detail_json-volum      = CONV #( ls_dtl_db-volum ).
      ls_detail_json-ekgrp      = ls_dtl_db-ekgrp.
      ls_detail_json-voleh      = ls_dtl_db-voleh.
      ls_detail_json-kzwsm      = ls_dtl_db-kzwsm.
      ls_detail_json-class      = ls_dtl_db-class.
      ls_detail_json-warna      = ls_dtl_db-warna.
      ls_detail_json-vol_prod   = ls_dtl_db-vol_prod.
      ls_detail_json-dismm      = ls_dtl_db-dismm.
      ls_detail_json-disgr      = ls_dtl_db-disgr.
      ls_detail_json-dispo      = ls_dtl_db-dispo.
      ls_detail_json-disls      = ls_dtl_db-disls.
      ls_detail_json-bstmi      = CONV #( ls_dtl_db-bstmi ).
      ls_detail_json-bstma      = CONV #( ls_dtl_db-bstma ).
      ls_detail_json-bstrf      = CONV #( ls_dtl_db-bstrf ).
      ls_detail_json-beskz      = ls_dtl_db-beskz.
      ls_detail_json-sobsl      = ls_dtl_db-sobsl.
      ls_detail_json-rgekz      = ls_dtl_db-rgekz.
      ls_detail_json-dzeit      = CONV #( ls_dtl_db-dzeit ).
      ls_detail_json-plifz      = CONV #( ls_dtl_db-plifz ).
      ls_detail_json-webaz      = CONV #( ls_dtl_db-webaz ).
      ls_detail_json-fhori      = ls_dtl_db-fhori.
      ls_detail_json-eisbe      = CONV #( ls_dtl_db-eisbe ).
      ls_detail_json-strgr      = ls_dtl_db-strgr.
      ls_detail_json-vrmod      = ls_dtl_db-vrmod.
      ls_detail_json-vint1      = CONV #( ls_dtl_db-vint1 ).
      ls_detail_json-vint2      = CONV #( ls_dtl_db-vint2 ).
      ls_detail_json-perkz      = ls_dtl_db-perkz.
      ls_detail_json-periv      = ls_dtl_db-periv.
      ls_detail_json-mtvfp      = ls_dtl_db-mtvfp.
      ls_detail_json-altsl      = ls_dtl_db-altsl.
      ls_detail_json-kzkst      = ls_dtl_db-kzkst.
      ls_detail_json-ausme      = ls_dtl_db-ausme.
      ls_detail_json-lgpro      = ls_dtl_db-lgpro.
      ls_detail_json-lgpro_ep   = ls_dtl_db-lgpro_ep.
      ls_detail_json-sfpro      = ls_dtl_db-sfpro.
      ls_detail_json-uneto      = CONV #( ls_dtl_db-uneto ).
      ls_detail_json-ueeto      = CONV #( ls_dtl_db-ueeto ).
      ls_detail_json-ueetk      = ls_dtl_db-ueetk.
      ls_detail_json-hkmat      = ls_dtl_db-hkmat.
      ls_detail_json-ekalr      = ls_dtl_db-ekalr.
      ls_detail_json-losgr      = CONV #( ls_dtl_db-losgr ).
      ls_detail_json-ncost      = ls_dtl_db-ncost.
      ls_detail_json-mmsta      = ls_dtl_db-mmsta.
      ls_detail_json-eprio      = ls_dtl_db-eprio.
      ls_detail_json-herbl      = ls_dtl_db-herbl.
      ls_detail_json-klrab      = ls_dtl_db-klrab.
      ls_detail_json-verid      = ls_dtl_db-verid.
      ls_detail_json-perkz_2    = ls_dtl_db-perkz_2.
      ls_detail_json-bwkey      = ls_dtl_db-bwkey.
      ls_detail_json-versg      = ls_dtl_db-versg.
      ls_detail_json-ssqss      = ls_dtl_db-ssqss.
      ls_detail_json-qssys      = ls_dtl_db-qssys.
      ls_detail_json-insptype   = ls_dtl_db-insptype.
      ls_detail_json-sernp      = ls_dtl_db-sernp.
      ls_detail_json-stawn      = ls_dtl_db-stawn.
      ls_detail_json-sales_text = ls_dtl_db-sales_text.

      APPEND ls_detail_json TO lt_detail_json.
    ENDLOOP.

    lv_json = /ui2/cl_json=>serialize( data = lt_detail_json compress = 'X' pretty_name = /ui2/cl_json=>pretty_mode-low_case ).
    _m_response->set_content_type( 'application/json' ).
    _m_response->set_cdata( lv_json ).
    navigation->goto_page( '' ).        " FIXED
    RETURN.


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

  WHEN 'LOGOUT'.
    navigation->exit( ).
    RETURN.
ENDCASE.