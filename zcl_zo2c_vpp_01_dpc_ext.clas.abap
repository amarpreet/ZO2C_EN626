class zcl_zo2c_vpp_01_dpc_ext definition
  public
  inheriting from zcl_zo2c_vpp_01_dpc
  create public .

  public section.

    methods /iwbep/if_mgw_appl_srv_runtime~changeset_begin
         redefinition .
    methods /iwbep/if_mgw_appl_srv_runtime~changeset_end
         redefinition .
    methods /iwbep/if_mgw_appl_srv_runtime~changeset_process
         redefinition .
    methods /iwbep/if_mgw_appl_srv_runtime~create_stream
         redefinition .
    methods /iwbep/if_mgw_appl_srv_runtime~execute_action
         redefinition .
  protected section.

    methods claimset_create_entity
         redefinition .
    methods claimset_get_entity
         redefinition .
    methods claimset_get_entityset
         redefinition .
    methods claimset_update_entity
         redefinition .
    methods progidset_create_entity
         redefinition .
    methods progidset_get_entity
         redefinition .
    methods progidset_update_entity
         redefinition .
    methods progidset_get_entityset
         redefinition .
    methods progidshset_get_entityset
         redefinition .
    methods claimset_delete_entity
         redefinition .
    methods pourlset_get_entity
         redefinition .
    methods pourlset_get_entityset
         redefinition .
  private section.
    "! get operations for navigations
    methods get_from_navigation
      importing
                io_tech_req_entity    type ref to  /iwbep/if_mgw_req_entity optional
                io_tech_req_entityset type ref to /iwbep/if_mgw_req_entityset optional
      exporting
                er_result             type data
                es_response_context   type /iwbep/if_mgw_appl_srv_runtime=>ty_s_mgw_response_context
      raising   /iwbep/cx_mgw_busi_exception .

    class-methods generate_po_url
      importing
        !iv_ebeln type ebeln
      exporting
        !ev_url   type string .

ENDCLASS.



CLASS ZCL_ZO2C_VPP_01_DPC_EXT IMPLEMENTATION.


  method /iwbep/if_mgw_appl_srv_runtime~changeset_begin.
    "use changeset now

    if lines( it_operation_info ) gt 1 .
      cv_defer_mode = abap_true .
    endif.
    loop at it_operation_info into data(ls_operation_info).
      if ls_operation_info-content_id is not initial or
         ls_operation_info-content_id_ref is not initial.
        cv_defer_mode = abap_true.
      endif.
    endloop.

  endmethod.


  method /iwbep/if_mgw_appl_srv_runtime~changeset_end.
    commit work .
  endmethod.


  method /iwbep/if_mgw_appl_srv_runtime~changeset_process.

    data:
      ls_changeset_request     type /iwbep/if_mgw_appl_types=>ty_s_changeset_request,
      ls_changeset_req_parent  type /iwbep/if_mgw_appl_types=>ty_s_changeset_request,
      lo_create_context        type ref to /iwbep/if_mgw_req_entity_c,
      ls_changeset_response    type /iwbep/if_mgw_appl_types=>ty_s_changeset_response,
      ls_changeset_resp_parent type /iwbep/if_mgw_appl_types=>ty_s_changeset_response,
      lo_tech_request_context  type ref to /iwbep/if_mgw_req_entity_c.
    data ls_claim type zcl_zo2c_vpp_01_mpc_ext=>ts_claim .
    data lt_claim type zcl_zo2c_vpp_01_mpc_ext=>tt_claim .
    types : begin of lty_action,
              entity type string,
              action type string,
            end of lty_action.
    data : ls_action type lty_action .
    data : lt_action type standard table of lty_action .
    data : lv_progid type zcl_zo2c_vpp_01_mpc_ext=>ts_claim-progid .
    data : lo_exp_vpp type ref to zcx_o2c_vpp .

    loop at it_changeset_request into ls_changeset_request.

      lo_create_context ?= ls_changeset_request-request_context.
      clear ls_action.

      ls_action = value #(  entity = lo_create_context->get_entity_type_name( ) action = ls_changeset_request-operation_type ) .
      append ls_action to lt_action.

      case ls_action-entity .
        when zcl_zo2c_vpp_01_mpc_ext=>gc_claim .

          lo_tech_request_context ?= ls_changeset_request-request_context.
          ls_changeset_request-entry_provider->read_entry_data( importing es_data = ls_claim ).
          lv_progid = ls_claim-progid .
          copy_data_to_ref(
              exporting
                is_data = ls_claim
              changing
                cr_data = ls_changeset_response-entity_data ).

          append ls_claim to lt_claim .
          clear ls_claim .
          ls_changeset_response-operation_no = ls_changeset_request-operation_no.
          insert ls_changeset_response into table ct_changeset_response.

        when others .
          super->/iwbep/if_mgw_appl_srv_runtime~changeset_process(
                exporting
                  it_changeset_request         = it_changeset_request
                changing
                  ct_changeset_response        =  ct_changeset_response
              ).
      endcase.
    endloop.

    sort lt_action by entity action  .

    delete adjacent duplicates from lt_action  comparing all fields .

    loop at lt_action into ls_action .
      case ls_action-entity .

        when zcl_zo2c_vpp_01_mpc_ext=>gc_claim .

          case ls_changeset_request-operation_type .
            when 'CE' or 'CD'. " Create entity
              try .

                  new zclo2c_vpp(  i_progid = lv_progid  )->freeze_claims( it_claims =  lt_claim ).

                catch zcx_o2c_vpp into lo_exp_vpp .
                  raise exception type /iwbep/cx_mgw_busi_exception
                    exporting
                      textid            = /iwbep/cx_mgw_busi_exception=>business_error_unlimited
                      message_unlimited = lo_exp_vpp->get_text( ).
              endtry.

            when 'UE' . " update entity
              try .
                  if line_exists( lt_claim[ ind = 'S' ] )  and line_exists( lt_claim[ ind = 'P' ]  )  .
*                   cannot have both stock and PO's is the same payload
                    raise exception type /iwbep/cx_mgw_busi_exception
                      exporting
                        textid            = /iwbep/cx_mgw_busi_exception=>business_error_unlimited
                        message_unlimited = 'Invalid Call' ##NO_TEXT.
                  elseif line_exists( lt_claim[ ind = 'S' ] )  .
                    " stock
                    new zclo2c_vpp(  i_progid = lv_progid  )->update_stk( it_claim  = value #(
                        for ls in lt_claim where (  ind = 'S' ) (  ls  ) ) ) .

                  elseif line_exists( lt_claim[ ind = 'P' ]  ) .
                    " Purchase order
                    new zclo2c_vpp(  i_progid = lv_progid
                        )->update_po( ir_ebeln = value #( for ls in lt_claim where (  ind = 'P' ) "#EC CI_STDSEQ
                        (  sign = 'I' option = 'EQ' low = ls-ebeln  ) ) ) .

                  else.
*                  no data was recieved
                    raise exception type /iwbep/cx_mgw_busi_exception
                      exporting
                        textid            = /iwbep/cx_mgw_busi_exception=>business_error_unlimited
                        message_unlimited = 'Invalid Call' ##NO_TEXT.
                  endif.
                catch zcx_o2c_vpp into lo_exp_vpp .
                  raise exception type /iwbep/cx_mgw_busi_exception
                    exporting
                      textid            = /iwbep/cx_mgw_busi_exception=>business_error_unlimited
                      message_unlimited = lo_exp_vpp->get_text( ).
              endtry.
            when 'DE' . " reverse .
              try .
                  if line_exists( lt_claim[ ind = 'S' ] )  and line_exists( lt_claim[ ind = 'P' ]  )  .
*                   cannot have both stock and PO's is the same payload
                    raise exception type /iwbep/cx_mgw_busi_exception
                      exporting
                        textid            = /iwbep/cx_mgw_busi_exception=>business_error_unlimited
                        message_unlimited = 'Invalid Call' ##NO_TEXT.
*                   exp
                  elseif line_exists( lt_claim[ ind = 'S' ] )  .
                    " stock
                    new zclo2c_vpp(  i_progid = lv_progid  )->update_stk( i_reverse = abap_true it_claim  = value #(
                        for ls in lt_claim where (  ind = 'S' ) (  ls  ) ) ) .

                  elseif line_exists( lt_claim[ ind = 'P' ]  ) .
                    " Purchase order not supported for reversals
                    raise exception type /iwbep/cx_mgw_busi_exception
                      exporting
                        textid            = /iwbep/cx_mgw_busi_exception=>business_error_unlimited
                        message_unlimited = 'Reversal of PO no supported' ##NO_TEXT.
                  else.
*                  no data was recieved
                    raise exception type /iwbep/cx_mgw_busi_exception
                      exporting
                        textid            = /iwbep/cx_mgw_busi_exception=>business_error_unlimited
                        message_unlimited = 'Invalid Call' ##NO_TEXT.
                  endif.
                catch zcx_o2c_vpp into lo_exp_vpp .
                  raise exception type /iwbep/cx_mgw_busi_exception
                    exporting
                      textid            = /iwbep/cx_mgw_busi_exception=>business_error_unlimited
                      message_unlimited = lo_exp_vpp->get_text( ).
              endtry.

            when others .
              super->/iwbep/if_mgw_appl_srv_runtime~changeset_process(
                exporting
                  it_changeset_request         = it_changeset_request
                changing
                  ct_changeset_response        =  ct_changeset_response
              ).
          endcase.
      endcase.
    endloop.

  endmethod.


  method /iwbep/if_mgw_appl_srv_runtime~create_stream.

    data : ls_entity type zcl_zo2c_vpp_01_mpc=>ts_file .
    data(lv_entity_name) = io_tech_request_context->get_entity_type_name( ).
    case lv_entity_name .
      when 'File' .

        data : lv_string type string .
        data : lt_string type string_t .
        data : lv_len type i .
        try .
            cl_abap_conv_in_ce=>create(
               exporting
*                 encoding    = 'UTF-8'
                 endian      = 'B'
*                 ignore_cerr = 'X'
                 replacement = '#'
                 input       = is_media_resource-value  )->read(
                                  importing
                                    data   = lv_string    " Data Object To Be Read
                                    len    = lv_len    " Number of Converted Units
                                ).

            data : lv_index type sy-index .
            data : lt_file type string_t .
            data : ls_file type string .
            data : lv_from type i .
            data : lv_offset type i .

            data(lv_do) = lv_len - 2 .
*           if there is an enter at the end
            if lv_string+lv_do(2) =  cl_abap_char_utilities=>cr_lf .
            else.
              concatenate lv_string  cl_abap_char_utilities=>cr_lf into lv_string.
              lv_do = lv_do + 2 .
            endif.

            do lv_do times.
              lv_index = sy-index .
              if lv_string+lv_index(2) eq cl_abap_char_utilities=>cr_lf .
                lv_offset = lv_index - lv_from .
                ls_file = lv_string+lv_from(lv_offset) .
                append ls_file to lt_file .
                lv_from = lv_index + 2 . " exclude the  next line indicator
              endif.
*              endif .
            enddo.

            data ls_progid type zcl_zo2c_vpp_01_mpc=>ts_progid .
            io_tech_request_context->get_converted_source_keys(
              importing
                es_key_values =  ls_progid   " Source Entity Key Values - converted
            ).
            data : ls_path type filepath .
            data: lt_msg type bal_t_msgr .
            data(lt_request_headers)  = /iwbep/if_mgw_conv_srv_runtime~get_dp_facade( )->get_request_header( ) .
            try .
                data(lo_pricing) = new zclo2c_pricing_upd(
                    im_sd       = cond #( when value #( lt_request_headers[ name = 'ctype' ]-value  optional )  eq 'SD'  then abap_true else abap_false )  ##NO_TEXT
                    im_mm       = cond #( when value #( lt_request_headers[ name = 'ctype' ]-value optional )  eq 'MM'  then abap_true else abap_false )  ##NO_TEXT
                    im_p_ovw    = value #( lt_request_headers[ name = 'ovrflag' ]-value  default space )    ##NO_TEXT
                    im_p_sep    = value #( lt_request_headers[ name = 'delimeter' ]-value optional )  ##NO_TEXT
                    im_p_datef  = value #( lt_request_headers[ name = 'datfrmt' ]-value  default space )  ##NO_TEXT
                    im_p_test   = value #( lt_request_headers[ name = 'tflag' ]-value optional )   ##NO_TEXT
                    im_p_matsrc = value #( lt_request_headers[ name = 'matsrc' ]-value default space )  ##NO_TEXT
                    im_p_fpath  = ls_path
                    im_p_shwlog = value #( lt_request_headers[ name = 'logflag' ]-value optional  )  ##NO_TEXT
                    im_odata    = abap_true
                    im_progid   = ls_progid-progid
                ) .

                lo_pricing->execute(
                  exporting
                    it_file = lt_file
                  importing
                    et_msg  = lt_msg  ).

                data(lo_message) = me->mo_context->get_message_container( ).

                loop at lt_msg into data(ls_msg) .

                  lo_message->add_message(
                     exporting
                      iv_msg_type             = ls_msg-msgty    " Message Type
                      iv_msg_id               = ls_msg-msgid    " Message Class
                      iv_msg_number           = ls_msg-msgno    " Message Number
                      iv_msg_text             = conv #( ls_msg-msg_txt )
                      iv_msg_v1               =  ls_msg-msgv1   " Message Variable
                      iv_msg_v2               =  ls_msg-msgv2   " Message Variable
                      iv_msg_v3               =   ls_msg-msgv3  " Message Variable
                      iv_msg_v4               =   ls_msg-msgv4  " Message Variable
*                      iv_error_category         =     " Error Category
                      iv_is_leading_message     = abap_false
*                      iv_entity_type            =     " Entity type/name
*                      it_key_tab                =     " Entity key as name-value pair
                      iv_add_to_response_header = abap_true    " Flag for adding or not the message to the response header
*                        iv_message_target         =     " Target (reference) (e.g. Property ID) of a message
                        ).

                endloop.

                lo_message->add_message(
                    exporting
                     iv_msg_type             = lo_message->get_worst_message_type( )    " Message Type
                     iv_msg_id               = 'ZO2C'    " Message Class   ##NO_TEXT
                     iv_msg_number           = '080'   " Message Number   ##NO_TEXT
                     iv_is_leading_message     = abap_true
                     iv_add_to_response_header = abap_true    " Flag for adding or not the message to the response header
                  ).
                ls_entity-progid = ls_progid-progid .
                ls_entity-value = is_media_resource-value .
                data : lt_entity type zcl_zo2c_vpp_01_mpc=>tt_file .
                append ls_entity to lt_entity .
                try .
                    if lt_request_headers[ name = 'tflag' ]-value  eq abap_false ##NO_TEXT .
                      new zclo2c_vpp(  ls_progid-progid )->upload_done(
                        exporting
                          i_upd1      = abap_true
                          i_upd2      = abap_false
                      ).
                    endif.
                  catch cx_sy_itab_line_not_found .
                    " in some browsers the UI app does not send back the Tflag when it is not set .
                    " this catch was added to the backend to handle that " 07 april 2017 during SIT
                    new zclo2c_vpp(  ls_progid-progid )->upload_done(
                        exporting
                          i_upd1      = abap_true
                          i_upd2      = abap_false
                      ).
                endtry .

                me->copy_data_to_ref(
                  exporting
                    is_data = ls_entity
                  changing
                    cr_data = er_entity
                ).

              catch cx_sy_itab_line_not_found .
                raise exception type /iwbep/cx_mgw_busi_exception
                  exporting
                    textid            = /iwbep/cx_mgw_busi_exception=>business_error_unlimited
                    message_unlimited = 'Missing Headers' ##NO_TEXT.

              catch zcx_o2c_vpp into data(lo_exp_vpp).
                raise exception type /iwbep/cx_mgw_busi_exception
                  exporting
                    textid            = /iwbep/cx_mgw_busi_exception=>business_error_unlimited
                    message_unlimited = lo_exp_vpp->get_text( ).
              catch zcx_ca_t100_message into data(lo_exp_price).
                raise exception type /iwbep/cx_mgw_busi_exception
                  exporting
                    textid            = /iwbep/cx_mgw_busi_exception=>business_error_unlimited
                    message_unlimited = lo_exp_price->get_text( ).
            endtry.

          catch cx_parameter_invalid_range into data(lo_inv_range).    "
            raise exception type /iwbep/cx_mgw_busi_exception
              exporting
                textid            = /iwbep/cx_mgw_busi_exception=>business_error_unlimited
                message_unlimited = lo_inv_range->get_text( ).
          catch cx_sy_codepage_converter_init into data(lo_conv) .     "
            raise exception type /iwbep/cx_mgw_busi_exception
              exporting
                textid            = /iwbep/cx_mgw_busi_exception=>business_error_unlimited
                message_unlimited = lo_conv->get_text( ).
          catch cx_sy_conversion_codepage into data(lo_codep) .
            raise exception type /iwbep/cx_mgw_busi_exception
              exporting
                textid            = /iwbep/cx_mgw_busi_exception=>business_error_unlimited
                message_unlimited = lo_codep->get_text( ).
          catch cx_parameter_invalid_type into data(lo_invalid).    "
            raise exception type /iwbep/cx_mgw_busi_exception
              exporting
                textid            = /iwbep/cx_mgw_busi_exception=>business_error_unlimited
                message_unlimited = lo_invalid->get_text( ).
        endtry.
      when others .
        super->/iwbep/if_mgw_appl_srv_runtime~create_stream(
              exporting
                iv_entity_name          = iv_entity_name
                iv_entity_set_name      = iv_entity_set_name
                iv_source_name          = iv_source_name
                is_media_resource       = is_media_resource
                it_key_tab              = it_key_tab
                it_navigation_path      = it_navigation_path
                iv_slug                 = iv_slug
                io_tech_request_context = io_tech_request_context
              importing
                er_entity               = er_entity ) .
    endcase.
  endmethod.


  method /iwbep/if_mgw_appl_srv_runtime~execute_action .
    types: begin of lty_param ,
             progid type zcl_zo2c_vpp_01_mpc_ext=>ts_progid-progid,
           end of lty_param .

    data: ls_param type lty_param.

    case iv_action_name.
      when 'SettleClaim'.
        io_tech_request_context->get_converted_parameters(
          importing
            es_parameter_values = ls_param
        ).
        try .
            new zclo2c_vpp( i_progid = ls_param-progid )->settle_claim( ).
          catch zcx_o2c_vpp into data(lo_exp_vpp) .  "
            raise exception type /iwbep/cx_mgw_busi_exception
              exporting
                textid            = /iwbep/cx_mgw_busi_exception=>business_error_unlimited
                message_unlimited = lo_exp_vpp->get_text( ).
        endtry.
      when others .
        super->/iwbep/if_mgw_appl_srv_runtime~execute_action(
          exporting
            iv_action_name               =  iv_action_name    " Obsolete
            it_parameter                 =  it_parameter      " Table of Strings Obsolete
            io_tech_request_context      =  io_tech_request_context
          importing
            er_data                      =   er_data
        ).
    endcase.

  endmethod.


  method claimset_create_entity.

    data: ls_claim type zcl_zo2c_vpp_01_mpc_ext=>ts_claim .

    io_tech_request_context->get_converted_source_keys(
      importing
        es_key_values =   ls_claim  " Source Entity Key Values - converted
    ).

    er_entity = ls_claim  .

  endmethod.


  method claimset_delete_entity.
    data: ls_claim type zcl_zo2c_vpp_01_mpc_ext=>ts_claim .

    io_tech_request_context->get_converted_keys(
      importing
        es_key_values =  ls_claim   " Entity Key Values - converted
    ).

    try .
        data(lo_progid) = new zclo2c_vpp( i_progid = ls_claim-progid  ) .
        data(lt_claims) = value zclo2c_vpp=>tty_claim( for ls in lo_progid->fetch_claims( ) where ( progid = ls_claim-progid and ebeln = ls_claim-ebeln and ebelp = ls_claim-ebelp and etenr = ls_claim-etenr ) ( ls ) ) .

        if line_exists( lt_claims[ ind = 'S' ] )   .
          " stock
          lo_progid->update_stk( i_reverse = abap_true  it_claim  =  lt_claims ) .

*        elseif ls_claim-ind = 'P' .
*          " Purchase order
*          raise exception type /iwbep/cx_mgw_busi_exception
*            exporting
*              textid            = /iwbep/cx_mgw_busi_exception=>business_error_unlimited
*              message_unlimited = 'Invalid Call' ##NO_TEXT.

        else.
*                  no data was recieved / purchase orders
          raise exception type /iwbep/cx_mgw_busi_exception
            exporting
              textid            = /iwbep/cx_mgw_busi_exception=>business_error_unlimited
              message_unlimited = 'Invalid Call' ##NO_TEXT.
        endif.
      catch zcx_o2c_vpp into data(lo_exp_vpp) .
        raise exception type /iwbep/cx_mgw_busi_exception
          exporting
            textid            = /iwbep/cx_mgw_busi_exception=>business_error_unlimited
            message_unlimited = lo_exp_vpp->get_text( ).
    endtry.

  endmethod.


  method claimset_get_entity .
    data : ls_claim type zcl_zo2c_vpp_01_mpc_ext=>ts_claim .
    if io_tech_request_context->get_source_entity_set_name( ) is initial .
*      we don't need this .
      io_tech_request_context->get_converted_keys(
        importing
          es_key_values = ls_claim     " Entity Key Values - converted
      ).

      select single * from zo2ctab_claimid into corresponding fields of ls_claim where
                progid = ls_claim-progid
            and ebeln = ls_claim-ebeln
            and ebelp = ls_claim-ebelp
            and etenr = ls_claim-etenr .
      if  sy-subrc eq 0 .
        er_entity = ls_claim .
      endif.

    else.
      me->get_from_navigation(
        exporting
          io_tech_req_entity    =  io_tech_request_context
        importing
          er_result             = er_entity
      ).

    endif.
  endmethod.


  method claimset_get_entityset .
    if io_tech_request_context->get_source_entity_set_name( ) is initial .
*      we don't need this .
      select * from zo2ctab_claimid into corresponding fields of table et_entityset
          up to 100 rows ."#EC CI_NOWHERE  we don't need this method this only exists to complete the test call for the Odata service
    else.
      me->get_from_navigation(
        exporting
          io_tech_req_entityset    =  io_tech_request_context
        importing
          er_result             = et_entityset
          es_response_context   = es_response_context
      ).
    endif.

  endmethod.


  method claimset_update_entity.

    data: ls_claim type zcl_zo2c_vpp_01_mpc_ext=>ts_claim .

*    io_tech_request_context->get_converted_keys(
*      importing
*        es_key_values =  ls_claim   " Entity Key Values - converted
*    ).

    io_data_provider->read_entry_data(
      importing
        es_data                      =  ls_claim
    ).
*      catch /iwbep/cx_mgw_tech_exception.    "

    try .
        if ls_claim-ind = 'S'   .
          " stock
          new zclo2c_vpp(  i_progid = ls_claim-progid  )->update_stk( it_claim  = value #( ( ls_claim ) ) ) .

        elseif ls_claim-ind = 'P' .
          " Purchase order
          new zclo2c_vpp(  i_progid = ls_claim-progid
              )->update_po( ir_ebeln =  value #( ( sign = 'I' option = 'EQ' low =  ls_claim-ebeln ) ) ) .

        else.
*                  no data was recieved
          raise exception type /iwbep/cx_mgw_busi_exception
            exporting
              textid            = /iwbep/cx_mgw_busi_exception=>business_error_unlimited
              message_unlimited = 'Invalid Call' ##NO_TEXT.
        endif.
      catch zcx_o2c_vpp into data(lo_exp_vpp) .
        raise exception type /iwbep/cx_mgw_busi_exception
          exporting
            textid            = /iwbep/cx_mgw_busi_exception=>business_error_unlimited
            message_unlimited = lo_exp_vpp->get_text( ).
    endtry.
    er_entity = ls_claim  .

  endmethod.


  method generate_po_url.

    constants lc_https     type string value 'https://'.
    constants lc_char      type string value ':'.
    constants lc_odatapath type string value '/sap/bc/gui/sap/its/webgui/?'.
    constants lc_sapclient type string value 'sap-client='.
    constants lc_saplang   type string value '&sap-language='.
    constants lc_sapie     type string value '&sap-ie=Edge'.
    constants lc_tcode     type string value '&~transaction=MMPURPAMEPO&%20P_EBELN='.
    constants lc_action    type string value '&%20~OKCODE=ONLI%27'.
    data lv_url            type string.
    data lv_hostname       type string.
    data lv_port           type string.

    call function 'TH_GET_VIRT_HOST_DATA'
      exporting
        protocol       = 2
        virt_idx       = 0
*       LOCAL          = 1
      importing
        hostname       = lv_hostname
        port           = lv_port
      exceptions
        not_found      = 1
        internal_error = 2
        others         = 3.

    if sy-subrc = 0.
      concatenate lc_https lv_hostname lc_char lv_port lc_odatapath lc_sapclient sy-mandt lc_saplang sy-langu lc_sapie lc_tcode iv_ebeln lc_action into lv_url.
    endif.

    ev_url = lv_url.

  endmethod.


  method get_from_navigation .
    constants: lc_progid type c length 6 value 'ProgId'    ##NO_TEXT,
               lc_claim  type c length 6 value 'Claim'     ##NO_TEXT,
               lc_vendor type c length 6 value 'Vendor'     ##NO_TEXT,
               lc_file   type c length 6 value 'File'      ##NO_TEXT,
               lc_pourl  type c length 6 value 'POUrl'      ##NO_TEXT.

    data  ls_conv_keys type zcl_zo2c_vpp_01_mpc=>ts_progid .
    data  ls_src_keys type zcl_zo2c_vpp_01_mpc=>ts_progid .
    field-symbols <fs_src_key> type  any .
    data : lt_nav_path type /iwbep/t_mgw_tech_navi .
    data : ls_progid type zcl_zo2c_vpp_01_mpc=>ts_progid .
    data : ls_claim type zcl_zo2c_vpp_01_mpc=>ts_claim .
    data : ls_file type zcl_zo2c_vpp_01_mpc=>ts_file .

    if io_tech_req_entity is bound  .
      lt_nav_path = io_tech_req_entity->get_navigation_path( ) .
    elseif io_tech_req_entityset is bound .
      lt_nav_path = io_tech_req_entityset->get_navigation_path( ) .
    else.
      raise exception type /iwbep/cx_mgw_busi_exception
        exporting
          textid            = /iwbep/cx_mgw_busi_exception=>business_error_unlimited
          message_unlimited = 'Invalid Call' ##NO_TEXT.
    endif.

    loop at lt_nav_path into data(ls_nav) .
      if sy-tabix  = 1 .
        case ls_nav-source_entity_type.
          when lc_progid. assign ls_progid to <fs_src_key> .
          when lc_claim.  assign ls_claim to <fs_src_key>  .
          when lc_file .  assign ls_file to <fs_src_key> .
        endcase.

        if io_tech_req_entity is bound  .
          io_tech_req_entity->get_converted_source_keys(
                       importing
                         es_key_values = <fs_src_key>  ).

        elseif io_tech_req_entityset is bound .
          io_tech_req_entityset->get_converted_source_keys(
                               importing
                                 es_key_values = <fs_src_key> ).

        endif.

        case ls_nav-source_entity_type.
          when lc_progid.
            try .
                ls_progid = new zclo2c_vpp( ls_progid-progid )->show_progid( ) .
              catch zcx_o2c_vpp into data(lo_exp).

                raise exception type /iwbep/cx_mgw_busi_exception
                  exporting
                    textid            = /iwbep/cx_mgw_busi_exception=>business_error_unlimited
                    message_unlimited = lo_exp->get_text( ).
            endtry.
          when lc_claim.
*            ?? do we need this . = NO
        endcase.

      endif.

      case ls_nav-source_entity_type .
        when lc_progid .
          case ls_nav-target_entity_type.
            when lc_claim.
              try .
                  data(lt_claim) = new zclo2c_vpp( ls_progid-progid )->fetch_claims( ) .
                  if not lt_claim is initial .
                    select kunnr , name1 from kna1 into table @data(lt_kna1)
                      for all entries in @lt_claim
                      where kunnr eq @lt_claim-kunnr .
                    select lifnr , name1 from kna1 into table @data(lt_lfa1)
                      for all entries in @lt_claim
                      where lifnr eq @lt_claim-lifnr . "#EC CI_NOFIELD
                  endif.

                  loop at lt_claim assigning field-symbol(<lfs_claim>) .
                    <lfs_claim>-lifnrtxt = value #( lt_lfa1[ lifnr = <lfs_claim>-lifnr ]-name1 optional )  .
                    <lfs_claim>-kunnrtxt = value #( lt_kna1[ kunnr = <lfs_claim>-kunnr ]-name1 optional ) .
                  endloop.
                  er_result = lt_claim .

                catch zcx_o2c_vpp into lo_exp .
                  raise exception type /iwbep/cx_mgw_busi_exception
                    exporting
                      textid            = /iwbep/cx_mgw_busi_exception=>business_error_unlimited
                      message_unlimited = lo_exp->get_text( ).
              endtry.
          endcase.
        when lc_claim .
          case ls_nav-target_entity_type.
            when lc_pourl .
              data : ls_pourl type zcl_zo2c_vpp_01_mpc_ext=>ts_pourl .
              move-corresponding ls_claim to ls_pourl .
              me->generate_po_url(
                exporting
                  iv_ebeln = ls_claim-ebeln
                importing
                  ev_url   = ls_pourl-url
              ).
              er_result = ls_pourl .
            when lc_vendor . " No longer called
              data: ls_vendor type zcl_zo2c_vpp_01_mpc_ext=>ts_vendor .

              try.
*                  data(lt_claim) = new zclo2c_vpp( ls_claim-progid )->fetch_claims( ) .
*                  ls_claim = lt_claim[ ebeln = ls_claim-ebeln ebelp = ls_claim-ebelp etenr = ls_claim-etenr ] .
*                  if not ls_claim-lifnr is initial .
*                    select single name1 from lfa1 into @ls_vendor-name1 where lifnr = @ls_claim-lifnr .
*                    if sy-subrc eq 0 .
*                      ls_vendor-lifnr = ls_claim-lifnr .
*                      er_result = ls_vendor .
*                    endif.
*                  endif.
                catch zcx_o2c_vpp into lo_exp .
                  raise exception type /iwbep/cx_mgw_busi_exception
                    exporting
                      textid            = /iwbep/cx_mgw_busi_exception=>business_error_unlimited
                      message_unlimited = lo_exp->get_text( ).

                catch cx_sy_itab_line_not_found .
                  raise exception type /iwbep/cx_mgw_busi_exception
                    exporting
                      textid            = /iwbep/cx_mgw_busi_exception=>business_error_unlimited
                      message_unlimited = 'Invalid Call' ##NO_TEXT.
              endtry.

            when others .
              raise exception type /iwbep/cx_mgw_busi_exception
                exporting
                  textid            = /iwbep/cx_mgw_busi_exception=>business_error_unlimited
                  message_unlimited = 'Invalid Call' ##NO_TEXT.
          endcase.
*               ??? do we need to get a prog id from a claim = no
      endcase.
    endloop.


  endmethod.


  method pourlset_get_entity.

    data : ls_pourl type zcl_zo2c_vpp_01_mpc_ext=>ts_pourl .

    if io_tech_request_context->get_source_entity_set_name( ) is initial .
*      we don't need this .
      io_tech_request_context->get_converted_keys(
          importing
            es_key_values =   ls_pourl  " Entity Key Values - converted
        ).

      er_entity = ls_pourl .

      me->generate_po_url(
        exporting
          iv_ebeln = ls_pourl-ebeln
        importing
          ev_url   = er_entity-url
      ).

    else.
      me->get_from_navigation(
        exporting
          io_tech_req_entity    =  io_tech_request_context
        importing
          er_result             = er_entity
      ).

    endif.




  endmethod.


  method pourlset_get_entityset.
    if io_tech_request_context->get_source_entity_set_name( ) is initial .
*      we don't need this .
    else.
      me->get_from_navigation(
        exporting
          io_tech_req_entityset    =  io_tech_request_context
        importing
          er_result             = et_entityset
          es_response_context   = es_response_context
      ).
    endif.

  endmethod.


  method progidset_create_entity.
    data : ls_entity type zcl_zo2c_vpp_01_mpc_ext=>ts_progid .

    if io_data_provider is bound .
      io_data_provider->read_entry_data( importing es_data = ls_entity ).
      try .

          data(lo_progid) = new zclo2c_vpp(  ) .

          er_entity =  lo_progid->create_progid(
            exporting
              i_lifnr     = ls_entity-lifnr
              i_ekorg     = ls_entity-ekorg
              i_ext_vend  = ls_entity-ext_vend
          ).

        catch zcx_o2c_vpp into data(lo_exp).
          raise exception type /iwbep/cx_mgw_busi_exception
            exporting
              textid            = /iwbep/cx_mgw_busi_exception=>business_error_unlimited
              message_unlimited = lo_exp->get_text( ).
      endtry.

    endif.
  endmethod.


  method progidset_get_entity.

    data  ls_conv_keys type zcl_zo2c_vpp_01_mpc=>ts_progid .
    io_tech_request_context->get_converted_keys(
        importing
         es_key_values =   ls_conv_keys  " Entity Key Values - converted
    ).
    try .
        er_entity = new zclo2c_vpp( i_progid = ls_conv_keys-progid )->show_progid( ) .

      catch zcx_o2c_vpp into data(lo_exp).
        raise exception type /iwbep/cx_mgw_busi_exception
          exporting
            textid            = /iwbep/cx_mgw_busi_exception=>business_error_unlimited
            message_unlimited = lo_exp->get_text( ).

    endtry.

  endmethod.


  method progidset_get_entityset.
    data : lv_where type string,
           lv_sort  type string.
    if io_tech_request_context is bound.

      data(lo_filter) = io_tech_request_context->get_filter( ) .
      if lo_filter is bound .
        data(lt_filter) = lo_filter->get_filter_select_options( ) .
        data(lv_filter_string) = lo_filter->get_filter_string( ) .
        data : lr_progid   type zclo2c_vpp=>gty_r_progid,
               lr_lifnr    type zclo2c_vpp=>gty_r_lifnr,
               lr_ekorg    type zclo2c_vpp=>gty_r_ekorg,
               lr_ext_vend type zclo2c_vpp=>gty_r_ext_vend.

        if lv_filter_string is not initial and lt_filter is initial .
*         EXCEPTION
          raise exception type /iwbep/cx_mgw_busi_exception
            exporting
              textid            = /iwbep/cx_mgw_busi_exception=>business_error_unlimited
              message_unlimited = 'Invalid Call'.
        else.

          loop at lt_filter into data(ls_filter).
            case ls_filter-property .
              when 'PROGID' .
                lo_filter->convert_select_option(
                 exporting
                   is_select_option =  ls_filter   " Key name
                 importing
                   et_select_option = lr_progid    " Ranges table
               ).
              when  'EXT_VEND' .
                lo_filter->convert_select_option(
                 exporting
                   is_select_option =  ls_filter   " Key name
                 importing
                   et_select_option = lr_ext_vend    " Ranges table
               ).
              when  'LIFNR' .
                lo_filter->convert_select_option(
                  exporting
                    is_select_option =  ls_filter   " Key name
                  importing
                    et_select_option = lr_lifnr    " Ranges table
                ).
              when 'EKORG' .
                lo_filter->convert_select_option(
                  exporting
                    is_select_option =  ls_filter   " Key name
                  importing
                    et_select_option = lr_ekorg    " Ranges table
                ).
            endcase.
          endloop.
        endif.
      endif.

      try .
          et_entityset = zclo2c_vpp=>fetch_progid(
                           ir_progid   =  lr_progid
                           ir_lifnr    =  lr_lifnr
                           ir_ekorg    =  lr_ekorg
                           ir_ext_vend =  lr_ext_vend
                       ) .

          data : lt_sortorder type abap_sortorder_tab .

          if it_order is not initial .
            loop at it_order assigning field-symbol(<lf_order>) .
              append initial line to lt_sortorder assigning field-symbol(<lf_sortorder>) .
              <lf_sortorder>-name = <lf_order>-property.

              if <lf_order>-property eq 'ExtVend' .
                <lf_sortorder>-astext = abap_true .
              endif.
              if <lf_order>-order = `desc`.
                <lf_sortorder>-descending = abap_true.
              endif.
            endloop.

            sort et_entityset by (lt_sortorder) .
          endif .
        catch zcx_o2c_vpp into data(lo_exp).
          raise exception type /iwbep/cx_mgw_busi_exception
            exporting
              message_unlimited = lo_exp->get_text( ).
      endtry.
    endif.

  endmethod.


  method progidset_update_entity.
    " only used to update the vendor claim ref before the settle step
    data : ls_progid type zcl_zo2c_vpp_01_mpc_ext=>ts_progid .

    io_data_provider->read_entry_data(
      importing
        es_data                      = ls_progid
    ).
    try .
        new zclo2c_vpp( ls_progid-progid )->updateclaimref( ls_progid-ext_vend  ).
      catch zcx_o2c_vpp into data(lo_exp).    "
        raise exception type /iwbep/cx_mgw_busi_exception
          exporting
            textid            = /iwbep/cx_mgw_busi_exception=>business_error_unlimited
            message_unlimited = lo_exp->get_text( ).
    endtry.

  endmethod.


  method progidshset_get_entityset.

    call method super->progidshset_get_entityset
      exporting
        iv_entity_name           = iv_entity_name
        iv_entity_set_name       = iv_entity_set_name
        iv_source_name           = iv_source_name
        it_filter_select_options = it_filter_select_options
        is_paging                = is_paging
        it_key_tab               = it_key_tab
        it_navigation_path       = it_navigation_path
        it_order                 = it_order
        iv_filter_string         = iv_filter_string
        iv_search_string         = iv_search_string
        io_tech_request_context  = io_tech_request_context
      importing
        et_entityset             = et_entityset
        es_response_context      = es_response_context.


    data : lt_sortorder type abap_sortorder_tab .

    if it_order is not initial .
      loop at it_order assigning field-symbol(<lf_order>) .

        append initial line to lt_sortorder assigning field-symbol(<lf_sortorder>) .
        <lf_sortorder>-name = <lf_order>-property.


        if <lf_order>-property eq 'ExtVend' .
          <lf_sortorder>-name = 'EXT_VEND'.
          <lf_sortorder>-astext = abap_true .
        endif.
        if <lf_order>-order = `desc`.
          <lf_sortorder>-descending = abap_true.
        endif.
      endloop.

      sort et_entityset by (lt_sortorder) .
    endif .

  endmethod.
ENDCLASS.
