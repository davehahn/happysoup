(function($, document, window, undefined) {
  var defaultEventColor = {
    backgroundColor: '#d6d6d6',
    borderColor: '#9c9c9c',
    textColor: '#3C3C3C'
  };

  var LGND_Calendar = (function() {

    //Constructor
    function LGND_Calendar(truckLoadSchedule)
    {
      this.$title = $('#calTitle');
      this.$cal = $('#calendar');
      this.tls = truckLoadSchedule
      this.tmpls = this.tls.tmpls;
      this.icons = this.tls.iconURLs;
      this.calFunctions = _calFunctions.call(this);
      this.droppedEvent = null;
      _inititalize.call(this);
    }

    function _enableControls()
    {
      var self = this;
      $('[data-cal-control]').on('click', function(e) {
        e.preventDefault();
        var ctrl = $(this).data('cal-control');
        if( ctrl === 'changeView' )
        {
          self.$cal.fullCalendar(ctrl, $(this).data('cal-view') );
        }
        else
        {
          self.$cal.fullCalendar(ctrl);
        }
        _setTitle.call(self);
      });
    }

    function _inititalize()
    {
      var self = this;
      self.$cal.fullCalendar({
        timezone: 'local',
        defaultView: 'month',
        header: false,
        displayEventTime: true,
        droppable: true,
        selectable: false,
        selectHelper: true,
        editable: true,
        loading: self.calFunctions.loading,
        drop: self.calFunctions.newEventDropped,
        eventClick: self.calFunctions.eventClick,
        eventDrop: self.calFunctions.eventChanged,
        eventResize: self.calFunctions.eventResize,
        eventDragStop: self.calFunctions.dragStop,
        eventReceive: self.calFunctions.eventReceive
      });
      _enableControls.call(self);
      _setTitle.call(self);
    }

    function _calFunctions()
    {
      var self = this;
      return {
        loading: function( isLoading, view)
        {
          if( isLoading )
          {
             $('.slds').append( self.tmpls.indicator( {icons: self.icons} ) );
            return false;
          }
          $('#indicator').remove();
        },
        newEventDropped: function( date, jsEvent, ui )
        {
          console.log('newEventDropped');
          var $this = $(this),
              tlId = $this.data('event-id');

          function findMaxTravelDays( tripData )
          {
            var max = 1;
            if( typeof(tripData.Destinations__r) !== 'undefined' && tripData.Destinations__r.length > 0 )
            {
              $.each( tripData.Destinations__r, function(idx, dest) {
                max = dest.Travel_Days__c > max ? dest.Travel_Days__c : max;
              });
            }
            return max - 1;
          }

          $this.addClass('processing');
          self.tls.Model.fetchTrip.call( self.tls, tlId )
          .then( function(tripData) {
            console.log( tripData );
            tripData.Departure_Date__c = moment(date).format("MM/DD/YY");
            tripData.Return_Date__c = moment(date).add( findMaxTravelDays(tripData), 'days').format("MM/DD/YY");
            tripData.Driver__c = self.tls.selectedDrivers.length > 1 ? '' : self.tls.selectedDrivers[0];
            self.tls.View.openTripModal.call( self.tls, tripData)
            .then( function() {
              self.tls.trip.schedule( self.tls );
            });
          })
          .fail( function(message) {
            self.tls.View.showNotification.call(self.tls, 'error', message);
          });

        },// /newEventDropped
        eventClick: function( calEvent, jsEvent, view )
        {
          self.tls.viewTripDetails.call(self.tls, calEvent.id );
        },// /eventClick
        eventChanged: function( event, delta, revertFunc )
        {
          console.log('eventChanged');
          self.tls.Model.changedByDays.call(self.tls, event.id, delta._days)
          .then( function() {
            self.tls.View.showNotification.call( self.tls, 'success', 'Successfully Updated Trip Details');
          })
          .fail( function(message) {
            self.tls.View.showNotification.call( self.tls, 'error', message);
            revertFunc();
          });
        },// /eventChanged
        eventReceive: function(event)
        {
          console.log('eventReceived');
          self.droppedEvent = event;
        },// /eventReceive
        eventResize: function( event, delta, revertFunc )
        {
          console.log('eventResize');
          //console.log( delta );
          //console.log(event.end.format());
          self.tls.Model.addedDays.call(self.tls, event.id, delta._days)
          .then( function() {
            self.tls.View.showNotification.call( self.tls, 'success', 'Successfully Updated Truck Load');
          })
          .fail( function(message) {
            self.tls.View.showNotification.call( self.tls, 'error', message);
            revertFunc();
          })
        },// /eventResize;
        dragStop: function( event, jsEvent )
        {
          console.log('dragStop');
          var schedEle = $('#scheduables'),
              ofs = schedEle.offset(),
              x1 = ofs.left,
              x2 = ofs.left + schedEle.outerWidth(true),
              y1 = ofs.top,
              y2 = ofs.top + schedEle.outerHeight(true);
          if (jsEvent.pageX >= x1 && jsEvent.pageX<= x2 &&
              jsEvent.pageY>= y1 && jsEvent.pageY <= y2)
          {
            self.tls.Model.unSchedule.call( self.tls, event.id )
            .then( function() {
              self.$cal.fullCalendar('removeEvents', event.id);
              self.tls.View.showNotification.call( self.tls, 'success', 'Successfully unscheduled');
            })
            .fail( function(message) {
              self.tls.View.showNotification.call( self.tls, 'error', message);
            });
          }
        }
      };
    }

    function _setTitle()
    {
      this.$title.html( this.$cal.fullCalendar('getView').title );
    }

    function _addEventSource(source)
    {
      this.$cal.fullCalendar('addEventSource', source);
    }

    function _removeEventSource( source )
    {
      this.$cal.fullCalendar('removeEventSource', source);
    }

    LGND_Calendar.prototype = {
      setTitle: function() {
        this.setTitle.call(this);
      },
      addEventSource: function(source)
      {
        _addEventSource.call(this, source);
      },
      removeEventSource: function(source)
      {
        _removeEventSource.call(this, source);
      },
      calLoading: function( isLoading, view )
      {
        _calLoading.call(this, isLoading, view);
      }
    }

    return LGND_Calendar;
  })();

  window.TruckLoadSchedule = {

    init: function(  )
    {
      //this.drivers = LGND.selectOptions.drivers;//options.drivers;
      this.truckDrivers = LGND.selectOptions.drivers;
      this.trucks = LGND.selectOptions.trucks;//options.trucks;
      this.trailers = LGND.selectOptions.trailers;//options.trailers;
      this.trailerPositions = LGND.selectOptions.trailePositions;//options.trailerPositions;
      this.selectedDrivers = [];
      this.tmpls = LGND.calTemplates;//options.tmpls;
      this.iconURLs = LGND.iconURLs;//options.iconURLs;
      this.cal = new LGND_Calendar( this );
      this.$calControls = $('.cal-toggle');
      //this.$modalContent = $('#modalContent');
      this.$notifications = $('#notifications');
      this.$schedulablesConatiner = $('#scheduables');
      this.Handlers.init.call(this);
      //this.hbHelpers.call(this);
      this.modalOpen = false;
      this.notificationsOpen = false;
      this.trip = null;
      this.$calControls.prop('checked', true).trigger('change');
    },

    viewTripDetails: function(tripId)
    {
      var self = this;
      self.Model.fetchTrip.call( self, tripId )
      .then( function(tripData) {
        self.View.openTripModal.call( self, tripData);
      })
      .fail( function(message) {
        self.View.showNotification.call(self, 'error', message);
      });
    },

    Handlers: {
      init: function()
      {
        this.Handlers.driverSelector.call(this);
        this.Handlers.schedulables.call(this);
        this.Handlers.closeModalAndNotificationsClickHandler.call(this);
      },

      closeModalAndNotificationsClickHandler: function()
      {
        var self = this;
         //modal close
        $('.slds').on('click', '.close-modal', function(e) {
          e.preventDefault();
          $('.schedulable.processing').removeClass('processing')
          .removeAttr('style');
          self.View.closeModal.call(self);
        })
        //notification close
        .on('click', '.slds-notify__close', function(e) {
          e.preventDefault();
          self.View.removeNotification.call(self);
        })
        .on('click', 'button.slds-modal__close', function(e) {
          e.preventDefault();
          self.View.closeTripModal.call(self);
        })
      },

      driverSelector: function()
      {
        var self = this,
            eventSources = {},
            buildEventSrc = function(driver)
            {
              return function(start, end, timezone, callback)
              {
                 self.Model.fetchTrips.call(self, Date.parse(start._d), Date.parse(end._d), driver.Id)
                .then( function(events) {
                  callback(events)
                })
                .fail( function(message) {
                  alert(message);
                });
              }
            };

        $.each(self.truckDrivers, function(id, driver) {
          eventSources[id] = buildEventSrc(driver);
        });

        $('.cal-toggle').change(function(e) {
          e.preventDefault();
          var $this = $(this),
              driverId = $this.data('driverId'),
              state = $this.is(':checked'),
              source = eventSources[driverId];

          if( source != null )
          {
            if( state )
            {
              self.selectedDrivers.push( driverId );
              self.cal.addEventSource(source);
              return false;
            }
            else
            {
              var dIndex = self.selectedDrivers.indexOf( driverId );
              if( dIndex > -1 )
              {
                self.selectedDrivers.splice(dIndex, 1)
              }
              self.cal.removeEventSource(source);
              return false;
            }
            return false;
          }
          return false;
        });
      },// /diverSelector

      schedulables: function()
      {
        var self = this;
        $('.schedulable').draggable({
          scroll: false,
          appendTo: '.cal-container',
          helper: 'clone',
          opacity: 0.35,
          addClasses: false,
          zIndex: 10000,
          revert: true,
          revertDuration: 0,
          start: function() {
            var $this = $(this);
            $this.hide();
            $('#'+$this.data('event-id') ).remove();
          },
          stop: function() {
            $(this).show();
          }
        })
        .find('a.trip-lookup')
        .on('mouseenter', function(e) {
          console.log( 'mouse entered' );
          e.preventDefault();
          var $this = $(this),
              tripId = $this.data('trip-id'),
              $parent = $(this).closest('.schedulable'),
              offset = $parent.offset(),
              $loader = $('<div></div>').addClass('slds-spinner--large'),
              $box = $('<div></div>').addClass('trip-details').attr('id', tripId);
          $box.append(
            $loader.append( $('<img></img>').attr('src', self.iconURLs.spinner) )
          )
          .appendTo( $this )
          .css({ top: offset.top - 100 + ($parent.outerHeight()/2), left: offset.left - $box.outerWidth() - 15} )
          .addClass('open');

          TruckSchedule.fetchTrip( tripId, function(result, event) {
            if( event.status )
            {
              $box.html(
                self.tmpls.trip_summary( { trip: result, assetPath: LGND.slds_asset_path } )
              )
              .find('button.view-trip')
              .on('click', function(e) {
                e.preventDefault();
                var tripId = $(this).data('trip-id');
                $('#'+tripId ).remove();
                self.viewTripDetails.call( self, tripId );
              });
            }
            else
            {
              self.View.showNotification('error', event.message);
            }
          })
        })
        .on('mouseleave', function(e) {
          $('#'+$(this).data('trip-id') ).remove();
        })

      },// /scheduables


    },// /Handlers

    Model: {

      fetchTrips: function(start, end, driver)
      {
        var self = this,
            dfd = new $.Deferred();

        TruckSchedule.fetchAllTrips( start, end, driver, function( result, event ) {
          var events = [];
          if( event.status )
          {
            $.each(result, function(idx, trip) {
              var bgColor,
                  borderColor,
                  textColor,
                  endDate = trip.startDate === trip.endDate ?
                    moment( trip.endDate, 'MM/DD/YY' ).add(1,'days') :
                    moment( trip.endDate, 'MM/DD/YY' );

              if( self.truckDrivers[ trip.truckDriverId ] == undefined )
              {
                bgColor = defaultEventColor.backgroundColor;
                borderColor = defaultEventColor.borderColor;
                textColor = defaultEventColor.textColor;
              }
              else
              {
                bgColor = self.truckDrivers[ trip.truckDriverId ].BgColor;
                borderColor = self.truckDrivers[ trip.truckDriverId ].BorderColor;
                textColor = self.truckDrivers[ trip.truckDriverId ].TextColor;
              }
              events.push({
                id: trip.id,
                title: trip.name,
                start: moment( trip.startDate, 'MM/DD/YY' ),
                end: moment( trip.endDate, 'MM/DD/YY' ).add(1, 'days'),
                allDay: true,
                forceEventDuration: true,
                //className: trip.driver.toLowerCase().split(' ').join('-')
                backgroundColor: bgColor,
                borderColor: borderColor,
                textColor: textColor
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

      fetchTrip: function( tlId )
      {
        var self = this,
            dfd = new $.Deferred();
        self.View.showIndicator.call(self);
        TruckSchedule.fetchTrip( tlId, function(result, event) {
          if( event.status )
          {
            dfd.resolve(result);
          }
          else
          {
            dfd.reject(event.message);
          }
          self.View.removeIndicator();
        });
        return dfd.promise();
      }, // /fetchLoad

      changedByDays: function( id, numDays )
      {
        var self = this,
            dfd = new $.Deferred();
        self.View.showIndicator.call(self);
        TruckSchedule.changedByDays( id, numDays, function(result, event) {
          if(event.status)
          {
            self.View.removeIndicator();
            self.cal.$cal.fullCalendar('refetchEvents');
            dfd.resolve();
          }
          else
          {
            self.View.removeIndicator();
            dfd.reject(event.message);
          }
        });
        return dfd.promise();
      },

      addedDays: function( tripId, numDays )
      {
        var self = this,
            dfd = new $.Deferred();
        self.View.showIndicator.call(self);
        TruckSchedule.addedDays( tripId, numDays, function(result, event) {
          if(event.status)
          {
            self.View.removeIndicator();
            self.cal.$cal.fullCalendar('refetchEvents');
            dfd.resolve();
          }
          else
          {
            self.View.removeIndicator();
            dfd.reject(event.message);
          }
        });
        return dfd.promise();
      },

      unSchedule: function( tripId )
      {
        var self = this,
        dfd = new $.Deferred();

        self.View.showIndicator.call(self);
        TruckSchedule.unschedule( tripId, function(result, event) {
          if( event.status )
          {
            self.$schedulablesConatiner.html( self.tmpls.schedulables({ schedulables: result, icons: self.iconURLs}) );
            self.Handlers.schedulables.call(self);
            dfd.resolve();
          }
          else
          {
            dfd.reject( event.message );
          }
          self.View.removeIndicator.call(self);
        });
        return dfd.promise();
      }// /unschedule

    },// / Model

    View: {

      showIndicator: function()
      {
        var $parent = this.modalOpen ? $('.slds-modal') : $('.slds');
        $parent.append( this.tmpls.indicator({icons: this.iconURLs}) );
      },// /showIndicator

      showNotification: function(type, message)
      {
        var self = this,
            content = {
              icons: self.iconURLs,
              notification: {
                type: type,
                message: message
              }
            };
        self.View.removeNotification.call(self)
        .then( function() {
          self.notificationsOpen = true;
          self.$notifications.addClass('open')
          .html( self.tmpls.notification( content ) );
        });
      }, // /showNotification

      removeNotification: function()
      {
        var self = this
            dfd = new $.Deferred();
        if( self.notificationsOpen )
        {
          self.$notifications.removeClass('open');
          setTimeout( function() {
            self.$notifications.html('');
            dfd.resolve();
          }, 500);
        }
        else
        {
          dfd.resolve();
        }
        return dfd.promise();
      }, //removeNotification

      removeIndicator: function()
      {
        $('#indicator').remove();
      },// /removeIndicator

      openTripModal: function( trip )
      {
        console.log( trip );
        var self = this,
            dfd = new $.Deferred();
        self.modalOpen = true;
        self.trip = new TruckTrip( trip, self );
        $('#trip_edit').addClass('slds-fade-in-open')
        .siblings('.slds-backdrop').addClass('slds-backdrop--open');
        self.trip.onSave = function(trip) {
          console.log('trip save');
          self.cal.$cal.fullCalendar('refetchEvents');
          $('.schedulable.processing').remove();
        }
        dfd.resolve();
        return dfd.promise();
      },

      closeTripModal: function()
      {
        var self = this;
        $('#trip_edit').removeClass('slds-fade-in-open')
        .siblings('.slds-backdrop').removeClass('slds-backdrop--open');
        $('#trip-header').html('');
        $('#trip-content').html('');
        self.trip = null;
        self.modalOpen = false;
      },

    }// /View

  }


})(jQuery.noConflict(), document, window)
