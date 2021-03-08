({
  COLUMNS: [
    {
      label: 'Name',
      fieldName: 'Name',
      type: 'text'
    },
    {
      label: 'ERP Order(s)',
      fieldName: 'billProject',
      type: 'text'
    },
    {
      label: 'Balance',
      fieldName: 'billBalance',
      type: 'currency',
      typeAttributes:
      {
         currencyCode: 'CAD'
      }
    }
  ],

  OTHER_COLUMNS: [
    {
      label: 'Name',
      fieldName: 'Name',
      type: 'text'
    },
    {
      label: 'Balance',
      fieldName: 'AcctSeed__Balance__c',
      type: 'currency',
      typeAttributes: {
         currencyCode: 'CAD'
      }
    }
  ],

  ERP_COLUMNS: [
    {
      label: 'Name',
      fieldName: 'Name',
      type: 'text'
    },
    {
      label: 'Grand Total',
      fieldName: 'grandTotal',
      type: 'currency',
      typeAttributes: {
         currencyCode: 'CAD'
      }
    },
    {
      label: 'Total Billed',
      fieldName: 'billTotal',
      type: 'currency',
      typeAttributes: {
         currencyCode: 'CAD'
      }
    },
    {
      label: 'Unbilled',
      fieldName: 'erpUnbilled',
      type: 'currency',
      typeAttributes: {
        currencyCode: 'CAD'
      }
    }
  ],

  getAccountId: function( component )
  {
    let action = component.get('c.getAccountId');

    action.setParams({
      recordId: component.get('v.recordId')
    });

    return new LightningApex( this, action ).fire();
  },

  runAction : function(component, actionName, params, callback) {
    var action = component.get(actionName);
    action.setParams(params);

    // Register the callback function
    action.setCallback(this, callback);

    // Invoke the service
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
      })
    );
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
  },

  processRefundPayable : function(component, event, helper) {
    helper.toggleSpinner(component, true);
    var transactionData = component.get("v.transactionData");
    var cdType = component.get('v.cdType'),
        refundAmount = component.get('v.refundAmount'),
        idBill = component.get('v.idBill'),
        navEvt = $A.get("e.force:navigateToSObject");

    var refundFromAmount = transactionData.totalARBalance;

    helper.runAction(component, "c.handleRefundPayment", {
        idAccount: component.get("v.accountId"),
        idBill: idBill
    }, function(response) {
        var state = response.getState();
        if (state != "SUCCESS") {
            var errors = response.getError();
            if (errors) {
                helper.toggleSpinner(component, false);
                if (errors[0] && errors[0].message) {
                    helper.showToast(component, "Error In Refund", "error", errors[0].message);
                } else {
                    helper.showToast(component, "Error In Refund", "error", "There was an error creating refund");
                }
                return;
            }
        }
        var results = response.getReturnValue();
        results = JSON.parse(results);
        component.set("v.idBill", results.idBill);
        component.set("v.idPayable", results.idPayable);
        component.set("v.idDisbursement", results.idDisbursement);
        component.set("v.transactionData", JSON.parse(results.txnData));
        helper.openRefundSuccessModal(component, event, helper);
        helper.toggleSpinner(component, false);
    });
  },

  processRefundStart: function(component, event, helper) {
   var self = this;
   self.processBilling(component).then($A.getCallback(function(response) {
       console.log(response);
       var results = response;
       console.log('results billing');
       console.log(results);
       component.set("v.idBill", results.idBill);
       self.processRefundPayment(component, event, helper);
   }), $A.getCallback(function(err) {
       LightningUtils.errorToast(err);
       self.toggleSpinner(component, false);
   }));
  },

  processBilling: function(component) {
    var action = component.get("c.handleRefund"),
       la;
    var cdType = component.get('v.cdType'),
       refundAmount = component.get('v.refundAmount');
    action.setParams({
       idAccount: component.get("v.accountId"),
       paymentMethod: cdType,
       refundAmount: refundAmount
    });
    la = new LightningApex(this, action);
    return la.fire();
  },

  processRefundPayment: function(component, event, helper) {
    var self = this;
    self.processPayment(component).then($A.getCallback(function(response) {
        var results = response;
         console.log('results payable');
         console.log(results);
        console.log('results pay');
        console.log(results);
        component.set("v.idPayable", results.idPayable);
        self.processRefundCD(component);
    }), $A.getCallback(function(err) {
        LightningUtils.errorToast(err);
        self.unpostBillRefund(component, event, helper);
        self.toggleSpinner(component, false);
    }));
  },

  processPayment: function(component, event, helper) {
    var action = component.get("c.handleRefundPayment"),
        la;
    action.setParams({
        idAccount: component.get("v.accountId"),
        idBill: component.get("v.idBill")
    });
    la = new LightningApex(this, action);
    return la.fire();
  },

  processRefundCD: function(component, event, helper) {
    var self = this;
    self.processCD(component).then($A.getCallback(function(response) {
      var results = response;
      console.log('results cd');
      console.log(results);
      component.set("v.idDisbursement", results.idDisbursement);
      component.set("v.transactionData", JSON.parse(results.txnData));
      self.openRefundSuccessModal(component, event, helper);
      self.toggleSpinner(component, false);
    }), $A.getCallback(function(err) {
      LightningUtils.errorToast(err);
      self.unpostBillRefund(component, event, helper);
      self.toggleSpinner(component, false);
    }));
  },

  processCD: function(component, event, helper) {
    var action = component.get("c.handleRefundCD"),
      la;
    var cdType = component.get('v.cdType'),
      refundAmount = component.get('v.refundAmount');
    action.setParams({
      idAccount: component.get("v.accountId"),
      idPayable: component.get("v.idPayable"),
      paymentMethod: cdType
    });
    la = new LightningApex(this, action);
    return la.fire();
  },

  unpostBillRefund: function(component, event, helper) {
    var self = this;
    self.unpostBill(component).then($A.getCallback(function(response) {
      component.set("v.idBill","");
      var idPayable = component.get('v.idPayable');
      if(idPayable != undefined || idPayable != null)
      {
        self.unpostRefundPayment(component);
      }
    }), $A.getCallback(function(err) {
        self.toggleSpinner(component, false);
    }));
  },

  unpostBill: function(component, event, helper) {
    var action = component.get("c.unpostBilling"),
        la;
    action.setParams({
      idBill: component.get("v.idBill")
    });
    la = new LightningApex(this, action);
    return la.fire();
  },

  unpostRefundPayment: function(component, event, helper) {
    var self = this;
    self.unpostPayment(component).then($A.getCallback(function(response) {
        component.set("v.idPayable","");
        var idCD = component.get('v.idDisbursement');
        if(idCD != undefined || idCD != null)
          self.unpostCDRefund(component);
    }), $A.getCallback(function(err) {
        self.toggleSpinner(component, false);
    }));
  },

  unpostPayment: function(component, event, helper) {
    var action = component.get("c.unpostPayable"),
        la;
    action.setParams({
        idPayable: component.get("v.idPayable")
    });
    la = new LightningApex(this, action);
    return la.fire();
  },

  unpostCDRefund: function(component, event, helper) {
    var self = this;
    self.unpostCD(component).then($A.getCallback(function(response) {
        component.set("v.idDisbursement","");
        console.log('CD Deleted');
    }), $A.getCallback(function(err) {
        self.toggleSpinner(component, false);
    }));
  },

  unpostCD: function(component, event, helper) {
    var action = component.get("c.unpostCD"),
        la;
    action.setParams({
        idCD: component.get("v.idDisbursement")
    });
    la = new LightningApex(this, action);
    return la.fire();
  }

})