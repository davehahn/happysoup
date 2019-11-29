({
	searchInventories : function(component) {
    console.log('helper.search')
		var action = component.get('c.searchPartnerInventories');
    return new LightningApex( this, action ).fire();
	}
})