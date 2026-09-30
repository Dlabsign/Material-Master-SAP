*"----------------------------------------------------------------------*
*" BSP ONINPUTPROCESSING FOR INFO RECORD (ME11) STAGING WORKFLOW
*"----------------------------------------------------------------------*

DATA: lv_action     TYPE string,
      lv_req_id     TYPE string,
      lv_lifnr      TYPE string,
      lv_matnr      TYPE string,
      lv_txz01      TYPE string,
      lv_matkl      TYPE string,
      lv_idnlf      TYPE string,
      lv_action_typ TYPE string,
      lv_status     TYPE string,
      lv_sub_reason TYPE string,
      lv_row_count  TYPE i,
      lv_rc_str     TYPE string,
      idx           TYPE i,
      idx_str       TYPE string.

DATA: ls_hdr TYPE zmdg_req_pir,
      ls_itm TYPE zmdg_pir_itm,
      lt_itm TYPE TABLE OF zmdg_pir_itm,
      ls_cnd TYPE zmdg_pir_cnd,
      lt_cnd TYPE TABLE OF zmdg_pir_cnd,
      ls_adt TYPE zmdg_pir_adt,
      lt_adt TYPE TABLE OF zmdg_pir_adt.

DATA: lv_timestamp TYPE string,
      lv_time_raw   TYPE c LENGTH 6,
      lv_date_raw   TYPE c LENGTH 8,
      lv_json_out   TYPE string,
      lv_err_msg    TYPE string,
      lv_search_key TYPE string.

" 1. Extract Event Action Parameter
lv_action = request->get_form_field( 'OnInputProcessing' ).
IF lv_action IS INITIAL.
  lv_action = request->get_form_field( 'action' ).
ENDIF.

CASE lv_action.

  " ====================================================================
  " ACTION: SAVE_STAGE (Submit or Save Draft to Staging)
  " ====================================================================
  WHEN 'SAVE_STAGE'.
    lv_req_id     = request->get_form_field( 'REQ_ID' ).
    lv_lifnr      = request->get_form_field( 'LIFNR' ).
    lv_matnr      = request->get_form_field( 'MATNR' ).
    lv_txz01      = request->get_form_field( 'TXZ01' ).
    lv_matkl      = request->get_form_field( 'MATKL' ).
    lv_idnlf      = request->get_form_field( 'IDNLF' ).
    lv_action_typ = request->get_form_field( 'ACTION_TYPE' ).
    lv_status     = request->get_form_field( 'STATUS' ).
    lv_sub_reason = request->get_form_field( 'SUB_REASON' ).
    lv_rc_str     = request->get_form_field( 'ROW_COUNT' ).

    IF lv_action_typ IS INITIAL.
      lv_action_typ = '01'. " Default: Create
    ENDIF.
    IF lv_status IS INITIAL.
      lv_status = '01'. " Submitted
    ENDIF.

    " Basic Mandatory Field Validations
    IF lv_lifnr IS INITIAL.
      gv_json_response = '{"status":"ERROR","message":"' &&
        'Vendor / Supplier Number (LIFNR) wajib diisi!"}'.
      _m_response->set_content_type( 'application/json' ).
      _m_response->set_cdata( gv_json_response ).
      _m_navigation->response_complete( ).
      RETURN.
    ENDIF.

    IF lv_matnr IS INITIAL AND lv_txz01 IS INITIAL.
      gv_json_response = '{"status":"ERROR","message":"' &&
        'Wajib mengisi Nomor Material (MATNR) atau Short Text!"}'.
      _m_response->set_content_type( 'application/json' ).
      _m_response->set_cdata( gv_json_response ).
      _m_navigation->response_complete( ).
      RETURN.
    ENDIF.

    " ------------------------------------------------------------------
    " SAP ALPHA Conversion for Vendor (LIFNR) & Material (MATNR)
    " ------------------------------------------------------------------
    DATA: lv_lifnr_alpha TYPE lifnr,
          lv_matnr_alpha TYPE matnr.

    lv_lifnr_alpha = lv_lifnr.
    IF lv_lifnr IS NOT INITIAL AND lv_lifnr CO '0123456789 '.
      UNPACK lv_lifnr TO lv_lifnr_alpha.
    ENDIF.

    lv_matnr_alpha = lv_matnr.
    IF lv_matnr IS NOT INITIAL AND lv_matnr CO '0123456789 '.
      UNPACK lv_matnr TO lv_matnr_alpha.
    ENDIF.

    " Generate REQ_ID if blank
    IF lv_req_id IS INITIAL OR lv_req_id CS 'Auto-Generated'.
      lv_date_raw = sy-datum.
      lv_time_raw = sy-uzeit.
      CONCATENATE 'PIR' lv_time_raw INTO lv_req_id.
      CONCATENATE 'REQ-' lv_req_id INTO lv_req_id.
    ENDIF.

    " Process Line Items (ZMDG_PIR_ITM)
    lv_row_count = lv_rc_str.
    IF lv_row_count <= 0.
      lv_row_count = 1.
    ENDIF.

    CLEAR lt_itm.
    DO lv_row_count TIMES.
      idx = sy-index.
      idx_str = idx.
      CONDENSE idx_str.

      CLEAR ls_itm.
      ls_itm-mandt   = sy-mandt.
      ls_itm-req_id  = lv_req_id.
      ls_itm-item_no = idx * 10.

      CONCATENATE 'EKORG_' idx_str INTO lv_err_msg.
      ls_itm-ekorg = request->get_form_field( lv_err_msg ).
      IF ls_itm-ekorg IS INITIAL AND idx = 1.
        ls_itm-ekorg = request->get_form_field( 'EKORG' ).
      ENDIF.

      CONCATENATE 'WERKS_' idx_str INTO lv_err_msg.
      ls_itm-werks = request->get_form_field( lv_err_msg ).
      IF ls_itm-werks IS INITIAL AND idx = 1.
        ls_itm-werks = request->get_form_field( 'WERKS' ).
      ENDIF.

      CONCATENATE 'ESOKZ_' idx_str INTO lv_err_msg.
      ls_itm-esokz = request->get_form_field( lv_err_msg ).
      IF ls_itm-esokz IS INITIAL. ls_itm-esokz = '0'. ENDIF.

      CONCATENATE 'EKGRP_' idx_str INTO lv_err_msg.
      ls_itm-ekgrp = request->get_form_field( lv_err_msg ).

      CONCATENATE 'APLFZ_' idx_str INTO lv_err_msg.
      ls_itm-aplfz = request->get_form_field( lv_err_msg ).

      CONCATENATE 'NORBM_' idx_str INTO lv_err_msg.
      ls_itm-norbm = request->get_form_field( lv_err_msg ).

      CONCATENATE 'MINBM_' idx_str INTO lv_err_msg.
      ls_itm-minbm = request->get_form_field( lv_err_msg ).

      CONCATENATE 'UEBTO_' idx_str INTO lv_err_msg.
      ls_itm-uebto = request->get_form_field( lv_err_msg ).

      CONCATENATE 'UNTTO_' idx_str INTO lv_err_msg.
      ls_itm-untto = request->get_form_field( lv_err_msg ).

      CONCATENATE 'NETPR_' idx_str INTO lv_err_msg.
      ls_itm-netpr = request->get_form_field( lv_err_msg ).

      CONCATENATE 'WAERS_' idx_str INTO lv_err_msg.
      ls_itm-waers = request->get_form_field( lv_err_msg ).
      IF ls_itm-waers IS INITIAL. ls_itm-waers = 'IDR'. ENDIF.

      CONCATENATE 'PEINH_' idx_str INTO lv_err_msg.
      ls_itm-peinh = request->get_form_field( lv_err_msg ).
      IF ls_itm-peinh IS INITIAL. ls_itm-peinh = 1. ENDIF.

      CONCATENATE 'BPRME_' idx_str INTO lv_err_msg.
      ls_itm-bprme = request->get_form_field( lv_err_msg ).

      CONCATENATE 'MWSKZ_' idx_str INTO lv_err_msg.
      ls_itm-mwskz = request->get_form_field( lv_err_msg ).

      CONCATENATE 'INCO1_' idx_str INTO lv_err_msg.
      ls_itm-inco1 = request->get_form_field( lv_err_msg ).

      CONCATENATE 'INCO2_' idx_str INTO lv_err_msg.
      ls_itm-inco2 = request->get_form_field( lv_err_msg ).

      CONCATENATE 'DATAB_' idx_str INTO lv_err_msg.
      ls_itm-datab = request->get_form_field( lv_err_msg ).
      REPLACE ALL OCCURRENCES OF '-' IN ls_itm-datab WITH ''.

      CONCATENATE 'DATBI_' idx_str INTO lv_err_msg.
      ls_itm-datbi = request->get_form_field( lv_err_msg ).
      REPLACE ALL OCCURRENCES OF '-' IN ls_itm-datbi WITH ''.

      ls_itm-post_status = ' '.

      " ----------------------------------------------------------------
      " SAP Standard Validation Rules (LFM1, MARC, EINA/EINE)
      " ----------------------------------------------------------------
      IF ls_itm-ekorg IS NOT INITIAL.
        DATA: lv_chk_lfm1 TYPE lifnr.
        SELECT SINGLE lifnr FROM lfm1 INTO lv_chk_lfm1
          WHERE ( lifnr = lv_lifnr OR lifnr = lv_lifnr_alpha )
            AND ekorg = ls_itm-ekorg.
        IF sy-subrc <> 0.
          gv_json_response = '{"status":"ERROR","message":"' &&
            'Vendor ' && lv_lifnr && ' tidak terdaftar pada Purch Org ' &&
            ls_itm-ekorg && '!"}'.
          _m_response->set_content_type( 'application/json' ).
          _m_response->set_cdata( gv_json_response ).
          _m_navigation->response_complete( ).
          RETURN.
        ENDIF.
      ENDIF.

      IF lv_matnr IS NOT INITIAL AND ls_itm-werks IS NOT INITIAL.
        DATA: lv_chk_marc TYPE matnr.
        SELECT SINGLE matnr FROM marc INTO lv_chk_marc
          WHERE ( matnr = lv_matnr OR matnr = lv_matnr_alpha )
            AND werks = ls_itm-werks.
        IF sy-subrc <> 0.
          gv_json_response = '{"status":"ERROR","message":"' &&
            'Material ' && lv_matnr && ' tidak aktif untuk Plant ' &&
            ls_itm-werks && '!"}'.
          _m_response->set_content_type( 'application/json' ).
          _m_response->set_cdata( gv_json_response ).
          _m_navigation->response_complete( ).
          RETURN.
        ENDIF.
      ENDIF.

      IF lv_matnr IS NOT INITIAL AND ls_itm-ekorg IS NOT INITIAL.
        DATA: lv_chk_pir TYPE infnr.
        SELECT SINGLE a~infnr FROM eina AS a
          INNER JOIN eine AS b ON a~infnr = b~infnr
          INTO lv_chk_pir
          WHERE ( a~lifnr = lv_lifnr OR a~lifnr = lv_lifnr_alpha )
            AND ( a~matnr = lv_matnr OR a~matnr = lv_matnr_alpha )
            AND b~ekorg = ls_itm-ekorg
            AND b~werks = ls_itm-werks
            AND b~esokz = ls_itm-esokz.
        IF sy-subrc = 0.
          gv_json_response = '{"status":"ERROR","message":"' &&
            'Info Record untuk Vendor, Material, Org & Plant ini ' &&
            'SUDAH ADA di SAP dengan Nomor: ' && lv_chk_pir && '!"}'.
          _m_response->set_content_type( 'application/json' ).
          _m_response->set_cdata( gv_json_response ).
          _m_navigation->response_complete( ).
          RETURN.
        ENDIF.
      ENDIF.

      APPEND ls_itm TO lt_itm.
    ENDDO.

    " Prepare Header Record (ZMDG_REQ_PIR)
    CLEAR ls_hdr.
    ls_hdr-mandt       = sy-mandt.
    ls_hdr-req_id      = lv_req_id.
    ls_hdr-action_type = lv_action_typ.
    ls_hdr-status      = lv_status.
    ls_hdr-lifnr       = lv_lifnr_alpha.
    ls_hdr-matnr       = lv_matnr_alpha.
    ls_hdr-txz01       = lv_txz01.
    ls_hdr-matkl       = lv_matkl.
    ls_hdr-idnlf       = lv_idnlf.
    ls_hdr-ernam       = sy-uname.
    ls_hdr-erdat       = sy-datum.
    ls_hdr-erzet       = sy-uzeit.
    ls_hdr-aenam       = sy-uname.
    ls_hdr-aedat       = sy-datum.
    ls_hdr-aezet       = sy-uzeit.

    MODIFY zmdg_req_pir FROM ls_hdr.

    DELETE FROM zmdg_pir_itm WHERE req_id = lv_req_id.
    IF lt_itm IS NOT INITIAL.
      INSERT zmdg_pir_itm FROM TABLE lt_itm.
    ENDIF.

    " Audit Log Insertion (ZMDG_PIR_ADT)
    CLEAR ls_adt.
    ls_adt-mandt      = sy-mandt.
    ls_adt-req_id     = lv_req_id.
    ls_adt-log_id     = 1.
    ls_adt-approv_lvl = 1.
    IF lv_status = '00'.
      ls_adt-action   = 'SAVE_DRAFT'.
    ELSE.
      ls_adt-action   = 'SUBMIT'.
    ENDIF.
    ls_adt-actor      = sy-uname.
    ls_adt-act_date   = sy-datum.
    ls_adt-act_time   = sy-uzeit.
    ls_adt-comments   = lv_sub_reason.

    MODIFY zmdg_pir_adt FROM ls_adt.

    " Explicit Database Commit
    COMMIT WORK.

    CONCATENATE '{"status":"SUCCESS","req_id":"' lv_req_id
      '","message":"Request Info Record berhasil disimpan '
      'ke Staging Database!"}' INTO gv_json_response.
    _m_response->set_content_type( 'application/json' ).
    _m_response->set_cdata( gv_json_response ).
    _m_navigation->response_complete( ).
    RETURN.

  " ====================================================================
  " ACTION: SEARCH_VENDOR (F4 Wildcard Lookup for Vendors - LFA1 JOIN LFM1)
  " ====================================================================
  WHEN 'SEARCH_VENDOR'.
    lv_search_key = request->get_form_field( 'query' ).
    IF lv_search_key IS INITIAL OR lv_search_key = '*'.
      lv_search_key = '%'.
    ELSE.
      REPLACE ALL OCCURRENCES OF '*' IN lv_search_key WITH '%'.
      IF NOT ( lv_search_key CS '%' ).
        CONCATENATE '%' lv_search_key '%' INTO lv_search_key.
      ENDIF.
    ENDIF.

    DATA: lv_sch_v_up TYPE string.
    lv_sch_v_up = lv_search_key.
    TRANSLATE lv_sch_v_up TO UPPER CASE.

    DATA: lt_v_out TYPE TABLE OF ty_lookup_vendor.
    CLEAR lt_v_out.

    SELECT a~lifnr, a~name1, a~ort01, a~land1
      FROM lfa1 AS a
      INTO CORRESPONDING FIELDS OF TABLE @lt_v_out
      UP TO 50 ROWS
      WHERE a~loevm = @space AND a~sperr = @space
        AND ( a~lifnr LIKE @lv_search_key OR a~name1 LIKE @lv_search_key
           OR a~lifnr LIKE @lv_sch_v_up OR a~name1 LIKE @lv_sch_v_up ).

    gv_json_response = /ui2/cl_json=>serialize(
      data        = lt_v_out
      compress    = 'X'
      pretty_name = /ui2/cl_json=>pretty_mode-low_case
    ).
    _m_response->set_content_type( 'application/json' ).
    _m_response->set_cdata( gv_json_response ).
    _m_navigation->response_complete( ).
    RETURN.

  " ====================================================================
  " ACTION: SEARCH_MATERIAL (F4 Wildcard Lookup for Materials - MARA/MAKT)
  " ====================================================================
  WHEN 'SEARCH_MATERIAL'.
    lv_search_key = request->get_form_field( 'query' ).
    IF lv_search_key IS INITIAL OR lv_search_key = '*'.
      lv_search_key = '%'.
    ELSE.
      REPLACE ALL OCCURRENCES OF '*' IN lv_search_key WITH '%'.
      IF NOT ( lv_search_key CS '%' ).
        CONCATENATE '%' lv_search_key '%' INTO lv_search_key.
      ENDIF.
    ENDIF.

    DATA: lv_sch_m_up TYPE string.
    lv_sch_m_up = lv_search_key.
    TRANSLATE lv_sch_m_up TO UPPER CASE.

    DATA: lt_m_out TYPE TABLE OF ty_lookup_material.
    CLEAR lt_m_out.

    SELECT a~matnr, b~maktx, a~matkl, a~meins
      FROM mara AS a
      INNER JOIN makt AS b ON a~matnr = b~matnr
      INTO CORRESPONDING FIELDS OF TABLE @lt_m_out
      UP TO 50 ROWS
      WHERE a~lvorm = @space
        AND ( a~matnr LIKE @lv_search_key OR b~maktx LIKE @lv_search_key
           OR a~matnr LIKE @lv_sch_m_up OR b~maktx LIKE @lv_sch_m_up ).

    IF lt_m_out IS INITIAL.
      SELECT a~matnr, b~maktx, a~matkl, a~meins
        FROM mara AS a
        LEFT OUTER JOIN makt AS b ON a~matnr = b~matnr
        INTO CORRESPONDING FIELDS OF TABLE @lt_m_out
        UP TO 50 ROWS
        WHERE a~lvorm = @space
          AND ( a~matnr LIKE @lv_search_key OR a~matnr LIKE @lv_sch_m_up ).
    ENDIF.

    gv_json_response = /ui2/cl_json=>serialize(
      data        = lt_m_out
      compress    = 'X'
      pretty_name = /ui2/cl_json=>pretty_mode-low_case
    ).
    _m_response->set_content_type( 'application/json' ).
    _m_response->set_cdata( gv_json_response ).
    _m_navigation->response_complete( ).
    RETURN.

  " ====================================================================
  " ACTION: SEARCH_PLANT (F4 Wildcard Lookup for Plants)
  " ====================================================================
  WHEN 'SEARCH_PLANT'.
    lv_search_key = request->get_form_field( 'query' ).
    IF lv_search_key IS INITIAL OR lv_search_key = '*'.
      lv_search_key = '%'.
    ELSE.
      REPLACE ALL OCCURRENCES OF '*' IN lv_search_key WITH '%'.
      IF NOT ( lv_search_key CS '%' ).
        CONCATENATE '%' lv_search_key '%' INTO lv_search_key.
      ENDIF.
    ENDIF.

    DATA: lv_sch_p_up TYPE string.
    lv_sch_p_up = lv_search_key.
    TRANSLATE lv_sch_p_up TO UPPER CASE.

    DATA: lt_p_out TYPE TABLE OF ty_lookup_plant.
    CLEAR lt_p_out.

    SELECT werks, name1
      FROM t001w INTO CORRESPONDING FIELDS OF TABLE @lt_p_out
      UP TO 50 ROWS
      WHERE werks LIKE @lv_search_key OR name1 LIKE @lv_search_key
         OR werks LIKE @lv_sch_p_up OR name1 LIKE @lv_sch_p_up.

    gv_json_response = /ui2/cl_json=>serialize(
      data        = lt_p_out
      compress    = 'X'
      pretty_name = /ui2/cl_json=>pretty_mode-low_case
    ).
    _m_response->set_content_type( 'application/json' ).
    _m_response->set_cdata( gv_json_response ).
    _m_navigation->response_complete( ).
    RETURN.

  " ====================================================================
  " ACTION: GET_HISTORY (Fetch History List for Current User)
  " ====================================================================
  WHEN 'GET_HISTORY'.
    DATA: lt_hdr_h     TYPE TABLE OF zmdg_req_pir,
          ls_hdr_h     TYPE zmdg_req_pir,
          ls_hist_h    TYPE ty_history,
          lt_hist_tab  TYPE TABLE OF ty_history,
          ls_adt_h     TYPE zmdg_pir_adt,
          lt_adt_tmp   TYPE TABLE OF zmdg_pir_adt,
          lv_cnt_h     TYPE i,
          lv_vname_h   TYPE name1_gp,
          lv_d_str     TYPE string.

    CLEAR: lt_hist_tab, lt_hdr_h.

    SELECT * FROM zmdg_req_pir INTO TABLE lt_hdr_h
      WHERE ernam = sy-uname.

    SORT lt_hdr_h BY erdat DESCENDING erzet DESCENDING.

    LOOP AT lt_hdr_h INTO ls_hdr_h.
      CLEAR ls_hist_h.
      ls_hist_h-req_id     = ls_hdr_h-req_id.
      ls_hist_h-lifnr      = ls_hdr_h-lifnr.

      IF ls_hdr_h-lifnr IS NOT INITIAL.
        CLEAR lv_vname_h.
        SELECT SINGLE name1 FROM lfa1 INTO lv_vname_h
          WHERE lifnr = ls_hdr_h-lifnr.
        ls_hist_h-lifnr_name = lv_vname_h.
      ENDIF.

      ls_hist_h-matnr      = ls_hdr_h-matnr.
      ls_hist_h-txz01      = ls_hdr_h-txz01.

      IF ls_hdr_h-erdat IS NOT INITIAL.
        CONCATENATE ls_hdr_h-erdat+6(2) '.' ls_hdr_h-erdat+4(2) '.' ls_hdr_h-erdat(4) INTO lv_d_str.
        ls_hist_h-erdat    = lv_d_str.
      ELSE.
        ls_hist_h-erdat    = ''.
      ENDIF.

      ls_hist_h-erzet      = ls_hdr_h-erzet.
      ls_hist_h-ernam      = ls_hdr_h-ernam.
      ls_hist_h-ernam_name = gv_user_fullname.
      ls_hist_h-status     = ls_hdr_h-status.

      CASE ls_hdr_h-status.
        WHEN '00'. ls_hist_h-status_desc = 'Draft'.
        WHEN '01'. ls_hist_h-status_desc = 'Submitted / In Review'.
        WHEN '02'. ls_hist_h-status_desc = 'Approved'.
        WHEN '03'. ls_hist_h-status_desc = 'Rejected'.
        WHEN '04'. ls_hist_h-status_desc = 'Posted to SAP'.
        WHEN OTHERS. ls_hist_h-status_desc = 'In Progress'.
      ENDCASE.

      " Count items
      SELECT COUNT( * ) FROM zmdg_pir_itm
        INTO lv_cnt_h WHERE req_id = ls_hdr_h-req_id.
      ls_hist_h-item_count = lv_cnt_h.

      " Get latest audit comment
      SELECT * FROM zmdg_pir_adt INTO TABLE lt_adt_tmp
        WHERE req_id = ls_hdr_h-req_id.
      SORT lt_adt_tmp BY log_id DESCENDING.
      READ TABLE lt_adt_tmp INTO ls_adt_h INDEX 1.
      IF sy-subrc = 0.
        ls_hist_h-comments = ls_adt_h-comments.
      ENDIF.

      APPEND ls_hist_h TO lt_hist_tab.
    ENDLOOP.

    TRY.
        gv_json_response = /ui2/cl_json=>serialize(
          data        = lt_hist_tab
          compress    = 'X'
          pretty_name = /ui2/cl_json=>pretty_mode-low_case
        ).
      CATCH cx_root.
        gv_json_response = '[]'.
    ENDTRY.

    _m_response->set_content_type( 'application/json' ).
    _m_response->set_cdata( gv_json_response ).
    _m_navigation->response_complete( ).
    RETURN.

  " ====================================================================
  " ACTION: GET_UPLOAD_DETAIL (Fetch Request Details for Modal)
  " ====================================================================
  WHEN 'GET_UPLOAD_DETAIL'.
    lv_req_id = request->get_form_field( 'REQ_ID' ).
    SELECT SINGLE * FROM zmdg_req_pir INTO ls_hdr WHERE req_id = lv_req_id.
    IF sy-subrc = 0.
      CONCATENATE '{"status":"SUCCESS","req_id":"' ls_hdr-req_id
        '","lifnr":"' ls_hdr-lifnr '","matnr":"' ls_hdr-matnr
        '","txz01":"' ls_hdr-txz01 '","matkl":"' ls_hdr-matkl
        '","idnlf":"' ls_hdr-idnlf '"}' INTO gv_json_response.
    ELSE.
      gv_json_response = '{"status":"ERROR","message":"' &&
        'Data Request tidak ditemukan"}'.
    ENDIF.
    _m_response->set_content_type( 'application/json' ).
    _m_response->set_cdata( gv_json_response ).
    _m_navigation->response_complete( ).
    RETURN.

  WHEN OTHERS.
    " Fallback
    gv_json_response = '{"status":"OK"}'.
    _m_response->set_content_type( 'application/json' ).
    _m_response->set_cdata( gv_json_response ).
    _m_navigation->response_complete( ).
    RETURN.

ENDCASE.
