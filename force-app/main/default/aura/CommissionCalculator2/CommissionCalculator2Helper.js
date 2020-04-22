/**
 * Created by dave on 2020-02-10.
 */

({
  getRecords: function( component )
  {
    let action = component.get('c.fetchCommissionRecords');
    action.setParams({
      erpId: component.get('v.recordId')
    });
    return new LightningApex( this, action ).fire();
  }
});