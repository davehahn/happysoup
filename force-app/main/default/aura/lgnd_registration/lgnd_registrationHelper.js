({
	fetchContacts: function( component )
	{
		console.log('regHelper.fetchContacts');
	  var action = component.get('c.fetchAccountContacts');
	  return new LightningApex( this, action ).fire();
	},

	resetCustomer: function( component )
	{
	  component.set('v.Customer', {
      id: '',
      firstName: '',
      lastName: '',
      email: '',
      phone: '',
      mobilePhone: '',
      street: '',
      city: '',
      state: '',
      stateCode: '',
      country: '',
      postalCode: ''
    });
  },

	fetchCustomer: function( component, objectId )
	{
	  var action = component.get('c.fetchCustomer');
	  action.setParams({
	    recordId: objectId
    });
    return new LightningApex( this, action ).fire();
  },

  formValid: function( component )
  {
    var requiredFields = component.find('required-form-1'),
        addrForm = component.find('address-form');

    if( component.get('v.accountScope') === 'dealer' ) return true;
    if( typeof(addrForm) === 'undefined' )
    {
     LightningUtils.errorToast('Did you forget to select an account?');
     return false;
    }

    if( requiredFields === null || requiredFields == undefined )
      requiredFields = [];
    // if we have a single field ( this will be an object not an array )
    if( requiredFields.length === undefined )
      requiredFields = [requiredFields];

    return requiredFields.reduce(function (validSoFar, inputCmp) {
      inputCmp.showHelpMessageIfInvalid();
      return validSoFar && inputCmp.get('v.validity').valid;
    }, addrForm.isValid() );
  },

	createRegistration : function(component, event, regSpinner) {
		var self = this,
				action 	= component.get("c.createRegistration"),
				serno  	= component.get('v.sernoId'),
				customer = component.get('v.Customer'),
				nestedItems = component.get('v.NestedItems'),
				motor = component.get('v.MotorUpgrade'),
				motorSerial = component.get('v.MotorSerial'),
				deliveryDate = component.get('v.DeliveryDate'),
				memoryMaker = component.get('v.memoryMaker'),
				caseId = component.get('v.caseId'),
				paymentMethod = component.get('v.paymentMethod');
		if (serno != null ) {
			action.setParams({
				"serno": serno,
				"customerJSON": JSON.stringify( customer ),
				"customerType": customer.type,
				"NestedItems": nestedItems,
				"motor": motor,
				"motorSerial": motorSerial,
				"deliveryDate": deliveryDate,
				"partnerMemoryMaker": memoryMaker,
				"caseId": caseId,
				"paymentMethod": paymentMethod
			});
			action.setCallback(this, function(response) {
				if (caseId != null) {
					self.updateCase(response, component)
					.then
					(
						$A.getCallback( function() {
							self.renderResults(response, component, regSpinner);
						})
					);
				} else {
					self.renderResults(response, component, regSpinner);
				}
			});
			$A.enqueueAction(action);
		}
		else if (serno == null) {
			self.renderResults('serno', component, regSpinner);
		}
		else {
			self.renderResults(null, component, regSpinner);
		}
	},

	updateCase : function(response, component) {
		return new Promise( function(resolve, reject) {
			var caseId = component.get('v.caseId'),
					regId = response.returnValue.Id,
					action = component.get('c.updateClaimWithRegistration');
			action.setParams({
				"caseId" : caseId,
				"regId" : regId
			});
			action.setCallback(this, function(response) {
				resolve();
			});
			$A.enqueueAction(action);
		});
	},

	renderResults : function(response, component, regSpinner) {
		var redirectToRecord = component.get('v.redirectToRecord'),
				regInProcess = component.get('v.regInProcess');

		if (response == null) {
			component.set('v.errorMessage', 'Something went wrong. Try again?');
		} else if (response == 'serno') {
			component.set('v.errorMessage', 'Did you forget the serial number?');
		}  else if (response.error.length > 0) {
		  console.log( JSON.parse( JSON.stringify( response.error ) ) );
			component.set('v.errorMessage', response.error[0].pageErrors[0].message);
		} else {
			if (redirectToRecord) {
				var xyz = $A.get("e.force:navigateToSObject");
				xyz.setParams({
					"recordId" : response.returnValue.Id
				});
				xyz.fire();
			} else if (regInProcess) {
				component.set('v.errorMessage', '');
				component.set('v.serno', '');
				component.set('v.sernoId', '');
				component.set('v.nestId', '');
				component.set('v.MotorUpgrade', '');
				component.set('v.MotorSerial', '');
				component.set('v.DeliveryDate', '');
				component.set('v.memoryMaker', '');
				component.set('v.paymentMethod', '');
				component.set('v.showProductCard', false);
				component.set('v.ProductId', '');
				component.set('v.ProductDescription', '');
				component.set('v.ProductType', '');
				component.set('v.ProductLocation', '');
				component.set('v.sernoSelected', false);
				component.set('v.canBeNest', false);
				component.set('v.hideSernoSearch', false);
				LightningUtils.showToast('success', 'success', 'Product has been registered. High five!');
				component.set('v.regInProcess', false);
			}
		}

		$A.util.toggleClass(regSpinner, 'slds-hide');
		component.set('v.searchQuery','');
	},

	getUpgrades : function (component) {
		var action = component.get('c.getUpgrades'),
				productId = component.get('v.ProductId');

		if (productId != null) {
			action.setParams({
				"productId" : productId
			});
			action.setCallback(this, function(response) {
				var details = JSON.parse(response.getReturnValue());
				component.set('v.MotorUpgrades', details['MotorUpgrades']);
			});
			$A.enqueueAction(action);
		}
	}
})