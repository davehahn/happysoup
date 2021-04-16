/**
 * Created by Tim on 2021-04-15.
 */

({
  doInit : function(component, event, helper) {
    const locale = $A.get("$Locale.langLocale");
    component.set("v.currentLocale", locale);
    if(locale === 'fr'){
      component.set("v.isEN.active", false);
    }
  },
});