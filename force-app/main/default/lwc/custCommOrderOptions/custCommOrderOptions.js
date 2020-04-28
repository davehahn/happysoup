/**
 * Created by Tim on 2020-04-22.
 */

import { LightningElement, api } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import gothamFonts from '@salesforce/resourceUrl/GothamHTF';

export default class CustCommOrderOptions extends LightningElement {
    @api optionsTitle;
    @api selections;
    @api selectionScope;

    renderedCallback()
      {
        loadStyle( this, gothamFonts + '/fonts.css')
        .then(()=>{});
      }
}