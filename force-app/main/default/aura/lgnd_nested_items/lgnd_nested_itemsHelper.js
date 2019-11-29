({
	findNestedItems : function(component, event) {
		console.log('helper.findNestedItems');
		var action = component.get("c.findNestedItems"),
				sernoId = component.get("v.nestId");

		action.setParams({
			"sernoId": sernoId
		});
		action.setCallback(this, function(response) {
			this.renderNestedItems(component, event, response);
		});
		$A.enqueueAction(action);
	},

	renderNestedItems : function(component, event, response) {
		console.log('helper.renderNestedItems');
		console.log(response);
		component.set('v.NestedItems', response.getReturnValue());
	},

	replaceNestedItem : function(component, event) {
	},

	cancelReplaceNestedItem : function(component, event) {
		console.log('cancelReplaceNestedItem');
		var recordId = event.currentTarget.value,
				record = document.getElementById(recordId),
				addItemForm = document.getElementById('addItem');
		
		$A.util.addClass(record.nextSibling, 'slds-hide');
		$A.util.removeClass(record, 'slds-hide');

		component.set('v.stage', '');
	},

	addToNestedItems : function(component, event) {
		console.log('helper.addToNestedItems');

		var sernoId = component.get('v.newSernoId'),
				action = component.get('c.getProductDetails'),
				nest = component.get('v.NestedItems'),
				i = component.get('v.holdingCell');

		console.log(sernoId);

		if (sernoId != null) {
			action.setParams({
				"sernoId": sernoId
			});
			action.setCallback(this, function(response) {
				console.log(response.getReturnValue());
				if (this.isNestable(component, event, response)) {
					// Remove previous item from nest if replacement is successful
					if (component.get('v.stage') == 'replace') {
						// Remove original item
						nest.splice(i, 1);
						// Add item
						nest.push(response.getReturnValue());
						component.set('v.NestedItems', nest);
						console.log(component.get('v.NestedItems'));
					} else {
						// Add item
						nest.push(response.getReturnValue());
						component.set('v.NestedItems', nest);
						console.log(component.get('v.NestedItems'));
					}
					component.set('v.stage','');
					component.set('v.holdingCell', '');
					$A.util.addClass(component.find('alert'), 'slds-hide');
				} else {
					$A.util.addClass(component.find('success'), 'slds-hide');
					$A.util.removeClass(component.find('alert'), 'slds-hide');
				}

				component.set('v.newSerno','');
				
			});
			$A.enqueueAction(action);
		}

		
	},

	removeFromNest : function(component, event) {
		console.log('helper.removeFromNest');
		var nestedItems = component.get('v.NestedItems'),
				i = event.target.value;

		nestedItems.splice(i, 1);

		component.set('v.NestedItems', nestedItems);
	},

	replaceInNestedItems : function(component, event) {
		console.log('helper.replacInNestedItems');

		var recordId = event.currentTarget.value,
				record = document.getElementById(recordId),
				i = event.currentTarget.name,
				nestedItems = component.get('v.NestedItems');

		nestedItems.splice(i, 1);

		component.set('v.NestedItems', nestedItems);

		this.addToNestedItems(component, event);
		
		$A.util.addClass(record.nextSibling, 'slds-hide');
		$A.util.removeClass(record, 'slds-hide');
	},

	// Helper helpers. The quicker picker uppers. Bounty.

	insertAfter : function(newNode, referenceNode) {
		console.log('insertAfter');
    referenceNode.parentNode.insertBefore(newNode, referenceNode.nextSibling);
	},

	isNestable : function(component, event, response) {
		var item = response.getReturnValue();
		var nest = component.get('v.NestedItems');
		var i = component.get('v.holdingCell');

		console.log(item);

		if (item.GMBLASERP__Product__r.Can_be_Nested__c) {
			var count = 0;

			if (component.get('v.stage') == 'replace') {
				if (nest[i].Product_Record_Type__c == item.Product_Record_Type__c) {
					return true;
				} else {
					component.set('v.errorMessage', 'You can only replace a ' + item.Product_Record_Type__c + ' with another ' + item.Product_Record_Type__c);
					return false;
				}
			} else {
				for (var x in nest) {
					if (nest[x].Product_Record_Type__c == item.Product_Record_Type__c) {
						count = count + 1;
					}
				}
				if (count == 0) {
					return true;
				} else {
					component.set('v.errorMessage', 'There can only be 1 ' + item.Product_Record_Type__c + ' per boat at a time.');
					return false;
				}
			}
		} else {
			component.set('v.errorMessage', 'This item cannot be nested.');
			return false;
		}
	}

})