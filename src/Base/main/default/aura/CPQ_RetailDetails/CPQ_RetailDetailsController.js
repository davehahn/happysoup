({
	handleCPQChange : function(component, event, helper)
  {
    helper.groupSaleItems( component );
    component.set('v.hasFees', helper.setHasFees( component ) );
    helper.calculateTotals( component );
	}

})