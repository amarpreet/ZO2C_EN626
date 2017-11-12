class zcx_o2c_vpp definition
  public
  inheriting from cx_static_check
  final
  create public .

  public section.

    interfaces if_t100_message .
    "! message id constant used in  this class.
    constants msgid type symsgid value 'ZO2C' .

*    constants:
*      begin of ZCX_O2C_VPP,
*        msgid type symsgid value 'ZO2c',
*        msgno type symsgno value 'msgno',
*        attr1 type scx_attrname value 'attr1',
*        attr2 type scx_attrname value 'attr2',
*        attr3 type scx_attrname value 'attr3',
*        attr4 type scx_attrname value 'attr4',
*      end of ZCX_O2C_VPP.

    methods constructor
      importing
        !textid   like if_t100_message=>t100key optional
        !previous like previous optional .
  protected section.
  private section.
endclass.

class zcx_o2c_vpp implementation.


  method constructor ##ADT_SUPPRESS_GENERATION.
    call method super->constructor
      exporting
        previous = previous.
    clear me->textid.
    if textid is initial.
      if_t100_message~t100key = if_t100_message=>default_textid.
    else.
      if_t100_message~t100key = textid.
    endif.
  endmethod.
endclass.
