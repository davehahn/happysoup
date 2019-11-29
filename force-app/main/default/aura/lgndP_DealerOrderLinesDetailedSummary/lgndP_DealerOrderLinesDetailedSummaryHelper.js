({
	fetchOrderDetails : function( component )
  {
    var self = this,
        dealerOrderId = component.get('v.recordId'),
        action = component.get('c.fetchOrderDetails');


    action.setParams({
      recordId: dealerOrderId
    });

    return new Promise( function( resolve, reject ) {
      action.setCallback( self, function( response ) {
        var state = response.getState();
        if (state === "SUCCESS") {
          resolve( JSON.parse( response.getReturnValue() ) );
        }
        else if (component.isValid() && state === "INCOMPLETE") {
          reject( 'incomplete' );
        }
        else if (component.isValid() && state === "ERROR") {
          var errors = response.getError();
          if (errors) {
              if (errors[0] && errors[0].message) {
                  reject("Error message: " +
                           errors[0].message);
              }
          } else {
              reject("Unknown error");
          }
        }
      });

      $A.enqueueAction( action );
    });
	},

  calcTotals: function( component )
  {
    var boatTotals = this.doTotalCalc( component, 'boats' ),
        motorTotals = this.doTotalCalc( component, 'motors' )
        trailerTotals = this.doTotalCalc( component, 'trailers' ),
        trollingMotorTotals = this.doTotalCalc( component, 'trollingMotors' ),
        optionTotals = this.doTotalCalc( component, 'options' ),
        feeTotals = this.doTotalCalc( component, 'fees' ),
        discountTotals = this.doTotalCalc( component, 'discounts' ),
        orderTotal = 0;
    component.set('v.boatTotals', boatTotals );
    component.set('v.motorTotals', motorTotals );
    component.set('v.trailerTotals', trailerTotals );
    component.set('v.trollingMotorTotals', trollingMotorTotals );
    component.set('v.optionTotals', optionTotals );
    component.set('v.feeTotals', feeTotals );
    component.set('v.discountTotals', discountTotals );
    orderTotal = [  boatTotals,
                    motorTotals,
                    trollingMotorTotals,
                    trailerTotals,
                    optionTotals,
                    feeTotals,
                    discountTotals ]
    .reduce( function( total, itemTotal ) {
      total += itemTotal.amount;
      return total;
    }, orderTotal );
    component.set('v.orderTotal', orderTotal );
  },

  doTotalCalc: function( component, item_name )
  {
    var items = component.get('v.'+item_name);
    if( items === null )
      return null;
    return items.reduce( function( total, item ) {
              total.count ++;
              if( item.total !== undefined )
                total.amount += parseFloat( item.total );
              else
                total.amount += parseFloat( item.cost );
              return total;
            }, {count: 0, amount: 0} );
  }
})