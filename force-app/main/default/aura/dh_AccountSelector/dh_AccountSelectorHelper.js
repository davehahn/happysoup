({
	createERP : function( component )
  {
    console.log( 'helper.createERP with accountId = ' + component.get('v.accountId') );
    var evt = component.getEvent("accountSelectedEvent");
    evt.setParams({
      accountId: component.get('v.accountId'),
      accountName: component.get('v.AccountName')
    })
    .fire();
	}
})