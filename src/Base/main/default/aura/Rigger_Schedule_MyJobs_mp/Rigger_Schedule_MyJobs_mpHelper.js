({
	getRiggers : function(component) {
		console.log('helper.getRiggers');
		var self = this,
				action = component.get('c.getListOfRiggers');
		return new Promise(function(resolve, reject) {
			self.actionHandler(action, false).then(function(riggers) {
				console.log(riggers);
				component.set('v.riggers', riggers);
				resolve();
			});
		});
	},

	getMyJobs : function(component) {
		console.log('helper.getMyJobs');
		var self = this,
				riggerId = component.get('v.selectedRiggerId'),
				action = component.get('c.getMyJobs');
		action.setParams({
			"riggerId": riggerId
		});
		self.actionHandler(action, false).then(function(jobs) {
      console.log('JULY:');
      console.log(jobs);
      for (job of jobs) {
        job.CreatedDate = job.CreatedDate.substr(0,10);
      
        if (job.DueDate__c) {
          job.age = self.daysBetween(new Date(), job.DueDate__c);
        } else {
          job.age = null;
        }
        
        if (job.age > -1)
          job.class="slds-box dragItem dueLater";
        else if (job.age == -1)
          job.class="slds-box dragItem dueToday";
        else if (job.age < -1)
          job.class="slds-box dragItem dueDateMissed";
        else
          job.class="slds-box dragItem";
      }
			component.set('v.jobs', jobs);
		});
	},

  getMyCompletedJobs : function(component) {
    console.log('helper.getMyJobs');
    var self = this,
        riggerId = component.get('v.selectedRiggerId'),
        action = component.get('c.getMyCompletedJobs');
    action.setParams({
      "riggerId": riggerId
    });
    self.actionHandler(action, false).then(function(jobs) {
      component.set('v.myCompletedJobs', jobs);
    });
  },

  assignJob : function(component, riggerId) {
    console.log('city helper.assignJob');
    var self = this,
        action = component.get('c.assignJob'),
        jobId = component.get('v.draggedItemId');
    console.log('riggerId: ' + riggerId);
    console.log('jobId: ' + jobId);
    action.setParams({
      "riggerId": riggerId,
      "jobId": jobId
    });
    self.actionHandler(action, false).then(function() {
      // $A.get("e.force:refreshView").fire();
    });
  },

  /* Utilities */

	actionHandler: function( action, deserialize ) {
		console.log('helper.actionHandler');
    var self = this;
    return new Promise( function( resolve, reject ) {
      action.setCallback(self, function(response) {
        var state = response.getState();
        console.log(state);
        if( state === 'SUCCESS' )
        {
          var result = response.getReturnValue();
          if( typeof result === 'string')
          {
            try {
              result = result.replace(/(\r|\n)/gm, "");
              result = JSON.parse( result );
            }
            catch(err) {
              console.log(err);
            }
          }
          resolve( result );
        }
        if( state === 'INCOMPLETE' )
        {
          reject( 'incomplete' );
        }
        if( state === 'ERROR' )
        {
          var errors = response.getError();
          if (errors) {
            if (errors[0] && errors[0].message) {
              reject("Error message: " +
                     errors[0].message);
            }
          } else {
            reject("Unknown error");
          }
        }
      });

      $A.enqueueAction( action );
    });
  },

  treatAsUTC: function(date) {
    var result = new Date(date);
    result.setMinutes(result.getMinutes() - result.getTimezoneOffset());
    return result;
  },

  daysBetween: function(startDate, endDate) {
      var self = this,
          millisecondsPerDay = 24 * 60 * 60 * 1000;
      return Math.round((self.treatAsUTC(endDate) - self.treatAsUTC(startDate)) / millisecondsPerDay);
  }
})