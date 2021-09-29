/**
 * Created by Tim on 2021-04-22.
 */

({
  goHome : function(component, event, helper){
      const navService = component.find("navService");
      let pageReference = {
        type: "comm__namedPage",
        attributes: {
          pageName: "home"
        }
      }
      navService.navigate(pageReference);
    },

   doInit : function(component, event, helper) {
   			var locale = $A.get("$Locale.language");
   			var isEN = (locale === 'en') ? true : false;
   		}
});

