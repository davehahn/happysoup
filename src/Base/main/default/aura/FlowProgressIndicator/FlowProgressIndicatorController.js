({
   init : function(component, event, helper) {
      var progressIndicator = component.find('progressIndicator');
      for (let step of component.get('v.stages')) {
         $A.createComponent(
            "lightning:progressStep",
            {
               "aura:id": "step_" + step,
               "label": step,
               "value": step
             },
             function(newProgressStep, status, errorMessage){
          
                if (status === "SUCCESS") {
                   var body = progressIndicator.get("v.body");
                   body.push(newProgressStep);
                   progressIndicator.set("v.body", body);
                 }
                 else if (status === "INCOMPLETE") {
                    console.log("No response from server, or client is offline.")
                  }
                  else if (status === "ERROR") {
                     console.log("Error: " + errorMessage);
                  }
              }
           );
       }
   }
})