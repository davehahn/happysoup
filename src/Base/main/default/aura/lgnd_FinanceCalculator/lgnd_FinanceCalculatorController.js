({
	doInit : function(component, event, helper)
  {
   helper.initComponent( component );
	},

  refresh: function( component, event, helper )
  {
    helper.initComponent( component );
  },

  reInit: function( component, event, helper )
  {
    var initd = component.get('v.originalInitComplete');
    if( initd )
      helper.initComponent( component );
  },

  reset: function( component, event, helper )
  {
    $A.get('e.force:refreshView').fire();
  },

  termChange: function( component, event, helper )
  {
    var deposit = component.get('v.deposit'),
        finTerm = component.get('v.finTerm'),
        finAmort = component.get('v.finAmort'),
        insTerm = component.get('v.insTerm'),
        intrestRate = component.get('v.intrestRate'),
        changeEvt = $A.get("e.c:lgnd_FinanceCalculator_ChangedEvent_dh");

    if( parseInt( finTerm ) > parseInt( finAmort ) )
    {
      finAmort = finTerm;
      component.set('v.finAmort', finAmort);
    }

    changeEvt.setParams({
      finTerm: finTerm,
      finAmort: finAmort,
      insTerm: insTerm,
      intrestRate: intrestRate,
      deposit: deposit
    })
    .fire();
  },

  amortChange: function( component, event, helper )
  {
    var deposit = component.get('v.deposit'),
        finTerm = component.get('v.finTerm'),
        finAmort = component.get('v.finAmort'),
        insTerm = component.get('v.insTerm'),
        intrestRate = component.get('v.intrestRate'),
        changeEvt = $A.get("e.c:lgnd_FinanceCalculator_ChangedEvent_dh");
    if( parseInt( finAmort ) < parseInt( finTerm ) )
    {
      finTerm = finAmort;
      component.set('v.finTerm', finTerm);
    }

    changeEvt.setParams({
      finTerm: finTerm,
      finAmort: finAmort,
      insTerm: insTerm,
      intrestRate: intrestRate,
      deposit: deposit
    })
    .fire();
  },

  rate_deposit_change: function( component, event, helper )
  {
    var deposit = component.get('v.deposit'),
        finTerm = component.get('v.finTerm'),
        finAmort = component.get('v.finAmort'),
        insTerm = component.get('v.insTerm'),
        intrestRate = parseFloat( component.get('v.intrestRate') ),
        changeEvt = $A.get("e.c:lgnd_FinanceCalculator_ChangedEvent_dh");
    if( isNaN(intrestRate) ||
        intrestRate < 0 ||
        intrestRate === undefined ||
        intrestRate === null ||
        intrestRate.length === 0 )
      LightningUtils.errorToast('Interest Rate must be greater than or equal to zero');
    else if( deposit < 0 )
      LightningUtils.errorToast('Deposit can not be less then zero');
    else
    {
      changeEvt.setParams({
        finTerm: finTerm,
        finAmort: finAmort,
        insTerm: insTerm,
        intrestRate: intrestRate,
        deposit: deposit
      })
      .fire();
    }
  },

  insuranceItemsChanged: function( component, event, helper )
  {
    var insuranceLines = event.getParam("insuranceItems");
    component.set('v.insuranceLines', insuranceLines);
    helper.calculatePayments( component, true );
  },

  remoteUpdate: function( component, event, helper )
  {
    var hasChanged = component.get('v.hasChanged');
    return new Promise( function( resolve, reject ) {
      if( hasChanged )
      {
        helper.doRecordSave( component )
        .then(
          $A.getCallback( function() {
            resolve('FinCalc has update successfully');
          }),
          $A.getCallback( function( err ) {
            reject( err );
          })
        );
      }
      else
      {
        resolve('fincalc - nothing to update');
      }
    });
  },

  handleSave: function( component, event, helper )
  {
    var indicator = component.find('busy-indicator');
    if( component.get('v.hasChanged') === true )
    {
      component.set('v.hasChanged', false);

      $A.util.toggleClass( indicator, 'toggle' );
      helper.doRecordSave( component )
      .then (
        $A.getCallback( function() {
          $A.get('e.force:refreshView').fire();
        }),
        $A.getCallback( function(err) {
          LightningUtils.errorToast( err );
        })
      );
    }
  }

})