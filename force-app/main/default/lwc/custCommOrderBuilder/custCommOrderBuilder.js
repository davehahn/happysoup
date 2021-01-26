/**
 * Created by dave on 2020-04-10.
 */

import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { errorToast, successToast, warningToast, reduceErrors } from 'c/utils';
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
  orderNumber;
  paymentResult;
  logo = LOGO;
  vertLogo = VLOGO;
  orderValid=true;
  isMobile = false;
  customer={};
  @track customerFirstName;
  @track customerLastName;
  creditCardError = false;
  isEN = true;
  isFR = false;

  pages = [
    {
    	label: 'performance',
    	label_fr: 'performance'
    },
    {
			label: 'trailering',
			label_fr: 'remorque'
		},
		{
			label: 'electronics',
			label_fr: 'électroniques'
		},
		{
			label: 'payment',
			label_fr: 'paiement'
		}
  ];

 	 modalPages = [
 	   {
      title: 'Finance Options',
      title_fr: 'Options de financement',
      label: 'payment-calculator',
      class: 'modal-nav-item  modal-nav-item_selected'
    },
		{
			title: 'Preferred Equipment Package',
			title_fr: 'Ensemble Équipement Préférentiel',
			label: 'premium-package',
			class: 'modal-nav-item'
		},
		{
			title: 'Delivery Timing + Freight',
			title_fr: 'Calendrier de livraison + transport',
			label: 'delivery',
			class: 'modal-nav-item'
		},
	];

 	@track freightCharge;

	premiumPackage;

  @track paymentAmount;
  @track term;
  @track interestRate;
	@track motorDetails;
	@track currentPage = 'performance';
  @track currentModalPage = 'premium-package';
  @track paymentType='loan';
  @track paymentTypeLabel='loan';
  @track iframeHeight;
  @track boat;
  @track purchasePrice;
  @track performanceItems = [];
  @track traileringItems = [];
  @track electronicsItems = [];
  @track freightItems = [];
  @track validatedFormFields = 0;
  @track paymentFormErrors;
  @track hasPaymentErrors = false;

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
//      console.log('FETCH BOAT DATA');
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
        label: page.label,
        label_fr: page.label_fr,
        class: this.currentPage === page.label ?
          'config-nav-item config-nav-item_selected' :
          'config-nav-item'
      }
    });
  }

  get buttonText()
  {
    return this.onPaymentPage() ? ((this.isEN) ? 'Place Order' : 'Placer la commande') : ((this.isEN) ? 'Next' : 'Suivant');
  }

  get buttonDisabled()
  {
    return this.onPaymentPage() ? !this.orderValid : false;
  }

  get currentLanguage()
  {
    if( this.isEn && !this.isFR ) return 'english';
    if( !this.isEn && this.isFR ) return 'french';
    return 'english';
  }

  navigateToCommunityPage( attrs, state )
  {
    this[NavigationMixin.Navigate]({
      type: 'comm__namedPage',
      attributes: attrs,
      state: state === undefined ? {} : state
    });
  }

  handleHomeNav()
  {
    this.navigateToCommunityPage(
      { pageName: 'home' }
    );
  }

  handleNav( event )
  {
    this.doPageChange( event.currentTarget.dataset.navName );
  }

  handleLanguage( event ){
  	let changeToLang = event.currentTarget.dataset.lang;
  	if(changeToLang === 'EN'){
  		this.isEN = true;
  		this.isFR = false;
  		this.currentLang = 'EN';
  		this.paymentTypeLabel = this.template.querySelector('.financetype-selector_option.selected').dataset.label;
  		fireEvent(this.pageRef, 'languageChange', 'EN');
  	} else {
  		this.isEN = false;
  		this.isFR = true;
  		this.currentLang = 'FR';
  		this.paymentTypeLabel = this.template.querySelector('.financetype-selector_option.selected').dataset.labelFr;
  		fireEvent(this.pageRef, 'languageChange', 'FR');
  	}

  	this.shippingTiming();
  	this.premiumPackValue();
  	this.buttonText();

  }

  handlePurchasePriceChange( amount )
  {
//    console.log(`Purchase Price Changed EVENT in OrderBuilder Captured ${amount}`);
    this.purchasePrice = amount;
    this.template.querySelector('c-boat-res-finance-details').calculate();
  }

  handleCustomerData( event )
  {
    const attr = event.currentTarget.dataset.attr,
          value = event.currentTarget.value;
    this.customer[attr] = value;

		var code = event.keyCode || event.which;
		if(code !== 9){
			this.validateField( event.currentTarget );
		}

    if( attr === 'state' )
      this.handleFreight( value );

    if( attr === 'firstName')
      this.customerFirstName = value;

    if( attr === 'lastName')
			this.customerLastName = value;

  }

  handlePaymentTypeChange( paymentType )
  {
    this.paymentType = paymentType;
  }

  openFinanceSelect( event )
  {
    this.template.querySelector('.financetype-selector_container').classList.add('open');
  }

  handlePaymentTypeSelect( event = null )
  {
  	this.paymentType = event.currentTarget.dataset.value;
  	this.paymentTypeLabel = (this.isEN) ? event.currentTarget.dataset.label : event.currentTarget.dataset.labelFr;
    this.template.querySelector('.financetype-selector_container').classList.remove('open');
    let types = this.template.querySelectorAll('.financetype-selector_option');
    types.forEach((type) => {
    	type.classList.remove('selected');
    });
    event.currentTarget.classList.add('selected');
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
    this.doPageChange( this.pages[ this.pages.findIndex( x => x.label === this.currentPage) + 1 ] );
  }

  jumpToPayment(){
  		this.onPaymentPage() ?
      this.submitOrder() :
      this.doPageChange( 'payment' );
  }

  doPageChange( page )
  {
    this.currentPage = (page.label) ? page.label : page;
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
			if(this.isEN){
				return new Intl.NumberFormat('en-CA', {
												style: 'currency',
												currency: 'CAD',
												minimumFractionDigits: 0
												}).format(value);
			} else if(this.isFR){
				return new Intl.NumberFormat('fr-CA', {
												style: 'currency',
												currency: 'CAD',
												minimumFractionDigits: 0
												}).format(value);
			}

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
				  let description_fr = item.description_fr;
				  let value = item.value;
				  let valueFormatted = new Intl.NumberFormat('en-CA', {
																style: 'currency',
																currency: 'CAD',
																minimumFractionDigits: 0
																}).format(value);
					let valueFormatted_fr = new Intl.NumberFormat('fr-CA', {
          																style: 'currency',
          																currency: 'CAD',
          																minimumFractionDigits: 0
          																}).format(value);
				  let details = {
				    description: description,
				    description_fr: description_fr,
				    value: value,
				    valueFormatted: valueFormatted,
				    valueFormatted_fr: valueFormatted_fr,
      		};
					packItems.push(details);
				}
			}

			packItems.sort(function(a,b){
				return b.value - a.value;
   		});
//   		console.log(packItems);
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
		console.log('updateListItems');
		console.log( JSON.parse( JSON.stringify( details ) ) );
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
  	let formFields = this.template.querySelectorAll('.form-input:not(.form-input--valueOnly)');
  	let numFormFields = formFields.length;
  	console.log('numFormFields', numFormFields);
  	console.log('numValidFields', this.validatedFormFields);
  	if(numFormFields > this.validatedFormFields){
  		//return false;
  	}
    const spinner = this.template.querySelector('c-legend-spinner');
    spinner.toggle();

	  this.saveCustomer()
		.then( ( accountSaveResult ) => {
		  this.opportunityId = accountSaveResult.opportunityId;
		  this.orderNumber = accountSaveResult.referenceNumber;
      this.accountId = accountSaveResult.record.Id;
		  return this.createSquarePayment();
  	})
  	.then( ( paymentResult ) => {
  	  console.log('PAYMENT RESULT');
  	  //console.log( JSON.parse(JSON.stringify( paymentResult ) ) );
  	  this.paymentResult = paymentResult;
  	  return this.saveSaleItems();
    })
  	.then( ( saveSaleItemsResult ) => {
      console.log('lineItemsResult: ', saveSaleItemsResult);
      this.creditCardError = false;
      this.displayThanks();
    })
  	.catch( ( error ) => {
      errorToast( this, reduceErrors( error )[0] );
   	})
   	.finally( () => {
      spinner.toggle();
    });
  }

  saveCustomer()
  {
    const userJSON = JSON.stringify( this.customer );
    return createAccount({customerJSON: userJSON});

    /* for thank you testing */
//    return Promise.resolve({
//      opportunityId: '005xxxxx',
//      referenceNumber: 'ref#0001',
//      record: { Id: '009xxxx'}
//    });
  }

  createSquarePayment()
  {
    return this.template.querySelector('c-square-payment-form')
      .doPostToSquare( this.paymentAmount, this.opportunityId );
    /* for thank you testing */
//    return Promise.resolve();
  }

  saveSaleItems()
  {
    /* for thank you testing */
//    return Promise.resolve();
    const acctInfo = JSON.stringify({
      Id: this.accountId,
      BillingPostalCode: this.paymentResult.postal_code
    });
    const oppInfo = JSON.stringify({
      'Id': this.opportunityId,
      'AccountId': this.accountId,
      'Deposit__c': this.paymentAmount,
      'Finance_Term__c': this.term,
      'Finance_Ammortization__c': this.term,
      'Insurance_Term__c': this.term,
      'Finance_Annual_Interest__c': this.interestRate
    });
    const boatLineItem = [{
      'Product2Id': this.boat.id,
      'UnitPrice': this.boat.retailPrice,
      'Quantity': 1,
    }];
    let lineItems = this.performanceItems.concat(this.traileringItems, this.electronicsItems, boatLineItem);
    lineItems = JSON.stringify(lineItems);
    return saveLineItems({acctJSON: acctInfo, oppJSON: oppInfo, olisJSON: lineItems});
  }

  onPaymentPage()
  {
    return this.pages.findIndex( x => x.label === this.currentPage ) + 1 === this.pages.length
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
  }

	handleFreight( province ){
		let charge = this.boat.additionalFees[province][0]['retailPrice'];
		this.displayFreightCharge(charge);
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
 	}

 	displayFreightCharge(charge){
 		console.log('freight Charge: ', charge);
 		let updatedFreight = null;
 		if(this.isEN){
 			updatedFreight = new Intl.NumberFormat('en-CA', {
								style: 'currency',
								currency: 'CAD',
								minimumFractionDigits: 0
								}).format(charge);
 		} else if(this.isFR){
			updatedFreight = new Intl.NumberFormat('fr-CA', {
							style: 'currency',
							currency: 'CAD',
							minimumFractionDigits: 0
							}).format(charge);
		}
		console.log('updated freight: ', updatedFreight);
 	  this.freightCharge = (this.isEN) ? '+ ' + updatedFreight + ' Freight Charge' : '+ ' + updatedFreight + ' Frais de transport';
  }

	triggerValidation( event ){
		this.validateField(event.currentTarget);
 	}

  validateField( field ){

    const attr = field.dataset.attr,
					value = field.value,
					feedback = field.parentElement.querySelector('.feedback');

		if( attr === 'firstName' || attr === 'lastName'){
			if(value.length === 0){
				if(field.hasAttribute('required')){
					let errmsg = (this.isEN) ? 'This field cannot be empty' : 'Ce champ ne peut pas être vide';
					feedback.classList.remove('clean');
					feedback.classList.add('error');
					feedback.innerHTML = errmsg;
					field.classList.remove('clean');
					field.classList.add('error');
					if(field.classList.contains('valid')){
						field.classList.remove('valid');
						this.validatedFormFields = this.validatedFormFields - 1;
					}
   	 		}
   		} else {
   		  const pattern = /^[a-zA-ZàâçéèêëîïôûùüÿæœÙÛÜŸÀÂÆÇÉÈÊËÏÎÔŒ  .'-]+$/i;
				if(!(pattern.test(value))){
					let errmsg = (this.isEN) ? 'This field contains invalid characters' : 'Ce champ contient des textes invalides';
					feedback.classList.remove('clean');
					feedback.classList.add('error');
					feedback.innerHTML = errmsg;
					field.classList.remove('clean');
					field.classList.add('error');
					if(field.classList.contains('valid')){
						field.classList.remove('valid');
						this.validatedFormFields = this.validatedFormFields - 1;
					}
				}
				else{
					feedback.classList.remove('error');
					feedback.classList.add('clean');
					feedback.innerHTML = '';
					field.classList.remove('error');
					field.classList.add('clean');
					if(!field.classList.contains('valid')){
						field.classList.add('valid');
						this.validatedFormFields = this.validatedFormFields + 1;
					}
				}
     	}
  	}

  	if( attr === 'email' ){
  		if(value.length === 0){
				if(field.hasAttribute('required')){
					let errmsg = (this.isEN) ? 'This field cannot be empty' : 'Ce champ ne peut pas être vide';
					feedback.classList.remove('clean');
					feedback.classList.add('error');
					feedback.innerHTML = errmsg;
					field.classList.remove('clean');
					field.classList.add('error');
					if(field.classList.contains('valid')){
						field.classList.remove('valid');
						this.validatedFormFields = this.validatedFormFields - 1;
					}
				}
			} else {
				const pattern = /^\w+([\.\-_]?\w+)*@\w+([\.\-_]?\w+)*(\.\w{2,5})+$/;
				if(!(pattern.test(value))){
					let errmsg = (this.isEN) ? 'This field is in the wrong format. Try using the format <em>email@address.com</em> instead.' : 'Ce champ est en mauvais format.  Essayez d\'utiliser ce format à la place <em>email@address.com</em> ';
					feedback.classList.remove('clean');
					feedback.classList.add('error');
					feedback.innerHTML = errmsg;
					field.classList.remove('clean');
					field.classList.add('error');
					if(field.classList.contains('valid')){
						field.classList.remove('valid');
						this.validatedFormFields = this.validatedFormFields - 1;
					}
				}
				else{
					feedback.classList.remove('error');
					feedback.classList.add('clean');
					feedback.innerHTML = '';
					field.classList.remove('error');
					field.classList.add('clean');
					if(!field.classList.contains('valid')){
						field.classList.add('valid');
						this.validatedFormFields = this.validatedFormFields + 1;
					}
				}
			}
  	}

  	if( attr === 'phone'){
			if(value.length === 0){
				if(field.hasAttribute('required')){
					let errmsg = (this.isEN) ? 'This field cannot be empty' : 'Ce champ ne peut pas être vide';
					feedback.classList.remove('clean');
					feedback.classList.add('error');
					feedback.innerHTML = errmsg;
					field.classList.remove('clean');
					field.classList.add('error');
					if(field.classList.contains('valid')){
						field.classList.remove('valid');
						this.validatedFormFields = this.validatedFormFields - 1;
					}
				}
			} else {
				const pattern = /^(?:\(?)(\d{3})(?:\)?)(\s|\.|-)?(\d{3})(\s|\.|-)?(\d{4})$/;
				if(!(pattern.test(value))){
					let errmsg = (this.isEN) ? 'This field is in the wrong format. Try using the format <em>123-456-7890</em> instead' : 'Ce champ est en mauvais format.  Essayez d\'utiliser ce format à la place  <em>123-456-7890</em>';
					feedback.classList.remove('clean');
					feedback.classList.add('error');
					feedback.innerHTML = errmsg;
					field.classList.remove('clean');
					field.classList.add('error');
					if(field.classList.contains('valid')){
						field.classList.remove('valid');
						this.validatedFormFields = this.validatedFormFields - 1;
					}
				}
				else{
					feedback.classList.remove('error');
					feedback.classList.add('clean');
					feedback.innerHTML = '';
					field.classList.remove('error');
					field.classList.add('clean');
					if(!field.classList.contains('valid')){
						field.classList.add('valid');
						this.validatedFormFields = this.validatedFormFields + 1;
					}
				}
			}
  	}

  	if( attr === 'state' ){
  		if(value.length === 0){
				if(field.hasAttribute('required')){
					let errmsg = (this.isEN) ? 'This field cannot be empty' : 'Ce champ ne peut pas être vide';
					feedback.classList.remove('clean');
					feedback.classList.add('error');
					feedback.innerHTML = errmsg;
					field.classList.remove('clean');
					field.classList.add('error');
					if(field.classList.contains('valid')){
						field.classList.remove('valid');
						this.validatedFormFields = this.validatedFormFields - 1;
					}
				}
			} else{
				feedback.classList.remove('error');
				feedback.classList.add('clean');
				feedback.innerHTML = '';
				field.classList.remove('error');
				field.classList.add('clean');
				if(!field.classList.contains('valid')){
					field.classList.add('valid');
					this.validatedFormFields = this.validatedFormFields + 1;
				}
			}
  	}
  }

  displayThanks()
  {
    this.navigateToCommunityPage(
      {
        pageName: 'thankyou'
      },
      {
        language: this.currentLanguage,
        opportunityId: this.opportunityId
      }
    );
  }

}