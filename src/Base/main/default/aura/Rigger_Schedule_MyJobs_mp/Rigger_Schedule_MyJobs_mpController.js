({
  doInit: function (component, event, helper) {
    helper.getRiggers(component, event);
  },

  loadMyJobs: function (component, event, helper) {
    console.log("loadMyJobs");
    console.log(event);
    helper.getMyJobs(component, event);
    helper.getMyCompletedJobs(component, event);
  },

  allowDrop: function (component, event, helper) {
    event.preventDefault();
  },

  drag: function (component, event, helper) {
    component.set("v.draggedItemId", event.srcElement.id);
    event.dataTransfer.setData("text", event.target.id);
  },

  drop: function (component, event, helper) {
    console.log("city drop");
    event.preventDefault();
    var data = event.dataTransfer.getData("text");
    event.target.parentElement.appendChild(document.getElementById(data));
    helper.assignJob(component, event.target.parentElement.id);
  },

  dropOnItem: function (component, event, helper) {
    console.log("city dropOnItem");
    event.preventDefault();
    var data = event.dataTransfer.getData("text");
    event.target.parentElement.parentElement.insertBefore(document.getElementById(data), event.target.parentElement);
    helper.assignJob(component, event.target.parentElement.parentElement.id);
  },

  onclick: function (component, event, helper) {
    var urlEvent = $A.get("e.force:navigateToURL");
    urlEvent.setParams({
      url: "/one/one.app#/sObject/" + event.srcElement.parentElement.id + "/edit",
      isredirect: false
    });
    urlEvent.fire();
  }
});
