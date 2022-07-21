({
  getAvailablePromos: function (component) {
    var self = this,
      attempts = component.get("v.attempts"),
      recordId = component.get("v.recordId"),
      action = component.get("c.getAvailablePromos"),
      la;
    action.setParams({
      recordId: recordId
    });
    la = new LightningApex(this, action);
    la.fire().then(
      $A.getCallback(function (results) {
        if (results == null || results.length > 0) {
          component.set("v.promotions", results);
        } else if (results != null && results == "1") {
          self.getClaims(component);
        }
      }),
      $A.getCallback(function (err) {})
    );
  },

  startClaim: function (component, event) {
    var self = this,
      recordId = component.get("v.recordId"),
      promoId = event.getSource().get("v.value"),
      action = component.get("c.startClaim"),
      la;
    action.setParams({
      recordId: recordId,
      promoId: promoId
    });
    la = new LightningApex(this, action);
    la.fire().then(
      $A.getCallback(function (results) {
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
          url: "/case/" + results.Id
        });
        urlEvent.fire();
      }),
      $A.getCallback(function (err) {
        console.log(err);
      })
    );
  },

  getClaims: function (component) {
    var self = this,
      recordId = component.get("v.recordId"),
      action = component.get("c.getClaims"),
      la;
    action.setParams({
      recordId: recordId
    });
    la = new LightningApex(this, action);
    la.fire().then(
      $A.getCallback(function (results) {
        component.set("v.claims", results);
      }),
      $A.getCallback(function (err) {
        console.log(err);
      })
    );
  }
});
