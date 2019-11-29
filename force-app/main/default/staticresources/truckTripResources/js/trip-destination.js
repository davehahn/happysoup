(function( $, window, document, undefined) {

  function genUniqueId()
  {
    function s4() {
    return Math.floor((1 + Math.random()) * 0x10000)
      .toString(16)
      .substring(1);
    }
    return s4() + s4() + '-' + s4() + '-' + s4() + '-' +
      s4() + '-' + s4() + s4() + s4();
  }

  var ContactSelectForm = {

    init: function( destination )
    {
      var self = this;

      self.destination = destination;
      self.$modal = $('#trip-dialog');
      self.$backdrop = $('#trip-backdrop');
      self.selectedContacts = [];


      TripHelper.addPageIndicator();
      TripHelper.fetchContacts( self.destination.Id )
      .then( function( result ) {
        console.log( result );
        TripHelper.openModal( LGND.templates.contact_select({contacts: result.contacts, wasSent: result.hasBeenSent }) );
        self.initContactForm.call(self);
      })
      .fail( function(message) {
        LGND.alert('There was an error!', message);
      })
      .always( function() {
        TripHelper.removePageIndicator();
      })
    },

    initContactForm: function()
    {
      var self = this;
      $('button[data-contact-select-btn]').on('click', function(e) {
        e.preventDefault();

        var $this = $(this),
            btnType = $this.data('contact-select-btn');
        if( btnType === 'cancel' )
        {
          TripHelper.closeModal();
        }
        if( btnType === 'send' )
        {
          self.handleSendNotice.call(self);
        }
      });

      $('.contact-select input[type="checkbox"]').on('change', function() {
        var $this = $(this),
            cId = $this.prop('value');

        if( $this[0].checked )
          self.selectedContacts.push( cId );
        else
          self.selectedContacts.splice( self.selectedContacts.indexOf( cId ), 1 );
        self.setSendButton.call(self);
      });
    },

    setSendButton: function()
    {
      var $btn = $('button[data-contact-select-btn="send"]');
      console.log( $btn )
      if( this.selectedContacts.length > 0 )
        $btn.removeAttr('disabled');
      else
        $btn.attr('disabled', 'true');
    },

    handleSendNotice: function()
    {
      var self = this;

      console.log( 'send it' );
      console.log( self.selectedContacts );
      TripHelper.closeModal()
      TripHelper.addPageIndicator();
      TripHelper.sendDeliveryNotice( self.destination.Id, self.selectedContacts )
      .then( function() {
        LGND.success('Notice was sent successfully!');
        if( !self.destination.NotificationSent )
        {
          self.destination.NotificationSent = true;
          self.destination.updateSFvalues(self.destination );
          var $badge = $('<span class="slds-badge">Notification Sent</span>');
          $('#'+self.destination.Id + ' h3').append( $badge );
        }
      })
      .fail( function( msg ) {
        LGND.alert('There was an error!', msg);
      })
      .always( function() {
        TripHelper.removePageIndicator();
      });
    }
  };

  var DestinationForm = {

    init: function( destination, title )
    {
      var self = this,
          icons = {
            'search': LGND.slds_asset_path + 'icons/utility/search_60.png',
            'account': LGND.slds_asset_path + 'icons/standard/account_60.png',
            'calendar': LGND.slds_asset_path + 'icons/utility-sprite/svg/symbols.svg#event'
          };


      function _fetchAccounts()
      {
        var self = this
            dfd = new $.Deferred();
        if( self.Accounts == null )
        {
          TripHelper.fetchAccounts()
          .then( function(accounts) {
            self.Accounts = accounts;
            dfd.resolve( self.Accounts );
          })
          .fail( function(message) {
            LGND.alert('There was an error!', message);
          });
        }
        else
        {
          dfd.resolve( self.Accounts );
        };
        return dfd.promise();
      }

      self.destination = destination;
      self.erps;
      self.$modal = $('#trip-dialog');
      self.$backdrop = $('#trip-backdrop');
      TripHelper.openModal( LGND.templates.loading_modal({ title: title }) );
      _fetchAccounts.call(self)
      .then( function() {
        self.$modal.html( LGND.templates.destination_form({icons: icons, accounts: self.Accounts, title: title}) );
        self.initForm.call(self);
      });

    },

    initForm: function()
    {
     var self = this;

     self.initAccountSelect.call(self);
     self.initTypeSelect.call(self);
     self.initDateSelect.call(self);
      // buttons
      $('button[data-add-destination-btn]').on('click', function(e) {
        e.preventDefault();

        var $this = $(this),
            btnType = $this.data('add-destination-btn');

        if( btnType === 'save' )
        {
          self.handleFormSave.call(self);
          return false;
        }
        if( btnType === 'cancel' )
        {
          self.handleFromCancel.call(self);
          return false;
        }
      });
    },

    handleFormSave: function()
    {
      var self = this;
      TripHelper.hideModal();
      if( self.destination.Type === 'Pick-Up' )
      {
        self.destination.Notes = $('[data-attribute-name="notes"]').val();
      }
      TripHelper.addPageIndicator( $('.destination-form') );
      TripHelper.saveDestination( self.destination.returnSFobject(), self.destination.erpIds )
      .then( function( result )
      {
        self.destination.updateSFvalues( result );
        TripHelper.removePageIndicator();
        TripHelper.closeModal();
        if( typeof self.destination.onSave === 'function' )
        {
          self.destination.onSave.call(self.destination);
        }
      })
      .fail( function( msg ) {
        TripHelper.removePageIndicator();
        LGND.alert( 'There was an error!', msg );
      });
    },

    handleFromCancel: function()
    {
      var self = this;
      if( typeof self.destination.onCancel === 'function' )
      {
        self.destination.onCancel.call( self.destination );
      }
      TripHelper.closeModal();
    },

    initDateSelect: function()
    {
      var self = this,
          initDate,
          dateArray = new Date(self.destination.Delivery_Date).toUTCString().split(' ');

      initDate = self.destination.Delivery_Date === null ? null :
        moment( dateArray[1]+' '+dateArray[2]+' '+dateArray[3], 'DD MMM YYYY' );

      $('.destination-form .has-datepicker').datepicker({
        initDate: initDate,
        onChange: function( datepicker ) {
          self.destination.Delivery_Date = moment( datepicker.$el.val() ).format('YYYY-MM-DD');
        }
      })
      .on('keypress', function(e) {
        e.preventDefault();
      });
    },

    initTypeSelect: function()
    {
      var self = this;
      if( self.destination.isNew() )
      {
        $('select[data-attribute-name="Type"]').on('change', function() {
          var v = $(this).val();
          if( v === '' || typeof( v ) === 'undefined' || v === null )
          {
            $('#account-select').attr('disabled', true);
          }
          else
          {
            $('#account-select').removeAttr('disabled');
          }
          self.destination.Type = v;
          if( self.destination.AccountId !== null && self.destination.AccountId.length > 0)
          {
            self.initTypeSpecificFields.call(self);
          }
        });
      }
      else
      {
        $('select[data-attribute-name="Type"]').attr('disabled', 'disabled')
        .val( self.destination.Type ).change();
      }
    },

    initAccountSelect: function()
    {
       var self = this,
          $hiddenAccount = $('input[data-attribute-name="Account"]'),
          $accountInput = $('#account-select'),
          focusHandler = function(e) {
            var $this = $(this),
            currentSelectedAccountId = $hiddenAccount.val(),
            $menu = $this.parent().siblings('.slds-lookup__menu');
            $menu.show();
            $this.closest('.slds-modal__content').on('click', function(e) {
              var $target = $(e.target);
              if( $target.attr('id') !== 'account-select')
              {
                $menu.hide();
                $(this).off('click');
                if( $target.closest('.slds-lookup__menu').length === 0)
                {
                  if( currentSelectedAccountId !== null ||currentSelectedAccountId != '' )
                  {
                    $.each( self.destination.Accounts, function( idx, acct) {
                      if( acct.Id === currentSelectedAccountId )
                      {
                        $accountInput.val( acct.Name );
                        return false;
                      }
                    });
                  }
                }
              }

            });
          },
          keyupHandler = function(e) {
            var $this = $(this);
            $.each( self.Accounts, function(idx, acct) {
              if( acct.Name.toLowerCase().indexOf( $this.val().toLowerCase() ) < 0 )
              {
                $('#'+acct.Id).hide();
              }
              else
              {
                $('#'+acct.Id).show();
              }
            })
          };

        $accountInput.on('focus', focusHandler)
        .on('keyup', keyupHandler )
        .val( self.destination.AccountName );

        //selecting the account
        $('.account-option').on('click', function(e) {
          e.preventDefault();
          var $this = $(this);
          $this.addClass('selected')
          .siblings().removeClass('selected');
          $accountInput.val( $this.find('.slds-lookup__result-text')[0].innerText );
          $hiddenAccount.val( $this.attr('id') ).trigger('change');
        });

        $hiddenAccount.on('change', function(e) {
          var accountId = $(this).val();
          if( accountId !== null || accountId !== '' )
          {
            self.destination.AccountId = accountId
            self.initTypeSpecificFields.call(self);
          }
        })

        if( !self.destination.isNew() )
        {
          $accountInput.attr('disabled', 'disabled');
          $hiddenAccount.val( self.destination.AccountId ).change();
        }
    },

    initTypeSpecificFields: function( )
    {
      var self = this;
      if( self.destination.Type === 'Delivery' )
      {
        self.fetchERPs.call(self);
      }
      if( self.destination.Type === 'Pick-Up' )
      {
        self.$modal.find('[data-type-specific-fields]')
        .html( LGND.templates.pickup_notes( self.destination.Notes ) );
      }
    },

    fetchERPs: function()
    {
      var self = this,
          $container =  self.$modal.find('[data-type-specific-fields]');
      $container.html( LGND.templates.spinner() );
      TripHelper.fetchERPs( self.destination.AccountId, self.destination.erpIds )
      .then( function( result ) {
        console.log( result );
        self.erps = result;
        if( result )
        {
          $container.html( LGND.templates.erp_orders( {erpOrders: result} ) )
          .find('input[type="checkbox"]').on('change', function() {
            self.handleErpSelection.call( self, $(this) );
          });
          $('.erp-type').css('display', 'inline-block'); // icons in modal footer to describe the booking/reorder icons
        }
        else
        {
          var ele = '<div class="slds-text-align--center slds-text-heading--medium slds-m-around--small slds-m-top--none">No Orders Outstanding</div>';
          $container.html( ele );
        }
      })
      .fail( function( msg ) {
        LGND.alert('There was an error!', msg);
      })
    },

    handleErpSelection: function( $checkbox )
    {
      var self = this,
          erpId =  $checkbox.data('erp-id'),
          idx = self.destination.erpIds.indexOf( erpId );

      if( idx < 0 )
      {
        self.destination.erpIds.push( erpId );
        self.destination.erpWrappers.push( self.erpFromId.call(self, erpId) );
      }
      else
      {
        self.destination.erpIds.splice(idx, 1);
        self.destination.erpWrappers.splice(idx, 1);
      }
    },

    erpFromId: function(erpId)
    {
      var self = this, match;
      $.each( self.erps, function(idx, erp) {
        if( erp.Id === erpId )
        {
          match = erp;
          return true;
        }
      });
      return match;
    }

    // openModal: function()
    // {
    //   this.$backdrop.addClass('slds-backdrop--open');
    //   this.$modal.addClass('slds-fade-in-open');
    // },

    // closeModal: function()
    // {
    //   this.$backdrop.removeClass('slds-backdrop--open');
    //   this.$modal.removeClass('slds-fade-in-open').html('');
    // }
  }

  var TripDestination = (function() {

    function TripDestination( trip )
    {
      this.AccountId = null;
      this.AccountName = null;
      this.Trip = typeof( trip ) === 'undefined' ? null : trip.Id;
      this.Type = null;
      this.Delivery_Date = null;
      this.NotificationSent = false
      this.Id = null;
      this.Notes = null;
      this.erpIds = [];
      this.erpWrappers = [];
      this.uiId = genUniqueId();
    }

    function _openForm( title)
    {
      DestinationForm.init( this, title );
    }

    function _openContactSelect()
    {
      ContactSelectForm.init( this );
    }

    TripDestination.prototype = {
      create: function()
      {
        _openForm.call(this, 'New Destination');
      },
      edit: function()
      {
        _openForm.call(this, 'Edit Destination');
      },
      delete: function()
      {
        var dfd = new $.Deferred();
        TripHelper.addPageIndicator();
        TripHelper.deleteDestination( this.Id )
        .then( function() {
          dfd.resolve();
        })
        .fail( function(msg) {
          TripHelper.removePageIndicator();
          LGND.alert('There was an error!', msg);
        });
        return dfd.promise();
      },
      isNew: function()
      {
        return this.Id === null || this.Id === '';
      },
      returnSFobject: function()
      {
        var result = {};
        result['Id'] = this.Id;
        result['Account__c'] = this.AccountId;
        result['Trip__c'] = this.Trip;
        result['Type__c'] = this.Type;
        result['Notes__c'] = this.Notes;
        result['Delivery_Date__c'] = this.Delivery_Date;
        result['Partner_Notification_Sent__c'] = this.NotificationSent;
        return result;
      },
      updateSFvalues: function( sfObject )
      {
        var self = this;
        $.each( sfObject, function( k, v ) {
          self[k] = v;
        });
        return self;
      },
      sendNotice: function()
      {
        _openContactSelect.call( this );
      }
    }

    return TripDestination;

  })();

  window.TripDestination = TripDestination;

  Handlebars.registerHelper('spinner', function() {
    return new Handlebars.SafeString( LGND.templates.spinner() );
  });

  Handlebars.registerHelper('checkbox', function( erpOrder, booleanField, disabled ) {
    var cb = '<input type="checkbox" data-erp-id="'+erpOrder.Id+'" id="'+erpOrder.Id+'_'+booleanField+'"';
    if( erpOrder[booleanField] )
    {
      cb += ' checked="checked"';
    }
    if( disabled )
    {
      cb += 'disabled="true"';
    }
    cb += ' />';
    return new Handlebars.SafeString( cb );
  });

  Handlebars.registerHelper('destinationMaterialRow', function ( materialWrapper ) {
    return new Handlebars.SafeString( LGND.templates.destination_material_row( materialWrapper ) );
  });

  Handlebars.registerHelper( "boatAndTrailerNames", function(erpOrder) {
    var  boatName, trailerName, result = '';
    $.each( erpOrder.MaterialWrappers, function(idx, mat) {
      if( mat.RecordType === 'Boat' )
      {
        boatName = mat.Name;
      }
      if( mat.RecordType === 'Trailer' )
      {
        trailerName = mat.Name;
      }
    });
    if( typeof(boatName) !== 'undefined' )
      result += boatName;
    if( typeof(boatName) !== 'undefined' && typeof(trailerName) !== 'undefined')
      result += ' / ';
    if( typeof( trailerName) !== 'undefined' )
      result += trailerName;
    return result;
  })

})( jQuery.noConflict(), window, document);
