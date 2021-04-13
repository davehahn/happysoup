/**
 * Created by dave on 2020-01-27.
 */

import { LightningElement, api, track } from 'lwc';
import SPINNER from '@salesforce/resourceUrl/LegendLoadingIndicator2017';

export default class LegendSpinner extends LightningElement {
  @api visible = false;
  @api variant;
  spinner = SPINNER;
  busyMessage;

  connectedCallback()
  {
    if( this.variant !== 'contained' )
    {
      this.variant='full';
    }
  }

  get spinnerClass()
  {
    let klass = 'lgnd-spinner';
    if( this.variant === 'contained' )
    {
      klass += ' lgnd-spinner_contained';
    }
    return klass;
  }

  @api toggle()
  {
    this.visible ? this.close() : this.open();
  }

  @api open()
  {
    this.visible = true;
  }

  @api close()
  {
    this.visible = false;
    this.busyMessage = undefined;
  }

  @api setMessage( msg )
  {
    this.busyMessage = msg;
  }

}