({
	toggleMenu : function(component)
  {
    var menu = component.find("theMenu");
    $A.util.toggleClass(menu, "slds-is-open");
  },

	getOrgId : function(component) {
		return new Promise(function(resolve, reject) {
			var action = component.get('c.getOrgId');
			action.setCallback( this, function( response ) {
				resolve( response.getReturnValue() );
			});
			$A.enqueueAction( action );
		});
	},

	getSetupId : function(component, recordId) {
		return new Promise(function(resolve, reject) {
			var action = component.get('c.getSetupId');
			action.setParams({
				"recordId" : recordId
			});
			action.setCallback( this, function( response ) {
				resolve( response.getReturnValue() );
			});
			$A.enqueueAction( action );
		});
	},

	getUserId : function(component) {
		return new Promise(function(resolve, reject) {
			var action = component.get('c.getUserId'),
					recordId = component.get('v.recordId');
			action.setParams({
				"recordId" : recordId
			});
			action.setCallback( this, function( response ) {
				resolve( response.getReturnValue() );
			});
			$A.enqueueAction( action );
		});
	},

	getCommunityUsers : function(component) {
		var self = this,
				action = component.get('c.getCommunityUsers');
		return new Promise(function(resolve, reject) {
			self.checkUserPermissions(component).then(function(permitted) {
				component.set('v.userHasPermission', permitted);
				action.setCallback( this, function( response ) {
					cuss = JSON.parse(response.getReturnValue());
					component.set('v.communityAccounts', cuss);
					resolve(cuss);
				});
				$A.enqueueAction( action );
			});
		});
	},

	checkUserPermissions : function(component) {
		var self = this;
		return new Promise(function(resolve, reject) {
			var action = component.get('c.checkUserPermissions');
			action.setCallback( this, function( response ) {
				resolve(response.getReturnValue());
			});
			$A.enqueueAction( action );
		});
	},

	generateUserList : function(component, event) {
		var self = this,
				ele = event.currentTarget,
				eleData = ele.dataset,
				accountId = eleData.id,
				accounts = component.get('v.communityAccounts'),
				thisAccount = accounts.find(x => x.id === accountId);

		component.set('v.menuTitle', thisAccount.account.Name);
		component.set('v.accountUsers', thisAccount.users);
		component.set('v.selectedAccount', thisAccount.id);
	},

	loginToCommunityAsUser : function(component) {
		var self = this,
				legendAccountId = component.get('v.legendAccountId'),
				dealerAccountId = component.get('v.selectedAccount'),
				recordId = event.currentTarget.dataset.id.substring(0,15),
				setupId,
				url,
				urlEvent = $A.get("e.force:navigateToURL");

		self.getSetupId(component, recordId).then(function(r) {
			setupId = r;
			url = '/servlet/servlet.su?oid=' + legendAccountId + '&retURL=' + dealerAccountId + '&sunetworkid=' + setupId + '&sunetworkuserid=' + recordId;
			urlEvent.setParams({
	      "url": url
	    });
	    urlEvent.fire();
		});

	}

})