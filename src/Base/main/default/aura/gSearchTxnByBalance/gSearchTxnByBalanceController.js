({
    doInit: function(component, event, helper) {
        helper.runAction(component, "c.getPeriods", {}, function(response) {
            var results = response.getReturnValue();
            component.set("v.periodOptions", results);
            component.set("v.idPeriod",results[0].Id);
        });
        helper.toggleSpinner(component, false);
    },
    balanceInputKeyUp: function(component, event, helper) {
		if (event.getParams().keyCode == 13) {
           	component.set("v.searchBalance", component.find("balanceInput").get("v.value"));
	    }
    },
    periodChanged: function(component, event, helper) {
      var val = component.find("balanceInput").get("v.value");
      if(val == '' || val == null) return;
      component.set("v.searchBalance", val);
    },
    onSearch: function(component, event, helper) {
        var searchNumber = component.get("v.searchBalance");
        
        if (!searchNumber || isNaN(searchNumber)) {
            helper.showToast(component, "Search Balance", "error", "Please enter a valid number");
            return;
        }
        helper.toggleSpinner(component, true);

        helper.runAction(component, "c.getMatchedTxn", {
            srcBalance: searchNumber,
            idPeriod:component.get("v.idPeriod")
        }, function(response) {
            var results = response.getReturnValue();
            component.set("v.txnFound", results.transactions);
            component.set("v.billFound", results.billings);
            component.set("v.payableFound", results.payables);
            component.set("v.disbursementFound", results.disbursements);
            component.set("v.receiptFound", results.receipts);
            component.set("v.journalFound", results.journals);
            helper.toggleSpinner(component, false);
            //if (results.length <= 0 ) {
            //    component.find("balanceInput").set("v.value", "");
            //    component.set("v.searchBalance", "");
            //    helper.showToast(component, "Search Balance", "error", "No record with balance " + searchNumber + " was found in the system.");
            //}
        });
    },
    closeToast: function(component, event, helper) {
		var toast = component.find("toast");
        
        window.setTimeout(
            $A.getCallback( function() {
                $A.util.addClass(toast, 'slds-hide');
            }));
    }
})