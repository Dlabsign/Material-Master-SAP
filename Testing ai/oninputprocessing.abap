*----------------------------------------------------------------------*
* Event Handler : OnInputProcessing
* Page          : test_ai.htm
* Table Target  : ZMDG_AI_CHAT_LOG (SAP MDG AI Chat History)
*----------------------------------------------------------------------*
DATA: lv_event        TYPE string,
      lv_chat_id      TYPE string,
      lv_msg_id_str   TYPE string,
      lv_prompt       TYPE string,
      lv_response     TYPE string,
      lv_status       TYPE string,
      lv_model        TYPE string,
      lv_in_tok_str   TYPE string,
      lv_out_tok_str  TYPE string,
      lv_tot_tok_str  TYPE string.

DATA: ls_chat_log TYPE zmdg_ai_chat_log,
      lv_max_msg  TYPE zmdg_ai_chat_log-msg_id.

lv_event = event_id.

CASE lv_event.

  " -------------------------------------------------------------------
  " 1. SIMPAN/APPEND CHAT LOG BERDASARKAN CHAT_ID
  " -------------------------------------------------------------------
  WHEN 'SAVE_CHAT_LOG'.
    TRY.
        lv_chat_id     = request->get_form_field( 'CHAT_ID' ).
        lv_prompt      = request->get_form_field( 'PROMPT_TEXT' ).
        lv_response    = request->get_form_field( 'RESPONSE_TEXT' ).
        lv_status      = request->get_form_field( 'STATUS' ).
        lv_model       = request->get_form_field( 'MODEL_NAME' ).
        lv_in_tok_str  = request->get_form_field( 'INPUT_TOKENS' ).
        lv_out_tok_str = request->get_form_field( 'OUTPUT_TOKENS' ).
        lv_tot_tok_str = request->get_form_field( 'TOTAL_TOKENS' ).

        IF strlen( lv_prompt ) > 255.
          lv_prompt = lv_prompt(255).
        ENDIF.
        IF strlen( lv_response ) > 255.
          lv_response = lv_response(255).
        ENDIF.
        IF strlen( lv_model ) > 40.
          lv_model = lv_model(40).
        ENDIF.
        IF strlen( lv_status ) > 10.
          lv_status = lv_status(10).
        ENDIF.

        IF lv_chat_id IS INITIAL.
          TRY.
              lv_chat_id = cl_system_uuid=>create_uuid_c32_static( ).
            CATCH cx_root.
              lv_chat_id = |CHAT{ sy-datum }{ sy-uzeit }|.
              WHILE strlen( lv_chat_id ) < 32.
                lv_chat_id = lv_chat_id && '0'.
              ENDWHILE.
          ENDTRY.
        ENDIF.

        IF strlen( lv_chat_id ) > 32.
          lv_chat_id = lv_chat_id(32).
        ENDIF.

        SELECT MAX( msg_id ) FROM zmdg_ai_chat_log
          WHERE chat_id = @lv_chat_id
          INTO @lv_max_msg.

        lv_max_msg = lv_max_msg + 1.

        CLEAR ls_chat_log.
        ls_chat_log-mandt         = sy-mandt.
        ls_chat_log-chat_id       = lv_chat_id.
        ls_chat_log-msg_id        = lv_max_msg.
        ls_chat_log-username      = sy-uname.
        ls_chat_log-chat_date     = sy-datum.
        ls_chat_log-chat_time     = sy-uzeit.
        ls_chat_log-prompt_text   = lv_prompt.
        ls_chat_log-response_text = lv_response.
        ls_chat_log-status        = COND #( WHEN lv_status IS NOT INITIAL 
                                            THEN lv_status ELSE 'SUCCESS' ).
        ls_chat_log-model_name    = lv_model.

        IF lv_in_tok_str CO '0123456789'.
          ls_chat_log-input_tokens = lv_in_tok_str.
        ENDIF.
        IF lv_out_tok_str CO '0123456789'.
          ls_chat_log-output_tokens = lv_out_tok_str.
        ENDIF.
        IF lv_tot_tok_str CO '0123456789'.
          ls_chat_log-total_tokens = lv_tot_tok_str.
        ELSE.
          ls_chat_log-total_tokens = ls_chat_log-input_tokens + 
                                     ls_chat_log-output_tokens.
        ENDIF.

        MODIFY zmdg_ai_chat_log FROM @ls_chat_log.
        COMMIT WORK.

        _m_response->set_status( code = 200 reason = 'OK' ).
        _m_response->set_content_type( 'application/json' ).
        _m_response->set_cdata( 
          |\{"status":"SUCCESS","chat_id":"{ lv_chat_id }","msg_id":"{ ls_chat_log-msg_id }"\}| 
        ).
        navigation->response_complete( ).
        RETURN.

      CATCH cx_root INTO DATA(lx_err).
        DATA(lv_err_msg) = lx_err->get_text( ).
        _m_response->set_status( code = 500 reason = 'Internal Server Error' ).
        _m_response->set_content_type( 'application/json' ).
        _m_response->set_cdata( |\{"status":"ERROR","message":"{ lv_err_msg }"\}| ).
        navigation->response_complete( ).
        RETURN.
    ENDTRY.

  " -------------------------------------------------------------------
  " 2. GET DAFTAR SESI CHAT HISTORY (GET_SESSION_LIST)
  " -------------------------------------------------------------------
  WHEN 'GET_SESSION_LIST' OR 'GET_CHAT_HISTORY'.
    TYPES: BEGIN OF ty_session_summary,
             chat_id       TYPE string,
             title         TYPE string,
             chat_date     TYPE string,
             chat_time     TYPE string,
             msg_count     TYPE i,
           END OF ty_session_summary.

    DATA: lt_raw_logs TYPE TABLE OF zmdg_ai_chat_log,
          ls_raw_log  TYPE zmdg_ai_chat_log,
          lt_sessions TYPE TABLE OF ty_session_summary,
          ls_session  TYPE ty_session_summary,
          lv_json_ses TYPE string.

    SELECT * FROM zmdg_ai_chat_log
      WHERE username = @sy-uname
      ORDER BY chat_date DESCENDING, chat_time DESCENDING, msg_id ASCENDING
      INTO TABLE @lt_raw_logs.

    LOOP AT lt_raw_logs INTO ls_raw_log.
      READ TABLE lt_sessions ASSIGNING FIELD-SYMBOL(<fs_ses>)
        WITH KEY chat_id = ls_raw_log-chat_id.
      IF sy-subrc = 0.
        <fs_ses>-msg_count = <fs_ses>-msg_count + 1.
      ELSE.
        CLEAR ls_session.
        ls_session-chat_id   = ls_raw_log-chat_id.
        ls_session-title     = ls_raw_log-prompt_text.
        ls_session-chat_date = ls_raw_log-chat_date.
        ls_session-chat_time = ls_raw_log-chat_time.
        ls_session-msg_count = 1.
        APPEND ls_session TO lt_sessions.
      ENDIF.
    ENDLOOP.

    /ui2/cl_json=>serialize(
      EXPORTING
        data        = lt_sessions
        pretty_name = /ui2/cl_json=>pretty_mode-low_case
      RECEIVING
        r_json      = lv_json_ses ).

    _m_response->set_status( code = 200 reason = 'OK' ).
    _m_response->set_content_type( 'application/json' ).
    _m_response->set_cdata( lv_json_ses ).
    navigation->response_complete( ).
    RETURN.

  " -------------------------------------------------------------------
  " 3. GET SELURUH PESAN PERCAKAPAN DALAM SESI (GET_SESSION_MESSAGES)
  " -------------------------------------------------------------------
  WHEN 'GET_SESSION_MESSAGES'.
    TYPES: BEGIN OF ty_msg_detail,
             chat_id       TYPE string,
             msg_id        TYPE string,
             username      TYPE string,
             chat_date     TYPE string,
             chat_time     TYPE string,
             prompt_text   TYPE string,
             response_text TYPE string,
             status        TYPE string,
             model_name    TYPE string,
             input_tokens  TYPE i,
             output_tokens TYPE i,
             total_tokens  TYPE i,
           END OF ty_msg_detail.

    DATA: lt_msg_db   TYPE TABLE OF zmdg_ai_chat_log,
          ls_msg_db   TYPE zmdg_ai_chat_log,
          lt_msg_out  TYPE TABLE OF ty_msg_detail,
          ls_msg_out  TYPE ty_msg_detail,
          lv_json_msg TYPE string.

    lv_chat_id = request->get_form_field( 'CHAT_ID' ).

    IF lv_chat_id IS NOT INITIAL.
      SELECT * FROM zmdg_ai_chat_log
        WHERE chat_id = @lv_chat_id
        ORDER BY msg_id ASCENDING
        INTO TABLE @lt_msg_db.

      LOOP AT lt_msg_db INTO ls_msg_db.
        CLEAR ls_msg_out.
        ls_msg_out-chat_id       = ls_msg_db-chat_id.
        ls_msg_out-msg_id        = ls_msg_db-msg_id.
        ls_msg_out-username      = ls_msg_db-username.
        ls_msg_out-chat_date     = ls_msg_db-chat_date.
        ls_msg_out-chat_time     = ls_msg_db-chat_time.
        ls_msg_out-prompt_text   = ls_msg_db-prompt_text.
        ls_msg_out-response_text = ls_msg_db-response_text.
        ls_msg_out-status        = ls_msg_db-status.
        ls_msg_out-model_name    = ls_msg_db-model_name.
        ls_msg_out-input_tokens  = ls_msg_db-input_tokens.
        ls_msg_out-output_tokens = ls_msg_db-output_tokens.
        ls_msg_out-total_tokens  = ls_msg_db-total_tokens.
        APPEND ls_msg_out TO lt_msg_out.
      ENDLOOP.
    ENDIF.

    /ui2/cl_json=>serialize(
      EXPORTING
        data        = lt_msg_out
        pretty_name = /ui2/cl_json=>pretty_mode-low_case
      RECEIVING
        r_json      = lv_json_msg ).

    _m_response->set_status( code = 200 reason = 'OK' ).
    _m_response->set_content_type( 'application/json' ).
    _m_response->set_cdata( lv_json_msg ).
    navigation->response_complete( ).
    RETURN.

ENDCASE.
