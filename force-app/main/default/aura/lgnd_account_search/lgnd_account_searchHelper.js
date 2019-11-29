({
	lookupContacts : function(component, event) {
		var action,
				query	 = component.get("v.searchQuery"),
				combobox 	= component.find('name_combobox'),
				scope = component.get('v.scope');

		if (scope == 'dealer') {
			action = component.get("c.searchDealerAccounts");
		} else if( scope == 'business' ) {
			action = component.get("c.searchBusinessAccounts");
		} else if( scope == 'supplier' ) {
			action = component.get("c.searchSupplierAccounts");
		} else {
			action = component.get("c.searchAccounts");
		}


		if (query.length >= 2) {
			action.setParams({
				"query": query
			});
			action.setCallback(this, function(response) {
				this.renderResults(response, component, scope);
			});
			$A.enqueueAction(action);
		} else {
			component.set("v.accountList", '');
			this.toggle(combobox, 'close');
			this.enableSearch( component );
			if( query.length === 0 )
				this.clearSearch( component );
		}
	},

	clearSearch: function( component )
	{
		component.set('v.accountId',null);
		component.set('v.selectionMade', false);
		component.set('v.AccountName', null);
		component.set('v.AccountPhone', null);
		component.set('v.AccountStreet', null);
		component.set('v.AccountCity', null);
		component.set('v.AccountZip', null);
		component.set('v.AccountState', null);
		component.set('v.AccountCountry', null);
		component.set('v.showAccountCard', false);
		var evt = component.getEvent('accountSearchCleared');
		evt.fire();
	},

	enableSearch: function( component )
	{
		var search = component.find('search');
		search.set('v.disabled', false);
	},

	renderResults : function(response, component, scope) {
		var data 			= response.getReturnValue(),
				combobox 	= component.find('name_combobox');

		if (scope == 'dealer' || scope == 'supplier' || scope == 'business') {
			if (data.length == 0) {
				component.set("v.accountList", '');
				this.toggle(combobox, 'open');
			} else if (data.length > 0) {
				console.log("found these accounts");
				console.log( data );
				component.set("v.accountList", data);
				this.toggle(combobox, 'open');
				console.log( component.get('v.accountList') );
				console.log( component.get('v.scope') );
			}
		} else {
			console.log("found these accounts");
			console.log( data );
			if (data[0].length == 0 && data[1].length == 0) {
				component.set("v.accountList", '');
				this.toggle(combobox, 'open');
			} else if (data[0].length > 0 || data[1].length > 0) {
				component.set("v.accountList", data);
				this.toggle(combobox, 'open');
			}
		}
	},

	toggle : function(element, action) {
		if (action == 'open') {
			$A.util.removeClass(element, 'slds-is-closed');
			$A.util.addClass(element, 'slds-is-open');
		} else if (action == 'close') {
			$A.util.removeClass(element, 'slds-is-open');
			$A.util.addClass(element, 'slds-is-closed');
		}
	},

	populateAccountCard : function(component, event, accountId) {
		// Fill in account details
		var accountDetails,
				type = component.get('v.AccountType');


		if (type == 'Account') {
			accountDetails = component.get("c.search_getAccount");
		} else if (type == 'Lead') {
			accountDetails = component.get("c.search_getLead");
		}

		accountDetails.setParams({
			"accountId": accountId
		});
		accountDetails.setCallback(this, function(response) {
			var details = response.getReturnValue();
			component.set('v.AccountName', details.Name);
			component.set('v.AccountPhone', details.Phone);
			if( Object.keys( details ).indexOf('BillingAddress') >= 0 )
			{
				component.set('v.AccountStreet', details.BillingAddress.street);
				component.set('v.AccountCity', details.BillingAddress.city);
				component.set('v.AccountZip', details.BillingAddress.postalCode);
				component.set('v.AccountState', details.BillingAddress.state);
				component.set('v.AccountCountry', details.BillingAddress.country);
			}
			if( Object.keys( details ).indexOf('Address') >= 0 )
			{
				component.set('v.AccountStreet', details.Address.street);
				component.set('v.AccountCity', details.Address.city);
				component.set('v.AccountZip', details.Address.postalCode);
				component.set('v.AccountState', details.Address.state);
				component.set('v.AccountCountry', details.Address.country);
			}
		});
		$A.enqueueAction(accountDetails);
		component.set('v.showAccountCard', true);
	}

})