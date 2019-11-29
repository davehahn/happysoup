({
	search : function(component, event, helper) {
		if (component.get('v.pauseSearch') == false) {
			helper.search(component, event);
			component.set('v.selectionMade', false);
			component.set('v.canBeNest', false);
			component.set('v.errorMessage', '');
		}
	},

	clickSerialNumber : function (component, event, helper) {
		component.set('v.pauseSearch', true);
		helper.clickSerialNumber(component, event)
					.then(function() {
						component.set('v.pauseSearch', false);
					});
	},

	getCard : function (component, event, helper) {
		console.log('getCard');
		helper.getCard(component, event);
	}
})