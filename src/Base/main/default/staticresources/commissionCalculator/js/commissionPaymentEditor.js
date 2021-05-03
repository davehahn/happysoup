(function($, document, window, undefined) {

  var PaymentEditor = (function() {

    /* paymentRecords = {
      payment_records: 'actual payment records for the commission record (CommissionPayments__r)',
      stage: 'commission record stage',
      commission_total: 'commission record total'
    }
    */
    //constructor
    function PaymentEditor(commRecordId, paymentRecords, templates, spinners)
    {
      this.commRecordId = commRecordId;
      this.PaymentRecords = paymentRecords;
      this.templates = templates;
      this.spinners = spinners;
      this.$editorContainer = $('#' + commRecordId).find('.payments-editor');
      this.UserSelector = new UserSelector(this);
      this.isOpen = false;
      this.payeeIds;
      this.paymentReassignId = null;
      this.totalPercentage = 0;
      _init.call(this);

    }

    function _init()
    {
      var self = this;
      _determineTotalPercentage.call(self);
      _setPayees.call(self);
      self.UserSelector.$selectContainer
      .on('new-owner-selected', function(e) {
        _handleNewOwner.call( self, e.originalEvent.detail.userId );
      })
      .on('selector-closed', function() {
        self.paymentReassignId = null;
      });
    }

    function _setPayees()
    {
      var self = this;
      self.payeeIds = [];
      $.each(self.PaymentRecords, function(idx, rec) {
        self.payeeIds.push( rec.Owner__c );
      });
    }

    function _handleNewOwner( userId )
    {
      var self = this,
          data = {
            Owner__c: userId,
            Id: self.paymentReassignId
          };
      _updatePayment.call( self, data )
      .then( function( result ) {
        $('#' + result.Id).replaceWith( self.templates.payment_record_details( { record: result } ) )
        $(document).foundation();
        this.paymentReassignId = null;
        self.UserSelector.closeSelector();
      })
      .fail( function( message ) {
        LGND.alert('There was an error', message);
      })
    }

    function _determineTotalPercentage()
    {
      var self = this;
      for( var i=0; i < self.PaymentRecords.payment_records.length; i++ )
      {
        self.totalPercentage += self.PaymentRecords.payment_records[i].PaymentPercent__c;
      }
    }

    function _enableActionButtons()
    {
      var self = this;

      self.$editorContainer.find('button')
      .on('click', function(e) {
        e.preventDefault();
        var $this = $(this), action = $this.data('action');
        if( action === 'add-payment')
        {
          _handleAddPayment.call(self);
          return false;
        }
        if( action === 'save-payments' )
        {
          $this.html(
            $('<span class="indicator"></span>').append( $('<img></img>').attr('src', self.spinners.brand) )
          );
          _handleSavePayments.call(self);
        }
      });
    }

    function _enablePaymentAmountAdjustment()
    {
      var self = this;
      self.$editorContainer.on('click', '.percent-input a', function(e) {
        e.preventDefault();
        _handlePaymentPercentageAdjustment.call(self, $(this) );
      });
    }

    function _handlePaymentPercentageAdjustment( $btn )
    {
      var self = this,
          incAmount = 1,
          $saveBtn = self.$editorContainer.find('button[data-action="save-payments"]');
          $paymentCard = $btn.closest('.slds-card'),
          $percentContainer = $btn.closest('.percent-input'),
          paymentId = $paymentCard.data('payment-record-id'),
          userPercentage = $paymentCard.data('owner-commission-percent'),
          $input = $percentContainer.find('input'),
          $amount = $percentContainer.prev('.total_amount').find('span'),
          percent = parseFloat( $input.val() ),
          btnAction = $btn.data('action'),
          update = function()
          {
            var amount = (self.PaymentRecords.commission_total * (percent/100) * (userPercentage/100) ).toFixed(2);
            $amount.html( '$ ' + amount);
            $input.val( percent );
            self.totalPercentage === 100 ?
              $saveBtn.removeAttr('disabled') :
              $saveBtn.attr('disabled', 'true');
          };

      if( btnAction === 'increase' )
      {
        if( percent < 100 && self.totalPercentage < 100)
        {
          self.totalPercentage += incAmount;
          percent += incAmount;
        }
      }
      if( btnAction === 'decrease' )
      {
        if( percent > 0 && self.totalPercentage > 0)
        {
          self.totalPercentage -= incAmount;
          percent -= incAmount;
        }
      }
      update();
    }

    function _handleAddPayment()
    {
      var self = this;
      self.addingPayment = true;
      self.UserSelector.openSelector();
    }

    function _handleSavePayments()
    {
      var self = this,
          data = {},
          arrayData = [];
      if( self.totalPercentage === 100 )
      {
        self.$editorContainer.find('.slds-card').each( function( idx, ele ) {
          $(ele).find('input').each( function(index, input) {
            data[$(input).data('attribute-name')] = $(input).val();
          });
          arrayData.push(data);
          data = {};
        });
        _savePaymentRecords.call(self, arrayData)
        .done( function( result) {
          self.PaymentRecords.payment_records = result;
          $('#'+ self.commRecordId).find('.payments-view')
          .html( self.templates.payment_records( { id: self.commRecordId, records: result} ) );
          self.closeEditor();
        })
        .fail( function( message ) {
          LGND.alert('There was an error', message);
        })
        return false;
      }
      return false;
    }

    function _savePaymentRecords( arrayData )
    {
      var self = this,
          dfd = new $.Deferred();

      CommissionCalculatorController.updatePaymentRecords( JSON.stringify( arrayData ), function(result, event){
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

    function _updatePayment( data )
    {
      var self = this,
          dfd = new $.Deferred();

      CommissionCalculatorController.updatePaymentRecord( JSON.stringify( data ), function(result, event){
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

    PaymentEditor.prototype = {

      openEditor: function()
      {
        var data = {
          CommissionRecordId: this.commRecordId,
          records: this.PaymentRecords.payment_records
        };
        this.isOpen = true;
        this.$editorContainer.siblings('.payments-view').hide();
        this.$editorContainer.html( this.templates.payment_record_editor( data) ).addClass('editing');
        _enableActionButtons.call(this);
        _enablePaymentAmountAdjustment.call(this);
        if( this.PaymentRecords.payment_records.length === 1 )
          this.UserSelector.openSelector();
      },

      closeEditor: function()
      {
        this.$editorContainer.removeClass('editing')
        .off('click')
        .children().remove();
        this.$editorContainer.siblings('.payments-view').show()
        .siblings('.status-path-container')
        .find('.split-payment').removeClass( 'editing' );
        this.isOpen = false;
        if( this.UserSelector.isOpen )
          this.UserSelector.closeSelector();
      },

      reassignOwner: function( paymentId )
      {
        this.paymentReassignId = paymentId;
        this.UserSelector.openSelector();
      }

    };

    return PaymentEditor;
  })();
  window.PaymentEditor = PaymentEditor;
})(jQuery.noConflict(), document, window);
