({
	doInit : function(component, event, helper) {
		helper.getClaimDetails(component, event);
	},

	btnClick : function(component, event, helper) {
		var final_destination = event.getSource().get('v.value');

		$A.get("e.force:navigateToSObject")
		.setParams({
			"recordId" : final_destination
		})
		.fire();
	}
})