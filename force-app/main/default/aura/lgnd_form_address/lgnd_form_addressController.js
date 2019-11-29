({
	doInit : function(component, event, helper) {
		var provinces = [
											{ value: "", 		label: "--None--" },
											{ value: "AB", 	label: "Alberta" },
											{ value: "BC", 	label: "British Columbia" },
											{ value: "MB", 	label: "Manitoba" },
											{ value: "NB", 	label: "New Brunswick" },
											{ value: "NL", 	label: "Newfoundland and Labrado" },
											{ value: "NT", 	label: "Northwest Territories" },
											{ value: "NS", 	label: "Nova Scotia" },
											{ value: "NU", 	label: "Nunavut" },
											{ value: "ON", 	label: "Ontario" },
											{ value: "PE",  label: "Prince Edward Island" },
											{ value: "QC", 	label: "Quebec" },
											{ value: "SK", 	label: "Saskatchewan" },
											{ value: "YT", 	label: "Yukon" }
										];

		var countries = [
											{ value: "",							label: "--None--" },
											{ value: "Canada",				label: "Canada" },
											{ value: "Unite States",	label: "USA" }
										];
		component.set('v.apiKey', 'AIzaSyADJPE6bn9M5jPLrQW57nAAfYA3aBvNkmk');
		component.set("v.provinces", provinces);
		component.set("v.countries", countries);

		document.onkeydown = checkKey;

		function checkKey(e) {

	    e = e || window.event;

	    var focus_on_search = false;

	    if (document.activeElement.getAttribute("name") == "Search" || document.activeElement.getAttribute("role") == "option") {
	    	focus_on_search = true;
	    } else {
	    	focus_on_search = false;
	    }

	    if (focus_on_search && e.keyCode == '38') {
	        helper.handleArrowKey(component, event, 'up');
	    }
	    else if (focus_on_search && e.keyCode == '40') {
	        helper.handleArrowKey(component, event, 'down');
	    }
		}

	},

	onRender : function(component, event, helper) {
		// Add aria to search
		var componentId = component.get("v.componentId"),
				searchField = document.getElementById(componentId).getElementsByTagName('input')[0];

		searchField.setAttribute('aria-autocomplet','list');
		searchField.setAttribute('role','combobox');
	},

	findPlaces : function(component, event, helper) {
		var searchTerm = component.get("v.search");
		helper.findPlaces(component, event, searchTerm);
	},

	fillInAddress : function(component, event, helper) {
		helper.fillInAddress(component, event);
	}
})