({
  doInit: function (component) {
    var steps = [
      "Select Account",
      "Select Serial Number",
      "Enter Problems",
      "Prepaid Service Redemption",
      "Additional Notes"
    ];
    component.set("v.steps", steps);
    component.set("v.currentStep", steps[0]);
    component.set("v.tasks", []);
  },

  afterScripts: function (component, event, helper) {
    helper.initNewService(component).then(
      $A.getCallback(function (result) {
        component.set("v.taskNameOptions", result.taskNames);
        component.set("v.warehouseOptions", result.warehouses);
        component.set("v.warehouseId", result.userWarehouse);
        component.set("v.riggers", result.riggers);
        component.set("v.parkingSpotOptions", result.parkingSpots);
        component.getEvent("ModalLoaded").fire();
      }),
      $A.getCallback(function (err) {
        LightningUtils.errorToast(err);
      })
    );
  },

  handleCancel: function (component) {
    component.getEvent("CloseModal").fire();
  },

  handleStepBack: function (component) {
    console.log(component.get("v.currentStep"));
    var steps = component.get("v.steps"),
      cStep = component.get("v.currentStep");
    component.set("v.currentStep", steps[steps.indexOf(cStep) - 1]);
  },

  handleStepNext: function (component, event, helper) {
    var steps = component.get("v.steps"),
      cStep = component.get("v.currentStep");
    if (steps.indexOf(cStep) === 2) helper.createPrepaidTasks(component);
    if (steps.indexOf(cStep) === 3) helper.storeTask(component);
    component.set("v.currentStep", steps[steps.indexOf(cStep) + 1]);
  },

  handleCreate: function (component, event, helper) {
    $A.util.removeClass(component.find("spinner"), "slds-hide");
    helper.saveService(component).then(
      $A.getCallback(function () {
        LightningUtils.showToast("success", "Success!", "The record was successfully updated");
        component.getEvent("UpdateSuccess").fire();
        console.log("event seemed to update");
      }),
      $A.getCallback(function (err) {
        $A.util.addClass(component.find("spinner"), "slds-hide");
        LightningUtils.errorToast(err);
      })
    );
  },

  handleAccountSelected: function (component, event, helper) {
    var accountId = event.getParam("accountId"),
      accountName = event.getParam("accountName"),
      cStep = component.get("v.currentStep"),
      steps = component.get("v.steps");

    component.set("v.accountId", accountId);
    component.set("v.accountName", accountName);
    component.set("v.currentStep", steps[steps.indexOf(cStep) + 1]);
    helper.getPrepaidsOnAccount(component).then(
      $A.getCallback(function (results) {
        for (var i = 0; i < results.length; i++) {
          results[i].toredeem = 0;
        }
        component.set("v.prepaids", results);
      }),
      $A.getCallback(function (err) {
        //
      })
    );
  },

  clearAccount: function (component, event, helper) {
    var steps = component.get("v.steps");
    component.set("v.accountId", null);
    component.set("v.accountName", null);
    component.set("v.serialId", null);
    component.set("v.serialNumber", null);
    component.set("v.currentStep", steps[0]);
  },

  clearSerial: function (component, event, helper) {
    var steps = component.get("v.steps");
    component.set("v.serialId", null);
    component.set("v.serialNumber", null);
    component.set("v.currentStep", steps[1]);
  },

  handleRemoveTask: function (component, event) {
    var tasks = component.get("v.tasks"),
      taskNumber = event.currentTarget.dataset.taskNumber;
    tasks.splice(taskNumber - 1, 1);
    //fix the numbers
    for (var i = 0; i < tasks.length; i++) {
      tasks[i].number = i + 1;
    }
    console.log("taskNumber = " + taskNumber);
    console.log("component taskNumber = " + component.get("v.currentTaskNumber"));
    if (taskNumber == component.get("v.currentTaskNumber")) {
      component.set("v.currentTaskName", null);
      component.set("v.currentTaskNumber", null);
      component.set("v.currentTaskTimeEstimate", null);
      component.set("v.currentTaskComplaint", null);
    }
    component.set("v.tasks", tasks);
  },

  handleAddAnotherTask: function (component, event, helper) {
    helper.storeTask(component);
  },

  handleTaskClick: function (component, event, helper) {
    var ele = event.currentTarget,
      number = ele.dataset.taskNumber,
      tasks = component.get("v.tasks"),
      task = tasks[number - 1],
      pills = component.find("task-pill");

    if (pills.length !== undefined) {
      for (let p of pills) {
        var e = p.getElement();
        e.classList.remove("selected");
      }
    }

    ele.parentNode.classList.add("selected");
    component.set("v.currentTaskName", task.name);
    component.set("v.currentTaskNumber", task.number);
    component.set("v.currentTaskTimeEstimate", task.estimate);
    component.set("v.currentTaskComplaint", task.complaint);
  },

  updateDurationEstimate: function (component) {
    var tasks = component.get("v.tasks"),
      est = 0;
    for (let t of tasks) {
      est += parseFloat(t.estimate);
    }
    component.set("v.estimatedDuration", est);
  },

  taskNameChanged: function (component) {
    console.log(component.get("v.currentTaskName"));
  },

  complaintChanged: function (component) {
    console.log(component.get("v.currentTaskComplaint"));
  },

  warehouseChanged: function (component, event, helper) {
    var warehouseId = component.get("v.warehouseId");
    if (warehouseId != null && warehouseId != "") {
      helper.getRiggers(component).then(
        $A.getCallback(function (result) {
          component.set("v.riggers", result);
        }),
        $A.getCallback(function (err) {
          $A.util.addClass(component.find("spinner"), "slds-hide");
          LightningUtils.errorToast(err);
        })
      );
    }
  },

  taskSearch: function (component, event, helper) {
    var combobox = component.find("task_combobox"),
      query = component.get("v.currentTaskName"),
      options = component.get("v.taskNameOptions"),
      originals = component.get("v.originalTaskNameOptions"),
      results = [];

    console.log(options);
    console.log(originals);

    if (originals == undefined || originals == null || originals.length < 1) {
      component.set("v.originalTaskNameOptions", options);
    }

    if (query.length > 2) {
      for (var i = 0; i < options.length; i++) {
        if (options[i].includes(query)) {
          results.push(options[i]);
        }
      }
    } else {
      results = originals;
    }

    component.set("v.taskNameOptions", results);

    if (results.length > 0) {
      helper.toggle(combobox, "open");
    } else {
      helper.toggle(combobox, "close");
    }
  },

  clickTaskName: function (component, event, helper) {
    var selectedItem = event.currentTarget,
      taskName = selectedItem.dataset.name,
      combobox = component.find("task_combobox");

    component.set("v.currentTaskName", taskName);

    helper.toggle(combobox, "close");
  }
});
