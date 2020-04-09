/**
 * Created by dave on 2020-04-09.
 */

import { LightningElement } from 'lwc';
import LOGO from '@salesforce/resourceUrl/LegendLogo';

export default class CustCommPublicMain extends LightningElement {

  logo = LOGO;

  toggleMenu()
  {
    this.template.querySelector('.overlay').classList.toggle('open');
    this.template.querySelector('.slide-menu').classList.toggle('open');
  }

}
