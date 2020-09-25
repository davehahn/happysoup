({
  doInit: function( component, event, helper )
  {
  },

  handleConfigChange : function(component, event, helper)
  {
    var params = event.getParams();
console.log( JSON.parse( JSON.stringify(params)));
    component.set('v.boat', params.boat);
    component.set('v.trailer', params.trailer);
    component.set('v.motor', params.motor);
    component.set('v.trollingMotor', params.trollingMotor);
    component.set('v.options', params.options);
    component.set('v.motorOptions', params.motorOptions );
    component.set('v.fees', params.fees);
    component.set('v.feeList', params.feeList);
    component.set('v.discounts', params.discounts);
    var ol = [];
    if( params.options )
    {
      for( let optionGroup of params.options )
      {
        for( let opt of optionGroup.values )
        {
          if( (opt.isCheckbox && opt.isSelected) ||
              (!opt.isCheckbox && opt.quantitySelected > 0 ) )
          {
            console.log( opt );
            ol.push( opt );
          }
        }
      }
    }
    component.set('v.optionsList', ol);
    helper.updateTotal( component );

  },

  // handleQuantityChange: function( component, event, helper )
  // {
  //   var quantity = component.get('v.quantity');
  //   if( quantity < 0 || quantity === '' )
  //     component.set('v.quantity', 1);
  //   helper.updateTotal( component );
  // },

  quantityUp: function( component, event, helper )
  {
    var q = component.get('v.quantity');
    component.set('v.quantity', q + 1);
    helper.updateTotal( component );
  },

  quantityDown: function( component, event, helper )
  {
    var q = component.get('v.quantity');
    if( q > 1 )
    {
      component.set('v.quantity', q - 1);
      helper.updateTotal( component );
    }
  }


})