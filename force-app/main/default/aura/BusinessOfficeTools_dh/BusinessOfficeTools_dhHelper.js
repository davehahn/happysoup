({
	doInit: function( component )
  {
     var action = component.get('c.toolInitialize'), la;
    action.setParams({
      recordId: component.get('v.recordId')
    });
    la = new LightningApex(this, action);
    return la.fire();
	}
})