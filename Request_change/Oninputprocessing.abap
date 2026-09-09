*&---------------------------------------------------------------------*
*& BSP Page: REQUEST_CHANGE.HTM - Event Handler: OnInputProcessing
*& Module  : SAP Master Data Governance (MDG) - Request Change Material
*& Author  : Master Data Governance Team
*& System  : SAP S/4HANA 1809 On-Premise
*&---------------------------------------------------------------------*

DATA: lv_action        TYPE string,
      lv_json          TYPE string,
      lv_chg_req_no    TYPE string,
      lv_matnr         TYPE string,
      lv_matnr_conv    TYPE mara-matnr,
      lv_werks         TYPE string,
      lv_status        TYPE string,
      lv_change_reason TYPE string,
      lv_count_str     TYPE string,
      lv_count         TYPE i,
      idx_str          TYPE string.

DATA: ls_chg_hdr TYPE zmdg_chg_hdr,
      lt_chg_dtl TYPE TABLE OF zmdg_chg_dtl,
      ls_chg_dtl TYPE zmdg_chg_dtl.

lv_action = request->get_form_field( 'action' ).
IF lv_action IS INITIAL.
  lv_action = request->get_form_field( 'OnInputProcessing' ).
ENDIF.
TRANSLATE lv_action TO UPPER CASE.
CONDENSE lv_action.

CASE lv_action.

  " ==================================================================
  " 1. SEARCH EXISTING SAP MATERIALS (MARA + MAKT + MARC)
  " ==================================================================
  WHEN 'SEARCH_MARA'.
    DATA: lv_str_matnr     TYPE string,
          lv_str_maktx     TYPE string,
          lv_str_mtart     TYPE string,
          lv_str_matkl     TYPE string,
          lv_str_werks     TYPE string,
          lv_filter_matnr  TYPE char40,
          lv_filter_maktx  TYPE char40,
          lv_filter_mtart  TYPE mara-mtart,
          lv_filter_matkl  TYPE char10,
          lv_filter_werks  TYPE marc-werks,
          lv_pattern_matnr TYPE char50,
          lv_pattern_maktx TYPE char50,
          lv_pattern_matkl TYPE char20,
          lv_num_matnr     TYPE mara-matnr.

    TYPES: BEGIN OF ty_search_res,
             matnr TYPE mara-matnr,
             maktx TYPE makt-maktx,
             mtart TYPE mara-mtart,
             matkl TYPE mara-matkl,
             meins TYPE mara-meins,
             bismt TYPE mara-bismt,
             mbrsh TYPE mara-mbrsh,
             werks TYPE marc-werks,
             disgr TYPE marc-disgr,
             dispo TYPE marc-dispo,
             lgpro TYPE marc-lgpro,
             lgfsb TYPE marc-lgfsb,
           END OF ty_search_res.

    DATA: lt_search_res TYPE TABLE OF ty_search_res,
          ls_search_res TYPE ty_search_res.

    lv_str_matnr = request->get_form_field( 'FILTER_MATNR' ).
    lv_str_maktx = request->get_form_field( 'FILTER_MAKTX' ).
    lv_str_mtart = request->get_form_field( 'FILTER_MTART' ).
    lv_str_matkl = request->get_form_field( 'FILTER_MATKL' ).
    lv_str_werks = request->get_form_field( 'FILTER_WERKS' ).

    TRANSLATE lv_str_matnr TO UPPER CASE.
    TRANSLATE lv_str_maktx TO UPPER CASE.
    TRANSLATE lv_str_mtart TO UPPER CASE.
    TRANSLATE lv_str_matkl TO UPPER CASE.
    TRANSLATE lv_str_werks TO UPPER CASE.

    CONDENSE lv_str_matnr.
    CONDENSE lv_str_maktx.
    CONDENSE lv_str_mtart.
    CONDENSE lv_str_matkl.
    CONDENSE lv_str_werks.

    lv_filter_matnr = lv_str_matnr.
    lv_filter_maktx = lv_str_maktx.
    lv_filter_mtart = lv_str_mtart.
    lv_filter_matkl = lv_str_matkl.
    lv_filter_werks = lv_str_werks.

    IF lv_filter_matnr IS NOT INITIAL.
      CONCATENATE '%' lv_str_matnr '%' INTO lv_pattern_matnr.
      IF lv_str_matnr CO '0123456789 '.
        lv_num_matnr = lv_str_matnr.
        CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
          EXPORTING input  = lv_num_matnr
          IMPORTING output = lv_num_matnr.
      ENDIF.
    ENDIF.

    IF lv_filter_maktx IS NOT INITIAL.
      CONCATENATE '%' lv_str_maktx '%' INTO lv_pattern_maktx.
    ENDIF.

    IF lv_filter_matkl IS NOT INITIAL.
      CONCATENATE '%' lv_str_matkl '%' INTO lv_pattern_matkl.
    ENDIF.

    SELECT a~matnr, b~maktx, a~mtart, a~matkl, a~meins, a~bismt,
           a~mbrsh, c~werks, c~disgr, c~dispo, c~lgpro, c~lgfsb
      FROM mara AS a
      LEFT OUTER JOIN makt AS b
        ON a~matnr = b~matnr AND b~spras = @sy-langu
      LEFT OUTER JOIN marc AS c
        ON a~matnr = c~matnr
      WHERE ( @lv_filter_matnr IS INITIAL OR
              a~matnr LIKE @lv_pattern_matnr OR
              ( @lv_num_matnr IS NOT INITIAL AND
                a~matnr = @lv_num_matnr ) )
        AND ( @lv_filter_maktx IS INITIAL OR
              b~maktx LIKE @lv_pattern_maktx )
        AND ( @lv_filter_mtart IS INITIAL OR
              a~mtart = @lv_filter_mtart )
        AND ( @lv_filter_matkl IS INITIAL OR
              a~matkl LIKE @lv_pattern_matkl )
        AND ( @lv_filter_werks IS INITIAL OR
              c~werks = @lv_filter_werks )
      INTO CORRESPONDING FIELDS OF TABLE @lt_search_res
      UP TO 200 ROWS.

    lv_json = /ui2/cl_json=>serialize(
                data        = lt_search_res
                compress    = 'X'
                pretty_name = /ui2/cl_json=>pretty_mode-low_case ).

    _m_response->set_content_type( 'application/json' ).
    _m_response->set_cdata( lv_json ).
    navigation->goto_page( '' ).
    RETURN.


  " ==================================================================
  " 2. GET COMPLETE MATERIAL MASTER DETAIL (MARA, MAKT, MARC, MBEW)
  " ==================================================================
  WHEN 'GET_MATERIAL_DETAIL'.
    lv_matnr = request->get_form_field( 'MATNR' ).
    lv_werks = request->get_form_field( 'WERKS' ).
    CONDENSE lv_matnr.
    CONDENSE lv_werks.

    IF lv_matnr IS INITIAL.
      lv_json = '{"status":"ERROR","message":"Material number is required."}'.
      _m_response->set_content_type( 'application/json' ).
      _m_response->set_cdata( lv_json ).
      navigation->goto_page( '' ).
      RETURN.
    ENDIF.

    lv_matnr_conv = lv_matnr.
    IF lv_matnr_conv CO '0123456789 '.
      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
        EXPORTING input  = lv_matnr_conv
        IMPORTING output = lv_matnr_conv.
    ENDIF.

    TYPES: BEGIN OF ty_full_detail,
             matnr     TYPE mara-matnr,
             maktx     TYPE makt-maktx,
             mtart     TYPE mara-mtart,
             matkl     TYPE mara-matkl,
             meins     TYPE mara-meins,
             bismt     TYPE mara-bismt,
             mbrsh     TYPE mara-mbrsh,
             spart     TYPE mara-spart,
             groes     TYPE mara-groes,
             brgew     TYPE string,
             ntgew     TYPE string,
             gewei     TYPE mara-gewei,
             volum     TYPE string,
             voleh     TYPE mara-voleh,
             " Plant & Storage (MARC)
             werks     TYPE marc-werks,
             lgpro     TYPE marc-lgpro,
             lgfsb     TYPE marc-lgfsb,
             ekgrp     TYPE marc-ekgrp,
             dismm     TYPE marc-dismm,
             disgr     TYPE marc-disgr,
             dispo     TYPE marc-dispo,
             disls     TYPE marc-disls,
             bstmi     TYPE string,
             bstma     TYPE string,
             bstrf     TYPE string,
             plifz     TYPE string,
             dzeit     TYPE string,
             fhori     TYPE marc-fhori,
             eisbe     TYPE string,
             prctr     TYPE marc-prctr,
             " Accounting & Valuation (MBEW)
             bwkey     TYPE mbew-bwkey,
             bklas     TYPE mbew-bklas,
             vprsv     TYPE mbew-vprsv,
             stprs     TYPE string,
             verpr     TYPE string,
             peinh     TYPE string,
           END OF ty_full_detail.

    DATA: ls_detail  TYPE ty_full_detail,
          ls_mara_db TYPE mara,
          ls_makt_db TYPE makt,
          ls_marc_db TYPE marc,
          ls_mbew_db TYPE mbew.

    " 1. Basic Data (MARA)
    SELECT SINGLE * FROM mara INTO @ls_mara_db
      WHERE matnr = @lv_matnr_conv.

    IF sy-subrc <> 0.
      lv_json = '{"status":"ERROR","message":"Material tidak ditemukan di master SAP (MARA)."}'.
      _m_response->set_content_type( 'application/json' ).
      _m_response->set_cdata( lv_json ).
      navigation->goto_page( '' ).
      RETURN.
    ENDIF.

    " 2. Description (MAKT)
    SELECT SINGLE * FROM makt INTO @ls_makt_db
      WHERE matnr = @lv_matnr_conv AND spras = @sy-langu.
    IF sy-subrc <> 0.
      SELECT SINGLE * FROM makt INTO @ls_makt_db
        WHERE matnr = @lv_matnr_conv.
    ENDIF.

    " 3. Plant Data (MARC)
    IF lv_werks IS NOT INITIAL.
      SELECT SINGLE * FROM marc INTO @ls_marc_db
        WHERE matnr = @lv_matnr_conv AND werks = @lv_werks.
    ELSE.
      SELECT SINGLE * FROM marc INTO @ls_marc_db
        WHERE matnr = @lv_matnr_conv.
    ENDIF.

    " 4. Valuation Data (MBEW)
    IF ls_marc_db-werks IS NOT INITIAL.
      SELECT SINGLE * FROM mbew INTO @ls_mbew_db
        WHERE matnr = @lv_matnr_conv AND bwkey = @ls_marc_db-werks.
    ELSE.
      SELECT SINGLE * FROM mbew INTO @ls_mbew_db
        WHERE matnr = @lv_matnr_conv.
    ENDIF.

    " Map to JSON Structure
    ls_detail-matnr = ls_mara_db-matnr.
    ls_detail-maktx = ls_makt_db-maktx.
    ls_detail-mtart = ls_mara_db-mtart.
    ls_detail-matkl = ls_mara_db-matkl.
    ls_detail-meins = ls_mara_db-meins.
    ls_detail-bismt = ls_mara_db-bismt.
    ls_detail-mbrsh = ls_mara_db-mbrsh.
    ls_detail-spart = ls_mara_db-spart.
    ls_detail-groes = ls_mara_db-groes.
    ls_detail-brgew = |{ ls_mara_db-brgew }|.
    ls_detail-ntgew = |{ ls_mara_db-ntgew }|.
    ls_detail-gewei = ls_mara_db-gewei.
    ls_detail-volum = |{ ls_mara_db-volum }|.
    ls_detail-voleh = ls_mara_db-voleh.

    ls_detail-werks = ls_marc_db-werks.
    ls_detail-lgpro = ls_marc_db-lgpro.
    ls_detail-lgfsb = ls_marc_db-lgfsb.
    ls_detail-ekgrp = ls_marc_db-ekgrp.
    ls_detail-dismm = ls_marc_db-dismm.
    ls_detail-disgr = ls_marc_db-disgr.
    ls_detail-dispo = ls_marc_db-dispo.
    ls_detail-disls = ls_marc_db-disls.
    ls_detail-bstmi = |{ ls_marc_db-bstmi }|.
    ls_detail-bstma = |{ ls_marc_db-bstma }|.
    ls_detail-bstrf = |{ ls_marc_db-bstrf }|.
    ls_detail-plifz = |{ ls_marc_db-plifz }|.
    ls_detail-dzeit = |{ ls_marc_db-dzeit }|.
    ls_detail-fhori = ls_marc_db-fhori.
    ls_detail-eisbe = |{ ls_marc_db-eisbe }|.
    ls_detail-prctr = ls_marc_db-prctr.

    ls_detail-bwkey = ls_mbew_db-bwkey.
    ls_detail-bklas = ls_mbew_db-bklas.
    ls_detail-vprsv = ls_mbew_db-vprsv.
    ls_detail-stprs = |{ ls_mbew_db-stprs }|.
    ls_detail-verpr = |{ ls_mbew_db-verpr }|.
    ls_detail-peinh = |{ ls_mbew_db-peinh }|.

    CONDENSE ls_detail-brgew.
    CONDENSE ls_detail-ntgew.
    CONDENSE ls_detail-volum.
    CONDENSE ls_detail-bstmi.
    CONDENSE ls_detail-bstma.
    CONDENSE ls_detail-bstrf.
    CONDENSE ls_detail-plifz.
    CONDENSE ls_detail-dzeit.
    CONDENSE ls_detail-eisbe.
    CONDENSE ls_detail-stprs.
    CONDENSE ls_detail-verpr.
    CONDENSE ls_detail-peinh.

    lv_json = /ui2/cl_json=>serialize(
                data        = ls_detail
                compress    = 'X'
                pretty_name = /ui2/cl_json=>pretty_mode-low_case ).

    _m_response->set_content_type( 'application/json' ).
    _m_response->set_cdata( lv_json ).
    navigation->goto_page( '' ).
    RETURN.


  " ==================================================================
  " 3. SAVE DRAFT OR SUBMIT CHANGE REQUEST
  " ==================================================================
  WHEN 'SAVE_CHANGE' OR 'SUBMIT_CHANGE'.
    lv_chg_req_no    = request->get_form_field( 'CHG_REQ_NO' ).
    lv_matnr         = request->get_form_field( 'MATNR' ).
    lv_werks         = request->get_form_field( 'WERKS' ).
    lv_status        = request->get_form_field( 'STATUS' ).
    lv_change_reason = request->get_form_field( 'CHANGE_REASON' ).
    lv_count_str     = request->get_form_field( 'CHANGES_COUNT' ).
    lv_count         = lv_count_str.

    CONDENSE lv_matnr.
    CONDENSE lv_werks.
    CONDENSE lv_status.

    IF lv_status IS INITIAL.
      IF lv_action = 'SUBMIT_CHANGE'.
        lv_status = 'SUBMITTED'.
      ELSE.
        lv_status = 'DRAFT'.
      ENDIF.
    ENDIF.

    IF lv_matnr IS INITIAL.
      lv_json = '{"status":"ERROR","message":"Material Number wajib diisi."}'.
      _m_response->set_content_type( 'application/json' ).
      _m_response->set_cdata( lv_json ).
      navigation->goto_page( '' ).
      RETURN.
    ENDIF.

    IF lv_status = 'SUBMITTED' AND lv_count <= 0.
      lv_json = '{"status":"ERROR","message":"Tidak ada perubahan data yang dilakukan. Silakan lakukan perubahan field sebelum submit."}'.
      _m_response->set_content_type( 'application/json' ).
      _m_response->set_cdata( lv_json ).
      navigation->goto_page( '' ).
      RETURN.
    ENDIF.

    IF lv_status = 'SUBMITTED' AND lv_change_reason IS INITIAL.
      lv_json = '{"status":"ERROR","message":"Alasan/justifikasi perubahan (Change Reason) wajib diisi."}'.
      _m_response->set_content_type( 'application/json' ).
      _m_response->set_cdata( lv_json ).
      navigation->goto_page( '' ).
      RETURN.
    ENDIF.

    " Generate Request ID jika belum ada
    IF lv_chg_req_no IS INITIAL.
      lv_chg_req_no = |CHG-{ sy-datum }-{ sy-uzeit }|.
    ENDIF.

    " Validasi eksistensi material di SAP
    lv_matnr_conv = lv_matnr.
    IF lv_matnr_conv CO '0123456789 '.
      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
        EXPORTING input  = lv_matnr_conv
        IMPORTING output = lv_matnr_conv.
    ENDIF.

    SELECT SINGLE mtart, mbrsh FROM mara
      INTO (@ls_chg_hdr-mtart, @ls_chg_hdr-mbrsh)
      WHERE matnr = @lv_matnr_conv.

    IF sy-subrc <> 0.
      lv_json = '{"status":"ERROR","message":"Material tidak valid atau tidak ditemukan di SAP MARA."}'.
      _m_response->set_content_type( 'application/json' ).
      _m_response->set_cdata( lv_json ).
      navigation->goto_page( '' ).
      RETURN.
    ENDIF.

    SELECT SINGLE maktx FROM makt INTO @ls_chg_hdr-old_maktx
      WHERE matnr = @lv_matnr_conv AND spras = @sy-langu.
    IF sy-subrc <> 0.
      SELECT SINGLE maktx FROM makt INTO @ls_chg_hdr-old_maktx
        WHERE matnr = @lv_matnr_conv.
    ENDIF.

    ls_chg_hdr-new_maktx = ls_chg_hdr-old_maktx.

    " Prepare Header
    ls_chg_hdr-chg_req_no    = CONV #( lv_chg_req_no ).
    ls_chg_hdr-matnr         = lv_matnr_conv.
    ls_chg_hdr-werks         = CONV #( lv_werks ).
    ls_chg_hdr-status        = CONV #( lv_status ).
    ls_chg_hdr-total_changes = lv_count.
    ls_chg_hdr-change_reason = lv_change_reason.
    ls_chg_hdr-requestor     = sy-uname.
    ls_chg_hdr-req_date      = sy-datum.
    ls_chg_hdr-req_time      = sy-uzeit.

    " Prepare Item Details
    CLEAR lt_chg_dtl.
    DO lv_count TIMES.
      idx_str = sy-index.
      CONDENSE idx_str.
      CLEAR ls_chg_dtl.

      ls_chg_dtl-chg_req_no  = ls_chg_hdr-chg_req_no.
      ls_chg_dtl-item_no     = sy-index.
      ls_chg_dtl-table_name  = request->get_form_field( |table_name_{ idx_str }| ).
      ls_chg_dtl-field_name  = request->get_form_field( |field_name_{ idx_str }| ).
      ls_chg_dtl-field_label = request->get_form_field( |field_label_{ idx_str }| ).
      ls_chg_dtl-old_value   = request->get_form_field( |old_val_{ idx_str }| ).
      ls_chg_dtl-new_value   = request->get_form_field( |new_val_{ idx_str }| ).
      ls_chg_dtl-status      = 'PENDING'.

      " Jika deskripsi material diubah, catat di header
      IF ls_chg_dtl-field_name = 'MAKTX' AND ls_chg_dtl-new_value IS NOT INITIAL.
        ls_chg_hdr-new_maktx = CONV #( ls_chg_dtl-new_value ).
      ENDIF.

      " Validasi Storage Location jika diubah
      IF ls_chg_dtl-field_name = 'LGPRO' OR ls_chg_dtl-field_name = 'LGORT'.
        IF ls_chg_hdr-werks IS NOT INITIAL AND ls_chg_dtl-new_value IS NOT INITIAL.
          SELECT SINGLE lgort FROM t001l INTO @DATA(lv_check_lgort)
            WHERE werks = @ls_chg_hdr-werks AND lgort = @ls_chg_dtl-new_value.
          IF sy-subrc <> 0.
            lv_json = |\{"status":"ERROR","message":"Storage Location '{ ls_chg_dtl-new_value }' tidak valid untuk Plant '{ ls_chg_hdr-werks }' (T001L)."\}|.
            _m_response->set_content_type( 'application/json' ).
            _m_response->set_cdata( lv_json ).
            navigation->goto_page( '' ).
            RETURN.
          ENDIF.
        ENDIF.
      ENDIF.

      APPEND ls_chg_dtl TO lt_chg_dtl.
    ENDDO.

    " Save Database
    MODIFY zmdg_chg_hdr FROM @ls_chg_hdr.
    DELETE FROM zmdg_chg_dtl WHERE chg_req_no = @ls_chg_hdr-chg_req_no.
    IF lt_chg_dtl IS NOT INITIAL.
      MODIFY zmdg_chg_dtl FROM TABLE @lt_chg_dtl.
    ENDIF.
    COMMIT WORK AND WAIT.

    DATA: lv_msg_text TYPE string.
    IF lv_status = 'SUBMITTED'.
      lv_msg_text = |Permohonan perubahan material { lv_matnr } berhasil disubmit dengan Request ID: { lv_chg_req_no }.|.
    ELSE.
      lv_msg_text = |Draft permohonan perubahan { lv_chg_req_no } berhasil disimpan.|.
    ENDIF.

    lv_json = |\{"status":"SUCCESS","chg_req_no":"{ lv_chg_req_no }","message":"{ lv_msg_text }","total_changes":{ lv_count }\}|.
    _m_response->set_content_type( 'application/json' ).
    _m_response->set_cdata( lv_json ).
    navigation->goto_page( '' ).
    RETURN.


  " ==================================================================
  " 4. GET CHANGE REQUEST HISTORY LIST
  " ==================================================================
  WHEN 'GET_HISTORY'.
    TYPES: BEGIN OF ty_hist_res.
             INCLUDE TYPE zmdg_chg_hdr.
    TYPES:   matkl TYPE mara-matkl,
             dismm TYPE marc-dismm,
             disgr TYPE marc-disgr,
             lgort TYPE mard-lgort,
           END OF ty_hist_res.

    DATA: lt_raw_hdr  TYPE TABLE OF zmdg_chg_hdr,
          ls_raw_hdr  TYPE zmdg_chg_hdr,
          lt_hist_res TYPE TABLE OF ty_hist_res,
          ls_hist_res TYPE ty_hist_res,
          lv_mat_c    TYPE mara-matnr,
          lv_marc_lg  TYPE marc-lgpro,
          lt_dtl_c    TYPE TABLE OF zmdg_chg_dtl,
          ls_dtl_c    TYPE zmdg_chg_dtl,
          lv_m_mtart  TYPE mara-mtart,
          lv_m_matkl  TYPE mara-matkl.

    SELECT * FROM zmdg_chg_hdr
      INTO TABLE @lt_raw_hdr
      ORDER BY req_date DESCENDING, req_time DESCENDING.

    LOOP AT lt_raw_hdr INTO ls_raw_hdr.
      CLEAR: ls_hist_res, lv_mat_c, lv_marc_lg, lt_dtl_c,
             lv_m_mtart, lv_m_matkl.
      MOVE-CORRESPONDING ls_raw_hdr TO ls_hist_res.

      lv_mat_c = ls_raw_hdr-matnr.
      IF lv_mat_c CO '0123456789 '.
        CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
          EXPORTING input  = lv_mat_c
          IMPORTING output = lv_mat_c.
      ENDIF.

      " 1. Ambil data aktual dari MARA (Material Type MTART & Material Group MATKL)
      SELECT SINGLE mtart, matkl FROM mara
        INTO ( @lv_m_mtart, @lv_m_matkl )
        WHERE matnr = @lv_mat_c.

      IF ls_hist_res-mtart IS INITIAL.
        ls_hist_res-mtart = lv_m_mtart.
      ENDIF.
      ls_hist_res-matkl = lv_m_matkl.

      " 2. Ambil data aktual dari MARC (MRP Type & MRP Group)
      IF ls_raw_hdr-werks IS NOT INITIAL.
        SELECT SINGLE dismm, disgr, lgpro FROM marc
          INTO ( @ls_hist_res-dismm, @ls_hist_res-disgr, @lv_marc_lg )
          WHERE matnr = @lv_mat_c AND werks = @ls_raw_hdr-werks.
      ELSE.
        SELECT SINGLE dismm, disgr, lgpro FROM marc
          INTO ( @ls_hist_res-dismm, @ls_hist_res-disgr, @lv_marc_lg )
          WHERE matnr = @lv_mat_c.
      ENDIF.

      " 3. Ambil data aktual dari MARD (Inspection / Storage Location)
      IF ls_raw_hdr-werks IS NOT INITIAL.
        IF lv_marc_lg IS NOT INITIAL.
          SELECT SINGLE lgort FROM mard INTO @ls_hist_res-lgort
            WHERE matnr = @lv_mat_c AND werks = @ls_raw_hdr-werks
              AND lgort = @lv_marc_lg.
        ENDIF.
        IF ls_hist_res-lgort IS INITIAL.
          SELECT SINGLE lgort FROM mard INTO @ls_hist_res-lgort
            WHERE matnr = @lv_mat_c AND werks = @ls_raw_hdr-werks.
        ENDIF.
      ENDIF.
      IF ls_hist_res-lgort IS INITIAL AND lv_marc_lg IS NOT INITIAL.
        ls_hist_res-lgort = lv_marc_lg.
      ENDIF.

      " 4. Jika permohonan spesifik mengubah field tersebut, gunakan new_val
      SELECT * FROM zmdg_chg_dtl INTO TABLE @lt_dtl_c
        WHERE chg_req_no = @ls_raw_hdr-chg_req_no.
      LOOP AT lt_dtl_c INTO ls_dtl_c.
        IF ls_dtl_c-field_name = 'MTART' AND ls_dtl_c-new_value IS NOT INITIAL.
          ls_hist_res-mtart = CONV #( ls_dtl_c-new_value ).
        ENDIF.
        IF ls_dtl_c-field_name = 'MATKL' AND ls_dtl_c-new_value IS NOT INITIAL.
          ls_hist_res-matkl = CONV #( ls_dtl_c-new_value ).
        ENDIF.
        IF ls_dtl_c-field_name = 'DISMM' AND ls_dtl_c-new_value IS NOT INITIAL.
          ls_hist_res-dismm = CONV #( ls_dtl_c-new_value ).
        ENDIF.
        IF ls_dtl_c-field_name = 'DISGR' AND ls_dtl_c-new_value IS NOT INITIAL.
          ls_hist_res-disgr = CONV #( ls_dtl_c-new_value ).
        ENDIF.
        IF ( ls_dtl_c-field_name = 'LGPRO' OR ls_dtl_c-field_name = 'LGORT' )
           AND ls_dtl_c-new_value IS NOT INITIAL.
          ls_hist_res-lgort = CONV #( ls_dtl_c-new_value ).
        ENDIF.
      ENDLOOP.

      APPEND ls_hist_res TO lt_hist_res.
    ENDLOOP.

    lv_json = /ui2/cl_json=>serialize(
                data        = lt_hist_res
                compress    = 'X'
                pretty_name = /ui2/cl_json=>pretty_mode-low_case ).

    _m_response->set_content_type( 'application/json' ).
    _m_response->set_cdata( lv_json ).
    navigation->goto_page( '' ).
    RETURN.


  " ==================================================================
  " 5. GET DETAIL OF A CHANGE REQUEST (FOR REVIEW / EDIT DRAFT)
  " ==================================================================
  WHEN 'GET_CHANGE_DETAIL'.
    lv_chg_req_no = request->get_form_field( 'CHG_REQ_NO' ).
    CONDENSE lv_chg_req_no.

    TYPES: BEGIN OF ty_chg_full_info,
             header  TYPE zmdg_chg_hdr,
             changes TYPE TABLE OF zmdg_chg_dtl WITH DEFAULT KEY,
           END OF ty_chg_full_info.

    DATA: ls_chg_info TYPE ty_chg_full_info.

    SELECT SINGLE * FROM zmdg_chg_hdr INTO CORRESPONDING FIELDS OF @ls_chg_info-header
      WHERE chg_req_no = @lv_chg_req_no.

    IF sy-subrc = 0.
      SELECT * FROM zmdg_chg_dtl INTO CORRESPONDING FIELDS OF TABLE @ls_chg_info-changes
        WHERE chg_req_no = @lv_chg_req_no
        ORDER BY item_no ASCENDING.
    ENDIF.

    lv_json = /ui2/cl_json=>serialize(
                data        = ls_chg_info
                compress    = 'X'
                pretty_name = /ui2/cl_json=>pretty_mode-low_case ).

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
