({
	afterScripts : function(component, event, helper) {
		helper.initialize(component);
	},

	selectLead : function(component, event, helper) {
		var value = component.find('leadSelect').get('v.value');
		component.set('v.lead', value);
	}
})