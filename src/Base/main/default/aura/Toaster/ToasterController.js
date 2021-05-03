({
    showToast : function(component, event, helper) {
        var toast = component.find("toast");

        var params = event.getParam("arguments");

        component.set("v.message", params.message);
        component.set("v.messageType", params.messageType);

        $A.util.removeClass(toast, 'slds-hide');

        if (helper.timer) {
            window.clearTimeout(helper.timer);
        }

        helper.timer = window.setTimeout(
            $A.getCallback( function() {
                $A.util.addClass(toast, 'slds-hide');
            }), 5000);
    },

    closeToast: function(component, event, helper) {
        var toast = component.find("toast");

        window.setTimeout(
            $A.getCallback( function() {
                $A.util.addClass(toast, 'slds-hide');
            })
        );
    }
})