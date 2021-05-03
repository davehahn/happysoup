({
  init : function(component, event, helper) {
    try{
        helper.loadERPOrder(component);
    }catch(ex){
        console.log(ex);
    }
  },

  openEditSearch : function(component, event, helper) {
     helper.openEditSearchHelper(component, event);
  },

  goBack : function(component, event, helper) {
     helper.goBackToListView(component, event);
  },

  deleteRecord : function(component, event, helper) {
      helper.deleteRecordHelper(component, event);
  },

  toggleDelete : function(component, event, helper) {
      helper.deleteConfirmPopup(component, event);
  }

})