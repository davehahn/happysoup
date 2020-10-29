({
    doInit: function(component, event, helper) {
        helper.toggleSpinner(component, false);
        var idRec = component.get("v.recordId");
        if(idRec != null){
          component.set("v.donotShowTop",true);
          component.set("v.idSerial",idRec);
          component.set("v.idProduct","");
          component.set("v.idWarehouse","");
          helper.retrievehistory(component, event, helper);
        }else{
          helper.runAction(component, "c.yearStartDate", {}, function(response) {
              component.set("v.today", response.getReturnValue());
          });
          helper.runAction(component, "c.listWarehouses", {}, function(response) {
              component.set("v.whOptions", response.getReturnValue());
          });
          helper.runAction(component, "c.checkCanSeeGLAmount", {}, function(response) {
              component.set("v.canSeeGLAmount", response.getReturnValue());
          });
        }
    },
    warehouseChanged: function(component, event, helper) {
        helper.retrievehistory(component, event, helper);
    },
    changeTotal: function(component) {
    	var listData = component.get("v.listData");
    	var totalQ = 0;
    	if(listData && listData != null & listData != undefined)
    	{
	    	for(var i=0; i < listData.length; i++)
	    		totalQ += parseFloat(listData[i].quantity);
	    }
    	component.set("v.availableQuantity",totalQ);
    },
    handleFilterSelected: function( component, event, helper )
    {
        var idFilter = event.getParam("filterId");
        component.set("v.idProduct",idFilter);
        helper.clearSerialSearch(component);
        helper.retrievehistory(component, event, helper);
    },
    handleSerialSelected: function( component, event, helper )
    {
        var idSerial = event.getParam("serialId");
        component.set("v.idSerial",idSerial);
        component.set("v.idProduct","");
        component.set("v.idWarehouse","");
        helper.clearProductSearch(component);
        helper.retrievehistory(component, event, helper);
    }
})