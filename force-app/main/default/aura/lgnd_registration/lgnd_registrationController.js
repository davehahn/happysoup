({
	doInit : function(component, event, helper) {
		var accId = component.get('v.accountId'),
				type = component.get('v.AccountType');
		helper.fetchContacts( component )
		.then(
			$A.getCallback( function( result ) {
				console.log(  result );
				component.set('v.salesPeople', result );
				if (accId != null) {
					helper.hideAccountForm(component, event);
					helper.populateAccountCard(component, event, type);
				}
			}),
			$A.getCallback( function( err) {
				LightningUtils.errorToast( err );
			})
		);
	},

	clickRegister : function(component, event, helper) {
		console.log('clickRegister');
		var regSpinner = component.find('registrationSpinner');
		$A.util.toggleClass(regSpinner, 'slds-hide');

		helper.createRegistration(component, event, regSpinner);
	},

	cancelRegister : function(component, event, helper) {
		component.set('v.serno',  '');
		component.set('v.sernoId',  '');
		component.find('lgnd_account_search').set('v.accountList', '');
    document.getElementById('lgnd_registration').classList.add('slds-hide');
    document.getElementById('lgnd_inventory_list').classList.remove('slds-hide');
	},

	lgndRegistrationEvent : function(component, event, helper) {
		var accountForm = component.find('accountCreationForm'),
				registration = component.find('registration'),
				registerBtn = component.find('buttonClickRegister'),
				regEvt = event.getParam("event");

		if (regEvt == 'new') {
			registerBtn.set('v.disabled', true);
			$A.util.removeClass(accountForm, 'slds-hide');
			$A.util.addClass(registration, 'slds-hide');
		} else {
			registerBtn.set('v.disabled', false);
			$A.util.addClass(accountForm, 'slds-hide');
			component.find('lgnd_account_search').enableSearch();
			$A.util.removeClass(registration, 'slds-hide');
		}
	},

	accountCreated : function(component, event, helper) {
		helper.hideAccountForm(component, event);
		var type = component.get('v.AccountType');
		if (component.get('v.accountId') != null) {
			helper.populateAccountCard(component, event, type);
		}
	},

	toggleAccountCard : function(component, event, helper) {
		if (component.get('v.accountId') != null) {
			$A.util.removeClass(component.find('account-card'), 'slds-hide');
		} else {
			$A.util.addClass(component.find('account-card'), 'slds-hide');
			component.set('v.MotorUpgrades', null);
		}

	},

	toggleProductCard : function(component, event, helper) {
		component.set('v.showProductCard', true)
	},

	remove : function(component, event, helper) {
		if(confirm("Are you sure you want to REMOVE this item?")) {
        alert('TO DO');
    } else {
        e.preventDefault();
    }
	},

	toggleMessage : function(component, event, helper) {
		var err = component.get('v.errorMessage');
		if (err != '') {
			LightningUtils.showToast('error', 'Oops', err);
		}
	},

	populateUpgrades : function(component, event, helper) {
		helper.getUpgrades(component);
	},

	toggleMotorDropdown : function(component) {
		$A.util.toggleClass(component.find('MotorDropdown'),'slds-is-open');
	},

	clearUpgrades : function(component) {
		if (!component.get('v.canBeNest')) {
			component.set('v.MotorUpgrades', null);
		}
	},

	selectUpgrade : function(component, event) {
		event.getSource().addClass('slds-is-selected');
	}
})