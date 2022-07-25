({
  afterRender: function (component, helper) {
    this.superAfterRender();
    var header = component.find("cpq-header");
    if (!$A.util.isEmpty(header)) {
      header = header.getElement();
      var sticky = header.getBoundingClientRect().top;
      window.onscroll = function () {
        if (window.pageYOffset > sticky) {
          helper.handleScroll(component, true);
        } else {
          helper.handleScroll(component, false);
        }
      };
    }
  }
});
