/**
 * Created by dave on 2020-10-01.
 */

({
  listNames: [
    'Available to Reserve',
    'Currently Reserved',
    'All Boats on Order'
  ],

  init: function( component )
  {
    let action = component.get('c.isFactoryStore');
    return new LightningApex( this, action ).fire();
  },

  fetchRecords: function( component )
  {
    let action = component.get('c.fetchOutstandingBoatOrders');

    return new Promise( (resolve, reject) => {
      new LightningApex( this, action ).fire()
      .then(
        $A.getCallback( (result) => {
          resolve( this.groupRecords( result) );
        }),
        $A.getCallback( (err) => {
          reject( err );
        })
      );
    });

  },

  groupRecords: function( records )
  {
    let grouped = {};
    records.forEach( record => {
      if( Object.keys(grouped).indexOf( record.majorItemName) < 0 )
      {
         grouped[ record.majorItemName ] = [];
      }
      grouped[ record.majorItemName ].push( record );
    });

    return Object.keys( grouped )
    .reduce( ( result, key ) => {
      result.push({
        name: key,
        records: grouped[key],
        count: grouped[key].length
      });
      return result;
    }, [] );
  },

  filterResults: function( component )
  {
    let self = this;
    const listName = component.get('v.selectedList');
    switch( this.listNames.indexOf( listName) )
    {
      case 0:
        self.filterForAvailable( component );
        break;
      case 1:
        self.filterForReserved( component );
        break;
      case 2:
        component.set('v.filteredRecords', component.get('v.allRecords') );
        break;
      default:
        return false;
    }
  },

  filterForAvailable: function( component )
  {
   const allRecords = component.get('v.allRecords'),
             checkAttrName = component.get('v.isFactoryStore') ?
               'retailErpId' : 'reservedForCustomerId';
        [];
       let filtered = allRecords.reduce( (result, boatModel) => {
         const check = boatModel.records.filter( rec => rec[checkAttrName] === null );
         if( check.length > 0 )
         {
           result.push({
             name: boatModel.name,
             records: check,
             count: check.length
           });
         }
         return result;
       }, [] );
       component.set('v.filteredRecords', filtered );
  },

  filterForReserved: function( component )
  {
    const allRecords = component.get('v.allRecords'),
          checkAttrName = component.get('v.isFactoryStore') ?
            'retailErpId' : 'reservedForCustomerId';
     [];
    let filtered = allRecords.reduce( (result, boatModel) => {
      const check = boatModel.records.filter( rec => rec[checkAttrName] !== null );
      if( check.length > 0 )
      {
        result.push({
          name: boatModel.name,
          records: check,
          count: check.length
        });
      }
      return result;
    }, [] );
    component.set('v.filteredRecords', filtered );
  },

  fetchRetailERPs: function( component )
  {
    const spinner = component.find('spinner'),
          record = component.get('v.recordForReserve');
    spinner.setMessage('Retrieving Retail Boat Sales');

    let action = component.get('c.fetchRetailERPs');
    action.setParams({
      productId: record.majorItemId
    });

    new LightningApex( this, action ).fire()
    .then(
      $A.getCallback( result => {
        console.log( JSON.parse(JSON.stringify(result)));
        component.set('v.retailERPs', result);
        component.set('v.isReserving', true);
      })
    )
    .catch(
      $A.getCallback( err => {
        LightningUtils.errorToast( err );
      })
    )
    .finally(
      $A.getCallback( () => {
        spinner.off();
      })
    )
  },

  createReservation: function( component )
  {
    console.log( 'helper.createReservation' );
    const currentStep = component.get('v.currentStep'),
          customerForm = component.find('customer-form'),
          spinner = component.find('spinner');

    if( customerForm.isValid() )
    {
      spinner.toggle('Creating Reservation');
      this.doReservation( component )
      .then(
        $A.getCallback( result => {
          console.log('selected Account');
          console.log( JSON.parse(JSON.stringify(result)));
          component.set('v.customerId', result.Id);
          return this.checkForPromotions( component );
        })
      )
      .then(
        $A.getCallback( result => {
          console.log('Available Promotions');
          console.log( JSON.parse(JSON.stringify(result)));
          if( result === null || result.length === 0 )
          {
            this.reload( component, 'Finishing up');
          }
          else
          {
            component.set('v.availablePromotions', result );
            const customerForm = component.find('customer-form');
            customerForm.cancel();
            this.incrementStep( component );
            spinner.toggle();
          }
        })
      )
      .catch(
        $A.getCallback( err => {
          LightningUtils.errorToast( err );
        })
      );
    }
  },

  incrementStep: function( component )
  {
    const currentStep = component.get('v.currentStep'),
          steps = component.get('v.reservationSteps');
    component.set( 'v.currentStep', steps[ (steps.indexOf(currentStep)) + 1] );
  },

  doReservation: function( component )
  {
    console.log('helper.doReservation');
    const record = component.get('v.recordForReserve');
    let action = component.get('c.createReservation');

    action.setParams({
      partnerErpId: record.erpOrderId,
      customerJSON: JSON.stringify( component.get('v.customer') )
    });

    return new LightningApex( this, action ).fire();
  },

  checkForPromotions: function( component )
  {
    const record = component.get('v.recordForReserve'),
          spinner = component.find('spinner'),
          isFactory = component.get('v.isFactory');
    let action = component.get('c.checkForPromotions');
    spinner.setMessage(`Checking for available Reservation Promotion for ${record.majorItemName}`);
    action.setParams({
      productId: record.majorItemId
    });

    return new LightningApex( this, action ).fire();
  },

  createPromoCase: function( component, promo )
  {
    let action = component.get('c.createPromotionCase'),
        record = component.get('v.recordForReserve'),
        jsonData = {
          customerId: component.get('v.customerId'),
          promoItemId: promo.Id,
          erpId: record.erpOrderId
        };

    action.setParams({
      jsonData: JSON.stringify( jsonData )
    });

    return new LightningApex( this, action ).fire();
  },

  cleanUpRecords: function( component )
  {
    const spinner = component.find('spinner'),
          promoCase = component.get('v.promotionCase'),
          record = component.get('v.recordForReserve'),
          steps = component.get('v.reservationSteps'),
          currentStep = component.get('v.currentStep');

    spinner.setMessage('Cancelling Reservation');
    if( steps.indexOf( currentStep ) === 0 )
    {
      return Promise.resolve();
    }

    let action = component.get('c.cancelReservation');
    action.setParams({
      erpId: record.erpOrderId,
      caseId: promoCase === null ? null : promoCase.Id
    });

    return new LightningApex( this, action ).fire();

  },

  reload: function( component, spinnerMessage )
  {
    const spinner = component.find('spinner');
    spinner.setMessage( spinnerMessage );
    this.fetchRecords( component )
    .then(
      $A.getCallback( result => {
        component.set('v.allRecords', result );
        if( component.get('v.reservationSteps').indexOf( component.get('v.currentStep')) === 0 )
        {
          try {
            const customerForm = component.find('customer-form');
            customerForm.cancel();
          }
          catch( e ){}
        }
        component.set('v.isReserving', false );
        component.set('v.recordForReserve', null );
        component.set('v.availablePromotions', null );
        component.set('v.selectedPromotion', null );
        component.set('v.customerId', null );
        component.set('v.promotionCase', null );
        component.set('v.requiredPromotionDocuments', null );
        component.set('v.uploadedFiles', null );
        component.set('v.currentStep', component.get('v.reservationSteps')[0] );
        component.find('listSelector--Cmp').doInit();
      })
    )
    .catch(
      $A.getCallback( err => {
        LightningUtils.errorToast( err );
      })
    )
    .finally(
      $A.getCallback( () => {
        spinner.off();
      })
    )
  },

  finish: function( component )
  {
    let action = component.get('c.submitCase');

    action.setParams({
      caseId: component.get('v.promotionCase').Id
    });

    new LightningApex( this, action ).fire()
    .then(
      $A.getCallback( () => {
        LightningUtils.showToast('success', 'Success', "Promotion successfully submitted");
        this.reload( component, 'Reloading records' );
      })
    )
    .catch(
      $A.getCallback( err => {
        LightningUtils.errorToast( err );
        component.find('spinner').off();
      })
    );
  }


});