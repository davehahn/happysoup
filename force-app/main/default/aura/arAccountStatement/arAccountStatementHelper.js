({
 runAction : function(component, actionName, params, callback) {
				var action = component.get(actionName);
				action.setParams(params);

				// Register the callback function
				action.setCallback(this, callback);

				// Invoke the service
				$A.enqueueAction(action);
 },
			showToast : function(component, title, type, message) {
				// var toast = component.find("toast");
				// toast.showToast(message, type);
				var toastEvent = $A.get("e.force:showToast");
				toastEvent.setParams({
							"title": title,
							"type": type,
							"message": message
				});
				toastEvent.fire();
	},
	validate : function(component, event, helper) {
		var transactionData = component.get("v.transactionData");
		var amount = component.get('v.refundAmount'),
				cdType = component.get('v.cdType');
		var refundFromAmount = transactionData.totalARBalance;

		if (amount >= 0 || amount == undefined || amount == '' || isNaN(amount)) {
			component.set('v.btnDisabled', true);
		}else if (amount < refundFromAmount ) {
			//helper.showToast(component, "Error", "error", "Refund must be less than "+refundFromAmount);
			component.set('v.btnDisabled', true);
		} else {
			component.set('v.btnDisabled', false);
		}
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
			openRefundModal: function(component, event, helper) {
			 component.set("v.isRefund", true);
			 component.set("v.cssCustomStyle", ".forceStyle .viewport .oneHeader.slds-global-header_container {z-index:0} .forceStyle.desktop .viewport{overflow:hidden}");
			},
			closeRefundModal: function(component, event, helper) {
			 component.set("v.isRefund", false);
			 component.set("v.cssCustomStyle", ".forceStyle .viewport .oneHeader.slds-global-header_container {z-index:5} .forceStyle.desktop .viewport{overflow:visible}");
			},
			openRefundSuccessModal: function(component, event, helper) {
			 component.set("v.isRefundSuccess", true);
			 component.set("v.cssCustomStyle", ".forceStyle .viewport .oneHeader.slds-global-header_container {z-index:0} .forceStyle.desktop .viewport{overflow:hidden}");
			},
			closeRefundSuccessModal: function(component, event, helper) {
			 component.set("v.isRefundSuccess", false);
			 component.set("v.cssCustomStyle", ".forceStyle .viewport .oneHeader.slds-global-header_container {z-index:5} .forceStyle.desktop .viewport{overflow:visible}");
			},
			openModelBill: function(component, event, helper) {
				var billTable = component.find('billDataTable');
				if(billTable != undefined && billTable.length){
					for(var i = 0; i < billTable.length; i++)
						billTable[i].destroy();
				}

			 component.set("v.isOpen", true);
			 component.set("v.isBillList", true);
			 component.set("v.listTitle", "Billings");
			 component.set("v.listData", component.get("v.transactionData").listBillings);
			 component.set("v.cssCustomStyle", ".forceStyle .viewport .oneHeader.slds-global-header_container {z-index:0} .forceStyle.desktop .viewport{overflow:hidden}");
			},
			openModelPayable: function(component, event, helper) {
			 component.set("v.isOpen", true);
			 component.set("v.isOtherList", true);
			 component.set("v.listTitle", "Payables");
			 component.set("v.listData", component.get("v.transactionData").listPayables);
			 component.set("v.cssCustomStyle", ".forceStyle .viewport .oneHeader.slds-global-header_container {z-index:0} .forceStyle.desktop .viewport{overflow:hidden}");
			},
			openModelCD: function(component, event, helper) {
			 component.set("v.isOpen", true);
			 component.set("v.isOtherList", true);
			 component.set("v.listTitle", "Disbursements");
			 component.set("v.listData", component.get("v.transactionData").listDisbursements);
			 component.set("v.cssCustomStyle", ".forceStyle .viewport .oneHeader.slds-global-header_container {z-index:0} .forceStyle.desktop .viewport{overflow:hidden}");
			},
			openModelERP: function(component, event, helper) {
			 component.set("v.isOpen", true);
			 component.set("v.isERPList", true);
			 component.set("v.listTitle", "ERP Unbilled");
			 component.set("v.listData", component.get("v.transactionData").listERP);
			 component.set("v.cssCustomStyle", ".forceStyle .viewport .oneHeader.slds-global-header_container {z-index:0} .forceStyle.desktop .viewport{overflow:hidden}");
			},
			openModelCR: function(component, event, helper) {
			 component.set("v.isOpen", true);
			 component.set("v.isCRList", true);
			 component.set("v.listTitle", "Cash Receipts");
			 component.set("v.cssCustomStyle", ".forceStyle .viewport .oneHeader.slds-global-header_container {z-index:0} .forceStyle.desktop .viewport{overflow:hidden}");
			},
			closeModel: function(component, event, helper) {
				var billTable = component.find('billDataTable');
				if(billTable != undefined && billTable.length){
					for(var i = 0; i < billTable.length; i++)
						billTable[i].destroy();
				}
				component.set("v.isOpen", false);
				component.set("v.isERPList", false);
				component.set("v.isCRList", false);
				component.set("v.isBillList", false);
				component.set("v.isOtherList", false);
				component.set("v.listTitle", "");
				component.set("v.listData", []);
				component.set("v.cssCustomStyle", ".forceStyle .viewport .oneHeader.slds-global-header_container {z-index:5} .forceStyle.desktop .viewport{overflow:visible}");
			}
})