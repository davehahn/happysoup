/**
 * Created by dave on 2019-09-04.
 */

({
  doInit: function (component, event, helper) {
    helper.doInit(component);
  },

  handleYearSelect: function (component, event, helper) {
    var year = component.get("v.selectedYear"),
      options = component.get("v.regData");

    component.set("v.mapMarkers", options[year]);
  }
});
