({
	doInit : function( component, event, helper )
	{
		helper.getPromoCases(component, event);
	},

	claimIt : function( component, event, helper )
	{
		helper.claimPromotion(component, event);
	}
})