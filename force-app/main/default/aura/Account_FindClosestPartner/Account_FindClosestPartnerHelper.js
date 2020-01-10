({
  findClosestDealer: function( component )
  {
    var spinner = component.find('spinner');
    spinner.toggle();
    this.doClosestDealer( component )
    .then(
      $A.getCallback( function( results ) {
        component.set('v.mapMarkers', results.mapMarkers);
        component.set('v.originAddress', results.origin_address );
      }),
      $A.getCallback( function( err ) {
        LightningUtils.errorToast( err );
      })
    )
    .finally( $A.getCallback( function() {
      spinner.toggle();
    }));
  },

  doClosestDealer: function( component )
  {
    var action = component.get('c.findClosestPartner'),
        excludes = component.get('v.excludedAccountIds'),
        params = {
          lookupValue: component.get('v.lookupValue'),
          resultCount: component.get('v.partnerCount')
        };
    if( excludes === undefined || excludes === null )
        excludes = '';
    params.excludedAccountIds = excludes;
    if( params.lookupValue == null ||
        params.lookupValue.length == 0 )
    {
      return Promise.resolve(null);
    }
    action.setParams(params);
    return new LightningApex( this, action ).fire();
  }
})