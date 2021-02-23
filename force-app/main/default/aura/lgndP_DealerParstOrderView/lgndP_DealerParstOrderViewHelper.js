({
    loadERPOrder : function(component) {
      var recordId = component.get('v.recordId');
      //if(!$A.util.isEmpty(component.get("v.erpOrderId"))) {
        //component.set("v.isFound", true);
        // $A.createComponent(
        //     "forceChatter:fullFeed",
        //     {
        //         "type": "RECORD",
        //         "subjectId": component.get("v.erpOrderId")
        //     },
        //     function(newButton, status, errorMessage){
        //         //Add the new button to the body array
        //         if (status === "SUCCESS") {
        //             var body = component.get("v.body");
        //             body.push(newButton);
        //             component.set("v.body", body);
        //         }
        //         else if (status === "INCOMPLETE") {
        //             console.log("No response from server or client is offline.")
        //             // Show offline error
        //         }
        //             else if (status === "ERROR") {
        //                 console.log("Error: " + errorMessage);
        //                 // Show error message
        //             }
        //     }
        // );
        var action = component.get("c.getERPOrder");
        action.setParams({
            "orderId" : recordId
        });

        action.setCallback(this, function(response){
            if(response.error && response.error.length){
                return $A.error('Unexpected error: '+response.error[0].message);
            }
            var data = response.getReturnValue();
            if(data != null){
                console.log( JSON.parse( JSON.stringify(data)));
                component.set("v.erpOrder", data.erpOrder);
                var matList = data.materialList;
                if(matList.length > 0) {
                    for(var record in matList) {
                        var div = document.createElement('div');
                        div.innerHTML = matList[record].matImgUrl;
                        var firstImage = div.getElementsByTagName('img')[0];
                        var rawImgSrc = firstImage ? firstImage.getAttribute("src") : "";
                        matList[record].matImgUrl = rawImgSrc;
                    }
                    component.set("v.materials", matList);
                }
            } else{
                console.error("No errors found");
            }
        });
        $A.enqueueAction(action);
      //}
    },

    openEditSearchHelper : function(component, event) {
        var myEvent = $A.get("e.c:HideShowERPCompEvent");
        myEvent.setParams({
            "compName": "newSearch",
            "erpOrderId": component.get("v.erpOrderId")
        });
        myEvent.fire();
    },
    goBackToListView : function(component, event) {
        $A.get('e.force:refreshView').fire();
    },
    deleteRecordHelper : function(component, event){
        this.deleteConfirmPopup(component, event);
        var action = component.get("c.erpDeleteRecord");
        action.setParams({
            "recordId": component.get("v.erpOrderId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === "SUCCESS") {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "message": "Order deleted successfully.",
                    "type": "success"
                });
                toastEvent.fire();
                $A.get('e.force:refreshView').fire();
            }
            else if (state === "ERROR") {
                alert(response.getError()[0].pageErrors[0].statusCode + '  '+response.getError()[0].pageErrors[0].message);
                console.log(response.getError()[0].pageErrors[0].statusCode + '  '+response.getError()[0].pageErrors[0].message);
                $A.log("Errors", response.getError());
            }
        });
        $A.enqueueAction(action);
    },
    deleteConfirmPopup : function(component, event) {
        var deleteForm = component.find('deleteForm');
        $A.util.toggleClass(deleteForm, 'slds-hide');
    },
})