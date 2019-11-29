({
	doInit : function(component, event, helper) {
		helper.getProducts(component);
		//helper.getDocumentationRequirements(component);
	},

	handleProductSelection : function(component, event, helper) {
		var selectedOptionValue = event.getParam("value");
		component.set('v.productId', selectedOptionValue);
		helper.getAvailablePromotionsByProduct(component);
	},

	handlepromoItemsSelection : function(component, event, helper) {
		var selectedOptionValue = event.getParam("value");
		component.set('v.promoItemId', selectedOptionValue);
		helper.getPromotion(component);
	},

	submit : function(component, event, helper) {
		component.find('spinner').toggle();
		helper.claimPromoWithoutSerno(component);
	},

	done : function(component, event, helper) {
		var urlEvent = $A.get("e.force:navigateToURL"),
				caseId = component.get('v.caseId');
    urlEvent.setParams({
      "url": "/case/" + caseId
    });
    urlEvent.fire()
	},

  lgndRegistrationEvent : function(component, event, helper) {
    var accountForm = component.find('accountCreationForm'),
        regEvt = event.getParam("event");

    if (regEvt == 'new') {
      $A.util.removeClass(accountForm, 'slds-hide');
      $A.util.addClass(registration, 'slds-hide');
    } else {
      $A.util.addClass(accountForm, 'slds-hide');
      component.find('lgnd_account_search').enableSearch();
      $A.util.removeClass(registration, 'slds-hide');
    }
  },

	accountCreated : function(component, event, helper) {
		helper.hideAccountForm(component, event);
	}
})