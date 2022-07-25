({
  doInit: function (component, event, helper) {
    var accId = component.get("v.accountId"),
      type = component.get("v.AccountType");
    console.log(`registration init accountId = ${accId}`);
    helper.resetCustomer(component);
    helper.fetchContacts(component).then(
      $A.getCallback(function (result) {
        console.log(result);
        component.set("v.salesPeople", result);
        if (accId != null) {
          helper.fetchCustomer(component, accId);
        }
      }),
      $A.getCallback(function (err) {
        LightningUtils.errorToast(err);
      })
    );
  },

  clickRegister: function (component, event, helper) {
    console.log("clickRegister");

    if (helper.formValid(component)) {
      var regSpinner = component.find("registrationSpinner");
      $A.util.toggleClass(regSpinner, "slds-hide");
      helper.createRegistration(component, event, regSpinner);
    }
  },

  cancelRegister: function (component, event, helper) {
    console.log("CANCEL REGISTRATION");
    console.log(component.get("v.regInProcess"));
    component.set("v.serno", "");
    component.set("v.sernoId", "");
    component.set("v.regInProcess", false);
    component.find("lgnd_account_search").set("v.accountList", "");
    document.getElementById("lgnd_registration").classList.add("slds-hide");
    document.getElementById("lgnd_inventory_list").classList.remove("slds-hide");
  },

  handleAccountSelected: function (component, event, helper) {
    var objectId = event.getParams().accountId;
    helper.fetchCustomer(component, objectId);
  },

  handleAccountSearchCleared: function (component, event, helper) {
    helper.resetCustomer(component);
    component.set("v.showAccountForm", false);
  },

  handleCreateAccount: function (component, event, helper) {
    component.set("v.showAccountForm", true);
  },

  toggleProductCard: function (component, event, helper) {
    component.set("v.showProductCard", true);
  },

  remove: function (component, event, helper) {
    if (confirm("Are you sure you want to REMOVE this item?")) {
      alert("TO DO");
    } else {
      e.preventDefault();
    }
  },

  toggleMessage: function (component, event, helper) {
    var err = component.get("v.errorMessage");
    if (err != "") {
      LightningUtils.showToast("error", "Oops", err);
    }
  },

  populateUpgrades: function (component, event, helper) {
    helper.getUpgrades(component);
  },

  toggleMotorDropdown: function (component) {
    $A.util.toggleClass(component.find("MotorDropdown"), "slds-is-open");
  },

  clearUpgrades: function (component) {
    if (!component.get("v.canBeNest")) {
      component.set("v.MotorUpgrades", null);
    }
  },

  selectUpgrade: function (component, event) {
    event.getSource().addClass("slds-is-selected");
  }
});
