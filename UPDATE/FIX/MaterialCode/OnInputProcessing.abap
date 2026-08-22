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

      " Update Header Status to CHECKED (Forward to Approval)
      UPDATE zmdg_req_hdr
        SET status = 'CHECKED'
        WHERE req_no = @lv_req_no.

      lv_json = |\{"status":"SUCCESS","message":"Request { lv_req_no } has been Checked by Data Steward and forwarded to Approval successfully!"\}|.
      _m_response->set_content_type( 'application/json' ).
      _m_response->set_cdata( lv_json ).
      navigation->goto_page( '' ).
      RETURN.

    " ==================================================================
    " 5. RETURN / REJECT REQUEST TO PURCHASING
    " ==================================================================
    WHEN 'RETURN_TO_REQUESTOR'.
      lv_req_no = request->get_form_field( 'REQ_NO' ).
      lv_reason = request->get_form_field( 'REASON' ).

      IF lv_req_no IS INITIAL.
        lv_json = '{"status":"ERROR","message":"Request ID is required."}'.
        _m_response->set_content_type( 'application/json' ).
        _m_response->set_cdata( lv_json ).
        navigation->goto_page( '' ).
        RETURN.
      ENDIF.

      UPDATE zmdg_req_hdr
        SET status     = 'REJECTED',
            rej_reason = @lv_reason
        WHERE req_no   = @lv_req_no.

      lv_json = |\{"status":"SUCCESS","message":"Request { lv_req_no } has been returned to Purchasing."\}|.
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
