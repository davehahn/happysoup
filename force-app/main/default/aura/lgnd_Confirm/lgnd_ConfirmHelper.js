({
	toggleModal : function( component, title, message )
  {
    var modal = component.find('the-modal'),
        backdrop = component.find('backdrop');

    component.set('v.title', title );
    component.set('v.message', message );
    $A.util.toggleClass(modal, 'slds-slide-up-open');
    $A.util.toggleClass(backdrop, 'slds-backdrop_open');
	},

  handleRespond: function( component, resp )
  {
    console.log( resp );
    var evt = $A.get('e.c:lgnd_Confirm_Response_Event');
    evt.setParams({
      theResponse: resp
    })
    .fire();
    this.toggleModal( component, '', '' );
  }
})