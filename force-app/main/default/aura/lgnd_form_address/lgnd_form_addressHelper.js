({
	findPlaces : function(component, event, searchTerm) {
		var action 			= component.get("c.getPlaces"),
				location		= component.get("v.location"),
				radius			= component.get("v.radius"),
				apiKey			= component.get("v.apiKey");

		action.setParams({
			"searchTerm": searchTerm,
			"location": location,
			"radius": radius
		});
		action.setCallback(this, function(response) {
			this.doLayout(response, component);
		});
		$A.enqueueAction(action);
	},

	doLayout : function(response, component) {
		var data = JSON.parse(response.getReturnValue()),
				combobox 	= component.find('address_combobox');

		console.log(data);

		if (data != null && data.predictions.length > 0) {
			component.set("v.addressList", data.predictions);
			$A.util.removeClass(combobox, 'slds-is-closed');
			$A.util.addClass(combobox, 'slds-is-open');
		} else {
			component.set("v.addressList", '');
			$A.util.removeClass(combobox, 'slds-is-open');
			$A.util.addClass(combobox, 'slds-is-closed');
		}
	},

	fillInAddress : function (component, event) {
		var self = this,
		    combobox 		= component.find('address_combobox'),
				id 					= event.currentTarget.dataset.addressId,
				addressList = component.get("v.addressList"),
				address 		= addressList[id] || '',
				street_num 	= '',
				street_name = '',
				city 				= '',
				province 		= '',
				country			= '',
				zip 				= '',
				placeId			= address.place_id,
				action			= component.get("c.getDetails");

		// Get Postal Code
		action.setParams({
			"placeId": placeId
		});
		action.setCallback(this, function(response) {
			var address = JSON.parse(response.getReturnValue()).result,
					street_num, street_name,
					el = document.createElement('html');

			el.innerHTML = address.adr_address;
			console.log(address);
			if (!address.error)
			{
				for( let addr_comp of address.address_components )
				{
					if( addr_comp.types.indexOf('country') >= 0 )
					{
						component.set('v.country', addr_comp.long_name);
						component.set('v.country_code', addr_comp.short_name);
					}
					if( addr_comp.types.indexOf('administrative_area_level_1') >= 0 )
					{
						component.set('v.province', addr_comp.long_name.normalize('NFD').replace(/[\u0300-\u036f]/g, ""));
						component.set('v.province_code', addr_comp.short_name);
					}
					if( addr_comp.types.indexOf('locality') >= 0 )
					{
						component.set('v.city', addr_comp.long_name);
					}
					if( addr_comp.types.indexOf('postal_code') >= 0 )
					{
						component.set('v.zip', addr_comp.long_name);
					}
					if( addr_comp.types.indexOf('route') >= 0 )
					{
						street_name = addr_comp.short_name;
					}
					if( addr_comp.types.indexOf('street_number') >= 0 )
					{
						street_num = addr_comp.long_name;
					}
				}
				component.set('v.street', street_num + ' ' + street_name );
				component.set("v.search", '');
				self.validateForm( component );
			}
		});
		$A.enqueueAction(action);

		// Close the combobox
		$A.util.removeClass(combobox, 'slds-is-open');
		$A.util.addClass(combobox, 'slds-is-closed');

		component.set('v.inFocus', null);
	},

	handleArrowKey : function(component, event, arrowKey) {
		var selection 	= component.get('v.inFocus'),
				addressList = component.get('v.addressList');

		if (arrowKey == 'up') {
			if (selection == 0) {
				selection = null;
			} else if (selection > 0) {
				selection -= 1;
			}
		} else if (arrowKey == 'down') {
			if (selection == null) {
				selection = 0;
			} else if (selection < addressList.length) {
				selection += 1;
			}
		}

		component.set('v.inFocus', selection);
		document.getElementById('listbox-option-unique-id-' + selection).focus();
	},

	validateForm: function( component )
	{
	  if( !component.get('v.allRequired') ) return true;
    var requiredFields = component.find('required-field');
    if( requiredFields === null || requiredFields == undefined )
      requiredFields = [];
    // if we have a single field ( this will be an object not an array )
    if( requiredFields.length === undefined )
      requiredFields = [requiredFields];

    return requiredFields.reduce(function (validSoFar, inputCmp) {
      inputCmp.showHelpMessageIfInvalid();
      return validSoFar && inputCmp.get('v.validity').valid;
    }, true);
  }
})