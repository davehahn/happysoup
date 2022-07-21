({
  doInit: function (component, event, helper) {
    console.log("promotion details init");
    helper.getClaimDetails(component).then(
      $A.getCallback(function (result) {
        component.set("v.claim", result);
        component.set("v.AccountId", result.Promotion_Customer_Account__c);
      })
    );
  },

  btnClick: function (component, event, helper) {
    var final_destination = event.getSource().get("v.value");

    $A.get("e.force:navigateToSObject")
      .setParams({
        recordId: final_destination
      })
      .fire();
  },

  handleRegistrationSuccess: function (component, event, helper) {
    console.log("registration success");
    helper
      .getClaimDetails(component)
      .then(
        $A.getCallback(function (result) {
          console.log("getClaimDetailsResult");
          console.log(JSON.parse(JSON.stringify(result)));
          component.set("v.claim", result);
          component.set("v.AccountId", result.Promotion_Customer_Account__c);
        })
      )
      .catch(
        $A.getCallback(function (error) {
          LightningUtils.errorToast(error);
        })
      );
  }
});
