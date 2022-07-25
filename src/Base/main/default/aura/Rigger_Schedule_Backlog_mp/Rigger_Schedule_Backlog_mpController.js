({
  doInit: function (component, event, helper) {
    var j = component.get("v.job");
  },

  allowDrop: function (component, event, helper) {
    event.preventDefault();
  },

  drag: function (component, event, helper) {
    component.set("v.draggedItemId", event.srcElement.id);
    event.dataTransfer.setData("text", event.target.id);
  },

  openNewForm: function (component, event, helper) {
    component.set("v.openNewForm", true);
  },

  setSelectedJobId: function (component, event, helper) {
    component.set("v.selectedJobId", event.srcElement.id);
  }
});
