(function($, document, window, undefined)
{
  window.CommissionCalculatorSfOne = function($container, templates, oppId, comRecordId, userProfile, userRole)
  {
    this.$container = $container;
    this.templates = templates;
    this.oppId = oppId;
    this.comRecordId = comRecordId;
    this.userDetails = {role: userRole, profile: userProfile };
    this.records = [];
    this.record = new CommissionRecord(comRecordId);
    this.Renderer = new Renderer(templates, $container);


    this.init = function()
    {
      var self = this;
      initHandlebarsHelpers.call(self);
      self.Renderer.loadIndicator('Retrieving Commission Records .....');
      self.record.initialize().then(
        function(r){
          console.log(r)
          self.Renderer.displayRecord(r);
          initEvents.call(self);
          /* REMOVE IF THIS EVER GETS FUNCTIONAL */
          LGND.alert('Warning!', 'This Page is not yet functional!  If you have found your way here please feel free to take a look around at the UI.  Nothing can be saved, it is just a proof of concept at the moment. If you have any ideas let me (Dave Hahn) know.');
        },
        function(failMessage) {
          LGND.alert('There was an error!', message);
        }
      );
    };

    function initHandlebarsHelpers()
    {
      var self = this;
      //Commission Record Line Item
      Handlebars.registerHelper( 'item', function(lineItem) {
        return new Handlebars.SafeString( self.templates.item( lineItem ) );
      });
      // An Attribute line for a Commission Line Item
      Handlebars.registerHelper( 'item_attr', function( label, v, type) {
        if( v === null || typeof v === 'undefined' ) return null;

        var valueString = type === 'currency' ? '$'+v :
                      type === 'percent' ? v+'%' :
                      v;
        return new Handlebars.SafeString( self.templates.item_attribute({ label: label, value: valueString}) );
      });
      // An editable Attribute line for a Commission Line Item
      Handlebars.registerHelper( 'editable_item_attr', function( label, form_label, v, type) {
        if( v === null || typeof v === 'undefined' ) return null;

        var valueString = type === 'currency' ? '$'+v :
                      type === 'percent' ? v+'%' :
                      v;
        return new Handlebars.SafeString( self.templates.editable_item_attribute({ label: label, f_label: form_label,value: valueString, f_value: v}) );
      });
      // Handlebars.registerHelper('stringifyFunc', function(fn) {
      //   return new Handlebars.SafeString("(" +
      //               fn.toString().replace(/\"/g,"'") + ")()");
      // });
    }

    function initEvents()
    {
      var self = this,
        hammertime,
        $content= $('#content') ;

      console.log( $('#main-container').width() );
      console.log( $(document).width() );
      console.log(  )

      //$('#main-container').height($(window).height() - 90 );

      $content.on('click', '.edit-item', function(e) {
        e.preventDefault();
        var item = self.record.findLineItem( $(this).data('item-id') );
        if( item )
        {
          item.toggleEdit();
          $('#content').toggleClass('editing-record');
        }
        else
        {
          console.log('counld not find Commission Line Items');
        }
      })
      .on('click', '.update-item', function(e) {
        e.preventDefault();
        alert('save the changes');
      });

      $('#header-nav-ctrl').on('click', function(e) {
        e.preventDefault();
       // $(this).toggleClass('open');
        $('#content').toggleClass('menu-open');
      });
      // $('#main-container').on('touchstart touchend', function(e) {
      //   console.log(e.type);
      //   switch( e.type ) {
      //     case 'touchstart':
      //       console.log('touch has started');
      //       $('#content').addClass('testClear');
      //       break;
      //     case 'touchend':
      //       console.log('touch has stopped');
      //       $('#content').removeClass('testClear');
      //       console.log(e)
      //       break;
      //     default:
      //       break;
      //   }
      // })
      // hammertime = new Hammer( document.getElementById('main-container'));
      // console.log(hammertime)
      // hammertime.on('swipeleft swiperight press', function(ev) {
      //   console.log('you ' + ev.type);
      //   alert( ev.type)
      // })

      $('.header-nav').on('click', 'ul > li > a', function(e) {
        e.preventDefault();
        var $link = $(this);
        $link.parent().siblings().removeClass('active');
        $link.parent().addClass('active');
        $('.page').removeClass('active');
        $($link.attr('href')).addClass('active');
        $('#header-nav-ctrl').click();
      })


    }

  }

  // function ComRecordService(){}

  // ComRecordService.prototype = {
  //   constructor: ComRecordService,
  //   fetchRecord: function(cRecId)
  //   {
  //     var dfd = new $.Deferred();
  //     CommissionCalculatorController.fetchRecords( cRecId, 'Id',  function(result, event){
  //       if( event.status )
  //       {
  //         dfd.resolve(result[0]);
  //       }
  //       else
  //       {
  //         message = event.message.indexOf('Logged in?') !== -1 ?
  //           ' Your session has expired.  Please refresh your browser and log in.' :
  //           event.message;
  //         dfd.reject(message);
  //       }
  //     });
  //     return dfd.promise();
  //   }
  // }

  function CommissionRecord(cRecId){
    this.Id = cRecId;
    this.lineItems = [];
    this.payments = [];
  }

  CommissionRecord.prototype = {
    constructor: CommissionRecord,
    initialize: function()
    {
      var dfd = new $.Deferred(),self = this;
      CommissionCalculatorController.fetchRecords( self.Id, 'Id',  function(result, event){
        if( event.status )
        {
          console.log( result[0] );
          $.each(result[0], function(k,v){
            if( k === 'CommissionLineItems__r' )
            {
              $.each( v, function(idx, item) {
                self.lineItems.push( new CommissionLineItem(item) )
              });
            }
            else if( k === 'CommissionPayments__r' )
            {
              $.each( v, function(idx, payment) {
                self.payments.push( new CommissionPayment(payment) )
              });
            }
            else
            {
              self[k] = v;
            }
          })
          dfd.resolve(self);
        }
        else
        {
          message = event.message.indexOf('Logged in?') !== -1 ?
            ' Your session has expired.  Please refresh your browser and log in.' :
            event.message;
          dfd.reject(message);
        }
      });
      return dfd.promise();
    },
    findLineItem: function(lineItemId)
    {
      var self = this,
        lineItem;
      $.each( self.lineItems, function(idx, item){
        if( lineItemId === item.Id )
        {
          lineItem = item;
        }
      });
      return lineItem;
    }
  }

  function CommissionLineItem(lineItem)
  {
    this.initialize(lineItem);
  }

  CommissionLineItem.prototype = {
    constructor: CommissionLineItem,
    initialize: function(li)
    {
      var self = this;
      $.each(li, function(k,v) {
        self[k] = v;
      });

    },
    toggleEdit: function()
    {
      $('#'+this.Id).toggleClass('is-editing');
    }

  }

  function CommissionPayment(payment)
  {
    this.initialize(payment);
  }

  CommissionPayment.prototype = {
    constructor: CommissionPayment,
    initialize: function(payment)
    {
      var self = this;
      $.each(payment, function(k,v) {
        self[k] = v;
      });

    },
    toggleEdit: function()
    {
      $('#'+this.Id).toggleClass('is-editing');
    }

  }

  function Renderer(templates, $container){
    this.$container = $container;
    this.templates = templates;
  }

  Renderer.prototype = {
    constructor: Renderer,
    loadIndicator: function(message)
    {
      this.$container.html( this.templates.indicator(message));
    },
    displayRecord: function(record)
    {
      this.$container.html( this.templates.record(record) );
    }

  }


})(jQuery.noConflict(), document, window);
