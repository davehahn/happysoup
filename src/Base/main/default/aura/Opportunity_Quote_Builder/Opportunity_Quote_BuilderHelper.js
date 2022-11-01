({
  doInit: function (component) {
    console.log("helper.doInit");
    var self = this;
    return new Promise(function (resolve, reject) {
      self.doFetchQuotes(component).then(
        $A.getCallback(function (result) {
          var selectedId;
          console.log(JSON.parse(JSON.stringify(result)));
          component.set("v.isOutdated", result.isOutdated);
          component.set('v.isPartnerOpportunity', result.isPartnerOpportunity);
          if (result.syncedQuoteId !== undefined && result.syncedQuoteId !== null) {
            component.set("v.syncedQuoteId", result.syncedQuoteId);
            component.set("v.syncedQuoteName", result.syncedQuoteName);
            selectedId = result.syncedQuoteId;
          } else if (result.quotes.length > 0) {
            selectedId = result.quotes[0].Id;
          }
          if (selectedId === null || selectedId === undefined) {
            console.log('selected ID null');
            component.set("v.loadCPQ", true);
          }
          component.set("v.url", result.url);
          component.set("v.quotes", result.quotes);
          component.set("v.selectedQuoteId", selectedId);
          resolve();
        }),
        $A.getCallback(function (err) {
          reject(err);
        })
      );
    });
  },

  doFetchQuotes: function (component) {
    var action = component.get("c.fetchQuotes");
    action.setParams({
      oppId: component.get("v.recordId")
    });
    return new LightningApex(this, action).fire();
  },

  confirm: function (component, confirmParams) {
    var confirmCmp = component.find("confirm"),
      syncedQuoteName = component.get("v.syncedQuoteName"),
      selectedQuote = component.get("v.selectedQuote"),
      title = "Sync " + selectedQuote.Name + " to Opportunity",
      message = "After a quote is synced, opportunity products and quote line items are updated automatically.";

    if (syncedQuoteName !== undefined) {
      title = "Are you sure?";
      var m = "<b>" + syncedQuoteName + "</b> is already synced with this opportunity.<br />";
      m += " An opportunity can be synced with only one quote.<br /><br />";
      m += " If you continue, <br>" + syncedQuoteName + "</b>  won’t sync and ";
      m += "the opportunity will be synced with <b>" + selectedQuote.Name + "</b>.<br /><br />";
      m += message;
      message = m;
    }
    return new Promise(function (resolve, reject) {
      component.addEventHandler("c:lgnd_Confirm_Response_Event", function (auraEvent) {
        auraEvent.getParam("theResponse") ? resolve() : reject();
      });
      confirmCmp.showConfirm({ title: title, message: message });
    });
  },

  setSelectedQuote: function (component, qId) {
    for (let q of component.get("v.quotes")) {
      if (q.Id === qId) {
        component.set("v.selectedQuote", q);
        break;
      }
    }
  },

  toggleQuoteList: function (component) {
    console.log("toggle Quote List");
    var ql = component.find("quote-list-container"),
      mask = component.find("menu-mask");
    $A.util.toggleClass(ql, "open");
    $A.util.toggleClass(mask, "open");
  },

  loadCPQ: function (component) {
    component.set("v.loadCPQ", true);
    var container = component.find("cpq-container"),
      isNew = component.get("v.creatingNewQuote");
    $A.createComponent(
      "c:CPQ_dh",
      {
        recordId: isNew ? null : component.get("v.selectedQuoteId"),
        opportunityId: component.get("v.recordId"),
        isPartnerOpportunity: component.get('v.isPartnerOpportunity')
      },
      function (cpq, status, errorMessage) {
        if (status === "SUCCESS") {
          var container_body = container.get("v.body");
          container_body.push(cpq);
          container.set("v.body", container_body);
        } else if (status === "INCOMPLETE") {
          LightningUtils.errorToast("No response from server or client is offline.");
        } else if (status === "ERROR") {
          LightningUtils.errorToast("Error: " + errorMessage);
        } else {
          console.log("something wrong");
        }
      }
    );
  },

  doCancel: function (component) {
    var selectedQuoteId = component.get("v.selectedQuoteId"),
      syncedQuoteId = component.get("v.syncedQuoteId"),
      container = component.find("cpq-container"),
      quoteIdToUse = selectedQuoteId !== null ? selectedQuoteId : syncedQuoteId;
    component.set("v.selectedQuoteId", quoteIdToUse);
    component.set("v.creatingNewQuote", false);
    component.set("v.loadCPQ", false);
    container.set("v.body", []);
  },

  doSync: function (component) {
    var action = component.get("c.syncQuoteToOpp");
    action.setParams({
      quoteId: component.get("v.selectedQuoteId"),
      oppId: component.get("v.recordId")
    });
    return new LightningApex(this, action).fire();
  },

  updateQuote: function (component, quote) {
    var action = component.get("c.updateQuote");
    action.setParams({
      quoteJSON: quote
    });
    return new LightningApex(this, action).fire();
  }
});
