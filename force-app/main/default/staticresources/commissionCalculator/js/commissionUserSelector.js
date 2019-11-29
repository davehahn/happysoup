(function($, document, window, undefined) {

  var UserSelector = (function() {

    function UserSelector( paymentEditor )
    {
      this.paymentEditor = paymentEditor;
      this.$selectContainer = $('#' + this.paymentEditor.commRecordId).find('.user-selector-container');
      this.isOpen = false;
      this.users = [];
    }

    function _fetchUsers()
    {
      var self = this,
          dfd = new $.Deferred();

      if( self.users.length > 0 )
      {
        dfd.resolve();
      }
      else {
        CommissionCalculatorController.fetchUsers(function(result, event){
          if( event.status )
          {
            self.users = result;
            dfd.resolve();
          }
          else
          {
            message = event.message.indexOf('Logged in?') !== -1 ?
              ' Your session has expired.  Please refresh your browser and log in.' :
              event.message;
            dfd.reject(message);
          }
        });
      }
      return dfd.promise();
    }

    function _findUserFromAttribute(attribute, value)
    {
      var self = this,
          users = self.users;
      for( var i=0; i < users.length; i++ )
      {
        if( users[i][attribute] === value )
          return users[i];
      }
      return null;
    }

    function _enableActions()
    {
      var self = this, data = {};
      self.$selectContainer.find('a')
      .on('click', function(e) {
        e.preventDefault();
        var $this = $(this);
        if( $this.data('user-id') )
        {
          $this.addClass('busy');
          _handleUserSelect.call(self, $this.data('user-id') );
          return false;
        }
        self.closeSelector();
        return false;
      })
    }

    function _handleUserSelect(userId)
    {
      var self = this, owner, data={}, newPayment;
      if( self.paymentEditor.paymentReassignId === null )
      {
        owner = _findUserFromAttribute.call(self, 'Id', userId);
        data = {
          PaymentPercent__c: 0,
          PaymentAmount__c: 0.00,
          CommissionRecord__c: self.paymentEditor.commRecordId,
          Owner__c: owner.Id,
          Owner__r: owner
        };
        newPayment = $.parseHTML( self.paymentEditor.templates.payment_record_edit( data ) );
        self.paymentEditor.$editorContainer.find('.slds-card:last').after( newPayment );
        // this just to get the stupid tooltip working
        $(document).foundation();
        self.closeSelector();
      }
      else
      {
       _publishNewOwnerSelected.call(self, userId);
      }
    }

    function _publishNewOwnerSelected( userId )
    {
      var self = this,
          evt = new CustomEvent('new-owner-selected', {'detail': { userId: userId } } );
      self.$selectContainer[0].dispatchEvent( evt );
    }

    function _publishClosedEvent()
    {
      var evt = new Event('selector-closed');
      this.$selectContainer[0].dispatchEvent(evt);
    }

    UserSelector.prototype = {

      openSelector: function()
      {
        var self = this;
        self.isOpen = true;
        self.$selectContainer.addClass('displayed');
        _fetchUsers.call(self)
        .then( function() {
          self.$selectContainer.html( self.paymentEditor.templates.user_selector( {users: self.users} ) );
          _enableActions.call(self);
        })
        .fail( function(message) {
          LGND.alert('There was an error', message);
        })
      },

      closeSelector: function()
      {
        var self = this;
        self.isOpen = false;
        self.$selectContainer.removeClass('displayed').off('click');
        _publishClosedEvent.call(self);
        setTimeout( function() {
          self.$selectContainer.children().remove();
        }, 750);
      }

    };

    return UserSelector;
  })();

  window.UserSelector = UserSelector;

})(jQuery.noConflict(), document, window);
