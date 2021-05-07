({
  setUserData: function( component )
  {
    var action = component.get('c.builderInit');
    return new LightningApex( this, action ).fire();
  },

	handleStageChange: function( params, component)
  {
    var actionNumber = params.navigateTo,
        prevActionNumber = params.firedBy,
        navMap = component.get('v.navMap'),
        isFactoryStore = component.get('v.dealerOrder').Account__r.Is_Internal__c,
        c_name, c_cmp;
        //c_name, i_name, c_cmp, i_cmp, prev_i_name, prev_i_cmp, navMap = component.get('v.navMap');

    console.log(`actionNumber ${actionNumber}`);
    console.log(`prevActionNumber ${prevActionNumber}`);

    // If it is a factory store skip the summary and
    // apply Partner Program step
//    if( actionNumber === 2 && isFactoryStore )
//      actionNumber = 3;

    component.set('v.currentAction', actionNumber );
    component.set('v.currentStep', actionNumber.toString() );
//    i_name = navMap[actionNumber] + '-indicator';
//    i_cmp = component.find( i_name );
//
    for( var i=0; i<navMap.length; i++ )
    {
      c_name = navMap[i];
      c_cmp = component.find( c_name );
//      prev_i_name = navMap[ i ] + '-indicator';
//      prev_i_cmp = component.find( prev_i_name );
//
      if( actionNumber === i )
      {
        $A.util.removeClass( c_cmp, 'toggle' );
//        $A.util.addClass( i_cmp,'slds-is-current');
//        $A.util.removeClass( i_cmp,'slds-is-incomplete');
      }
      else if( actionNumber > i )
      {
        $A.util.addClass( c_cmp, 'toggle' );
//        $A.util.removeClass( i_cmp,'slds-is-incomplete');
//        $A.util.addClass( prev_i_cmp,'slds-is-complete');
//        $A.util.removeClass( prev_i_cmp,'slds-is-current');
//        $A.util.removeClass( prev_i_cmp,'slds-is-incomplete');
      }
      else if( actionNumber < i )
      {
        $A.util.addClass( c_cmp, 'toggle' );
//        $A.util.removeClass( i_cmp,'slds-is-complete');
//        $A.util.addClass( prev_i_cmp,'slds-is-incomplete');
//        $A.util.removeClass( prev_i_cmp,'slds-is-current');
//        $A.util.removeClass( prev_i_cmp,'slds-is-complete');
      }
//
    }

    //$A.util.addClass( i_cmp,'slds-is-current');

    // moving to the next step
//    if( actionNumber > prevActionNumber )
//    {
//      for( let i = prevActionNumber; i<actionNumber; i++ )
//      {
//        prev_i_name = navMap[ i ] + '-indicator';
//        prev_i_cmp = component.find( prev_i_name );
//        $A.util.removeClass( i_cmp,'slds-is-incomplete');
//        $A.util.addClass( prev_i_cmp,'slds-is-complete');
//        $A.util.removeClass( prev_i_cmp,'slds-is-current');
//        $A.util.removeClass( prev_i_cmp,'slds-is-incomplete');
//      }
//    }
//
//    //moving back to previous step
//    if( actionNumber < prevActionNumber )
//    {
//      for( let i = prevActionNumber; i<actionNumber; i-- )
//      {
//        prev_i_name = navMap[ i ] + '-indicator';
//        prev_i_cmp = component.find( prev_i_name );
//        $A.util.removeClass( i_cmp,'slds-is-complete');
//        $A.util.addClass( prev_i_cmp,'slds-is-incomplete');
//        $A.util.removeClass( prev_i_cmp,'slds-is-current');
//        $A.util.removeClass( prev_i_cmp,'slds-is-complete');
//      }
//    }

    //initialize Builder coming from Dealer Order Form
    if( actionNumber === 1 && prevActionNumber === 0 )
      component.find("orderBuildBoat--Cmp").doInit();

    //if we are going from the builder to review
    if( actionNumber === 2 && prevActionNumber === 1 )
    {
      component.find("finalizeOrder-Cmp").doInit();
    }
    //if we are going from review to finalize
//    if( actionNumber === 3 && ( prevActionNumber === 2 || prevActionNumber === 1 ) )
//    {
//      component.find('finalizeOrder-Cmp').doInit();
//    }
    //if we are coming from review to build a boat we need to reset all the variables
    if( actionNumber === 1 && prevActionNumber === 2 )
    {
      if( params.groupId !== undefined && params.groupId.length > 0 )
        component.find("orderBuildBoat--Cmp").doInitForEdit( params.groupId );
      else
        component.find("orderBuildBoat--Cmp").doInit();
    }
  },

  cancelOrder: function( component )
  {
    var dealerOrder = component.get('v.dealerOrder'),
        action,
        la;

    if( dealerOrder.Id === undefined ||
        dealerOrder.Id === null )
    {
      return Promise.resolve();
    }

    action = component.get('c.deleteDealerOrder');
    action.setParams({
      dealerOrderId: dealerOrder.Id
    });
    la = new LightningApex( this, action );
    return la.fire();
  },

  navigateHome: function()
  {
    var homeEvent = $A.get("e.force:navigateToObjectHome");
    homeEvent.setParams({
        "scope": "Dealer_Order__c"
    });
    homeEvent.fire();
  },

  toggleIndicator: function( component, message )
  {
    let indicator = component.find('busy-indicator');
    indicator.toggle( message );
  },

  changeIndicatorMessage: function( component, msg )
  {
    let indicator = component.find('busy-indicator');
    indicator.setMessage( msg );
  }
})