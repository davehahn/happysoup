({
	runAction : function(component, actionName, params, callback) {
		var action = component.get(actionName);
		action.setParams(params);
		action.setCallback(this, callback);
		$A.enqueueAction(action);
 },
	showToast : function(component, title, type, message) {
		var toastEvent = $A.get("e.force:showToast");
		toastEvent.setParams({
					"title": title,
					"type": type,
					"message": message
		});
		toastEvent.fire();
	},
	toggleSpinner: function (component, value) {
		var spinner = component.find('spinner');
		
		window.setTimeout(
			$A.getCallback( function() {
						if (value) {
									$A.util.removeClass(spinner, 'slds-hide');
						} else {
									$A.util.addClass(spinner, 'slds-hide');
						}
			}));
	},
  returnThisProduct: function( component, event, helper )
  {
		var erpId = event.currentTarget.dataset.matlid;
		var dataIndx = event.currentTarget.dataset.indx;
		var existingData = component.get("v.erpProducts");
		var existingMaterials = component.get("v.materials");
		var addedMaterials = component.get("v.materialsAdded");
		var selectedMaterial = existingData[dataIndx];
		if(addedMaterials.indexOf(selectedMaterial.matId) === -1){
			addedMaterials.push(selectedMaterial.matId);
			var returnMatl = {};
				returnMatl.matId = selectedMaterial.matId;
				returnMatl.productName = selectedMaterial.productName;
				returnMatl.isSerialized = true;
				returnMatl.matQuantity = selectedMaterial.returnQuantity;
				
				returnMatl.serialNumber = '';
				if(selectedMaterial.serialId != null)
					returnMatl.serialNumber = selectedMaterial.serialName;
				returnMatl.projectName = selectedMaterial.projectName;
				returnMatl.returnQuantity = returnMatl.matQuantity;
				returnMatl.pricePerQuantity = selectedMaterial.pricePerQuantity;
				returnMatl.totalPrice = (returnMatl.returnQuantity * returnMatl.pricePerQuantity).toFixed(2);
				console.log(returnMatl);
			existingMaterials.push(returnMatl);
			component.set("v.materials",existingMaterials);
				this.calOrderTotal(component, existingMaterials);
		}
		else
		{
		  this.showToast(component, "Error", "error", "ERP Order Item is already in the list of returns.");
		}
  },
	processCOGS: function( component, event, helper, idBill)
	{
		/// We were accepting multiple projects. but later decided to have only one.
		/// That is why we are returning the user to the first ERP order which is going to be the only one.
		var plist = component.get("v.listData");
		//console.log(plist[0].Id);
		// return;
		// helper.toggleSpinner(component, true);
		helper.runAction(component, "c.takeExpense", {
			idProject: plist[0].Id,
			idNegBill: idBill
		}, function(response) {
            var state = response.getState();
            if (state != "SUCCESS") {
                var errors = response.getError();                
                if (errors) {
                    helper.toggleSpinner(component, false);
                    if (errors[0] && errors[0].message) {
                        helper.showToast(component, "Error In COGS", "error", errors[0].message);   
                    } else {
                        helper.showToast(component, "Error In COGS", "error", "The Return was completed, but the COGS movement was not done. Please post the COGS Journal entry from ERP order page.");
                    }
                    return;
                }
            }
			var results = response.getReturnValue();
			helper.toggleSpinner(component, false);
			var navEvt = $A.get("e.force:navigateToSObject");
			// helper.closeModal( component, event, helper );
			navEvt.setParams({
			  "recordId": plist[0].Id,
			  "slideDevName": "related"
			});
			navEvt.fire();
		});
	},
	removeFromList : function(component, event) {
		var matId = event.currentTarget.dataset.recordid;
		var tmpMaterialList = component.get("v.materials");
		var tmpArrList1 = new Array();
		for (var i = 0; i < tmpMaterialList.length; i++) {
				if(matId != tmpMaterialList[i].matId) {
						tmpArrList1.push(tmpMaterialList[i]);
				} 
				else
				{
				var addedMaterials = component.get("v.materialsAdded");
				addedMaterials.splice(matId,1);
				component.set("v.materialsAdded",addedMaterials);
				}
		}
		component.set("v.materials", tmpArrList1);
		this.calOrderTotal(component, tmpArrList1);
	},
	calculateTotalAmount : function(component, event) {
		var index = event.currentTarget.dataset.recordid;
		// console.log(index) ;
		var className = ".inputNumber" + index;
		var quantity = document.querySelector(className).value;
		var tmpMaterialList = component.get("v.materials");
		tmpMaterialList[index].totalPrice = (quantity*tmpMaterialList[index].pricePerQuantity).toFixed(2);
		if(quantity > tmpMaterialList[index].matQuantity || quantity <= 0 || tmpMaterialList[index].serialized){
			tmpMaterialList[index].returnQuantity = tmpMaterialList[index].matQuantity;
			tmpMaterialList[index].totalPrice = (tmpMaterialList[index].matQuantity*tmpMaterialList[index].pricePerQuantity).toFixed(2);
	// this.showToast(component, "Error", "error", "Cannot return more than material quantity "+tmpMaterialList[index].matQuantity);				
		}
		else{
			tmpMaterialList[index].returnQuantity = quantity;
		}
		component.set("v.materials", tmpMaterialList);
		this.calOrderTotal(component, tmpMaterialList);
	},
	searchERPproductsSingle: function( component, event, helper )
	{
		var erpaccid = component.get('v.accountId');
		var erpId = component.get('v.erpId');
		console.log('here:'+erpId);
		helper.toggleSpinner(component, true);
		helper.runAction(component, "c.retrieveERPProducts", {
			erpId: erpId
		}, function(response) {
			var results = response.getReturnValue();
			component.set('v.accountId',erpaccid);
			results = JSON.parse(results);
			component.set("v.erpProducts", results);
			helper.toggleSpinner(component, false);
		});
	},
	calOrderTotal : function(component, materialList) {
			var orderTotal = 0.0;
			for(var i = 0; i < materialList.length; i++) {
					orderTotal += parseFloat(materialList[i].totalPrice);
			}
			component.set("v.grandTotal", orderTotal.toFixed(2));
	},
  returnAllMaterials: function( component, event, helper )
  {
		component.set("v.canBereturned", true);
		component.set("v.cssCustomStyle", ".forceStyle .viewport .oneHeader.slds-global-header_container {z-index:0} .forceStyle.desktop .viewport{overflow:hidden}");
  },
	closeModal: function(component, event, helper) {
		component.set("v.canBereturned", false);
		component.set("v.cssCustomStyle", ".forceStyle .viewport .oneHeader.slds-global-header_container {z-index:5} .forceStyle.desktop .viewport{overflow:visible}");
	}
})