({
  setUserType: function( component )
  {
    var self = this,
        action = component.get('c.builderInit');

    return new Promise( function( resolve, reject ) {
      self.actionHandler.call(self, component, action, true )
      .then(
        $A.getCallback( function(result) {
          self.functions.clearVars( component );
          component.set('v.modelYearOptions', result.modelYearOptions );
          component.set('v.userType', result.userType);
          component.set('v.sessionId', result.sessionId );
          component.set('v.modelYear', result.modelYear);
          if( result.uiTheme !== 'Theme3' )
            component.set('v.inCommuninty', false );
          resolve();
        })
      );
    });
  },

	fetchProducts : function( component, recordType, family )
  {
    var self = this,
        action = component.get("c.fetchProducts"),
        message = 'Retrieving ';

    message += recordType + 's';

    action.setParams({
      'recordType': recordType,
      'family': family,
      'pricebookId': component.get('v.dealerOrder').Pricebook__c
    });

    return self.actionHandler.call( self, component, action, false, true, message );
	},

  fetchProduct: function( component, productId, recordTypeName )
  {
    var action = component.get("c.fetchProductDetails"),
        dealerOrder = component.get('v.dealerOrder');

    action.setParams({
      recordTypeName: recordTypeName,
      productId: productId,
      pricebookId: dealerOrder.Pricebook__c
    });

    return this.actionHandler.call( this, component, action, false, true, 'Retrieving Details' );
  },

  saveDealerOrderLine: function( component )
  {
    var self = this,
        boat = component.get('v.boat'),
        trailer = component.get('v.trailer'),
        motor = component.get('v.motor'),
        trollingMotor = component.get('v.trollingMotor'),
        quantity = component.get('v.quantity'),
        //options = component.get('v.options'),
        motorOptions = component.get('v.motorOptions'),
        fees = component.get('v.feeList'),
        discounts = component.get('v.discounts'),
        dealerOrder = component.get('v.dealerOrder'),
        order_ProductRecordType = component.get('v.recordType'),
        isMotorRequest = component.get('v.isMotorRequest'),
        erpLineItems = [],
        isFactoryStore = component.get('v.isFactoryStore'),
        motorRequest = component.get('v.motorRequest'),
        orderGroupId = component.get('v.orderGroupId'),
        options = [],
        data = {},
        action = component.get('c.saveDealerLineItem');

    self.functions.toggleSpinner( component, true, 'Saving Order' );

    for( let optionGroup of component.get('v.optionalProducts') )
    {
      options = options.concat( optionGroup.values );
    }

    if( options !== undefined && options !== null )
    {
      for( let option of options)
      {
        if( ( option.isCheckbox && option.isSelected ) ||
            ( !option.isCheckbox && option.quantitySelected > 0 ) )
        {
          erpLineItems.push( option );
        }
        if( option.subOptions !== undefined && option.subOptions !== null )
        {
          for( var i=0; i<option.subOptions.length; i++ )
          {
            if( ( option.subOptions[i].isCheckbox && option.subOptions[i].isSelected ) ||
                (!option.subOptions[i].isCheckbox && option.subOptions[i].quantitySelected > 0 ) )
            {
              erpLineItems.push( option.subOptions[i] );
            }
          }
        }
      }
    }
    for( var i=0; i<fees.length; i++ )
    {
      if( !isMotorRequest )
        erpLineItems.push( fees[i] );
    }
    data.discounts = [];
    for( var i=0; i<discounts.length; i++ )
    {
      data.discounts.push( discounts[i] );
    }
    data.notes = component.get('v.notes');
    data.quantity = quantity;
    data.dealerOrderId = dealerOrder.Id;
    data.isLegendTransfer = dealerOrder.Is_Legend_Transfer__c;
    data.accountId = dealerOrder.Account__c;
    data.isMotorRequest = isMotorRequest;
    data.modelYear = component.get('v.modelYear');
    if( boat !== null && Object.keys(boat).length > 0 )
    {
      boat.isSelected = true;
      boat.isCheckbox = true;
      data.boat = boat;
      erpLineItems.push( boat );
    }
    if( trailer !== null && Object.keys(trailer).length > 0 )
    {
      trailer.isSelected = true;
      trailer.isCheckbox = true;
      data.trailer = trailer;
      erpLineItems.push( trailer );
    }

    if( motor !== null && Object.keys(motor).length > 0 )
    {
      motor.isSelected = true;
      motor.isCheckbox = true;
      if( isFactoryStore )
      {
        data.motor = motor;
        erpLineItems.push( motor );
        for( let mo of motorOptions )
        {
          if( mo.isSelected )
            erpLineItems.push( mo );
        }
      }
      else if( order_ProductRecordType === 'Motor' && isMotorRequest )
      {
        motorRequest.Motor__c = motor.id;
        motorRequest.Quantity__c = quantity;
      }
      else if( !isMotorRequest &&
                ( dealerOrder.Is_Legend_Transfer__c || order_ProductRecordType === 'Motor' )
             )
      {
        data.motor = motor;
        erpLineItems.push( motor );
      }
      else
      {
        motorRequest.Motor__c = motor.id;
        motorRequest.Quantity__c = quantity;
      }
    }

    if( trollingMotor !== null && Object.keys(trollingMotor).length > 0 )
    {
      trollingMotor.isSelected = true;
      trollingMotor.isCheckbox = true;
      data.trollingMotor = trollingMotor;
      erpLineItems.push( trollingMotor );
    }
    if( orderGroupId !== undefined && orderGroupId !== null && orderGroupId.length > 0 )
      data.orderGroupId = orderGroupId;
    data.lineItems = erpLineItems;

    return new Promise( function( resolve, reject ) {
      self.handleMotorRequest.call(self, component, motorRequest )
      .then(
        $A.getCallback( function( result ) {
          motorRequest = result;
          //required for saving
          motorRequest.sobjectType = 'Dealer_Motor_Request__c';
          component.set('v.motorRequest', motorRequest);
          if( motorRequest.Id !== undefined )
          {
            data.dealerMotorRequestId = motorRequest.Id;
            data.motor = { id: motorRequest.Motor__c };
          }
          action.setParams({
            jsonData: JSON.stringify( data )
          });
          return new LightningApex(self, action).fire();
          //return self.actionHandler.call( self, component, action );
        }),
        $A.getCallback( function(err) {
          reject(err);
        })
      )

      .then(
        $A.getCallback( function( result ) {
          resolve( result );
        }),
        $A.getCallback( function( err) {
          reject(err);
        })
      );
    });


  },

  applyPartnerProgram: function( component )
  {
    const dealerOrder = component.get('v.dealerOrder');
    let action = component.get('c.applyPartnerProgram');
    action.setParams({
      dealerOrderId: dealerOrder.Id
    });
    this.functions.toggleModal( component, 'close');
    this.functions.toggleSpinner( component, true, 'Applying Partner Program');
    new LightningApex( this, action ).fire();
  },

  handleMotorRequest: function( component, motorRequest )
  {
    var self = this,
        action = component.get('c.saveMotorRequest');
    return new Promise( function( resolve, reject ) {
      if( ( motorRequest.Motor__c === undefined ||
            motorRequest.Motor__c === null ||
            motorRequest.Motor__c ===  '' ) &&
          ( motorRequest.Id === undefined ||
            motorRequest.Id === null ||
            motorRequest.Id ===  '' )
        )
        resolve(motorRequest);
      else
      {
        action.setParams({
          motorRequest: motorRequest
        });
        action.setCallback( self, function(response) {
          var state = response.getState();
          if( state === 'SUCCESS' )
          {
            resolve( response.getReturnValue() );
          }
          if( state === 'INCOMPLETE' )
          {
            reject( 'incomplete' );
          }
          if( state === 'ERROR' )
          {
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
      }
    });
  },

  initForEdit: function( component, groupId )
  {
    var action = component.get('c.editDealerLineItem');

    action.setParams({
      groupId: groupId,
      pricebookId: component.get('v.dealerOrder').Pricebook__c
    });

    return this.actionHandler.call(this, component, action, false, true, 'Initializing');

  },

  actionHandler: function( component, action, parse, showIndicator, message )
  {
    var self = this;
    showIndicator = showIndicator === undefined ? true : showIndicator;
    parse = parse === undefined ? false : parse;
    if( showIndicator )
      self.functions.toggleSpinner( component, true, message );
    return new Promise( function(resolve, reject) {

      action.setCallback(self, function(response) {
        var state = response.getState();
        if( state === 'SUCCESS' )
        {
          var result = response.getReturnValue();
          if( parse )
            result = JSON.parse(result);
          resolve( result );
        }
        if( state === 'INCOMPLETE' )
        {
          reject( 'incomplete' );
        }
        if( state === 'ERROR' )
        {
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
        if( showIndicator )
          self.functions.toggleSpinner( component, false );
      });

      $A.enqueueAction( action );
    });
  },

  selectTypeFunction: function( component, family, recordType )
  {
    var self = this,
        dealerOrder = component.get('v.dealerOrder');

    return new Promise( function( resolve, reject ) {
      component.set( 'v.family', family );
      component.set( 'v.recordType', recordType );
      self.fetchProducts(component, recordType, family )
      .then(
        //fetchProducts SUCCESS
        $A.getCallback( function(response) {
          //self.functions.clearVars( component );
          self.handleConfigChange( component, { whatChanged: 'reset' } )
          .then(
            //handleConfigChange SUCCESS
            $A.getCallback( function()
            {
              component.set( 'v.boatSelectOptions', [] );
              component.set( 'v.motorSelectOptions', [] );
              component.set( 'v.trailerSelectOptions', [] );
              component.set( 'v.selectedBoat_Id', '');
              component.set( 'v.selectedTrailer_Id', 'none');
              component.set( 'v.selectedMotor_Id', 'none');
              component.set( 'v.selectedTrollingMotor_Id', 'none');
              component.set( 'v.hasStandardTrailer', false);
              component.set( 'v.hasStandardMotor', false);
              self.fireChangeEvent( component );
              if( recordType === 'Boat' )
              {
                component.set('v.boatSelectOptions', response );
              }
              if( recordType === 'Motor' )
              {
                component.set('v.motorSelectOptions', response );
                component.set('v.isMotorRequest', !component.get('v.isFactoryStore') );
              }
              if( recordType === 'Trailer' )
              {
                component.set('v.trailerSelectOptions', response );
              }
              if( recordType === 'Trolling Motor' )
              {
                component.set('v.trollingMotorSelectOptions', response );
              }
              //resolve the selectTypeFunction promise;
              resolve();
            })
          );
        }),

        //ftechProducts ERROR
        $A.getCallback(function(err) {
          reject(err);
        })
      );
    });
  },

  selectBoatFunction: function( component, boatId, selectedOptions )
  {
    var helper = this,
        prov = component.get('v.province'),
        dealerOrder = component.get('v.dealerOrder'),
        options = typeof( selectedOptions ) === 'undefined' ? null : selectedOptions,
        boat,
        checkForSelectedOpts = function( productOptions )
        {
          if( options !== null && Object.keys(options).length > 0 )
          {
            for( var productId in options )
            {
              productOptions.forEach( (optionGroup) => {
                optionGroup.values.forEach( (option) => {
                  if( productId === option.id )
                  {
                    if( options[productId].isCheckbox )
                      option.isSelected = true;
                    else
                      option.quantitySelected = options[productId].quantitySelected;
                    if(options[productId].subOptions !== undefined && options[productId].subOptions !== null )
                      option.subOptions = options[productId].subOptions;
                    console.log( "***OPTION***");
                    console.log(option);
                  }
                });
              });
            }
          }
          return productOptions;
        };

    return new Promise( function( resolve, reject ) {
      if( boatId === undefined || boatId === null )
        resolve();
      else
      {
        helper.fetchProduct( component, boatId, 'Boat' )
        .then(
          //fetchProduct SUCCESS
          $A.getCallback( function(response)
          {
            boat = JSON.parse(response);
            helper.functions.clearConfigVars( component );
            component.set('v.selectedBoat_Id', boatId );
            component.set( 'v.trailerSelectOptions', boat.trailerUpgrades );
            component.set( 'v.motorSelectOptions', boat.motorUpgrades );
            component.set( 'v.trollingMotorSelectOptions', boat.trollingMotorUpgrades );
            component.set( 'v.hasStandardTrailer', boat.standardTrailer_Id !== null );
            component.set( 'v.hasStandardMotor', boat.standardMotor_Id !== null );
            component.set( 'v.hasStandardTrollingMotor', boat.standardTrollingMotor_Id !== null );
            component.set( 'v.canvasDiscountAmount', boat.canvasDiscountAmount );

            var feeData = [],
                optProds = [],
                changeData;
            for( let fam of Object.keys( boat.optionalProducts) )
            {
              optProds.push({
                title: fam,
                values: boat.optionalProducts[fam]
              });
            }            //component.set( 'v.optionalProducts', optProds );
            component.set('v.optionalProducts', checkForSelectedOpts(optProds) );
            helper.checkForCanvasDiscount( component );
            if( boat.fees !== undefined &&
                boat.fees != null &&
                boat.fees[prov] !== undefined &&
                !dealerOrder.Is_Legend_Transfer__c )
            {
              feeData = feeData.concat( helper.handleFees( boat, prov ) );
            }

            changeData = {
              whatChanged: 'boat',
              changeData: {
                id: boat.id,
                name: boat.name,
                cost: boat.cost,
                fees: feeData
              }
            };
            return helper.handleConfigChange( component, changeData );
          }),
          //fetchProduct ERROR
          $A.getCallback( function(product_err) {
            console.log('fetch product error');
            console.log( product_err );
            reject(product_err);
          })
        )

        //handleConfigChange returned Promise
        .then(
          //handleConfigChange SUCCESS
          $A.getCallback( function() {
            helper.fireChangeEvent( component );
            component.set('v.productSelected', true);
            resolve( boat );
          })
        );
      }
    });

  },

  handleTrailer: function( component, trailerId )
  {
    var self = this,
        dealerOrder = component.get('v.dealerOrder'),
        changeData;
    return new Promise(function( resolve, reject )
    {
      if( trailerId == null ||trailerId == 'none' )
      {
        component.set( 'v.selectedTrailer_Id', 'none' );
        changeData = {
          whatChanged: 'trailer'
        };
        self.handleConfigChange( component, changeData )
        .then( function() {
          resolve();
        });
      }
      else
      {
        component.set( 'v.selectedTrailer_Id', trailerId );
        var trailerOptions = component.get('v.trailerSelectOptions'),
            prov = component.get('v.province'),
            trailerCost,
            trailerName = '',
            trailer,
            fees,
            feeData = [],
            trailerData;
        self.fetchProduct( component, trailerId, 'Trailer' )
        .then( function( response )
        {
          trailer = JSON.parse(response);
          component.set('v.productSelected', true);
          if( trailer.fees !== undefined &&
              trailer.fees !== null &&
              trailer.fees[prov] !== undefined &&
              !dealerOrder.Is_Legend_Transfer__c )
          {
            feeData = feeData.concat( self.handleFees( trailer, prov ) );
          }
          /*
          we want to get the cost of the trailer from the trailerSelectOptions
          as it may be an upgrade or a full cost trailer, this is the easiest way
          */
          for( var i=0; i<trailerOptions.length; i++ )
          {
            if( trailerOptions[i].id === trailer.id )
            {
              trailerCost = trailerOptions[i].cost;
              if( trailerOptions[i].isUpgrade == true )
                trailerName = 'Upgrade to ';
              trailerName += trailerOptions[i].name;
              break;
            }
          }
          changeData = {
            whatChanged: 'trailer',
            changeData: {
              id: trailer.id,
              name: trailerName,
              cost: trailerCost,
              fees: feeData
            }
          };
          self.handleConfigChange( component, changeData )
          .then( function() {
            resolve();
          });
        },
        function( err ) {
          reject(err);
        });
      }
    });
  },

  handleMotor: function( component, motorId, selectedMotorOptions )
  {
    var self = this,
        dealerOrder = component.get('v.dealerOrder'),
        isFactoryStore = component.get('v.isFactoryStore'),
        order_ProductRecordType = component.get('v.recordType'),
        selectedMotorOptions = typeof( selectedMotorOptions ) === 'undefined' ? null : selectedMotorOptions,
        changeData;
    return new Promise(function( resolve, reject )
    {
      if( motorId == null || motorId == 'none' )
      {
        component.set( 'v.selectedMotor_Id', 'none' );
        changeData = {
          whatChanged: 'motor'
        };
        self.handleConfigChange( component, changeData )
        .then( function() {
          resolve();
        });
      }
      else
      {
        component.set( 'v.selectedMotor_Id', motorId );
        var motorOptions = component.get('v.motorSelectOptions'),
            prov = component.get('v.province'),
            isMotorRequestOnly = component.get('v.isMotorRequest'),
            motorCost,
            motor,
            fees,
            feeData = [],
            motorData;
        self.fetchProduct( component, motorId, 'Motor' )
        .then( function( response )
        {
          motor = JSON.parse(response);
          component.set('v.productSelected', true);
          if( motor.fees !== undefined &&
              motor.fees !== null &&
              motor.fees[prov] !== undefined &&
              !dealerOrder.Is_Legend_Transfer__c &&
              !isMotorRequestOnly )
          {
            feeData = feeData.concat( self.handleFees( motor, prov ) );
          }
          /*
          if the dealer order is not record type of Motor then this is a package and
          save motor AND this is not a Legend Factory Store
          */
          if( isMotorRequestOnly || ( !isFactoryStore && order_ProductRecordType !== 'Motor' &&
               !dealerOrder.Is_Legend_Transfer__c  ) )
          {
            motorCost = null;
          }
          /*
          we want to get the cost of the motor from the motorSelectOptions
          as it may be an upgrade or a full cost motor, this is the easiest way
          */
          else
          {
            for( var i=0; i<motorOptions.length; i++ )
            {
              if( motorOptions[i].id === motor.id )
              {
                motorCost = motorOptions[i].cost;
                break;
              }
            }
          }

          if( typeof(motor.motorOptions) === 'undefined' )
            component.set('v.motorOptions', [] );
          else
          {
            if( selectedMotorOptions != null )
            {
              for( var mOpt of motor.motorOptions )
              {
                for( var selected_mOpt of selectedMotorOptions )
                {
                  if( selected_mOpt.id === mOpt.id )
                  {
                    mOpt.isSelected = true;
                  }
                }
              }
            }
            component.set('v.motorOptions', motor.motorOptions );
          }

          changeData = {
            whatChanged: 'motor',
            changeData: {
              id: motor.id,
              name: motor.name,
              cost: motorCost,
              fees: feeData
            }
          };
          if( isMotorRequestOnly )
            changeData.changeData.cost_description = 'Package and Save';

          self.handleConfigChange( component, changeData )
          .then( function() {
            resolve();
          });
        },
        function( err ) {
          reject(err);
        });
      }
    });
  },

  handleTrollingMotor: function( component, trollingMotorId )
  {
    var self = this,
        dealerOrder = component.get('v.dealerOrder'),
        changeData;
    return new Promise(function( resolve, reject )
    {
      if( trollingMotorId == null || trollingMotorId == 'none' )
      {
        component.set( 'v.selectedTrollingMotor_Id', 'none' );
        changeData = {
          whatChanged: 'trolling motor'
        };
        self.handleConfigChange( component, changeData )
        .then( function() {
          resolve();
        });
      }
      else
      {
        component.set( 'v.selectedTrollingMotor_Id', trollingMotorId );
        var trollingMotorOptions = component.get('v.trollingMotorSelectOptions'),
            prov = component.get('v.province'),
            trollingMotorCost,
            trollingMotor,
            fees,
            feeData = [],
            trollingMotorData;
        self.fetchProduct( component, trollingMotorId, 'Trolling Motor' )
        .then( function( response )
        {
          trollingMotor = JSON.parse(response);
          component.set('v.productSelected', true);
          if( trollingMotor.fees !== undefined &&
              trollingMotor.fees !== null &&
              trollingMotor.fees[prov] !== undefined &&
              !dealerOrder.Is_Legend_Transfer__c )
          {
            feeData = feeData.concat( self.handleFees( trollingMotor, prov ) );
          }
          /*
          we want to get the cost of the trailer from the trailerSelectOptions
          as it may be an upgrade or a full cost trailer, this is the easiest way
          */
          for( var i=0; i<trollingMotorOptions.length; i++ )
          {
            if( trollingMotorOptions[i].id === trollingMotor.id )
            {
              trollingMotorCost = trollingMotorOptions[i].cost;
              break;
            }
          }
          changeData = {
            whatChanged: 'trolling motor',
            changeData: {
              id: trollingMotor.id,
              name: trollingMotor.name,
              cost: trollingMotorCost,
              fees: feeData
            }
          };
          self.handleConfigChange( component, changeData )
          .then( function() {
            resolve();
          });
        },
        function( err ) {
          reject(err);
        });
      }
    });
  },

  handleFees: function( product, province )
  {
    var fees = product.fees[ province ],
        result = [],
        priceType = product.isPartner ? 'PartnerPrice' : 'FactoryPrice';
    for( var i=0; i<fees.length; i++ )
    {
      if( fees[i][priceType] !== null && fees[i][priceType] > 0 )
      {
        result.push({
          id: fees[i].Id,
          name: fees[i].Name,
          cost: fees[i][priceType]
        });
      }
    }
    return result;
  },

  handleConfigChange: function( component, params )
  {
    var self = this,
        handleFees = function( params )
        {
          var fees = component.get('v.fees'),
              newFees,
              allFeeList = [],
              newFeeList = [];

          /* if changeData does not exist the whatChanged product is
             being removed
          */
          if( params.changeData === undefined &&
              fees[params.whatChanged] !== undefined )
          {
            delete fees[params.whatChanged];
          }
          else if( params.changeData !== undefined &&
                   params.changeData.fees !== undefined )
          {
            newFees = params.changeData.fees;
            //remove existing fees for the product that changed
            if( fees[params.whatChanged] !== undefined )
              delete fees[params.whatChanged];

            for( var i=0; i<newFees.length; i++ )
            {
              newFeeList.push( newFees[i] );
            }
            fees[params.whatChanged] = newFeeList;
          }
          for( var key in fees )
          {
            Array.prototype.push.apply( allFeeList, fees[key] );
          }
          component.set('v.feeList', allFeeList);
          component.set('v.fees', fees);
        };

    return new Promise( function( resolve, reject ) {
      if( params.whatChanged === 'reset' )
        self.functions.clearConfigVars( component );

      if( params.whatChanged === 'boat' )
      {
        component.set('v.boat', params.changeData );
        handleFees( params );
      }

      if( params.whatChanged === 'trailer')
      {
        if( params.changeData !== undefined )
          component.set('v.trailer', params.changeData );
        else
          component.set('v.trailer', [] );

        handleFees( params );
      }

      if( params.whatChanged === 'motor')
      {
        if( params.changeData !== undefined )
          component.set('v.motor', params.changeData );
        else
        {
          component.set('v.motor', {} );
          var motorRequest = component.get('v.motorRequest')
          motorRequest.Motor__c = null;
          component.set('v.motorRequest', motorRequest);
        }

        handleFees( params );
      }

      if( params.whatChanged === 'trolling motor')
      {
        if( params.changeData !== undefined )
        {
          component.set('v.trollingMotor', params.changeData );
        }
        else
          component.set('v.trollingMotor', [] );
      }

      if( params.whatChanged === 'options' )
      {
        self.checkForCanvasDiscount( component );
      }

      resolve();
    });
  },

  motorIsPackageAndSave: function( component )
  {
    var motor = component.get('v.motor'),
        mOpts = component.get('v.motorSelectOptions'),
        result = false;
    for( var i=0; i<mOpts.length; i++ )
    {
      if( mOpts[i].id === motor.id )
      {
        result = mOpts[i].packageAndSave === 'true' ? true : false;
        break;
      }
    }
    return result;
  },

  checkForCanvasDiscount: function( component )
  {
    var canvasDiscountAmount = component.get('v.canvasDiscountAmount');

    if( canvasDiscountAmount !== null )
    {
      var discountName = '"We Have You Covered" Discount',
          discounts = component.get('v.discounts'),
          canvasOptions = [],
          optionalProducts = component.get('v.optionalProducts'),
          discountIndex,
          hasCanvasOptions;


      for( var i=0; i<discounts.length; i++ )
      {
        if( discounts[i].name === discountName )
        {
          discountIndex = i;
          break;
        }
      }

      for( let familyProducts of optionalProducts )
      {
        if( familyProducts.title === 'Canvas' )
        {
          for( let option of familyProducts.values )
          if( option.isSelected )
          {
            hasCanvasOptions = true;
          }
        }
      }


      if( hasCanvasOptions &&
          discountIndex === undefined )
      {
        discounts.push({
          name: discountName,
          amount: canvasDiscountAmount * -1
        });
      }
      else if( !hasCanvasOptions &&
               discountIndex !== undefined )
      {
        discounts.splice( discountIndex, 1 );
      }
      component.set('v.discounts', discounts);
    }
  },

  fireChangeEvent: function( component )
  {
    var configChangeEvt = $A.get('e.c:lgnd_BoatConfig_configChange_Event');

    configChangeEvt.setParams({
      boat: component.get('v.boat'),
      trailer: component.get('v.trailer'),
      motor: component.get('v.motor'),
      trollingMotor: component.get('v.trollingMotor'),
      options: component.get('v.optionalProducts'),
      motorOptions: component.get('v.motorOptions'),
      fees: component.get('v.fees'),
      feeList: component.get('v.feeList'),
      discounts: component.get('v.discounts')
    });
    configChangeEvt.fire();
  },

  functions: {

    clearVars: function( component )
    {
      component.set( 'v.recordType', '' );
      component.get( 'v.family', '' );
      component.set( 'v.productSelected', false);
      component.set( 'v.boatSelectOptions', [] );
      component.set( 'v.motorSelectOptions', [] );
      component.set( 'v.trollingMotorSelectOptions', [] );
      component.set( 'v.trailerSelectOptions', [] );
      component.set( 'v.hasStandardTrailer', false);
      component.set( 'v.hasStandardMotor', false);
      component.set( 'v.hasStandardTrollingMotor', false);
      component.set('v.optionalProducts', [] );
      component.set( 'v.selectedBoat_Id', '' );
      component.set( 'v.selectedTrailer_Id', '' );
      component.set( 'v.selectedMotor_Id', '');
      component.set( 'v.selectedTrollingMotor_Id', '');
      component.set( 'v.motorRequest', {'sobjectType': 'Dealer_Motor_Request__c',
                                         'Quantity__c': 0,
                                         'Motor__c': null});
      component.set('v.isMotorRequest', false);
      component.set( 'v.notes', '');
      component.set('v.quantity', 1);
      component.set('v.boat', {} );
      component.set('v.trailer', {} );
      component.set('v.motor', {} );
      component.set('v.trollingMotor', {} );
      component.set('v.options', {} );
      component.set('v.motorOptions', [] );
      component.set('v.discounts', []);
      // component.set('v.optionsList', [] );
      component.set('v.fees', {} );
      component.set('v.feeList', [] );
      component.set('v.orderGroupId', '' );
      component.set('v.promotionMessage', null);
      component.set('v.modelYear', '');
    },

    clearConfigVars: function( component )
    {
      component.set( 'v.notes', '');
      component.set('v.quantity', 1);
      component.set('v.boat', {} );
      component.set('v.trailer', {} );
      component.set('v.motor', {} );
      component.set('v.trollingMotor', {} );
      component.set('v.options', {} );
      component.set('v.motorOptions', [] );
      component.set( 'v.trollingMotorSelectOptions', [] );
      component.set( 'v.canvasOptions', [] );
      component.set(' v.buildOptions', [] );
      component.set('v.fees', {} );
      component.set('v.feeList', [] );
      component.set('v.discounts', []);
      component.set('v.isMotorRequest', false);
    },

    toggleSpinner: function( component, busy, message )
    {
      var indEvt = $A.get('e.c:lgndP_BusyIndicator_Event');
      indEvt.setParams(
        {
          isBusy: busy,
          message: message
        }
      ).fire();
    }
  }
})