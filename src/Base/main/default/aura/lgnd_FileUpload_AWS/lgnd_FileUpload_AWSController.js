({
  doInit: function (component, event, helper) {
    var device = $A.get("$Browser.formFactor"),
      isMobile = device === "DESKTOP" ? false : true;
    component.set("v.isMobile", isMobile);
    component.set("v.fileCount", 0);
  },

  autoInit: function (component, event, helper) {
    console.log("afterScripts");
    var recordId = component.get("v.recordId");
    if (recordId !== null) component.init();
  },

  initWithId: function (component, event, helper) {
    console.log("initWithId");
    var dropToAWS = component.get("v.dropToAWS"),
      params = event.getParam("arguments");
    if (!$A.util.isEmpty(dropToAWS)) {
      dropToAWS.legendForceDropToAWS("destroy");
      component.set("v.dropToAWS", null);
    }
    if ($A.util.isEmpty(params.recordId)) {
      alert("Could not find record Id");
      throw "could not find record Id";
    }
    component.set("v.recordId", params.recordId);
    component.init();
  },

  init: function (component, event, helper) {
    console.log("init");
    var action = component.get("c.setupLegendGallery"),
      recId = component.get("v.recordId"),
      evt = component.getEvent("initComplete");
    action.setParams({
      recordId: recId
    });
    console.log(recId);
    action.setCallback(this, function (response) {
      var r = JSON.parse(response.getReturnValue());
      component.set("v.LegendGallery", JSON.parse(response.getReturnValue()));
      helper.initDragAndDrop(component);
      evt.fire();
    });
    $A.enqueueAction(action);
  },

  addImages: function (component, event, helper) {
    var dropToAWS = component.get("v.dropToAWS");
    if (!$A.util.isEmpty(dropToAWS)) {
      dropToAWS.legendForceDropToAWS("addImage");
    }
  },

  doUpload: function (component) {
    var dropToAWS = component.get("v.dropToAWS");
    dropToAWS.legendForceDropToAWS("doUpload");
  },

  handleCreateSfRecordEvent: function (component, event, helper) {
    var sfData = event.getParam("sfData");
    helper.createSalesforceRecords(component, sfData);
  }
});
