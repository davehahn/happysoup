({
	fetchData : function( component )
  {
    var action = component.get('c.fetchData'), la;
    action.setParams({
      recordId: component.get('v.recordId')
    });
    la = new LightningApex( this, action );
    return la.fire();
	}
})