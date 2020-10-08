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
    const spinner = component.find('spinner'),
          partnerSteps =  [
            'Select Customer',
            'Submit Promotion',
            'Upload Documentation',
            'Finish'
          ],
          factorySteps = [
            'Select Retail ERP',
            'Finish'
          ];
    spinner.toggle();
    helper.init( component )
    .then(
      $A.getCallback( (isFactoryStore) => {
        console.log( `Is Factory Store = ${isFactoryStore}`);
        let steps = isFactoryStore ? factorySteps : partnerSteps;
        component.set('v.isFactoryStore', isFactoryStore );
        component.set('v.reservationSteps', steps);
        component.set('v.currentStep', steps[0] );
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
    const record = event.getSource().get('v.value'),
          isFactory = component.get('v.isFactoryStore');

    component.set( 'v.recordForReserve', record );
    if( isFactory )
    {
      LightningUtils.errorToast('Functionality not yet implemented');
      //helper.fetchRetailERPs( component );
    }
    else
    {
      component.set('v.isReserving', true);
    }
  },

  handleFactoryReservation: function( component, event, helper )
  {
    const record = event.getSource().get('v.value');
    console.log(JSON.parse(JSON.stringify(record)));
    LightningUtils.errorToast( 'Not yet Implemented' );
  },

  handleNext: function( component, event, helper )
  {
    const currentStep = component.get('v.currentStep'),
          steps = component.get('v.reservationSteps');
    switch( steps.indexOf( currentStep ) )
    {
      case 0:
        helper.createReservation( component );
        break;
      case 1:
        helper.incrementStep( component );
        break;
      default:
        return false;
    }
  },

  handleCancel: function( component, event, helper )
  {
    helper.cleanUpRecords( component )
    .then(
      $A.getCallback( () => {
        helper.reload( component, 'Reloading Reservations');
      })
    )
    .catch(
      $A.getCallback( err => {
        LightningUtils.errorToast( err );
        component.find('spinner').off();
      })
    );
  },

  handleSelectPromo: function( component, event, helper )
  {
    const promo = event.getSource().get('v.value'),
          spinner = component.find('spinner');
    let requiresDocuments = false;
    console.log('SELECTED PROMO');
    console.log( JSON.parse(JSON.stringify(promo)));
    console.log(Object.keys(promo.Promotion__r));

    if( Object.keys(promo.Promotion__r).indexOf('Document_Requirements__c') >= 0 &&
        promo.Promotion__r.Document_Requirements__c !== undefined &&
        promo.Promotion__r.Document_Requirements__c.length > 0 )
    {
      component.set(
        'v.requiredPromotionDocuments',
        promo.Promotion__r.Document_Requirements__c.split(';')
      );
      requiresDocuments = true;
    }

    spinner.toggle('Creating Promotion Case');
    helper.createPromoCase( component, promo )
    .then(
      $A.getCallback( result => {
        component.set('v.promotionCase', result );
        if( !requiresDocuments )
        {
          spinner.setMessage('No Documentation Required');
          helper.finish( component );
        }
        else
        {
          helper.incrementStep( component );
          spinner.off();
        }
      })
    )
    .catch(
      $A.getCallback( err => {
        LightningUtils.errorToast( err );
      })
    );
  },

  handleUploadFinished: function( component, event, helper )
  {
    let newFiles = event.getParam("files"),
        uploadedFiles = component.get('v.uploadedFiles');
    if( uploadedFiles === null )
      uploadedFiles = [];
    uploadedFiles = uploadedFiles.concat( newFiles );
    component.set('v.uploadedFiles', uploadedFiles );
  },

  handleFinish: function( component, event, helper )
  {
    const required = component.get('v.requiredPromotionDocuments'),
         uploaded = component.get('v.uploadedFiles');

    if( required.length != uploaded.length )
    {
      LightningUtils.errorToast( 'Not all required documents have been uploaded' );
      return false;
    }

    helper.finish( component )

  }
});