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
      for( var key in options )
      {
        if( options[key].isSelected == true )
          total += parseFloat( options[key].cost );
        if( options[key].subOptions !== undefined && options[key].subOptions !== null )
        {
          for( var i=0; i<options[key].subOptions.length; i++ )
          {
            if( options[key].subOptions[i].isSelected === true )
              total += options[key].subOptions[i].cost;
          }
        }
      }
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