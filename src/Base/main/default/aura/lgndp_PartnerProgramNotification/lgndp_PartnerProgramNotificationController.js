/**
 * Created by dave on 2020-07-28.
 */

({
  closeSuccess: function (component) {
    let message = component.get("v.message");
    message.appliedDiscountNames = null;
    component.set("v.message", message);
  },

  closeError: function (component) {
    let message = component.get("v.message");
    message.errors = null;
    component.set("v.message", message);
  }
});
