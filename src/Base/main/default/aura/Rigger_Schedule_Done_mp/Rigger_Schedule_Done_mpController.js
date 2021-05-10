({
	doInit : function(component, event, helper) {
		helper.getCompletedJobs(component);
	},

	allowDrop : function(component, event, helper) {
		event.preventDefault();
	},

	drag : function(component, event, helper) {
		component.set('v.draggedItemId', event.srcElement.id);
		event.dataTransfer.setData("text", event.target.id);
	},

	dragEnd : function(component, event, helper) {
	},

	drop : function(component, event, helper) {
  	event.preventDefault();

    helper.assignJob(component, 
    								 event)
  	.then(
  		$A.getCallback(
  			function() {
					return helper.getCompletedJobs(component);
				}
    	),
      $A.getCallback( 
        function( err ) {
          LightningUtils.errorToast( err );
        }
      )
		)
	},

	dropOnItem : function(component, event, helper) {
		event.preventDefault();
    var data = event.dataTransfer.getData("text");
    event.target.parentElement.parentElement.insertBefore(document.getElementById(data), event.target.parentElement);
    helper.assignJob(component, event, event.target.closest('.dropContainer').id);
	},

	handleDroppedItem : function(component, event, helper) {
		helper.getCompletedJobs(component);
	},

	filterCompleted : function(component, event, helper) {
		helper.getCompletedJobs(component);
	}
})