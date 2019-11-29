({
	getSummary : function(component) {
		console.log('AccountSummary.helper.getBillings: initiated');
		var self = this,
				startDate = component.get('v.startDate'),
				endDate = component.get('v.endDate'),
				includeInvoices = component.get('v.includeInvoices'),
				includeCreditMemos = component.get('v.includeCreditMemos'),
				includeReceipts = component.get('v.includeReceipts'),
				action = component.get('c.getAccountSummary'), la;
		action.setParams({
			"accountId" : null,
			"startDate" : startDate,
			"endDate" : endDate,
			"includeInvoices" : includeInvoices,
			"includeCreditMemos" : includeCreditMemos,
			"includeReceipts" : includeReceipts,
			"recType" : 'parts'
		});
    la = new LightningApex( this, action );
    return la.fire();
	}
})