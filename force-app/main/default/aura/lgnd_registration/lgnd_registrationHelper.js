({
	fetchContacts: function( component )
	{
		console.log('regHelper.fetchContacts');
	  var action = component.get('c.fetchAccountContacts');
	  return new LightningApex( this, action ).fire();
	},

	createRegistration : function(component, event, regSpinner) {
		var self = this,
				action 	= component.get("c.createRegistration"),
				serno  	= component.get('v.sernoId'),
				account = component.get('v.accountId'),
				nestedItems = component.get('v.NestedItems'),
				motor = component.get('v.MotorUpgrade'),
				motorSerial = component.get('v.MotorSerial'),
				deliveryDate = component.get('v.DeliveryDate'),
				memoryMaker = component.get('v.memoryMaker'),
				caseId = component.get('v.caseId'),
				paymentMethod = component.get('v.paymentMethod');

		if (serno != null && account != null) {
			action.setParams({
				"serno": serno,
				"account": account,
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
		else if (account == null) {
			self.renderResults('account', component, regSpinner);
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
		} else if (response == 'account') {
			component.set('v.errorMessage', 'Did you forget to select an account?');
		} else if (response.error.length > 0) {
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

	hideAccountForm : function(component, event) {
		var accountForm = component.find('accountCreationForm'),
				registerBtn = component.find('buttonClickRegister'),
				registration = component.find('registration');

		registerBtn.set('v.disabled', false);

		$A.util.addClass(accountForm, 'slds-hide');
		$A.util.removeClass(registration, 'slds-hide');

		component.find('lgnd_account_search').enableSearch();
	},

	populateAccountCard : function(component, event) {
		var accountDetails,
				accountId = component.get("v.accountId"),
				type = component.get("v.AccountType");

		if (type == 'Account') {
			accountDetails = component.get("c.getAccount");
		} else if (type == 'Lead') {
			accountDetails = component.get("c.getLead");
		}

		accountDetails.setParams({
			"accountId": accountId
		});
		accountDetails.setCallback(this, function(response) {
			var details = response.getReturnValue();
			component.set('v.AccountName', details.Name);
			component.set('v.AccountPhone', details.Phone);
			component.set('v.AccountStreet', details.Street);
			component.set('v.AccountCity', details.City);
			component.set('v.AccountZip', details.PostalCode);
			component.set('v.AccountState', details.State);
			component.set('v.AccountCountry', details.Country);
		});
		$A.enqueueAction(accountDetails);
		component.set('v.showAccountCard', true);
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