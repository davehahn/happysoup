(function( window, document, undefined ) {

  class LightningUtils {

    constructor() {
    }

    static showToast(state, title, message)
    {
      toaster(state, title, message);
    }

    static errorToast( err )
    {
      toaster( 'error', 'We have encountered an error!', err);
    }

    static doInsuranceCostCalculations( items,
                                        amount,
                                        deposit,
                                        term,
                                        amort,
                                        intrestRate,
                                        insuranceTaxRate,
                                        calculationMethod )
    {
      calculationMethod = calculationMethod === undefined || calculationMethod === null ? 'Recursive' : calculationMethod;
      if( calculationMethod === 'Recursive' )
        return recursiveCalculation( items,
                                     amount,
                                     deposit,
                                     term,
                                     amort,
                                     intrestRate,
                                     insuranceTaxRate );
      if( calculationMethod === 'Simple' )
        return simpleCalculation( items,
                                  amount,
                                  deposit,
                                  term,
                                  amort,
                                  intrestRate,
                                  insuranceTaxRate );
      return Promise.reject('Incorrect Calculation Method Specified');
    }

  }

  function recursiveCalculation( items,
                                 amount,
                                 deposit,
                                 term,
                                 amort,
                                 intrestRate,
                                 insuranceTaxRate )
  {
    return new Promise( function( resolve, reject ) {
      var v, ann, paymt, acc, res, newAmount, origPaymt, cost, paymentsMatch = false;

      amount = amount - deposit;
      newAmount = amount;

      if( items === undefined || items.length === 0 )
        paymentsMatch = true;

      if( parseFloat(intrestRate) === 0 )
      {
        paymt =  doRound(amount / amort);
      }
      else
      {
        intrestRate = intrestRate / 100;
        v = 12 / ( 12 + intrestRate );
        ann = (1 - Math.pow(v, amort)) / (intrestRate / 12);
        paymt = doRound(amount / ann);
        acc = (1 - Math.pow(v, (amort - term))) / (intrestRate / 12);
      }

      while( !paymentsMatch )
      {
        //if acc is not set then we are dealing with 0 Interest
        if( acc === undefined || acc === null )
          res = newAmount - ( paymt * term );
        else
          res = doRound(paymt * acc);

        newAmount = amount;
        origPaymt = paymt;

        for( var i=0; i< items.length; i++ )
        {
          cost = null;
          if( items[i].isResidual == false || items[i].isResidual === 'false' )
          {
            cost = doRound(paymt * term * items[i].insuranceRate / 100);
            items[i].unitPrice = cost;
          }
          else
          {
            cost = doRound(res * items[i].insuranceRate / 100);
            items[i].unitPrice = cost;
          }
          newAmount += ( cost * ( 1 + (insuranceTaxRate / 100) ) );
        }

        //if ann is not set then we afre doing 0 Interest
        if( ann === undefined || ann === null )
          paymt = doRound( newAmount / amort );
        else
          paymt = doRound( newAmount / ann );

        if( origPaymt == paymt )
          paymentsMatch = true;
      }
      resolve( items );
    });
  }

  function simpleCalculation( items,
                              amount,
                              deposit,
                              term,
                              amort,
                              intrestRate,
                              insuranceTaxRate )
  {
    return new Promise( function( resolve, reject ) {
      var v, ann, paymt,
          feeApplicableType = determineFeeApplicableType(items);
      amount = amount - deposit;
      if( intrestRate === 0 )
      {
        paymt = doRound( amount / amort );
      }
      else
      {
        intrestRate = intrestRate / 100;
        v = 12 / ( 12 + intrestRate );
        ann = (1 - Math.pow(v, amort)) / (intrestRate / 12);
        paymt = doRound(amount / ann);
      }

      for( var i=0; i< items.length; i++ )
      {
        items[i].unitPrice = doRound(paymt * items[i].insuranceRate );
        if( feeApplicableType && items[i].type === feeApplicableType )
          items[i].unitPrice += 50;
      }
      resolve( items );
    });
  }

  function calcJointFactor( unitPrice, insuranceType )
  {
    if( insuranceType === 'Life Insurance Coverage' )
      return unitPrice * 1.8;
    if( insuranceType === 'Critical Illness Coverage' )
      return unitPrice * 1.8;
    if( insuranceType === 'Disability Insurance Coverage' )
      return unitPrice * 2.0;
    return unitPrice;
  }

  function determineFeeApplicableType(items)
  {
    var hasLife = false,
        hasIllness = false,
        hasDisability = false;
    for( var i=0; i<items.length; i++ )
    {
      if( items[i].type === 'Life Insurance Coverage' )
        hasLife = true;
      if( items[i].type === 'Critical Illness Coverage' )
        hasIllness = true;
      if( items[i].type === 'Disability Insurance Coverage' )
        hasDisability = true;
    }
    if( hasDisability )
      return 'Disability Insurance Coverage';
    if( hasLife )
      return 'Life Insurance Coverage';
    if( hasIllness )
      return 'Critical Illness Coverage';
    return false;
  }

  function doRound( n )
  {
    return Math.round( n * 1e2 ) / 1e2;
  }

  function toaster( state, title, message )
  {
    var toastEvent = $A.get("e.force:showToast");
    toastEvent.setParams({
        "title": title,
        "message": message,
        type: state
    });
    toastEvent.fire();
  }

  window.LightningUtils = LightningUtils;

})( window, document );