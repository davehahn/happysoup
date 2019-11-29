({
  init: function( component )
  {
    var action = component.get('c.initNewService' ), la;
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

  fetchSerialNumberDetails: function( component, serialNumberId )
  {
    console.log('serialNumberId = ' + serialNumberId );
    if( serialNumberId === undefined ||
        serialNumberId == null )
      return Promise.resolve();

    var action = component.get('c.fetchSerialDetails'), la;
    action.setParams({
      serialId: serialNumberId
    });
    la = new LightningApex( this, action );
    return la.fire();
  },

  updateEventData: function( component, eventData )
  {
    console.log('helper.updateEventData');
    var self = this;
    return new Promise(function(resolve, reject) {
      $A.util.removeClass( component.find('spinner'), 'slds-hide' );
      self.doUpdateEventData( component, eventData )
      .then(
        $A.getCallback( function() {
          LightningUtils.showToast('success', 'Success!', 'The record was successfully updated');
          component.getEvent("UpdateSuccess").fire();
          console.log( 'event seemed to update');
          resolve();
        }),
        $A.getCallback( function(err) {
          $A.util.addClass( component.find('spinner'), 'slds-hide' );
          LightningUtils.errorToast(err);
          reject(err);
        })
      );
    });
  },

  doUpdateEventData: function( component, eventData )
  {
    var action = component.get('c.updateServiceRecord'), la;

    if( eventData.startDateTime === '' )
        eventData.startDateTime = null

    action.setParams({
      jsonEventData: JSON.stringify( eventData )
    });
    la = new LightningApex( this, action );
    return la.fire();
  },

  getRiggers: function( component )
  {
    var riggers = component.get('v.riggers'),
        warehouseId = component.get('v.eventData.warehouseId'),
        action = component.get('c.getRiggers'), la;
    component.set('v.riggers', null);
    component.set('v.riggerId', null);
    action.setParams({
      "warehouseId": warehouseId
    });
    la = new LightningApex( this, action );
    return la.fire();
  },

  updateRiggerJob: function( component, erpId, riggerId, action )
  {
    console.log('helper.updateRiggerJob');
    action.setParams({
      "erpId": erpId,
      "riggerId": riggerId
    });
    var la = new LightningApex( this, action );
    return la.fire();
  },

  getRiggerId: function( component )
  {
    var erpId = component.get('v.recordId'),
        action = component.get('c.getRiggerId'), la;
    action.setParams({
      "erpId" : erpId
    });
    la = new LightningApex( this, action );
    return la.fire();
  }
})