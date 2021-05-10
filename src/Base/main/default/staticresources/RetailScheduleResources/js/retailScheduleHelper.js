(function($, document, window, undefined) {

  var timeOptions = [ '00:00', '00:30',
                     '01:00', '01:30',
                     '02:00', '02:30',
                     '03:00', '03:30',
                     '04:00', '04:30',
                     '05:00', '05:30',
                     '06:00', '06:30',
                     '07:00', '07:30',
                     '08:00', '08:30',
                     '09:00', '09:30',
                     '10:00', '10:30',
                     '11:00', '11:30',
                     '12:00', '12:30',
                     '13:00', '13:30',
                     '14:00', '14:30',
                     '15:00', '15:30',
                     '16:00', '16:30',
                     '17:00', '17:30',
                     '18:00', '18:30',
                     '19:00', '19:30',
                     '20:00', '20:30',
                     '21:00', '21:30',
                     '22:00', '22:30',
                     '23:00', '23:30'
                    ]

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

  window.RetailScheduleHelper = {

    fetchScheduledERPs: function( start, end, location)
    {
      var dfd = new $.Deferred(),
          evtClass,
          events = [];
      RetailSchedule.fetchScheduledRecords(start, end, location, function( result, event ) {
        if( event.status )
        {
          $.each(result, function(idx, erp) {
            evtClass = erp.storeLocation.toLowerCase();
            if( erp.Id === LGND.scheduleSettings.activeErpId )
            {
              evtClass += ' activeErp';
            }
            events.push({
              id: erp.Id,
              title: erp.eventType + ' - ' + erp.boatName + ' - ' + erp.accountName,
              start: new Date( erp.startDateTime ),
              end: new Date( erp.endDateTime ),
              className: evtClass
            });
          });
          dfd.resolve(events);
        }
        else
        {
          dfd.reject(event.message);
        }
      });
      return dfd.promise();
    },

    fetchERP: function( erpId )
    {
      var dfd = new $.Deferred();
      RetailSchedule.fetchRecord( erpId, function( r, e ) {
        vfRemotingHandler(r, e, dfd);
      });
      return dfd.promise();
    },

    upsertERP: function( erpData )
    {
      var dfd = new $.Deferred();
      console.log( erpData );
      RetailSchedule.upsertRecord( erpData.Id, JSON.stringify(erpData), function( r, e) {
        vfRemotingHandler(r, e, dfd);
      });
      return dfd.promise();
    },

    changeByDays: function( erpId, numDays )
    {
      var dfd = new $.Deferred();
      RetailSchedule.changePickupByDays( erpId, numDays, function( r, e ) {
        vfRemotingHandler(r, e, dfd);
      });
      return dfd.promise();
    },

    unscheduleERP: function( erpId )
    {
      var dfd = new $.Deferred();
      RetailSchedule.unScheduleRecord( erpId, function( r, e ) {
        vfRemotingHandler(r, e, dfd);
      });
      return dfd.promise();
    },

    showPageIndicator: function()
    {
      $('.slds').append( LGND.templates.indicator( {icons: LGND.iconURLs} ) );
    },

    removePageIndicator: function()
    {
      $('#indicator').remove();
    }
  }

  window.RetailScheduleViewHelper = {

    openModal: function( content )
    {
      var self = this,
          $modalContent =  $('#modalContent'),
          dfd =  new $.Deferred();
      $modalContent.html( content )
      .find('.has-datepicker')
      .each( function( idx, ele) {
        var $ele = $(ele);
        $ele.datepicker( {
          initDate: moment( $ele.val(), 'MM/DD/YYYY')
        });
      });
      $modalContent.find('.is-combobox').sldsComboBox({
        templateAssetLocation: LGND.scheduleSettings.comboBoxAssetLocation,
        selectOptions: timeOptions,
        matchWidth: true
      });
      $modalContent.parent().addClass('slds-fade-in-open')
      .siblings('.slds-backdrop').addClass('slds-backdrop--open');
      dfd.resolve();
      return dfd.promise();
    },

    closeModal: function()
    {
      var $modalContent =  $('#modalContent');
      $modalContent.html('');
      $('.slds-fade-in-open').removeClass('slds-fade-in-open')
      .siblings('.slds-backdrop').removeClass('slds-backdrop--open');
      $('.scheduable.processing').removeClass('processing');
    }

  }


})( jQuery.noConflict(), document, window);
