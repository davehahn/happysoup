({
  handleSaleTypeSelect: function( component, event, helper )
  {
    var saleType = event.currentTarget.dataset.accountType;
    component.set('v.saleType', saleType );
  },

  handleOppCreated: function( component, event, helper )
  {
    var fromCPQ = component.get('v.fromCPQ'),
        oppId = event.getParam('opportunityId'),
        urlEvent;
    if( !fromCPQ )
    {
      urlEvent = $A.get("e.force:navigateToURL");
      if( urlEvent )
      {
        urlEvent.setParams({
          "url": '/apex/BoatConfigurator?opportunity_id=' + oppId
        });
        urlEvent.fire();
      }
      else
      {
        window.location = '/apex/BoatConfigurator?opportunity_id=' + oppId;
      }
    }
  }
})