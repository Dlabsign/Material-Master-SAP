*======================================================================*
* BSP PAGE ATTRIBUTES: ZBP_REQUEST
* Application: MDG Business Partner - User Request (Organization)
* Standard T-Code: BP (Create Organization - Address & General Data)
* Environment: SAP S/4HANA 1809 / NetWeaver 7.50+
*======================================================================*

* Attribute Name    Typing Method    Associated Type     Auto   Description
* -----------------------------------------------------------------------
* GT_COUNTRIES      TYPE             TY_T_DROPDOWN       [ ]    Countries Buffer
* GT_MESSAGES       TYPE             TY_T_MESSAGES       [X]    Alerts & Notifications
* WA_REQ            TYPE             TY_BP_REQUEST       [X]    Current Staging Record
* GT_MY_REQUESTS    TYPE             TY_T_BP_REQUEST     [X]    Request History Drafts
* GV_REQ_ID         TYPE             CHAR10              [X]    Request ID Key
* GT_ROLES          TYPE             TY_T_DROPDOWN       [ ]    BP Roles Buffer
* GT_BP_ROLES       TYPE             TY_T_BP_ROLES       [ ]    BP Roles (TB003/TB003T)
* GT_BP_GROUPING    TYPE             TY_T_BP_GROUPING    [ ]    BP Grouping (TB001/TB002)
* GT_LANGUAGES      TYPE             TY_T_LANGUAGES      [ ]    Languages Buffer (T002/T002T)
* GT_REGIONS        TYPE             TY_T_DROPDOWN       [ ]    Regions Buffer
* GT_DUPLICATES     TYPE             TY_T_DUPLICATES     [ ]    Duplicate Check Buffer
*
* CATATAN PENTING SE80:
* 1. Error 'Type TY_T_DUPLICATES is unknown' teratasi karena tipe TY_T_DUPLICATES
*    telah dideklarasikan di type_definitions.abap.
* 2. Nama atribut negara & wilayah disesuaikan dengan SE80: GT_COUNTRIES dan GT_REGIONS.
* 3. Tambahkan atribut publik GT_BP_ROLES TYPE TY_T_BP_ROLES untuk dropdown dinamis TB003.
* 4. Tambahkan atribut publik GT_BP_GROUPING TYPE TY_T_BP_GROUPING untuk TB001/TB002.
* 5. Tambahkan atribut publik GT_LANGUAGES TYPE TY_T_LANGUAGES untuk T002/T002T.
