({
  doInit: function (component, event, helper) {
    helper.doInit(component).then(
      $A.getCallback(function (result) {
        component.set("v.priorityOptions", result.priorityOptions);
        component.set("v.jiraProjectOptions", result.jiraProjectOptions);
      }),
      $A.getCallback(function (err) {
        LightningUtils.errorToast(err);
      })
    );
  },

  handleNav: function (component, event, helper) {
    component.set("v.currentStep", event.getSource().get("v.value"));
  },

  checkValidity: function (component, event, helper) {
    component.set("v.formValid", helper.isFormValid(component));
  },

  submitCase: function (component, event, helper) {
    var indicator = component.find("busy-indicator");
    $A.util.toggleClass(indicator, "hidden");
    helper
      .submitCase(component)
      .then(
        $A.getCallback(function (result) {
          component.set("v.caseId", result.Id);
          component.set("v.currentStep", "three");
        }),
        $A.getCallback(function (err) {
          LightningUtils.errorToast(err);
        })
      )
      .finally(
        $A.getCallback(function () {
          $A.util.toggleClass(indicator, "hidden");
        })
      );
  },

  handleFileUploadSuccess: function (component, event, helper) {
    var files = event.getParam("files");
    console.log(JSON.parse(JSON.stringify(files)));
    component.set("v.uploadedFiles", files);
  },

  handleFinish: function (component, event, helper) {
    helper.caseCreateComplete(component);
  }
});
