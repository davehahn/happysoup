({
  doInit: function( component, event, helper )
  {
    helper.EventSources = {};
    component.set('v.activeCalendars', [] );
    var calendars = [
      { location: 'Barrie',
        types : [
          { label: 'Retail',
            name: 'barrieRetail',
            value: 'barrie:retail',
            className: 'barrie-retail'
          },
          { label: 'Service',
            name: 'barrieService',
            value: 'barrie:service',
            className: 'barrie-service'
          }
        ]
      },
      { location: 'Montreal',
        types : [
          { label: 'Retail',
            name: 'montrealRetail',
            value: 'montreal:retail',
            className: 'montreal-retail'
          },
          { label: 'Service',
            name: 'montrealService',
            value: 'montreal:service',
            className: 'montreal-service'
          }
        ]
      },
      { location: 'Whitefish',
        types : [
          { label: 'Retail',
            name: 'whitefishRetail',
            value: 'whitefish:retail',
            className: 'whitefish-retail'
          },
          { label: 'Service',
            name: 'whitefishService',
            value: 'whitefish:service',
            className: 'whitefish-service'
          }
        ]
      }
    ];
    component.set('v.calendars', calendars);
  },

	afterScripts : function(component, event, helper)
  {
    helper.setupUserAndPermissions( component )
    .then(
      $A.getCallback( function( result ) {
        console.log( result );
        component.set('v.canEditRetailPickupDate', result.editPickupDate);
        component.set('v.canEditServiceDate', result.editServiceDate);
        helper.initCalendar( component, result.canCreateERP === "true" );
        helper.setContentHeights( component );
        if( result.warehouse !== null &&
            result.warehouse !== undefined &&
            result.warehouse.length > 0 )
          helper.addAllEventSourcesByLocation( component, result.warehouse );
      }),
      $A.getCallback( function( err ) {
        LightningUtils.errorToast( err );
      })
    );

	},

  calNav: function( component, event )
  {
    $('#cal').fullCalendar( event.getSource().get('v.value') );
  },

  handleCalView: function( component, event )
  {
    $('#cal').fullCalendar( 'changeView', event.detail.menuItem.get('v.value') );
  },

  filterToggle: function( component )
  {
    var isOpen = component.get('v.filterOpen');
    component.set('v.schedulableOpen', false);
    component.set('v.filterOpen', !isOpen);
  },

  scheduableToggle: function( component )
  {
    console.log('schedulable visiblity changed');
    var isOpen = component.get('v.schedulableOpen');
    component.set('v.filterOpen', false);
    component.set('v.schedulableOpen', !isOpen );
  },

  handleSchedulableOpen: function( component )
  {
    console.log('handling schedulable change')
    var schedList = component.find('schedulables'),
        isOpen = component.get('v.schedulableOpen');
    console.log( isOpen );
    if( !isOpen )
    {
      setTimeout( function() {
        schedList.set('v.body', [] );
      },
      0.5 );
    }
    else
    {
        $A.createComponent(
        "c:Sales_Service_Calendar_Schedulables",
        {
          "aura:id": "schedulables-CMP",
          activeCalendars: component.get('v.activeCalendars')
        },
        function( list, status, message )
        {
          if (status === "SUCCESS") {
            var body = schedList.get('v.body');
            body.push(list);
            schedList.set("v.body", body);
          }
          else if (status === "INCOMPLETE") {
            LightningUtils.errorToast("No response from server or client is offline.")
          }
          else if (status === "ERROR") {
            LightningUtils.errorToast("Error: " + message);
          }
        }
      );
    }
  },

  toggleEventSource: function( component, event, helper )
  {
    console.log('tootle change');
    var val = event.getSource().get('v.value'),
        isChecked = event.getSource().get('v.checked');
    if( isChecked )
    {
      helper.addEventSource( component, val )
    }
    else
      helper.removeEventSource( component, val );
  },

  closeModal: function( component, event, helper )
  {
    helper.closeModal( component );
  },

  handleModalLoaded: function( component )
  {
    $A.util.addClass( component.find('spinner'), 'slds-hide' );
  },

  handleUpdateSuccess: function( component, event, helper )
  {
    helper.closeModal( component );
    $('#cal').fullCalendar('refetchEvents');
  }
})