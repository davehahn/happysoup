({
	doInit : function(component, event, helper) {
		helper.getJobs(component)
		.then(
			$A.getCallback(
				function(jobs) {
					component.set('v.jobs', jobs);
				}
			),
      $A.getCallback(
        function( err ) {
          LightningUtils.errorToast( err );
          $A.util.addClass(component.find('spinner'), 'slds-hide');
        }
      )
		)
	},

	allowDrop : function(component, event, helper) {
		event.preventDefault();
	},

	drag : function(component, event, helper) {
		var riggerId = component.get('v.rigger').Id;
		if (event.target.classList.contains('placeholder')) {
			component.set('v.draggingPlaceholder', true);
			component.set('v.doneCSS','slds-card slds-p-around_small garbage');
		}
		component.set('v.draggedItemId', event.srcElement.id);
		event.dataTransfer.setData("text", event.target.id);
		event.dataTransfer.setData("riggerId", riggerId);
	},

	dragEnd : function(component, event, helper) {
		component.set('v.draggingPlaceholder', false);
		component.set('v.doneCSS','slds-card slds-p-around_small done');
		helper.getJobs(component);
	},

	drop : function(component, event, helper) {
		event.preventDefault();
    $A.util.removeClass(component.find('spinner'), 'slds-hide');
		var data = event.dataTransfer.getData("text");
		var parentId = document.getElementById(data).dataset.parentid;

		if (event.target.parentElement.classList.contains('placeholder')) {
    	helper.mergePlaceholder(component, event);
    	return;
    } else if (event.target.classList.contains('overlay')) {
			event.target
    			 .closest('.jobsContainer')
    			 .insertBefore(
    			 		document.getElementById(data),
    			 		event.target.closest('.dragItem').closest('span')
    			 );
		} else {
			event.target
					 .closest('.dropContainer')
					 .getElementsByClassName('jobsContainer')[0]
					 .appendChild(document.getElementById(data));
		}

    helper.assignJob(component,
    								 event,
    								 event.target.closest('.dropContainer').id)
    .then(
    	$A.getCallback(
    		function(){
    			return helper.saveJobOrder(component, event);
    		}
    	),
      $A.getCallback(
        function( err ) {
          LightningUtils.errorToast( err );
          $A.util.addClass(component.find('spinner'), 'slds-hide');
        }
      )
		)
  	.then(
  		$A.getCallback(
  			function() {
					if (event.target.classList.contains('overlay')) {
						event.target
							 	 .closest('.jobsContainer')
							 	 .removeChild(document.getElementById(data));
					} else {
						document.getElementById(data).remove();
					}
					return helper.getJobs(component);
				}
    	),
      $A.getCallback(
        function( err ) {
          LightningUtils.errorToast( err );
          $A.util.addClass(component.find('spinner'), 'slds-hide');
        }
      )
		)
		.then(
			$A.getCallback(
				function(jobs) {
					component.set('v.jobs', jobs);

					$A.get("e.c:Rigging_ItemDropped_Event")
					.setParams({
						"riggerId" : event.target.closest('.dropContainer').id
					})
					.fire();
				}
			),
      $A.getCallback(
        function( err ) {
          LightningUtils.errorToast( err );
          $A.util.addClass(component.find('spinner'), 'slds-hide');
        }
      )
		)
	},

	setSelectedJobId : function(component, event, helper) {
		component.set('v.selectedJobId', event.srcElement.id);
	},

	toggleJobs : function(component, event, helper) {
		var cards = component.find('job');
		if (cards.length > 0) {
			for (card of cards) {
				helper.toggleCard(card.elements[0]);
			}
		}
	},

	toggleThisJob : function(component, event, helper) {
		var card = event.srcElement.parentElement.parentElement;
		helper.toggleCard(card);
	},

	startJob : function(component, event, helper) {
		helper.setJobStart(component, event);
	},

	handleDroppedItem : function(component, event, helper) {
		var riggerId = component.get('v.rigger').Id;

    helper.getJobs(component)
    .then(
      $A.getCallback(
        function(jobs) {
          component.set('v.jobs', jobs);
        }
      ),
      $A.getCallback(
        function( err ) {
          LightningUtils.errorToast( err );
          $A.util.addClass(component.find('spinner'), 'slds-hide');
        }
      )
    );
	},

	refresh : function(component, event, helper) {
		var jobId = component.get('v.selectedJobId');
		if (jobId != null) {
			helper.getJobs(component)
			.then(
				$A.getCallback(
					function(jobs) {
						component.set('v.jobs', jobs);
					}
				),
	      $A.getCallback(
	        function( err ) {
	          LightningUtils.errorToast( err );
	          $A.util.addClass(component.find('spinner'), 'slds-hide');
	        }
	      )
			)
		}
	}
})