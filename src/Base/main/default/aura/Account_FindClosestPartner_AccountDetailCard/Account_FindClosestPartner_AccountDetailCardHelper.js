({
  navToUrl: function (url) {
    var nav = $A.get("e.force:navigateToURL");
    nav
      .setParams({
        url: url
      })
      .fire();
  }
});
