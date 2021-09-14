/**
 * Created by Tim on 2021-04-01.
 */

import { LightningElement } from 'lwc';
import { renderEN, renderFR } from 'c/communitySharedUtils';

export default class FactoryStoreFooterAllInPricing extends LightningElement {
	isEN = renderEN();
	isFR = renderFR();
}