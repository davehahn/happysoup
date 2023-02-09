/**
 * Created by dave on 2020-02-27.
 */

import { ShowToastEvent } from "lightning/platformShowToastEvent";

const gen8DigitId = () => {
  return Math.random().toString(36).substring(2, 10);
};

const errorToast = (cmp, msg, title) => {
  title = typeof title === "undefined" ? "An Error Occurred" : title;
  showToast(cmp, "error", msg, title);
};

const warningToast = (cmp, msg, title) => {
  title = typeof title === "undefined" ? "Warning!" : title;
  showToast(cmp, "warning", msg, title);
};

const successToast = (cmp, msg, title) => {
  title = typeof title === "undefined" ? "Success!" : title;
  showToast(cmp, "success", msg, title);
};

const infoToast = (cmp, msg, title) => {
  title = typeof title === "undefined" ? "Application Information" : title;
  showToast(cmp, "info", msg, title);
};

const showToast = (cmp, variant, message, title) => {
  const evt = new ShowToastEvent({
    title: title,
    message: message,
    variant: variant,
    mode: "dismissable"
  });
  cmp.dispatchEvent(evt);
};

const reduceErrors = (errors) => {
  if (!Array.isArray(errors)) {
    errors = [errors];
  }

  return (
    errors
      // Remove null/undefined items
      .filter((error) => !!error)
      // Extract an error message
      .map((error) => {
        // UI API read errors
        if (Array.isArray(error.body)) {
          return error.body.map((e) => e.message);
        }
        // UI API DML, Apex and network errors
        else if (error.body && typeof error.body.message === "string") {
          return error.body.message;
        }
        // JS errors
        else if (typeof error.message === "string") {
          return error.message;
        }
        // Unknown error shape so try HTTP status text
        return error.statusText;
      })
      // Flatten
      .reduce((prev, curr) => prev.concat(curr), [])
      // Remove empty strings
      .filter((message) => !!message)
  );
};

/*
  @params = {
    groupedItems: [{groupName: [ {planItems} ] } ] (grouped line items),
    amount: 50000 (preInsurance Amount)
    deposit: 1000
    term: 60
    amort: 120
    interestRate: 6.99
    insuranceTaxRate: 8
    calculationMethod: 'Simple' || 'Recursive'
  }
*/
const doInsuranceCalculations = (params) => {
  const calculationMethod =
    params.calculationMethod === undefined || params.calculationMethod === null
      ? "Recursive"
      : params.calculationMethod;
    if(calculationMethod === 'Recursive'){
      recursiveCalculation(params);
    }
    if(calculationMethod === 'Simple'){
      simpleCalculation(params);
    }
};

function recursiveCalculation(params){
  var v, ann, paymt, acc, res, newAmount, origPaymt, cost, paymentsMatch = false;

  let amount = params.amount - params.deposit;
   newAmount = amount;

  if( params.groupedItems === undefined || params.groupedItems.length === 0 ){
    paymentsMatch = true;
  }

  if( parseFloat(params.interestRate) === 0 )
  {
    paymt =  doRound(amount / params.amort);
  }
  else
  {
    let interestRate = params.interestRate / 100;
    v = 12 / ( 12 + interestRate );
    ann = (1 - Math.pow(v, params.amort)) / (interestRate / 12);
    paymt = doRound(amount / ann);
    acc = (1 - Math.pow(v, (params.amort - params.term))) / (interestRate / 12);
  }

  while( !paymentsMatch )
  {
    //if acc is not set then we are dealing with 0 Interest
    if( acc === undefined || acc === null )
      res = newAmount - ( paymt * params.term );
    else
      res = doRound(paymt * acc);

    newAmount = amount;
    origPaymt = paymt;

    params.groupedItems.forEach( planItems => {
      planItems.planItems.forEach( item => {
        if(item.isSelected && !item.termOutOfRange){
          cost = null;
          if( item.isResidual == false || item.isResidual === 'false' )
          {
            cost = doRound(paymt * params.term * item.rate / 100);
            item.unitPrice = cost;
          }
          else
          {
            cost = doRound(res * item.rate / 100);
            item.unitPrice = cost;
          }
          newAmount += ( cost * ( 1 + (params.insuranceTaxRate / 100) ) );
        }
      })
    });

    //if ann is not set then we afre doing 0 Interest
    if( ann === undefined || ann === null ){
      paymt = doRound( newAmount / params.amort );
    } else {
      paymt = doRound( newAmount / ann );
    }
    if( origPaymt == paymt ){
      paymentsMatch = true;
    }
  }
}

function simpleCalculation( params )
{
  var v, ann, paymt, interestRate,
      feeApplicableType = determineFeeApplicableType(params.groupedItems),
      amount = params.amount - params.deposit;
  if( params.interestRate === 0 )
  {
    paymt = doRound( amount / params.amort );
  }
  else
  {
    interestRate = params.interestRate / 100;
    v = 12 / ( 12 + interestRate );
    ann = (1 - Math.pow(v, params.amort)) / (interestRate / 12);
    paymt = doRound(amount / ann);
  }

  params.groupedItems.forEach( planItems => {
    planItems.planItems.forEach( item => {
      if(item.isSelected){
        item.unitPrice = doRound(paymt * item.rate );
        if( feeApplicableType && item.type === feeApplicableType ){
          item.unitPrice += 50;
        }
      }
    })
  });
}

function doRound( n )
{
  return Math.round( n * 1e2 ) / 1e2;
}

function determineFeeApplicableType(items)
{
  var hasLife = false,
      hasIllness = false,
      hasDisability = false;

  params.groupedItems.forEach( planItems => {
    planItems.planItems.forEach( item => {
      if(item.isSelected){
        if( item.type === 'Life Insurance Coverage' ){
          hasLife = true;
         }
        if( item.type === 'Critical Illness Coverage' ){
          hasIllness = true;
         }
        if( item.type === 'Disability Insurance Coverage' ){
          hasDisability = true;
        }
      }
    })
  });
  if( hasDisability )
    return 'Disability Insurance Coverage';
  if( hasLife )
    return 'Life Insurance Coverage';
  if( hasIllness )
    return 'Critical Illness Coverage';
  return false;
}

export { gen8DigitId, errorToast, warningToast, successToast, infoToast, reduceErrors, doInsuranceCalculations };
