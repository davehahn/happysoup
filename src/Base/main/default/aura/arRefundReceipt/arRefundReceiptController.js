({
  doInit: function (component, event, helper) {
    helper.getOptions(component).then(function () {
      helper.getReceiptAmount(component).then(function () {
        $A.util.addClass(component.find("spinner"), "slds-hide");
        $A.util.removeClass(component.find("form"), "slds-hide");
        helper.validate(component, event, helper);
      });
    });
  },

  processRefund: function (component, event, helper) {
    helper.toggleSpinner(component, true);
    var action = component.get("c.handleRefund"),
      crId = component.get("v.recordId"),
      cdType = component.get("v.cdType"),
      refundFrom = component.get("v.refundFrom"),
      refundAmount = component.get("v.refundAmount"),
      navEvt = $A.get("e.force:navigateToSObject"),
      receiptData = component.get("v.receiptData");

    var refundFromAmount = 0;
    if (refundFrom == "Balance") refundFromAmount = receiptData.AcctSeed__Balance__c;
    else refundFromAmount = receiptData.AcctSeed__Amount__c;

    if (refundAmount > refundFromAmount || isNaN(refundAmount)) {
      helper.showToast(component, "Error", "error", "Refund amount must be less than " + refundFrom);
      // component.set('v.btnDisabled', true);
      helper.toggleSpinner(component, false);
      return;
    }

    helper.runAction(
      component,
      "c.handleRefund",
      {
        crId: crId,
        paymentMethod: cdType,
        refundFrom: refundFrom,
        refundAmount: refundAmount
      },
      function (response) {
        var state = response.getState();
        if (state != "SUCCESS") {
          var errors = response.getError();

          if (errors) {
            console.log(errors);
            if (errors[0] && errors[0].message) {
              helper.showToast(component, "Error In Refund", "error", errors[0].message);
            } else {
              helper.showToast(component, "Error In Refund", "error", "There was an error creating refund");
            }
            helper.toggleSpinner(component, false);
            return;
          }
        }
        var results = response.getReturnValue();
        helper.toggleSpinner(component, false);
        navEvt.setParams({
          recordId: results,
          slideDevName: "related"
        });
        navEvt.fire();
      }
    );
  },

  resetRefundAmount: function (component, event, helper) {
    var receiptData = component.get("v.receiptData"),
      refundFrom = component.get("v.refundFrom");
    if (refundFrom == "Balance") {
      component.set("v.refundAmount", receiptData.AcctSeed__Balance__c);
    } else {
      component.set("v.refundAmount", receiptData.AcctSeed__Amount__c);
    }
    helper.validate(component, event, helper);
  },

  validate: function (component, event, helper) {
    helper.validate(component, event, helper);
  }
});
