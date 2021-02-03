/**
 * Created by dave on 2020-01-26.
 */

import { LightningElement, api, wire, track } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { fireEvent, registerListener, unregisterAllListeners} from 'c/pubsub';

export default class AccountFindClosestPartnerDetailsCard extends NavigationMixin(LightningElement) {
  @api acct;
  @api originAddress;
  @api isSelectable;
  @api hideIcon=false;

	@wire(CurrentPageReference) pageRef;

  get teleHref()
  {
    return 'tel:' + this.acct.phone;
  }

  get emailHref()
  {
    return 'emailto:' + this.acct.email;
  }

  handleSelect( evt )
  {
    this.dispatchEvent(
      new CustomEvent(
        'accountselected',
        { detail: this.acct }
      )
    );
  }

  navToWebsite( evt )
  {
    evt.preventDefault();
    this.navToURL( evt.currentTarget.getAttribute('href') );
    return false;
  }

  showDirections()
  {
//    let url = 'https://google.com/maps/dir/';
//    url += this.originAddress.split(' ').join('+');
//    url += '/' + this.acct.location.Street.split(' ').join('+') + ',';
//    url += '+' + this.acct.location.City +',';
//    url += '+' + this.acct.location.State;
//    this.navToURL(url);
		fireEvent(this.pageRef, 'setMap', this.acct);
    return false;
  }

  navToURL( url )
  {
    if( url.toLowerCase().substring(0,4) !== 'http')
    {
      url = 'http://' + url;
    }
    window.open( url, "_blank");
  }
}