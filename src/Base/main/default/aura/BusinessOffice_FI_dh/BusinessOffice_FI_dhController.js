({
  doInit: function (component, event, helper) {
    console.log("BusinessOffice_FI_dhController.doInit");
    helper.fetchFinancialInstitutionOptions(component).then(
      $A.getCallback(function (result) {
        console.log(result.value);
        console.log(result.options);
        component.set("v.institutionOptions", result.options);
        component.set("v.financingInstitution", result.value);
      }),
      $A.getCallback(function (err) {
        LightningUtils.errorToast(err);
      })
    );
  },

  handleChange: function (component, event, helper) {
    component.set("v.isUpdateable", true);
  },

  reInit: function (component, event, helper) {
    console.log("FI reinit");
    var insCMP = component.find("insurance_CMP"),
      finCalcCmp = component.find("finCalc_CMP");
    insCMP.reInit();
    finCalcCmp.reInit();
  },

  reset: function (component, event, helper) {
    $A.get("e.force:refreshView").fire();
  },

  doUpdate: function (component, event, helper) {
    console.log("BusinessOffice_FI_dhController.doUpdate");
    var finCalcCMP = component.find("finCalc_CMP"),
      insuranceCMP = component.find("insurance_CMP");

    helper.toggleSpinner(component);
    helper
      .updateFinancialInstitution(component)
      .then(
        // financial institution update success
        $A.getCallback(function () {
          return insuranceCMP.remoteUpdate();
        }),
        // financial institution update error
        $A.getCallback(function (err) {
          LightningUtils.errorToast(err);
        })
      )
      //Insurance Lines promise
      .then(
        //insurance lines save success
        $A.getCallback(function (r) {
          console.log(r);
          return finCalcCMP.remoteUpdate();
        }),
        //insurance lines save error
        $A.getCallback(function (err) {
          LightningUtils.errorToast(err);
        })
      )
      // fincalc promise
      .then(
        //fincalc update success
        $A.getCallback(function (r) {
          console.log(r);
          helper.toggleSpinner(component);
          component.set("v.isUpdateable", false);
          $A.get("e.force:refreshView").fire();
        }),
        //fincalc update error
        $A.getCallback(function (err) {
          LightningUtils.errorToast(err);
        })
      );
  }
});
