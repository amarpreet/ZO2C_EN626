*"* use this source file for any type of declarations (class
*"* definitions, interfaces or type declarations) you need for
*"* components in the private section


class lcl_progid definition create public.

  public section.
    "! Program ID Status Record in Use
    data gs_prog_status type zclo2c_vpp=>gty_prog_status.

    "! Factory method for Program ID's
    "!
    "! @parameter i_lifnr | Vendors
    "! @parameter i_ekorg | Puchasing Org
    "! @parameter i_ext_vend | External Vendor Ref
    "! @parameter result | Ref to Program ID
    "! @raising zcx_o2c_vpp | Exceptions
    class-methods factory importing i_lifnr       type zclo2c_vpp=>gty_prog_status-lifnr
                                    i_ekorg       type zclo2c_vpp=>gty_prog_status-ekorg
                                    i_ext_vend    type zclo2c_vpp=>gty_prog_status-ext_vend
                          returning
                                    value(result) type ref to lcl_progid
                          raising   zcx_o2c_vpp .
    "! Constructor for Program ID
    "!
    "! @parameter i_progid | Program ID for Open mode onlyh
    "! @raising zcx_o2c_vpp | Exception
    methods constructor importing i_progid type zclo2c_vpp=>gty_prog_status-progid optional
                        raising   zcx_o2c_vpp .
    "! Create a Program ID from the Data provided
    "!
    "! @parameter i_lifnr | Vendor
    "! @parameter i_ekorg | Pruchase org
    "! @parameter i_ext_vend | External Vendor Ref
    "! @parameter result | Ref to Program ID
    "! @raising zcx_o2c_vpp | Exception
    methods create_porgid
      importing
                i_lifnr       type zclo2c_vpp=>gty_prog_status-lifnr
                i_ekorg       type zclo2c_vpp=>gty_prog_status-ekorg
                i_ext_vend    type zclo2c_vpp=>gty_prog_status-ext_vend
      returning
                value(result) type ref to lcl_progid
      raising   zcx_o2c_vpp .
    "! Central Status Management for Program ID
    "!
    "! @parameter i_upload |  Upload completed
    "! @parameter i_calc_stk |  Obsolete
    "! @parameter i_calc_po |  Obsolete
    "! @parameter i_crt_claim | Claim Created
    "! @parameter i_upd_pir_csp |Obsolete
    "! @parameter i_upd_stk | Stock Update complete
    "! @parameter i_upd_po |  PO Update complete
    "! @parameter i_upd_stk_rev | Stock Reversed
    "! @parameter i_upd_po_rev |  PO REversed
    "! @parameter i_settle | Claim Settled
    "! @raising zcx_o2c_vpp | Exceptions
    methods update_status
      importing
                i_upload      type zclo2c_vpp=>gty_prog_status-upload optional
                i_calc_stk    type zclo2c_vpp=>gty_prog_status-calc_stk optional
                i_calc_po     type zclo2c_vpp=>gty_prog_status-calc_po optional
                i_crt_claim   type zclo2c_vpp=>gty_prog_status-crt_claim optional
                i_upd_pir_csp type zclo2c_vpp=>gty_prog_status-upd_pir_csp optional
                i_upd_stk     type zclo2c_vpp=>gty_prog_status-upd_stk optional
                i_upd_po      type zclo2c_vpp=>gty_prog_status-upd_po optional
                i_upd_stk_rev type zclo2c_vpp=>gty_prog_status-upd_stk_rev optional
                i_upd_po_rev  type zclo2c_vpp=>gty_prog_status-upd_po_rev optional
                i_settle      type zclo2c_vpp=>gty_prog_status-settle optional
      raising   zcx_o2c_vpp .
    methods checkclaimref
            importing
                i_lifnr       type zclo2c_vpp=>gty_prog_status-lifnr
                i_ekorg       type zclo2c_vpp=>gty_prog_status-ekorg
                i_ext_vend    type zclo2c_vpp=>gty_prog_status-ext_vend
             raising   zcx_o2c_vpp .
     methods updateclaimref
                importing
                    i_ext_vend    type zclo2c_vpp=>gty_prog_status-ext_vend
                  raising zcx_o2c_vpp .
    "! Fetch list of program id's as per selection.
    "!
    "! @parameter ir_progid | Range of Program ID's
    "! @parameter ir_lifnr | Range of Vendors
    "! @parameter ir_ekorg | Range of Purchasing Org
    "! @parameter ir_ext_vend |  Range of External Vendor ref
    "! @parameter result |  List of Program ID staus records
    "! @raising zcx_o2c_vpp | Exceptions
    class-methods fetch_progid             " read program
      importing
                ir_progid     type zclo2c_vpp=>gty_r_progid
                ir_lifnr      type zclo2c_vpp=>gty_r_lifnr
                ir_ekorg      type zclo2c_vpp=>gty_r_ekorg
                ir_ext_vend   type zclo2c_vpp=>gty_r_ext_vend
      returning
                value(result) type zclo2c_vpp=>tty_prog_status
      raising   zcx_o2c_vpp .

  protected section.
  private section.
    "! Get next number from Program ID number range .
    "!
    "! @parameter result | Program ID number range
    "! @raising zcx_o2c_vpp | Exceptions
    methods get_progid_num
      returning
                value(result) type zclo2c_vpp=>gty_prog_status-progid
      raising   zcx_o2c_vpp .
    "! DB Create for Program ID
    "!
    "! @parameter is_prog_status | Program ID status records
    "! @raising zcx_o2c_vpp | Exceptions
    methods db_create
      importing is_prog_status type zclo2c_vpp=>gty_prog_status
      raising   zcx_o2c_vpp .
    "! DB Modify for Program ID
    "!
    "! @parameter is_prog_status | Program ID Status records
    "! @raising zcx_o2c_vpp |
    methods db_modify
      importing is_prog_status type zclo2c_vpp=>gty_prog_status
      raising   zcx_o2c_vpp .
    "! fetch details of a program ID
    "!
    "! @parameter i_progid | Program ID
    "! @parameter result | Program ID status record
    "! @raising zcx_o2c_vpp |
    methods fetch_progid_single importing i_progid      type zclo2c_vpp=>gty_prog_status-progid
                                returning value(result) type ref to lcl_progid
                                raising   zcx_o2c_vpp .
    "! Enqueue the Program ID is use
    "!
    "! @raising zcx_o2c_vpp | Exceptions
    methods enqueue raising zcx_o2c_vpp.
    "! dequeue the Program ID is use
    "!
    "! @raising zcx_o2c_vpp | Exceptions
    methods dequeue .


endclass.


class lcl_claim definition create public.

  public section.
    data : gt_claim type zclo2c_vpp=>tty_claim .
    data : go_progid type ref to lcl_progid .

    constants : gc_zvpp type c length 4 value 'ZVPP' .
    constants : gc_po type c length 4 value 'P' .
    constants : gc_stk type c length 4 value 'S' .
    "! Constructor for Calims
    "!
    "! @parameter io_progid |
    "! @raising zcx_o2c_vpp |
    methods constructor importing io_progid type ref to lcl_progid
                        raising   zcx_o2c_vpp .
    "! Fetch claims for Program ID in use
    methods fetch_claims returning value(result) type ref to lcl_claim
                         raising   zcx_o2c_vpp .
    "! Freeze the claim so it's no longer dynamic
    class-methods freeze_claim importing it_claims type zclo2c_vpp=>tty_claim
                               raising   zcx_o2c_vpp .
    methods settle raising zcx_o2c_vpp .

  protected section.

  private section.
    methods db_read returning value(result) type  zclo2c_vpp=>tty_claim
                    raising   zcx_o2c_vpp.

    methods dyn_read returning value(result) type zclo2c_vpp=>tty_claim
                     raising   zcx_o2c_vpp .

endclass.
