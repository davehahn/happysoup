({
	doInit : function(component, event, helper)
  {
    var opt = component.get('v.optionItem'),
        amount = 0;
    if( opt !== undefined && opt !== null)
    {
      if( opt.standard != opt.quantitySelected )
      {
        amount = ( opt.quantitySelected * opt.retailPrice );
        amount -= ( opt.standard * opt.retailPrice );
      }
      component.set('v.lineCost', amount);
    }
	}
})