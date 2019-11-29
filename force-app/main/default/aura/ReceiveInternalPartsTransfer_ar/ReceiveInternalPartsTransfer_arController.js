({
    doInit: function(component, event, helper) {
        helper.checkIdType(component,event);
    },
    receiveTransferInventory: function(component, event, helper) {
        var dataTnsfId = event.getSource().get('v.class');
        var dataTnsIndx = event.getSource().get('v.name');
        var listData = component.get("v.listDataNew")[dataTnsIndx];
        var getAllId = component.find('datePickers');
        var dateInbound;
        if(!Array.isArray(getAllId)){
            dateInbound = component.find("datePickers").get("v.value");
        }else{
            for (var i = 0; i < getAllId.length; i++) {
                var theId = component.find("datePickers")[i].get("v.class");
                if(theId == dataTnsfId){
                    dateInbound = component.find("datePickers")[i].get("v.value");
                    break;
                }
            }
        }
        helper.toggleSpinner(component, true);
        helper.runAction(component, "c.receiveTransfer", {
            idERP: component.get("v.recordId"),
            idTnsf: dataTnsfId,
            dateInbound: dateInbound,
            listValues: JSON.stringify(listData)
        }, function(response) {
            helper.toggleSpinner(component, false);
            var state = response.getState();
            if (state != "SUCCESS") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        helper.showToast(component, "Error", "error", errors[0].message);
                    }else {
                        helper.showToast(component, "Error", "error", "There was an error with negative balance.");
                    }
                }
                return;
            }
            var results = response.getReturnValue();
            if(results != 'ok')
                helper.createInvoice(component, results);

            helper.retrieveTransfers(component, event);
            helper.showToast(component, "Received", "success", "Transferred Items were received successfully.");
        });
    }
})