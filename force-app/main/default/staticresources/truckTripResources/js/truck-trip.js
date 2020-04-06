(function($, document, window, undefined) {
  var TruckTrip = (function() {

    function TruckTrip( SF_TruckTrip, truckLoadSchedule )
    {
      _populateValuesFromSF_TruckTrip.call( this, SF_TruckTrip );
      this.Destinations = {};
      this.AccountSpecialInstructions = [];
      this.TruckLoad = new TruckLoad();
      this.truckLoadSchedule = typeof( truckLoadSchedule ) === 'undefined' ? null : truckLoadSchedule;
      this.elements = {
        'modal': $('#trip-dialog')
      },
      this.icons = {
        'trip': LGND.slds_asset_path + 'icons/custom/custom31_60.png',
        'calendar': LGND.slds_asset_path + 'icons/utility-sprite/svg/symbols.svg#event'
      }
      _init.call(this);

    }

    function _populateValuesFromSF_TruckTrip( SF_TruckTrip )
    {
        console.log('SF_TruckTrip');
        console.log(SF_TruckTrip);
      if( typeof(SF_TruckTrip) === 'undefined' )
      {
        this.Id = null;
        this.Name = null;
        this.Truck_Driver__c = null;
        this.Truck_Driver__r = null;
        this.Departure_Date__c = null;
        this.Distance_KM__c = null;
        this.Return_Date__c = null;
        this.Trailer__c = null;
        this.Truck__c = null;
      }
      else
      {
        this.Id = SF_TruckTrip.Id;
        this.Name = SF_TruckTrip.Name;
        this.Truck_Driver__c = SF_TruckTrip.Truck_Driver__c;
        this.Truck_Driver__r = SF_TruckTrip.Truck_Driver__r;
        this.Departure_Date__c = SF_TruckTrip.Departure_Date__c;
        this.Distance_KM__c = SF_TruckTrip.Distance_KM__c;
        this.Return_Date__c = SF_TruckTrip.Return_Date__c;
        this.Trailer__c = SF_TruckTrip.Trailer__c;
        this.Truck__c = SF_TruckTrip.Truck__c;
        this.Destinations__r = SF_TruckTrip.Destinations__r;
      }
    }

    function _SF_TripObject()
    {
      return {
        Id: this.Id,
        Name: this.Name,
        Truck_Driver__c: this.Truck_Driver__c,
        Truck_Driver__r: this.Truck_Driver__r,
        Departure_Date__c: this.Departure_Date__c === null ? null : moment( this.Departure_Date__c ).format('YYYY-MM-DD'),
        Return_Date__c: this.Return_Date__c === null ? null : moment( this.Return_Date__c ).format('YYYY-MM-DD'),
        Trailer__c: this.Trailer__c,
        Distance_KM__c: this.Distance_KM__c,
        Truck__c: this.Truck__c
      };
    }

    function _init()
    {
      var self = this;
      if( self.Id === null )
      {
        _openTripForm.call(self);
      }
      else
      {
        $('#trip-header').replaceWith(
          LGND.templates.trip_header( {icons: self.icons, record: self} )
        );
       $('#trip-content').html( LGND.templates.trip_content( self ) );
       $('[data-aljs="tabs"]').tabs();
        _headerClickHandlers.call(self);
        _reconstructDestinationTimeline.call(self);
      }
    }

    function _reconstructDestinationTimeline()
    {
      var self = this;
       _buildDestinations.call(self)
      .then( function() {
        _buildDeliveryItems.call(self)
        .then( function() {
          _loadContent.call(self);
        })
      })
      .fail( function(msg) {
        LGND.alert('There was an error!', msg);
      });
    }


    function _buildDestinations()
    {
      var self = this,
          dfd = new $.Deferred(),
          deliveryItems = [],
          accountIds = [],
          destIds = [];
      $('#destination-container').html( LGND.templates.spinner() );
      if( typeof( self.Destinations__r ) !== 'undefined' && self.Destinations__r.length > 0 )
      {
        $.each( self.Destinations__r, function( idx, dest ) {
          destIds.push( dest.Id );
        });
        TripHelper.fetchDestinations( destIds )
        .then( function( result ) {
          console.log( 'result of fetchDestinations' );
          console.log( result );
          $.each( result, function( idx, dest ) {
            var d = new TripDestination();
            self.Destinations[dest.Id] = d.updateSFvalues( dest );

            if( dest.Type === 'Delivery' &&
                accountIds.indexOf( dest.AccountId ) < 0 &&
                dest.AccountSpecialInstructions !== undefined &&
                dest.AccountSpecialInstructions.length > 0)
            {
              accountIds.push( dest.AccountId );
              var data = {};
              data.accountName = dest.AccountName;
              data.specialInstructions = dest.AccountSpecialInstructions;
              if( dest.ShippingTools !== undefined && dest.ShippingTools.length > 0 )
              {
                var tools = [];
                $.each( dest.ShippingTools.split(';'), function(idx,tool) {
                  tools.push( tool );
                });
                data.shippingTools = tools;
              }
              self.AccountSpecialInstructions.push( data );
            }
          });
          dfd.resolve();
        })
        .fail( function(msg) {
          dfd.reject(msg);
        });
      }
      else
      {
        $('#trip-content').html( LGND.templates.trip_content( self ) );
        dfd.resolve();
      }
      return dfd.promise();
    }

    function _buildDeliveryItems()
    {
      var self = this,
          dfd = new $.Deferred();
          deliveryItems = [];
      $.each( self.Destinations, function( key, destination) {
        if( destination.deliveryItems !== undefined )
        {
          $.each( destination.deliveryItems, function(idx, item) {
            deliveryItems.push( new TruckDeliveryItem( item ) );
          });
        }
      });
      self.TruckLoad.addItems( deliveryItems );
      if( self.Id !== self.TruckLoad.tripId )
        self.TruckLoad.tripId = self.Id;
      dfd.resolve();
      return dfd.promise();
    }

    function _loadContent()
    {
      var self = this;
      if( self.AccountSpecialInstructions.length > 0 )
         $('#delivery-instructions').html( LGND.templates.special_instructions( {instructions: self.AccountSpecialInstructions} ) );
      $('#destination-container').html( LGND.templates.destinations_timeline( { destinations: self.Destinations } ) );
      _destinationClickHandlers.call(self);
      self.TruckLoad.reloadView();
    }

    function _openTripForm()
    {
      var self = this;
      //self.elements.modal.html( LGND.templates.trip_form() );
      TripHelper.openModal( LGND.templates.trip_form( {icons: self.icons, selectOptions: LGND.selectOptions, record: self} ) );
      _initTripForm.call(self);
    }

    function _initTripForm()
    {
      var self = this,
          data = $.extend( {}, _SF_TripObject.call(self) );

      function updateData( attribute, value )
      {
        if( value === '' || value === null )
        {
          //delete data[ attribute ];
          data[ attribute ] = null;
        }
        else
        {
          data[ attribute ] = value;
        }
      }

      function determineInitDate( value )
      {
        var dateArray = new Date(value).toUTCString().split(' ');
        return value === null || value === '' ? null :
          moment( dateArray[1]+' '+dateArray[2]+' '+dateArray[3], 'DD MMM YYYY' );
      }

      function dataValid(d)
      {
          console.log('d');
          console.log(d);
        var result = true,
            errorFields = [];
        $('.error').removeClass('error');
        if( d.Name === '' || d.Name === null || typeof( d.Name ) === 'undefined' )
        {
          errorFields.push('Name');
        }
        if( self.truckLoadSchedule )
        {
          if( d.Departure_Date__c > d.Return_Date__c )
          {
            errorFields.push('Departure_Date__c');
            errorFields.push('Return_Date__c');
          }
          if( d.Departure_Date__c === '' || d.Departure_Date__c == null || typeof(d.Departure_Date__c) == 'undefined')
          {
            errorFields.push('Departure__c');
          }
          if( d.Return_Date__c === '' || d.Return_Date__c == null || typeof(d.Return_Date__c) == 'undefined')
          {
            errorFields.push('Return_Date__c');
          }
          if( d.Truck_Driver__c === '' || d.Truck_Driver__c == null || typeof(d.Truck_Driver__c) == 'undefined')
          {
            errorFields.push('Truck_Driver__c');
          }
        }
        if( errorFields.length > 0 )
        {
          $.each(errorFields, function(idx, name) {
            $('[data-attribute-name="'+name+'"]').addClass('error');
          });
          return false;
        }
        return true;
      }

      //populate Select values
      $('select[data-attribute-name]').each( function(idx, ele ) {
        var $ele = $(ele);
        $ele.val( $ele.data('init-value') ).change();
      })
      .on('change', function() {
        var $this = $(this);
        updateData( $this.data('attribute-name'), $this.val() );
      });

      //populate distance
      $('.trip-form .has-distance').each( function(idx, ele ) {
        var $ele = $(ele);
        $ele.val( $ele.data('init-value') ).change();
      })
      .on('change', function() {
        var $this = $(this);
        updateData( $this.data('attribute-name'), $this.val() );
      });

      // date selects
      $('.trip-form .has-datepicker').each( function( idx, ele ){
        var $ele = $(ele),
            initDate = determineInitDate( $ele.data('init-value') );
        $ele.datepicker({
          initDate: initDate,
          onChange: function( datepicker )
          {
            updateData( datepicker.$el.data('attribute-name'), moment( datepicker.$el.val() ).format('YYYY-MM-DD') );
          }
        })
        .on('keypress', function(e) {
          e.preventDefault();
        });
      });
      // continue button
      $('[data-trip-form-btn]').on('click', function(e) {
        e.preventDefault();
        console.log('save button click');
        console.log(data);

        var funct = $(this).data('trip-form-btn');
        if( funct === 'save' )
        {
          data.Name = $('input[data-attribute-name="Name"]').val();
          if( dataValid( data ) )
          {
            _saveTrip.call( self, data );
          }
        }
        if( funct === 'cancel' )
        {
          TripHelper.closeModal();
          if( self.Id === null )
          {
            TripHelper.addPageIndicator();
            window.location.assign( LGND.listViewURL );
          }
          if( self.truckLoadSchedule )
          {
            $('.schedulable.processing').removeClass('processing')
            .removeAttr('style');
            self.truckLoadSchedule.View.closeTripModal.call( self.truckLoadSchedule );
            self.truckLoadSchedule = null;
          }
        }
      });

    }

    function _saveTrip( data )
    {
      var self = this;
      TripHelper.hideModal();
      TripHelper.addPageIndicator();
      console.log('data');
      console.log(data);
      TripHelper.saveTrip( data )
      .then( function( record ) {
        $('#trip-header').replaceWith(
          LGND.templates.trip_header( {icons: self.icons, record: record} )
        );
        TripHelper.removePageIndicator();
        TripHelper.closeModal();
        _headerClickHandlers.call(self);
        _populateValuesFromSF_TruckTrip.call(self, record);
        if( $('#trip-content').children().length === 0 )
        {
          $('#trip-content').html( LGND.templates.trip_content( self ) );
          setTimeout( function() {
            $('[data-aljs="tabs"]').tabs();
          },500);
        }
        _reconstructDestinationTimeline.call(self);
        self.truckLoadSchedule = null;
        TripHelper.closeModal();
        if( self.Desitinations === null || $.isEmptyObject(self.Destinations) )
        {
          _handleNewDestination.call(self);
        }
        if( typeof( self.onSave) === 'function' )
        {
          self.onSave.call(self);
        }
      })
      .fail( function( msg ) {
        TripHelper.unHideModal();
        TripHelper.removePageIndicator();
        LGND.alert('There was an error!', msg);
      });
    }

    function _headerClickHandlers()
    {
      var self = this;
      $('[data-header-btn]').on('click', function(e) {
        e.preventDefault();
        var funct = $(this).data('header-btn');
        if( funct === 'new_destination')
          _handleNewDestination.call(self);
        if( funct === 'edit_trip' )
          _openTripForm.call(self);
        if( funct === 'delete_trip' )
          _handleDeleteTrip.call(self);
        if( funct === 'cancel' )
          _handleReturn.call(self);
      });
    }

    function _destinationClickHandlers()
    {
      var self = this;

      $('.destination-list a[role="menuitem"]').on('click', function(e) {
        e.preventDefault();
        var $this = $(this),
            funct = $this.data('function'),
            dId = $this.data('id');
        if( funct === 'delete' )
        {
          _handleDeleteDestination.call(self, dId );
        }
        if( funct === 'edit' )
        {
          _handleEditDestination.call(self, dId);
        }
        if( funct === 'send-notice' )
        {
          _handleSendPartnerNotification.call(self, dId);
        }
      });
    }

    function _handleReturn()
    {
      if( (typeof sforce != 'undefined') && (sforce != null)  )
      {
        sforce.one.navigateToURL( LGND.returnURL );
      }
      else
      {
        window.location.href = window.location.origin + LGND.returnURL;
      }
    }

    function _handleDeleteTrip()
    {
      var self = this;
      LGND.confirm('Are you sure?', 'This can not be undone.')
      .then( function(response){
        if( response )
        {
          TripHelper.addPageIndicator();
          TripHelper.deleteTrip( self.Id )
          .then( function() {
            _handleReturn.call(self);
          })
          .fail( function( msg ) {
            TripHelper.removePageIndicator();
            LGND.alert('There was an error!', msg);
          })
        }
      });
    }

    function _handleEditDestination( dId )
    {
      var self = this,
          destination = self.Destinations[dId];
      destination.edit();
      if( typeof( destination.onSave ) === 'undefined' )
      {
        destination.onSave = function()
        {
          self.Destinations[this.Id] = this;
          _buildDeliveryItems.call( self)
          .then( function() {
            _loadContent.call(self);
          });
        }
      }
    }

    function _handleSendPartnerNotification( dId )
    {
      var self = this,
          destination = self.Destinations[dId];
      destination.sendNotice();
    }

    function _handleDeleteDestination( dId )
    {
      var self = this;
      LGND.confirm('Are you sure?', 'This can not be undone!')
      .then( function(result) {
        if( result )
        {
          self.Destinations[ dId ].delete()
          .then( function() {
            delete self.Destinations[dId];
            TripHelper.removePageIndicator();
            _buildDeliveryItems.call(self)
            .then( function() {
              self.TruckLoad.reloadView();
              $('#'+dId).animate({
                height: 0
                }, 500, function() {
                  $(this).remove();
              });
            });
          })
        }
      });
    }

    function _handleNewDestination()
    {
      var self = this,
          destination = new TripDestination( self );
      destination.create();
      destination.onSave = function() {
        self.Destinations[this.Id] = this;
         _buildDeliveryItems.call( self)
        .then( function() {
          _loadContent.call(self);
        });
      };
      destination.onCancel = function() {
        //delete self.Destinations[ this.uiId ];
      }
    }



    TruckTrip.prototype = {
      schedule: function( truckLoadSchedule ) {
        this.truckLoadSchedule = truckLoadSchedule;
        _openTripForm.call(this);
      }
    }

    return TruckTrip;

  })();

  window.TruckTrip = TruckTrip;

  Handlebars.registerHelper('toDateString', function( d ) {
    if( d === '' || d === null || typeof( d ) === 'undefined' )
      return '';
    var dArray = new Date(d).toUTCString().split(' '),
        dString = dArray[2] + ' ' + dArray[1] + ', ' + dArray[3];
    return new Handlebars.SafeString( dString );
  });

  Handlebars.registerHelper('noticeIndicator', function(wasSent) {
    console.log( wasSent );
    if( wasSent )
      return new Handlebars.SafeString('<span class="slds-badge">Notification Sent</span>');
     return null;
  });

  Handlebars.registerHelper('destinationTypeIcon', function( destination_type ) {
    var img = '<img class="slds-icon slds-icon--small ';
    if( destination_type == 'Delivery' )
    {
      img += 'slds-icon-custom-custom8"';
      img += ' src="' + LGND.slds_asset_path + 'icons/custom/custom8_60.png"';
      img += '></img>';
      return new Handlebars.SafeString( img );
    }
    if( destination_type == 'Pick-Up' )
    {
      img += 'slds-icon-custom-custom7"';
      img += ' src="' + LGND.slds_asset_path + 'icons/custom/custom7_60.png"';
      img += '></img>';
      return new Handlebars.SafeString( img );
    }
    img += 'slds-icon-custom-custom4"';
    img += ' src="' + LGND.slds_asset_path + 'icons/custom/custom4_60.png"';
    img += '></img>';
    return new Handlebars.SafeString( img );
  });

  Handlebars.registerHelper('downArrowUrl', function() {
    return new Handlebars.SafeString( LGND.slds_asset_path + 'icons/utility-sprite/svg/symbols.svg#down');
  });

  Handlebars.registerHelper('bookingOrder', function( erp ) {
    var iconName = 'replace',
        svg = '<svg aria-hidden="true" class="slds-icon slds-icon-text-default';
    if( erp.isDealerBookingOrder )
    {
      svg += ' booking';
      iconName = 'bookmark';
    }
    if( erp.isRetailSale )
    {
      svg += ' retail';
      iconName = 'people';
    }

    svg += '"><use xmlns:xlink="http://www.w3.org/1999/xlink" xlink:href="';
    svg += LGND.slds_asset_path
    svg += 'icons/utility-sprite/svg/symbols.svg#';
    svg += iconName;
    svg += '"></use></svg>';
    return new Handlebars.SafeString( svg );
  } );

  Handlebars.registerHelper('svgIcon', function( iconPath, svgStyleClass )
  {
    var svg = '<svg aria-hidden="true" class="slds-icon  ';
    svg += svgStyleClass;
    svg += '"><use xmlns:xlink="http://www.w3.org/1999/xlink" xlink:href="';
    svg += LGND.slds_asset_path
    svg += iconPath;
    svg += '"></use></svg>';
    return new Handlebars.SafeString( svg );
  });

  Handlebars.registerHelper('destinationClass', function( destType) {
    if( destType === 'Delivery' )
      return new Handlebars.SafeString('slds-timeline__media--delivery');
    if( destType === 'Pick-Up' )
      return new Handlebars.SafeString('slds-timeline__media--pickup');
    return new Handlebars.SafeString('slds-timeline__media--default');
  });

  Handlebars.registerHelper('ifIsNew', function( recordId, options ){
    if( recordId !== null || recordId !== '' )
    {
      return options.inverse(this);
    }
    return options.fn(this);
  });

  Handlebars.registerHelper('ifNotNull', function( field, options) {
    if( field === null || field === '' || typeof(field) === 'undefined' )
    {
      return options.inverse(this);
    }
    return options.fn(this);
  });

  Handlebars.registerHelper('ifHasPermission', function(permissions, options) {
    if( typeof( LGND.crudPermissions ) === 'undefined')
      return options.fn(this);
    var pArray = permissions.split(','), result = false;
    $.each( pArray, function(idx, permission) {
      if( result === false && LGND.crudPermissions[permission] )
        result = true;
    })
    return result === true ? options.fn(this) : options.inverse(this);
  });

  Handlebars.registerHelper('ifNull', function( field, options) {
    if( field === null || field === '' || typeof(field) === 'undefined' )
    {
      return options.fn(this);
    }
    return options.inverse(this);
  });

  Handlebars.registerHelper('truckLoadItem', function( position, records) {
    var items = [];
    $.each( records, function(key, rec) {
      $.each( rec.deliveryItems, function(idx, item) {
        if( parseInt( item.Position ) === parseInt( position ) )
          items.push(item);
      });
    });
    return new Handlebars.SafeString( LGND.templates.truck_load_items( {items: items} ) );
  });

  Handlebars.registerHelper('spinner', function() {
    return new Handlebars.SafeString( LGND.templates.spinner() );
  });


})(jQuery.noConflict(), document, window);
