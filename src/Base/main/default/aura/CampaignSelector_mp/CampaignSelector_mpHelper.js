({
	initialize : function(component) {
		this.initData(component)
		.then(
			$A.getCallback(function(result) {
				console.log(result);
				var options = [],
						i = 0;
				for (var key in result) {
					// console.log(r);
					options[i] = {Id: key, Name: result[key]};
					i++;
				}
				console.log(options);
				component.set('v.campaignOptions', options);
			}),
			$A.getCallback(function(err) {
				LightningUtils.showToast('error', 'An error has been encountered', err );
			})
		);
	},

	initData : function(component) {
		var action = component.get('c.getCampaignSources'), la;
		la = new LightningApex(this, action);
		return la.fire();
	}
})