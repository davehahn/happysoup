({
	searchInventories : function(component) {
    console.log('helper.search')
		var action = component.get('c.searchPartnerInventories');
		action.setParams({
		  includeFactoryStoresForPartners: component.get('v.includeFactoryStoresForPartners')
    });
    return new LightningApex( this, action ).fire();
	}
})