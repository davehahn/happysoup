({
  doInit: function (component, event, helper) {
    var steps = ["Select Account", "Account Contacts", "Opportunity"];
    component.set("v.steps", steps);
    component.set("v.currentStep", steps[0]);
    component.set("v.business", {});
    component.set("v.activeContact", {});
  },

  afterScripts: function (component, event, helper) {
    helper.getSelectOptions(component).then(
      $A.getCallback(function (result) {
        console.log(result);
        component.set("v.selectOptions", result);
        component.set("v.opp", result.opp);
      }),
      $A.getCallback(function (err) {
        LightningUtils.errorToast(err);
      })
    );
  },

  handleNext: function (component, event, helper) {
    var steps = component.get("v.steps"),
      step = component.get("v.currentStep"),
      stepNum = steps.indexOf(step) + 1;

    if (stepNum === 1 && !component.get("v.showBusinessForm")) {
      LightningUtils.errorToast("Please select or create a new account");
      return false;
    }

    if (stepNum === 2) {
      if (!helper.verifyContactBuyerSet(component)) {
        LightningUtils.errorToast("Please select a Contact as the Buyer");
        return false;
      }
    }

    if (helper.formValid(component, stepNum)) component.set("v.currentStep", steps[stepNum]);
    else LightningUtils.errorToast("Please fix any errors on the form to continue");
  },

  handleBack: function (component) {
    var steps = component.get("v.steps"),
      step = component.get("v.currentStep"),
      stepNum = steps.indexOf(step);

    if (stepNum === 0) component.set("v.saleType", "");
    else component.set("v.currentStep", steps[steps.indexOf(step) - 1]);
  },

  handleCreateAccount: function (component, event, helper) {
    component.set("v.showBusinessForm", true);
  },

  handleAccountSelected: function (component, event, helper) {
    console.log("accountSelected");
    var objectId = event.getParams().accountId,
      spinner = component.find("spinner");
    spinner.toggle();
    console.log(objectId);
    helper.fetchBusiness(component, objectId).then(
      $A.getCallback(function (result) {
        console.log(result);
        component.set("v.business", result);
        component.set("v.showBusinessForm", true);
        spinner.toggle();
      }),
      $A.getCallback(function (err) {
        LightningUtils.errorToast(err);
      })
    );
  },

  handleAccountSearchCleared: function (component) {
    console.log("handling account search cleared event ");
    component.set("v.business", {});
    component.set("v.activeContactNum", null);
    component.set("v.activeContact", {});
    component.set("v.showBusinessForm", false);
    component.set("v.showContactForm", false);
  },

  contactPillClick: function (component, event) {
    var ele = event.currentTarget,
      contactNum = ele.dataset.contactNumber,
      contacts = component.get("v.business").contacts;
    component.set("v.activeContactNum", contactNum);
    component.set("v.activeContact", contacts[contactNum]);
    // false/true statement reset the validation on the form
    component.set("v.showContactForm", false);
    component.set("v.showContactForm", true);
  },

  addContact: function (component, event, helper) {
    var business = component.get("v.business"),
      newContact,
      steps = component.get("v.steps"),
      step = component.get("v.currentStep"),
      stepNum = steps.indexOf(step) + 1;

    if (business.contacts === undefined) business.contacts = [];

    if (component.get("v.showContactForm")) {
      if (!helper.formValid(component, stepNum)) return;
    }

    //check if there is already a "New Contact" in list
    for (let c of business.contacts) {
      if (c.label === "New Contact") {
        newContact = c;
        break;
      }
    }

    if (newContact === undefined || newContact === null) {
      newContact = { label: "New Contact" };
      business.contacts.push(newContact);
    }
    component.set("v.activeContact", newContact);
    component.set("v.activeContactNum", business.contacts.length);
    component.set("v.business", business);
    // false/true statement reset the validation on the form
    component.set("v.showContactForm", false);
    component.set("v.showContactForm", true);
  },

  handleUpdateContactLabel: function (component, event, helper) {
    var business = component.get("v.business"),
      activeContact = component.get("v.activeContact"),
      fName = activeContact.firstName === undefined ? "" : activeContact.firstName,
      lName = activeContact.lastName === undefined ? "" : activeContact.lastName;

    activeContact.label = fName + " " + lName;
    business.contacts[business.contacts.indexOf(activeContact)] = activeContact;
    component.set("v.business", business);
  },

  handleRemoveContact: function (component, event, helper) {
    var ele = event.currentTarget,
      contactNum = ele.dataset.contactNumber,
      activeContact = component.get("v.activeContact"),
      business = component.get("v.business");

    // if we are displaying the contact we are destroying
    if (contactNum === parseInt(business.contacts.indexOf(activeContact))) {
      component.set("v.activeContact", {});
      component.set("v.showContactForm", false);
    }
    business.contacts.splice(contactNum, 1);
    component.set("v.business", business);
  },

  handleContinue: function (component, event, helper) {
    var steps = component.get("v.steps"),
      step = component.get("v.currentStep"),
      stepNum = steps.indexOf(step) + 1,
      spinner = component.find("spinner");

    if (helper.formValid(component, stepNum)) {
      spinner.toggle();
      helper
        .createSale(component)
        .then(
          $A.getCallback(function (result) {
            component.set("v.opportunityId", result);
            var evt = $A.get("e.c:Retail_Sales_Tool_OppCreated_Event");
            evt
              .setParams({
                opportunityId: result
              })
              .fire();
          }),
          $A.getCallback(function (err) {
            LightningUtils.errorToast(err);
          })
        )
        .finally(
          $A.getCallback(function () {
            spinner.toggle();
          })
        );
    } else LightningUtils.errorToast("Please fix any errors on the form to continue");
  }
});
