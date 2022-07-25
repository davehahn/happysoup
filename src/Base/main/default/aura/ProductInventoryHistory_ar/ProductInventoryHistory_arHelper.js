({
  runAction: function (component, actionName, params, callback) {
    var action = component.get(actionName);
    action.setParams(params);
    // Register the callback function
    action.setCallback(this, callback);
    // Invoke the service
    $A.enqueueAction(action);
  },
  showToast: function (component, title, type, message) {
    var toastEvent = $A.get("e.force:showToast");
    toastEvent.setParams({
      title: title,
      type: type,
      message: message
    });
    toastEvent.fire();
  },
  toggleSpinner: function (component, value) {
    var spinner = component.find("spinner");
    window.setTimeout(
      $A.getCallback(function () {
        if (value) {
          $A.util.removeClass(spinner, "slds-hide");
        } else {
          $A.util.addClass(spinner, "slds-hide");
        }
      })
    );
  }
});
