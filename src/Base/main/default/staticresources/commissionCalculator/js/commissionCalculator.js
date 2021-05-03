(function($, document, window) {

  window.CommissionCalc = {

  /*
    @oppId = the Id of the Opportunity we need to calculate the commission on
    @templates = object - name, handlebars compiled templates
       {'indicator', Handlebars.compile( $(ele).html() ) }
       make sure to compile templates before passing in
  */

  init: function(oppId,
                 comRecordId,
                 erpOrderId,
                 templates,
                 userId,
                 maxApprovalStage,
                 spinnerURLs,
                 permissions )
  {
    this.spinnerURLs = spinnerURLs;
    this.permissions = permissions;
    this.$pageSpinner = $('#lgnd-spinner');
    this.comRecords = {};
    this.oppId = oppId;
    this.comRecordId = comRecordId;
    this.erpOrderId = erpOrderId;
    this.userId = userId;
    this.maxApprovalStage = maxApprovalStage;
    //this.userProfileName = userProfile;
    //this.userRole = userRole;
    this.tempItemData = {};
    this.Items = {};
    this.recordId,
    this.$container = $('#content');
    this.$invoiceContainer = $('#invoice');
    this.$modalContainer = $('#modal');
    //this.$recreateRecordBtn = $('#recreateRecord');
    this.templates = templates.calc;
    this.CommissionPayments.templates = templates.payment;
    this.paymentsObject = {};
    this.stageMap = [
      'New',
      'Reviewed',
      'Approved',
      'Sales Accepted'
    ];

    var self = this;

    self.initHandlebarsHelpers.call(self);

    self.$container.html( self.templates.indicator('Retrieving Commission Record .....'));


    $.when( self.Model.fetchRecords.call(self) ).done( function(result) {
      if( result )
      {
        $.each( result, function( idx, record) {
          self.comRecords[record.Id] = record;
        });
        self.createItemObject.call(self, result);
        self.View.displayRecords.call(self, result);
      }
      else
      {
        self.View.setNoRecordsMessage.call(self, "You can only view your own Commission Records");
      }
    })
    .fail( function(message) {
       self.View.setFailedLoadingMessage(message);
    }) ;

    self.View.initNumberInputs.call(self);
    self.View.initDispute.call(self);

  }, // /init

  initHandlebarsHelpers: function()
  {
    var self = this;

    Handlebars.registerHelper('items-table', function( comRecord) {
      return new Handlebars.SafeString( self.templates.items_table(comRecord) );
    });

    Handlebars.registerHelper('status-path', function( comRecord ) {
      return new Handlebars.SafeString( self.templates.stage_path( {comRecord: comRecord, spinnerURL: self.spinnerURL} ) );
    });

    Handlebars.registerHelper('control-buttons', function( comRecord ) {
      return new Handlebars.SafeString( self.templates.control_buttons( comRecord ) );
    });

    Handlebars.registerHelper('dealLostClass', function( comrecords ) {
      return new Handlebars.SafeString( comrecords[0].isDealLost__c === true ? 'dealLost' : '');
    });

    Handlebars.registerHelper('status-link-class', function( recordStage, linkStage) {
      if( recordStage === linkStage )
      {
        return new Handlebars.SafeString( 'slds-is-current' );
      }
      if( self.stageMap.indexOf( linkStage ) > self.stageMap.indexOf( recordStage) )
      {
        return new Handlebars.SafeString( 'slds-is-incomplete' );
      }
      if( self.stageMap.indexOf( linkStage ) < self.stageMap.indexOf( recordStage) )
      {
        return new Handlebars.SafeString( 'slds-is-complete' );
      }
      return '';
    });

    Handlebars.registerHelper('split-commission-class', function( record ) {
      var result = 'hidden';
      if( record.Stage__c == 'Sales Accepted' )
        return result;
      if( self.permissions.canReview || self.permissions.canApprove )
        return '';
      for( let payment of record.CommissionPayments__r )
      {
        if( payment.Owner__c === self.userId )
        {
          result = '';
          break;
        }
      }
      return result;
    });

    Handlebars.registerHelper('contest-commission-class', function( record ) {
      console.log('dispute commission button class');
      console.log( record )
      var result = 'hidden';
      if( record.Is_Disputed__c )
      {
        if( self.permissions.canApprove )
          return 'in-dispute';
        else
          return result;
      }
      if( record.Stage__c != 'Approved' )
        return result;
      for( let payment of record.CommissionPayments__r )
      {
        if( payment.Owner__c === self.userId )
        {
          result = '';
          break;
        }
      }
      return result;
    });

    Handlebars.registerHelper('status-path-container-class', function( isDisputed ) {
      if( isDisputed )
        return new Handlebars.SafeString('in-dispute');
      return new Handlebars.SafeString('');
    });

    Handlebars.registerHelper('status-display-class', function( recordStage) {

      if( self.stageMap.indexOf( recordStage) > self.stageMap.indexOf( self.maxApprovalStage) )
      {
        return new Handlebars.SafeString('hidden')
      }
      return new Handlebars.SafeString('');
    });

    Handlebars.registerHelper('table_body', function( items ) {
      return new Handlebars.SafeString( self.templates.table_body( {lineItems: self.groupItems.call(self, items) } ) );
    });

    Handlebars.registerHelper('quantity_header', function( record ) {
      if( record.Type__c != 'Business Office')
      {
        return new Handlebars.SafeString( '<td class="w10">Quantity</td>' );
      }
      return null;
    });

    Handlebars.registerHelper('quantity_cell', function(item) {
      if( item.Department__c != "Business Office")
      {
        var s = '<td class="w10">';
        if( !item.CustomItem__c )
        {
          s += item.Quantity__c + ' x <span>$' + item.Retail_Price__c + ' ea.</span>';
        }
        s += '</td>';
        return new Handlebars.SafeString(s);
      }
      return null;
    });

    Handlebars.registerHelper('quantity_cell_new', function(item) {
      if( item.Department__c != "Business Office" )
      {
        return new Handlebars.SafeString('<td></td>');
      }
      return null;
    });

    Handlebars.registerHelper('quantity_footer', function( record ) {
      if( record.Type__c != 'Business Office')
      {
        return new Handlebars.SafeString( '<td></td>' );
      }
      return null;
    });

    Handlebars.registerHelper('tableRow', function( item ){
      return new Handlebars.SafeString( self.templates.row({ item: item } ) );
    });

    Handlebars.registerHelper('rowTypeClass', function( item ) {
      var klass = item.InsuranceItemId__c  || item.IsInsurance__c ? 'insurance-item' : 'oli-item';
      if( item.hasChanged__c === true )
      {
        klass += ' has-changed';
      }
      return new Handlebars.SafeString( klass );
    });

    Handlebars.registerHelper('ifEditable', function( recordStage, options ){
      if( self.stageMap.indexOf( recordStage) >= self.stageMap.indexOf( self.maxApprovalStage) )
      {
        return options.inverse(this);
      }
      return options.fn(this);
    });

    Handlebars.registerHelper('totalPrice', function( item )
    {
     if( item.Department__c.indexOf('Business') >= 0 )
     {
      return item.Retail_Price__c;
     }
      return item.Quantity__c * item.Sale_Price__c;
    });

  },// /initHandlebarsHelpers

  setupPayments: function(records)
  {
    var self = this,
      payments = {};

    $.each(records, function(idx, record) {
      self.paymentsObject[record.Id] = { 'payment_records': record.CommissionPayments__r,
                                         'stage': record.Stage__c,
                                         'commission_total': record.CommissionTotal__c};
    });
    self.CommissionPayments.init.call(self, self.paymentsObject);
  },// /setupPayemnts

  groupItems: function(items)
  {
    var self = this,
    result = {};
    result.first = [];
    result.second = [];
    result.third = [];
    if( items )
    {
      $.each(items, function(idx, item) {
        switch(item.CommissionRate__c)
        {
          case 1.75:
            result.first.push(item);
            break;
          case 10:
            result.second.push(item);
            break;
          default:
            result.third.push(item);
        }
      });
    }
    return result;
  },

  /*

  createItemObject:
    @records = array of CommissionRecord__c's returned from AJAX call tp apex controller
    sets Items property on CommissionCalc object {item.Id, item} from CommissionRecord__c.CommissionLineiTems__r
    makes it easy to retrieve item information from Items objects

  */
  createItemObject: function(records)
  {
    var self = this;
    self.Items = {};
    $.each(records, function(idx, record){
      if(record.CommissionLineItems__r)
      {
        $.each( record.CommissionLineItems__r, function( idx, item) {
          self.Items[item.Id] = item;
        });
      }
    });
  }, // /createItemObject

  Model: {

    fetchRecords: function()
    {
      var self = this,
        wrapper,
        recordId,
        queryIdField,
        dfd = new $.Deferred();
      if( self.oppId )
      {
        recordId = self.oppId;
        queryIdField = 'OpportunityId__c';
      }
      else if( self.comRecordId )
      {
        recordId = self.comRecordId;
        queryIdField = 'Id';
      }
      else if( self.erpOrderId )
      {
        recordId = self.erpOrderId;
        queryIdField = 'ERP_Order__c'
      }
      if( recordId && queryIdField )
      {
        CommissionCalculatorController.fetchRecords( recordId, queryIdField, function(result, event) {
          if( event.status )
          {
            if(result === null || result.length === 0)
            {
              dfd.resolve(null);
            }
            else
            {
              dfd.resolve(result);
            }
         }
         else
          {
           dfd.reject(event.message);
          }
        });
      }
      else
      {
        dfd.reject('Invalid Id or query field specified.');
      }
      return dfd.promise();
    },// /fetchRecord


    createRecords: function()
    {
      var self = this,
          dfd = new $.Deferred();

      CommissionCalculatorController.createRecords( self.oppId, function(result, event) {
        if( event.status )
        {
          if(result === null || result.length === 0)
          {
            dfd.resolve(null);
          }
          else
          {
            dfd.resolve(result);
          }
       }
       else
        {
         dfd.reject(event.message);
        }
      });
      return dfd.promise();
    }, // createRecords

    updateItem: function(data)
    {
      var dfd = new $.Deferred(),
        message;
      CommissionCalculatorController.updateItem( JSON.stringify(data), function(result, event) {
        if( event.status )
        {
          dfd.resolve(result);
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

    setDisputed: function( comRecordId, message )
    {
      var self = this,
          dfd = new $.Deferred();
      self.View.togglePageSpinner.call(self);
      CommissionCalculatorController.setDisputed( comRecordId, message, function(result, event) {
        self.View.togglePageSpinner.call(self);
        if( event.status )
        {
          dfd.resolve(result);
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

    resolveDispute: function( comRecordId )
    {
      var self = this,
          dfd = new $.Deferred();
      self.View.togglePageSpinner.call(self);
      CommissionCalculatorController.resolveDisputed( comRecordId, function(result, event) {
        self.View.togglePageSpinner.call(self);
        if( event.status )
        {
          dfd.resolve(result);
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

    deleteItem: function(itemId)
    {
      var self = this,
        message,
        dfd = new $.Deferred();

      CommissionCalculatorController.deleteCommissionLineItem( itemId, function(result, event){
        if( event.status )
        {
          dfd.resolve(result);
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

    fetchInvoice: function( parentRecordId )
    {
      var self = this,
        message,
        dfd = new $.Deferred();

      CommissionCalculatorController.fetchInvoice( parentRecordId, function(result, event){
        if( event.status )
        {
          dfd.resolve(result);
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
    }

  },// /Model

  View: {

    togglePageSpinner: function()
    {
      this.$pageSpinner.toggleClass('hidden');
    },

    initNumberInputs: function()
    {
      var isNumberKey = function(evt)
        {
          var charCode = (evt.which) ? evt.which : evt.keyCode;
          if (charCode != 46 && charCode > 31
            && (charCode < 48 || charCode > 57) //keyboardnumbers
             && charCode != 189
             && charCode != 109
             && charCode != 37 //left key
             && charCode != 39 //right key
             && charCode != 190 // period
             && charCode != 110 //numberpad decimal
             && (charCode > 105 || charCode < 96) ) //numberpad numbers
             return false;

          return true;
        };

      $(document).on('keydown', '.number_only', function(e) {
        if( !isNumberKey(e) )
        {
          e.preventDefault();
        }
      });
    },

    initDispute: function()
    {
      var self = this;
      $('.lgnd').on('click', '.dispute-commission', function(e) {
        e.preventDefault();
        var $this = $(this),
            recordId = $this.data('commission-record-id'),
            comRecord = self.comRecords[recordId];
        if( comRecord.Is_Disputed__c )
        {
          $.when( self.Model.resolveDispute.call( self, recordId ) )
          .done( function( comRecord ) {
            self.View.reloadChatter.call( self, comRecord.Id );
            self.View.Table.reloadTable.call( self, comRecord );
            self.View.ControlBtns.reload.call( self, comRecord );
            self.comRecords[comRecord.Id] = comRecord;
            self.statusPaths[comRecord.Id].reInit(comRecord);
          })
          .fail( function ( err ) {
            LGND.alert('There was an error', err);
          });
        }
        else
        {
          self.View.DisputeModal.init.call( self, recordId );
        }
      });
    },

    setLoadingMessage: function(message)
    {
      $('#indicator .indicator_message').html(message);
    },

    setFailedLoadingMessage: function(message)
    {
      $('#indicator').addClass('error').find('.indicator_message').html(message);
    },

    setNoRecordsMessage: function(message)
    {
      var self = this,
          $link;
      $('#indicator').addClass('no-records').find('.indicator_message').html(message)
      .siblings('.sk-no-records')
      .find('a')
      .on('click', function(e){
        e.preventDefault();
        $link = $(this);

        if( $link.attr('href') === 'cancel' )
        {
          window.location.assign("/"+self.oppId);
        }
        if( $link.attr('href') === 'create' )
        {
          $('#indicator').removeClass('no-records').find('.indicator_message').html('Creating Commission Records ...')
          $.when( self.Model.createRecords.call(self) ).done( function(result) {
            if( result )
            {
              self.createItemObject.call(self, result);
              self.View.displayRecords.call(self, result);
            }
            else
            {
              self.View.setFailedMessage("Something is pretty strange");
            }
          })
          .fail( function(message) {
             self.View.setFailedLoadingMessage(message);
          }) ;
        }
      });
    },

    displayRecords: function(records, tabIndex )
    {
      var self = this
       tabIndex = typeof(tabIndex) === 'undefined' ? 0 : tabIndex,
       parentRecordId = records[0].ERP_Order__c ? records[0].ERP_Order__c :
        records[0].OpportunityId__c ? records[0].OpportunityId__c : null;

      self.$container.html( self.templates.records({records: records}) );
      self.View.displayInvoice.call(self, parentRecordId);
      self.setupPayments.call(self, records);

      $('[data-aljs="tabs"]').tabs({
        defaultTabId: '',
        tabItemClass: '.outer-tab-item',
        tabLinkClass: '.outer-tab-link',
        tabContentClass: '.outer-tab-content',
        onChange: function(obj) {
        }
      });
      $('[data-aljs="inner-tabs"]').each( function( idx, ele) {
        var $ele = $(ele);
        $(ele).tabs({
          defaultTabId: '',
          tabItemClass: '.inner-tab-item' + $ele.data('uniquifier'),
          tabLinkClass: '.inner-tab-link' + $ele.data('uniquifier'),
          tabContentClass: '.inner-tab-content' + $ele.data('uniquifier'),
          onChange: function(obj) {}
        });
      });

      self.View.Table.init.call(self);
      self.View.StatusPath.init.call(self);
    },

    displayInvoice: function( parentRecordId )
    {
      var self = this,
          $invoiceContainer = $('#invoice');

      $invoiceContainer.html( self.templates.indicator('Retrieving Invoice for ' + parentRecordId + ' .....'));
      self.Model.fetchInvoice( parentRecordId )
      .then( function( url ) {
        if( url != null )
        {
          $('a[data-aljs-show="invoice"]').parent().removeClass('slds-hide');
          $invoiceContainer.html( self.templates.invoice( url ) );
        }
      })
    },

    reloadChatter: function(recordId)
    {
       $( '#'+recordId+'_feed' ).find('iframe').attr( 'src', function ( i, val ) { return val; });
    },

    DisputeModal: {

      init: function( recordId )
      {
        var self = this, editor;
        self.$modalContainer.html( self.templates.dispute_modal({recordId: recordId}) );
        //editor = CKEDITOR.replace( 'dispute-reason' );
        self.View.DisputeModal.initHandlers.call(self);
      },

      initHandlers: function()
      {
        var self = this;
        //buttons
        self.$modalContainer.find('button').on('click', function(e){
          e.preventDefault();
          var action = $(this).data('btn-action');
          if( action === 'cancel' )
          {
            self.$modalContainer.empty();
          }
          if( action === 'save' )
          {
            var $message = $('#dispute-reason'),
                $modal = $message.closest('div[role="dialog"]');
            $modal.addClass('hidden');
            $.when( self.Model.setDisputed.call( self,
                                                 $(this).data('record-id'),
                                                  $message.val() ) )
            .done( function( record ) {
              self.View.DisputeModal.handleDisputeSuccess.call( self, record );
            })
            .fail( function( err ) {
              self.View.DisputeModal.handleDisputeFail.call( self, err, $modal );
            })
          }
        });
        //textarea
        $('#dispute-reason').on('change keyup paste', function(e) {
          e.preventDefault();
          var saveBtn = self.$modalContainer.find( 'button[data-btn-action="save"]' );
          if( $.trim($(this).val()).length === 0 )
          {
            saveBtn.attr('disabled', true);
          }
          else
          {
            saveBtn.removeAttr('disabled');
          }
        })
        // editor.on('change', function(e) {
        //   //e.preventDefault();
        //   var saveBtn = self.$modalContainer.find( 'button[data-btn-action="save"]' );
        //   if( e.editor.getData().length === 0 )
        //   {
        //     saveBtn.attr('disabled', true);
        //   }
        //   else
        //   {
        //     saveBtn.removeAttr('disabled');
        //   }
        // })
      },

      handleDisputeSuccess: function( comRecord )
      {
        var self = this;
        self.$modalContainer.empty();
        self.View.reloadChatter.call( self, comRecord.Id );
        self.View.Table.reloadTable.call( self, comRecord );
        self.View.ControlBtns.reload.call( self, comRecord );
        self.comRecords[comRecord.Id] = comRecord;
        self.statusPaths[comRecord.Id].reInit(comRecord);
      },

      handleDisputeFail: function( err, $modal )
      {
        LGND.alert('There was an error', err);
        $modal.removeClass('hidden');
      }
    },

    Table: {

      init: function()
      {
        var self = this;
        self.View.Table.$tables = $('.commissionTable');
        self.View.Table.sumAllColumns.call(self);
        self.View.Table.initClickEvents.call(self);

      },// /init

      reloadTable: function( comRecord )
      {
        var self = this,
            $tableContainer = $('#'+comRecord.Id).find('.items-table-container');
        //re-display the table so if Stage__c = Complete it is no loger editable
        $tableContainer.html( self.templates.items_table( comRecord ) );
        // sum the totals of the table and display them in the footer
        self.View.Table.sumColumnsInTable.call(self, $tableContainer.find('table') );
      },

      sumAllColumns: function()
      {
        var self = this;
        self.View.Table.$tables.each( function(idx, ele) {
          self.View.Table.sumColumnsInTable.call(self, $(ele) );
        });
      },// /sumAllColumns

      sumColumnsInTable: function($table)
      {
        var self = this,
          $bodyRows = $table.find('tbody tr'),
          $footerRow = $table.find('tfoot tr:first'),
          totals = {},
          comRecordId = $table.data('record-id'),
          $cellsWithTotals = $table.find('thead td.hasTotal');

        $.each($cellsWithTotals, function(inx,ele) {
           totals[ $(ele).index() ] = {};
          totals[ $(ele).index() ].oli = 0;
          totals[ $(ele).index() ].ili = 0;
          totals[ $(ele).index() ].total = 0;
        });

        $.each($bodyRows, function(idx, ele){
          var $row = $(ele);
          $.each( totals, function(idx, value){
            if( $row.hasClass('insurance-item') )
            {
              totals[idx].ili += Number( $row.find('td').eq(idx).html().replace(/[^0-9\-.]+/g,"") );
            }
            if( $row.hasClass('oli-item') )
            {
              totals[idx].oli += Number( $row.find('td').eq(idx).html().replace(/[^0-9\-.]+/g,"") );
            }
             totals[idx].total += Number( $row.find('td').eq(idx).html().replace(/[^0-9\-.]+/g,"") );
          });
        });

        $.each(totals, function(idx, values){
          var $cell = $footerRow.find('td').eq(idx),
            $cellhtml = $('<span></span>');
          if( values.ili > 0 )
          {
            $cellhtml.append( $('<div></div>').addClass('oli-total').html('$ ' + values.oli.toFixed(2) ) );
            $cellhtml.append( $('<div></div>').addClass('ili-total').html('$ ' + values.ili.toFixed(2) ) );
          }
          $cellhtml.append( $('<div></div>').addClass('total').html('$ ' + values.total.toFixed(2) ) );
          $cell.html( $cellhtml );
          // $cell.html('$ ' + value.toFixed(2) );
          if( $cell.data('total') && comRecordId )
          {
            self.CommissionPayments.updateTotals.call( self.CommissionPayments,
                                                       comRecordId,
                                                       values.total.toFixed(2) );
          }
        });
      }, // /sumColumnsInTable

      initClickEvents: function()
      {
        var self = this,
            $table,
            $indicator = $('<span class="indicator"></span>').append( $('<img></img>').attr('src', self.spinnerURLs.gray) );
        self.View.Table.$tables.each( function(idx, ele){
          $table = $(ele);
          // Edit button click handler
          $table.parent().on('click', 'a.editItem', function(e) {
            e.preventDefault();
            var $this = $(this),
              iId = $this.data('id'),
              $row = $this.closest('tr');

            $this.addClass('busy');
            $row.replaceWith( self.templates.edit_row( self.Items[iId]) );
            self.View.Table.initPercentageCurrencyInputs.call(self, $('#'+iId), self.Items[iId].CommissionableAmount__c);
          })
          //cancel edit click handler
          .on('click', 'a.cancelEdit', function(e){
            e.preventDefault();
            var $this = $(this),
              $row = $this.closest('tr'),
              itemId = $this.data('id');

            $row.replaceWith( self.templates.row( {item: self.Items[itemId]} ) );
          })
          //update button click handler
          .on('click', 'a.updateItem', function(e){
            e.preventDefault();
            var $this = $(this),
              $row = $this.closest('tr'),
              $table =$row.closest('table'),
              data = {},
              itemId = $this.data('id'),
              $button = $this.closest('.slds-dropdown').siblings('button'),
              item;

            data['Id'] = itemId;
            $this.addClass('busy');
            $button.html( $indicator );
            $row.find('input').each( function( idx, ele) {
              data[ $(ele).data('field-name') ] = $(ele).val();
            });
            $.when( self.Model.updateItem.call(self, data) )
            .done( function(result) {
              item = self.Items[result.Id];
              if( result.Description__c )
              {
                item.Description__c = result.Description__c;
              }
              if( result.CommissionableAmount__c )
              {
                item.CommissionableAmount__c = result.CommissionableAmount__c;
              }
              item.AppliedCommissionRate__c = result.AppliedCommissionRate__c;
              item.AppliedCommissionAmount__c = result.AppliedCommissionAmount__c;
              $row.replaceWith( self.templates.row( {item: item} ) );
              $table.data('record-id', item.CommissionRecord__c );
              self.View.Table.sumColumnsInTable.call(self, $table );
              self.View.reloadChatter( item.CommissionRecord__c);
            })
            .fail( function(message) {
              LGND.alert('There was an error!', message);
              $row.replaceWith( self.templates.row( self.Items[itemId] ) );
            })
          })
          // add item click handler
          .on('click', '.newItem', function(e) {
            e.preventDefault();
            var $this = $(this);
            $this.closest('tfoot').prev().append( self.templates.new_row( $this.data('record') ) );
          })
          //create item click handler
          .on('click', 'a.createItem', function(e) {
            e.preventDefault();
            var $this = $(this),
              $row = $this.closest('tr'),
              $button = $this.closest('.slds-dropdown').siblings('button'),
              $table = $row.closest('table'),
              data = {};

            $this.addClass('busy');
            $button.html( $indicator );
            $row.find('input')
            .each( function(idx, ele){
              data[$(ele).data('field-name')] = $(ele).val();
            });
            //data['Opportunity__c'] = self.oppId;
            data['EditCommissionableAmount__c'] = true;
            $.when( self.Model.updateItem.call(self, data) )
            .done( function(result) {
              self.Items[result.Id] = result;
              $row.replaceWith( self.templates.row( {item: result} ) );
              $table.data('record-id', result.CommissionRecord__c );
              self.View.Table.sumColumnsInTable.call(self, $table );
              self.View.reloadChatter( result.CommissionRecord__c);
            })
            .fail( function(message){
              LGND.alert('There was an error!', message);
            })
          })
          //cancel new item click handler
          .on('click', 'a.cancelNewItem', function(e) {
            e.preventDefault();
            $(this).closest('tr').remove();
          })
          // delete custom item click handler
          .on('click', 'a.removeItem', function(e) {
            e.preventDefault();
            var $this = $(this),
              $table = $this.closest('table'),
              $button = $this.closest('.slds-dropdown').siblings('button'),
              itemId = $this.data('id');


            $.when( LGND.confirm('Confirm Delete', 'Are you sure you want to permenantly delete this item?') )
            .done( function(response)
            {
              if(response)
              {
                $this.addClass('busy');
                $button.html( $indicator );
                $.when( self.Model.deleteItem.call( self, itemId ) )
                .done( function (result) {
                  var recordId = self.Items[itemId].CommissionRecord__c;
                  $this.closest('tr').remove();
                  $table.data('record-id', recordId );
                  delete self.Items[itemId];
                  self.View.Table.sumColumnsInTable.call(self, $table );
                  self.View.reloadChatter( recordId);
                })
                .fail( function(message) {
                  $this.removeClass('busy');
                  LGND.alert('There was an Error', message);
                });
              }
            });

          })
          // new commission line item Commissionable Amount Input
          .on('keyup', '.customItemAmount', function(e) {
            var $this = $(this),
              $row = $this.closest('tr');

            if( $this.val().length > 0 )
            {
              $row.find('input[disabled="disabled"]').removeAttr('disabled');
              self.View.Table.initPercentageCurrencyInputs.call(self, $row, $this.val() );
              $row.find('input[data-field-name="AppliedCommissionRate__c"]').trigger('keyup');
            }
            else
            {
              $row.find('input.cp_linked').attr('disabled', 'disabled');
            }
          })
          //trigger handler for form row validation
          .on('formRowInputChanged', 'tr.validatable', function() {
            var $this = $(this),
              valid = true;

            $this.find('input.required').each( function(idx, ele) {
              if( $(ele).val().length == 0 )
              {
                valid = false;
              }
            });
            valid ? $this.removeClass('invalid') : $this.addClass('invalid');
          })
          //trigger handler on all required form field to check if form valid
          .on('keyup', 'input.required', function() {
            $(this).closest('tr').trigger('formRowInputChanged');
          })

        });
      },

      initPercentageCurrencyInputs: function($row, price)
      {
        var self = this,
          $inputs = $row.find('input.cp_linked'),
          inputsMap = {},
          handleAmountChange = function($input)
          {
            var v = $input.val(),
              calcVal,
              typ;
            if( $input.data('field-type') === 'percentage' )
            {
              typ = 'currency';
              calcVal = ( price * ( v / 100) );
            }
            if( $input.data('field-type') === 'currency' )
            {
              typ = 'percentage';
              calcVal = price === 0 ? 100 : (v / price) * 100;
            }
            inputsMap[typ].val(calcVal.toFixed(2));
          };
          // handleCurrency = function($input)
          // {
          //   var v = $input.val();
          // }

        $inputs.each(function(idx,ele) {
          var $this = $(ele);
          inputsMap[ $this.data('field-type') ] = $this;
        })
        .off('keyup')
        .on({
          keyup: function(e) {
            handleAmountChange( $(this) );
          }
        });

      }

    },// /Table

    StatusPath: {

      init: function()
      {
        var self = this;
        self.statusPaths = {};

        $.each( self.comRecords, function(id, record) {
          self.statusPaths[id] = new StatusPath(record, self.templates.stage_path, self.spinnerURLs);
        });
        self.View.StatusPath.addListeners.call(self);


        // self.$statusPath = $('.status-path');
        // self.View.StatusPath.statusHandler.call( self );
      },

      addListeners: function()
      {
        var self = this;
        $.each( self.statusPaths, function( comRecordId, sp) {
          sp.$statusPathContainer.on('status-changed', function(e) {
            self.View.StatusPath.handleStatusChange.call(self, e.originalEvent.detail.comRecord );
          });
        });
      },

      handleStatusChange: function( comRecord )
      {
        var self = this;

        $.each( comRecord.CommissionLineItems__r, function( idx, li ) {
          self.Items[li.Id] = li;
        });

        var self = this,
            $editPaymentsBtn = $('.split-payment[data-commission-record-id="' + comRecord.Id + '"]'),
            $disputeBtn = $('.dispute-commission[data-commission-record-id="' + comRecord.Id + '"]'),
            $onwerReassignControls = $('#'+comRecord.Id +' .payments-view .slds-dropdown-trigger');
        self.comRecords[comRecord.Id] = comRecord;
        self.View.Table.reloadTable.call( self, comRecord );
        self.View.ControlBtns.reload.call( self, comRecord );

        //hide show the dispute/split/re-assign buttons
        if( comRecord.Stage__c === 'Approved' )
        {
          // for( let payment of comRecord.CommissionPayments__r )
          // {
          //   if( self.userId === payment.Owner__c )
          //   {
          //     $disputeBtn.removeClass('hidden');
          //     break;
          //   }
          // }
          // $editPaymentsBtn.removeClass('hidden');
          $onwerReassignControls.removeClass('hidden');
        }
        else
        {
          // $disputeBtn.addClass('hidden');
          // $editPaymentsBtn.addClass('hidden');
          $onwerReassignControls.addClass('hidden');
        }
        //reload the feed
        self.View.reloadChatter.call(self, comRecord.Id);

      }

    },// /StatusPath

    ControlBtns: {

      reload: function( comRecord )
      {
        var self = this,
            $btnContainer = $('#'+comRecord.Id+'_details').find('.control-buttons');
        $btnContainer.empty().html( self.templates.control_buttons( comRecord ) );
      }
    }

  }// /View

}// CommissionCalc

})(jQuery, document, window, undefined);
