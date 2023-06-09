({
  initScrollWatch: function (component, event, helper) {
    var header = component.find("cpq-header"),
      content = component.find("cpq-content");
    //sticky;
    if (!$A.util.isEmpty(header) && !$A.util.isEmpty(content)) {
      header = header.getElement();
      content = content.getElement();
      var sticky = header.getBoundingClientRect();
      window.onscroll = function () {
        if (window.pageYOffset > sticky.top) {
          content.style.paddingTop = sticky.height + "px";
          header.classList.add("sticky");
        } else {
          header.classList.remove("sticky");
          content.style.paddingTop = "0px";
        }
      };
    }
  },

  saleTotalChange: function (component, event) {
    //component.find('cpqBuilder').saleTotalChanged(event.getParam("value"));
  },

  handlePreInsuranceTotalChange: function(component, event) {
    component.find('cpqBuilder').preInsuranceAmountChanged(event.getParam("value"));
  },

  doInit: function (component, event, helper) {
    helper.doInit(component);
  },

  handleRefresh: function (component, event, helper) {
    var readOnly = component.get("v.readOnly");
    if (readOnly) helper.doInit(component);
  },

  handleMobileMenuChange: function (component, event, helper) {
    switch (event.getParam("value")) {
      case "calc":
        helper.toggleCalc(component);
        break;
      case "createQuote":
        helper.doToggleCreateQuote(component);
        break;
      case "updateQuote":
        helper.doUpdateQuote(component);
        break;
      case "return":
        helper.doToggleCreateQuote(component);
        break;
      default:
        component.set("v.mobileMenuValue", event.getParam("value"));
    }
  },

  togglePaymentCalc: function (component, event, helper) {
    const hasTermError = component.get('v.hasInsuranceTermErrors');
    if(!hasTermError ){
      helper.toggleCalc(component);
    }
  },

  updateQuote: function (component, event, helper) {
    helper.doUpdateQuote(component);
  },

  cloneQuote: function( component,  event, helper ){
    let cpq = component.get('v.cpq');
    cpq.saveToRecordId = component.get("v.opportunityId");
    component.set('v.cpq', cpq);
    helper.buildQuoteName(component);
    helper.doUpdateQuote(component);
  },

  cancelQuoteDetails: function (component) {
    $A.util.toggleClass(component.find("quote-name-modal"), "slds-hide");
  },

  toggleCreateQuote: function (component, event, helper) {
    helper.doToggleCreateQuote(component);
  },

  handleOppCreated: function (component, event, helper) {
    var oppId = event.getParam("opportunityId");
    helper.buildQuoteName(component);
    component.set("v.recordId", oppId);
    //component.set('v.opportunityId', oppId);
    $A.util.toggleClass(component.find("quote-name-modal"), "slds-hide");
  },

  continueFromQuoteName: function (component, event, helper) {
    var spinner = component.find("spinner"),
      quoteId,
      isFromOpportunity = !$A.util.isUndefinedOrNull(component.get("v.opportunityId")),
      oppId = component.get("v.recordId");
    spinner.toggle();
    helper
      .createQuote(component)
      .then(
        $A.getCallback(function (result) {
          console.log(`%cSAVETORECORDID = ${result}`, 'font-size:18px;color:red;');
          quoteId = result;
          return helper.saveCPQ(component, quoteId);
        }),
        $A.getCallback(function (err) {
          LightningUtils.errorToast(err);
        })
      )
      .then(
        $A.getCallback(function (result) {
          if (isFromOpportunity) {
            var evt = $A.get("e.c:CPQ_SavedForQuote_Event");
            evt
              .setParams({
                quoteId: quoteId
              })
              .fire();
          } else {
            var navEvt = $A.get("e.force:navigateToSObject");
            navEvt
              .setParams({
                recordId: oppId
              })
              .fire();
          }
        }),
        $A.getCallback(function (err) {
          LightningUtils.errorToast(err);
        })
      )
      .finally(
        $A.getCallback(function () {
          spinner.toggle();
        })
      );
  }
});
