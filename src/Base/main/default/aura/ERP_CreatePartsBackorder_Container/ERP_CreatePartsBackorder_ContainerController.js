/**
 * Created by dave on 2021-03-29.
 */

({
  doInit: function (component, event, helper) {
    let steps = [
      { buttonLabel: "Next", title: "Select Parts to Back Order", value: 0 },
      { buttonLabel: "Next", title: "What is the Reason for the Back Order", value: 1 },
      { buttonLabel: "Next", title: "Select Parts Request Case(s) to move to Back Order ERP", value: 2 },
      { buttonLabel: "Next", title: "Verify Back Order ERP", value: 3 },
      { buttonLabel: "Finish", title: "Verify Changes to Original ERP", value: 4 }
    ];
    component.set("v.steps", steps);
    component.set("v.currentStep", steps[0]);
  },

  handleInit: function (component, helper, event) {
    const spinner = component.find("spinner");
    spinner.close();
  },

  handleCancel: function (component, event, helper) {
    $A.get("e.force:closeQuickAction").fire();
  },

  handleValidityChange: function (component, event, helper) {
    component.set("v.disableNext", !event.getParam("valid"));
  },

  handleCreateSuccess: function (component, event, helper) {
    const spinner = component.find("spinner");
    spinner.setMessage("Updating Original Order");
  },

  handleNext: function (component, event, helper) {
    let currentStep = component.get("v.currentStep");
    const spinner = component.find("spinner");
    if (currentStep.value === 1) {
      spinner.setMessage("Checking for Parts Request Cases");
    }
    if (currentStep.value === 4) {
      spinner.setMessage("Creating Back Order ERP");
    }
    spinner.toggle();
    const steps = component.get("v.steps");
    helper
      .doNextPromise(component, currentStep.value)
      .then(
        $A.getCallback((response) => {
          if (currentStep.value === 4) {
            $A.get("e.force:closeQuickAction").fire();
            $A.get("e.force:refreshView").fire();
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
              type: "success",
              title: "Success!",
              message: "Back Order created and Original Order Updated Successfully"
            });
            toastEvent.fire();
            return;
          }
          component.set("v.currentStep", steps[response]);
        })
      )
      .catch(
        $A.getCallback((error) => {
          var toastEvent = $A.get("e.force:showToast");
          toastEvent.setParams({
            type: "error",
            title: "Oops, there was an error.",
            message: error
          });
          toastEvent.fire();
        })
      )
      .finally(
        $A.getCallback(() => {
          spinner.close();
        })
      );
  },

  handleBack: function (component) {
    let currentStep = component.get("v.currentStep");
    if (currentStep.value === 0) return;
    const creatorCmp = component.find("backOrderCreator");
    let nextStep = currentStep.value - 1;
    if (nextStep === 2 && !creatorCmp.hasCases()) {
      nextStep--;
    }
    const steps = component.get("v.steps");
    component.set("v.currentStep", steps[nextStep]);
  }
});
