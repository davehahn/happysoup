(function($, document, window, undefined) {
  var LGND_Opening_Time = 8,
      LGND_Closing_Time = 18;

  function LGND_Calendar(pickupCalendar)
  {
    this.pickupCal = pickupCalendar;
    this.calendars = this.pickupCal.calendars;
    this.canAccessOpps = this.pickupCal.canAccessOpps;
    this.$cal = $('#'+this.pickupCal.settings.cal);
    this.$calTitle = $('#'+this.pickupCal.settings.calTitle);
    this.tmpls = this.pickupCal.tmpls;
    this.iconURLs = this.pickupCal.iconURLs;
    this.pickupLocations = this.pickupCal.pickupLocations;
    this.calHeight = this.pickupCal.calHeight;
    this.defaultView = this.pickupCal.defaultCalView;
    this.defaultDate = this.pickupCal.startDate;
    this.droppedEvent = null;
    this.isDuringOperatingHours = function(hour, minute)
    {
      var result = null,
          minString = minute.toString().length === 1 ? '0' + minute.toString() : minute.toString();
      if( hour < LGND_Opening_Time )
      {
        result = 'The pickup time of ' + hour + ':' + minString + ' is before the normal opening time.';
      }
      if( hour > LGND_Closing_Time ||
          ( hour === LGND_Closing_Time && minute > 0 )
        )
      {
        result = 'The pickup time of ' + hour + ':' + minString + ' is after the normal closing time.';
      }
      return result;
    }

    var self = this,
        calendarFunctions = {
          loading: function( isLoading, view )
          {
            if( isLoading )
            {
              console.log('i am loading');
              self.pickupCal.View.showIndicator.call(self.pickupCal,  $('.slds') );
              return false;
            }
            console.log('i am done loading');
             self.pickupCal.View.removeIndicator();
          }, // /loading
          eventChanged: function( event, delta, revertFunc)
          {
            var eventData = {},
                errorMsg,
                message = event.title + ' was successfully updated',
                upsertEvent = function()
                {
                  self.pickupCal.View.showIndicator.call( self.pickupCal, $('.slds') );
                  LGND_PickupCalendar.Model.upsertEvent( eventData )
                  .then( function(result) {
                    self.pickupCal.View.removeIndicator();
                    self.pickupCal.View.showNotification.call(self.pickupCal, 'success', message);
                    self.$cal.fullCalendar('refetchEvents');
                  })
                  .fail( function(message) {
                    revertFunc();
                    alert(message);
                    self.removeIndicator();
                  });
                };
            eventData.Id = event.id;
            eventData.startSeconds = Date.parse(event.start._d);
            eventData.endSeconds = Date.parse(event.end._d);
            errorMsg = self.isDuringOperatingHours(event.start.hour(), event.start.minute() );
            if( errorMsg === null )
            {
              upsertEvent();
            }
            else
            {
              self.pickupCal.View.sldsConfirm.call(self.pickupCal, errorMsg)
              .then( function() {
                upsertEvent();
              })
              .fail( function() {
                revertFunc();
              });
            }
          },// /eventChanged
          eventMouseover: function( event, jsEvent, view )
          {
            var $this = $(this),
                 leftPos = parseInt($this.css('left')) > 0 ? '20px' : '0';

            $this.data('orig-z-index', $this.css('z-index') )
            .data('orig-left', $this.css('left') )
            .css({'z-index': 100, 'left': leftPos })
            .siblings('a').css('opacity', 0.3);
          },// /eventMouseover
          eventMouseout: function( event, jsEvent, view )
          {
            var $this = $(this);
            $this.css( {'z-index': $this.data('orig-z-index'), 'left': $this.data('orig-left') } )
            .data('orig-z-index', null)
            .data('orig-left', null)
            .siblings('a').css('opacity', 1);
          },// /eventMouseout
          eventClick: function( calEvent, jsEvent, view )
          {
            self.pickupCal.Model.fetchEvent.call( self.pickupCal, calEvent.id )
            .then( function( eventData ) {
              if( calEvent.editable )
              {
                self.pickupCal.View.openModal.call( self.pickupCal, self.tmpls.edit_event( {
                  icons: self.iconURLs,
                  eventData: eventData,
                  eventTypes: self.pickupCal.eventTypes,
                  calOptions: self.pickupCal.manualCalendars } )
                )
                .then( self.pickupCal.Handlers.enableForm.call( self.pickupCal ) );
              }
              else
              {
                self.pickupCal.View.openModal.call( self.pickupCal, self.tmpls.view_event( {icons: self.iconURLs, eventData: eventData} ) )
              }
            })
            .fail( function(message) {
              alert(message);
            });
          },// / eventClick
          newEventDropped: function( date, jsEvent, ui )
          {
            var $this = $(this),
                dataEvent = $this.data('event'),
                eventData = {};

            $this.addClass('processing');
            eventData.startDate = date.format("MM/DD/YY");
            eventData.startTime = date.format("HH:mm");
            eventData.whatId = dataEvent["whatId"];
            eventData.subject = dataEvent["subject"];
            eventData.onWater = JSON.parse(dataEvent['onWater'].toLowerCase());
            eventData.pickupLocation = dataEvent['pickupLocation'];
            self.pickupCal.View.openModal.call( self.pickupCal, self.tmpls.schedule_event( {icons: self.iconURLs,
                                                    eventData: eventData,
                                                    pickupLocations: self.pickupLocations} ) )
            .then( self.pickupCal.Handlers.scheduleForm.call(self.pickupCal) );
          },// /newEventDropped
          selected: function( start, end, jsEvent, view )
          {
            var eventData = {
              startDate: start.format('MM/DD/YY'),
              startTime: start.format('HH:mm'),
              endDate: end.format('MM/DD/YY'),
              endTime: end.format('HH:mm'),
            };
            self.pickupCal.View.openModal.call(self.pickupCal, self.tmpls.new_event( {
              icons: self.iconURLs,
              eventTypes: self.pickupCal.eventTypes,
              eventData: eventData,
              calOptions: self.pickupCal.manualCalendars } )
            )
            .then( self.pickupCal.Handlers.enableForm.call(self.pickupCal) );

          },// /selected
          eventReceive: function(event)
          {
            self.droppedEvent = event;
          }// /eventReceive
        },
        initializeCalendar = function()
        {
          var self = this;
          self.$cal.fullCalendar({
            timezone: 'local',
            height: self.calHeight,
            editable: true,
            defaultDate: self.defaultDate,
            defaultView: self.defaultView,
            nowIndicator: true,
            header: false,
            selectable: true,
            selectHelper: true,
            droppable: true,
            loading: calendarFunctions.loading,
            eventMouseover: calendarFunctions.eventMouseover,
            eventMouseout: calendarFunctions.eventMouseout,
            eventClick: calendarFunctions.eventClick,
            eventDrop: calendarFunctions.eventChanged,
            eventResize: calendarFunctions.eventChanged,
            drop: calendarFunctions.newEventDropped,
            select: calendarFunctions.selected,
            eventReceive: calendarFunctions.eventReceive
          });
        };

    initializeCalendar.call(this);

  }

  LGND_Calendar.prototype = {
    setTitle:function()
    {
      this.$calTitle.html( this.$cal.fullCalendar('getView').title );
      return false;
    },
    addEventSource: function(source)
    {
      this.$cal.fullCalendar('addEventSource', source);
    },
    removeEventSource: function(source)
    {
      this.$cal.fullCalendar('removeEventSource', source);
    }

  };

  LGND_Calendar.prototype.constructor = LGND_Calendar;


  window.LGND_PickupCalendar = {

    settings: {
      droppedEvent: false,
      cal: 'calendar',
      calTitle: 'calTitle',
      modalContent: 'modalContent',
      notifications: 'notifications',
      timeOptions: [ '00:00', '00:30',
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
    },


    init: function( options )
    {
      /*
      options needs to contain:
        isEditable - Boolean
        userStore - String (current users sales store)
        pickupLocations -
        iconURLs - Object (containing icon names and relative urls for the SVGS to use in handlebars templates)
        tmpls = object ( handlebars compiled templates)
        calHeight - Integer (height of calendar)
        defaultCalView - String 9default view for fullCalendar plugin)
        comboBoxAssetLocation - String ( the relative url for the sldsCombobox plugin )
      */
      var self = this;

      self.canAccessOpps = options.canAccessOpps;
      self.userStore = options.userStore;
      self.calendars = options.calendars;
      self.pickupLocations = options.pickupLocations;
      self.calHeight = options.calHeight;
      self.defaultCalView = options.defaultCalView;
      self.iconURLs = options.iconURLs;
      self.tmpls = options.tmpls;
      self.eventTypes = options.eventTypes;
      self.startDate = options.startDate;
      self.LGND_Cal = new LGND_Calendar(self);
      self.activeOpportunityId = options.activeOpportunityId;
      /*
        manualCalendars are public salesforce calendars which we allow
        adding generic events to through selecting or the new button
        and not allowing pickup events( scheduables )
      */
      self.manualCalendars = [];

      self.comboBoxAssetLocation = options.comboBoxAssetLocation;
      self.$modalContent = $('#'+self.settings.modalContent);
      self.$notifications = $('#'+self.settings.notifications);

      self.LGND_Cal.setTitle();
      self.Handlers.init.call(self);
      self.hbHelpers.call(self);
      self.View.setScheduableContainer();

      if( options.userStore === null || options.userStore === '' )
      {
        $('.cal-toggle').prop('checked', true).trigger('change');
      }
      else
      {
        console.log('i am doing this');
        $('input.lg-toggle[data-location="'+options.userStore+'"]' )
        .prop('checked', true)
        .trigger('change');
      }

      //setup the manualCalendars {Name: ..., Id: ...}
      $.each(self.calendars, function(idx, cal) {
        if( cal.allowNewEvents )
        {
          self.manualCalendars.push({
            Name: cal.Name,
            Id: cal.Id
          });
        }
      });

    },// /init

    hbHelpers: function()
    {
      var self = this;
      Handlebars.registerHelper('locationOption', function(value, selectedValue) {
        var optsString = '<option value="'+value+'"';
        if(value === selectedValue) {
         optsString += ' selected';
        }
        optsString += '>'+value+'</option>';
        return new Handlebars.SafeString(optsString);
      });
      Handlebars.registerHelper('optionBuilder', function(name, value, selectedValue) {
        var optsString = '<option value="'+value+'"';
        if(value === selectedValue) {
         optsString += ' selected';
        }
        optsString += '>'+name+'</option>';
        return new Handlebars.SafeString(optsString);
      });
      Handlebars.registerHelper('ifHasOpportunity', function(value, options) {
        if(value)
        {
          return options.fn(this);
        }
        return options.inverse(this);
      });
      Handlebars.registerHelper('ifHasNoOpportunity', function(value, options) {
        if(value)
        {
          return options.inverse(this);
        }
        return options.fn(this);
      });
      Handlebars.registerHelper('oppName', function(event) {
        if( self.canAccessOpps )
        {
          return new Handlebars.SafeString('<a href="/' + event.whatId + '">' + event.oppDetails.Name + '</a>');
        }
        return new Handlebars.SafeString(event.oppDetails.Name);
      });
      Handlebars.registerHelper('stringDate', function(seconds) {
        return new Handlebars.SafeString(moment(seconds).format('MMM DD / YY @ HH:mm') );
      })

    },// /hbHelpers


    Handlers: {

      init: function()
      {
        var self = this;

        self.Handlers.calendarSelect.call(self);
        self.Handlers.calendarControls.call(self);
        self.Handlers.scheduables.call(self);
        self.Handlers.newEvent.call(self);

         //modal close
        $('.slds').on('click', '.close-modal', function(e) {
          e.preventDefault();
          $('.scheduable.processing').removeClass('processing')
          .removeAttr('style');
          self.View.closeModal.call(self);
        })

        //notification close
        .on('click', '.slds-notify__close', function(e) {
          e.preventDefault();
          self.View.removeNotification.call(self);
        });

      },// /init

      calendarSelect: function()
      {
        var self = this,
            eventSources = {},
            buildEventSrc = function(cal)
            {
              return function(start, end, timezone, callback)
              {
                 self.Model.fetchEvents.call(self, Date.parse(start._d), Date.parse(end._d), cal)
                .then( function(events) {
                  callback(events)
                })
                .fail( function(message) {
                  alert(message);
                });
              }
            };

        $.each( self.calendars, function(idx, cal) {
          eventSources[cal.Id] = buildEventSrc(cal);
        });

        // calendar select sliders
        $('.cal-toggle').change(function(e) {
          e.preventDefault();
          console.log('cal select change triggered');
          var $this = $(this),
              calData = $this.data('cal-data'),
              state = $this.is(':checked'),
              source = eventSources[calData.Id];

          if( source != null )
          {
            if( calData.acceptsScheduables )
            {
              $('.scheduable.'+calData.Location.toLowerCase()).slideToggle();
            }
            if( state )
            {
              self.LGND_Cal.addEventSource(source);
              return false;
            }
            else
            {
              self.LGND_Cal.removeEventSource(source);
              return false;
            }
            return false;
          }
          return false;
        });
      },// /calendarSelect

      calendarControls: function()
      {
        var self = this;
        $('[data-cal-control]').on('click', function(e) {
          e.preventDefault();
          var ctrl = $(this).data('cal-control');
          if( ctrl === 'changeView' )
          {
            self.LGND_Cal.$cal.fullCalendar(ctrl, $(this).data('cal-view') );
          }
          else
          {
            self.LGND_Cal.$cal.fullCalendar(ctrl);
          }
          self.LGND_Cal.setTitle();
        });
      },// /calendarControls

      scheduables: function()
      {
        $('.scheduable').data('duration', '01:00')
        .draggable({
          scroll: false,
          appendTo: '.cal-container',
          helper: 'clone',
          opacity: 0.35,
          addClasses: false,
          zIndex: 10000,
          revert: true,
          revertDuration: 0,
          start: function() {
            $(this).hide();
          },
          stop: function() {
            $(this).show();
          }
        });
      },// /scheduables

      newEvent: function()
      {
        var self = this;
        $('#newEventBtn').on('click', function(e) {
          e.preventDefault();
          self.View.openModal.call(self, self.tmpls.new_event( {
            icons: self.iconURLs,
            eventTypes: self.eventTypes,
            calOptions: self.manualCalendars } )
          )
          .then( self.Handlers.enableForm.call(self) );
        });
      },// /newEvent

      enableForm: function()
      {
        var self = this,
            formAction,
            errorMsg,
            $startTimeSelect = $('[data-field-name="start-time"]'),
            currentStartTime = $startTimeSelect.val().split(':'),
            $requiredFields = $('[data-required]'),
            startTimeSplit,
            watchRequired = function() {
              $requiredFields.on('change', function(e) {
                var $this = $(this);
                if( typeof( $this.val() ) == 'undefined' || $this.val() === null || $this.val() === '' )
                {
                  $this.addClass('has-error');
                  return;
                }
                $this.removeClass('has-error');
              });
            },
            validateForm = function() {
              var result = true;
              $.each( $requiredFields, function(idx, ele) {
                var $ele = $(ele);
                if( typeof( $ele.val() ) == 'undefined' || $ele.val() === null || $ele.val() === '' )
                {
                  $ele.addClass('has-error');
                  result = false;
                }
              });
              return result;
            },
            submitForm = function(formData)
            {
              self.View.showIndicator.call( self, $('.slds-modal') );
              formAction = typeof(formData['Id']) === 'undefined' || formData['Id'] === null ? 'created' : 'updated';
              self.Model.upsertEvent.call( self, formData )
              .then( function(result) {
                self.View.removeIndicator();
                self.View.closeModal.call(self);
                self.View.showNotification.call( self, 'success', result.Subject + ' was successfully ' + formAction);
                self.LGND_Cal.$cal.fullCalendar('refetchEvents');
              })
              .fail( function(message) {
                self.View.showNotification.call( self, 'error', message);
                self.View.removeIndicator();
              });
            };


        validateForm();
        watchRequired();

        // Save Button
        $('[data-form-submit-btn]').on('click', function(e) {
          e.preventDefault();
          var $this = $(this),
              formData = {};

          $('#'+$this.data('form-submit-btn')).find('input, select, textarea')
          .each( function( idx, ele ) {
            var $ele = $(ele);
            formData[ $ele.data('field-name') ] = $ele.val();
          });
          if( formData['start-date'] && formData['start-time'] )
          {
            formData['startSeconds'] = Date.parse( formData['start-date'] + ' ' + formData['start-time'] );
            startTimeSplit = formData['start-time'].split(':');
            delete formData['start-date'];
            delete formData['start-time'];
          }
          if( formData['end-date'] && formData['end-time'] )
          {
            formData['endSeconds'] = Date.parse( formData['end-date'] + ' ' + formData['end-time'] );
            delete formData['end-date'];
            delete formData['end-time'];
          }
          if( validateForm() )
          {
            errorMsg = self.LGND_Cal.isDuringOperatingHours( parseInt( startTimeSplit[0] ),
                                                              parseInt( startTimeSplit[1] ) );
            if( errorMsg === null )
            {
              submitForm(formData);
            }
            else
            {
              self.View.sldsConfirm.call(self, errorMsg)
              .then( function() {
                submitForm(formData);
              });
            }
          }
        });

        // Delete Button
        $('[data-event-delete]').on('click', function(e) {
          e.preventDefault();
          self.View.showIndicator.call( self, $('.slds-modal') );
          self.Model.deleteEvent( $(this).data('event-delete') )
          .then( function(result) {
            self.View.removeIndicator();
            self.View.closeModal.call(self);
            self.View.showNotification.call( self, 'success', 'Event was successfully deleted');
            self.LGND_Cal.$cal.fullCalendar('refetchEvents');
          })
          .fail( function(message) {
            self.View.showNotification.call( self, 'error', message);
            self.View.removeIndicator();
          });
        });

      },// /enableForm

      scheduleForm: function()
      {
        var self = this;

        $('[data-form-submit-btn]').on('click', function(e) {
          e.preventDefault();
          var $this = $(this),
              startDate,
              errorMsg,
              startTimeSplit,
              oppData = {},
              dateData = {},
              submitForm = function()
              {
                self.View.showIndicator.call( self, $('.slds-modal') );
                PickupCalendar.createEventForOpp( JSON.stringify(oppData), startDate, function(result, event) {
                  if( event.status )
                  {
                    self.View.removeIndicator();
                    $('.scheduable.processing').remove();
                    self.View.closeModal.call(self);
                    self.View.showNotification.call( self, 'success', 'Successfully Scheduled Pickup');
                    self.LGND_Cal.$cal.fullCalendar('refetchEvents');
                  }
                  else
                  {
                    self.View.showNotification(self, 'error', event.message);
                    self.View.removeIndicator();
                  }
                });
              };

          $('[data-field-name]')
          .each( function( idx, ele ) {
            var $ele = $(ele);
            if( $ele.is('[data-opp-field]') )
            {
              if( $ele.is("[type='checkbox']") )
              {
                oppData[ $ele.data('field-name') ] = ele.checked;
              }
              else
              {
                oppData[ $ele.data('field-name') ] = $ele.val();
              }
            }
            else
            {
              dateData[ $ele.data('field-name') ] = $ele.val();
            }
          });

          startTimeSplit = dateData['start-time'].split(':');
          startDate = Date.parse( dateData['start-date'] + ' ' + dateData['start-time'] );
          errorMsg = self.LGND_Cal.isDuringOperatingHours( parseInt( startTimeSplit[0]), parseInt( startTimeSplit[1]) );
          if( errorMsg == null )
          {
            submitForm();
          }
          else
          {
            self.View.sldsConfirm.call(self, errorMsg)
            .then( function() {
              submitForm();
            })
          }
        });
      }// /schedualeForm

    },// /Handlers

    Model: {
      fetchEvent: function( eventId )
      {
        var self = this,
            dfd = new $.Deferred();
        self.View.showIndicator.call(self, $('.slds') );
        PickupCalendar.fetchEvent( eventId, function(result, event) {
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
      },// /fetchEvent

      fetchEvents: function(startAt, endAt, cal)
      {
        var self = this,
            dfd = new $.Deferred();
            // calNameFromId = function(calId)
            // {
            //   var result = null;
            //   $.each( self.calendars, function(idx, cal) {
            //     if( calId == cal.Id )
            //     {
            //       result = cal.Name.replace(/ /g, '-').toLowerCase();
            //     }
            //   });
            //   return result;
            // };

        PickupCalendar.fetchEvents( startAt, endAt, cal.Id, function( result, event ){
          var events= [];
          if( event.status )
          {
            $.each(result, function(idx, evt) {
              var evtClass = cal.Name.replace(/ /g, '-').toLowerCase(),
                  title = evt.subject;

              if( evt.accountName )
              {
                title += ' - ';
                title += evt.accountName;
              }
              if( evt.whatId === self.activeOpportunityId )
              {
                evtClass += ' activeOpp';
              }
              events.push({
                id: evt.Id,
                editable: evt.editable,
                title: title,
                start: new Date(evt.startDateTime),
                end: new Date(evt.endDateTime),
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
      },// /fetchEvent

      upsertEvent: function( eventData )
      {
        var dfd = new $.Deferred();
        PickupCalendar.upsertEvent( JSON.stringify(eventData), function(result, event) {
          if(event.status)
          {
            dfd.resolve(result);
          }
          else
          {
            dfd.reject(event.message);
          }
        });
        return dfd.promise();
      },// /upsertEvent

      deleteEvent: function( eventId )
      {
        var self = this,
            dfd = new $.Deferred();
        PickupCalendar.deleteEvent( eventId, function(result, event) {
          if( event.status )
          {
            dfd.resolve(result);
          }
          else
          {
            dfd.reject(event.message);
          }
        });
        return dfd.promise();
      },// /deleteEvent

    },

    View: {
      setScheduableContainer: function()
      {
        var totalHeight = $('.cal-container >.column:first').height(),
              h1Height = $('.column > h1:first').outerHeight(true),
              togglesHeight = $('.toggles').outerHeight(true),
              scheduablesHeight = totalHeight - ( 2* h1Height ) - togglesHeight - 5;
        $('.scheduable.barrie, .scheduable.whitefish, .scheduable.montreal').hide();
        $('.scheduables').css('max-height', scheduablesHeight +'px').show();
      }, // /setScheduableContainer

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
        self.$notifications.addClass('open')
        .html( self.tmpls.notification( content ) );
        //setTimeout( removeNotification, 3000 );
      }, // /showNotification

      removeNotification: function()
      {
        var self = this;
        self.$notifications.removeClass('open');
        setTimeout( function() {
          self.$notifications.html('');
        }, 500);
      }, //removeNotification

      showIndicator: function( $parent )
      {
        $parent.append( this.tmpls.indicator({icons: this.iconURLs}) );
      },// /showIndicator

      removeIndicator: function()
      {
        $('#indicator').remove();
      },// /removeIndicator

      openModal: function( content )
      {
        var self = this,
            dfd = new $.Deferred();

        self.$modalContent.html( content )
        .find('.has-datepicker').datepicker();
        self.$modalContent.find('.is-combobox').sldsComboBox({
          templateAssetLocation: self.comboBoxAssetLocation,
          selectOptions: self.settings.timeOptions,
          matchWidth: true
        });
        self.$modalContent.parent().addClass('slds-fade-in-open')
        .siblings('.slds-backdrop').addClass('slds-backdrop--open');
        dfd.resolve();
        return dfd.promise();
      },// /openModel

      closeModal: function()
      {
        var self = this;

        self.$modalContent.html('');
        $('.slds-fade-in-open').removeClass('slds-fade-in-open')
        .siblings('.slds-backdrop').removeClass('slds-backdrop--open');
        if( self.LGND_Cal.droppedEvent != null )
        {
          self.LGND_Cal.$cal.fullCalendar('removeEvents', self.LGND_Cal.droppedEvent.id );
          self.LGND_Cal.droppedEvent = null;
        }
      },

      sldsConfirm: function(message)
      {
        var self = this,
            $otherModals = $('.slds-modal:not(#slds-confirm)'),
            wasOpen = true;
            $backDrop = $('.slds-backdrop'),
            dfd = new $.Deferred();

        if( !$backDrop.hasClass('slds-backdrop--open') )
        {
          $backDrop.addClass('slds-backdrop--open');
          wasOpen = false;
        }
        $('body > .slds').append( self.tmpls.confirm(message) );
        $otherModals.css('opacity', '0');

        $('#slds-confirm').addClass('slds-fade-in-open')
        .on('click', '.confirm-btn', function(e) {
          e.preventDefault();
          var $btn = $(this);

          $('#slds-confirm').remove();
          $otherModals.css('opacity', '1');
          if( !wasOpen )
          {
            $('.slds-backdrop').removeClass('slds-backdrop--open');
          }
          if( $btn.data('confirm-answer') === true )
          {
            dfd.resolve();
          }
          else
          {
            dfd.reject();
          }
        });
        return dfd.promise();
      }
    }


  }



})(jQuery.noConflict(), document, window)
