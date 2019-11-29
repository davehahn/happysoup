({
	clonePromo : function(component, event) {
		var action = component.get('c.clonePromo'), la,
				promoId = component.get('v.recordId');
    action.setParams({
      "promoId" : promoId
    });
    la = new LightningApex( this, action );
    component.set('v.status', 'Cloning...');
    la.fire()
    .then(
			function(result) {
				$A.get("e.force:navigateToSObject")
				.setParams({
					"recordId" : result.Id
				})
				.fire();
			}
		);
  }
})