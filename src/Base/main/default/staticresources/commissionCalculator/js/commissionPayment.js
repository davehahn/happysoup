(function($, window, document, undefined)
{

  CommissionCalc.CommissionPayments = {
    /*
    @paymentsRecords = object - {CommissionRecord__c.Id: {stage: CommissionRecord__c.Stage__c,
                                                          payment_records: CommissionRecord__c.CommissionPayments__r} }
   */

    init: function(paymentRecords)
    {
      var _super = this,
        self = _super.CommissionPayments;

      self.paymentRecords = paymentRecords;
      self.PaymentEditors = {};
      self._Super = _super;
      $.each( self._Super.comRecords, function(id, record) {
        self.PaymentEditors[id] = new PaymentEditor(id,
                                                    paymentRecords[id],
                                                    self.templates,
                                                    self._Super.spinnerURLs);
      });


      Handlebars.registerHelper('paymentRecordDetails', function( record ){
        return new Handlebars.SafeString( self.templates.payment_record_details({record: record, stage: self.paymentRecords[record.CommissionRecord__c].stage} ) );
      });

      Handlebars.registerHelper('commissionPercentageIndicator', function(record ){
        var htmlString = '';
        if( record.CommissionRecordType__c != 'Counter Sale' && record.Owner__r.Commission_Percentage__c !== 100 )
        {
          htmlString += '<i class="fa fa-asterisk has-tip tip-top radius" data-tooltip="true" '
          htmlString += 'title="'+record.Owner__r.Name+' receives ' +record.Owner__r.Commission_Percentage__c;
          htmlString += ' % of Commission Payment"></i>';
        }
        return new Handlebars.SafeString(htmlString);
      });

      Handlebars.registerHelper('payment_amount', function(record) {
        return new Handlebars.SafeString( self.templates.payment_amount(record) );
      });

      Handlebars.registerHelper('PaymentRecordEditCell', function( record ){
        return new Handlebars.SafeString( self.templates.payment_record_edit(record) );
      });

      $.each(paymentRecords, function(id, rcds) {
        if(rcds)
        {
          $('#'+id).find('.payments-view').html( self.templates.payment_records( {id: id, records: rcds.payment_records} ) );
        }
      });

      self.Handlers.init.call(self);
    },// /init

    commissionRecordIdFromPaymentId: function(paymentId)
    {
      var self = this,
        result;
      $.each(self.paymentRecords, function(commId, records) {
        if( !result )
        {
          for(var i=0; i<records.payment_records.length;i++){
            if(records.payment_records[i].Id === paymentId)
            {
              result = commId;
              break;
             }
          };
        }
      });
      return result;
    },// /commissionRecordIdFromPaymentId

    updateTotals: function(commissionRecordId, value)
    {
      var self = this,
        records;

      self.paymentRecords[commissionRecordId].commission_total = value;
      records = self.paymentRecords[commissionRecordId].payment_records;

      $.each(records, function(idx, record) {
        record.PaymentAmount__c = ( value *
                                    ( record.PaymentPercent__c / 100) *
                                    (record.Owner__r.Commission_Percentage__c /100)
                                  ).toFixed(2);
        //' .total_amount').html( '$ ' + record.PaymentAmount__c.toFixed(2) );
       $('#'+record.Id +' .slds-card__body').html( self.templates.payment_amount( record ) )
      });
    }, // /updateTotals

    Handlers: {

      init: function()
      {
        var self = this;
        self.Handlers.paymentReassignHandler.call(self);
        self.Handlers.splitHandler.call(self);
        //self.Handlers.stageHandler.call(self);
      },

      paymentReassignHandler: function()
      {
        var self = this;

        $('.payments-view').on('click', '.reassign', function(e) {
          e.preventDefault();
          var $this = $(this),
           paymentId = $this.data('payment-id'),
           comRecordId = self.commissionRecordIdFromPaymentId(paymentId),
           paymentEditor = self.PaymentEditors[comRecordId],
           $paymentBox = $this.closest('.payment-box'),
           $userSelectorContainer;

          if( !paymentEditor.UserSelector.isOpen )
          {
            $paymentBox.addClass('changingOwner');
            paymentEditor.reassignOwner( paymentId );
          }
        })

      },// /paymentReassignHandler

      splitHandler: function()
      {
        var self = this;

        $('.lgnd').on('click', '.split-payment', function(e){
          e.preventDefault();
          var $this = $(this),
              paymentEditor = self.PaymentEditors[ $this.data('commission-record-id') ];

          $this.toggleClass('editing');
          paymentEditor.isOpen ? paymentEditor.closeEditor() : paymentEditor.openEditor()
        });
      }, // /splitHandler

    }// /Handlers

  }// / CommissionCalc.CommissionPayments

})(jQuery.noConflict(), window, document)
