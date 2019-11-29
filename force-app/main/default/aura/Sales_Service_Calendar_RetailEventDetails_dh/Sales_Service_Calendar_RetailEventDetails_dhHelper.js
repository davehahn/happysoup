({
  initEventDetailsForm: function( component )
  {
    var action = component.get('c.initDetailsForm' ), la;
    la = new LightningApex( this, action );
    return la.fire();
  },

  fetchRecord : function( component )
  {
    var action = component.get('c.fetchRecord'), la;
    action.setParams({
      recordId: component.get('v.recordId')
    });
    la = new LightningApex( this, action );
    return la.fire();
  },

  updateEventData: function( component, eventData )
  {
    $A.util.removeClass( component.find('spinner'), 'slds-hide' );
    this.doUpdateEventData( component, eventData )
    .then(
      $A.getCallback( function() {
        LightningUtils.showToast('success', 'Success!', 'The record was successfully updated');
        component.getEvent("UpdateSuccess").fire();
        console.log( 'event seemed to update');
      }),
      $A.getCallback( function(err) {
        $A.util.addClass( component.find('spinner'), 'slds-hide' );
        LightningUtils.errorToast(err);
      })
    );
  },

  doUpdateEventData: function( component, eventData )
  {
    var action = component.get('c.updateRetailRecord'), la;

    if( eventData.startDateTime == '' )
      eventData.startDateTime = null;
    action.setParams({
      jsonEventData: JSON.stringify( eventData )
    });
    la = new LightningApex( this, action );
    return la.fire();
  }
})