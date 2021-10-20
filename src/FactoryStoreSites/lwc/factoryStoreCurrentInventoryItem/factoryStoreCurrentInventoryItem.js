/**
 * Created by Tim on 2021-10-19.
 */

import { LightningElement, api } from 'lwc';
import { stringy, stripParentheses, rewriteMotorName, rewriteTrailerName, convertLength, parseLocationName, formatPrice, weeklyPayment, renderEN, renderFR } from 'c/communitySharedUtils';

export default class FactoryStoreCurrentInventoryItem extends LightningElement {
	@api stock;
	@api isCurrent;

	isEN = renderEN();
	isFR = renderFR();

	get isCurrentModel(){
		return (this.isCurrent === 'true') ? true : false;
 	}

}