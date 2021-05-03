({
    doInit: function(component, event, helper) {
        helper.toggleSpinner(component, true);
        helper.retrieveBillingData(component, event, helper);
    },
    retrieveBillingData: function(component, event, helper) {
        helper.retrieveBillingData(component, event, helper);
    },
    removeComponent:function(component){
        component.destroy();
    },
    loadBalance: function(component, event, helper) {
        var idAmount = event.getSource().get('v.class');
        var arr = idAmount.split('_');
        var idBCM = arr[0];
        var amountBCM = parseFloat(arr[1]);
        var totalCanBeApplied = component.get("v.totalCanBeApplied");
        var totalApplied = component.get("v.totalApplied");
        var toApply = amountBCM;
        if(totalApplied == (totalCanBeApplied * -1))
        	return;
        else if(amountBCM >= totalCanBeApplied)
        	toApply = totalCanBeApplied + totalApplied;

        var inputId = idBCM+'_input';
        console.log('totalApplied');
        console.log(totalApplied);
        console.log('totalCanBeApplied');
        console.log(totalCanBeApplied);
        console.log('amountBCM');
        console.log(amountBCM);
        console.log('toApply');
        console.log(toApply);
        console.log('inputId');
        console.log(inputId);
        var getAllFields = component.find("billAmount");
        if(! Array.isArray(getAllFields)){
            var $elem = component.find("billAmount");
            $elem.set("v.value",toApply);
        }else{
            for (var i = 0; i < getAllFields.length; i++) {
                var $elem = component.find("billAmount")[i];
                var cId = $elem.get("v.id");
                console.log(cId);
                if(cId == inputId)
                	$elem.set("v.value",toApply);
            }
        }
        helper.amountChanged(component, event, helper);
    },
    amountChanged: function(component, event, helper) {
        helper.amountChanged(component, event, helper);
    },
    processCMApply: function(component, event, helper) {
        var getAllFields = component.find("billAmount");
        var billingMap = [];
        if(! Array.isArray(getAllFields)){
            var cId = component.find("billAmount").get("v.class");
            var cAmount = component.find("billAmount").get("v.value");
            var cPeriod = component.find("billingPeriodField").get("v.value");
            if(isNaN(cAmount)) cAmount = 0;
            billingMap.push({idBilling:cId, applyAmount:cAmount, applyPeriod:cPeriod});
        }else{
            for (var i = 0; i < getAllFields.length; i++) {
	            var cId = component.find("billAmount")[i].get("v.class");
	            var cAmount = component.find("billAmount")[i].get("v.value");
	            var cPeriod = component.find("billingPeriodField")[i].get("v.value");
	            if(isNaN(cAmount)) cAmount = 0;
	            billingMap.push({idBilling:cId, applyAmount:cAmount, applyPeriod:cPeriod});
            }
        }
        console.log(billingMap);
        helper.sendBCMData(component,billingMap);
    },
    closeWindow: function(component, event, helper) {
        helper.closeWindow(component);
    }
})