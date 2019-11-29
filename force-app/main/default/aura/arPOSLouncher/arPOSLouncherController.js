({
	openAppSales : function(component, event, helper) {
		component.set('v.currentPosFunction', 'cs');
	},
	navigateToPOS : function(component, event, helper) {
	  component.set('v.currentPosFunction', 'csr');
	}
})