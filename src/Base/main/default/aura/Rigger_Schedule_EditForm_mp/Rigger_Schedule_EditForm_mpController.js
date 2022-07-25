({
  doInit: function (component, event, helper) {
    helper
      .getJob(component)
      .then(
        $A.getCallback(function (wrapper) {
          var job = wrapper.job;
          component.set("v.job", job);
          if (job.Model__r && job.Model__r.Name) component.set("v.title", job.Model__r.Name);
          else if (job.ERP_Order__r && job.ERP_Order__r.Model_Name__c)
            component.set("v.title", job.ERP_Order__r.Model_Name__c);
        }),
        $A.getCallback(function (err) {
          LightningUtils.errorToast(err);
        })
      )
      .finally(
        $A.getCallback(function () {
          component.set("v.loading", false);
        })
      );
  },

  save: function (component, event, helper) {
    helper.saveJob(component);
  },

  saveToBacklog: function (component, event, helper) {
    helper.saveJobToBacklog(component);
  },

  back: function (component, event, helper) {
    component.set("v.selectedJobId", null);
  },

  handleViewRecord: function (compo, event, result) {
    var recordId = event.getSource().get("v.value"),
      evt = $A.get("e.force:navigateToSObject");
    console.log(recordId);
    evt
      .setParams({
        recordId: recordId
      })
      .fire();
  },

  updateJobStatus: function (component, event, helper) {
    var status = component.find("jobStatus").get("v.value");
    component.set("v.job.ERP_Order__r.Job_Status__c", status);
  },

  initializeStatus: function (component, event, helper) {
    var initialValue = component.get("v.job.ERP_Order__r.Job_Status__c"),
      statusElement = component.find("jobStatus");
    statusElement.set("v.value", initialValue);
  }
});
