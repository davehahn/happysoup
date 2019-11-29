({
	getPromoCases : function( component, event )
	{
		this.fetchPromos( component )
    .then(
      $A.getCallback( function(result ) {
      	component.set('v.promoCases',result);
      }),
      $A.getCallback( function( err ) {
        LightningUtils.errorToast( err );
      })
    )
	},

	fetchPromos : function( component )
  {
    var action = component.get('c.getPromoCases'), la;
    la = new LightningApex( this, action );
    return la.fire();
	},

	claimPromotion : function( component, event )
	{
		var self = this,
				action = component.get('c.claimPromotion'), la,
				caseId = event.srcElement.dataset.caseid,
				regId = event.srcElement.dataset.regid,
				piId = event.srcElement.dataset.piid;
		action.setParams({
			caseId: caseId,
			regId: regId,
			piId: piId
		});
    la = new LightningApex( this, action );
    la.fire()
    .then(
      $A.getCallback( function(result ) {
      	LightningUtils.showToast('success', 'success', 'Claim submitted');
      	self.getPromoCases(component, event);
      }),
      $A.getCallback( function( err ) {
        LightningUtils.errorToast( err );
      })
    )
	}
})