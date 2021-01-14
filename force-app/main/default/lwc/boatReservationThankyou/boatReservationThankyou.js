/**
 * Created by dave on 2021-01-15.
 */

import { LightningElement, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { errorToast, successToast, warningToast, reduceErrors } from 'c/utils';
import { loadStyle } from 'lightning/platformResourceLoader';
import gothamFonts from '@salesforce/resourceUrl/GothamHTF';
import fetchOrderDetails from '@salesforce/apex/OnlineBoatReservation_Controller.fetchOrderDetails';
import setPickupDealership from '@salesforce/apex/OnlineBoatReservation_Controller.setPickupDealership';

export default class BoatReservationThankyou extends NavigationMixin(LightningElement) {

  isEN = true;
  isFR = false;
  locator;
  spinner;
  opportunityId;
  orderNumber;
  boat;
  motor;
  trailer;
  options;
  paymentAmount;
  customer;
  postalCode;
  pickupDealership;
  pickupDealershipSelected = false;
  dataLoaded = false;

  _stylesLoaded = false;
  _componentRendered = false;
  _initialized = false;


  @wire(CurrentPageReference)
  setCurrentPageReference(currentPageReference) {
    console.log(`Language passed in ${currentPageReference.state.language}`);
    console.log(`Opportunity Id = ${currentPageReference.state.opportunityId}`);
    this.opportunityId = currentPageReference.state.opportunityId;
    if( currentPageReference.state.language === 'french' )
    {
      this.isEN = false;
      this.isFR = true;
    }
    console.log('wire currentPageReference');
    this.init();
  }

  @wire( fetchOrderDetails, { opportunityId: '$opportunityId'} )
  wiredDetails( { error, data } )
  {
    if( data )
    {
      console.log( JSON.parse(JSON.stringify(data)) );
      this.customer = data.account;
      this.boat = data.boat;
      if( Object.keys( data ).indexOf('motor') )
      {
        this.motor = data.motor;
      }
      if( Object.keys( data ).indexOf('trailer') )
      {
        this.trailer = data.trailer;
      }
      if( Object.keys( data ).indexOf('options') )
      {
        this.options = data.options;
      }
      this.orderNumber = data.opportunity.Reference_Number__c;
      this.paymentAmount = data.opportunity.Deposit__c;
      this.dataLoaded = true;
      console.log('wire fetchOrderDetails');
      this.init();
    }
    else if( error )
    {
      console.log( error );
    }
  }

  renderedCallback()
  {
    console.log('renderedCallback called');
    if( !this._stylesLoaded )
    {
      loadStyle( this, gothamFonts + '/fonts.css')
      .then( () => {
        this._stylesLoaded = true;
      });
    }
    this.locator = this.template.querySelector('c-account-find-closest-partner');
    if( this.locator )
    {
      this._componentRendered = true;
      console.log('renderedCallback');
      this.init();
    }
  }

  init()
  {
    console.log(`init ${this.dataLoaded} ${this._componentRendered}` );
    if( this.dataLoaded && this._componentRendered )
    {
      this.spinner = this.template.querySelector('c-legend-spinner');
      this.locator.findPartners( this.customer.BillingPostalCode )
      .then( result => {
        this._initialized = true;
        this.spinner.close();
      });
    }
  }

  get ready()
  {
    return this._initialized;
  }

  get containerClass()
  {
    let klass = 'config-thanks';
    return this._initialized ? klass + ' loaded' : klass;
  }

  get shippingTiming()
  {
    let marketingContent = this.boat.marketingContent;
    for(const mc of marketingContent){
      const label = mc['label'].toLowerCase();
      const origContent = mc['content'];
      const stripContent = origContent.replace(/(<([^>]+)>)/ig,"");
      if(this.isEN){
        if(label === 'shippingtiming'){
          return stripContent;
        }
      } else if(this.isFR){
        if(label === 'shippingtimingfr'){
          return stripContent;
        }
      }

    }
    return '';
  }

  handleAccountSelected( event )
  {
    console.log('thanks account selected');
    console.log( {...event.detail} );
    this.spinner.open();
    this.pickupDealership = {...event.detail};
    setPickupDealership( {
      opportunityId: this.opportunityId,
      dealerId: this.pickupDealership.id
    })
    .then( () => {
      this.pickupDealershipSelected = true;
    })
    .catch( (err) => {
      errorToast( this, reduceErrors( err )[0] );
    })
    .finally( () => {
      this.spinner.close();
    });

  }
}