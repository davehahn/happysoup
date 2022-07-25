({
  doInit: function (component, event, helper) {
    console.log("+++ doInit +++");
    helper.init(component);
  },

  setTeamAll: function (component) {
    component.set("v.team", null);
  },

  setTeamProduction: function (component) {
    component.set("v.team", "Production");
  },

  setTeamService: function (component) {
    component.set("v.team", "Service");
  },

  teamChange: function (component, event, helper) {
    helper.refresh(component);
  }
});
