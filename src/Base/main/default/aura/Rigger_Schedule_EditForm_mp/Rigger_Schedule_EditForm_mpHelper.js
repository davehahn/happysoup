({
	getJob : function(component) {
		var self = this,
				jobId = component.get('v.selectedJobId'),
				action = component.get('c.getJob');
    return new Promise(function(resolve, reject) {
      action.setParams({
        "jobId":jobId
      });

      self.actionHandler(action, false).then(function(wrapper) {
        resolve( wrapper );
      });
    });
	},

	saveJob : function(component) {
		var self = this,
				job = component.get('v.job'),
				action = component.get('c.saveJob'),
        location, shippingStatus, riggingStatus, jobStatus, sernoStatus;

    component.set('v.loading', true );
    if (job.ERP_Order__c !== undefined) {
      if (job.ERP_Order__r.GMBLASERP__Warehouse__r.Name) location = job.ERP_Order__r.GMBLASERP__Warehouse__r.Name;
      if (job.ERP_Order__r.Shipping_Status__c) shippingStatus = job.ERP_Order__r.Shipping_Status__c;
      if (job.ERP_Order__r.Rigging_Status__c) riggingStatus = job.ERP_Order__r.Rigging_Status__c;
      if (job.ERP_Order__r.Job_Status__c) jobStatus = job.ERP_Order__r.Job_Status__c;
      if (job.ERP_Order__r.Serial_Number__c !== undefined) {
        if (job.ERP_Order__r.Serial_Number__r.Lot_Exchange__c == null) {
          if (job.ERP_Order__r.Serial_Number__r.Status__c) sernoStatus = job.ERP_Order__r.Serial_Number__r.Status__c;
        }
      }
    }
    var params = {
      "jobId" : job.Id,
       "location" : location,
       "notes" : job.Notes__c,
       "shippingStatus" : shippingStatus,
       "riggingStatus" : riggingStatus,
       "jobStatus" : jobStatus,
       "sernoStatus" : sernoStatus,
       "expectedTime" : job.ExpectedTime__c,
 //      "actualTime" : job.ActualTime__c,
       "warrantyTime": job.Warranty_Time__c ? parseFloat(job.Warranty_Time__c) : null,
       "nonWarrantyTime": job.Non_Warranty_Time__c ? parseFloat(job.Non_Warranty_Time__c) : null,
       "parking" : job.ERP_Order__r.Parking_Spot__c
    };
    console.log( 'HERE *******' );
    console.dir( params );
		action.setParams( params );
		self.actionHandler(action, false).then(
      $A.getCallback( 
        function( result ) {
          $A.get("e.c:Rigging_ItemDropped_Event").fire();
          component.set('v.selectedJobId', null);
        }
      ),
      $A.getCallback( 
        function( err ) {
          LightningUtils.errorToast( err );
        }
      )
		)
		.finally( $A.getCallback( function() {
		  component.set('v.loading', false );
    }));
	},

  saveJobToBacklog : function(component) {
    $A.util.removeClass(component.find('formSpinner'), 'slds-hide');
    var self = this,
        job = component.get('v.job'),
        action = component.get('c.saveJobToBacklog'),
        location, shippingStatus, riggingStatus, jobStatus, sernoStatus;

    component.set('v.loading', true );
    if (job.ERP_Order__c !== undefined) {
      if (job.ERP_Order__r.WarehouseName__c) location = job.ERP_Order__r.WarehouseName__c;
      if (job.ERP_Order__r.Shipping_Status__c) shippingStatus = job.ERP_Order__r.Shipping_Status__c;
      if (job.ERP_Order__r.Rigging_Status__c) riggingStatus = job.ERP_Order__r.Rigging_Status__c;
      if (job.ERP_Order__r.Job_Status__c) jobStatus = job.ERP_Order__r.Job_Status__c;
      if (job.ERP_Order__r.Serial_Number__c !== undefined) {
        if (job.ERP_Order__r.Serial_Number__r.Lot_Exchange__c == null) {
          if (job.ERP_Order__r.Serial_Number__r.Status__c) sernoStatus = job.ERP_Order__r.Serial_Number__r.Status__c;
        }
      }
    }

    action.setParams({
      "jobId" : job.Id,
      "location" : location,
      "notes" : job.Notes__c,
      "shippingStatus" : shippingStatus,
      "riggingStatus" : riggingStatus,
      "jobStatus" : jobStatus,
      "sernoStatus" : sernoStatus,
      "expectedTime" : job.ExpectedTime__c,
      //"actualTime" : job.ActualTime__c,
      "warrantyTime": job.Warranty_Time__c ? job.Warranty_Time__c : null,
      "nonWarrantyTime": job.Non_Warranty_Time__c ? job.Non_Warranty_Time__c : null,
      "parking" : job.ERP_Order__r.Parking_Spot__c
    });

    self.actionHandler(action, false).then(
      $A.getCallback( 
        function( results ) {
          $A.get("e.c:Rigging_ItemDropped_Event").fire();
          component.set('v.selectedJobId', null);
        }
      ),
      $A.getCallback( 
        function( err ) {
          LightningUtils.errorToast( err );
        }
      )
    )
    .finally( $A.getCallback( function() {
      component.set('v.loading', false );
    }))
  },

	actionHandler: function( action, deserialize ) {
    var self = this;
    return new Promise( function( resolve, reject ) {
      action.setCallback(self, function(response) {
        var state = response.getState();
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
  }
})