/**
 * Created by dave on 2019-11-06.
 */

({
  fetchData: function( component )
  {
    var action = component.get('c.fetchData');
    action.setParams({
      recordId: component.get('v.recordId')
    });
    return new LightningApex( this, action ).fire();
  },

  updateItems: function( component, pbId )
  {
     var action= component.get('c.updateData');
     action.setParams({
       recordId: component.get('v.recordId'),
       pbId: pbId
     });
     return new LightningApex( this, action ).fire();
  },

  setTotals: function( component )
  {
    var lineItems = component.get('v.lineItems'),
        saleTotal=0, costTotal=0, factoryPbTotal=0, riggingTotal=0;
    for( let li of lineItems )
    {
      if( li.include )
      {
        saleTotal += li.saleTotal;
        costTotal += li.costTotal;
        factoryPbTotal += li.factoryPbTotal;
        riggingTotal += li.riggingCost;
      }
    }
    component.set('v.saleTotal', saleTotal);
    component.set('v.costTotal', costTotal);
    component.set('v.riggingLabourTotal', riggingTotal);
    component.set('v.factoryPbTotal', factoryPbTotal);
    component.set('v.costProfit', saleTotal - costTotal - riggingTotal );
    component.set('v.costProfitPercent', 1 - ( (costTotal+riggingTotal)/saleTotal )  );
    component.set('v.factoryPbProfit', saleTotal - factoryPbTotal - riggingTotal );
    component.set('v.factoryPbProfitPercent', 1 - ( (factoryPbTotal+riggingTotal)/saleTotal )  );
  }

});