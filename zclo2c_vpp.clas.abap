class zclo2c_vpp definition
  public
  final
  create public .

  public section.
    types :
      "! type for program ID status
      gty_prog_status type zo2cstr_vpp_progid,
      "! table type for program ID status
      tty_prog_status type table of gty_prog_status with default key,
      "! type for Claim (frozen )
      gty_claim       type zo2cstr_vpp_calim,
      "! table type for Claims
      tty_claim       type  table of gty_claim with default key.

    types :
      "! type of range for program id
      gty_r_progid   type range of   gty_prog_status-progid,
      "! type of range for purchase org.
      gty_r_ekorg    type range of  gty_prog_status-ekorg,
      "! type of range for vendor
      gty_r_lifnr    type range of  gty_prog_status-lifnr,
      "! type of range for vendor ref
      gty_r_ext_vend type range of gty_prog_status-ext_vend,
      "! type of range for purchase order .
      gty_r_ebeln    type range of ebeln.

    "! Constructor for the main class for VPP
    "!
    "! @parameter i_progid |  Program ID, use to open and existing program ID
    "! @raising zcx_o2c_vpp |  Exception
    methods constructor importing i_progid type gty_prog_status-progid optional
                        raising   zcx_o2c_vpp .
    "! Create Program ID
    "!
    "! @parameter i_lifnr |  Vendor
    "! @parameter i_ekorg |  Purchase Organization
    "! @parameter i_ext_vend | External vendor Reference
    "! @parameter result |  Status record of the Program ID created
    "! @raising zcx_o2c_vpp | Exception
    methods create_progid
      importing
                i_lifnr       type zclo2c_vpp=>gty_prog_status-lifnr
                i_ekorg       type zclo2c_vpp=>gty_prog_status-ekorg
                i_ext_vend    type zclo2c_vpp=>gty_prog_status-ext_vend
      returning
                value(result) type zclo2c_vpp=>gty_prog_status
      raising   zcx_o2c_vpp.
    "! Fetch the Claims for the Program ID in use / status dependent
    "!
    "! @parameter result |
    "! @raising zcx_o2c_vpp |
    methods fetch_claims  returning value(result) type zclo2c_vpp=>tty_claim
                          raising   zcx_o2c_vpp .
    "! freeze claims for the program ID in use / Updates status
    "!
    "! @parameter it_claims |
    "! @raising zcx_o2c_vpp |
    methods freeze_claims importing it_claims type tty_claim
                          raising   zcx_o2c_vpp .
    "! Fetch the details of the program ID / Used to return to a program ID .
    "!
    "! @parameter result |
    methods show_progid returning value(result) type zclo2c_vpp=>gty_prog_status .
    "! Fetch a list of program ID for the initial step.
    "!
    "! @parameter ir_progid | Range of Program ID's
    "! @parameter ir_lifnr | Range of Vendors
    "! @parameter ir_ekorg | Ranse of Purchase organizations
    "! @parameter ir_ext_vend | Range of External vendor reference
    "! @parameter result | list of program ID status records
    "! @raising zcx_o2c_vpp | Exceptions
    class-methods fetch_progid
      importing
                ir_progid     type zclo2c_vpp=>gty_r_progid
                ir_lifnr      type zclo2c_vpp=>gty_r_lifnr
                ir_ekorg      type zclo2c_vpp=>gty_r_ekorg
                ir_ext_vend   type zclo2c_vpp=>gty_r_ext_vend
      returning
                value(result) type zclo2c_vpp=>tty_prog_status
      raising   zcx_o2c_vpp .
    "! Status update for Upload done step.
    "!
    "! @parameter i_upd1 | Update Level 1
    "! @parameter i_upd2 | Update Level 2
    "! @raising zcx_o2c_vpp | Exceptions
    methods upload_done importing i_upd1 type flag
                                  i_upd2 type flag
                        raising   zcx_o2c_vpp .

    "! Submit an update to the purchase orders
    "!
    "! @parameter ir_ebeln | " list of Purchase orders that were approved
    "! @raising zcx_o2c_vpp | Exceptions
    methods update_po importing ir_ebeln type gty_r_ebeln
                      raising   zcx_o2c_vpp .
    "! update Stock data
    "!
    "! @parameter it_claim | list of claims that are approved
    "! @parameter i_reverse | flag to indicate that a reversal is being performed
    "! @raising zcx_o2c_vpp | Exceptions
    methods update_stk importing it_claim  type zclo2c_vpp=>tty_claim
                                 i_reverse type flag optional
                       raising   zcx_o2c_vpp.
    "! settle the claim - creates a Sale order for the claim .
    "!
    "! @parameter i_test | called in test mode .
    "! @raising zcx_o2c_vpp |
    methods settle_claim importing i_test type flag optional
                         raising   zcx_o2c_vpp .
    "! used the update the vendor claim ref after a program id has been created.
    "!
    "! @parameter i_ext_vend | the new vendor claim ref
    "! @raising zcx_o2c_vpp | exections
    methods updateclaimref
      importing
                i_ext_vend type zclo2c_vpp=>gty_prog_status-ext_vend
      raising   zcx_o2c_vpp .

  protected section.


  private section.

    "! internal ref to program ID
    data go_progid type ref to lcl_progid .
    "! interal Ref to Calim ID
    data go_claim type ref to lcl_claim .

endclass.

class zclo2c_vpp implementation.

  method constructor .
    if i_progid is supplied  .
*    this is for a read operation .
*    use create progrid to create a new one
      me->go_progid = new #( i_progid ) .
    endif.
  endmethod.

  method create_progid.
    if me->go_progid is not bound .
*    must be called after the constructor
      me->go_progid = lcl_progid=>factory(
                  i_lifnr     = i_lifnr
                  i_ekorg     = i_ekorg
                  i_ext_vend  =  i_ext_vend
              ).
      result = go_progid->gs_prog_status .
    else.
*      invalid call .
      raise exception type zcx_o2c_vpp
        exporting
          textid = value #( msgid = zcx_o2c_vpp=>msgid msgno = '062' attr1 = 'Invalid call'  ##NO_TEXT
          attr2 = space attr3 = space attr4 = space ).
    endif.
  endmethod.


  method fetch_claims.
    me->go_claim = new #( me->go_progid ) .
    result = me->go_claim->fetch_claims( )->gt_claim.
  endmethod.                                             "#EC CI_VALPAR


  method fetch_progid.
    " get a list of program ids used for the open existing program
    result = lcl_progid=>fetch_progid(
      exporting
        ir_progid   =  ir_progid
        ir_lifnr    =  ir_lifnr
        ir_ekorg    =  ir_ekorg
        ir_ext_vend =  ir_ext_vend
    ).
  endmethod.                                             "#EC CI_VALPAR


  method freeze_claims.
    lcl_claim=>freeze_claim( it_claims = it_claims ).
*    if not exceptions are raised updated the status
    me->go_progid->update_status( i_crt_claim   = abap_true ) .
* the following logic was added to avoid a situation where no stock or po's are available in the
* claim, this lets the user proceed to the claim settlement by setting the corresponding statuses
* automatically during the creation of the claim
    if not line_exists(  it_claims[ ind = 'P' ] ) . " added on 26 march
      me->go_progid->update_status( i_upd_po  =  abap_true   ).
    endif.
    if not line_exists(  it_claims[ ind = 'S' ] ) .
      me->go_progid->update_status( i_upd_stk  =  abap_true   ).
    endif.

  endmethod.


  method show_progid .
    if go_progid is bound .
      result = go_progid->gs_prog_status .
    endif.
  endmethod.


  method update_po.
    data : lr_ebeln type range of ekko-ebeln.
    data : lv_kiprs type rmeind1-kiprs .
    data : lv_jobnr type tbtcjob-jobcount .
    data : lv_jobname type tbtcjob-jobname value 'VPP_PO_UPDATES' .
    data : lv_rel type char1 .
    data: ls_head      type bapimepoheader .
    data: ls_head_ex   type bapieikp  .
    data:  lt_return  type bapirettab .
    data:  lt_item    type table of bapimepoitem .
    data:  lt_itemx    type  table of bapimepoitemx .


    select ebeln ,  ebelp
        from ekpo
        into table @data(lt_ekpo)
        where ebeln in @lr_ebeln .                        "#EC CI_SUBRC

    loop at ir_ebeln into data(ls_ebeln) .
      clear : ls_head , ls_head_ex , lt_return , lt_item , lt_itemx .
      lt_item = value #(  for ls in lt_ekpo where ( ebeln = ls_ebeln-low )
                         ( po_item = ls-ebelp pricedate = '3' price_date = sy-datum )   ) .

      lt_itemx = value #(  for ls in lt_ekpo where ( ebeln = ls_ebeln-low )
                         ( po_item = ls-ebelp pricedate = abap_true price_date = abap_true )   ) .
*  this change was added into to change the price date on all the PO's being updated to current date

      call function 'BAPI_PO_CHANGE'
        exporting
          purchaseorder     = ls_ebeln-low   " Purchasing Document Number
        importing
          expheader         = ls_head       " Header Data
          exppoexpimpheader = ls_head_ex    " Export Trade: Header Data
        tables
          return            = lt_return    " Return Parameter
          poitem            = lt_item      " Item Data
          poitemx           = lt_itemx.     " Item Data (Change Parameter)
      if line_exists( lt_return[ type = 'E' ] ) .
*      error .
        raise exception type zcx_o2c_vpp
          exporting
            textid = value #( msgid = zcx_o2c_vpp=>msgid msgno = '062' attr1 = 'VPP Update PO'  ##NO_TEXT
            attr2 = space attr3 = space attr4 = space ).
      else.
        call function 'BAPI_TRANSACTION_COMMIT'
          exporting
            wait = abap_true.  " Using the command `COMMIT AND WAIT`
      endif.
    endloop.

    if me->go_progid is bound .
      lv_jobname = 'VPP_PO_UPDATES_' && me->go_progid->gs_prog_status-progid .
    endif.
    lr_ebeln = ir_ebeln .
    lv_kiprs =  'B'  .
    call function 'JOB_OPEN'
      exporting
        jobname          = lv_jobname " Job Name
      importing
        jobcount         = lv_jobnr   " ID Number of Background Job
      exceptions
        cant_create_job  = 1
        invalid_job_data = 2
        jobname_missing  = 3
        others           = 4.
    if sy-subrc <> 0.
      message id sy-msgid type sy-msgty number sy-msgno
                 with sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    endif.
    submit rmebein4                                     "#EC CI_SUBMIT.
*            with s_adat_h  eq sy-datum
*            with s_adat_l eq sy-datum " removed on 05 december 2016
            with s_match eq abap_false
            with s_posout eq abap_false
            with s_reorga eq 'X'
            with s_reorgb eq 'X'
            with s_reorgo eq abap_false
            with s_sebeln eq 'X'
            with s_sebelo eq abap_false
            with s_skbelb eq abap_false
            with s_skbeln eq abap_false
            with s_sortli eq abap_false
            and return
            via job lv_jobname number lv_jobnr .
    if sy-subrc eq 0 .

      submit rmebein2                                   "#EC CI_SUBMIT.
              with p_alv eq abap_true
              with p_list eq abap_false
*              with s_bdat_h eq sy-datum
*              with s_bdat_l eq sy-datum
              with s_ebeln in lr_ebeln
*              with s_kbeln
*              with s_kdat_h ...
*              with s_kdat_l ...
              with s_kiprs eq lv_kiprs
*              with s_kiprst ...
*              with s_mess ...
*              with s_onlydi eq abap_true
*              with s_pdat_h ...
*              with s_pdat_l ...
*              with s_reorga ...
*              with s_reorgb ...
*              with s_sebeln ...
*              with s_selscr ...
              with s_skbeln eq abap_false
              and return
              via job lv_jobname number lv_jobnr .

      if sy-subrc eq 0 .
        call function 'JOB_CLOSE'
          exporting
            jobcount             = lv_jobnr   " Job number
            jobname              = lv_jobname  " Job Name
            strtimmed            = 'X'
          importing
            job_was_released     = lv_rel  " = 'X', if Job Was Released
*          changing
*           ret                  =     " Special Additional Error Code
          exceptions
            cant_start_immediate = 1
            invalid_startdate    = 2
            jobname_missing      = 3
            job_close_failed     = 4
            job_nosteps          = 5
            job_notex            = 6
            lock_failed          = 7
            invalid_target       = 8
            others               = 9.
        if sy-subrc <> 0.
          raise exception type zcx_o2c_vpp
            exporting
              textid = value #( msgid = sy-msgid msgno = sy-msgno attr1 = sy-msgv1 attr2 = sy-msgv2 attr3 = sy-msgv3 attr4 = sy-msgv4 ).
        else .
          me->go_progid->update_status( i_upd_po  =  abap_true   ).
        endif.
      else .
        raise exception type zcx_o2c_vpp
          exporting
            textid = value #( msgid = zcx_o2c_vpp=>msgid msgno = '062' attr1 = 'VPP Update PO'  ##NO_TEXT
            attr2 = space attr3 = space attr4 = space ).
      endif.
    else .
      raise exception type zcx_o2c_vpp
        exporting
          textid = value #( msgid = zcx_o2c_vpp=>msgid msgno = '062' attr1 = 'VPP Update PO'  ##NO_TEXT
          attr2 = space attr3 = space attr4 = space ).
    endif.
  endmethod.


  method update_stk .
    data: lt_stk type table of zo2ctab_claimid .
    data : ls_stk type zo2ctab_claimid .

    lt_stk = value #( for ls in it_claim
                       ( corresponding #( ls ) )  ) .

    select *
        from zmmtab_stckresqt
        into table @data(lt_data)
    for all entries in @lt_stk
    where ebeln = @lt_stk-ebeln
      and ebelp = @lt_stk-ebelp
      and etens = @lt_stk-etenr
      and matnr = @lt_stk-matnr
      and kunnr = @lt_stk-kunnr.
    if sy-subrc eq 0 .
      loop at lt_data into data(ls_data) .
        try .
            if i_reverse is initial .
              clear ls_stk .
              ls_stk = lt_stk[ ebeln = ls_data-ebeln  ebelp = ls_data-ebelp etenr = ls_data-etens ] .
            else.
              clear ls_stk .
              ls_stk = lt_stk[ ebeln = ls_data-ebeln  ebelp = ls_data-ebelp etenr = ls_data-etens zppprc = ls_stk-zppprc  zppcur = ls_stk-zppcur ] . " check what to clear
              clear ls_stk-vpp_newval .
              clear ls_stk-vpp_newcurr .
*              set the vendor protected price to blank during reverse .
            endif.

            update zmmtab_stckresqt
                set zppprc = @ls_stk-vpp_newval ,
                    zppcur = @ls_stk-vpp_newcurr
                where ebeln = @ls_data-ebeln
                 and  ebelp = @ls_data-ebelp
                 and  etens = @ls_data-etens
                 and  matnr = @ls_data-matnr
                 and  kunnr = @ls_data-kunnr  . "#EC CI_IMUD_NESTED selective conditional update
            if sy-subrc ne 0 .
              raise exception type zcx_o2c_vpp
                exporting
                  textid = value #( msgid = zcx_o2c_vpp=>msgid msgno = '062' attr1 = 'VPP Update Stock DB'  ##NO_TEXT
                  attr2 = space attr3 = space attr4 = space ).
            else.
              continue. " move to next record
            endif.
          catch cx_sy_itab_line_not_found .
            raise exception type zcx_o2c_vpp
              exporting
                textid = value #( msgid = zcx_o2c_vpp=>msgid msgno = '062' attr1 = 'VPP Update Stock'  ##NO_TEXT
                attr2 = space attr3 = space attr4 = space ).
        endtry.
      endloop.
      if i_reverse is initial .
        me->go_progid->update_status( i_upd_stk  =  abap_true   ).
      else.
        me->go_progid->update_status( i_upd_stk_rev  =  abap_true   ).
      endif.
    endif.

  endmethod.



  method upload_done .
    if not i_upd1 is  initial or not  i_upd2 is initial .
      me->go_progid->update_status(
        exporting
          i_upload      = abap_true
*          i_upd_pir_csp = i_upd2
      ).
    endif.
  endmethod.

  method settle_claim.
    if me->go_claim is not bound .
      me->go_claim = new #( me->go_progid ) .
    endif.
    me->go_claim->settle( ).
    me->go_progid->update_status( i_settle = abap_true ) .
  endmethod.

  method updateclaimref.
    if me->go_progid is not initial .
      me->go_progid->updateclaimref( i_ext_vend = i_ext_vend ).
    endif.
  endmethod.

endclass.
