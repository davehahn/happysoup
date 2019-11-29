({
	checkForExistingJob : function(component) {
		var recordId = component.get('v.recordId'),
				action = component.get('c.checkForExistingJob'), la;
		action.setParams({
			"recordId" : recordId
		});
		la = new LightningApex( this, action );
		return new Promise(function(resolve, reject) {
			la.fire()
			.then(
	      $A.getCallback(
	      	function( response ) {
						resolve( response );
					}
				),
	      $A.getCallback(
	        function( err ) {
	          LightningUtils.errorToast( err );
	        }
	      )
			);
		});
	},

	createJob : function(component) {
		var recordId = component.get('v.recordId'),
				action = component.get('c.createJobFromERP_nochecks'), la;
		action.setParams({
			"erpId" : recordId
		});
		la = new LightningApex( this, action );
		return new Promise(function(resolve, reject) {
			la.fire()
			.then(
	      $A.getCallback(
	      	function( response ) {
	      		component.set('v.state', 'created');
						resolve( response );
					}
				),
	      $A.getCallback(
	        function( err ) {
	          LightningUtils.errorToast( err );
	        }
	      )
			);
		});
	},

	returnJobToBacklog : function(component) {
		var jobId = component.get('v.job').Id,
				action = component.get('c.returnJobToBacklog'), la;
		action.setParams({
			"jobId" :jobId
		});
		la = new LightningApex( this, action );
		return new Promise(function(resolve, reject) {
			la.fire()
			.then(
	      $A.getCallback(
	      	function( response ) {
	      		component.set('v.state', 'returned');
						resolve( response );
					}
				),
	      $A.getCallback(
	        function( err ) {
	          LightningUtils.errorToast( err );
	        }
	      )
			);
		});
	}
})