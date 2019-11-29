(function($, document, window, undefined) {

  function vfRemotingHandler( result, event, dfd )
  {
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
  };

  window.TripHelper = {

    fetchAccounts: function()
    {
      var dfd = new $.Deferred();
      TripBuilderController.fetchDestinationAccounts( function( result, event ) {
        vfRemotingHandler( result, event, dfd );
      });
      return dfd.promise();
    },

    fetchContacts: function( destinationId )
    {
      var dfd = new $.Deferred();
      TripBuilderController.fetchAccountContacts( destinationId, function( result, event ) {
        vfRemotingHandler( result, event, dfd );
      })
      return dfd.promise();
    },

    fetchERPs: function(accountId, selectedErpIds)
    {
      var dfd = new $.Deferred();
      TripBuilderController.fetchERPs( accountId, selectedErpIds,  function( result, event) {
        vfRemotingHandler(result, event, dfd);
      });
      return dfd.promise();
    },

    saveTrip: function( recordData )
    {
      var dfd = new $.Deferred();
      TripBuilderController.saveTrip( JSON.stringify( recordData ), function( r, e) {
        vfRemotingHandler(r, e, dfd );
      });
      return dfd.promise();
    },

    deleteTrip: function( tripId )
    {
      var dfd = new $.Deferred();
      TripBuilderController.deleteTrip( tripId, function( r, e) {
        vfRemotingHandler(r, e, dfd);
      });
      return dfd.promise();
    },

    fetchDestinations: function( ids )
    {
      var dfd = new $.Deferred();
      TripBuilderController.fetchDestinations( ids, function( r, e ) {
        vfRemotingHandler(r,e,dfd);
      });
      return dfd.promise();
    },

    saveDestination: function( sfDestination, erpIds )
    {
      var dfd = new $.Deferred();
      TripBuilderController.saveDestination( JSON.stringify( sfDestination ), erpIds, function( r, e ) {
        vfRemotingHandler( r, e, dfd );
      });
      return dfd.promise();
    },

    deleteDestination: function( destId )
    {
      var dfd = new $.Deferred();
      TripBuilderController.deleteDestination( destId, function(r,e) {
        vfRemotingHandler(r,e,dfd);
      });
      return dfd.promise();
    },

    updateTruckDeliveryItemPosition: function( position, id )
    {
      var dfd = new $.Deferred();
      TripBuilderController.updateTruckDeliveryItemPosition( position, id, function(r, e) {
        vfRemotingHandler(r,e,dfd);
      });
      return dfd.promise();
    },

    fetchAvailableSerials: function(materialId)
    {
      var dfd = new $.Deferred();
      TripBuilderController.searchSerialForMaterial( materialId, function( r,e ) {
        vfRemotingHandler(r, e, dfd);
      })
      return dfd.promise();
    },

    setSerial: function( materialId, serialId )
    {
      var dfd = new $.Deferred();
      TripBuilderController.setSerialOnMaterial( materialId, serialId, function(r, e) {
        vfRemotingHandler(r,e,dfd);
      });
      return dfd.promise();
    },

    sendDeliveryNotice: function( destinationId, contactIds )
    {
      var dfd = new $.Deferred();
      TripBuilderController.sendPartnerDeliveryNotice( destinationId, contactIds,  function(r, e) {
        vfRemotingHandler(r,e,dfd);
      })
      return dfd.promise();
    },

    openModal: function( template )
    {
      $('#trip-backdrop').addClass('slds-backdrop--open');
      $('#trip-dialog').html(template).addClass('slds-fade-in-open');
    },

    closeModal: function()
    {
      $('#trip-backdrop').removeClass('slds-backdrop--open');
      $('#trip-dialog').removeClass('slds-fade-in-open').html('');
    },

    hideModal: function()
    {
      $('#trip-backdrop').removeClass('slds-backdrop--open');
      $('#trip-dialog').removeClass('slds-fade-in-open');
    },

    unHideModal: function()
    {
      $('#trip-backdrop').addClass('slds-backdrop--open');
      $('#trip-dialog').addClass('slds-fade-in-open');
    },

    // addInlineSpinner: function($parent)
    // {
    //   var rs= '';
    //   rs += '<div class="slds-spinner_container" style="height: 0">';
    //   rs += '<div class="slds-spinner--brand slds-spinner slds-spinner--small" role="alert">';
    //   rs += '<span class="slds-assistive-text">Loading</span>';
    //   rs += '<div class="slds-spinner__dot-a"></div>';
    //   rs += '<div class="slds-spinner__dot-b"></div>';
    //   rs += '</div>';
    //   rs += '</div>';
    //   $parent.html( rs );
    // },

    addPageIndicator: function()
    {
      var $container = $('<div></div>').addClass('slds-spinner_container').attr('id', 'page-indicator').css('position', 'fixed'),
          $spinner = $('<div></div>').addClass('slds-spinner slds-spinner--large').attr('role', 'alert');

      $spinner.append( $('<div></div>'). addClass('slds-spinner__dot-a') )
      .append( $('<div></div>'). addClass('slds-spinner__dot-b') );
      $container.append( $spinner );
      $('.lgnd:first').append( $container );
    },

    removePageIndicator: function()
    {
      $('#page-indicator').remove();
    }

  }


})(jQuery.noConflict(), document, window );
