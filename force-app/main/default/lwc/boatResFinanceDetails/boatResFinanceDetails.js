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
  pages = ['cash', 'loan'];

  payments = {
    weekly: 11.11,
    biweekly: 22.22,
    monthly: 333.33
  };


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

  get tabData()
  {
    return this.pages.map( page => {
      return {
        label: page,
        class: this.financeType === page ?
          'finance-nav-item finance-nav-item_selected' :
          'finance-nav-item'
      }
    });
  }

  get interestRateValue()
  {
    return `${this.interestRate} %`;
  }

  handleNav( event )
  {
    const navPage =  event.currentTarget.dataset.navName;
    console.log(`Nav to page ${navPage}`);
    this.financeType = navPage;
  }

}