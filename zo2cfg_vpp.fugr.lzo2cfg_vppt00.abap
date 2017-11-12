*---------------------------------------------------------------------*
*    view related data declarations
*   generation date: 27.10.2016 at 17:06:10
*   view maintenance generator version: #001407#
*---------------------------------------------------------------------*
*...processing: ZO2CTAB_SERV_VPP................................*
DATA:  BEGIN OF STATUS_ZO2CTAB_SERV_VPP              .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZO2CTAB_SERV_VPP              .
CONTROLS: TCTRL_ZO2CTAB_SERV_VPP
            TYPE TABLEVIEW USING SCREEN '0111'.
*.........table declarations:.................................*
TABLES: *ZO2CTAB_SERV_VPP              .
TABLES: ZO2CTAB_SERV_VPP               .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
