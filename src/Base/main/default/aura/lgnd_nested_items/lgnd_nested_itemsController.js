({
	updateNestedItems : function(component, event, helper) {
		console.log('updateNestedItems');
		helper.findNestedItems(component, event);
	},

	replaceNestedItem : function(component, event, helper) {
		console.log('replaceNestedItem');
		var recordId = event.currentTarget.value,
				record = document.getElementById(recordId),
				i = record.getElementsByTagName('button')[1].value;

		component.set('v.holdingCell', i);

		// Hide original record
		$A.util.addClass(record, 'slds-hide');
		$A.util.removeClass(document.getElementById('addItem'), 'slds-hide');
		$A.util.addClass(document.getElementById('addNestedItemButton'), 'slds-hide');

		// Search field
		document.getElementById('addItem').getElementsByTagName('input')[0].focus();

		// Track stage
		component.set('v.stage','replace');

		// Cancel button
		document.getElementById('addItem').getElementsByTagName('button')[1].setAttribute('value',recordId);
	},

	replaceInNestedItems : function(component, event, helper) {
		console.log("replaceInNestedItems");

		helper.replaceInNestedItems(component, event);
	},

	cancelReplaceNestedItem : function(component, event, helper) {
		console.log('cancelReplaceNestedItem');

		helper.cancelReplaceNestedItem(component, event);
	},

	addNestedItem : function(component, event, helper) {
		console.log('addNestedItem');
		$A.util.removeClass(document.getElementById('addItem'), 'slds-hide');
		$A.util.addClass(document.getElementById('addNestedItemButton'), 'slds-hide');
	},

	addToNestedItems : function(component, event, helper) {
		console.log("addToNestedItems");

		helper.addToNestedItems(component, event);
	},

	cancelAddingNestedItem : function(component, event, helper) {
		console.log('cancelAddingNestedItem');

		component.set('v.stage', '');

		component.set('v.errorMessage','');
		$A.util.addClass(component.find('success'), 'slds-hide');
		$A.util.addClass(component.find('alert'), 'slds-hide');

		$A.util.addClass(document.getElementById('addItem'), 'slds-hide');
		$A.util.removeClass(document.getElementById('addNestedItemButton'), 'slds-hide');

		var recordId = event.currentTarget.value,
				record = document.getElementById(recordId);

		for (var i in document.getElementsByClassName('record')) {
			document.getElementsByClassName('record')[i].classList.remove('slds-hide');
		}		

	},

	removeFromNest : function(component, event, helper) {
		console.log('removeFromNest');
		if (confirm("Are you sure you want to remove this item from your registration?")) {
			helper.removeFromNest(component, event);
		}
	}

})