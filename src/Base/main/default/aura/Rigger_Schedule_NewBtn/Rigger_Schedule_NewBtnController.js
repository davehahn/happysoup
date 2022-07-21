({
  doInit: function (component, event, helper) {
    var job;
    helper.checkForExistingJob(component).then(
      $A.getCallback(function (response) {
        console.log(response);
        if (response.length > 0) {
          job = response[0];
          if (job.Employee__c == null) {
            job.Employee__r = {};
            job.Employee__r.Name = "No One";
          }
          if (job.ERP_Order__r.Job_Status__c == undefined) {
            job.ERP_Order__r.Job_Status__c = "Unassigned";
          }
          component.set("v.job", job);
          if (job.ERP_Order__r.Job_Status__c == "Unassigned" && job.Employee__r.Name == "No One") {
            component.set("v.state", "backlog");
          } else {
            component.set("v.state", "exists");
          }
        } else {
          helper.createJob(component);
        }
      }),
      $A.getCallback(function (err) {
        LightningUtils.errorToast(err);
      })
    );
  },

  sendJobBack: function (component, event, helper) {
    component.set("v.state", null);
    helper.returnJobToBacklog(component);
  }
});
