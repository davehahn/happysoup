({
    init : function(component, event, helper) {
        try{
            helper.loadERPOrder(component);

        }catch(ex){
            console.log(ex);
        }
    },
    openEditSearch : function(component, event, helper) {
       helper.openEditSearchHelper(component, event);
    },
    goBack : function(component, event, helper) {
       helper.goBackToListView(component, event);
    },
    deleteRecord : function(component, event, helper) {
        helper.deleteRecordHelper(component, event);
    },
    toggleDelete : function(component, event, helper) {
        helper.deleteConfirmPopup(component, event);
    }
//    firstClilck : function(component, event, helper) {
//        var firstTab = component.find('firstTab');
//        var firstTabDetail = component.find('firstDetail');
//
//        var secondTab = component.find('secondTab');
//        var secondTabDetail = component.find('secondDetail');
//
//        $A.util.addClass(firstTab, 'slds-active');
//        $A.util.removeClass(firstTabDetail, 'slds-hide');
//        $A.util.addClass(firstTabDetail, 'slds-show');
//
//        $A.util.removeClass(secondTab, 'slds-active');
//        $A.util.removeClass(secondTabDetail, 'slds-show');
//        $A.util.addClass(secondTabDetail, 'slds-hide');
//    },
//    secondClilck : function(component, event, helper) {
//        var firstTab = component.find('firstTab');
//        var firstTabDetail = component.find('firstDetail');
//
//        var secondTab = component.find('secondTab');
//        var secondTabDetail = component.find('secondDetail');
//
//        $A.util.removeClass(firstTab, 'slds-active');
//        $A.util.removeClass(firstTabDetail, 'slds-show');
//        $A.util.addClass(firstTabDetail, 'slds-hide');
//
//        $A.util.addClass(secondTab, 'slds-active');
//        $A.util.addClass(secondTabDetail, 'slds-show');
//        $A.util.removeClass(secondTabDetail, 'slds-hide');
//    },
})