/**
 * Created by Tim on 2020-04-22.
 */

import { LightningElement, api } from 'lwc';

export default class CustCommOrderOptions extends LightningElement {
    @api optionsTitle;
    @api selections;
    @api selectionScope;

}