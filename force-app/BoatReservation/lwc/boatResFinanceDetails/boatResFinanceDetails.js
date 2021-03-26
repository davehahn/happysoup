/**
 * Created by dave on 2020-06-25.
 */

import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { registerListener, fireEvent } from 'c/pubsub';

export default class BoatResFinanceDetails extends LightningElement {

  @api paymentType;
  @api deposit;
  @api amount;
  @api amort;
  @api interestRate;
  @api premiumPackValue;
  @api premiumPackItems;
  @api hideInputs
  //@track downPayment = 1000;

  numOfAmortYears = 20;
  pages = [
    {
      label: 'cash',
      label_fr: 'comptant'
    },
    {
      label: 'loan',
      label_fr: 'emprunt'
    }
  ];
  initialRenderComplete = false;

  @track payments = {
    weekly: 11.11,
    biweekly: 22.22,
    monthly: 333.33
  };

  @track isEN = true;
	@track isFR = false;

  @wire(CurrentPageReference) pageRef;

  connectedCallback(){
    registerListener('purchasePriceChanged', this.handlePurchasePriceChange, this);
  }

  renderedCallback()
  {
    this.template.querySelector('select[data-field-name="term"]').value = this.amort;
    if( !this.initialRenderComplete )
    {
      this.calculate();
      this.initialRenderComplete = true;
    }
    registerListener('languageChange', this.handleLanguageChange, this);
  }

  get termOptions()
  {
    return Array.from( { length: this.numOfAmortYears}, (v,k) => (k+1)*12 )
    .reduce( (result, currentVal) => {
      result.push({
        value: currentVal,
        label: `${currentVal} months`,
        label_fr: `${currentVal} mois`
      });
      return result;
    }, [] );
  }

  get tabData()
  {
    return this.pages.map( page => {
      return {
        label: page.label,
        title: this.isEN ? page.label : page.label_fr,
        class: this.paymentType === page.label ?
          'finance-nav-item finance-nav-item_selected' :
          'finance-nav-item'
      }
    });
  }

  handleNav( event )
  {
    const navPage =  event.currentTarget.dataset.navName;
    this.paymentType = navPage;
    fireEvent( this.pageRef, 'paymentTypeChanged', this.paymentType );
  }

  handleTermChange( event )
  {
    this.amort = event.currentTarget.value;
    this.calculate();
  }

  handlePurchasePriceChange( amount )
  {
    this.amount = amount;
    this.calculate();
  }

  @api calculate()
  {
    if( this.amount === undefined ) return;
    if( this.interestRate === undefined ) return;

    const amountFinanced = this.amount - this.deposit,
          compound_per_year = 12;
    let compoundInterest, payment;

    if( parseFloat( this.interestRate ) === 0 )
    {
      payment = ( amountFinanced / this.amort );
      //remaining = ( amountFinanced - ( payment * term ) );
    }
    else
    {
      compoundInterest = this.interestRate  / compound_per_year,
      payment = ( compoundInterest * amountFinanced ) / ( 1 - ( Math.pow( (1 + compoundInterest), (- ( this.amort * compound_per_year / 12 ) ) ) ) );
      //remaining = amountFinanced *( Math.pow((1+ compoundInterest ), ( term * compound_per_year / 12)) ) -( payment )*( ( Math.pow((1+ compoundInterest ),( term * compound_per_year / 12)) - 1 ) /compoundInterest );
    }
    this.payments.monthly = ( payment / ( 12 / compound_per_year ) );
    this.payments.biweekly = ( payment / ( 26 / compound_per_year ) );
    this.payments.weekly = ( payment / ( 52 / compound_per_year ) );

    fireEvent( this.pageRef, 'paymentAmountChanged', this.payments );
  }

  get retailPlusPremium(){
    const value = this.amount + this.premiumPackValue;
    return value;
  }

  handleLanguageChange(detail){
			if(detail){
				this.isEN = (detail === 'EN') ? true : false;
				this.isFR = (detail === 'FR') ? true : false;
		}
	}

}