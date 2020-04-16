/**
 * Created by dave on 2020-04-10.
 */

import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { loadStyle } from 'lightning/platformResourceLoader';
import sldsIconFont from '@salesforce/resourceUrl/sldsIconFont';
import LOGO from '@salesforce/resourceUrl/LegendLogo';

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
  @track paymentType='cash';
  @track iframeHeight;

  @wire(CurrentPageReference)
  setCurrentPageReference(currentPageReference) {
    this.recordId = currentPageReference.state.c__recordId;
  }

  constructor()
  {
    super();
    this.origin = window.location.origin;
    window.addEventListener('message', (event) => {
      if( event.origin === this.origin )
      {
        console.log( JSON.parse( JSON.stringify( event.data ) ) );
      }
    });
    window.addEventListener('resize', (event) => {
      console.log( event.currentTarget.outerWidth )
      this.setIframeHeight( event.currentTarget.outerWidth );
    });
  }

  connectedCallback()
  {
    this.setIframeHeight( window.outerWidth );
  }

  renderedCallback()
  {
    loadStyle( this, sldsIconFont + '/style.css')
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

  get paymentPageURL()
  {
    const paymentApexPage = '/apex/Square_PaymentForm_CustomerCommunity';
    const urlString = window.location.href;
    return urlString.substring(0, urlString.indexOf("/s") ) + paymentApexPage;
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
    this.template.querySelector('.modal-container').addEventListener('click', () => {
      this.toggleModal(false);
    });
  }

  handleEditConfig()
  {
    this.doPageChange('performance');
  }

  setIframeHeight( w )
  {
    this.iframeHeight = w >= 1401 ? 'height:184px' : 'height:368px';
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

  handleNext()
  {
    this.onPaymentPage() ?
    this.submitOrder() :
    this.doPageChange( this.pages[ this.pages.indexOf( this.currentPage ) +1 ] );
  }

  doPageChange( page )
  {
    this.currentPage = page;
    /* nav */
    //this.template.querySelector('.config-nav-item_selected').classList.remove('config-nav-item_selected');
    //this.template.querySelector(`[data-nav-name="${this.currentPage}"]` ).classList.add('config-nav-item_selected');
    /* content */
    this.template.querySelector('.config-page_selected').classList.remove('config-page_selected');
    this.template.querySelector(`[data-page="${this.currentPage}"]` ).classList.add('config-page_selected');
  }

  submitOrder()
  {

    const data = { paymentAmount: 6000 };
    const iframe = this.template.querySelector('[data-id="square-payment-container"]').contentWindow;

    iframe.postMessage(data, this.origin);
    console.log('Submit Order');

  }

  onPaymentPage()
  {
    return this.pages.indexOf( this.currentPage ) + 1 === this.pages.length
  }


}