({
  getRiggers: function (component) {
    var self = this,
      warehouse = component.get("v.city"),
      team = component.get("v.team"),
      action = component.get("c.getRiggers"),
      la;
    action.setParams({
      warehouse: warehouse,
      team: team
    });
    la = new LightningApex(this, action);
    return new Promise(function (resolve, reject) {
      la.fire().then(
        $A.getCallback(function (riggers) {
          component.set("v.riggers", riggers);
          resolve();
        }),
        $A.getCallback(function (err) {
          LightningUtils.errorToast(err);
        })
      );
    });
  },

  getJobs: function (component) {
    var self = this;
    return new Promise(function (resolve, reject) {
      self.getUnassignedJobs(component);
      // self.getCompletedJobs(component);
      resolve();
    });
  },

  getUnassignedJobs: function (component) {
    var self = this,
      action = component.get("c.getUnassignedJobs"),
      la,
      filter = component.get("v.selectedBacklogFilter"),
      search = component.get("v.backlogSearch"),
      search2 = component.get("v.backlogSearch2"),
      city = component.get("v.city"),
      limitToCity = component.get("v.limitToCity");
    action.setParams({
      filter: filter,
      city: city,
      limitToCity: limitToCity
    });
    la = new LightningApex(this, action);
    return new Promise(function (resolve, reject) {
      la.fire().then(
        $A.getCallback(function (jobs) {
          // Formatting and prep
          for (j of jobs) {
            j.job.CreatedDate = j.job.CreatedDate.substr(0, 10);

            if (j.job.DueDate__c) j.job.age = self.daysBetween(new Date(), j.job.DueDate__c);
            else j.job.age = null;

            if (j.job.Placeholder__c) j.job.class = "slds-box dragItem placeholder";
            else if (j.job.age > -1) j.job.class = "slds-box dragItem dueLater";
            else if (j.job.age == -1) j.job.class = "slds-box dragItem dueToday";
            else if (j.job.age < -1) j.job.class = "slds-box dragItem dueDateMissed";
            else j.job.class = "slds-box dragItem";

            if (j.materials) {
              for (m of j.materials) {
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

            if (j.job.ERP_Order__c !== undefined) {
              if (j.job.ERP_Order__r.Delivery_Date__c != null) {
                j.job.ERP_Order__r.Delivery_Date__c = j.job.ERP_Order__r.Delivery_Date__c.substr(0, 10);
              }
            }
          }
          component.set("v.backlogged_jobs", jobs);
          component.set("v.backlogged_results", jobs);
          resolve();
        }),
        $A.getCallback(function (err) {
          LightningUtils.errorToast(err);
        })
      );
    });
  },

  getCompletedJobs: function (component) {
    component.set("v.completed_jobs", null);
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
          for (j of jobs) {
            if (j.job.Employee__c != null) {
              j.job.initials =
                j.job.Employee__r.User__r.FirstName.substr(0, 1) + j.job.Employee__r.User__r.LastName.substr(0, 1);
            }
            if (j.materials) {
              for (m of j.materials) {
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
          component.set("v.completed_jobs", jobs);
          jobs = component.get("v.completed_jobs");
          resolve();
        }),
        $A.getCallback(function (err) {
          LightningUtils.errorToast(err);
        })
      );
    });
  },

  assignJob: function (component, event, riggerId) {
    var self = this,
      action = component.get("c.assignJob"),
      la,
      jobId = component.get("v.draggedItemId"),
      data = event.dataTransfer.getData("text");
    if (riggerId == "done") {
      component.set("v.lockCompleted", true);
    }
    action.setParams({
      riggerId: riggerId,
      jobId: jobId
    });
    la = new LightningApex(this, action);
    la.fire().then(
      $A.getCallback(function () {
        $A.get("e.c:Rigging_ItemDropped_Event")
          .setParams({
            riggerId: riggerId
          })
          .fire();
      }),
      $A.getCallback(function (err) {
        LightningUtils.errorToast(err);
      })
    );
  },

  backlogSearch: function (component, event) {
    component.set("v.backlogged_results", null);
    var self = this,
      backlog = component.get("v.backlogged_jobs"),
      search1 = component.get("v.backlogSearch"),
      search2 = component.get("v.backlogSearch2"),
      results = [],
      results2 = [];
    try {
      if ((search1 == null || search1 == "") && (search2 == null || search2 == "")) {
        results2 = backlog;
      } else {
        backlog.forEach(function (j) {
          if (j.hasOwnProperty("job")) {
            if (
              j.job.Manufactured_Product_Name__c != null &&
              j.job.Manufactured_Product_Name__c.indexOf(search1) > -1
            ) {
              results.push(j);
            } else if (j.job.hasOwnProperty("ERP_Order__r")) {
              if (j.job.ERP_Order__r.Model_Name__c != null && j.job.ERP_Order__r.Model_Name__c.indexOf(search1) > -1) {
                results.push(j);
              } else if (
                j.job.ERP_Order__r.Serial_Product__c != null &&
                j.job.ERP_Order__r.Serial_Product__c.indexOf(search1) > -1
              ) {
                results.push(j);
              } else if (
                j.job.ERP_Order__r.Manufactured_Product_Name__c != null &&
                j.job.ERP_Order__r.Manufactured_Product_Name__c.indexOf(search1) > -1
              ) {
                results.push(j);
              } else if (
                j.job.ERP_Order__r.AcctSeedERP__Manufactured_Product__r != undefined &&
                j.job.ERP_Order__r.AcctSeedERP__Manufactured_Product__r.Name != null &&
                j.job.ERP_Order__r.AcctSeedERP__Manufactured_Product__r.Name.indexOf(search1)
              ) {
                results.push(j);
              } else if (
                j.job.ERP_Order__r.AcctSeed__Account__r != null &&
                j.job.ERP_Order__r.AcctSeed__Account__r.Name != null &&
                j.job.ERP_Order__r.AcctSeed__Account__r.Name.indexOf(search1) > -1
              ) {
                results.push(j);
              } else if (
                j.job.ERP_Order__r.Serial_Number__r != null &&
                j.job.ERP_Order__r.Serial_Number__r.Name != null &&
                j.job.ERP_Order__r.Serial_Number__r.Name.indexOf(search1) > -1
              ) {
                results.push(j);
              } else if (
                j.job.ERP_Order__r.AcctSeedERP__Work_Order_Number__c != null &&
                j.job.ERP_Order__r.AcctSeedERP__Work_Order_Number__c.indexOf(search1) > -1
              ) {
                results.push(j);
              }
            }
          }
        });
        if (search2 == null || search2 == "") {
          results2 = results;
        } else {
          if (results.length < 1) {
            results = backlog;
          }
          results.forEach(function (j) {
            if (j.hasOwnProperty("job")) {
              if (
                j.job.Manufactured_Product_Name__c != null &&
                j.job.Manufactured_Product_Name__c.indexOf(search2) > -1
              ) {
                results2.push(j);
              } else if (j.job.hasOwnProperty("ERP_Order__r")) {
                if (
                  j.job.ERP_Order__r.Model_Name__c != null &&
                  j.job.ERP_Order__r.Model_Name__c.indexOf(search2) > -1
                ) {
                  results2.push(j);
                } else if (
                  j.job.ERP_Order__r.Serial_Product__c != null &&
                  j.job.ERP_Order__r.Serial_Product__c.indexOf(search2) > -1
                ) {
                  results2.push(j);
                } else if (
                  j.job.ERP_Order__r.Manufactured_Product_Name__c != null &&
                  j.job.ERP_Order__r.Manufactured_Product_Name__c.indexOf(search2) > -1
                ) {
                  results2.push(j);
                } else if (
                  j.job.ERP_Order__r.AcctSeedERP__Manufactured_Product__r != undefined &&
                  j.job.ERP_Order__r.AcctSeedERP__Manufactured_Product__r.Name != null &&
                  j.job.ERP_Order__r.AcctSeedERP__Manufactured_Product__r.Name.indexOf(search2)
                ) {
                  results2.push(j);
                } else if (
                  j.job.ERP_Order__r.AcctSeed__Account__r != null &&
                  j.job.ERP_Order__r.AcctSeed__Account__r.Name != null &&
                  j.job.ERP_Order__r.AcctSeed__Account__r.Name.indexOf(search2) > -1
                ) {
                  results2.push(j);
                } else if (
                  j.job.ERP_Order__r.Serial_Number__r != null &&
                  j.job.ERP_Order__r.Serial_Number__r.Name != null &&
                  j.job.ERP_Order__r.Serial_Number__r.Name.indexOf(search2) > -1
                ) {
                  results2.push(j);
                } else if (
                  j.job.ERP_Order__r.AcctSeedERP__Work_Order_Number__c != null &&
                  j.job.ERP_Order__r.AcctSeedERP__Work_Order_Number__c.indexOf(search2) > -1
                ) {
                  results2.push(j);
                }
              }
            }
          });
        }
      }
      component.set("v.backlogged_results", results2);
    } catch (e) {}
  },

  handleSearch: function (component) {
    var self = this,
      locked = component.get("v.lockSearch"),
      inputBox = component.find("backlogSearchInput"),
      query = component.get("v.backlogSearch"),
      query2;
    self.findJobs(component).then(
      $A.getCallback(function (result) {
        component.set("v.lockSearch", false);
        query2 = component.get("v.backlogSearch");
        if (query != query2) {
          self.handleSearch(component);
        }
      }),
      $A.getCallback(function (err) {
        component.set("v.lockSearch", false);
        LightningUtils.errorToast(err);
      })
    );
  },

  findJobs: function (component) {
    return new Promise(function (resolve, reject) {
      var action = component.get("c.findJobs"),
        la,
        query = component.get("v.backlogSearch"),
        keywords = [],
        cleanwords = [],
        filter = component.get("v.selectedBacklogFilter"),
        city = component.get("v.city"),
        limitToCity = component.get("v.limitToCity");
      keywords = query.match(/[^\s"]+|"([^"]*)"/gi);
      if (keywords == null) return;
      keywords.forEach(function (kw) {
        cleanwords.push(kw.replace(/^"(.*)"$/, "$1"));
      });
      action.setParams({
        keywords: cleanwords,
        filter: filter,
        city: city,
        limitToCity: limitToCity
      });
      la = new LightningApex(this, action);
      la.fire().then(
        $A.getCallback(function (jobs) {
          for (j of jobs) {
            j.job.CreatedDate = j.job.CreatedDate.substr(0, 10);

            if (j.job.DueDate__c) j.job.age = self.daysBetween(new Date(), j.job.DueDate__c);
            else j.job.age = null;

            if (j.job.Placeholder__c) j.job.class = "slds-box dragItem placeholder";
            else if (j.job.age > -1) j.job.class = "slds-box dragItem dueLater";
            else if (j.job.age == -1) j.job.class = "slds-box dragItem dueToday";
            else if (j.job.age < -1) j.job.class = "slds-box dragItem dueDateMissed";
            else j.job.class = "slds-box dragItem";

            if (j.materials) {
              for (m of j.materials) {
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
          component.set("v.backlogged_jobs", jobs);
          component.set("v.backlogged_results", jobs);
          resolve();
        }),
        $A.getCallback(function (err) {
          LightningUtils.errorToast(err);
          reject();
        })
      );
    });
  },

  treatAsUTC: function (date) {
    var result = new Date(date);
    result.setMinutes(result.getMinutes() - result.getTimezoneOffset());
    return result;
  },

  daysBetween: function (startDate, endDate) {
    var self = this,
      millisecondsPerDay = 24 * 60 * 60 * 1000;
    return Math.round((self.treatAsUTC(endDate) - self.treatAsUTC(startDate)) / millisecondsPerDay);
  }
});
