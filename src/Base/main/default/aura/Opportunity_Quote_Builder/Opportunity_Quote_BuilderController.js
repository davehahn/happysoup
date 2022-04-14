({
	doInit : function(component, event, helper)
  {
    console.log( 'builder INIT ');
    helper.doInit( component )
    .then(
      $A.getCallback( function() {} ),
      $A.getCallback( function( err ) {
         LightningUtils.errorToast( err );
      })
    );
	},

  onRender: function( component, event, helper )
  {
    var iframe = component.find('pdf-iframe'),
        btns = component.find('button-container'),
        ele;
    if( iframe !== null && iframe !== undefined )
    {
      ele = iframe.getElement();
      ele.classList.add('loading');
      $A.util.addClass( btns, 'loading' );
      if( !ele.getAttribute('data-event-loaded') )
      {
        ele.setAttribute('data-event-loaded', 'true');
        ele.addEventListener("load",
          $A.getCallback( function(){
            console.log('iframe loaded');
            ele.classList.remove('loading');
            $A.util.removeClass( btns, 'loading' );
          })
        );
      }
    }
  },

  quotesChanged: function( component, event, helper )
  {
    helper.setSelectedQuote( component, component.get('v.selectedQuoteId') );
  },

  toggleQuoteList: function( component, event, helper )
  {
    helper.toggleQuoteList( component );
  },

  toggleViewPdfPayments: function( component, event, helper )
  {
    component.set('v.showPaymentsOnPDF', !component.get('v.showPaymentsOnPDF'));
  },

  handleSelectedChanged: function( component, event, helper )
  {
    var qId = event.getParam('value'),
        btns = component.find('button-container'),
        quoteList = component.find('quote-list-container');
    $A.util.addClass( btns, 'loading' );
    helper.setSelectedQuote( component, qId );
    if( $A.util.hasClass( quoteList, 'open' ) )
    {
      helper.toggleQuoteList( component );
    }
  },

  doRefresh: function(component, event, helper)
  {
    $A.get('e.force:refreshView').fire();
  },

  handleNewQuote: function( component, event, helper )
  {
    component.set('v.creatingNewQuote', true);
    //component.set('v.selectedQuoteId', null);
    helper.loadCPQ( component );
  },

  handleQuoteSaved: function( component, event, helper )
  {
    var quoteId = event.getParam("quoteId"),
        quoteList = component.find('quote-list');
    helper.doInit( component )
    .then(
      $A.getCallback( function() {
        component.set('v.selectedQuoteId', quoteId );
        helper.doCancel( component );
      } ),
      $A.getCallback( function( err ) {
         LightningUtils.errorToast( err );
      })
    );

    //quoteList.reload();
  },

  handleEditQuote: function( component, event, helper )
  {
    helper.loadCPQ( component );
  },

  handleSyncQuote: function( component, event, helper )
  {
    var spinner = component.find('spinner');
    helper.confirm( component )
    .then(
      $A.getCallback( function() {
        spinner.toggle();
        component.set('v.showPDF', false);
        return helper.doSync( component );
      }),
      $A.getCallback( function() {
        spinner.toggle();
        return Promise.reject();
      })
    )
    .then(
      $A.getCallback( function( result ) {
        component.set('v.syncedQuoteId', result );
        component.set('v.selectedQuoteId', result);
        component.set('v.showPDF', true);
        $A.get('e.force:refreshView').fire();
      }),
      $A.getCallback( function( err ) {
        if( err !== undefined )
          LightningUtils.errorToast( err );
      })
    )
    .finally( $A.getCallback( function() {
      spinner.toggle();
    }))
  },

  handlePaymentChange: function( component, event, helper )
  {
    console.log('handlePaymentChange')
    var params = event.getParams(),
        quote = {},
        spinner = component.find('spinner'),
        quoteList = component.find('quote-list'),
        cpqLoaded = component.get('v.loadCPQ');
    if( params.recordId === undefined ||
        params.recordId === null ||
        cpqLoaded )
    {
      return;
    }
    quote.Id = params.recordId;
    quote.Deposit__c = params.deposit;
    quote.Finance_Ammortization__c = params.amort;
    quote.Finance_Annual_Interest__c = params.interestRate;
    quote.Finance_Term__c = params.term;
    spinner.toggle();
    component.set('v.showPDF', false);
    helper.updateQuote( component, JSON.stringify(quote) )
    .then(
      $A.getCallback( function(result) {
        quoteList.quoteUpdated( result );
        $A.get('e.force:refreshView').fire();
      }),
      $A.getCallback( function(err) {
        LightningUtils.errorToast(err);
      })
    )
    .finally( $A.getCallback( function() {
      component.set('v.showPDF', true);
      spinner.toggle();
    }))
  },

  cancelEditOrNew: function( component, event, helper )
  {
    helper.doCancel( component );
  }

  // handleQuoteCreated: function( component, event, helper )
  // {
  //   console.log( 'handleQuoteCreated' );
  //   var quoteId = event.getParam("quoteId");
  //   helper.doFetchQuotes( component )
  //   .then(
  //     $A.getCallback( function( result ) {
  //       component.set('v.quotes', result.quotes);
  //       component.set('v.selectedQuoteId', quoteId );
  //       component.set('v.creatingNewQuote', false);
  //     }),
  //     $A.getCallback( function( err ) {
  //       LightningUtils.errorToast( err );
  //     })
  //   );
  // }
})