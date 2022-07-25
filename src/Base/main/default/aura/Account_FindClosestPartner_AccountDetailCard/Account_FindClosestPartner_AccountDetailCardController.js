({
  navToWebsite: function (component, event, helper) {
    event.preventDefault();
    helper.navToUrl("http://" + event.currentTarget.getAttribute("href"));
  },

  showDirections: function (component, event, helper) {
    var origin,
      acct = component.get("v.acct"),
      url = "https://google.com/maps/dir/";
    url += component.get("v.originAddress").split(" ").join("+");
    url += "/" + acct.location.Street.split(" ").join("+") + ",";
    url += "+" + acct.location.City + ",";
    url += "+" + acct.location.State;
    helper.navToUrl(url);
  }
});
