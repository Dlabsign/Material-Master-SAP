*----------------------------------------------------------------------*
* Event Handler : OnInputProcessing
* Description   : Handler Staging Material Part R&D (ZMDG_STG_HDR & PART)
*----------------------------------------------------------------------*
DATA: event        TYPE string,
      req_id       TYPE string,
      lv_upload_id TYPE string,
      lv_filename  TYPE string,
      lv_status    TYPE string,
      lv_sub_reason TYPE string,
      lv_count_str TYPE string,
      lv_count     TYPE i,
      idx_str      TYPE string.

DATA: ls_hdr TYPE zmdg_stg_hdr,
      lt_dtl TYPE TABLE OF zmdg_stg_part,
      ls_dtl TYPE zmdg_stg_part.

event = event_id.

CASE event.

  " -------------------------------------------------------------------
  " 1. SIMPAN MULTI-LINE DATA STAGING KE ZMDG_STG_HDR & ZMDG_STG_PART
  " -------------------------------------------------------------------
  WHEN 'SAVE_STAGE'.
    TRY.
        req_id        = request->get_form_field( 'REQ_ID' ).
        lv_upload_id  = request->get_form_field( 'UPLOAD_ID' ).
        lv_filename   = request->get_form_field( 'FILENAME' ).
        lv_status     = request->get_form_field( 'STATUS' ).
        lv_sub_reason = request->get_form_field( 'REQUEST_REASON' ).
        IF lv_sub_reason IS INITIAL.
          lv_sub_reason = request->get_form_field( 'SUB_REASON' ).
        ENDIF.

        " Generasi REQ_NO (max 10 Karakter) jika belum ada
        IF lv_upload_id IS INITIAL AND req_id IS NOT INITIAL.
          lv_upload_id = req_id.
        ENDIF.

        IF lv_upload_id IS INITIAL.
          DATA: lv_chars  TYPE string VALUE '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ',
                lv_rand6  TYPE string,
                lv_rnd_i  TYPE i,
                lo_rnd    TYPE REF TO cl_abap_random_int.

          TRY.
              lo_rnd = cl_abap_random_int=>create(
                         seed = cl_abap_random=>seed( )
                         min  = 0
                         max  = 35 ).
              DO 6 TIMES.
                lv_rnd_i = lo_rnd->get_next( ).
                lv_rand6 = lv_rand6 && lv_chars+lv_rnd_i(1).
              ENDDO.
            CATCH cx_root.
              lv_rand6 = |{ sy-uzeit }{ sy-datum+6(2) }|.
          ENDTRY.

          lv_upload_id = |UPL-{ lv_rand6 }|.
        ENDIF.

        IF strlen( lv_upload_id ) > 10.
          lv_upload_id = lv_upload_id(10).
        ENDIF.

        " 1A. SIMPAN HEADER REQ KE ZMDG_STG_HDR
        CLEAR ls_hdr.
        ls_hdr-mandt      = sy-mandt.
        ls_hdr-req_no     = lv_upload_id.
        ls_hdr-req_type   = 'PART'.
        IF lv_status = 'SUBMITTED' OR lv_status = 'PENDING'.
          lv_status = 'CHECKED'.
        ENDIF.
        ls_hdr-status     = COND #( WHEN lv_status IS NOT INITIAL THEN lv_status ELSE 'DRAFT' ).
        ls_hdr-requestor  = sy-uname.
        ls_hdr-req_date   = sy-datum.
        ls_hdr-req_time   = sy-uzeit.
        ls_hdr-remarks    = lv_filename.
        ls_hdr-sub_reason = lv_sub_reason.

        MODIFY zmdg_stg_hdr FROM @ls_hdr.

        " 1B. HAPUS & SIMPAN DETAIL ITEMS KE ZMDG_STG_PART
        DELETE FROM zmdg_stg_part WHERE req_no = @lv_upload_id.

        lv_count_str = request->get_form_field( 'ROW_COUNT' ).
        IF lv_count_str IS NOT INITIAL AND lv_count_str CO '0123456789'.
          lv_count = lv_count_str.
        ELSE.
          lv_count = 0.
        ENDIF.

        CLEAR lt_dtl.
        DO lv_count TIMES.
          idx_str = sy-index.
          CONDENSE idx_str.

          CLEAR ls_dtl.
          ls_dtl-mandt      = sy-mandt.
          ls_dtl-req_no     = lv_upload_id.
          ls_dtl-item_no    = sy-index.
          ls_dtl-ferth      = request->get_form_field( |code_num_{ idx_str }| ).
          ls_dtl-matnr_ext  = request->get_form_field( |matnr_{ idx_str }| ).
          ls_dtl-maktx      = request->get_form_field( |maktx_{ idx_str }| ).

          DATA(lv_grs_fin)  = request->get_form_field( |groes_fin_{ idx_str }| ).
          DATA(lv_grs_raw)  = request->get_form_field( |groes_{ idx_str }| ).
          IF lv_grs_fin IS NOT INITIAL.
            ls_dtl-groes    = lv_grs_fin.
          ELSE.
            ls_dtl-groes    = lv_grs_raw.
          ENDIF.

          ls_dtl-zeinr      = request->get_form_field( |wrkst_{ idx_str }| ).
          ls_dtl-normt      = request->get_form_field( |note_{ idx_str }| ).
          ls_dtl-sales_text = request->get_form_field( |description_{ idx_str }| ).
          ls_dtl-disgr      = request->get_form_field( |disgr_{ idx_str }| ).
          ls_dtl-dispo      = request->get_form_field( |dispo_{ idx_str }| ).

          DATA(lv_l1)       = request->get_form_field( |lgort1_{ idx_str }| ).
          ls_dtl-lgpro      = lv_l1.
          ls_dtl-lgort      = lv_l1.
          ls_dtl-lgpro_ep   = request->get_form_field( |lgort2_{ idx_str }| ).
          ls_dtl-werks      = request->get_form_field( |werks_{ idx_str }| ).
          ls_dtl-meins      = request->get_form_field( |meins_{ idx_str }| ).
          IF ls_dtl-meins IS INITIAL.
            ls_dtl-meins = 'PC'.
          ENDIF.

          DATA(lv_umrez_raw) = request->get_form_field( |umrez_{ idx_str }| ).
          IF lv_umrez_raw IS NOT INITIAL.
            TRY.
                ls_dtl-umrez = lv_umrez_raw.
              CATCH cx_root.
                CLEAR ls_dtl-umrez.
            ENDTRY.
          ELSE.
            CLEAR ls_dtl-umrez.
          ENDIF.

          ls_dtl-meinh      = request->get_form_field( |meinh_{ idx_str }| ).
          ls_dtl-mbrsh      = request->get_form_field( |mbrsh_{ idx_str }| ).
          IF ls_dtl-mbrsh IS INITIAL.
            ls_dtl-mbrsh    = 'F'.
          ENDIF.
          ls_dtl-mtart      = request->get_form_field( |mtart_{ idx_str }| ).
          IF ls_dtl-mtart IS INITIAL.
            ls_dtl-mtart    = 'HALB'.
          ENDIF.
          ls_dtl-matkl      = request->get_form_field( |matkl_{ idx_str }| ).
          IF ls_dtl-matkl IS INITIAL. ls_dtl-matkl = 'ESP018'. ENDIF.

          ls_dtl-prctr      = request->get_form_field( |prctr_{ idx_str }| ).
          IF ls_dtl-prctr IS INITIAL. ls_dtl-prctr = '200201'. ENDIF.

          ls_dtl-qssys      = request->get_form_field( |qssys_{ idx_str }| ).
          IF ls_dtl-qssys IS INITIAL. ls_dtl-qssys = '04'. ENDIF.

          ls_dtl-insptype   = request->get_form_field( |insptype_{ idx_str }| ).
          IF ls_dtl-insptype IS INITIAL OR ls_dtl-insptype = 'X'.
            ls_dtl-insptype = '04'.
          ENDIF.

          IF ls_dtl-vkorg IS INITIAL. ls_dtl-vkorg = '1000'. ENDIF.
          IF ls_dtl-ekalr IS INITIAL. ls_dtl-ekalr = 'X'. ENDIF.
          ls_dtl-lgnum      = request->get_form_field( |lgnum_{ idx_str }| ).
          IF ls_dtl-lgnum IS INITIAL. ls_dtl-lgnum = '100'. ENDIF.

          ls_dtl-val_type   = request->get_form_field( |val_type_{ idx_str }| ).
          IF ls_dtl-class IS INITIAL. ls_dtl-class = 'WARNA'. ENDIF.
          IF ls_dtl-warna IS INITIAL. ls_dtl-warna = 'NATURAL'. ENDIF.

          IF ls_dtl-periv IS INITIAL. ls_dtl-periv = 'C1'. ENDIF.
          IF ls_dtl-mtvfp IS INITIAL. ls_dtl-mtvfp = 'KP'. ENDIF.
          IF ls_dtl-xchpf IS INITIAL. ls_dtl-xchpf = 'X'. ENDIF.
          IF ls_dtl-hkmat IS INITIAL. ls_dtl-hkmat = 'X'. ENDIF.
          IF ls_dtl-spart IS INITIAL. ls_dtl-spart = 'M6'. ENDIF.
          IF ls_dtl-mtpos_mara IS INITIAL. ls_dtl-mtpos_mara = 'NORM'. ENDIF.
          IF ls_dtl-herkl IS INITIAL. ls_dtl-herkl = 'ID'. ENDIF.
          IF ls_dtl-taxkm IS INITIAL. ls_dtl-taxkm = '1'. ENDIF.
          IF ls_dtl-tatyp IS INITIAL. ls_dtl-tatyp = 'MWST'. ENDIF.
          IF ls_dtl-mtpos IS INITIAL. ls_dtl-mtpos = 'NORM'. ENDIF.
          IF ls_dtl-tragr IS INITIAL. ls_dtl-tragr = '1'. ENDIF.
          IF ls_dtl-ladgr IS INITIAL. ls_dtl-ladgr = '1'. ENDIF.
          IF ls_dtl-bklas IS INITIAL. ls_dtl-bklas = 'SF01'. ENDIF.
          IF ls_dtl-vprsv IS INITIAL. ls_dtl-vprsv = 'V'. ENDIF.
          IF ls_dtl-ekgrp IS INITIAL. ls_dtl-ekgrp = 'K03'. ENDIF.
          IF ls_dtl-dismm IS INITIAL. ls_dtl-dismm = 'PD'. ENDIF.
          IF ls_dtl-beskz IS INITIAL. ls_dtl-beskz = 'F'. ENDIF.
          IF ls_dtl-rgekz IS INITIAL. ls_dtl-rgekz = '1'. ENDIF.
          IF ls_dtl-fhori IS INITIAL. ls_dtl-fhori = '0'. ENDIF.
          IF ls_dtl-perkz IS INITIAL. ls_dtl-perkz = 'M'. ENDIF.
          IF ls_dtl-bstrf IS INITIAL. ls_dtl-bstrf = '100'. ENDIF.
          IF ls_dtl-disls IS INITIAL. ls_dtl-disls = 'PB'. ENDIF.
          IF ls_dtl-vtweg IS INITIAL. ls_dtl-vtweg = '10'. ENDIF.
          IF ls_dtl-ktgrm IS INITIAL. ls_dtl-ktgrm = 'M6'. ENDIF.

          DATA(lv_vol_raw)  = request->get_form_field( |vol_m3_{ idx_str }| ).
          IF lv_vol_raw IS NOT INITIAL.
            REPLACE ALL OCCURRENCES OF ',' IN lv_vol_raw WITH '.'.
            TRY.
                ls_dtl-volum = lv_vol_raw.
              CATCH cx_root.
                CLEAR ls_dtl-volum.
            ENDTRY.
          ELSE.
            CLEAR ls_dtl-volum.
          ENDIF.

          IF ls_dtl-volum IS NOT INITIAL AND ls_dtl-vol_prod IS INITIAL.
            ls_dtl-vol_prod = CONV #( ls_dtl-volum ).
          ENDIF.

          ls_dtl-vkorg      = '1000'.
          ls_dtl-spart      = 'M6'.
          ls_dtl-mtpos_mara = 'NORM'.
          ls_dtl-vtweg      = '10'.
          ls_dtl-peinh      = 1.
          ls_dtl-peinh_2    = 1.

          IF ls_dtl-maktx IS NOT INITIAL OR ls_dtl-matnr_ext IS NOT INITIAL.
            APPEND ls_dtl TO lt_dtl.
          ENDIF.
        ENDDO.

        IF lt_dtl IS NOT INITIAL.
          MODIFY zmdg_stg_part FROM TABLE @lt_dtl.
          COMMIT WORK.
        ENDIF.

        _m_response->set_status( code = 200 reason = 'OK' ).
        _m_response->set_content_type( 'application/json' ).
        _m_response->set_cdata( |\{"status":"SUCCESS","upload_id":"{ lv_upload_id }"\}| ).
        navigation->response_complete( ).
        RETURN.

      CATCH cx_root INTO DATA(lx_save_err).
        DATA(lv_save_msg) = lx_save_err->get_text( ).
        _m_response->set_status( code = 500 reason = 'Internal Server Error' ).
        _m_response->set_content_type( 'application/json' ).
        _m_response->set_cdata( |\{"status":"ERROR","message":"{ lv_save_msg }"\}| ).
        navigation->response_complete( ).
        RETURN.
    ENDTRY.

  " -------------------------------------------------------------------
  " 2. GET RIWAYAT BATCH UPLOAD DARI ZMDG_STG_HDR
  " -------------------------------------------------------------------
  WHEN 'GET_HISTORY'.
    TYPES: BEGIN OF ty_history,
             upload_id     TYPE string,
             filename      TYPE string,
             erdat         TYPE string,
             ertim         TYPE string,
             ernam         TYPE string,
             status        TYPE string,
             approved_by   TYPE string,
             app_date      TYPE string,
             app_time      TYPE string,
             reject_reason TYPE string,
             sub_reason    TYPE string,
             total_row     TYPE i,
           END OF ty_history.

    DATA: lt_hdr_list TYPE TABLE OF zmdg_stg_hdr,
          ls_hdr_item TYPE zmdg_stg_hdr,
          lt_history  TYPE TABLE OF ty_history,
          ls_hist     TYPE ty_history,
          lv_json_his TYPE string.

    SELECT * FROM zmdg_stg_hdr
      ORDER BY req_date DESCENDING, req_time DESCENDING
      INTO TABLE @lt_hdr_list.

    LOOP AT lt_hdr_list INTO ls_hdr_item.
      CLEAR ls_hist.
      ls_hist-upload_id     = ls_hdr_item-req_no.
      ls_hist-filename      = ls_hdr_item-remarks.
      ls_hist-erdat         = ls_hdr_item-req_date.
      ls_hist-ertim         = ls_hdr_item-req_time.
      ls_hist-ernam         = ls_hdr_item-requestor.
      ls_hist-status        = ls_hdr_item-status.
      ls_hist-approved_by   = ls_hdr_item-approver.
      ls_hist-app_date      = ls_hdr_item-app_date.
      ls_hist-app_time      = ls_hdr_item-app_time.
      ls_hist-reject_reason = ls_hdr_item-rej_reason.
      ls_hist-sub_reason    = ls_hdr_item-sub_reason.

      SELECT COUNT( * ) FROM zmdg_stg_part
        WHERE req_no = @ls_hdr_item-req_no
        INTO @ls_hist-total_row.

      APPEND ls_hist TO lt_history.
    ENDLOOP.

    /ui2/cl_json=>serialize(
      EXPORTING
        data        = lt_history
        pretty_name = /ui2/cl_json=>pretty_mode-low_case
      RECEIVING
        r_json      = lv_json_his ).

    _m_response->set_status( code = 200 reason = 'OK' ).
    _m_response->set_content_type( 'application/json' ).
    _m_response->set_cdata( lv_json_his ).
    navigation->response_complete( ).
    RETURN.

  " -------------------------------------------------------------------
  " 3. GET DETAIL UPLOAD BERDASARKAN REQ_NO DARI ZMDG_STG_PART
  " -------------------------------------------------------------------
  WHEN 'GET_UPLOAD_DETAIL'.
    TYPES: BEGIN OF ty_detail_out,
             upload_id   TYPE string,
             req_id      TYPE string,
             posnr       TYPE i,
             code_num    TYPE string,
             matnr       TYPE string,
             maktx       TYPE string,
             groes       TYPE string,
             groes_fin   TYPE string,
             vol_m3      TYPE string,
             wrkst       TYPE string,
             note        TYPE string,
             description TYPE string,
             disgr       TYPE string,
             dispo       TYPE string,
             lgort1      TYPE string,
             lgort2      TYPE string,
             werks       TYPE string,
             meins       TYPE string,
             umrez       TYPE string,
             meinh       TYPE string,
             mtart       TYPE string,
             matkl       TYPE string,
             ssqss       TYPE string,
             qssys       TYPE string,
             insptype    TYPE string,
           END OF ty_detail_out.

    DATA: lt_stg_rows TYPE TABLE OF zmdg_stg_part,
          ls_stg_row  TYPE zmdg_stg_part,
          lt_out_rows TYPE TABLE OF ty_detail_out,
          ls_out_row  TYPE ty_detail_out,
          lv_json_det TYPE string.

    lv_upload_id = request->get_form_field( 'UPLOAD_ID' ).

    IF lv_upload_id IS NOT INITIAL.
      SELECT * FROM zmdg_stg_part
        WHERE req_no = @lv_upload_id
        ORDER BY item_no ASCENDING
        INTO TABLE @lt_stg_rows.

      LOOP AT lt_stg_rows INTO ls_stg_row.
        CLEAR ls_out_row.
        ls_out_row-upload_id   = ls_stg_row-req_no.
        ls_out_row-req_id      = ls_stg_row-req_no.
        ls_out_row-posnr       = ls_stg_row-item_no * 10.
        ls_out_row-code_num    = ls_stg_row-ferth.
        ls_out_row-matnr       = ls_stg_row-matnr_ext.
        ls_out_row-maktx       = ls_stg_row-maktx.
        ls_out_row-groes       = ls_stg_row-groes.
        ls_out_row-groes_fin   = ls_stg_row-groes.
        ls_out_row-vol_m3      = CONV #( ls_stg_row-volum ).
        ls_out_row-wrkst       = ls_stg_row-zeinr.
        ls_out_row-note        = ls_stg_row-normt.
        ls_out_row-description = ls_stg_row-sales_text.
        ls_out_row-disgr       = ls_stg_row-disgr.
        ls_out_row-dispo       = ls_stg_row-dispo.
        ls_out_row-lgort1      = ls_stg_row-lgpro.
        IF ls_out_row-lgort1 IS INITIAL.
          ls_out_row-lgort1    = ls_stg_row-lgort.
        ENDIF.
        ls_out_row-lgort2      = ls_stg_row-lgpro_ep.
        ls_out_row-werks       = ls_stg_row-werks.
        ls_out_row-meins       = ls_stg_row-meins.
        ls_out_row-umrez       = CONV #( ls_stg_row-umrez ).
        ls_out_row-meinh       = ls_stg_row-meinh.
        ls_out_row-mtart       = ls_stg_row-mtart.
        ls_out_row-matkl       = ls_stg_row-matkl.
        ls_out_row-ssqss       = '0004'.
        ls_out_row-qssys       = ls_stg_row-qssys.
        IF ls_out_row-qssys IS INITIAL. ls_out_row-qssys = '04'. ENDIF.
        ls_out_row-insptype    = ls_stg_row-insptype.
        IF ls_out_row-insptype IS INITIAL OR ls_out_row-insptype = 'X'.
          ls_out_row-insptype = '04'.
        ENDIF.

        APPEND ls_out_row TO lt_out_rows.
      ENDLOOP.
    ENDIF.

    /ui2/cl_json=>serialize(
      EXPORTING
        data        = lt_out_rows
        pretty_name = /ui2/cl_json=>pretty_mode-low_case
      RECEIVING
        r_json      = lv_json_det ).

    _m_response->set_status( code = 200 reason = 'OK' ).
    _m_response->set_content_type( 'application/json' ).
    _m_response->set_cdata( lv_json_det ).
    navigation->response_complete( ).
    RETURN.

  " -------------------------------------------------------------------
  " 4. UPDATE STATUS BATCH (HOLD / APPROVE / REJECT)
  " -------------------------------------------------------------------
  WHEN 'UPDATE_STATUS'.
    DATA: lv_new_st  TYPE string,
          lv_rej_rsn TYPE string.

    lv_upload_id = request->get_form_field( 'UPLOAD_ID' ).
    lv_new_st    = request->get_form_field( 'STATUS' ).
    lv_rej_rsn   = request->get_form_field( 'REJECT_REASON' ).

    IF lv_upload_id IS NOT INITIAL AND lv_new_st IS NOT INITIAL.
      UPDATE zmdg_stg_hdr
        SET status     = @lv_new_st,
            rej_reason = @lv_rej_rsn,
            approver   = @sy-uname,
            app_date   = @sy-datum,
            app_time   = @sy-uzeit
        WHERE req_no   = @lv_upload_id.

      COMMIT WORK.
    ENDIF.

    _m_response->set_status( code = 200 reason = 'OK' ).
    _m_response->set_content_type( 'application/json' ).
    _m_response->set_cdata( '{"status":"SUCCESS"}' ).
    navigation->response_complete( ).
    RETURN.

  " -------------------------------------------------------------------
  " 5. SEARCH MARA RECORDS
  " -------------------------------------------------------------------
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
             matnr  TYPE mara-matnr,
             maktx  TYPE makt-maktx,
             werks  TYPE marc-werks,
             disgr  TYPE marc-disgr,
             dispo  TYPE marc-dispo,
             lgort1 TYPE marc-lgpro,
             lgort2 TYPE marc-lgfsb,
             mtart  TYPE mara-mtart,
             matkl  TYPE mara-matkl,
             meins  TYPE mara-meins,
             bismt  TYPE mara-bismt,
             mbrsh  TYPE mara-mbrsh,
             spart  TYPE mara-spart,
           END OF ty_mara_res.

    DATA: lt_mara_res TYPE TABLE OF ty_mara_res.

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

    SELECT a~matnr, b~maktx, c~werks, c~disgr, c~dispo,
           c~lgpro AS lgort1, c~lgfsb AS lgort2,
           a~mtart, a~matkl, a~meins, a~bismt, a~mbrsh, a~spart
      FROM mara AS a
      LEFT OUTER JOIN makt AS b ON a~matnr = b~matnr AND b~spras = @sy-langu
      LEFT OUTER JOIN marc AS c ON a~matnr = c~matnr
      WHERE ( @lv_filter_matnr IS INITIAL
              OR a~matnr LIKE @lv_pattern_matnr
              OR ( @lv_matnr_padded IS NOT INITIAL AND a~matnr = @lv_matnr_padded ) )
        AND ( @lv_filter_maktx IS INITIAL OR b~maktx LIKE @lv_pattern_maktx )
        AND ( @lv_filter_mtart IS INITIAL OR a~mtart = @lv_filter_mtart )
        AND ( @lv_filter_matkl IS INITIAL OR a~matkl LIKE @lv_pattern_matkl )
      INTO TABLE @lt_mara_res
      UP TO 200 ROWS.

    DATA(lv_json_mara) = /ui2/cl_json=>serialize(
                           data        = lt_mara_res
                           compress    = 'X'
                           pretty_name = /ui2/cl_json=>pretty_mode-low_case ).

    _m_response->set_status( code = 200 reason = 'OK' ).
    _m_response->set_content_type( 'application/json' ).
    _m_response->set_cdata( lv_json_mara ).
    navigation->response_complete( ).
    RETURN.

  " -------------------------------------------------------------------
  " 6. LOGOUT
  " -------------------------------------------------------------------
  WHEN 'LOGOUT'.
    _m_response->redirect( url = '/sap/public/bc/icf/logoff' ).
    navigation->response_complete( ).

ENDCASE.