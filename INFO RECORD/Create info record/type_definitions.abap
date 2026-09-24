*"----------------------------------------------------------------------*
*" TYPE DEFINITIONS FOR PURCHASING INFO RECORD (ME11) STAGING WORKFLOW
*" Database tables based on Data.xlsx:
*"   - ZMDG_REQ_PIR (Header Permintaan Info Record)
*"   - ZMDG_PIR_ITM (Detail Organisasi Pengadaan & Plant)
*"   - ZMDG_PIR_CND (Detail Kondisi Harga)
*"   - ZMDG_PIR_ADT (Audit Trail & Log Approval)
*"----------------------------------------------------------------------*

TYPES: BEGIN OF ty_req_pir,
         mandt       TYPE mandt,
         req_id      TYPE c LENGTH 10,
         action_type TYPE c LENGTH 2,
         status      TYPE c LENGTH 2,
         infnr       TYPE c LENGTH 10,
         lifnr       TYPE c LENGTH 10,
         matnr       TYPE c LENGTH 40,
         txz01       TYPE c LENGTH 40,
         matkl       TYPE c LENGTH 9,
         idnlf       TYPE c LENGTH 35,
         ernam       TYPE c LENGTH 12,
         erdat       TYPE dats,
         erzet       TYPE tims,
         aenam       TYPE c LENGTH 12,
         aedat       TYPE dats,
         aezet       TYPE tims,
       END OF ty_req_pir.

TYPES: BEGIN OF ty_pir_itm,
         mandt       TYPE mandt,
         req_id      TYPE c LENGTH 10,
         item_no     TYPE n LENGTH 6,
         ekorg       TYPE c LENGTH 4,
         werks       TYPE c LENGTH 4,
         esokz       TYPE c LENGTH 1,
         ekgrp       TYPE c LENGTH 3,
         aplfz       TYPE p LENGTH 8 DECIMALS 0,
         norbm       TYPE p LENGTH 8 DECIMALS 3,
         minbm       TYPE p LENGTH 8 DECIMALS 3,
         uebto       TYPE p LENGTH 8 DECIMALS 1,
         untto       TYPE p LENGTH 8 DECIMALS 1,
         netpr       TYPE p LENGTH 8 DECIMALS 2,
         waers       TYPE c LENGTH 5,
         peinh       TYPE p LENGTH 8 DECIMALS 0,
         bprme       TYPE c LENGTH 3,
         mwskz       TYPE c LENGTH 2,
         inco1       TYPE c LENGTH 3,
         inco2       TYPE c LENGTH 28,
         datab       TYPE dats,
         datbi       TYPE dats,
         post_status TYPE c LENGTH 1,
         post_msg    TYPE c LENGTH 220,
       END OF ty_pir_itm.

TYPES: BEGIN OF ty_pir_cnd,
         mandt      TYPE mandt,
         req_id     TYPE c LENGTH 10,
         item_no    TYPE n LENGTH 4,
         cond_count TYPE n LENGTH 3,
         kschl      TYPE c LENGTH 4,
         kbetr      TYPE p LENGTH 8 DECIMALS 2,
         konwa      TYPE c LENGTH 5,
         kpein      TYPE p LENGTH 8 DECIMALS 0,
         kmein      TYPE c LENGTH 3,
       END OF ty_pir_cnd.

TYPES: BEGIN OF ty_pir_adt,
         mandt      TYPE mandt,
         req_id     TYPE c LENGTH 10,
         log_id     TYPE n LENGTH 4,
         approv_lvl TYPE n LENGTH 2,
         action     TYPE c LENGTH 10,
         actor      TYPE c LENGTH 12,
         act_date   TYPE dats,
         act_time   TYPE tims,
         comments   TYPE c LENGTH 255,
       END OF ty_pir_adt.

TYPES: BEGIN OF ty_history,
         req_id        TYPE string,
         lifnr         TYPE string,
         lifnr_name    TYPE string,
         matnr         TYPE string,
         txz01         TYPE string,
         erdat         TYPE string,
         erzet         TYPE string,
         ernam         TYPE string,
         ernam_name    TYPE string,
         status        TYPE string,
         status_desc   TYPE string,
         item_count    TYPE i,
         comments      TYPE string,
       END OF ty_history,
       ty_history_tab TYPE TABLE OF ty_history.

TYPES: BEGIN OF ty_lookup_vendor,
         lifnr TYPE string,
         name1 TYPE string,
         ort01 TYPE string,
         land1 TYPE string,
       END OF ty_lookup_vendor.

TYPES: BEGIN OF ty_lookup_material,
         matnr TYPE string,
         maktx TYPE string,
         matkl TYPE string,
         meins TYPE string,
       END OF ty_lookup_material.

TYPES: BEGIN OF ty_lookup_plant,
         werks TYPE string,
         name1 TYPE string,
       END OF ty_lookup_plant.

TYPES: BEGIN OF ty_lookup_porg,
         ekorg TYPE string,
         ekotx TYPE string,
       END OF ty_lookup_porg.
