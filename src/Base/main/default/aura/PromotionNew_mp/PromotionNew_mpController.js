({
	doInit : function(component, event, helper) 
	{
		helper.getDealerAccounts(component)
		.then(
			function() 
			{
				helper.getProducts(component)
				.then(
					function() 
					{
						$A.util.addClass(component.find('spinner'),'slds-hide');
						helper.getPromoDocumentationRequirementOptions(component);
					}
				)
			}
		);
	},

	goToStep2 : function(component, event, helper) 
	{
		$A.util.removeClass(component.find('spinner'),'slds-hide');
		helper.createNewPromotion(component).then(
			function() 
			{
				component.set('v.currentStep','step2');
				$A.util.addClass(component.find('spinner'),'slds-hide');
			}
		);
	},

	goToStep3 : function(component, event, helper) 
	{
		$A.util.removeClass(component.find('spinner'),'slds-hide');
		helper.getDetailedProducts(component).then(
			function() 
			{
				component.set('v.currentStep','step3');
				$A.util.addClass(component.find('spinner'),'slds-hide');
			}
		);
	},

	goToStep4 : function(component, event, helper) 
	{
		$A.util.removeClass(component.find('spinner'),'slds-hide');
		component.set('v.currentStep','step4');
		$A.util.addClass(component.find('spinner'),'slds-hide');
	},

	goBack : function(component, event, helper) 
	{
		var currentStep = component.get('v.currentStep');
		if (currentStep == 'step2') 
		{
			component.set('v.currentStep', 'step1');
		} 
		else if (currentStep == 'step3') 
		{
			component.set('v.currentStep', 'step2');
		}
		else if (currentStep == 'step4') 
		{
			component.set('v.currentStep', 'step3');
		}
	},

	publish : function(component, event, helper) 
	{
		helper.savePromoAndItems(component).then(
			function() 
			{
				var homeEvent = $A.get("e.force:navigateToObjectHome");
		    homeEvent.setParams({
		        "scope": "Promotion__c"
		    });
		    homeEvent.fire();
			}
		);
	}
})