({
	doInit : function(component, event, helper) {
		console.log('doInit');
		helper.getSummary(component)
		.then(
			$A.getCallback( function(result) {
				console.log('result:');
				console.log(result);
				for (var i = 0; i < result.statements.length; i++) {
					result.statements[i].name = result.statements[i].version.ContentDocument.CreatedDate.substr(0,10);
				}
				component.set('v.statements', result.statements);
				component.set('v.availableCredit', result.availableCredit);
				component.set('v.creditLimit', result.creditLimit);
				component.set('v.creditTotal', result.creditTotal);
				component.set('v.actualBalance', result.actualBalance);
				component.set('v.currentBalance', result.currentBalance);
				component.set('v.debitTotal', result.debitTotal);
				component.set('v.lastPayment', result.lastPayment);
				component.set('v.paymentDueDate', result.paymentDueDate.substring(0,10));
				component.set('v.transactions', result.transactions);
				if (result.lastPaymentDate != null) {
					component.set('v.lastPaymentDate', result.lastPaymentDate.substring(0,10));
				}
				component.set('v.isLoaded', true);
			}),
			$A.getCallback( function(err) {
				console.log('err:');
				console.log(err);
			})
		)
	},

	openStatement : function(component, event, helper) {
		var selectedStatement = component.get('v.selectedStatement');
		window.open('/s/contentdocument/' + selectedStatement);
	}
})