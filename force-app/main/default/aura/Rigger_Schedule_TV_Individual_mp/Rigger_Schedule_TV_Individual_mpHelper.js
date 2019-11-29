({
  init : function(component) {
    var self = this,
        action = component.get('c.getMyJobs'),
        riggerId = component.get('v.rigger').Id;
    action.setParams({
      "riggerId": riggerId
    });
    self.getJobs(component, riggerId, action);
    window.setInterval(
      $A.getCallback(function() {
        self.getJobs(component, riggerId, action);
      }), 60000
    );
  },

	getJobs : function(component, riggerId, action) {
    console.log('helper.getJobs');
    var self = this,
        jobs = component.get('v.jobs');
    self.actionHandler(action, true).then(function(wrappedJobs) {
      console.log('*** INDIVIDUAL JOBS ***');
      console.log(wrappedJobs);
      for (j of wrappedJobs) {
        j.job.CreatedDate = j.job.CreatedDate.substr(0,10);
        
        if (j.job.DueDate__c) {
          j.job.age = self.daysBetween(new Date(), j.job.DueDate__c);
        } else {
          j.job.age = null;
        }
        
        if (j.job.Placeholder__c)
          j.job.class="dragItem card-collapsed placeholder";
        else if (j.job.ERP_Order__r.Job_Status__c == 'In Progress')
          j.job.class="dragItem card-collapsed inProgress";
        else if (   j.job.ERP_Order__r.Job_Status__c == 'Parts Required'
                 || j.job.ERP_Order__r.Job_Status__c == 'Boat Required'
                 || j.job.ERP_Order__r.Job_Status__c == 'Additional Rigging Required')
          j.job.class="dragItem card-collapsed onHold";
        else if (   j.job.ERP_Order__r.Job_Status__c == 'Sublet'
                 || j.job.ERP_Order__r.Job_Status__c == 'Warranty'
                 || j.job.ERP_Order__r.Job_Status__c == 'Factory Return'
                 || j.job.ERP_Order__r.Job_Status__c == 'Insurance')
          j.job.class="dragItem card-collapsed yellow";
        else
          j.job.class="dragItem card-collapsed";

        if (j.materials) {
          for (m of j.materials) {
            if (m.AcctSeedERP__Product__c != null && m.AcctSeedERP__Product__r.Family == 'Canvas') {
              if (j.materialsText == undefined) {
                j.materialsText = m.Product_Name__c;
              } else {
                j.materialsText += '; ' + m.Product_Name__c;
              }
            }
            if (m.Product_Record_Type__c != null && m.Product_Record_Type__c == 'Boat') {
              j.job.Manufactured_Product_Name__c = m.Product_Name__c;
            }
          }
        }

        if (j.job.ERP_Order__c !== undefined) {
          if (   j.job.ERP_Order__r.RecordType.Name == 'Retail Boat Sale'
              || j.job.ERP_Order__r.RecordType.Name == 'Legend Service Work Order' ) {
            j.job.Notes__c = null;
          }
        }

        // Strip out any HTML, such as <br> tags
        if (j.job.Notes__c != null) {
          j.job.Notes__c = j.job.Notes__c.replace(/<(?:.|\n)*?>/gm, ' ');
        }
      }
      component.set('v.jobs', wrappedJobs);
    });
  },

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
              console.log( 'Lightning apex error')
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

  treatAsUTC : function(date) {
    var result = new Date(date);
    result.setMinutes(result.getMinutes() - result.getTimezoneOffset());
    return result;
  },

  daysBetween : function(startDate, endDate) {
      var self = this,
          millisecondsPerDay = 24 * 60 * 60 * 1000;
      return Math.round((self.treatAsUTC(endDate) - self.treatAsUTC(startDate)) / millisecondsPerDay);
  }
})