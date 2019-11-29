(function($, document, window, undefined) {

  var RetailSchedule = (function() {

    var Handlers = {
      /* all functions will be called using the RetailSchedule as "this" hence rs */
      calControls: function()
      {
        var rs = this;
        rs.elements.$calControls.change(function(e) {
          e.preventDefault();
          var $this = $(this),
              location = $this.data('store-location'),
              state = $this.is(':checked'),
              source = rs.eventSources[location];
          if( source != null )
          {
            $('.scheduable.'+location.toLowerCase()).slideToggle();
            if( state )
            {
              rs.selectedLocations.push( location );
              rs.calendar.addEventSource(source);
              return false;
            }
            else
            {
              var dIndex = rs.selectedLocations.indexOf( location );
              if( dIndex > -1 )
              {
                rs.selectedLocations.splice(dIndex, 1)
              }
              rs.calendar.removeEventSource(source);
              return false;
            }
            return false;
          }
          return false;
        });
      },

      modalClose: function()
      {
        $('.slds').on('click', '.close-modal', function(e) {
          e.preventDefault();
          RetailScheduleViewHelper.closeModal();
        });
      },

      initEditForm: function()
      {
        var rs = this,
            formData,
            $processing,
            submitForm = function( formData )
            {
              console.log( formData );
              RetailScheduleViewHelper.closeModal();
              RetailScheduleHelper.showPageIndicator();
              RetailScheduleHelper.upsertERP( formData  )
              .then( function( result ) {
                if( $processing.length > 0 )
                  $processing.remove();
                RetailScheduleHelper.removePageIndicator();
                rs.calendar.showNotification('success', 'Record was successfully updated!');
                rs.calendar.refetch();
              })
              .fail( function(message) {
                $('.scheduable.processing').removeClass('processing');
                RetailScheduleHelper.removePageIndicator();
                LGND.alert( 'Something went wrong!', message );
              });
            };
         // Save Button
        $processing = $('.scheduable.processing');
        $('[data-form-submit-btn]').on('click', function(e) {
          e.preventDefault();
          var $this = $(this),
              formData = {};

          $('#'+$this.data('form-submit-btn')).find('input, select, textarea')
          .each( function( idx, ele ) {
            var $ele = $(ele);
            if( $ele.attr('type') === 'checkbox')
            {
              formData[ $ele.data('field-name') ] = $ele.is(':checked');
            }
            else
            {
              formData[ $ele.data('field-name') ] = $ele.val();
            }
          });
          if( formData['start-date'] && formData['start-time'] )
          {
            formData['Delivery_Date__c'] = Date.parse( formData['start-date'] + ' ' + formData['start-time'] );
            startTimeSplit = formData['start-time'].split(':');
            delete formData['start-date'];
            delete formData['start-time'];
          }

          errorMsg = rs.calendar.isDuringOperatingHours( parseInt( startTimeSplit[0] ),
                                                            parseInt( startTimeSplit[1] ) );
          if( errorMsg === null )
          {
             submitForm(formData);
          }
          else
          {
            LGND.confirm('Are you Sure?', errorMsg)
            .then( function( result ) {
              if( result )
              {
                submitForm(formData);
              }
            });
          }

        });

        // onWater toggle
        $('#onWaterToggle').on('change', function(e) {
          console.log( 'toggle changed');
          var $this = $(this);
          if( $this.attr('checked') )
          {
            console.log( 'selecting false');
            $this.removeAttr('checked');
          }
          else
          {
            console.log('selecting true');
            $this.attr('checked', 'checked');
          }
        });
      },

      scheduables: function()
      {
        var rs = this;
        $('.scheduable').each( function(idx, ele) {
          var $ele = $(ele);
          Handlers.draggableScheduable( $ele );
          if( $ele.data('event-id') === LGND.scheduleSettings.activeErpId )
          {
            $ele.addClass('activeErp');
            $ele.prependTo( $ele.parent() );
          }
        })
      },

      draggableScheduable: function ( $ele )
      {
        $ele.draggable({
          scroll: false,
          appendTo: '.cal-container',
          helper: 'clone',
          opacity: 0.35,
          addClasses: false,
          zIndex: 10000,
          revert: true,
          revertDuration: 0,
          start: function() {
            $(this).addClass('beingScheduled');
          },
          stop: function() {
           $(this).removeClass('beingScheduled');
          }
        })
      }
    }

    //constructor
    function RetailSchedule()
    {
      this.storeLocations = LGND.scheduleSettings.storeLocations;
      this.selectedLocations = [];
      this.modalOpen = false;
      this.notificationsOpen = false;
      this.tmpls = LGND.templates;
      this.eventSources = {};
      this.elements = {
        $notifications: $('#notifications'),
        $schedulablesConatiner: $('#scheduables'),
        $calControls: $('.cal-toggle')
      }
      _initialize.call( this );
      _buildEventSources.call( this );
      _initHandlers.call( this );
      $.each( LGND.scheduleSettings.activeStores, function(idx, store)
      {
        $('input.lg-toggle[data-store-location="'+store+'"]' )
        .prop('checked', true)
        .trigger('change');
      });
    }

    function _initialize()
    {
      var self = this;
      self.calendar = new LGND_Calendar( _calFunctions.call( self ) );
    }

    function _buildEventSources()
    {
      var self = this,
          buildEventSrc = function(location)
          {
            return function(start, end, timezone, callback)
            {
              RetailScheduleHelper.fetchScheduledERPs( Date.parse(start._d), Date.parse(end._d), location)
              .then( function(events) {
                console.log( events );
                callback(events)
              })
              .fail( function(message) {
                alert(message);
              });
            }
          };

      $.each( self.storeLocations, function( idx, location ) {
        self.eventSources[ location ] = buildEventSrc( location );
      });
    }

    function _initHandlers()
    {
      Handlers.calControls.call( this );
      Handlers.modalClose.call( this );
      Handlers.scheduables.call( this );
    }

    function _editPickup( erpId )
    {
      var self = this;
      RetailScheduleHelper.showPageIndicator();
      RetailScheduleHelper.fetchERP( erpId )
      .then( function( eventData ) {
        console.log(eventData);
        RetailScheduleHelper.removePageIndicator();
        RetailScheduleViewHelper.openModal( LGND.templates.edit_pickup({
          icons: LGND.iconURLs,
          pickupOptions: LGND.scheduleSettings.pickupSelectOptions,
          eventData: eventData
        }) )
        .then( function() {
          Handlers.initEditForm.call( self );
        })
      })
      .fail( function( message ) {
        RetailScheduleHelper.removePageIndicator();
        alert(message);
      });
    }

    function _changePickupByDays( erpId, numOfDays )
    {
      var self = this;
      RetailScheduleHelper.showPageIndicator();
      RetailScheduleHelper.changeByDays( erpId, numOfDays )
      .then( function(result) {
        RetailScheduleHelper.removePageIndicator();
        self.calendar.showNotification('success', 'Record was successfully updated!');
      })
      .fail( function(message) {
        LGND.alert('Something went Wrong!', message);
      })
    }

    function _calFunctions()
    {
      var self = this;
      return {
        loading: function( isLoading, view )
        {
          if( isLoading )
          {
            RetailScheduleHelper.showPageIndicator();
            return false;
          }
          RetailScheduleHelper.removePageIndicator();
        },// /loading

        newEventDropped: function( date, jsEvent, ui )
        {
          console.log( 'New Event dropped' );
          var $this = $(this),
              erpId = $this.data('event-id');

          $this.addClass('processing');
          RetailScheduleHelper.showPageIndicator();
          RetailScheduleHelper.fetchERP( erpId )
          .then( function( eventData ) {
            eventData.startDate = date.format("MM/DD/YY");
            eventData.startTime = date.format("HH:mm");
            RetailScheduleHelper.removePageIndicator();
            RetailScheduleViewHelper.openModal( LGND.templates.edit_pickup({
              icons: LGND.iconURLs,
              pickupOptions: LGND.scheduleSettings.pickupSelectOptions,
              eventData: eventData
            }) )
            .then( function() {
              Handlers.initEditForm.call( self );
            })
          })
          .fail( function( message ) {
            RetailScheduleHelper.removePageIndicator();
            LGND.alert('Something went wrong!', message);
          });
        }, // /newEventDropped

        eventClick: function( calEvent, jsEvent, view )
        {
          _editPickup.call( self, calEvent.id );
        }, // /eventClick

        eventChanged: function( event, delta, revertFunc )
        {
          _changePickupByDays.call( self, event.id, delta._days);
        }, // /eventChanged

        eventReceive: function( event )
        {
          console.log( 'Event Received' );
        }, // /eventReceive

        eventResize: function( event, delta, revertFunc )
        {
          console.log( 'Event Resize')
        }, // /eventResize

        dragStart: function()
        {
          $('#scheduables').addClass('dropZone');
        },

        dragStop: function( event, jsEvent, ui )
        {
          console.log( 'dragStop' );
          var schedEle = $('#scheduables'),
              ofs = schedEle.offset(),
              x1 = ofs.left,
              x2 = ofs.left + schedEle.outerWidth(true),
              y1 = ofs.top,
              y2 = ofs.top + schedEle.outerHeight(true);

          schedEle.removeClass('dropZone');
          if (jsEvent.pageX >= x1 && jsEvent.pageX<= x2 &&
              jsEvent.pageY>= y1 && jsEvent.pageY <= y2)
          {
            RetailScheduleHelper.showPageIndicator();
            RetailScheduleHelper.unscheduleERP( event.id )
            .then( function( result ) {
              RetailScheduleHelper.removePageIndicator();
              self.calendar.removeEvent( event.id );
              schedEle.children('.scheduable-list').prepend( LGND.templates.scheduable({ eventData: result}) );
              Handlers.draggableScheduable( $('.scheduable.justRemoved') );
            })
            .fail( function(message){
              RetailScheduleHelper.removePageIndicator();
              LGND.alert("Something went wrong!", message);
            });
          }
        }// /dragStop
      };
    }

    return RetailSchedule;
  })();

  window.RetailSchedule = RetailSchedule;

  Handlebars.registerHelper('optionBuilder', function(value, selectedValue) {
    var optsString = '<option value="'+value+'"';
    if(value === selectedValue) {
     optsString += ' selected';
    }
    optsString += '>'+value+'</option>';
    return new Handlebars.SafeString(optsString);
  });

  Handlebars.registerHelper('switchInput', function( fieldName, value) {
    var input = '<div class="legend_switch">';
    input += '<input id="onWaterToggle" class="lg-toggle lg-toggle-round" type="checkbox" data-field-name="';
    input += fieldName;
    input += '"';
    console.log( value );
    if( value === true )
      input += ' checked="checked"';
    input += '/><label for="onWaterToggle"></label></div>';
    return new Handlebars.SafeString( input );
  });

  Handlebars.registerHelper('lowerCase', function(text) {
    return text.toLowerCase();
  });

  Handlebars.registerHelper('svgIconURL', function( text ) {
    return LGND.slds_asset_path + text;
  });


  // <svg aria-hidden="true" class="slds-icon slds-icon-custom-custom92 slds-icon--medium">
  //           <use xlink:href="{{icons.erp}}"></use>
  //         </svg>

  Handlebars.registerHelper('objectIcon', function( objOrigin ) {
    var classString,
        iconUrlString = LGND.slds_asset_path,
        htlmString;
    if( objOrigin === 'erp' )
    {
      classString = 'slds-icon-custom-custom92';
      iconUrlString += 'icons/custom-sprite/svg/symbols.svg#custom92';
    }
    if( objOrigin === 'opportunity' )
    {
      classString = 'slds-icon-standard-opportunity';
      iconUrlString += 'icons/standard-sprite/svg/symbols.svg#opportunity';
    }
    htlmString = '<svg aria-hidden="true" class="slds-icon slds-icon--medium ' + classString + '">';
    htlmString += '<use xlink:href="';
    htlmString += iconUrlString;
    htlmString += '"></use></svg>';
    return new Handlebars.SafeString( htlmString );
  })

})(jQuery.noConflict(), document, window);
