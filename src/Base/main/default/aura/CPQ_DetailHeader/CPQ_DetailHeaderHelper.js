({
	calcTotal : function( component )
  {
    var cpq = component.get('v.cpq'),
        cpqUtils = component.find('CpqUtils'),
        totals = cpqUtils.calcCpqTotals( cpq );

    component.set('v.preTaxTotal', totals.preTaxTotal );
    component.set('v.total', totals.grandTotal );
  }
})