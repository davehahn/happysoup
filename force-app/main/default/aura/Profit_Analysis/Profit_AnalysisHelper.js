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

  setResultValues: function( component, result )
  {
    console.log('helper.setResultValue');
    console.log( JSON.parse( JSON.stringify(result)));
    component.set('v.lineItems', result.items);
    component.set('v.saleItems', result.saleItems );
    component.set('v.businessOfficeItems', result.businessOfficeItems );
    component.set('v.selectedPbId', result.pbId );
    component.set('v.pbOptions', result.pbOptions );
    this.setTotals( component );
  },

  setTotals: function( component )
  {
    var lineItems = component.get('v.lineItems'),
        grandTotal=0, salesTotal=0, boTotal=0, factoryPbTotal=0, riggingTotal=0;
    for( let li of component.get('v.saleItems') )
    {
      if( li.include )
      {
        grandTotal += li.saleTotal;
        //costTotal += li.costTotal;
        salesTotal += li.saleTotal;
        factoryPbTotal += li.factoryPbTotal;
        riggingTotal += li.riggingCost;
      }
    }
    for( let li of component.get('v.businessOfficeItems') )
    {
      if( li.include )
      {
        grandTotal += li.saleTotal;
        //costTotal += li.costTotal;
        boTotal += li.saleTotal;
        factoryPbTotal += li.factoryPbTotal;
        riggingTotal += li.riggingCost;
      }
    }
    component.set('v.saleTotal', grandTotal);
    component.set('v.salesItemsTotal', salesTotal );
    component.set('v.businessOfficeItemsTotal', boTotal);
//    component.set('v.costTotal', costTotal);
    component.set('v.riggingLabourTotal', riggingTotal);
    component.set('v.factoryPbTotal', factoryPbTotal);
//    component.set('v.costProfit', saleTotal - costTotal - riggingTotal );
//    component.set('v.costProfitPercent', 1 - ( (costTotal+riggingTotal)/saleTotal )  );
    component.set('v.factoryPbProfit', grandTotal - factoryPbTotal - riggingTotal );
    component.set('v.factoryPbProfitPercent', 1 - ( (factoryPbTotal+riggingTotal)/grandTotal )  );
  }

});