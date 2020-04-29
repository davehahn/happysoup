/**
 * Created by dave on 2020-04-10.
 */

import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadStyle } from 'lightning/platformResourceLoader';
import sldsIconFont from '@salesforce/resourceUrl/sldsIconFont';
import gothamFonts from '@salesforce/resourceUrl/GothamHTF';
import LOGO from '@salesforce/resourceUrl/LegendLogo';
import VLOGO from '@salesforce/resourceUrl/LegendLogoVertical';

export default class CustCommOrderBuilder extends NavigationMixin(LightningElement) {

  origin;
  recordId;
  logo = LOGO;
  orderValid=true;
  pages = [
    'performance',
    'trailering',
    'electronics',
    'payment'
  ];
  @track currentPage = 'performance';

 	 modalPages = [
		{
			title: 'Premium Package',
			label: 'premium-package',
			class: 'modal-nav-item modal-nav-item_selected'
		},
		{
			title: 'Payment Calculator',
			label: 'payment-calculator',
			class: 'modal-nav-item'
		},
		{
			title: 'Deliver Timing',
			label: 'delivery',
			class: 'modal-nav-item'
		},
	];
	@track currentModalPage = 'premium-package';

  @track paymentType='cash';
  @track iframeHeight;
  isMobile = false;

  @wire(CurrentPageReference)
  setCurrentPageReference(currentPageReference) {
    this.recordId = currentPageReference.state.c__recordId;
    console.log( this.recordId );
  }

  connectedCallback()
  {
    window.addEventListener('resize', (event) => {
      this.isMobile = (event.currentTarget.outerWidth < 1024) ? true : false;
    });

    this.isMobile = (window.outerWidth < 1024) ? true : false;
  }

  renderedCallback()
  {
    loadStyle( this, sldsIconFont + '/style.css')
    .then(()=>{});
    loadStyle( this, gothamFonts + '/fonts.css')
    .then(()=>{});
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

  submitOrder()
  {
    const spinner = this.template.querySelector('c-legend-spinner');
    spinner.toggle();
    this.template.querySelector('c-square-payment-form').doPostToSquare( 2000 )
    .then( (result) => {
      console.log( 'submitOrder Result ');
      console.log( JSON.parse( JSON.stringify( result ) ) );
    })
    .catch( ( error ) => {
      console.log( error );
      error.forEach( (err) => {
        const event = new ShowToastEvent({
          title: "Please fix the following error",
          message:  err.message,
          variant: 'error',
          mode: 'sticky'
        });
        this.dispatchEvent( event );
      });
    })
    .finally( () => {
      spinner.toggle();
      //alert( 'Figure out what to do now!!!!!');
    });
  }

  onPaymentPage()
  {
    return this.pages.indexOf( this.currentPage ) + 1 === this.pages.length
  }


}
