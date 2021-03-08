/**
 * Created by dave on 2021-03-04.
 */

({
  handleAccountBalanceChange: function( component, event )
  {
    console.log( `Account Balance Changed = ${component.get('v.accountBalance')}`);
  },

  toggleStatement: function( component, event )
  {
    console.log('click show account statement');
    let modal = component.find("account-balance-modal"),
        backdrop = component.find("backdrop");
    $A.util.toggleClass( modal, 'slds-fade-in-open');
    $A.util.toggleClass( backdrop, 'slds-backdrop_open' );
  }



});