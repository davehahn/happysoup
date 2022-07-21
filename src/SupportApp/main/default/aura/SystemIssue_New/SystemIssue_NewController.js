/**
 * Created by dave on 2020-01-02.
 */

({
  doInit: function (component, event, helper) {
    var spinner = component.find("spinner");

    helper
      .doInit(component)
      .then(
        $A.getCallback(function (result) {
          console.log(result);
          component.set("v.issueTypesByProject", result.issueTypesByProject);
          component.set("v.priorityOptions", result.priorityOptions);
          component.set("v.jiraProjectOptions", result.jiraProjectOptions);
          let dOpts = [];
          for (let dOpt of result.departmentOptions) {
            dOpts.push({
              label: dOpt,
              value: dOpt
            });
          }
          component.set("v.departmentOptions", dOpts);
          component.set("v.loaded", true);
        }),
        $A.getCallback(function (err) {
          LightningUtils.errorToast(err);
          helper.doCancel(component);
        })
      )
      .finally(
        $A.getCallback(function () {
          //spinner.toggle();
        })
      );
  },

  handleNav: function (component, event, helper) {
    component.set("v.currentStep", event.getSource().get("v.value"));
  },

  handleJiraProjectChange: function (component, event, helper) {
    const issueTypesByProject = component.get("v.issueTypesByProject");
    const proj = event.getSource().get("v.value");
    let issue = component.get("v.issue");
    issue.Type__c = null;
    component.set("v.issue", issue);
    console.log(proj);
    if (Object.keys(issueTypesByProject).indexOf(proj >= 0)) {
      component.set("v.typeOptions", issueTypesByProject[proj]);
    }
    component.set("v.formValid", helper.isFormValid(component));
  },

  checkValidity: function (component, event, helper) {
    component.set("v.formValid", helper.isFormValid(component));
  },

  handleCancel: function (component, event, helper) {
    helper.doCancel(component);
  },

  handleSubmit: function (component, event, helper) {
    var spinner = component.find("spinner");
    spinner.toggle();
    helper
      .doSubmit(component)
      .then(
        $A.getCallback(function (result) {
          component.set("v.issue", result);
          component.set("v.currentStep", "three");
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
  },

  handleFileUploadSuccess: function (component, event, helper) {
    var files = event.getParam("files");
    console.log(JSON.parse(JSON.stringify(files)));
    component.set("v.uploadedFiles", files);
  },

  handleFinish: function (component) {
    var navEvt = $A.get("e.force:navigateToSObject");
    navEvt
      .setParams({
        recordId: component.get("v.issue").Id
      })
      .fire();
  }
});
