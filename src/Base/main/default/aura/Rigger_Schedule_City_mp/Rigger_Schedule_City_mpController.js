({
  doneRendering: function (component, event, helper) {
    if (!component.get("v.isDoneRendering")) {
      component.set("v.isDoneRendering", true);
    }
  },

  doNothing: function () {},

  readyForInit: function (component) {
    component.set("v.readyForInit", true);
  },

  doInit: function (component, event, helper) {
    helper.getRiggers(component).then(function () {
      helper.getJobs(component).then(function () {
        $A.util.addClass(component.find("citySpinner"), "slds-hide");
      });
    });
  },

  teamChange: function (component, event, helper) {
    helper.getRiggers(component).then(function () {
      helper.getJobs(component);
    });
  },

  allowDrop: function (component, event, helper) {
    event.preventDefault();
  },

  drag: function (component, event, helper) {
    component.set("v.draggedItemId", event.srcElement.id);
    event.dataTransfer.setData("text", event.target.id);
  },

  dragEnd: function (component, event, helper) {
    helper.getJobs(component);
  },

  drop: function (component, event, helper) {
    event.preventDefault();
    var data = event.dataTransfer.getData("text");
    // event.target.parentElement.appendChild(document.getElementById(data));
    helper.assignJob(component, event, event.target.closest(".dropContainer").id);
  },

  dropOnItem: function (component, event, helper) {
    event.preventDefault();
    var data = event.dataTransfer.getData("text");
    event.target.parentElement.parentElement.insertBefore(document.getElementById(data), event.target.parentElement);
    helper.assignJob(component, event, event.target.closest(".dropContainer").id);
  },

  searchBacklog: function (component, event, helper) {
    var locked = component.get("v.lockSearch");
    if (!locked) {
      component.set("v.lockSearch", true);
      helper.handleSearch(component);
    } else {
      setTimeout(function () {
        component.set("v.lockSearch", false);
      }, 500);
    }
  },

  filterBacklog: function (component, event, helper) {
    helper.getUnassignedJobs(component);
  },

  filterCompleted: function (component, event, helper) {
    helper.getCompletedJobs(component);
  },

  openNewForm: function (component, event, helper) {
    component.set("v.openNewForm", true);
  },

  setSelectedJobId: function (component, event, helper) {
    component.set("v.selectedJobId", event.srcElement.id);
  },

  loadMore: function (component, event, helper) {
    var pageNum = component.get("v.pageNum");
    pageNum += 1;
    component.set("v.pageNum", pageNum);
  },

  handleDroppedItem: function (component, event, helper) {
    //		component.set('v.fuckit', false);
    helper.getJobs(component);
  }
});
