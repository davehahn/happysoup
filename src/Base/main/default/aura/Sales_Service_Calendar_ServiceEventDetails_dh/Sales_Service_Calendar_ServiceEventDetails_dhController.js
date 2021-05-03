({
	afterScripts : function(component, event, helper)
  {
    helper.init( component )
    .then(
      $A.getCallback( function( result ) {
        console.log( result );
        component.set('v.warehouseOptions', result.warehouses );
        component.set('v.perms', result.permissions );
        component.set('v.parkingSpotOptions', result.parkingSpots );
        return helper.fetchRecord( component );
      }),
      $A.getCallback( function( err ) {
        LightningUtils.errorToast( err );
      })
    )
    .then(
      $A.getCallback( function( record ) {
        console.log( record );
        if( record.startDateTime == null )
          record.startDateTime = component.get('v.scheduleStartDate');
        if( record.endDateTime == null )
          record.endDateTime = component.get('v.scheduleEndDate');
        component.set('v.eventData', record);
        return helper.fetchSerialNumberDetails( component, record.serialNumberId );
      }),
      $A.getCallback( function( err ) {
        LightningUtils.errorToast( err );
      })
    )
    .then(
      $A.getCallback( function( result ) {
        console.log( result );
        component.set('v.selectedSerial', result );
        component.getEvent("ModalLoaded").fire();
        return helper.getRiggerId(component);
      }),
      $A.getCallback( function( err ) {
        LightningUtils.errorToast( err );
      })
    )
    .then(
      $A.getCallback( function( record ) {
        component.set('v.riggerId', record);
      }),
      $A.getCallback( function( err ) {
        LightningUtils.errorToast( err );
      })
    )
	},

  handleNavToRecord: function( component, event, helper )
  {
    var recordId = event.currentTarget.dataset.recordId;
    var navEvt = $A.get("e.force:navigateToSObject");
    navEvt.setParams({
      "recordId": recordId,
    })
    .fire();
  },

  handleCancel : function(component, event, helper) {
    console.log( 'close modal');
    component.getEvent("CloseModal").fire();
  },

  handleUnschedule: function( component, event, helper )
  {
    helper.updateEventData( component, true );
  },

  handleUpdate: function( component, event, helper )
  {
    helper.updateEventData( component );
  },

  warehouseChanged: function( component, event, helper )
  {
    console.log('warehouseChanged');
    var warehouseId = component.get('v.eventData.warehouseId');
    if (warehouseId != null && warehouseId != '') {
      helper.getRiggers( component )
      .then(
        $A.getCallback( function(result) {
          component.set('v.riggers', result);
        }),
        $A.getCallback( function(err) {
          $A.util.addClass( component.find('spinner'), 'slds-hide' );
          LightningUtils.errorToast(err);
        })
      );
    }
  }
})