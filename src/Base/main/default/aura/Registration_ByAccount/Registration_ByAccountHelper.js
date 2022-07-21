/**
 * Created by dave on 2019-09-04.
 */

({
  doInit: function (component) {
    console.log("helper.doInit");
    var self = this;
    self
      .fetchRegistrations(component)
      .then(
        $A.getCallback(function (result) {
          console.log(JSON.parse(JSON.stringify(result)));
          self.handleResult(component, result);
        }),
        $A.getCallback(function (err) {
          LightningUtils.errorToast(err);
        })
      )
      .finally($A.getCallback(function () {}));
  },

  fetchRegistrations: function (component) {
    var action = component.get("c.fetchRegistrations");
    action.setParams({
      registeredByAccountId: component.get("v.recordId")
    });
    return new LightningApex(this, action).fire();
  },

  handleResult: function (component, result) {
    var options = [],
      selectedYear = new Date().getFullYear();
    for (let k of Object.keys(result)) {
      options.push({
        label: k + " - ( " + result[k].length + " Registrations )",
        value: k
      });
    }
    component.set("v.yearOptions", options);
    component.set("v.selectedYear", selectedYear);
    component.set("v.regData", result);
    component.set("v.mapMarkers", result[selectedYear]);
  }
});
