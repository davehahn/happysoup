({
	fetchRecords : function( component )
  {
    var action = component.get('c.fetchOrderTasks'), la;
    action.setParams({
      erpId: component.get('v.erpId')
    });
    la = new LightningApex( this, action );
    return la.fire();
	}
})