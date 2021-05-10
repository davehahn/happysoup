({
	doInit : function(component, event, helper) {
		var recordId = component.get('v.recordId');
		helper.getOrgId(component).then(function(r) {
			component.set('v.legendAccountId', r);
		});

		helper.getCommunityUsers(component);
	},

	click : function(component, event, helper) {
		helper.loginToCommunityAsUser(component);
	},

	showUsers : function(component, event, helper) {
		helper.toggleMenu( component );
		helper.generateUserList(component, event);
	},

	toggleMenu : function(component, event, helper)
  {
    helper.toggleMenu( component );
	}
})