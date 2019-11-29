({
	doInit : function(component, event, helper) {
    helper.getAvailablePromos(component);
  },

  createClaim : function(component, event, helper) {
    $A.util.removeClass( component.find('spinner'), 'slds-hide' );
    helper.startClaim(component, event);
  }
})