/**
 * Created by Tim on 2021-04-01.
 */

import { LightningElement } from 'lwc';

export default class FactoryStoreFooterCopyright extends LightningElement {
	get currentYear(){
	  let d = new Date();
	  return d.getFullYear();
 }
}