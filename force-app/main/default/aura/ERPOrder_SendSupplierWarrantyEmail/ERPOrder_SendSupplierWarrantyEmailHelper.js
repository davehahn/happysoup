({
  fetchERPInfo: function( component )
  {
    var recordId = component.get( 'v.recordId' ),
        action = component.get('c.fetchERPInfo');

    action.setParams({
      recordId: recordId
    });
    var la = new LightningApex( this, action );
    return la.fire();
  },

	fetchContacts : function( component )
  {
    var recordId = component.get( 'v.recordId' ),
        action = component.get('c.findContacts');

    action.setParams({
      recordId: recordId
    });
    var la = new LightningApex( this, action );
    return la.fire();
	},

  submitToSmoker: function( component )
  {
    var isSmoker = component.get('v.isSmoker'),
        action = component.get('c.postToSmokerAPI'),
        la;

    if( isSmoker )
    {
      action.setParams({
        recordId: component.get('v.recordId')
      });

      la = new LightningApex( this, action );
      return la.fire();
    }
    return Promise.resolve();
  },

  sendEmail: function( component )
  {
    var table = component.find('contactDataTable'),
        recordId = component.get('v.recordId'),
        action = component.get('c.sendRecoverableEmail'),
        contactIds = [];
    for( var cont of table.getSelectedRows() )
    {
      contactIds.push( cont.Id );
    }

    action.setParams({
      erpId: recordId,
      contactIds: contactIds
    });

    var la = new LightningApex( this, action );
    return la.fire();
  }

})