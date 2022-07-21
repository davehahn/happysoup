({
  init: function (component) {
    // Find the component whose aura:id is "flowData"
    var flow = component.find("flowData");
    // In that component, start your flow. Reference the flow's API Name.

    flow.startFlow("Book_Service_Appointment");
  },

  handleStatusChange: function (component, event) {
    if (event.getParam("status") === "FINISHED") {
      window.open("https://legendboats.com", "_top");
    }
  }
});
