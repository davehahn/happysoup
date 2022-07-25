({
  afterRender: function (component, helper) {
    this.superAfterRender();
    console.log("afterRender");
    var header = component.find("cpq-header");
    if (!$A.util.isEmpty(header)) {
      header = header.getElement();
      var sticky = header.getBoundingClientRect().top;
      window.onscroll = function () {
        console.log(window.pageYOffset);
        if (window.pageYOffset > sticky) {
          helper.handleScroll(component, true);
        } else {
          helper.handleScroll(component, false);
        }
      };
    }
  }
});
