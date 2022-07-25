({
  getClaimDetails: function (component) {
    var self = this,
      action = component.get("c.getClaimDetails"),
      la,
      recordId = component.get("v.recordId"),
      reqs;
    action.setParams({
      caseId: recordId
    });
    la = new LightningApex(this, action);
    return la.fire();
  },

  // getRegistrationId : function(component) {
  // 	console.log('helper.getRegistrationId');
  // 	var self = this,
  // 			action = component.get('c.getRegistrationId'), la,
  // 			productName = component.get('v.claim.Promotion_Item__r.Product__r.Name'),
  // 			customerId = component.get('v.claim.Promotion_Customer_Account__c');
  // 	console.log('productName: ' + productName);
  // 	console.log('customerId: ' + customerId);
  // 	if (productName !== undefined && customerId !== undefined) {
  // 		action.setParams({
  // 			"productName" : productName,
  // 			"customerId" : customerId
  // 		});
  // 		la = new LightningApex( this, action );
  //     return la.fire();
  // 	}
  // },

  claimPromotion: function (component, event) {
    var self = this,
      action = component.get("c.claimPromotion"),
      la,
      caseId = component.get("v.recordId"),
      regId = component.get("v.regId"),
      piId = component.get("v.claim.Promotion_Item__c");
    action.setParams({
      caseId: caseId,
      regId: regId,
      piId: piId
    });
    la = new LightningApex(this, action);
    la.fire().then(
      $A.getCallback(function (result) {
        component.set("v.stage", 3);
        component.find("spinner").toggle();
      }),
      $A.getCallback(function (err) {
        LightningUtils.errorToast(err);
        component.find("spinner").toggle();
      })
    );
  }
});
