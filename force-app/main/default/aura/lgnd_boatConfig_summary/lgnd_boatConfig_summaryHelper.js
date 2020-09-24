({
	clearVars : function( component )
  {
    component.set('v.total', 0 );
    component.set('v.quantity', 1);
    component.set('v.boat', [] );
    component.set('v.trailer', [] );
    component.set('v.motor', [] );
    component.set('v.options', {} );
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
        total = 0.00,
        sumOptions = function( options )
        {
          return options.reduce( ( optTotal, option ) => {
            if( option.isCheckbox && option.isSelected )
            {
             optTotal += parseFloat( option.cost );
            }

            if( option.isCheckbox != true && parseFloat(option.quantitySelected) > 0 )
            {
             optTotal += (( parseFloat(option.quantitySelected ) - parseFloat(option.quantityStandard)) * parseFloat(option.individualCost) );
            }

            if( option.subOptions !== undefined && option.subOptions !== null )
            {
              optTotal += sumOptions( option.subOptions );
            }
            return optTotal;
          }, 0 );
        }

    if( boat !== null && boat.length !== 0 && boat.cost !== undefined)
      total += boat.cost;

    if( trailer !== null && trailer.length !== 0 && trailer.cost !== undefined)
    {
      total += isNaN( parseFloat( trailer.cost ) ) ? 0 : parseFloat( trailer.cost );
      if( trailer.optionalProducts !== undefined && trailer.optionalProducts !== null )
      {
        total += sumOptions( trailer.optionalProducts );
      }
    }

    if( motor !== undefined && motor !== null && motor.length !== 0 && motor.cost !== undefined && !isNaN(motor.cost))
    {
      total += isNaN( parseFloat( motor.cost ) ) ? 0 : parseFloat( motor.cost );
      if( motor.optionalProducts !== undefined && motor.optionalProducts !== null )
      {
        total += sumOptions( motor.optionalProducts );
      }
    }

    if( trollingMotor !== undefined && trollingMotor !== null && trollingMotor.length !== 0 && trollingMotor.cost !== undefined && !isNaN(trollingMotor.cost))
    {
      total += isNaN( parseFloat( trollingMotor.cost ) ) ? 0 : parseFloat( trollingMotor.cost );
      if( trollingMotor.optionalProducts !== undefined && trollingMotor.optionalProducts !== null )
      {
        total += sumOptions( trollingMotor.optionalProducts );
      }
    }

    if( options !== null && Object.keys( options ).length > 0 )
    {
      options.forEach( optionGroup => {
        total += sumOptions( optionGroup.values );
      });
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