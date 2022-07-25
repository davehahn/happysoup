({
  doInit: function (component) {
    this.fetchImages(component).then(
      $A.getCallback(function (result) {
        console.log(result);
        component.set("v.imageList", result);
        $A.util.addClass(component.getElement(), "loaded");
        if (result.length > 0) {
          component.set("v.currentImage", result[0]);
          component.set("v.imageCount", result.length);
        }
      }),
      $A.getCallback(function (err) {
        alert(err);
      })
    );
  },

  fetchImages: function (component) {
    var self = this,
      recordId = component.get("v.recordId"),
      action = component.get("c.fetchAllAssociatedImages");

    action.setParams({
      objId: recordId
    });

    console.log(recordId);

    return new Promise(function (resolve, reject) {
      action.setCallback(self, function (response) {
        var state = response.getState();
        if (state === "SUCCESS") {
          resolve(JSON.parse(response.getReturnValue()));
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
