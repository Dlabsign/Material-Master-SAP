DATA: lv_action     TYPE string,
      lv_json       TYPE string,
      lv_req_id     TYPE string,
      lv_upload_id  TYPE string,
      lv_filename   TYPE string,
      lv_status     TYPE string,
      lv_count_str  TYPE string,
      lv_count      TYPE i,
      idx_str       TYPE string,
      lv_losgr_raw  TYPE string.

DATA: ls_hdr TYPE zmdg_req_hdr,
      lt_dtl TYPE TABLE OF zmdg_req_dtl,
      ls_dtl TYPE zmdg_req_dtl.

TYPES: BEGIN OF ty_hdr_db,
         req_no    TYPE zmdg_req_hdr-req_no,
         remarks   TYPE zmdg_req_hdr-remarks,
         req_date  TYPE zmdg_req_hdr-req_date,
         req_time  TYPE zmdg_req_hdr-req_time,
         requestor TYPE zmdg_req_hdr-requestor,
         status    TYPE zmdg_req_hdr-status,
       END OF ty_hdr_db.

DATA: lt_hdr_db TYPE TABLE OF ty_hdr_db,
      ls_hdr_db TYPE ty_hdr_db.

DATA: lt_dtl_db TYPE TABLE OF zmdg_req_dtl,
      ls_dtl_db TYPE zmdg_req_dtl.

TYPES: BEGIN OF ty_history,
         upload_id TYPE string,
         filename  TYPE string,
         erdat     TYPE string,
         ertim     TYPE string,
         total_row TYPE i,
         ernam     TYPE string,
         status    TYPE string,
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
       END OF ty_detail_json.
DATA: lt_detail_json TYPE TABLE OF ty_detail_json,
      ls_detail_json TYPE ty_detail_json.

lv_action = request->get_form_field( 'OnInputProcessing' ).

CASE lv_action.

  " ==================================================================
  " 1. SAVE STAGING DATA FROM JS FETCH API
  " ==================================================================
  WHEN 'SAVE_STAGE'.
    lv_req_id    = request->get_form_field( 'REQ_ID' ).
    lv_upload_id = request->get_form_field( 'UPLOAD_ID' ).
    lv_filename  = request->get_form_field( 'FILENAME' ).
    lv_status    = request->get_form_field( 'STATUS' ).
    lv_count_str = request->get_form_field( 'ROW_COUNT' ).
    lv_count     = lv_count_str.

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

    ls_hdr-req_no    = CONV #( lv_upload_id ).
    ls_hdr-status    = CONV #( lv_status ).
    ls_hdr-requestor = sy-uname.
    ls_hdr-req_date  = sy-datum.
    ls_hdr-req_time  = sy-uzeit.
    ls_hdr-remarks   = CONV #( lv_filename ).
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
      ls_dtl-vhart      = request->get_form_field( |vhart_{ idx_str }| ).
      ls_dtl-xchpf      = request->get_form_field( |xchpf_{ idx_str }| ).
      ls_dtl-prctr      = request->get_form_field( |prctr_{ idx_str }| ).
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

      lv_losgr_raw      = request->get_form_field( |losgr_{ idx_str }| ).
      REPLACE ALL OCCURRENCES OF ',' IN lv_losgr_raw WITH '.'.
      ls_dtl-losgr      = CONV #( lv_losgr_raw ).

      APPEND ls_dtl TO lt_dtl.
    ENDDO.

    IF lt_dtl IS NOT INITIAL.
      MODIFY zmdg_req_dtl FROM TABLE @lt_dtl.
    ENDIF.

    lv_json = |\{"status":"SUCCESS","upload_id":"{ lv_upload_id }","message":"Data berhasil disimpan!"\}|.
    _m_response->set_content_type( 'application/json' ).
    _m_response->set_cdata( lv_json ).
    navigation->goto_page( '' ).        " FIXED: cegah BSP merender layout setelah JSON
    RETURN.


  " ==================================================================
  " 2. FETCH BATCH HISTORY
  " ==================================================================
  WHEN 'GET_HISTORY'.
    CLEAR: lt_hdr_db, lt_history.

    SELECT req_no, remarks, req_date, req_time, requestor, status
      FROM zmdg_req_hdr
      INTO TABLE @lt_hdr_db
      ORDER BY req_date DESCENDING, req_time DESCENDING.

    LOOP AT lt_hdr_db INTO ls_hdr_db.
      CLEAR ls_history.
      ls_history-upload_id = ls_hdr_db-req_no.
      ls_history-filename  = ls_hdr_db-remarks.
      ls_history-erdat     = ls_hdr_db-req_date.
      ls_history-ertim     = ls_hdr_db-req_time.
      ls_history-ernam     = ls_hdr_db-requestor.
      ls_history-status    = ls_hdr_db-status.

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

      APPEND ls_detail_json TO lt_detail_json.
    ENDLOOP.

    lv_json = /ui2/cl_json=>serialize( data = lt_detail_json compress = 'X' pretty_name = /ui2/cl_json=>pretty_mode-low_case ).
    _m_response->set_content_type( 'application/json' ).
    _m_response->set_cdata( lv_json ).
    navigation->goto_page( '' ).        " FIXED
    RETURN.


  WHEN 'LOGOUT'.
    navigation->exit( ).
    RETURN.

ENDCASE.