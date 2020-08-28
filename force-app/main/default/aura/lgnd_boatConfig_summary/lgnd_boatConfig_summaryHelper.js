({
	clearVars : function( component )
  {
    component.set('v.total', 0 );
    component.set('v.quantity', 1);
    component.set('v.boat', [] );
    component.set('v.trailer', [] );
    component.set('v.motor', [] );
    component.set('v.options', {} );
    //component.set('v.optionsList', [] );
    component.set('v.fees', {} );
    component.set('v.feeList', [] );
    component.set('v.discounts', []);
	},

  updateTotal: function(component)
  {
    var quantity = component.get('v.quantity'),
        boat = component.get('v.boat'),
        trailer = component.get('v.trailer'),
        motor = component.get('v.motor'),
        trollingMotor = component.get('v.trollingMotor'),
        //optionList = component.get('v.optionsList'),
        options = component.get('v.options'),
        motorOptions = component.get('v.motorOptions'),
        feeList = component.get('v.feeList'),
        discounts = component.get('v.discounts'),
        total = 0.00;

    if( boat !== null && boat.length !== 0 && boat.cost !== undefined)
      total += boat.cost;

    if( trailer !== null && trailer.length !== 0 && trailer.cost !== undefined)
      total += isNaN( parseFloat( trailer.cost ) ) ? 0 : parseFloat( trailer.cost );

    if( motor !== null && motor.length !== 0 && motor.cost !== undefined && !isNaN(motor.cost))
      total += motor.cost;

    if( trollingMotor !== null && trollingMotor.length !== 0 && trollingMotor.cost !== undefined && !isNaN(trollingMotor.cost))
      total += trollingMotor.cost;

    if( options !== null && Object.keys( options ).length > 0 )
    {
      options.forEach( optionGroup => {
        optionGroup.values.forEach( option => {
          if( option.isCheckbox && option.isSelected )
          {
            total += parseFloat( option.cost );
          }

          if( option.isCheckbox != true && parseFloat(option.quantitySelected) > 0 )
          {
            total += ( parseFloat(option.quantitySelected) * parseFloat(option.cost) );
          }

          if( option.subOptions !== undefined && option.subOptions !== null )
          {
            for( var i=0; i<option.subOptions.length; i++ )
            {
              if( option.subOptions[i].isCheckbox &&
                  option.subOptions[i].isSelected === true )
              {
                total += option.subOptions[i].cost;
              }
              if( !option.subOptions[i].isCheckbox &&
                  option.subOptions[i].quantitySelected > 0 )
                {
                  total += option.subOptions[i].cost * option.subOptions[i].quantitySelected;
                }
            }
          }
        })
      })
    }
    if( motorOptions !== null && motorOptions.length > 0 )
    {
      for( let mOpt of motorOptions )
      {
        if( mOpt.isSelected )
          total += parseFloat( mOpt.cost );
      }
    }
    if( feeList !== null && feeList.length !== 0 )
    {
      for( var i=0; i<feeList.length; i++ )
      {
        total += parseFloat(feeList[i].cost);
      }
    }

    if( discounts !== null && discounts.length !== 0 )
    {
      for( var i=0; i<discounts.length; i++ )
      {
        total += parseFloat(discounts[i].amount);
      }
    }
    component.set('v.total', parseFloat( (total * quantity) ) );
  }
})