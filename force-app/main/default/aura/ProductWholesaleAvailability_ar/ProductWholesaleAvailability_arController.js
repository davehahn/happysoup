({
	doInit: function(component, event, helper) {
        helper.toggleSpinner(component, false);
		helper.runAction(component, "c.retrieveBoats", {}, function(response) {
			var results = response.getReturnValue();            
			component.set("v.allAvailableBoats", results);
		});
	},
	searchAgain: function( component, event, helper )
	{
		component.set("v.wholesaleData", []);
		component.set('v.showData', false);				
	},
	handleProductSelected: function( component, event, helper )
	{
        if(component.get("v.idProduct") == ''){
            component.set("v.availAbility", '0');
            component.set("v.availAbilityDate", '');
			component.set('v.showData', false);				
        	return;
        }
		helper.toggleSpinner(component, true);
		helper.runAction(component, "c.retrieveWholesaleInfo", {
			idProduct: component.get("v.idProduct")
		}, function(response) {
			var results = response.getReturnValue();
			results = JSON.parse(results);
            console.log('length');
			if(results['Wholesale Inventory'] != undefined)
			{
				component.set("v.availAbility", results['Wholesale Inventory'][0].netAvailable);
				component.set("v.availAbilityDate", results['Wholesale Inventory'][0].nextPositiveShipment);
				component.set("v.datePositiveShipment", results['Wholesale Inventory'][0].datePositiveShipment);
				component.set("v.datePositiveShipmentIsToday", results['Wholesale Inventory'][0].datePositiveShipmentIsToday);
                component.set('v.showData', true);
			}else{
                component.set("v.availAbility", '0');
                component.set("v.availAbilityDate", '');
				component.set('v.showData', true);				
			}
            console.log(results['Wholesale Inventory'][0].netAvailable);
            console.log(results['Wholesale Inventory'][0].nextPositiveShipment);            
            console.log(component.get("v.availAbilityDate"));            
            console.log(results['Wholesale Inventory'][0].datePositiveShipment);            
            console.log(results['Wholesale Inventory'][0].datePositiveShipmentIsToday);            
			helper.toggleSpinner(component, false);
		});
	}
})