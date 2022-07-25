({
  runAction: function (component, actionName, params, callback) {
    var action = component.get(actionName);
    action.setParams(params);

    // Register the callback function
    action.setCallback(this, callback);

    // Invoke the service
    $A.enqueueAction(action);
  },
  retrieveBillingData: function (component, event, helper) {
    helper.toggleSpinner(component, true);
    this.runAction(
      component,
      "c.retrieveInvoices",
      {
        idCMemo: component.get("v.recordId")
      },
      function (response) {
        helper.toggleSpinner(component, false);
        var results = response.getReturnValue();
        if (results == "No") {
          helper.showNotice(component, "Error In BCM", "error", "Not a credit memo.");
          component.get("v.notInvoice", false);
        } else {
          results = JSON.parse(results);
          console.log("results");
          console.log(results);
          component.set("v.billingCM", results.originalBill);
          component.set("v.originalBalance", results.originalBill[0].AcctSeed__Balance__c);
          component.set("v.totalCanBeApplied", parseFloat(results.originalBill[0].AcctSeed__Balance__c) * -1);
          component.set("v.billingCMData", results.allInvoices);
          console.log(component.get("v.originalBalance"));
        }
      }
    );
  },
  sendBCMData: function (component, listData) {
    helper = this;
    helper.toggleSpinner(component, true);
    this.runAction(
      component,
      "c.createBCM",
      {
        idCM: component.get("v.recordId"),
        listData: listData
      },
      function (response) {
        helper.toggleSpinner(component, false);
        var state = response.getState();
        if (state != "SUCCESS") {
          var errors = response.getError();
          console.log(errors);
          if (errors) {
            if (errors[0] && errors[0].message) {
              helper.showNotice(component, "Error In BCM", "error", errors[0].message);
            } else {
              helper.showNotice(
                component,
                "Error In BCM",
                "error",
                "There was an error applying credit memo. Please try again."
              );
            }
            helper.toggleSpinner(component, false);
            return;
          }
        }
        $A.get("e.force:refreshView").fire();
        helper.closeWindow(component);
      }
    );
  },
  amountChanged: function (component, event, helper) {
    var oldAmount = 0;
    var getAllFields = component.find("billAmount");
    if (!Array.isArray(getAllFields)) {
      var $elem = component.find("billAmount");
      oldAmount = $elem.get("v.value");
      if (isNaN(oldAmount)) oldAmount = 0;
    } else {
      for (var i = 0; i < getAllFields.length; i++) {
        var $elem = component.find("billAmount")[i];
        var cVal = $elem.get("v.value");
        if (isNaN(cVal)) cVal = 0;
        oldAmount += parseFloat(cVal);
      }
    }
    if (isNaN(oldAmount)) oldAmount = 0;
    oldAmount = oldAmount * -1;
    component.set("v.totalApplied", oldAmount);
    var canBeApplied = component.get("v.originalBalance");
    if (oldAmount < canBeApplied || oldAmount == 0) {
      component.set("v.totalCanBeApplied", canBeApplied - oldAmount);
      component.set("v.btnDisabled", true);
    } else if (oldAmount != 0) component.set("v.btnDisabled", false);
  },
  closeWindow: function (component) {
    $A.get("e.force:closeQuickAction").fire();
  },
  showToast: function (component, title, type, message) {
    var toastEvent = $A.get("e.force:showToast");
    toastEvent.setParams({
      title: title,
      type: type,
      message: message
    });
    toastEvent.fire();
  },
  showNotice: function (component, title, type, message) {
    component.find("notifLib").showNotice({
      variant: type,
      header: title,
      message: message
    });
  },
  toggleSpinner: function (component, value) {
    var spinner = component.find("spinner");

    window.setTimeout(
      $A.getCallback(function () {
        if (value) {
          $A.util.removeClass(spinner, "slds-hide");
        } else {
          $A.util.addClass(spinner, "slds-hide");
        }
      })
    );
  }
});
