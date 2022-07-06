({
  getCompletedJobs: function (component) {
    component.set("v.lockCompleted", true);
    var self = this,
      warehouse = component.get("v.city"),
      action = component.get("c.getCompletedJobs"),
      la,
      search = component.get("v.completedSearch");
    action.setParams({
      warehouse: warehouse,
      search: search
    });
    la = new LightningApex(this, action);
    return new Promise(function (resolve, reject) {
      la.fire().then(
        $A.getCallback(function (jobs) {
          for (var j of jobs) {
            if (j.job.Employee__c != null) {
              if (j.job.Employee__r.User__r.FirstName === undefined || j.job.Employee__r.User__r.FirstName == null) {
                j.job.initials = j.job.Employee__r.User__r.LastName.substr(0, 2);
              } else {
                j.job.initials =
                  j.job.Employee__r.User__r.FirstName.substr(0, 1) + j.job.Employee__r.User__r.LastName.substr(0, 1);
              }
            }
            if (j.materials) {
              for (var m of j.materials) {
                if (m.AcctSeedERP__Product__c != null && m.AcctSeedERP__Product__r.Family == "Canvas") {
                  if (j.materialsText == undefined) {
                    j.materialsText = m.Product_Name__c;
                  } else {
                    j.materialsText += "; " + m.Product_Name__c;
                  }
                }
                if (m.Product_Record_Type__c != null && m.Product_Record_Type__c == "Boat") {
                  j.job.Manufactured_Product_Name__c = m.Product_Name__c;
                }
              }
            }
          }
          component.set("v.jobs", jobs);
          jobs = component.get("v.jobs");
          component.set("v.completedJobsCount", jobs.length);
          component.set("v.lockCompleted", false);
          resolve();
        }),
        $A.getCallback(function (err) {
          component.set("v.lockCompleted", false);
          LightningUtils.errorToast(err);
        })
      );
    });
  },

  assignJob: function (component, event) {
    var self = this,
      action = component.get("c.assignJob"),
      la,
      jobId = component.get("v.draggedItemId");
    return new Promise(function (resolve, reject) {
      action.setParams({
        riggerId: "done",
        jobId: jobId
      });
      la = new LightningApex(this, action);
      la.fire().then(
        $A.getCallback(function () {
          $A.get("e.c:Rigging_ItemDropped_Event").fire();
        }),
        $A.getCallback(function (err) {
          LightningUtils.errorToast(err);
        })
      );
    });
  }
});
