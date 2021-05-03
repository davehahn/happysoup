({
	doInit : function(component, event, helper) {
		helper.getSummary(component)
		.then(
			$A.getCallback( function(result) {
				console.log('result:');
				console.log(result);
				component.set('v.creditTotal', result.creditTotal);
				component.set('v.debitTotal', result.debitTotal);
				component.set('v.transactions', result.transactions);
				for (var i = 0; i < result.statements.length; i++) {
					result.statements[i].name = result.statements[i].version.ContentDocument.CreatedDate.substr(0,10);
				}
				component.set('v.statements', result.statements);
			}),
			$A.getCallback( function(err) {
				console.log('err:');
				console.log(err);
			})
		)
	},

	openStatement : function(component, event, helper) {
		var link = component.find("monthlyStatement").get("v.value");
		window.open(link);
	}
})