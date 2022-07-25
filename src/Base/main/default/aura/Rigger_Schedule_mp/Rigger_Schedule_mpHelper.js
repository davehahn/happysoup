({
  initialization: function (component, event) {
    var self = this;
    if (document.getElementsByClassName("cRigger_Schedule_mp")[0] === undefined) {
      setTimeout(function () {
        self.initialization(component, event);
      }, 10);
    } else {
      self.getUserWarehouse(component);

      // Get the base height for all jobs containers.
      var parent = document.getElementsByClassName("cRigger_Schedule_mp")[0],
        topRect = parent.getBoundingClientRect(),
        maxHeight = window.innerHeight - topRect.top - 40,
        containers = document.getElementsByClassName("jobsContainer");

      component.set("v.maxHeight", maxHeight);

      for (var i = 0; i < containers.length; i++) {
        containers[i].style.height = "" + maxHeight + "px";
      }
    }
  },

  getUserWarehouse: function (component) {
    console.log("getUserWarehouse");
    var self = this,
      action = component.get("c.getUserWarehouse");
    return new Promise(function (resolve, reject) {
      self.actionHandler(action, false).then(function (result) {
        component.set("v.city", result);
        resolve();
      });
    });
  },

  initCity: function (component) {
    console.log("initCity");
    var self = this;
    if (component.find("city").get("v.isDoneRendering") && component.find("city").get("v.readyForInit")) {
      component.find("city").doInit();
    } else {
      setTimeout(function () {
        self.initCity(component);
      }, 10);
    }
  },

  actionHandler: function (action, deserialize) {
    console.log("helper.actionHandler");
    var self = this;
    return new Promise(function (resolve, reject) {
      action.setCallback(self, function (response) {
        var state = response.getState();
        console.log(state);
        if (state === "SUCCESS") {
          var result = response.getReturnValue();
          if (typeof result === "string") {
            try {
              result = result.replace(/(\r|\n)/gm, "");
              result = JSON.parse(result);
            } catch (err) {
              //              console.log(err);
            }
          }
          resolve(result);
        }
        if (state === "INCOMPLETE") {
          reject("incomplete");
        }
        if (state === "ERROR") {
          var errors = response.getError();
          if (errors) {
            if (errors[0] && errors[0].message) {
              reject("Error message: " + errors[0].message);
            }
          } else {
            reject("Unknown error");
          }
        }
      });

      $A.enqueueAction(action);
    });
  }
});
