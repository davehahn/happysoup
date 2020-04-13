/**
 * Created by dave on 2020-04-10.
 */

import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import LOGO from '@salesforce/resourceUrl/LegendLogo';

export default class CustCommOrderBuilder extends NavigationMixin(LightningElement) {

  recordId;
  logo = LOGO;
  orderValid=false;
  pages = [
    'motor',
    'trailer',
    'package',
    'electronics',
    'payment'
  ];
  @track currentPage = 'motor';
  @track paymentType='cash';

  @wire(CurrentPageReference)
  setCurrentPageReference(currentPageReference) {
    this.recordId = currentPageReference.state.c__recordId;
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
  }

  handleOpenModal()
  {
    this.toggleModal( true );
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
    this.template.querySelector('.config-nav-item_selected').classList.remove('config-nav-item_selected');
    this.template.querySelector(`[data-nav-name="${this.currentPage}"]` ).classList.add('config-nav-item_selected');
    /* content */
    this.template.querySelector('.config-page_selected').classList.remove('config-page_selected');
    this.template.querySelector(`[data-page="${this.currentPage}"]` ).classList.add('config-page_selected');
  }

  submitOrder()
  {
    console.log('Submit Order');
    return;
  }

  onPaymentPage()
  {
    return this.pages.indexOf( this.currentPage ) + 1 === this.pages.length
  }


}