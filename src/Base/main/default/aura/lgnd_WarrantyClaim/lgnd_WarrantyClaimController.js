({
  doInit: function (component, event, helper) {
    var action = component.get("c.initData");
    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        var result = JSON.parse(response.getReturnValue());
        console.log(result);
        component.set("v.userName", result.userName);
        component.set("v.userEmail", result.userEmail);
        component.set("v.claimTypeOptions", result.claimTypeOptions);
        //component.set('v.typeOptions', result.typeOptions);
        //component.set('v.reasonOptions', result.reasonOptions );
        //component.set('v.priorityOptions', result.priorityOptions );
        component.set("v.contactId", result.userId);
        //component.set('v.fileList', []);
      }
      //else if (cmp.isValid() && state === "INCOMPLETE") {
      else if (state === "INCOMPLETE") {
        // do something
        console.log("incomplete");
      }
      //else if (cmp.isValid() && state === "ERROR") {
      else if (state === "ERROR") {
        var errors = response.getError();
        if (errors) {
          if (errors[0] && errors[0].message) {
            console.log("Error message: " + errors[0].message);
          }
        } else {
          console.log("Unknown error");
        }
      }
    });
    $A.enqueueAction(action);
  },

  validateStepOne: function (component, event, helper) {
    helper.isStepOneValid(component);
  },

  checkValidity: function (component, event, helper) {
    component.set("v.stepTwoValid", helper.isFormValid(component));
  },

  fetchSerialDetails: function (component, event, helper) {
    helper.isStepOneValid(component);
    var serialId = event.getParam("value");
    if (serialId !== undefined && serialId.length > 0) {
      helper.fetchSerial(component, serialId).then(
        $A.getCallback(function (result) {
          console.log(result);
          component.set("v.serialProductName", result.Product_Name__c);
          result.GMBLASERP__Lot__r === undefined
            ? component.set("v.serialProductYear", "")
            : component.set("v.serialProductYear", result.GMBLASERP__Lot__r.Name);
        }),
        $A.getCallback(function (err) {
          alert(err);
        })
      );
    }
  },

  submitCase: function (component, event, helper) {
    // console.log( component.get('v.fileList') );
    // return false;
    var data = {
        // 'url': component.get('v.url'),
        // 'orgid': component.get('v.orgId'),
        contactId: component.get("v.contactId"),
        name: component.get("v.userName"),
        email: component.get("v.userEmail"),
        //'caseType': component.get('v.type'),
        //'reason': component.get('v.reason'),
        //'priority': component.get('v.priority'),
        subject: component.get("v.subject"),
        description: component.get("v.description"),
        claimType: component.get("v.claimType"),
        failureDate: component.get("v.failureDate"),
        serialId: component.get("v.serialNumberId"),
        accountId: component.get("v.accountId"),
        recordTypeName: "Warranty"
      },
      action = component.get("c.saveTheCase"),
      indicator = component.find("busy-indicator");

    $A.util.toggleClass(indicator, "hidden");

    action.setParams({
      jsonData: JSON.stringify(data)
    });

    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        var result = JSON.parse(response.getReturnValue());
        component.set("v.caseId", result.Id);
        //component.set('v.erpId', result.Warranty_ERP__c );
        helper.caseCreateComplete(component);
      }
      //else if (cmp.isValid() && state === "INCOMPLETE") {
      else if (state === "INCOMPLETE") {
        // do something
        console.log("incomplete");
        component.set("v.toastContent", { type: "error", message: "Incomplete" });
        $A.util.toggleClass(indicator, "hidden");
      }
      //else if (cmp.isValid() && state === "ERROR") {
      else if (state === "ERROR") {
        var errors = response.getError();
        if (errors) {
          if (errors[0] && errors[0].message) {
            console.log("Error message: " + errors[0].message);
          }
        } else {
          console.log("Unknown error");
          component.set("v.toastContent", { type: "error", message: "Error encountered" });
          $A.util.toggleClass(indicator, "hidden");
        }
      }
    });
    $A.enqueueAction(action);
  },

  resetForm: function (component, event, helper) {
    helper.resetForm(component);
  },

  goToGallery: function (component, event, helper) {
    var caseId = component.get("v.caseId");
    helper.resetForm(component);
    $A.get("e.force:navigateToURL")
      .setParams({
        url: "/apex/LegendImageGallery_Add?id=" + caseId
      })
      .fire();
  },

  // goToERP: function( component, event, helper )
  // {
  //   var erpId = component.get('v.erpId');
  //   helper.resetForm( component );
  //   $A.get("e.force:navigateToSObject")
  //   .setParams({
  //     recordId: erpId
  //   })
  //   .fire();
  // },

  goToStepTwo: function (component, event, helper) {
    component.set("v.currentStep", 2);
    //console.log( component.get('v.serialNumberId') );
  },

  goBackToStepOne: function (component) {
    component.set("v.currentStep", 1);
  }
});
