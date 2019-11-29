({
  EventSources: {},
  buildCalCallbacks: function( component )
  {
    var self = this,
        allowedRetail = component.get('v.canEditRetailPickupDate') === 'true',
        allowedService = component.get('v.canEditServiceDate') === 'true';

    return {
      viewRender: $A.getCallback( function( view, element ){
        component.set('v.calTitle', view.title );
        window.scrollTo(0,0);
      }),

      windowResize: $A.getCallback( function( view ){
        self.setContentHeights( component );
      }),

      loading: $A.getCallback( function( isLoading, view ){
        var spinner = component.find('spinner');
        if( isLoading )
          $A.util.removeClass( spinner, 'slds-hide' );
        else
          $A.util.addClass( spinner, 'slds-hide' );
      }),

      dayClick: $A.getCallback( function( date, jsEvent, view ){
        console.log( 'day clicked was ' + date.format() );
      }),

      eventClick: $A.getCallback( function( calEvent, jsEvent, view ){
        self.renderDetails(component, calEvent );
      }),

      eventDrop: $A.getCallback( function( event, delta, revertFunc ) {
        self.updateEventDate( component, event, revertFunc );
      }),

      eventMouseover: $A.getCallback( function( event, jsEvent, view ){
        var $this = $(this),
             leftPos = parseInt($this.css('left')) > 0 ? '5px' : '0',
             rightPos = parseInt($this.css('right')) > 0 ? '5px' : '0';

        $this.data({
          'orig-z-index': $this.css('z-index'),
          'orig-left': $this.css('left'),
          'orig-right': $this.css('right') })
        .css({'z-index': 100,
              'left': leftPos,
              'right': rightPos })
        .siblings('a').css('opacity', 0.3);
      }),

      eventMouseout: $A.getCallback( function( event, jsEvent, view ){
        var $this = $(this);
        $this.css({'z-index': $this.data('orig-z-index'),
                   'left': $this.data('orig-left'),
                   'right': $this.data('orig-right') } )
        .data({'orig-z-index': null,
               'orig-left': null,
               'orig-right': null })
        .siblings('a').css('opacity', 1);
      }),

      newEventDrop: $A.getCallback( function( date ) {
        var $this = $(this),
            recordId = $this.data('record-id'),
            calId = $this.data('cal-id'),
            startDate,
            endDate;

        if( ( calId.includes('retail') && allowedRetail ) ||
            ( calId.includes('service') && allowedService ) )
        {
          if( date.hour() == 0 )
            date = moment( date.format() + ' 09:00:00');

          startDate = date.format();
          endDate = date.add(2, 'hours').format();
          $this.addClass('scheduling');
          self.scheduleEvent( component,
                              recordId,
                              calId,
                              startDate,
                              endDate );
        }
      }),

      selectionMade: $A.getCallback( function( start, end, jsEvent, view ) {
        self.renderNewServiceEventForm( component, start, end );
      }),

      navWeek: $A.getCallback( function( weekStart, jsEvent ) {
        $('#cal').fullCalendar('changeView', 'agendaWeek', weekStart.format() );
      }),

      navDay: $A.getCallback( function( date ) {
        $('#cal').fullCalendar('changeView', 'agendaDay', date.format() );
      })
    }
  },

  initCalendar: function( component, canCreate )
  {
    var self = this,
        calCallbacks = self.buildCalCallbacks( component );
    $('#cal').fullCalendar({
      header: false,
      minTime: '06:00:00',
      maxTime: '20:00:00',
      timezone: 'local',
      //eventLimit: true,
      defaultView: 'agendaWeek',
      editable: true,
      eventDurationEditable: false,
      droppable: true,
      weekNumbers: true,
      navLinks: true,
      forceEventDuration: true,
      selectable: canCreate,
      defaultTimedEventDuration: '02:00:00',
      viewRender: calCallbacks.viewRender,
      windowResize: calCallbacks.windowResize,
      loading: calCallbacks.loading,
      eventClick: calCallbacks.eventClick,
      eventMouseover: calCallbacks.eventMouseover,
      eventMouseout: calCallbacks.eventMouseout,
      eventDrop: calCallbacks.eventDrop,
      drop: calCallbacks.newEventDrop,
      select: calCallbacks.selectionMade,
      navLinkWeekClick: calCallbacks.navWeek,
      navLinkDayClick: calCallbacks.navDay
    });
  },

  setContentHeights: function( component )
  {
    var cal = component.find('cal-container'),
        schedulableList = component.find('schedulable-list');
    schedulableList.getElement().style.height = cal.getElement().offsetHeight +'px';
  },

  setupUserAndPermissions: function( component )
  {
    var action = component.get('c.fetchUserDetailsAndPermissions'), la;
    la = new LightningApex( this, action );
    return la.fire();
  },

  addAllEventSourcesByLocation: function( component, location )
  {
    var self = this,
        calendars = component.get('v.calendars');
    for( let cal of calendars )
    {
      if( cal.location === location )
      {
        for( let ct of cal.types )
        {
          self.addEventSource( component, ct.value );
        }
      }
    }
  },

	addEventSource : function( component, source )
  {
    var self = this,
        calSelects = component.find('cal-select'),
        activeCalendars = component.get('v.activeCalendars');

    activeCalendars.push( source );
    component.set('v.activeCalendars', activeCalendars );

    if( !self.EventSources.hasOwnProperty( source) )
      self.EventSources[source] = self.buildEventSource( component, source.split(':')[0], source.split(':')[1] );

    $('#cal').fullCalendar('addEventSource', self.EventSources[source] );
    for( let cs of calSelects )
    {
      if( cs.get('v.value') === source )
        cs.set('v.checked', true);
    }

	},

  removeEventSource : function( component, source )
  {
    var eventSources = this.EventSources,
        activeCalendars = component.get('v.activeCalendars');
    activeCalendars.splice( activeCalendars.indexOf(source), 1 );
    component.set('v.activeCalendars', activeCalendars );
    $('#cal').fullCalendar('removeEventSource', eventSources[source] );
  },

  buildEventSource: function( component, location, calType )
  {
    var self = this;
    return $A.getCallback( function( start, end, timezone, callback )
    {
      self.fetchEvents( component, Date.parse( start._d ), Date.parse( end._d ), location, calType )
      .then(
        $A.getCallback( function( events ) {
          callback( events );
        }),
        $A.getCallback( function( err ) {
          LightningUtils.errorToast( err );
        })
      );
    });
  },

  fetchEvents: function( component, start, end, location, calType )
  {
    var action = component.get('c.fetchScheduledRecords'),
        la,
        editable = false,
        self = this,
        events = [];
    action.setParams({
      startAt: start.toString(),
      endAt: end.toString(),
      storeLocation: location,
      calendarType : calType
    });
    if( calType === 'retail' )
      editable = component.get('v.canEditRetailPickupDate');
    if( calType === 'service' )
      editable = component.get('v.canEditServiceDate');
    la = new LightningApex( self, action )

    return new Promise( function( resolve, reject ) {
      la.fire()
      .then(
        $A.getCallback( function( result ) {
          for( var i=0; i<result.length; i++)
          {
            console.log( result[i]);
            var title =  result[i].eventType + ' (' + result[i].woNumber + ') ';
            if( result[i].boatName != null )
              title += ' - ' + result[i].boatName;
            if( result[i].accountName != null )
              title += '\n\r' + result[i].accountName;
            if( result[i].stage !== null )
              title += '\n\r [ ' + result[i].stage + ' ]';
            if( result[i].jobStatus !== null )
              title += ' [ ' + result[i].jobStatus + ' ]';
            events.push({
              id: result[i].Id,
              title: title,
              start: new Date( result[i].startDateTime ),
              end: new Date( result[i].endDateTime ),
              className: location.toLowerCase() + '-' + calType.toLowerCase(),
              calendarId: result[i].calId,
              editable: editable
            });
          }
          resolve( events );
        }),
        $A.getCallback( function( err ) {
          reject( err );
        })
      );
    });
  },

  renderDetails: function( component, calEvent )
  {
    var componentMap = {
          'retail': "c:Sales_Service_Calendar_RetailEventDetails_dh",
          'service': "c:Sales_Service_Calendar_ServiceEventDetails_dh"
        },
        params = {
          recordId: calEvent.id
        };
    this.openModal( component, componentMap[calEvent.calendarId.split(':')[1] ], params );
  },

  renderNewServiceEventForm: function( component, m_start, m_end )
  {
    var params = {
      startAt: m_start.format(),
      endAt: m_end.format()
    };
    this.openModal( component, 'c:Sales_Service_Calendar_NewServiceForm', params );
  },

  scheduleEvent: function( component,
                          recordId,
                          calId,
                          startTime,
                          endTime )
  {
    var self = this,
        params,
        componentMap = {
          'retail': "c:Sales_Service_Calendar_RetailEventDetails_dh",
          'service': "c:Sales_Service_Calendar_ServiceEventDetails_dh"
        },
        calSplit = calId.split(':'),
        location = calSplit.length === 1 ? calId : calSplit[1];
    if( Object.keys( componentMap ).indexOf( location ) < 0 )
    {
      LightningUtils.errorToast('Invalid calendar specified "' + location + '"');
    }
    else
    {
      params = {
        recordId: recordId,
        scheduleStartDate: startTime,
        scheduleEndDate: endTime
      };
      self.openModal( component, componentMap[ location], params );
    }
  },

  openModal: function( component, modalCompName, params )
  {
    $A.util.removeClass( component.find('spinner'), 'slds-hide' );
    $A.createComponent(
      modalCompName,
      params,
      function( modal, status, errorMessage )
      {
        if (status === "SUCCESS") {
          var mc = component.find('modal-container'),
              body = mc.get('v.body');
          body.push(modal);
          mc.set("v.body", body);
        }
        else if (status === "INCOMPLETE") {
          LightningUtils.errorToast("No response from server or client is offline.")
        }
        else if (status === "ERROR") {
          LightningUtils.errorToast("Error: " + errorMessage);
        }
      }
    );
  },

  updateEventDate: function( component, calEvent, revertFunc )
  {
    var allowedRetail = component.get('v.canEditRetailPickupDate') === 'true',
        allowedService = component.get('v.canEditServiceDate') === 'true',
        calType = calEvent.calendarId.split(':')[1],
        eventData = {
          Id: calEvent.id,
          calId: calEvent.calendarId,
          startDateTime: calEvent.start.format(),
          endDateTime: calEvent.end.format()
        },
        spinner = component.find('spinner'),
        self = this,
        action, la;

    if( calType == 'retail' )
      action = component.get('c.updateRetailRecord');
    else if( calType == 'service' )
      action = component.get('c.updateServiceRecord');
    else {
      LightningUtils.errorToast('Could not determine Event Type');
      revertFunc();
      return false;
    }

    if( calType === 'retail' && !allowedRetail )
    {
      LightningUtils.errorToast('You do not have Permission to make this change');
      revertFunc();
      return false;
    }
    if( calType === 'service' && !allowedService )
    {
      LightningUtils.errorToast('You do not have Permission to make this change');
      revertFunc();
      return false;
    }

    action.setParams({
      jsonEventData: JSON.stringify( eventData )
    });
    $A.util.removeClass(spinner, 'slds-hide');
    la = new LightningApex( self, action );
    la.fire()
    .then(
      $A.getCallback( function() {
        $A.util.addClass(spinner, 'slds-hide');
        LightningUtils.showToast('success', 'Success', 'Date was successfully changed');
      }),
      $A.getCallback( function( err ) {
        $A.util.addClass(spinner, 'slds-hide');
        LightningUtils.errorToast( err );
        revertFunc();
      })
    )
  },

  closeModal: function( component )
  {
    var schedCmp = component.find('schedulables-CMP'),
        modal = component.find('modal-container');
    modal.set('v.body', [] );
    if( component.get('v.schedulableOpen') == true)
      schedCmp.refresh();
  }

})