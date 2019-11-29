({
	getClaimDetails : function(component, event) {
		var self = this,
				action = component.get('c.getClaimDetails'), la,
				recordId = component.get('v.recordId');
		action.setParams({
			"caseId" : recordId
		});
        la = new LightningApex( this, action );
        return la.fire()
        .then(
            $A.getCallback(
            	function(result) {
            		component.set('v.claim', result);
            		component.set('v.AccountId', result.Promotion_Customer_Account__c)
            	}
            )
        );
	}
})