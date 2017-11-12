class ZCL_ZO2C_VPP_01_MPC_EXT definition
  public
  inheriting from ZCL_ZO2C_VPP_01_MPC
  create public .

public section.

  methods DEFINE
    redefinition .
protected section.
private section.
ENDCLASS.



CLASS ZCL_ZO2C_VPP_01_MPC_EXT IMPLEMENTATION.


  method define.

    super->define( ).
    data: lo_entity   type ref to  /iwbep/if_mgw_odata_entity_typ,
          lo_property type ref to  /iwbep/if_mgw_odata_property.

    lo_entity = model->get_entity_type( iv_entity_name = 'File' )."Entity Name

    if lo_entity is bound.

      lo_property = lo_entity->get_property( iv_property_name = 'value' )."Key Value(SLUG)
      lo_property->set_as_content_type( ).

    endif.

  endmethod.
ENDCLASS.
