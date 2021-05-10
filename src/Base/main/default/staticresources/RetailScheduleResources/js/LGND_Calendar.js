(function( $, document, window, undefined) {

  var LGND_Calendar = (function() {

    var LGND_Opening_Time = 8,
      LGND_Closing_Time = 18;

    //Constructor
    function LGND_Calendar( callbacks )
    {
      this.$title = $('#calTitle');
      this.$cal = $('#calendar');
      this.$notifications = $('#notifications');
      this.calFunctions = callbacks;
      this.droppedEvent = null;
      _initialize.call( this );
    }

    function _initialize()
    {
      var self = this;
      self.$cal.fullCalendar({
        timezone: 'local',
        defaultView: 'month',
        defaultDate: LGND.scheduleSettings.calStartDate,
        header: false,
        droppable: true,
        selectable: false,
        selectHelper: true,
        editable: true,
        loading: self.calFunctions.loading,
        drop: self.calFunctions.newEventDropped,
        eventClick: self.calFunctions.eventClick,
        eventDrop: self.calFunctions.eventChanged,
        eventResize: self.calFunctions.eventResize,
        eventDragStart: self.calFunctions.dragStart,
        eventDragStop: self.calFunctions.dragStop,
        eventReceive: self.calFunctions.eventReceive
      });
      _enableControls.call(self);
      _setTitle.call(self);
    }

    function _enableControls()
    {
      var self = this;
      /* calendar controls */
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

      /* notification close controls */
      $('.lgnd').on('click', '.slds-notify__close', function(e) {
        e.preventDefault();
        self.$notifications.removeClass('open');
        setTimeout( function() {
          self.$notifications.html('');
        }, 500);
      })
    }

    function _setTitle()
    {
      var self = this;
      this.$title.html( this.$cal.fullCalendar('getView').title );
    }

    function _showNotification( type, message )
    {
      var self = this,
          content = {
            icons: LGND.iconURLs,
            notification: {
              type: type,
              message: message
            }
          };
      self.$notifications.addClass('open')
      .html( LGND.templates.notification( content ) );
    }

    function _checkOperatingHours( hour, minute )
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

    LGND_Calendar.prototype = {
      setTitle: function()
      {
        this._setTitle.call(this);
      },
      addEventSource: function( source )
      {
        this.$cal.fullCalendar('addEventSource', source);
      },
      removeEventSource: function( source )
      {
        this.$cal.fullCalendar( 'removeEventSource', source );
      },
      refetch: function()
      {
        this.$cal.fullCalendar('refetchEvents');
      },
      showNotification: function(type, message)
      {
        _showNotification.call( this, type, message );
      },
      isDuringOperatingHours: function( hour, minute )
      {
        return _checkOperatingHours.call( this, hour, minute );
      },
      removeEvent: function( eventId )
      {
        this.$cal.fullCalendar('removeEvents', eventId );
      }

    }

    return LGND_Calendar;

  })();

  window.LGND_Calendar = LGND_Calendar;

})(jQuery.noConflict(), document, window)
