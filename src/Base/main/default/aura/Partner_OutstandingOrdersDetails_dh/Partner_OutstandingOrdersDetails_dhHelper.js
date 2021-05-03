({
	fetchDetails: function( component )
  {
    var action = component.get('c.fetchOrderTypeDetails'), la;
    action.setParams({
      orderType: component.get('v.orderType')
    });
    la = new LightningApex( this, action );
    return la.fire();
  }
})