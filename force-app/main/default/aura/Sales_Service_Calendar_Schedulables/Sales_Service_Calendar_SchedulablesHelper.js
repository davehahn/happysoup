({
  loadSchedulable: function( component )
  {
    $A.util.removeClass( component.find('spinner'), 'slds-hide');
    var self = this;
    self.fetchSchedulables( component )
    .then(
      $A.getCallback( function( result ) {
        component.set('v.allRecords', result);
        self.applyCalenderFilter( component );
        $A.util.addClass( component.find('spinner'), 'slds-hide');
      }),
      $A.getCallback( function( err ) {
        LightningUtils.errorToast( err );
        $A.util.addClass( component.find('spinner'), 'slds-hide');
      })
    );
  },

	fetchSchedulables : function( component )
  {
    var action = component.get('c.fetchSchedulables'), la;
    la = new LightningApex( this, action );
    return la.fire();
	},

  applyCalenderFilter: function( component )
  {
    component.set('v.displayedRecords', this.findRecordsByCalendars( component ) );
  },

  findRecordsByCalendars: function( component )
  {
    var allRecords = component.get('v.allRecords'),
        cals = component.get('v.activeCalendars'),
        calTypes = [],
        toDisplay = [];

    for( let cal of cals )
    {
      calTypes.push( cal.split(':')[1] );
    }

    for( let r of allRecords )
    {
      if( r.storeLocation.length === 0 && calTypes.indexOf( r.calId ) > -1 )
        toDisplay.push( r );
      else if( cals.indexOf( r.calId ) > -1 )
        toDisplay.push( r );
    }
    return toDisplay;
  },

  applySearch: function( component, searchValue )
  {
    var displayedRecs = this.findRecordsByCalendars( component ),
        result = [];
    searchValue = searchValue.toLowerCase();
    for( let rec of displayedRecs )
    {
      if( rec.Name && rec.Name.toLowerCase().includes( searchValue) )
        result.push( rec );
      else if( rec.accountName && rec.accountName.toLowerCase().includes( searchValue ) )
        result.push( rec );
      else if( rec.boatName && rec.boatName.toLowerCase().includes( searchValue ) )
        result.push( rec );
    }
    component.set('v.displayedRecords', result );
  }
})