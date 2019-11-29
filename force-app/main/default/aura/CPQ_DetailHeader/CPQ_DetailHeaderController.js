({
	handleCPQChange : function(component, event, helper)
  {
    helper.calcTotal( component );
  },

  handlePaymentChange: function( component, event, helper )
  {
    var cpq = component.get('v.cpq');
    component.set('v.monthlyPayment', event.getParam("monthlyPayment") );
    component.set('v.biWeeklyPayment', event.getParam("biWeeklyPayment") );
    component.set('v.weeklyPayment', event.getParam("weeklyPayment") );
    cpq.term = event.getParam("term");
    cpq.deposit = event.getParam("deposit");
    cpq.amort = event.getParam("amort");
    cpq.interestRate = event.getParam("interestRate");
    component.set('v.cpq', cpq);
  }
})