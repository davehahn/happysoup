/**
 * Created by dave on 2020-09-30.
 */

({
  doInit: function( component, event, helper )
  {
    component.set('v.availableLists', helper.listNames);
    component.set('v.selectedList', helper.listNames[0]);
  },

  afterScripts: function( component, event, helper )
  {
    const spinner = component.find('spinner');
    spinner.toggle();
    helper.init( component )
    .then(
      $A.getCallback( (isFactoryStore) => {
        console.log( `Is Factory Store = ${isFactoryStore}`);
        component.set('v.isFactoryStore', isFactoryStore );
        return helper.fetchRecords( component );
      })
    )
    .then(
      $A.getCallback( (result) => {
        component.set('v.allRecords', result );
        console.log( JSON.parse( JSON.stringify( result ) ) );
        component.find('listSelector--Cmp').doInit();
      })
    )
    .catch(
      $A.getCallback( (err) => {
        LightningUtils.errorToast( err );
      })
    )
    .finally(
      $A.getCallback( () => {
        spinner.toggle();
      })
    )
  },

  handleListChange: function( component, event, helper )
  {
    component.set('v.selectedList', event.getParam('listName') );
    console.log( event.getParam('listName') );
    helper.filterResults( component );
  },

  toggleAccordion: function( component, event, helper )
  {
    let active = event.currentTarget.dataset.value,
        accord = component.find('theAccordion').getElement();

    accord.querySelectorAll(`li[data-name="${active}"]`)[0].classList.toggle('slds-is-open');
  },

  handleReservation: function( component, event, helper )
  {
    const record = event.getSource().get('v.value');
    console.log( JSON.parse(JSON.stringify(record)));
    component.set('v.isReserving', true);
  }
});