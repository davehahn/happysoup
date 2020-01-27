/**
 * Created by dave on 2020-01-27.
 */

import { LightningElement, api, track } from 'lwc';
import SPINNER from '@salesforce/resourceUrl/LegendLoadingIndicator2017';

export default class LegendSpinner extends LightningElement {
  @track visible = false;
  @api variant;
  spinner = SPINNER;

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
    this.visible = !this.visible;
  }

}