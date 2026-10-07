*======================================================================*
* SAP BSP EVENT HANDLER: OnInputProcessing                             *
* Target BSP Page: history_rejected.htm                                *
* Application: MDG Staging Part Rejected History (ZMDG_STG_HDR & PART) *
*======================================================================*

TYPES: BEGIN OF ty_history_item,
         req_no        TYPE string,
         remarks       TYPE string,
         sub_reason    TYPE string,
         req_date      TYPE string,
         req_time      TYPE string,
         requestor     TYPE string,
         status        TYPE string,
         total_item    TYPE i,
         matnr_gen     TYPE string,
         maktx_desc    TYPE string,
         approver      TYPE string,
         app_date      TYPE string,
         app_time      TYPE string,
         rej_reason    TYPE string,
       END OF ty_history_item.

DATA: lv_action_hr   TYPE string,
      lt_history     TYPE TABLE OF ty_history_item,
      ls_item        TYPE ty_history_item,
      lt_hdr_db      TYPE TABLE OF zmdg_stg_hdr,
      ls_hdr_db      TYPE zmdg_stg_hdr,
      lt_dtl_db      TYPE TABLE OF zmdg_stg_part,
      ls_dtl_db      TYPE zmdg_stg_part,
      lv_codes_str   TYPE string,
      lv_maktx_str   TYPE string,
      lv_clean_mat   TYPE string,
      lv_json_res    TYPE string,
      lv_req_no_hr   TYPE string,
      lv_cnt_p       TYPE i,
      lv_cnt_a       TYPE i,
      lv_cnt_r       TYPE i,
      lv_cnt_draft   TYPE i,
      lv_cnt_total   TYPE i,
      lv_auth_user   TYPE string,
      lv_persnum     TYPE usr21-persnumber,
      lv_fname       TYPE adrp-name_first,
      lv_lname       TYPE adrp-name_last,
      ls_bapi_addr   TYPE bapiaddr3,
      lt_bapi_ret    TYPE TABLE OF bapiret2,
      lv_uname_tmp   TYPE bapibname-bapibname.

lv_auth_user = sy-uname.
TRANSLATE lv_auth_user TO UPPER CASE.
CONDENSE lv_auth_user NO-GAPS.

IF lv_auth_user <> 'ABAPER04' AND lv_auth_user <> 'BASIS' AND
   lv_auth_user <> 'KMI-BOD' AND lv_auth_user <> 'KMI-U163' AND
   lv_auth_user <> 'ADMINISTRATOR' AND lv_auth_user <> 'TOTOK' AND lv_auth_user <> 'DEFAULT'.
  lv_action_hr = request->get_form_field( 'action' ).
  IF lv_action_hr IS INITIAL.
    lv_action_hr = request->get_form_field( 'OnInputProcessing' ).
  ENDIF.
  IF lv_action_hr IS NOT INITIAL.
    lv_json_res = '{"status":"ERROR","message":"Akses Terbatas: Anda tidak memiliki akses."}'.
    _m_response->set_status( code = 403 reason = 'Forbidden' ).
    _m_response->set_content_type( 'application/json' ).
    _m_response->set_cdata( lv_json_res ).
    _m_navigation->response_complete( ).
    RETURN.
  ENDIF.
ENDIF.

lv_action_hr = request->get_form_field( 'action' ).
IF lv_action_hr IS INITIAL.
  lv_action_hr = request->get_form_field( 'OnInputProcessing' ).
ENDIF.
TRANSLATE lv_action_hr TO UPPER CASE.

IF lv_action_hr IS NOT INITIAL.
  CASE lv_action_hr.

    WHEN 'GET_COUNTERS'.
      SELECT COUNT( * ) FROM zmdg_stg_hdr
        WHERE status IN ( 'CHECKED', 'CODED' )
        INTO @lv_cnt_p.

      SELECT COUNT( * ) FROM zmdg_stg_hdr
        WHERE status = 'APPROVED'
        INTO @lv_cnt_a.

      SELECT COUNT( * ) FROM zmdg_stg_hdr
        WHERE status IN ( 'REJECTED', 'FAILED' )
        INTO @lv_cnt_r.

      SELECT COUNT( * ) FROM zmdg_stg_hdr
        WHERE status = 'DRAFT' OR status IS INITIAL OR status = ''
        INTO @lv_cnt_draft.

      lv_cnt_total = lv_cnt_a + lv_cnt_r.

      lv_json_res = '{"pending":' && lv_cnt_p &&
                    ',"approved":' && lv_cnt_a &&
                    ',"rejected":' && lv_cnt_r &&
                    ',"draft":' && lv_cnt_draft &&
                    ',"total_history":' && lv_cnt_total && '}'.

      _m_response->set_content_type( 'application/json' ).
      _m_response->set_cdata( lv_json_res ).
      _m_navigation->response_complete( ).
      RETURN.

    WHEN 'GET_REJECTED_LIST' OR 'GET_HISTORY_LIST'.
      CLEAR: lt_history, lt_hdr_db.

      SELECT * FROM zmdg_stg_hdr
        INTO TABLE @lt_hdr_db
        WHERE status IN ( 'REJECTED', 'FAILED' )
        ORDER BY req_date DESCENDING, req_time DESCENDING.

      LOOP AT lt_hdr_db INTO ls_hdr_db.
        CLEAR: ls_item, lv_codes_str, lv_maktx_str, lt_dtl_db.

        ls_item-req_no     = CONV #( ls_hdr_db-req_no ).
        ls_item-remarks    = CONV #( ls_hdr_db-remarks ).
        ls_item-sub_reason = CONV #( ls_hdr_db-sub_reason ).
        ls_item-req_date   = CONV #( ls_hdr_db-req_date ).
        ls_item-req_time   = CONV #( ls_hdr_db-req_time ).
        ls_item-status     = CONV #( ls_hdr_db-status ).
        ls_item-app_date   = CONV #( ls_hdr_db-app_date ).
        ls_item-app_time   = CONV #( ls_hdr_db-app_time ).
        ls_item-rej_reason = CONV #( ls_hdr_db-rej_reason ).

        " Requestor Name
        IF ls_hdr_db-requestor IS NOT INITIAL.
          CLEAR: ls_bapi_addr, lt_bapi_ret, lv_fname, lv_lname.
          lv_uname_tmp = ls_hdr_db-requestor.
          CALL FUNCTION 'BAPI_USER_GET_DETAIL'
            EXPORTING username = lv_uname_tmp
            IMPORTING address  = ls_bapi_addr
            TABLES    return   = lt_bapi_ret.

          IF ls_bapi_addr-firstname IS NOT INITIAL OR ls_bapi_addr-lastname IS NOT INITIAL.
            CONCATENATE ls_bapi_addr-firstname ls_bapi_addr-lastname INTO ls_item-requestor SEPARATED BY space.
          ELSEIF ls_bapi_addr-fullname IS NOT INITIAL.
            ls_item-requestor = ls_bapi_addr-fullname.
          ELSE.
            SELECT SINGLE persnumber FROM usr21 INTO lv_persnum WHERE bname = ls_hdr_db-requestor.
            IF sy-subrc = 0.
              SELECT SINGLE name_first name_last FROM adrp INTO (lv_fname, lv_lname) WHERE persnumber = lv_persnum.
              IF lv_fname IS NOT INITIAL OR lv_lname IS NOT INITIAL.
                CONCATENATE lv_fname lv_lname INTO ls_item-requestor SEPARATED BY space.
              ENDIF.
            ENDIF.
          ENDIF.
        ENDIF.
        IF ls_item-requestor IS INITIAL.
          ls_item-requestor = ls_hdr_db-requestor.
        ENDIF.

        " Approver Name
        IF ls_hdr_db-approver IS NOT INITIAL.
          CLEAR: ls_bapi_addr, lt_bapi_ret, lv_fname, lv_lname.
          lv_uname_tmp = ls_hdr_db-approver.
          CALL FUNCTION 'BAPI_USER_GET_DETAIL'
            EXPORTING username = lv_uname_tmp
            IMPORTING address  = ls_bapi_addr
            TABLES    return   = lt_bapi_ret.

          IF ls_bapi_addr-firstname IS NOT INITIAL OR ls_bapi_addr-lastname IS NOT INITIAL.
            CONCATENATE ls_bapi_addr-firstname ls_bapi_addr-lastname INTO ls_item-approver SEPARATED BY space.
          ELSEIF ls_bapi_addr-fullname IS NOT INITIAL.
            ls_item-approver = ls_bapi_addr-fullname.
          ELSE.
            SELECT SINGLE persnumber FROM usr21 INTO lv_persnum WHERE bname = ls_hdr_db-approver.
            IF sy-subrc = 0.
              SELECT SINGLE name_first name_last FROM adrp INTO (lv_fname, lv_lname) WHERE persnumber = lv_persnum.
              IF lv_fname IS NOT INITIAL OR lv_lname IS NOT INITIAL.
                CONCATENATE lv_fname lv_lname INTO ls_item-approver SEPARATED BY space.
              ENDIF.
            ENDIF.
          ENDIF.
        ENDIF.
        IF ls_item-approver IS INITIAL.
          ls_item-approver = ls_hdr_db-approver.
        ENDIF.

        SELECT COUNT( * ) FROM zmdg_stg_part
          WHERE req_no = @ls_hdr_db-req_no INTO @ls_item-total_item.

        SELECT * FROM zmdg_stg_part
          WHERE req_no = @ls_hdr_db-req_no INTO TABLE @lt_dtl_db.

        LOOP AT lt_dtl_db INTO ls_dtl_db.
          IF ls_dtl_db-maktx IS NOT INITIAL.
            IF lv_maktx_str IS INITIAL.
              lv_maktx_str = ls_dtl_db-maktx.
            ELSE.
              lv_maktx_str = lv_maktx_str && ', ' && ls_dtl_db-maktx.
            ENDIF.
          ENDIF.

          IF ls_dtl_db-matnr_ext IS NOT INITIAL.
            lv_clean_mat = ls_dtl_db-matnr_ext.
            SHIFT lv_clean_mat LEFT DELETING LEADING '0'.
            IF lv_clean_mat IS INITIAL.
              lv_clean_mat = '0'.
            ENDIF.
            IF lv_codes_str IS INITIAL.
              lv_codes_str = lv_clean_mat.
            ELSE.
              lv_codes_str = lv_codes_str && ', ' && lv_clean_mat.
            ENDIF.
          ELSEIF ls_dtl_db-ferth IS NOT INITIAL.
            IF lv_codes_str IS INITIAL.
              lv_codes_str = ls_dtl_db-ferth.
            ELSE.
              lv_codes_str = lv_codes_str && ', ' && ls_dtl_db-ferth.
            ENDIF.
          ENDIF.
        ENDLOOP.

        ls_item-matnr_gen  = lv_codes_str.
        ls_item-maktx_desc = lv_maktx_str.

        APPEND ls_item TO lt_history.
      ENDLOOP.

      lv_json_res = /ui2/cl_json=>serialize(
        data        = lt_history
        compress    = 'X'
        pretty_name = /ui2/cl_json=>pretty_mode-low_case ).

      _m_response->set_content_type( 'application/json' ).
      _m_response->set_cdata( lv_json_res ).
      _m_navigation->response_complete( ).
      RETURN.

    WHEN 'GET_UPLOAD_DETAIL'.
      lv_req_no_hr = request->get_form_field( 'REQ_NO' ).
      IF lv_req_no_hr IS INITIAL.
        lv_req_no_hr = request->get_form_field( 'UPLOAD_ID' ).
      ENDIF.

      TYPES: BEGIN OF ty_att_json,
               att_no      TYPE i,
               file_name   TYPE string,
               file_type   TYPE string,
               file_size   TYPE i,
               description TYPE string,
               file_base64 TYPE string,
             END OF ty_att_json.

      DATA: lt_att_db   TYPE TABLE OF zmdg_req_att,
            ls_att_db   TYPE zmdg_req_att,
            lt_att_json TYPE TABLE OF ty_att_json,
            ls_att_json TYPE ty_att_json.

      CLEAR: lt_dtl_db, lt_att_db, lt_att_json.

      SELECT * FROM zmdg_stg_part
        WHERE req_no = @lv_req_no_hr
        ORDER BY item_no ASCENDING
        INTO TABLE @lt_dtl_db.

      SELECT * FROM zmdg_req_att
        INTO TABLE @lt_att_db
        WHERE req_no = @lv_req_no_hr
        ORDER BY att_no ASCENDING.

      LOOP AT lt_att_db INTO ls_att_db.
        CLEAR ls_att_json.
        ls_att_json-att_no      = ls_att_db-att_no.
        ls_att_json-file_name   = ls_att_db-file_name.
        ls_att_json-file_type   = ls_att_db-file_type.
        ls_att_json-file_size   = ls_att_db-file_size.
        ls_att_json-description = ls_att_db-description.
        IF ls_att_db-file_data IS NOT INITIAL.
          TRY.
              ls_att_json-file_base64 = cl_http_utility=>encode_x_base64( unencoded = ls_att_db-file_data ).
            CATCH cx_root.
              CLEAR ls_att_json-file_base64.
          ENDTRY.
        ENDIF.
        APPEND ls_att_json TO lt_att_json.
      ENDLOOP.

      TYPES: BEGIN OF ty_upload_detail_resp,
               items       TYPE TABLE OF zmdg_stg_part WITH DEFAULT KEY,
               attachments TYPE TABLE OF ty_att_json WITH DEFAULT KEY,
             END OF ty_upload_detail_resp.

      DATA: ls_upload_detail_resp TYPE ty_upload_detail_resp.
      ls_upload_detail_resp-items       = lt_dtl_db.
      ls_upload_detail_resp-attachments = lt_att_json.

      lv_json_res = /ui2/cl_json=>serialize(
        data        = ls_upload_detail_resp
        compress    = 'X'
        pretty_name = /ui2/cl_json=>pretty_mode-low_case ).

      _m_response->set_content_type( 'application/json' ).
      _m_response->set_cdata( lv_json_res ).
      _m_navigation->response_complete( ).
      RETURN.

    WHEN 'LOGOUT'.
      _m_navigation->exit( ).
      RETURN.

  ENDCASE.
ENDIF.