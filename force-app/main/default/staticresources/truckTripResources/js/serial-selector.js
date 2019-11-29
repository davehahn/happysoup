(function($, window, document, undefined) {

  window.SerialSelector = {

    init: function( deliveryItem )
    {
      this.deliveryItem = deliveryItem;
      this.materials = deliveryItem.ErpWrapper.MaterialWrappers;
      this.openForm.call(this);
      return this;
    },

    openForm: function()
    {
      var self = this;
      TripHelper.openModal( LGND.templates.serial_selector({ materials: self.materials} ));
      self.initForm.call(self);
    },

    initForm: function()
    {
      var self = this;
      // footer buttons
      $('.serial-select [ data-serial-form-btn]').on('click', function(e) {
        TripHelper.closeModal();
      });
      //serial select link
      $('.serial-select').on('click', '[data-serial-number-link]', function(e) {
        e.preventDefault();
        var $this = $(this);
            data = {},
            $serialList = $('#product-serial-list');

        $serialList.html( LGND.templates.spinner() );
        self.selectedMaterialId = $this.data('material-id');
        self.selectedSerialId = $this.data('serial-number-id');
        if( self.selectedSerialId !== '' ||
            self.selectedSerialId !== null )
        {
          data.currentSerial = $this.data('serial-number-id');
        }
        $this.closest('tr').addClass('slds-is-selected')
        .siblings().removeClass('slds-is-selected');
        TripHelper.fetchAvailableSerials( $this.data('material-id') )
        .then( function( result ) {
          data.selectOptions = [];
          for( var i=0, len=result.length; i < len; i++ )
          {
            //if( result[i].IsAvailable === 'true' )
            data.selectOptions.push( result[i] );
          }
          $serialList.html( LGND.templates.serial_list( data ) );
          if( self.selectedSerialId !== null ||
              self.selectedSerialId !== '' )
          {
            $('a[data-serial-id="'+self.selectedSerialId+'"]').addClass('selected');
          }
          self.enableSerialFilter.call(self);
          self.enableSerialSelectLinks.call(self);
        })
        .fail( function(msg) {
          LGND.alert('There was an Error !', msg);
        });
      })
    },

    enableSerialFilter: function()
    {
      var self = this,
          $serialLinks = $('.serial-link');
      $('#serial-filter').on('keyup', function(e) {
        e.preventDefault();
        var $this = $(this),
            qString = $this.val(),
            regex,
            $link;

        $.each($serialLinks, function(idx, ele) {
          $link = $(ele);
          if( $link.data('serial-name').toLowerCase().indexOf( qString.toLowerCase() ) < 0 )
          {
            $link.hide();
          }
          else
          {
            if( $link.data('serial-name') === qString )
            {
              $link.addClass('selected').siblings().removeClass('selected');
              self.selectData.serId = $link.data('serial-id');
            }
            regex = new RegExp(qString, "gi");
            $link.html( $link.data('serial-name').replace(regex, "<span class='highlight'>"+qString+"</span>") )
            .show();
          }
        });
      });
    },

    enableSerialSelectLinks: function()
    {
      var self = this,
          assignSerial = function( $link ) {
            $('[data-material-id="'+ self.selectedMaterialId +'"]').parent('td')
            .html( LGND.templates.spinner_small );
            $link.addClass('selected')
            .siblings().removeClass('selected');
            self.handleSerialSelected.call(self, $link.data('serial-id') );
          };
      $('.serial-link').on('click', function(e) {
        e.preventDefault();
        var $this = $(this),
            available = $this.data('serial-available');

        if( available == false )
        {
          LGND.confirm('This Serial Number is "Not Available"',
                       'This serial number might be attached to some other ERP Order which is marked as completed. Please make sure you understand the consequences. Do you want to proceed?')
          .then( function(result) {
            if( result == true )
            {
              assignSerial( $this );
            }
          });
        }
        else
        {
          assignSerial( $this );
        }
      });
    },

    handleSerialSelected: function( serialId )
    {
      var self = this;
      TripHelper.setSerial( self.selectedMaterialId, serialId )
      .then( function( result ) {
        $('#'+result.Id).replaceWith( LGND.templates.serial_selector_row( result ) );
        self.deliveryItem.updateMaterialWrapperSerialInfo( result );
        $('#product-serial-list').animate({height: 0}, 500, function() {
          $(this).html('')
          .css('height', 'initial');
        });
        self.selectedMaterialId = null;
        self.selectedSerialId = null;
      })
      .fail( function(msg) {
        LGND.alert('There was an error!', msg);
        $('#product-serial-list').animate({height: 0}, 500, function() {
          $(this).html('')
          .css('height', 'initial');
        });
        $('#'+self.selectedMaterialId).replaceWith(
          LGND.templates.serial_selector_row( self.deliveryItem.findMaterialWrapper( self.selectedMaterialId) )
        );
        self.selectedMaterialId = null;
        self.selectedSerialId = null;

      });
    },

  }

  Handlebars.registerHelper('materialRow', function(material) {
    return new Handlebars.SafeString( LGND.templates.serial_selector_row( material ) );
  });

  Handlebars.registerHelper('serialNumberLink', function( material ) {
    var returnString = '<a href="#" data-material-id="' + material.Id + '" data-serial-number-link';
    if( !material.SerialId )
    {
     returnString += ' class="slds-button slds-button--neutral">Set Serial</a>';
    }
    else
    {
      returnString += ' data-serial-number-id="'+material.SerialId + '">';
      returnString += material.SerialNumber+'</a>';
    }
    return new Handlebars.SafeString( returnString );
  });

})(jQuery.noConflict(), window, document);
