/**
 * Created by dave on 2020-04-10.
 */

import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadStyle } from 'lightning/platformResourceLoader';
import { fireEvent, registerListener, unregisterAllListeners} from 'c/pubsub';
import sldsIconFont from '@salesforce/resourceUrl/sldsIconFont';
import gothamFonts from '@salesforce/resourceUrl/GothamHTF';
import LOGO from '@salesforce/resourceUrl/LegendLogo';
import VLOGO from '@salesforce/resourceUrl/LegendLogoVertical';
import fetchBoat from '@salesforce/apex/OnlineBoatReservation_Controller.fetchBoat';
import fetchSettings from '@salesforce/apex/OnlineBoatReservation_Controller.fetchSettings';
import createAccount from '@salesforce/apex/OnlineBoatReservation_Controller.createAccount';
import saveLineItems from '@salesforce/apex/OnlineBoatReservation_Controller.saveLineItems';

export default class CustCommOrderBuilder extends NavigationMixin(LightningElement) {

  origin;
  recordId;
  accountId;
  opportunityId;
  logo = LOGO;
  vertLogo = VLOGO;
  orderValid=true;
  isMobile = false;
  customer={};



  pages = [
    'performance',
    'trailering',
    'electronics',
    'payment'
  ];

 	 modalPages = [
 	   {
      title: 'Finance Options',
      label: 'payment-calculator',
      class: 'modal-nav-item  modal-nav-item_selected'
    },
		{
			title: 'Preferred Equipment Package',
			label: 'premium-package',
			class: 'modal-nav-item'
		},
		{
			title: 'Delivery Timing + Freight',
			label: 'delivery',
			class: 'modal-nav-item'
		},
	];

	freight = {
		fishingBoat: {
		  "Alberta": 1450,
      "British Columbia": 1675,
      "Manitoba": 825,
      "New Brunswick": 825,
      "Newfoundland and Labrador": 2450,
      "Northwest Territories": 0,
      "Nova Scotia": 825,
      "Nunavut": 0,
      "Ontario": 0,
      "Prince Edward Island": 825,
      "Quebec": 0,
      "Saskatchewan": 975,
      "Yukon": 0,
  	},
 	};
 	@track freightCharge;

	premiumPackage;

  @track paymentAmount;
  @track term;
  @track interestRate;
	@track motorDetails;
	@track currentPage = 'performance';
  @track currentModalPage = 'premium-package';
  @track paymentType='loan';
  @track iframeHeight;
  @track boat;
  @track purchasePrice;
  @track performanceItems = [];
  @track traileringItems = [];
  @track electronicsItems = [];
  @track freightItems = [];

  @wire(CurrentPageReference)
  setCurrentPageReference(currentPageReference) {
    this.recordId = currentPageReference.state.c__recordId;
  }

  @wire(CurrentPageReference) pageRef;

  @wire( fetchBoat, { boatId: '$recordId'} )
  wiredFetchBoat( { error, data } )
  {
    if( data )
    {
      console.log('FETCH BOAT DATA');
      console.log(data);
      this.boat = data;
    }
    else if( error )
    {
      console.log( error );
    }
  }

  @wire( fetchSettings, {} )
  wiredSettings( {error, data } )
  {
    if( data )
    {
      this.paymentAmount = data.deposit;
      this.term = data.term;
      this.interestRate = data.interestRate / 100;
    }
    if( error )
    {
      console.log( error );
    }
  }

  get boatDetailsLoaded()
  {
    return this.boat != null;
  }

  get processPages()
  {
    window.addEventListener('resize', (event) => {
      this.isMobile = (event.currentTarget.outerWidth < 1024) ? true : false;
    });

    this.isMobile = (window.outerWidth < 1024) ? true : false;
  }

  connectedCallback(){
    registerListener('updateListItems', this.updateListItems, this);
    registerListener('purchasePriceChanged', this.handlePurchasePriceChange, this);
    registerListener('paymentTypeChanged', this.handlePaymentTypeChange, this);
  }

  renderedCallback()
  {
    loadStyle( this, sldsIconFont + '/style.css')
    .then(()=>{});
    loadStyle( this, gothamFonts + '/fonts.css')
    .then(()=>{});

    window.addEventListener('resize', (event) => {
			this.isMobile = (event.currentTarget.outerWidth < 1024) ? true : false;
		});
		this.isMobile = (window.outerWidth < 1024) ? true : false;

		this.unsetClickFocus();

  }

  get processPages()
  {
    return this.pages.map( page => {
      return {
        label: page,
        class: this.currentPage === page ?
          'config-nav-item config-nav-item_selected' :
          'config-nav-item'
      }
    });
  }

  get buttonText()
  {
    return this.onPaymentPage() ? 'Place Order' : 'Next';
  }

  get buttonDisabled()
  {
    return this.onPaymentPage() ? !this.orderValid : false;
  }

  handleHomeNav()
  {
    this[NavigationMixin.Navigate]({
      type: 'comm__namedPage',
      attributes: {
          pageName: 'home'
      }
    });
  }

  handleNav( event )
  {
    this.doPageChange( event.currentTarget.dataset.navName );
  }

  handlePurchasePriceChange( amount )
  {
    console.log(`Purchase Price Changed EVENT in OrderBuilder Captured ${amount}`);
    this.purchasePrice = amount;
    this.template.querySelector('c-boat-res-finance-details').calculate();
  }

  handleCustomerData( event )
  {
    const attr = event.currentTarget.dataset.attr,
          value = event.currentTarget.value;
    this.customer[attr] = value;
    if( attr === 'state' )
      this.handleFreight( value );
  }

  handlePaymentTypeChange( paymentType )
  {
    this.paymentType = paymentType;
  }

  openFinanceSelect( event )
  {
    this.template.querySelector('.financetype-selector_container').classList.add('open');
  }

  handlePaymentTypeSelect( event )
  {
    this.paymentType = event.currentTarget.dataset.value;
    this.template.querySelector('.financetype-selector_container').classList.remove('open');
  }

  handleCloseModal()
  {
    this.toggleModal( false );
    this.template.querySelector('.modal-container').removeEventListener('click');
  }

  handleOpenModal()
  {
    this.toggleModal( true );
    this.template.querySelector('.modal-container').addEventListener('click', (e) => {
      if(e.target.classList.contains('modal-container')){
      	this.toggleModal(false);
      }
    });
  }

	handleModalNav( event )
	{
		this.doModalPageChange( event.currentTarget );
	}

	doModalPageChange( page )
	{
	  let pageName = page.dataset.modalNavName;
		this.currentModalPage = pageName;

		this.template.querySelector('.modal-nav-item_selected').classList.remove('modal-nav-item_selected');
		this.template.querySelector( `[data-modal-nav-name="${this.currentModalPage}"]` ).classList.add('modal-nav-item_selected');

		this.template.querySelector('.modal-page_selected').classList.remove('modal-page_selected');
		this.template.querySelector( `[data-modal-page="${this.currentModalPage}"]` ).classList.add('modal-page_selected');
	}

  handleEditConfig()
  {
    this.doPageChange('performance');
  }

  handleNext()
  {
    this.onPaymentPage() ?
    this.submitOrder() :
    this.doPageChange( this.pages[ this.pages.indexOf( this.currentPage ) +1 ] );
  }

  jumpToPayment(){
      this.doPageChange( 'payment' );
  }

  doPageChange( page )
  {
    this.currentPage = page;
    this.template.querySelector('.config-page_selected').classList.remove('config-page_selected');
    this.template.querySelector(`[data-page="${this.currentPage}"]` ).classList.add('config-page_selected');

    if( this.currentPage === 'payment')
    {
      this.template.querySelector('[data-id="square-payment-container"]').src = '/apex/Square_PaymentForm_CustomerCommunity';
    }
  }

  toggleModal( shouldOpen )
  {
    if( shouldOpen )
    {
      this.template.querySelector('.modal-container').classList.add('open');
    }
    else
    {
      this.template.querySelector('.modal-container').classList.remove('open');
    }
  }

  get premiumPackValue(){
    if(this.boat.premiumPackage.value){
			const value = parseInt(this.boat.premiumPackage.value);
			return new Intl.NumberFormat('en-CA', {
    							  							style: 'currency',
    							  							currency: 'CAD',
    							  							minimumFractionDigits: 0
    							  							}).format(value);
		}
  }

	get premiumPackItems(){
	  if(this.boat.premiumPackage.contents){
			const contents = this.boat.premiumPackage.contents;
			const sections = Object.entries(contents);
			let packItems = [];
			for(const [section, parts] of sections){
				const items = Object.values(parts);
				for(const item of items){
				  let description = item.description;
				  let value = item.value;
				  let valueFormatted = new Intl.NumberFormat('en-CA', {
																style: 'currency',
																currency: 'CAD',
																minimumFractionDigits: 0
																}).format(value);
				  let details = {
				    description: description,
				    value: value,
				    valueFormatted: valueFormatted,
      		};
					packItems.push(details);
				}
			}

			packItems.sort(function(a,b){
				return b.value - a.value;
   		});
   		console.log(packItems);
			return packItems;
		}
	}



	updateListItems(details){
	  let payload = {
			 'Product2Id': details.sku,
			 'ParentProductId__c': details.ppSku,
			 'UnitPrice': details.price,
			 'Quantity': 1
		};
		if(details.addToSummary){
			//add item to list
			if(details.type === 'radio'){
				//replace the existing item for this section
				if(details.addon){
				} else {
					if(details.section === 'performance'){
						this.performanceItems.pop();
						this.performanceItems.push(payload);
					} else if(details.section === 'trailering'){
						this.traileringItems.pop();
						this.traileringItems.push(payload);
					} else if(details.section === 'electronics'){
						this.electronicsItems.pop();
						this.electronicsItems.push(payload);
					}
				}
			} else if(details.type === 'select'){
			  this.freightItems = [];
			  this.freightItems.push(payload);
   		} else {
				//append the item to this section
				if(details.section === 'performance'){
					this.performanceItems.push(payload);
				} else if(details.section === 'trailering'){
					this.traileringItems.push(payload);
				} else if(details.section === 'electronics'){
					this.electronicsItems.push(payload);
				}
			}
		} else {
			//remove item from list
			if(details.section === 'performance'){
				this.performanceItems = this.performanceItems.filter(obj => obj.PricebookEntryId !== payload.PricebookEntryId);
			} else if(details.section === 'trailering'){
				this.traileringItems = this.traileringItems.filter(obj => obj.PricebookEntryId !== payload.PricebookEntryId);
			} else if(details.section === 'electronics'){
				this.electronicsItems = this.electronicsItems.filter(obj => obj.PricebookEntryId !== payload.PricebookEntryId);
			}
		}
 	}

  submitOrder()
  {
    console.log('submit a');
    const spinner = this.template.querySelector('c-legend-spinner');
    spinner.toggle();
    console.log('submit b');
	  this.saveCustomer()
		.then( ( accountSaveResult ) => {
		  console.log('submit c');
		  this.opportunityId = accountSaveResult.opportunityId;
      this.accountId = accountSaveResult.record.Id;
      console.log('submit d');
		  return this.createSquarePayment();
  	})
  	.then( ( paymentResult ) => {
  	  console.log('submit e');
  	   return this.saveSaleItems();
    })
  	.then( ( saveSaleItemsResult ) => {
  	  console.log('submit f');
      console.log('lineItemsResult: ', saveSaleItemsResult);
    })
  	.catch( ( error ) => {
  	  console.log('submit g');
			console.log('error: ', JSON.stringify(error));
   	})
   	.finally( () => {
   	  console.log('submit h');
      spinner.toggle();
      console.log('Everything is done, but what should happen now');
    });
  }

  saveCustomer()
  {
    const userJSON = JSON.stringify( this.customer );
		console.log('save f');
    return createAccount({customerJSON: userJSON});
  }

  createSquarePayment()
  {
    console.log('square a');
    return this.template.querySelector('c-square-payment-form')
      .doPostToSquare( this.paymentAmount, this.opportunityId );
  }

  saveSaleItems()
  {
    console.log('sale a');
    const oppInfo = JSON.stringify({
      'Id': this.opportunityId,
      'AccountId': this.accountId,
      'Deposit__c': this.paymentAmount,
      'Finance_Term__c': this.term,
      'Finance_Ammortization__c': this.term,
      'Insurance_Term__c': this.term,
      'Finance_Annual_Interest__c': this.interestRate
    });
    console.log('sale b');
    const boatLineItem = [{
      'Product2Id': this.boat.id,
      'UnitPrice': this.boat.retailPrice,
      'Quantity': 1,
    }];
    console.log('sale c');
    let lineItems = this.performanceItems.concat(this.traileringItems, this.electronicsItems, boatLineItem);
    lineItems = JSON.stringify(lineItems);
    console.log('sale d');
    console.log('oppInfo: ', oppInfo);
    console.log('lineItems: ', lineItems);
    return saveLineItems({oppJSON: oppInfo, olisJSON: lineItems});
  }

  onPaymentPage()
  {
    return this.pages.indexOf( this.currentPage ) + 1 === this.pages.length
  }

	get traileringOptions(){
	  const options = [this.boat.standardTrailer, this.boat.trailerUpgrades[0]];
		return options;
 	}

	unsetClickFocus(){
	  let mouseDown = false;
		const unsetFocus = this.template.querySelectorAll('[data-click-focus="unset"]');
		unsetFocus.forEach((element) => {
			element.addEventListener('mousedown', () => {
				mouseDown = true;
			});
			element.addEventListener('mouseup', () => {
				mouseDown = false;
			});
			element.addEventListener('focus', (event) => {
				if (mouseDown) {
					event.target.blur();
				}
			});
		});
 	}


 	get shippingTiming(){
		let marketingContent = this.boat.marketingContent;
		for(const mc of marketingContent){
			const label = mc['label'].toLowerCase();
			const origContent = mc['content'];
			const stripContent = origContent.replace(/(<([^>]+)>)/ig,"");
			if(label === 'shippingtiming'){
				return stripContent;
			}
		}
  }

	handleFreight( province ){
		console.log('update freight info!');
		let charge = this.freight.fishingBoat[province];

		let purchasePrice = {
			'sku': 'freight',
			'price': charge,
			'addToPrice': true,
			'section': 'freight',
			'type': 'select',
			'addon': false,
			'userSelectionName': 'freight'
		};

		let summaryDetails = {
			'sku': 'freight',
			'name': 'Freight to ' + province,
			'price': charge,
			'addToSummary': true,
			'section': 'freight',
			'type': 'select',
			'addon': false,
			'userSelectionName': 'freight'
		};

		fireEvent(this.pageRef, 'updateSummary', summaryDetails);
		fireEvent(this.pageRef, 'updateListItems', summaryDetails);
		fireEvent(this.pageRef, 'updatePurchasePrice', purchasePrice);

		this.displayFreightCharge(charge);
 	}

 	displayFreightCharge(charge){
 	  let updatedFreight = new Intl.NumberFormat('en-CA', {
													style: 'currency',
													currency: 'CAD',
													minimumFractionDigits: 0
													}).format(charge);
 	  this.freightCharge = '+ ' + updatedFreight + ' Freight Charge';
  }

}