({
  doInit: function (component, event, helper) {
    console.log("+++ doInit +++");
    var self = this;

    helper.initialization(component, event);
  },

  cityChange: function (component, event, helper) {
    console.log("cityChange");
    helper.initCity(component);
  }
});
