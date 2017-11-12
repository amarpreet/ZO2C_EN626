*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations


CLASS lcl_progid IMPLEMENTATION.
**********************************************************************
  METHOD factory .

    result = NEW #( ) .

    result->create_porgid(
      EXPORTING
        i_lifnr     = i_lifnr
        i_ekorg     = i_ekorg
        i_ext_vend  = i_ext_vend ).

  ENDMETHOD.

  METHOD updateclaimref .
    me->gs_prog_status-ext_vend = i_ext_vend .

    me->checkclaimref(
      EXPORTING
        i_lifnr     = gs_prog_status-lifnr
        i_ekorg     = gs_prog_status-ekorg
        i_ext_vend  = gs_prog_status-ext_vend
    ).

    me->db_modify( is_prog_status = me->gs_prog_status ).
  ENDMETHOD.
**********************************************************************
  METHOD get_progid_num .
*  get the next number from the number range .
    CALL FUNCTION 'NUMBER_GET_NEXT'
      EXPORTING
        nr_range_nr             = '01'      " Number range number
        object                  = 'ZZPROGID' ##NO_TEXT  " Name of number range object
*       quantity                = '1'       " Number of numbers
*       subobject               = SPACE     " Value of subobject
*       toyear                  = '0000'    " Value of To-fiscal year
*       ignore_buffer           = SPACE     " Ignore object buffering
      IMPORTING
        number                  = result    " free number
*       quantity                =           " Number of numbers
*       returncode              =           " Return code
      EXCEPTIONS
        interval_not_found      = 1
        number_range_not_intern = 2
        object_not_found        = 3
        quantity_is_0           = 4
        quantity_is_not_1       = 5
        interval_overflow       = 6
        buffer_overflow         = 7
        OTHERS                  = 8.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_o2c_vpp
        EXPORTING
          textid = VALUE #( msgid = sy-msgid msgno = sy-msgno attr1 = sy-msgv1 attr2 = sy-msgv2 attr3 = sy-msgv3 attr4 = sy-msgv4 ).
    ENDIF.
  ENDMETHOD.

**********************************************************************
  METHOD constructor.
    IF i_progid IS SUPPLIED.
      me->fetch_progid_single( i_progid =  i_progid ).
    ENDIF.
  ENDMETHOD.
  """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
  METHOD fetch_progid_single .

    IF NOT i_progid IS INITIAL .
      DATA(lv_progid) = i_progid .

      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
        EXPORTING
          input  = i_progid
        IMPORTING
          output = lv_progid.

*    custom table we need all fields for ths app
      SELECT SINGLE * FROM zo2ctab_progid
          INTO CORRESPONDING FIELDS OF @me->gs_prog_status
          WHERE progid = @lv_progid .
      IF sy-subrc EQ 0 AND me->gs_prog_status IS NOT INITIAL .
        me->enqueue( ).
        result = me .
      ELSE.
        RAISE EXCEPTION TYPE zcx_o2c_vpp
          EXPORTING
            textid = VALUE #( msgid = zcx_o2c_vpp=>msgid msgno = '062' attr1 = 'lcl_progid create_porgid'  ##NO_TEXT
            attr2 = space attr3 = space attr4 = space ).
      ENDIF.
    ELSE.
      RAISE EXCEPTION TYPE zcx_o2c_vpp
        EXPORTING
          textid = VALUE #( msgid = zcx_o2c_vpp=>msgid msgno = '062' attr1 = 'lcl_progid create_porgid' ##NO_TEXT
           attr2 = space attr3 = space attr4 = space ).
    ENDIF.
  ENDMETHOD.
  """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
  METHOD create_porgid.
    IF NOT i_lifnr  IS INITIAL
       AND NOT i_ekorg IS INITIAL .

      IF i_ext_vend IS NOT INITIAL .
        me->checkclaimref(
            i_lifnr    = i_lifnr
            i_ekorg    = i_ekorg
            i_ext_vend = i_ext_vend
        ).
      ENDIF.
      me->db_create( is_prog_status =
                VALUE #( progid = me->get_progid_num( ) lifnr  = i_lifnr
                         ekorg = i_ekorg  ext_vend = i_ext_vend   ) ).



    ELSE.
      RAISE EXCEPTION TYPE zcx_o2c_vpp
        EXPORTING
          textid = VALUE #( msgid = zcx_o2c_vpp=>msgid msgno = '062' attr1 = 'lcl_progid create_porgid' ##NO_TEXT
          attr2 = space attr3 = space attr4 = space ).
    ENDIF.
  ENDMETHOD.

  METHOD fetch_progid.
*    custom table we need all fields for ths app
    SELECT * FROM zo2ctab_progid
    INTO CORRESPONDING FIELDS OF TABLE @result
       WHERE progid IN @ir_progid
         AND ekorg  IN @ir_ekorg
         AND lifnr  IN @ir_lifnr
         AND ext_vend IN @ir_ext_vend .
    IF sy-subrc NE 0 OR result IS INITIAL.
      RAISE EXCEPTION TYPE zcx_o2c_vpp
        EXPORTING
          textid = VALUE #( msgid = zcx_o2c_vpp=>msgid msgno = '060' attr1 = space attr2 = space attr3 = space attr4 = space ).
    ENDIF.
  ENDMETHOD.                                             "#EC CI_VALPAR

  METHOD update_status.
    IF    i_upload         IS INITIAL
        AND i_calc_stk     IS INITIAL
        AND i_calc_po      IS INITIAL
        AND i_crt_claim    IS INITIAL
        AND i_upd_pir_csp  IS INITIAL
        AND i_upd_stk      IS INITIAL
        AND i_upd_po       IS INITIAL
        AND i_upd_stk_rev  IS INITIAL
        AND i_upd_po_rev   IS INITIAL
        AND i_settle       IS INITIAL .
      RAISE EXCEPTION TYPE zcx_o2c_vpp
        EXPORTING
          textid = VALUE #( msgid = zcx_o2c_vpp=>msgid msgno = '062' attr1 = 'lcl_progid update_status'  ##NO_TEXT
          attr2 = space attr3 = space attr4 = space ).
    ENDIF.

    CASE abap_true .

      WHEN i_upload .
        IF  " ( me->gs_prog_status-upload   is initial or me->gs_prog_status-upload     is not initial )
*          and me->gs_prog_status-calc_stk     is initial
*          and me->gs_prog_status-calc_po      is initial
           me->gs_prog_status-crt_claim    IS INITIAL
*          and me->gs_prog_status-upd_pir_csp  is initial
          AND me->gs_prog_status-upd_stk      IS INITIAL
          AND me->gs_prog_status-upd_po       IS INITIAL
          AND me->gs_prog_status-upd_stk_rev  IS INITIAL
          AND me->gs_prog_status-upd_po_rev   IS INITIAL
          AND me->gs_prog_status-settle       IS INITIAL .
          me->gs_prog_status-upload = abap_true .
        ELSE.
          RAISE EXCEPTION TYPE zcx_o2c_vpp
            EXPORTING
              textid = VALUE #( msgid = zcx_o2c_vpp=>msgid msgno = '061' attr1 = 'Upload VPP' ##NO_TEXT
               attr2 = space attr3 = space attr4 = space ).
        ENDIF.
*      when i_calc_stk .
*        if  me->gs_prog_status-upload     is not initial
**          and me->gs_prog_status-calc_stk     is initial
**          and me->gs_prog_status-calc_po      is initial
*          and me->gs_prog_status-crt_claim    is initial
*          and me->gs_prog_status-upd_pir_csp  is initial
*          and me->gs_prog_status-upd_stk      is initial
*          and me->gs_prog_status-upd_po       is initial
*          and me->gs_prog_status-upd_stk_rev  is initial
*          and me->gs_prog_status-upd_po_rev   is initial
*          and me->gs_prog_status-settle       is initial .
*          me->gs_prog_status-calc_stk = abap_true .
*        else.
*          raise exception type zcx_o2c_vpp
*            exporting
*              textid = value #( msgid = zcx_o2c_vpp=>msgid msgno = '061' attr1 = 'Calculate Stock' attr2 = space attr3 = space attr4 = space ).
*        endif.
*      when i_calc_po  .
*        if  me->gs_prog_status-upload     is not initial
**          and me->gs_prog_status-calc_stk is not initial
**          and me->gs_prog_status-calc_po      is initial
*          and me->gs_prog_status-crt_claim    is initial
*          and me->gs_prog_status-upd_pir_csp  is initial
*          and me->gs_prog_status-upd_stk      is initial
*          and me->gs_prog_status-upd_po       is initial
*          and me->gs_prog_status-upd_stk_rev  is initial
*          and me->gs_prog_status-upd_po_rev   is initial
*          and me->gs_prog_status-settle       is initial .
*          me->gs_prog_status-calc_po = abap_true .
*        else.
*          raise exception type zcx_o2c_vpp
*            exporting
*              textid = value #( msgid = zcx_o2c_vpp=>msgid msgno = '061' attr1 = 'Calculate PO' attr2 = space attr3 = space attr4 = space ).
*        endif.
      WHEN i_crt_claim .
        IF  me->gs_prog_status-upload     IS NOT INITIAL
*          and me->gs_prog_status-calc_stk is not initial
*          and me->gs_prog_status-calc_po  is not initial
          AND me->gs_prog_status-crt_claim    IS INITIAL
          AND me->gs_prog_status-upd_pir_csp  IS INITIAL
          AND me->gs_prog_status-upd_stk      IS INITIAL
          AND me->gs_prog_status-upd_po       IS INITIAL
          AND me->gs_prog_status-upd_stk_rev  IS INITIAL
          AND me->gs_prog_status-upd_po_rev   IS INITIAL
          AND me->gs_prog_status-settle       IS INITIAL .
          me->gs_prog_status-crt_claim = abap_true .
        ELSE.
          RAISE EXCEPTION TYPE zcx_o2c_vpp
            EXPORTING
              textid = VALUE #( msgid = zcx_o2c_vpp=>msgid msgno = '061' attr1 = 'Create Claim' ##NO_TEXT
              attr2 = space attr3 = space attr4 = space ).
        ENDIF.
      WHEN i_upd_pir_csp .
        IF  me->gs_prog_status-upload     IS NOT INITIAL
*        and me->gs_prog_status-calc_stk   is not initial
*        and me->gs_prog_status-calc_po    is not initial
        AND me->gs_prog_status-crt_claim  IS NOT INITIAL
        AND me->gs_prog_status-upd_pir_csp  IS INITIAL
        AND me->gs_prog_status-upd_stk      IS INITIAL
        AND me->gs_prog_status-upd_po       IS INITIAL
        AND me->gs_prog_status-upd_stk_rev  IS INITIAL
        AND me->gs_prog_status-upd_po_rev   IS INITIAL
        AND me->gs_prog_status-settle       IS INITIAL .
          me->gs_prog_status-upd_pir_csp = abap_true .
        ELSE.
          RAISE EXCEPTION TYPE zcx_o2c_vpp
            EXPORTING
              textid = VALUE #( msgid = zcx_o2c_vpp=>msgid msgno = '061' attr1 = 'Update PIR CSP' ##NO_TEXT
              attr2 = space attr3 = space attr4 = space ).
        ENDIF.
      WHEN i_upd_stk  .
        IF  me->gs_prog_status-upload     IS NOT INITIAL
*         and me->gs_prog_status-calc_stk   is not initial
*         and me->gs_prog_status-calc_po    is not initial
         AND me->gs_prog_status-crt_claim  IS NOT INITIAL
*         and me->gs_prog_status-upd_pir_csp is not initial
         AND me->gs_prog_status-upd_stk      IS INITIAL
*         and me->gs_prog_status-upd_po       is initial
*         and me->gs_prog_status-upd_stk_rev  is initial
*         and me->gs_prog_status-upd_po_rev   is initial
         AND me->gs_prog_status-settle       IS INITIAL .
          me->gs_prog_status-upd_stk = abap_true .
        ELSE.
          RAISE EXCEPTION TYPE zcx_o2c_vpp
            EXPORTING
              textid = VALUE #( msgid = zcx_o2c_vpp=>msgid msgno = '061' attr1 = 'Stock Update' ##NO_TEXT
              attr2 = space attr3 = space attr4 = space ).

        ENDIF.
      WHEN i_upd_po   .
        IF  me->gs_prog_status-upload     IS NOT INITIAL
*         and me->gs_prog_status-calc_stk   is not initial
*         and me->gs_prog_status-calc_po    is not initial
         AND me->gs_prog_status-crt_claim  IS NOT INITIAL
*         and me->gs_prog_status-upd_pir_csp is not initial
*         and me->gs_prog_status-upd_stk      is not initial
         AND me->gs_prog_status-upd_po       IS INITIAL
*         and me->gs_prog_status-upd_stk_rev  is initial
*         and me->gs_prog_status-upd_po_rev   is initial
         AND me->gs_prog_status-settle       IS INITIAL .
          me->gs_prog_status-upd_po = abap_true .
        ELSE.
          RAISE EXCEPTION TYPE zcx_o2c_vpp
            EXPORTING
              textid = VALUE #( msgid = zcx_o2c_vpp=>msgid msgno = '061' attr1 = 'Po Update' ##NO_TEXT
              attr2 = space attr3 = space attr4 = space ).
        ENDIF .
      WHEN i_upd_stk_rev .
        IF  me->gs_prog_status-upload     IS NOT INITIAL
*         and me->gs_prog_status-calc_stk   is not initial
*         and me->gs_prog_status-calc_po    is not initial
         AND me->gs_prog_status-crt_claim  IS NOT INITIAL
*         and me->gs_prog_status-upd_pir_csp is not initial
         AND me->gs_prog_status-upd_stk      IS NOT INITIAL
*         and me->gs_prog_status-upd_po       is not initial
         AND me->gs_prog_status-upd_stk_rev  IS INITIAL
*         and me->gs_prog_status-upd_po_rev   is initial
         AND me->gs_prog_status-settle       IS INITIAL .
*          me->gs_prog_status-upd_stk_rev = abap_true .
          me->gs_prog_status-upd_stk = abap_false .
        ELSE.
          RAISE EXCEPTION TYPE zcx_o2c_vpp
            EXPORTING
              textid = VALUE #( msgid = zcx_o2c_vpp=>msgid msgno = '061' attr1 = 'Stock Rev' ##NO_TEXT
              attr2 = space attr3 = space attr4 = space ).
        ENDIF .
      WHEN i_upd_po_rev .
        IF  me->gs_prog_status-upload       IS NOT INITIAL
*         and me->gs_prog_status-calc_stk    is not initial
*         and me->gs_prog_status-calc_po     is not initial
         AND me->gs_prog_status-crt_claim   IS NOT INITIAL
*         and me->gs_prog_status-upd_pir_csp is not initial
*         and me->gs_prog_status-upd_stk      is not initial
         AND me->gs_prog_status-upd_po       IS NOT INITIAL
*         and me->gs_prog_status-upd_stk_rev  is not  initial
         AND me->gs_prog_status-upd_po_rev   IS INITIAL
         AND me->gs_prog_status-settle       IS INITIAL .
          me->gs_prog_status-upd_po_rev = abap_true .
        ELSE.
          RAISE EXCEPTION TYPE zcx_o2c_vpp
            EXPORTING
              textid = VALUE #( msgid = zcx_o2c_vpp=>msgid msgno = '061' attr1 = 'PO Rev' ##NO_TEXT
              attr2 = space attr3 = space attr4 = space ).
        ENDIF.
      WHEN i_settle    .
        IF  me->gs_prog_status-upload         IS NOT INITIAL
*          and me->gs_prog_status-calc_stk     is not initial
*          and me->gs_prog_status-calc_po      is not initial
          AND me->gs_prog_status-crt_claim    IS NOT INITIAL
*          and me->gs_prog_status-upd_pir_csp  is not initial
          AND ( me->gs_prog_status-upd_stk      IS NOT INITIAL OR  me->gs_prog_status-upd_po IS NOT INITIAL )
*          and me->gs_prog_status-upd_stk_rev  is not  initial
*          and me->gs_prog_status-upd_po_rev   is not initial
          AND me->gs_prog_status-settle       IS INITIAL .
          me->gs_prog_status-settle = abap_true .
        ELSE.
          RAISE EXCEPTION TYPE zcx_o2c_vpp
            EXPORTING
              textid = VALUE #( msgid = zcx_o2c_vpp=>msgid msgno = '061' attr1 = 'Settle' ##NO_TEXT
              attr2 = space attr3 = space attr4 = space ).
        ENDIF.
    ENDCASE.

    me->db_modify( me->gs_prog_status ).
  ENDMETHOD.

  METHOD db_create.
    DATA : ls_progid TYPE zo2ctab_progid .
    MOVE-CORRESPONDING is_prog_status TO ls_progid .
    ls_progid-mandt = sy-mandt .
    INSERT zo2ctab_progid FROM ls_progid .
    IF sy-subrc NE 0 .
      RAISE EXCEPTION TYPE zcx_o2c_vpp
        EXPORTING
          textid = VALUE #( msgid = zcx_o2c_vpp=>msgid msgno = '060' attr1 = space attr2 = space attr3 = space attr4 = space ).
    ELSE.
      me->enqueue( ).
      CLEAR me->gs_prog_status .
      me->gs_prog_status = is_prog_status .
    ENDIF.
  ENDMETHOD.

  METHOD db_modify.
    DATA : ls_progid TYPE zo2ctab_progid .
    MOVE-CORRESPONDING is_prog_status TO ls_progid .
    ls_progid-mandt = sy-mandt .
    MODIFY zo2ctab_progid FROM ls_progid .
    IF sy-subrc NE 0 .
      RAISE EXCEPTION TYPE zcx_o2c_vpp
        EXPORTING
          textid = VALUE #( msgid = zcx_o2c_vpp=>msgid msgno = '060' attr1 = space attr2 = space attr3 = space attr4 = space ).
    ELSE.
      COMMIT WORK AND WAIT .
      me->gs_prog_status = is_prog_status .
    ENDIF.
  ENDMETHOD.

  METHOD enqueue.
    CALL FUNCTION 'ENQUEUE_EZPROGID'
      EXPORTING
        progid         = me->gs_prog_status-progid  " 02th enqueue argument
      EXCEPTIONS
        foreign_lock   = 1
        system_failure = 2
        OTHERS         = 3.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_o2c_vpp
        EXPORTING
          textid = VALUE #( msgid = sy-msgid msgno = sy-msgno attr1 = sy-msgv1 attr2 = sy-msgv2 attr3 = sy-msgv3 attr4 = sy-msgv4 ).
    ENDIF.
  ENDMETHOD.

  METHOD dequeue.
    CALL FUNCTION 'DEQUEUE_EZPROGID'
      EXPORTING
        progid = me->gs_prog_status-progid.   " 02th enqueue argument
  ENDMETHOD.

  METHOD checkclaimref.
    SELECT SINGLE progid FROM zo2ctab_progid
        INTO @DATA(lv_progid)
        WHERE ext_vend EQ @i_ext_vend
          AND lifnr EQ @i_lifnr
          AND ekorg EQ @i_ekorg. "#EC CI_NOFIELD we are fectching the primary key here . cannot be in where
    IF sy-subrc EQ 0 .
      IF lv_progid EQ me->gs_prog_status-progid .
*         allowed
      ELSE.
        RAISE EXCEPTION TYPE zcx_o2c_vpp
          EXPORTING
            textid = VALUE #( msgid = zcx_o2c_vpp=>msgid msgno = '081' attr1 = lv_progid
             attr2 = space attr3 = space attr4 = space ).
      ENDIF.
    ENDIF.
  ENDMETHOD.

ENDCLASS.


CLASS lcl_claim IMPLEMENTATION.

  METHOD constructor.
    IF io_progid IS NOT INITIAL .
      me->go_progid = io_progid .
    ELSE.
      RAISE EXCEPTION TYPE zcx_o2c_vpp
        EXPORTING
          textid = VALUE #( msgid = zcx_o2c_vpp=>msgid msgno = '062' attr1 = 'lcl_claim consturctor' ##NO_TEXT
           attr2 = space attr3 = space attr4 = space ).
    ENDIF.
  ENDMETHOD.
  METHOD fetch_claims.
    result = me .
    IF me->go_progid->gs_prog_status-crt_claim IS INITIAL .
      CLEAR me->gt_claim .
      me->gt_claim = me->dyn_read( ).
    ELSE .
      CLEAR me->gt_claim .
      me->gt_claim = me->db_read( ).
    ENDIF.
  ENDMETHOD.
  METHOD freeze_claim .
    DATA : lt_claim TYPE TABLE OF zo2ctab_claimid .
    IF NOT it_claims IS INITIAL .
      lt_claim = VALUE #( FOR ls IN it_claims ( CORRESPONDING #( ls ) ) ) .
      MODIFY zo2ctab_claimid FROM TABLE lt_claim .
      IF sy-subrc NE 0 .
        RAISE EXCEPTION TYPE zcx_o2c_vpp
          EXPORTING
            textid = VALUE #( msgid = zcx_o2c_vpp=>msgid
                              msgno = '060' attr1 = space attr2 = space
                              attr3 = space attr4 = space ).
      ENDIF.
    ELSE.
*      exp
      RAISE EXCEPTION TYPE zcx_o2c_vpp
        EXPORTING
          textid = VALUE #( msgid = zcx_o2c_vpp=>msgid
                            msgno = '062' attr1 = 'Freeze Claims' attr2 = space ##NO_TEXT
                            attr3 = space attr4 = space ).
    ENDIF .
  ENDMETHOD.

  METHOD dyn_read .
    TYPES: BEGIN OF lty_konh ,
             knumh   TYPE konh-knumh,               " condition number
             kappl   TYPE konh-kappl,               " application
             kschl   TYPE konh-kschl,               " condition
             tabname TYPE dd03l-tabname,            " table name
             vakey   TYPE konh-vakey,               " var key
             kbetr   TYPE konp-kbetr,               " value
             konwa   TYPE konp-konwa,               " unit
             kunnr   TYPE kunnr,                    " key value
             lifnr   TYPE lifnr,                    " key value
             matnr   TYPE matnr,                    " key value
             f_kunnr TYPE flag,                     " is relevant for record
             f_lifnr TYPE flag,                     " is relevant for record
             f_matnr TYPE flag,                     " is relevant for record
           END OF lty_konh .
    DATA : lt_konh   TYPE TABLE OF lty_konh,
           lr_data   TYPE REF TO data,
           lv_varkey TYPE char200,
           ls_claim  TYPE zclo2c_vpp=>gty_claim,
           lv_where  TYPE string.
    FIELD-SYMBOLS: <fs_table> TYPE any,
                   <fs_var>   TYPE any.

    SELECT  MAX( konh~knumh ) , " this was added latter as multipule uploads cause many conditions with the same var key and validity in konh
            konh~kappl ,
            konh~kschl ,
            konh~kvewe && kotabnr AS tabname ,
            konh~vakey ,
            konp~kbetr ,
            konp~konwa
        FROM konh INNER JOIN konp
            ON konh~knumh = konp~knumh
        INTO TABLE @lt_konh
        WHERE konh~kschl = @me->gc_zvpp
          AND konh~kosrt = @me->go_progid->gs_prog_status-progid
          AND konh~datbi >= @sy-datum
          GROUP BY konh~kappl ,
            konh~kschl ,
            konh~kvewe && kotabnr ,
            konh~vakey ,
            konp~kbetr ,
            konp~konwa .
    IF sy-subrc EQ 0 AND lt_konh  IS NOT INITIAL .
      LOOP AT lt_konh ASSIGNING FIELD-SYMBOL(<fs_konh>) .
        lv_varkey+0(3)   = sy-mandt.
        lv_varkey+3(2)   = <fs_konh>-kappl.
        lv_varkey+5(4)   = <fs_konh>-kschl.
        lv_varkey+9(100) = <fs_konh>-vakey.
        CREATE DATA lr_data TYPE (<fs_konh>-tabname) .
        IF lr_data IS BOUND .
          ASSIGN lr_data->* TO <fs_table> .
          IF <fs_table> IS ASSIGNED .
            <fs_table> = lv_varkey .
            ASSIGN COMPONENT 'KUNAG' OF STRUCTURE <fs_table> TO <fs_var>  .
            IF sy-subrc EQ 0 .
              <fs_konh>-kunnr = <fs_var> .
              <fs_konh>-f_kunnr = abap_true .
            ENDIF.
            ASSIGN COMPONENT 'LIFNR' OF STRUCTURE <fs_table> TO <fs_var>  .
            IF sy-subrc EQ 0 .
              <fs_konh>-lifnr = <fs_var> .
              <fs_konh>-f_lifnr = abap_true .
            ENDIF.
            ASSIGN COMPONENT 'MATNR' OF STRUCTURE <fs_table> TO <fs_var>  .
            IF sy-subrc EQ 0 .
              <fs_konh>-matnr = <fs_var> .
              <fs_konh>-f_matnr = abap_true .
            ENDIF.
          ENDIF .
        ENDIF.
      ENDLOOP.
      IF NOT lt_konh IS INITIAL .
        SELECT zmmtab_stckresqt~kunnr ,
               zmmtab_stckresqt~matnr ,
               ekko~lifnr ,   " added on 16 November 2016
               zmmtab_stckresqt~ebeln ,
               zmmtab_stckresqt~ebelp ,
               zmmtab_stckresqt~etens ,
               zmmtab_stckresqt~remaining_qty ,
               zmmtab_stckresqt~zpoprc ,
               zmmtab_stckresqt~zpocur ,
               zmmtab_stckresqt~zpoprc_lc ,
               zmmtab_stckresqt~zlcurr,
               zmmtab_stckresqt~zppprc ,
               zmmtab_stckresqt~zppcur ,
               zmmtab_stckresqt~receipt_date
          FROM zmmtab_stckresqt LEFT OUTER JOIN ekko ON
                zmmtab_stckresqt~ebeln EQ ekko~ebeln
          INTO TABLE @DATA(lt_stckreqst)
          FOR ALL ENTRIES IN @lt_konh
          WHERE zmmtab_stckresqt~matnr EQ @lt_konh-matnr
            AND zmmtab_stckresqt~receipt_date IS NOT NULL
*            and lifnr eq @lt_konh-lifnr
            AND zmmtab_stckresqt~kunnr EQ @lt_konh-kunnr .
        IF sy-subrc EQ 0  .
          DELETE lt_stckreqst WHERE receipt_date IS INITIAL . "#EC CI_STDSEQ " necessary as the Custom table date field was filled in incrrectly
        ENDIF.
        SELECT matnr ,
               mfrpn
          FROM mara
          INTO TABLE @DATA(lt_mara)
          FOR ALL ENTRIES IN @lt_konh
              WHERE matnr EQ @lt_konh-matnr . "#EC CI_SUBRC not direct consequence


        SELECT ekko~ebeln ,
               ekko~lifnr ,
               ekpo~ebelp ,
               ekpo~matnr ,
               ekko~zzkunnr AS kunnr ,
               eket~etenr ,
               ekpo~netpr ,
               ekko~waers ,
               eket~menge ,
               eket~wemng
           FROM ekko INNER JOIN ekpo
               ON ekko~ebeln = ekpo~ebeln
                     INNER JOIN eket
             ON ekpo~ebeln = eket~ebeln
            AND ekpo~ebelp = eket~ebelp
           INTO TABLE @DATA(lt_ek)
           FOR ALL ENTRIES IN @lt_konh
           WHERE ekpo~matnr EQ @lt_konh-matnr
             AND ekko~lifnr EQ @lt_konh-lifnr
*             and ekko~zzkunnr eq @lt_konh-kunnr
             AND eket~menge GT eket~wemng.
        IF sy-subrc EQ 0 .
          SORT lt_ek BY ebeln lifnr ebelp matnr etenr .
        ENDIF.

      ENDIF .

      LOOP AT lt_konh INTO DATA(ls_konh)  .

        ls_claim-progid            =  me->go_progid->gs_prog_status-progid .
        ls_claim-matnr             =  ls_konh-matnr .
        ls_claim-lifnr             =  ls_konh-lifnr .
        ls_claim-kunnr             =  ls_konh-kunnr .
        ls_claim-valid             =  sy-datum      .
        ls_claim-vpp_newval        =  ls_konh-kbetr .
        ls_claim-vpp_newcurr       =  ls_konh-konwa .

        DATA(ls_mara) = VALUE #( lt_mara[ matnr = ls_konh-matnr ] OPTIONAL ) . "#EC CI_STDSEQ
        ls_claim-mfrpn             =    ls_mara-mfrpn      .

        CLEAR lv_where .

        IF ls_konh-f_kunnr IS NOT INITIAL .
          addtowhere lv_where 'and' 'kunnr eq ls_konh-kunnr' ##NO_TEXT .
        ELSE.
          addtowhere lv_where 'and' 'kunnr is initial' ##NO_TEXT .
        ENDIF.
*
        IF ls_konh-f_lifnr IS NOT INITIAL .
          addtowhere lv_where 'and' 'lifnr eq ls_konh-lifnr' ##NO_TEXT .
        ELSE.
          addtowhere lv_where 'and' 'lifnr is initial' ##NO_TEXT .
        ENDIF.

        IF ls_konh-f_matnr IS NOT INITIAL .
          addtowhere lv_where 'and' 'matnr eq ls_konh-matnr'  ##NO_TEXT .
        ELSE.
          addtowhere lv_where 'and' 'matnr is initial'  ##NO_TEXT .
        ENDIF.

        LOOP AT lt_stckreqst INTO DATA(ls_stk) WHERE (lv_where) . "#EC CI_NESTED Loop requried with dynamic where
*            ls_claim-REMAINING_PO_QTY  =      .
          ls_claim-remaining_qty     = ls_stk-remaining_qty    .
          ls_claim-ebeln             = ls_stk-ebeln            .
          ls_claim-ebelp             = ls_stk-ebelp            .
          ls_claim-etenr             = ls_stk-etens .
          ls_claim-zpoprc            = ls_stk-zpoprc           .
          ls_claim-zpocur            = ls_stk-zpocur           .
          ls_claim-zppprc            = ls_stk-zppprc           .
          ls_claim-zppcur            = ls_stk-zppcur           .
          ls_claim-zpoprc_lc         = ls_stk-zpoprc_lc        .
          ls_claim-zlcurr            = ls_stk-zlcurr           .
          ls_claim-ind               =  me->gc_stk       .

          APPEND ls_claim TO result .
        ENDLOOP.

*        if ls_konh-f_lifnr is not initial .
*          addtowhere lv_where 'and' 'lifnr eq ls_konh-lifnr' ##NO_TEXT .
*        endif.
        CLEAR: ls_claim-remaining_qty, ls_claim-ebeln , ls_claim-ebelp      ,
              ls_claim-etenr  , ls_claim-zpoprc , ls_claim-zppprc     ,
              ls_claim-zpocur , ls_claim-zppcur , ls_claim-zpoprc_lc  ,
              ls_claim-zlcurr , ls_claim-ind     .

        CLEAR lv_where.

        IF ls_konh-f_kunnr IS NOT INITIAL .
          addtowhere lv_where 'and' ' ( kunnr eq ls_konh-kunnr ) ' ##NO_TEXT . " "or kunnr is initial ) ' .
        ELSE.
          addtowhere lv_where 'and' 'kunnr is initial' ##NO_TEXT .
        ENDIF.
*
        IF ls_konh-f_lifnr IS NOT INITIAL .
          addtowhere lv_where 'and' 'lifnr eq ls_konh-lifnr' ##NO_TEXT .
        ELSE.
          addtowhere lv_where 'and' 'lifnr is initial' ##NO_TEXT .
        ENDIF.

        IF ls_konh-f_matnr IS NOT INITIAL .
          addtowhere lv_where 'and' 'matnr eq ls_konh-matnr'  ##NO_TEXT .
        ELSE.
          addtowhere lv_where 'and' 'matnr is initial'  ##NO_TEXT .
        ENDIF.

        LOOP AT lt_ek INTO DATA(ls_ek) WHERE (lv_where) . "#EC CI_NESTED Loop requried with dynamic where
          ls_claim-remaining_po_qty  =   ( ls_ek-menge - ls_ek-wemng ) .
          ls_claim-ebeln             =  ls_ek-ebeln .
          ls_claim-ebelp             =  ls_ek-ebelp .
          ls_claim-etenr             =  ls_ek-etenr .
          ls_claim-zpoprc            =  ls_ek-netpr .
          ls_claim-zpocur            =  ls_ek-waers .
          ls_claim-ind               =   me->gc_po       .
*          ls_claim-zppprc            = ls_stk-zppprc           .
*          ls_claim-zppcur            = ls_stk-zppcur           .
          APPEND ls_claim TO result .
        ENDLOOP.

        CLEAR ls_claim .
      ENDLOOP.
*      defect 880 . ( additional logic  to hide the non customer specific records where a customer specific record exists .
* Begin of change Defect # 3361
*      DATA(lt_result) = result .
*      LOOP AT lt_result INTO DATA(ls_result) WHERE kunnr IS NOT INITIAL . "#EC CI_STDSEQ
*        IF line_exists( result[ ebeln = ls_result-ebeln ebelp = ls_result-ebelp etenr = ls_result-etenr kunnr = space ] )  .
*          DELETE result WHERE ebeln = ls_result-ebeln
*                         AND ebelp = ls_result-ebelp
*                        AND etenr = ls_result-etenr
*                        AND kunnr = space .              "#EC CI_STDSEQ
*        ENDIF.
*      ENDLOOP.
*End of Change Defect # 3361
    ELSE.
*    no condition records found.
      RAISE EXCEPTION TYPE zcx_o2c_vpp
        EXPORTING
          textid = VALUE #( msgid = zcx_o2c_vpp=>msgid msgno = '063' attr1 = space attr2 = space attr3 = space attr4 = space ).
    ENDIF.
  ENDMETHOD.                                             "#EC CI_VALPAR

  METHOD settle .

    SELECT SINGLE * FROM zo2ctab_serv_vpp INTO @DATA(ls_data) .
    IF sy-subrc NE 0 .
*    Constants not maintained.
      RAISE EXCEPTION TYPE zcx_o2c_vpp
        EXPORTING
          textid = VALUE #( msgid = zcx_o2c_vpp=>msgid msgno = '063' attr1 = 'Constants not maintained.' ##NO_TEXT
            attr2 = space attr3 = space attr4 = space ).
    ENDIF.

*    DATA(ls_head) = VALUE bapisdhd1(  doc_type    = ls_data-auart
*                                      sales_org   = ls_data-vkorg
*                                      distr_chan  = ls_data-vtweg
*                                      division    = ls_data-spart
*                                      ord_reason  = ls_data-augru
*                                      purch_no_c  = me->go_progid->gs_prog_status-ext_vend
*                                      price_date  = sy-datum
**                                      currency  =  and sold to
*                                    ) .
*    DATA(ls_head_x) = VALUE bapisdhd1x( doc_type  = abap_true
*                                    sales_org     = abap_true
*                                    distr_chan    = abap_true
*                                    division      = abap_true
*                                    ord_reason    = abap_true
*                                    purch_no_c    = abap_true
*                                    price_date    = abap_true
*                                  ) .

    SELECT  SINGLE kunnr , adrnr   FROM lfa1
             INTO ( @DATA(lv_kunnr) , @DATA(lv_adrnr) )
             WHERE lifnr = @me->go_progid->gs_prog_status-lifnr .
*    IF sy-subrc EQ 0 .
*      DATA(ls_part) = VALUE bapiparnr( partn_role  = 'AG' partn_numb = lv_kunnr  address = lv_adrnr )  .
*    ENDIF.
    DATA lt_part TYPE TABLE OF bapiparnr .

*    APPEND ls_part TO lt_part .
*
*    DATA: lt_items  TYPE STANDARD TABLE OF bapisditm,
*          lt_itemsx TYPE STANDARD TABLE OF bapisditmx.
*
*    DATA(ls_items) = VALUE bapisditm( material = ls_data-matnr target_qty = 1 ) .
*    DATA(ls_itemsx) = VALUE bapisditmx( material = abap_true target_qty = abap_true ) .
*
*    APPEND ls_items TO lt_items .
*    APPEND ls_itemsx TO lt_itemsx .

    DATA:  lt_return      TYPE TABLE OF bapiret2,
           lv_so          TYPE vbeln,
*           lt_keys        type table of bapicrmsfk,
           lt_conditions  TYPE TABLE OF bapicond,
           lt_conditionsx TYPE TABLE OF bapicondx,
           lv_price       TYPE zclo2c_vpp=>gty_claim-zppprc,
           lv_poprice     TYPE zclo2c_vpp=>gty_claim-zppprc,
           lv_newval      TYPE zclo2c_vpp=>gty_claim-zppprc.
*           lv_curr        type zclo2c_vpp=>gty_claim-zppcur.

    DATA: lv_doc_type        TYPE blart,
          lv_glacc           TYPE hkont,
          lv_bukrs           TYPE bukrs,
          lv_item_no         TYPE posnr_acc,
          lv_waers           TYPE waers,
          ls_documentheader  TYPE bapiache09,
          lv_obj_type        TYPE bapiache09-obj_type,
          lv_obj_key         TYPE bapiache09-obj_key,
          lv_obj_sys         TYPE bapiache09-obj_sys,
          lv_tax_amount      TYPE fwste,
          lv_gl_amount       TYPE wrbtr,
          lv_vendor          TYPE lifnr,
          lv_error           TYPE char1,
          ls_mwdat           TYPE  rtax1u15,
          ls_return          TYPE bapiret2,
          ls_accountgl       TYPE bapiacgl09,
          ls_accountspayable TYPE bapiacap09,
          ls_currencyamount  TYPE bapiaccr09,
          lt_accountgl       TYPE STANDARD TABLE OF bapiacgl09,
          lt_accountspayable TYPE STANDARD TABLE OF bapiacap09,
          lt_accounttax      TYPE STANDARD TABLE OF bapiactx09,
          ls_accounttax      TYPE bapiactx09,
          lt_range_table     TYPE hdb_t_range,
          ls_range_table     TYPE hdb_s_range,
          lt_currencyamount  TYPE STANDARD TABLE OF bapiaccr09.


    TYPES: BEGIN OF lty_items_info,
             lifnr  TYPE lifnr,
             matnr  TYPE matnr,
             waers  TYPE waers,
             amount TYPE zdel_zpoprc,
           END OF lty_items_info.
    DATA :lt_items_info TYPE STANDARD TABLE OF lty_items_info,
          ls_items_info TYPE lty_items_info.


    DATA(lt_claim) = me->dyn_read( ) .
    IF NOT lt_claim IS INITIAL .
* only select the stock that was updated
      SELECT  kunnr ,
              matnr ,
              ebeln ,
              ebelp ,
              etens ,
              zppprc ,
              zppcur
            FROM zmmtab_stckresqt
            INTO TABLE @DATA(lt_stckreqst)
            FOR ALL ENTRIES IN @lt_claim
            WHERE kunnr EQ @lt_claim-kunnr
              AND matnr EQ @lt_claim-matnr
              AND ebeln EQ @lt_claim-ebeln
              AND ebelp EQ @lt_claim-ebelp
              AND etens EQ @lt_claim-etenr
              AND zppprc GT 0
*              and zppcur is not null
              AND receipt_date IS NOT NULL .              "#EC CI_SUBRC
*    only for po's that were not updated with the new price.
      LOOP AT lt_claim INTO DATA(ls_claim) .
*      sum .
        IF ls_claim-ind EQ 'P' .
          IF ls_claim-zpoprc NE ls_claim-vpp_newval .
            lv_poprice = lv_poprice +  ( ls_claim-zpoprc *  ls_claim-remaining_po_qty )   .
            lv_newval = lv_newval +  ( ls_claim-vpp_newval * ls_claim-remaining_po_qty )  .
** Begin of CHange CR377
*            ls_items_info-lifnr  = ls_claim-lifnr.
*            ls_items_info-matnr  = ls_claim-matnr.
*            ls_items_info-amount = ( ls_claim-zpoprc *  ls_claim-remaining_po_qty ) -
*                                   ( ls_claim-vpp_newval * ls_claim-remaining_po_qty ).
********            ls_items_info-amount = ls_items_info-amount / 10.
*            ls_items_info-waers = ls_claim-vpp_newcurr.
*            APPEND ls_items_info TO lt_items_info.
*            CLEAR ls_items_info.
** End of CHange CR377
          ELSE.
            CONTINUE .
          ENDIF.
        ENDIF.
        IF ls_claim-ind EQ 'S' .
          IF line_exists( lt_stckreqst[ kunnr = ls_claim-kunnr
                                        matnr = ls_claim-matnr
                                        ebeln = ls_claim-ebeln
                                        ebelp = ls_claim-ebelp
                                        etens = ls_claim-etenr ] ) .
            lv_poprice = lv_poprice +  ( ls_claim-zpoprc *  ls_claim-remaining_qty )   .
            lv_newval = lv_newval +  ( ls_claim-vpp_newval * ls_claim-remaining_qty )  .

* Begin of CHange CR377
            ls_items_info-lifnr  = ls_claim-lifnr.
            ls_items_info-matnr  = ls_claim-matnr.
            ls_items_info-amount = ( ls_claim-zpoprc *  ls_claim-remaining_qty ) -
                                   ( ls_claim-vpp_newval * ls_claim-remaining_qty ).
*****            ls_items_info-amount = ls_items_info-amount / 10.
            ls_items_info-waers = ls_claim-vpp_newcurr.
            IF ls_items_info-amount GT 0.
              APPEND ls_items_info TO lt_items_info.
            ENDIF.
            CLEAR ls_items_info.
* End of CHange CR377
          ELSE.
            CONTINUE .
          ENDIF.
        ENDIF.
      ENDLOOP.

      lv_price  = ( lv_poprice - lv_newval ) / 10 .
    ENDIF.
* Begin of change CR377 UK18984
*    lt_conditions = value #(  ( itm_number = '000010'  cond_type = 'ZMPR'  cond_value  = lv_price ) ) .
*    lt_conditionsx = value #(  ( itm_number = '000010'  cond_type = 'ZMPR'  cond_value  = abap_true ) ) .
*    call function 'SD_SALESDOCUMENT_CREATE'
*      exporting
*        sales_header_in      = ls_head   " Document Header Data
*        sales_header_inx     = ls_head_x   " Header Data Checkboxes
*        business_object      = 'BUS2096'    " Business Object
*      importing
*        salesdocument_ex     = lv_so   " Number of Generated Document
*      tables
*        return               = lt_return   " Return Messages
*        sales_items_in       = lt_items  " Item Data
*        sales_items_inx      = lt_itemsx   " Item Data Checkboxes
*        sales_partners       = lt_part   " Document Partner
*        sales_conditions_in  = lt_conditions   " Conditions
*        sales_conditions_inx = lt_conditionsx.    " Conditions Checkbox

    DEFINE get_constant_value.
      REFRESH lt_range_table.
      CALL METHOD zcl_exertis_constants=>get_constants_range
        EXPORTING
          im_wricef        = 'EN687'
          im_constant_name = &1
        IMPORTING
          et_t_range       = lt_range_table
        EXCEPTIONS
          no_values_found  = 1
          OTHERS           = 2.
      IF sy-subrc IS NOT INITIAL.
        lv_error = abap_true.
      ELSE.
        CLEAR ls_range_table.
        READ TABLE lt_range_table INTO ls_range_table INDEX 1.
        IF sy-subrc IS INITIAL.
           &2 = ls_range_table-low.
        ENDIF.
      ENDIF.
    END-OF-DEFINITION.

    get_constant_value 'C_DOC_TYPE'  lv_doc_type.
    get_constant_value 'C_GL_ACC'    lv_glacc.
    get_constant_value 'C_COMPCODE'  lv_bukrs.

    IF lv_error IS INITIAL.

      SORT lt_items_info BY lifnr matnr waers.
      lv_item_no = lv_item_no + 1.
      CLEAR lv_price.
      LOOP AT lt_items_info INTO ls_items_info.

        AT END OF waers."matnr.
          SUM.
          lv_vendor = ls_items_info-lifnr. "ls_claim-lifnr.
          lv_waers  = ls_items_info-waers."ls_claim-vpp_newcurr.
          lv_gl_amount = ls_items_info-amount.
          CLEAR: ls_return,
                 lv_error,
                 ls_return,
                 ls_mwdat,
                 lv_tax_amount,
                 ls_accounttax.
**********************************************************************
* Calculate Tax Amount
**********************************************************************
          CALL FUNCTION 'ZFIFM_CALC_TAX_AMOUNT'
            EXPORTING
              im_vendor     = lv_vendor
              im_comp_code  = lv_bukrs
              im_amount     = lv_gl_amount
              im_currency   = lv_waers
            IMPORTING
              ev_error      = lv_error
              es_return     = ls_return
              es_mwdat      = ls_mwdat
              ev_tax_amount = lv_tax_amount
              ev_tax_code   = ls_accounttax-tax_code.
          IF lv_error IS NOT INITIAL.
            ls_return-number = 007.
            ls_return-id     = 'ZFI'.
            ls_return-message_v1 = lv_vendor.
            ls_return-message_v2 = lv_bukrs.
            ls_return-message_v3 = lv_waers.
            ls_return-message_v4 = ls_return-message.

            RAISE EXCEPTION TYPE zcx_o2c_vpp
              EXPORTING
                textid = VALUE #( msgid = ls_return-id
                    msgno = ls_return-number attr1 = ls_return-message_v1 attr2 = ls_return-message_v2
                    attr3 = ls_return-message_v3 attr4 = ls_return-message_v4 ).
          ENDIF.

          ls_documentheader-username    = sy-uname.
          ls_documentheader-comp_code   = lv_bukrs.
          ls_documentheader-doc_date    = sy-datum.
          ls_documentheader-pstng_date  = sy-datum.
          ls_documentheader-doc_type    = lv_doc_type.
          ls_documentheader-ref_doc_no  = me->go_progid->gs_prog_status-progid.   " Defect 3361
          ls_documentheader-header_txt  = me->go_progid->gs_prog_status-ext_vend. " Defect 3361
**********************************************************************
* GL Accounts
**********************************************************************
          lv_item_no = lv_item_no + 1.
          ls_accountgl-itemno_acc  = lv_item_no.
          ls_accountgl-gl_account  = lv_glacc.
          ls_accountgl-comp_code   = lv_bukrs.
          ls_accountgl-tax_code    = ls_accounttax-tax_code.
          ls_accountgl-material    = ls_items_info-matnr.
          ls_accountgl-pstng_date  = sy-datum.  "Posting date
          APPEND ls_accountgl TO lt_accountgl.
          CLEAR ls_accountgl.
**********************************************************************
* Currency Amount
**********************************************************************
          ls_currencyamount-itemno_acc  = lv_item_no.
          ls_currencyamount-currency    = lv_waers.
*          ls_currencyamount-amt_doccur  = ls_items_info-amount." * - 1.  "lv_price  * -1.  " - Defect 3361
          ls_currencyamount-amt_doccur  = ls_items_info-amount * - 1.
          APPEND ls_currencyamount TO lt_currencyamount.
          CLEAR  ls_currencyamount.
* Tax Line Information
**********************************************************************
          lv_item_no = lv_item_no + 1.
          ls_accounttax-itemno_acc = lv_item_no.
          ls_accounttax-gl_account = ls_mwdat-hkont.
          ls_accounttax-tax_rate   = ls_mwdat-msatz. " Defect 3361 EEDK907759 "lv_tax_amount. "ls_items_info-amount.
          ls_accounttax-tax_date   = sy-datum.
          APPEND ls_accounttax TO lt_accounttax.
          CLEAR ls_accounttax.
**********************************************************************
* Tax Line Currency
**********************************************************************
          ls_currencyamount-itemno_acc    = lv_item_no.
          ls_currencyamount-currency      = lv_waers.
*          ls_currencyamount-amt_doccur    = lv_tax_amount. " - Defect 3361
          ls_currencyamount-amt_doccur    = lv_tax_amount * -1.  " + Defect 3361
          ls_currencyamount-amt_base      = ls_items_info-amount.
          APPEND ls_currencyamount TO lt_currencyamount.
          CLEAR ls_currencyamount.
          lv_price = lv_price + ls_items_info-amount + lv_tax_amount.
        ENDAT.

        AT LAST.
**********************************************************************
* Vendor Line
**********************************************************************
          ls_accountspayable-itemno_acc  = 1.
          ls_accountspayable-vendor_no   = lv_vendor."lv_sold_to.
          ls_accountspayable-comp_code   = lv_bukrs.
*            ls_accountspayable-tax_code    = ls_accounttax-tax_code.
          APPEND ls_accountspayable TO lt_accountspayable.
          CLEAR ls_accountspayable.

**********************************************************************
* Currency Amount For Vendor Line
**********************************************************************
          ls_currencyamount-itemno_acc    = 1.
          ls_currencyamount-currency      = lv_waers.
*          ls_currencyamount-amt_doccur    = lv_price * -1.  " - Defect 3361
          ls_currencyamount-amt_doccur    = lv_price.  " + Defect 3361
          IF ls_currencyamount-amt_doccur LE 0.
            DATA(lv_vendor_amount_error) = abap_true.
            EXIT.
          ENDIF.
          APPEND ls_currencyamount TO lt_currencyamount.
          CLEAR ls_currencyamount.
        ENDAT.
      ENDLOOP.
      IF lv_vendor_amount_error IS NOT INITIAL.
**********************************************************************
* Fill Error
**********************************************************************
        CLEAR ls_return.
        ls_return-number = 008.
        ls_return-id     = 'ZFI'.
        ls_return-message_v1 = lv_vendor.

        RAISE EXCEPTION TYPE zcx_o2c_vpp
          EXPORTING
            textid = VALUE #( msgid = ls_return-id
                msgno = ls_return-number attr1 = ls_return-message_v1 attr2 = ls_return-message_v2
                attr3 = ls_return-message_v3 attr4 = ls_return-message_v4 ).
      ELSE. " IF lv_vendor_amount_error IS NOT INITIAL.

        CALL FUNCTION 'BAPI_ACC_DOCUMENT_POST'
          EXPORTING
            documentheader = ls_documentheader
          IMPORTING
            obj_type       = lv_obj_type
            obj_key        = lv_obj_key
            obj_sys        = lv_obj_sys
          TABLES
            accountgl      = lt_accountgl
            accountpayable = lt_accountspayable
            accounttax     = lt_accounttax
            currencyamount = lt_currencyamount
            return         = lt_return.
* End of change CR377 UK18984
        IF line_exists( lt_return[ type = 'E' ] )."  and lv_so is initial .
          ls_return = lt_return[ type = 'E' ] .
          RAISE EXCEPTION TYPE zcx_o2c_vpp
            EXPORTING
              textid = VALUE #( msgid = ls_return-id
                  msgno = ls_return-number attr1 = ls_return-message_v1 attr2 = ls_return-message_v2
                  attr3 = ls_return-message_v3 attr4 = ls_return-message_v4 ).
        ELSE.
          CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
            EXPORTING
              wait = abap_true.  " Using the command `COMMIT AND WAIT`
        ENDIF.
      ENDIF." IF lv_vendor_amount_error IS NOT INITIAL.
    ELSE. "       CALL METHOD zcl_exertis_constants=>get_constants_range
**********************************************************************
* Fill Error
**********************************************************************
      CLEAR ls_return.
      ls_return-number = 009.
      ls_return-id     = 'ZFI'.

      RAISE EXCEPTION TYPE zcx_o2c_vpp
        EXPORTING
          textid = VALUE #( msgid = ls_return-id
              msgno = ls_return-number attr1 = ls_return-message_v1 attr2 = ls_return-message_v2
              attr3 = ls_return-message_v3 attr4 = ls_return-message_v4 ).


    ENDIF. " CALL METHOD zcl_exertis_constants=>get_constants_range

  ENDMETHOD .                                            "#EC CI_VALPAR

  METHOD db_read.
    SELECT * FROM zo2ctab_claimid
      INTO CORRESPONDING FIELDS OF TABLE @result
      WHERE progid EQ @me->go_progid->gs_prog_status-progid . "#EC CI_SUBRC
    IF sy-subrc NE 0 .
*        exp
    ENDIF.
  ENDMETHOD.                                             "#EC CI_VALPAR

ENDCLASS.
