({
  doInit: function (component, event, helper) {
    helper.toggleSpinner(component, "Retrieving Order Details");
    helper
      .doInit(component)
      .then(
        $A.getCallback(() => {}),
        $A.getCallback(() => {})
      )
      .finally(
        $A.getCallback(() => {
          helper.toggleSpinner(component);
        })
      );
  },

  detailToggle: function (component, event, helper) {
    var moreDeets = component.get("v.moreDetails");
    component.set("v.moreDetails", !moreDeets);
  },

  handleAdd: function (component, event, helper) {
    var evt = component.getEvent("actionEvent");
    evt
      .setParams({
        action: "add"
      })
      .fire();
  },

  handleCheckPartnerProgram: function (component, event, helper) {
    helper.toggleSpinner(component, "Calculating Applicable Discounts under the Partner Program");
    helper.checkPartnerProgram(component);
  },

  handleSubmit: function (component, event, helper) {
    var confirmParams = {
      title: "Submit this order?",
      message: "Once this order is submitted it will be locked from further editing!"
    };
    let dealerOrder = component.get("v.dealerOrder");
    let spinnerMessage = dealerOrder.Account__r.Is_Internal__c
      ? "Submitting Order"
      : "Calculating and Applying Applicable Discounts under the Partner Program";

    helper.confirm(component, confirmParams).then(
      $A.getCallback(function () {
        helper.toggleSpinner(component, spinnerMessage);
        if (dealerOrder.Account__r.Is_Internal__c) {
          helper.submitOrder(component);
        } else {
          helper.applyPartnerProgramAndSubmit(component);
        }
      }),
      $A.getCallback(function () {
        return Promise.reject();
      })
    );
  },

  handleDelete: function (component, event, helper) {
    var params = event.getParams(),
      confirmParams = {
        title: "Are you sure?",
        message: "This will permenantly delete the record and can not be undone!"
      };
    helper.confirm(component, confirmParams).then(
      $A.getCallback(function () {
        helper.deleteOrderRow(component, params.groupId, params.itemType);
      }),
      $A.getCallback(function () {
        return false;
      })
    );
  }
});
