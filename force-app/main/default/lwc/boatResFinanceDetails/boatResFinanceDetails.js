/**
 * Created by dave on 2020-06-25.
 */

import { LightningElement, api, track } from 'lwc';

export default class BoatResFinanceDetails extends LightningElement {

  @api financeType;
  @api deposit;
  @api amount = 10000;

  @track amort = 60;
  @track interestRate = 5.00;
  @track downPayment = 2000;

  numOfAmortYears = 20;

  renderedCallback()
  {
    this.template.querySelector('select[data-field-name="term"]').value = this.amort;
  }

  get termOptions()
  {
    return Array.from( { length: this.numOfAmortYears}, (v,k) => (k+1)*12 )
    .reduce( (result, currentVal) => {
      result.push({
        value: currentVal,
        label: `${currentVal} months`
      });
      return result;
    }, [] );
  }

}