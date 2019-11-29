({
	isFormValid: function( component )
  {
    return component.find('requiredField').reduce(function (validSoFar, inputCmp) {
            inputCmp.showHelpMessageIfInvalid();
            return validSoFar && inputCmp.get('v.validity').valid;
        }, true);
  },

	createLead : function(component, event) {
		var action,
				params,
				createLead = component.get('v.createLead'),
				accountSpinner = component.find('accountSpinner');
		console.log( 'Should we create a lead first ? ' + createLead === true ? 'YES' : 'NO' );
		action = createLead ? component.get('c.createLeadAndConvert') : component.get('c.createAccount');
		params = {
			"FirstName" : 				component.get('v.FirstName'),
			"LastName" : 					component.get('v.LastName'),
			"Email" : 						component.get('v.PersonEmail'),
			"Phone" : 						component.get('v.Phone'),
			"Street" : 						component.get('v.BillingAddressStreet'),
			"City" : 							component.get('v.BillingAddressCity'),
			"State" : 						component.get('v.BillingAddressState'),
			"StateCode": 					component.get('v.BillingAddressStateCode'),
			"Country" : 					component.get('v.BillingAddressCountry'),
			"CountryCode" : 			component.get('v.BillingAddressCountryCode'),
			"PostalCode" : 				component.get('v.BillingAddressPostalCode'),
			"PersonMobilePhone" : component.get('v.PersonMobilePhone')
		};
		console.log( params );
		action.setParams( params );
		action.setCallback(this, function(response) {
			console.log("account response:");
			console.log(response);
			if (response.getReturnValue() != null) {
				this.accountCreated(response, component);
			}
			else if (response.error.length > 0 && response.error[0].pageErrors.length > 0) {
				this.showError(component, response.error[0].pageErrors[0].message);
				$A.util.toggleClass(accountSpinner, 'slds-hide');
			}
			else {
				this.showError(component, "Something went wrong. Contact your administrator.");
				$A.util.toggleClass(accountSpinner, 'slds-hide');
			}
		});
		$A.enqueueAction(action);
	},

	accountCreated : function(response, component) {
		var self = this;
		try {
			var result = response.getReturnValue();
			console.log('HEY');
			console.log(result);
			component.set('v.selectionMade',true);
			component.set('v.accountId', result.Id);
			component.set('v.searchQuery', result.Name);
			var evt = component.getEvent("lgnd_account_created");
			evt.setParams({
				accountId: result.Id,
				accountName: result.FirstName + ' ' + result.LastName
			})
			.fire();
			component.set('v.errorMessage', '');
			$A.util.addClass(component.find('alert'), 'slds-hide');
			this.clearForm( component );
		}
		catch (e) {
			component.set('v.errorMessage', e);
		}
		finally {
			var accountSpinner = component.find('accountSpinner');
			$A.util.toggleClass(accountSpinner, 'slds-hide');
		}
	},

	showError : function(component, error) {
		component.set('v.errorMessage', error);
		$A.util.removeClass(component.find('alert'), 'slds-hide');
	},

	clearForm: function( component )
	{
		component.set('v.FirstName', '');
		component.set('v.LastName', '');
		component.set('v.PersonEmail', '');
		component.set('v.Phone', '');
		component.set('v.BillingAddressStreet', '');
		component.set('v.BillingAddressCity', '');
		component.set('v.BillingAddressState', '');
		component.set('v.BillingAddressCountry', '');
		component.set('v.BillingAddressPostalCode', '');
		component.set('v.PersonMobilePhone', '');
	}
})