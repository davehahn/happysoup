({
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