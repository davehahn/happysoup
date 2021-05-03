/**
 * Created by dave on 2019-10-21.
 */

({
  fetchSerial: function( component )
  {
     var action = component.get('c.fetchSerialNumber');
     action.setParams({
       serialId: component.get('v.recordId')
     });
     return new LightningApex( this, action ).fire();
  },

  fetchRegistration: function( component )
  {
    var serial = component.get('v.serialNumber'),
        action;
    if( serial == null )
    {
      return new Promise( function(resolve) { resolve( null ); } );
    }
    action = component.get('c.fetchRegistration');
    action.setParams({
      serialId: serial.Id
    });
    return new LightningApex( this, action ).fire();
  },

  doRegistration: function( component )
  {
    var action = component.get('c.doRegister');
    action.setParams({
      registrationId: component.get('v.registration').Id
    });
    return new LightningApex( this, action ).fire();
  }
});