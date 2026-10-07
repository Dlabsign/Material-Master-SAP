*----------------------------------------------------------------------*
* Event Handler : OnInitialization
* Page          : test_ai.htm
* Table Target  : ZMDG_AI_CHAT_LOG (SAP MDG AI Chat History)
*----------------------------------------------------------------------*
TYPES: BEGIN OF ty_chat_log_json,
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
       END OF ty_chat_log_json.

DATA: lt_chat_db   TYPE TABLE OF zmdg_ai_chat_log,
      ls_chat_db   TYPE zmdg_ai_chat_log,
      lt_chat_json TYPE TABLE OF ty_chat_log_json,
      ls_chat_json TYPE ty_chat_log_json,
      gv_chat_json TYPE string.

" Read chat history logs for current user from ZMDG_AI_CHAT_LOG
SELECT * FROM zmdg_ai_chat_log
  WHERE username = @sy-uname
  ORDER BY chat_date DESCENDING, chat_time DESCENDING, msg_id DESCENDING
  INTO TABLE @lt_chat_db
  UP TO 100 ROWS.

LOOP AT lt_chat_db INTO ls_chat_db.
  CLEAR ls_chat_json.
  ls_chat_json-chat_id       = ls_chat_db-chat_id.
  ls_chat_json-msg_id        = ls_chat_db-msg_id.
  ls_chat_json-username      = ls_chat_db-username.
  ls_chat_json-chat_date     = ls_chat_db-chat_date.
  ls_chat_json-chat_time     = ls_chat_db-chat_time.
  ls_chat_json-prompt_text   = ls_chat_db-prompt_text.
  ls_chat_json-response_text = ls_chat_db-response_text.
  ls_chat_json-status        = ls_chat_db-status.
  ls_chat_json-model_name    = ls_chat_db-model_name.
  ls_chat_json-input_tokens  = ls_chat_db-input_tokens.
  ls_chat_json-output_tokens = ls_chat_db-output_tokens.
  ls_chat_json-total_tokens  = ls_chat_db-total_tokens.
  APPEND ls_chat_json TO lt_chat_json.
ENDLOOP.

/ui2/cl_json=>serialize(
  EXPORTING
    data        = lt_chat_json
    compress    = 'X'
    pretty_name = /ui2/cl_json=>pretty_mode-low_case
  RECEIVING
    r_json      = gv_chat_json ).
