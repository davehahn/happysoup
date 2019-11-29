({
	doInit : function(component, event, helper)
  {
    helper.fetchData( component )
    .then(
      $A.getCallback( function(result) {
        result = JSON.parse(result);
        component.set('v.salesData', result);
        console.log(result);
      }),
      $A.getCallback( function(err) {
        alert(err);
      })
    )
	}
})