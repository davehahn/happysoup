({
	doInit: function( component, event, helper )
	{
		var scope = component.get('v.scope');
		console.log('SCOPE: ' + scope);
		component.set('v.isPerson', ( scope === null || scope === undefined || scope.length === 0 || scope === 'customer' ) );
		console.log(component.get('v.isPerson'));
	},

	handleScopeChange: function( component, event )
	{
		var scope = event.getParam("value");
		console.log('HEYYYYYY');
		console.log(scope);
		console.log(component.get('v.isPerson'));
		component.set('v.isPerson', ( scope === null || scope === undefined || scope.length === 0 || scope === 'customer' ) );
		console.log(component.get('v.isPerson'));
	},

	lookupContacts : function(component, event, helper) {
		if (component.get('v.selectionMade') == false) {
			helper.lookupContacts(component, event);
		} else if (component.get('v.searchQuery') == '') {
			helper.clearSearch( component );
		} else {
			component.set('v.selectionMade', true);
		}
	},

	clickAccount : function (component, event, helper) {
		component.set('v.selectionMade', true);

		var selectedItem = event.currentTarget,
				accountId = selectedItem.dataset.accountid;

		component.set('v.searchQuery', selectedItem.dataset.name);
		component.set('v.AccountType', selectedItem.dataset.type);
		component.set('v.accountId', accountId);
		component.set('v.showAccountCard',true);

		combobox = component.find('name_combobox');
		helper.toggle(combobox, 'close');

		if( component.get('v.selectorOnly') )
		{
			var evt = component.getEvent("accountSelected"),
			    accountSearchEvent = component.getEvent('accountSearchResultEvent');
			evt.setParams({
				accountId: accountId
			})
			.fire();
			accountSearchEvent.setParams({
			  action: 'edit',
			  recordId: accountId
      })
      .fire();
		}
		else
		{
			helper.populateAccountCard(component, event, accountId);
		}
	},

	populateAccountCard : function(component, event) {
		var accountId = component.get('accountId');
		helper.populateAccountCard(component, event, accountId);
	},

	enableSearch: function( component )
	{
		component.find('search').set('v.disabled', false);
	},

	disableSearch: function( component )
	{
		component.find('search').set('v.disabled', true);
	},

	clickCreateNewAccount : function(component, event, helper) {
		var myEvent = component.getEvent("lgnd_registration_event"),
		    accountSearchEvent = component.getEvent('accountSearchResultEvent'),
				combobox = component.find('name_combobox'),
				search = component.find('search');

		helper.toggle(combobox, 'close');

		search.set('v.disabled', true);

		myEvent.setParams({"event": "new"});

		myEvent.fire();

		accountSearchEvent.setParams({
		  action: 'new'
    })
    .fire();
	},

	close : function(component, event, helper) {
		var element = component.find('name_combobox'),
				accountList = component.get('v.accountList');

		if (accountList.length < 1) {
			helper.toggle(element, 'close');
		}
	}
})