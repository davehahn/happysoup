({
  doInit: function (component, event, helper) {
    var lists = component.get("v.listNames"),
      opts;
    if (lists !== undefined) {
      opts = lists.split(",");
      component.set("v.selectedList", opts[0].split(":")[0]);
      component.set("v.availableLists", opts);
      component.find("listSelector--Cmp").doInit();
    }
  },

  navigateToNew: function (component) {
    var urlEvent = $A.get("e.force:navigateToURL"),
      url = component.get("v.newURL");
    urlEvent.setParams({
      url: url
    });
    urlEvent.fire();
  }
});
