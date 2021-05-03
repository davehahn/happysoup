({
	 handleCaseClick: function( component, event, helper )
  {
    console.log(window.location.href);
    var recordId = event.currentTarget.dataset.recordId,
        url = 'https://legendboats--full.lightning.force.com/lightning/r/Case/'+recordId+'/view',
        evt = $A.get("e.force:navigateToURL");
    evt.setParams({
      url: url,
      isredirect: true
    })
    .fire();
  },
})