({
  onClick: function (component, event, helper) {
    const id = event.target.dataset.menuItemId;
    const expander = event.currentTarget.dataset.expander;

    if (id) {
      component.getSuper().navigate(id);
    }

    if (expander) {
      const navList = component.find("navList").getElement();
      const burger = component.find("burger").getElement();

      event.currentTarget.classList.toggle("open");
      navList.classList.toggle("show");
      burger.classList.toggle("open");
    }
  }
});
