/**
 * Created by dave on 2020-04-16.
 */

import { LightningElement, api, track } from 'lwc';

export default class SquarePaymentForm extends LightningElement {

  origin;

  @api apexPageName;
  @api isResponsive = false;
  @api widthBreakPoint = 140;
  @api smallHeight = 200;
  @api largeHeight = 400;

  @track iframeHeight;

  constructor()
  {
    super();
    this.origin = window.location.origin;
  }

  connectedCallback()
  {
    if( this.isResponsive )
    {
      window.addEventListener('resize', (event) => {
        this.setIframeHeight( event.currentTarget.outerWidth );
      });
    }
    this.setIframeHeight( window.outerWidth );
  }

  @api doPostToSquare( paymentAmount, reference_id )
  {
    const data = {
      messageType: 'doPayment',
      paymentAmount: paymentAmount,
      reference_id: reference_id
    };
    const iframe = this.template.querySelector('[data-id="square-payment-container"]').contentWindow;

    return new Promise( (resolve, reject) => {
      const messageHandler = ( event ) =>
      {
        if( event.origin === this.origin )
        {
          window.removeEventListener('message', messageHandler );
          if( event.data.status === 'success' )
            resolve( event.data.response );
          if( event.data.status === 'error' )
            reject( event.data.errors );
        }
      };
      window.addEventListener('message', messageHandler );
      iframe.postMessage(data, this.origin);
    });
  }

  get pageURL()
  {
    const urlString = window.location.href;
    return urlString.substring(0, urlString.indexOf("/s") ) + this.apexPageName;
  }

  setIframeHeight( width )
  {
     this.iframeHeight = width >= this.widthBreakPoint ?
      `height:${this.smallHeight}px` : `height:${this.largeHeight}px`;
  }
}
