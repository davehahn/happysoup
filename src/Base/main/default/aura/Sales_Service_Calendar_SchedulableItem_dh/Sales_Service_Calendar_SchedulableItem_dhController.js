({
  toggleDetails: function (component, event, helper) {
    var link = event.currentTarget,
      calId = link.dataset.calType,
      eventType = calId.includes(":") ? calId.split(":")[1] : calId;
    if (["service", "trade", "internal"].indexOf(eventType) >= 0)
      component.set("v.showDetails", !component.get("v.showDetails"));
  }
});
