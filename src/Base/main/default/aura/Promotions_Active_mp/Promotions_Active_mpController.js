({
	doInit : function(component, event, helper) {
    console.log('doInit');
		helper.getPromotions(component);
	},

  openClaimDialog : function(component, event, helper) {
    $A.util.removeClass(component.find('newClaimForm'), 'slds-hide');  
    helper.getPromoItems(component, event)
    .then(
    	function(result) {
        component.set('v.newClaim_promoItems', result);
        console.log(result);      
    	}
    );
  },

  closeFormModal : function(component, event, helper) {
    $A.util.addClass(component.find('newClaimForm'), 'slds-hide');
  },

  enableSaveBtn : function(component, event, helper) {
    var selectValue = component.get('v.newClaim_promoItem_selected');
    if (selectValue != 'select')
      component.set('v.saveBtnDisabled', false);
    else
      component.set('v.saveBtnDisabled', true);
  },

  saveClaim : function(component, event, helper) {
    $A.util.addClass(component.find('newClaimForm'), 'slds-hide');
    $A.util.removeClass(component.find('spinner'), 'slds-hide');
    helper.createPromoClaim(component, event)
    .then(
      function(result) {
        console.log('Claim saved');
        console.log(result);
        $A.util.addClass(component.find('spinner'), 'slds-hide');
      }
    );
  }
})