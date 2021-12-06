({
  getJobs : function(component) {
    console.log('individual helper.getJobs');

    var self = this,
        warehouse = component.get('v.city'),
        riggerId = component.get('v.rigger').Id,
        jobs = component.get('v.jobs'),
        action = component.get('c.getMyJobs'), la,
        hours = 0;

    return new Promise(function( resolve, reject ) {

      action.setParams({
        "riggerId": riggerId,
        "warehouse": warehouse
      });

      la = new LightningApex( this, action );
      la.fire().then(
        $A.getCallback( 
          function( wrappedJobs ) {
            console.log('getJobs callback');
            console.log('JSON.stringify(wrappedJobs )= '+JSON.stringify(wrappedJobs ));
            console.log( JSON.parse(JSON.stringify(wrappedJobs )));
            wrappedJobs.forEach( j => {
              console.log(j);
              j.job.CreatedDate = j.job.CreatedDate.substr(0,10);

              if (j.job.DueDate__c) {
                j.job.age = self.daysBetween(new Date(), j.job.DueDate__c);
              } else {
                j.job.age = null;
              }
              var cardClass = 'job-card slds-box dragItem card-collapsed'
              if (j.job.Placeholder__c)
                //j.job.class="slds-box dragItem card-collapsed placeholder";
                cardClass += ' placeholder';
              else if (j.job.ERP_Order__r.Job_Status__c == 'In Progress')
                //j.job.class="slds-box dragItem card-collapsed inProgress";
                cardClass += ' inProgress';
              else if (   j.job.ERP_Order__r.Job_Status__c == 'Parts Required'
                       || j.job.ERP_Order__r.Job_Status__c == 'Boat Required'
                       || j.job.ERP_Order__r.Job_Status__c == 'Additional Rigging Required')
                cardClass += ' onHold';
                //j.job.class="slds-box dragItem card-collapsed onHold";
              else if (   j.job.ERP_Order__r.Job_Status__c == 'Sublet'
                       || j.job.ERP_Order__r.Job_Status__c == 'Warranty'
                       || j.job.ERP_Order__r.Job_Status__c == 'Factory Return'
                       || j.job.ERP_Order__r.Job_Status__c == 'Insurance')
                //j.job.class="slds-box dragItem card-collapsed yellow";
                cardClass += ' yellow';
              else if (   j.job.ERP_Order__r.Job_Status__c == 'In Storage')
                //j.job.class="slds-box dragItem card-collapsed instorage";
                cardClass += ' instorage';
              //else
              //  j.job.class="slds-box dragItem card-collapsed";
              j.job.class = cardClass;

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
                  if (m.Product_Record_Type__c == 'Trailer') {
                    j.trailer = m;
                  }
                }
              }

              if (j.job.ERP_Order__c !== undefined) {
                if (   j.job.ERP_Order__r.RecordType.Name == 'Retail Boat Sale'
                    || j.job.ERP_Order__r.RecordType.Name == 'Legend Service Work Order' ) {
                  j.job.Notes__c = null;
                }
                if (j.job.ERP_Order__r.Delivery_Date__c != null) {
                  j.job.ERP_Order__r.Delivery_Date__c = j.job.ERP_Order__r.Delivery_Date__c.substr(0,10);
                }
                if (j.job.ERP_Order__r.Service_Date__c != null) {
                  j.job.ERP_Order__r.Service_Date__c = j.job.ERP_Order__r.Service_Date__c.substr(0,10);
                }
              }

              // Strip out any HTML, such as <br> tags
              if (j.job.Notes__c != null) {
                j.job.Notes__c = j.job.Notes__c.replace(/<(?:.|\n)*?>/gm, ' ');
              }

              if (j.timeEstimate !== undefined) {
                hours += parseFloat(j.timeEstimate);
              }
            })
//            for(j of wrappedJobs) {
//
//            }
            component.set('v.hours', Number(Math.round(hours+'e2')+'e-2'));

            $A.util.addClass(component.find('spinner'), 'slds-hide');
            resolve( wrappedJobs );
          }
        ),
        $A.getCallback( 
          function( err ) {
            console.log(err);
            LightningUtils.errorToast( err );
            $A.util.addClass(component.find('spinner'), 'slds-hide');
            reject( err );
          }
        )
      );
    });
  },

	assignJob : function(component, event, riggerId) {
    console.log('individual helper.assignJob');
    var self = this,
        action = component.get('c.assignJob'), la,
        jobId = component.get('v.draggedItemId');
    return new Promise(function( resolve, reject ) {
      action.setParams({
        "riggerId": riggerId,
        "jobId": jobId
      });
      la = new LightningApex( this, action );
      la.fire().then(
        $A.getCallback( 
          function( results ) {
            console.log('individual helper.assignJob.actionHandler');
            resolve();
          }
        ),
        $A.getCallback( 
          function( err ) {
            console.log(err);
            LightningUtils.errorToast( err );
            $A.util.addClass(component.find('spinner'), 'slds-hide');
            reject();
          }
        )
      );
    });
	},

  saveJobOrder : function(component, event) {
    console.log('individual helper.saveJobOrder');
    var self = this,
        elements = event.target.closest('.dropContainer').querySelectorAll('div.dragItem'),
        items = [],
        i = 0,
        action = component.get('c.saveJobOrder'), la;
    return new Promise(function( resolve, reject ) {

      for (el of elements) {
        items[i] = {};
        items[i].Id = el.id;
        items[i].list_order__c = parseInt(i);
        i++;
      }

      items = JSON.stringify(items);

      action.setParams({
        "items": items
      });

      la = new LightningApex( this, action );
      la.fire().then(
        $A.getCallback( 
          function( results ) {
            console.log('individual helper.saveJobOrder.actionHandler');
            resolve();
          }
        ),
        $A.getCallback( 
          function( err ) {
            console.log(err);
            LightningUtils.errorToast( err );
            reject();
          }
        )
      );
    });
  },

  mergePlaceholder : function(component, event) {
    console.log('mergePlaceholder');
    var self = this,
        placeholderId = event.srcElement.id,
        jobId = component.get('v.draggedItemId'),
        action = component.get('c.mergePlaceholder'), la;
    console.log(placeholderId + ', ' + jobId);
    action.setParams({
      "placeholderId": placeholderId,
      "jobId": jobId
    });
    la = new LightningApex( this, action );
    la.fire().then(
      $A.getCallback( 
        function( results ) {
          console.log('individual helper.mergePlaceholder.actionHandler');
          if (results) {
            $A.get('e.c:Rigging_ItemDropped_Event').fire();
          }
        }
      ),
      $A.getCallback( 
        function( err ) {
          console.log(err);
          LightningUtils.errorToast( err );
        }
      )
    );
  },

  setJobStart : function(component, event) {
    console.log('individual helper.setJobStart');
    var self = this,
        card = event.srcElement.parentElement.parentElement,
        dataSet = event.currentTarget.dataset,
        action = component.get('c.setJobStart'), la;
    $A.util.toggleClass(card, "busy");
    console.log( dataSet );
    action.setParams({
      "jobId" : dataSet.jobId,
      "timeEntryId": dataSet.timeEntryId === "null" ? null : dataSet.timeEntryId
    });
    la = new LightningApex( this, action );
    la.fire().then(
      $A.getCallback(
        function( results ) {
          console.log('individual helper.setJobStart.actionHandler');
           return self.getJobs(component);
        }
      ),
      $A.getCallback(
        function( err ) {
          console.log(err);
          LightningUtils.errorToast( err );
        }
      )
    )
    //getJobs Promise
    .then(
      $A.getCallback( function( jobs ) {
        component.set('v.jobs', jobs);
      }),
      $A.getCallback( function( err ) {
        LightningUtils.errorToast( err );
      })
    )
    .finally( $A.getCallback( function() {
      $A.util.toggleClass(card, "busy");
    }))
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
	},

  toggleCard : function(card) {
    if (card.classList.contains('card-expanded')) {
      $A.util.removeClass(card, 'card-expanded');
      $A.util.addClass(card, 'card-collapsed');
    } else {
      $A.util.addClass(card, 'card-expanded');
      $A.util.removeClass(card, 'card-collapsed');
    }
  }
})