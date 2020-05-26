({
  doInit: function( component, event, helper )
  {
    helper.EventSources = {};
    component.set('v.activeCalendars', [] );
    component.set('v.selectedLocation', '');
    const locations = [
      {
        label: 'Barrie',
        value: 'barrie'
      },
      {
        label: 'Montreal',
        value:'montreal'
      },
      {
        label: 'Whitefish',
        value: 'whitefish'
      }
    ];
    const eventTypes = [
      {
        label: 'Retail',
        value: 'retail'
      },
      {
        label: 'Service',
        value: 'service'
      },
      {
        label: 'Internal',
        value: 'internal'
      },
      {
        label: 'Trade In',
        value: 'trade'
      }

    ];
    component.set('v.eventTypes', eventTypes );
    component.set('v.locations', locations);
  },

	afterScripts : function(component, event, helper)
  {
    helper.setupUserAndPermissions( component )
    .then(
      $A.getCallback( function( result ) {
        component.set('v.canEditRetailPickupDate', result.editPickupDate);
        component.set('v.canEditServiceDate', result.editServiceDate);
        helper.initCalendar( component, result.canCreateERP === "true" );
        helper.setContentHeights( component );
        if( result.warehouse !== null &&
            result.warehouse !== undefined &&
            result.warehouse.length > 0 )
        {
          component.set('v.selectedLocation', result.warehouse.toLowerCase() );
          helper.addAllEventSourcesByLocation( component );
        }
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

  handleLocationChange: function( component, event, helper )
  {
    const schedCMP = component.find('schedulables-CMP');
    if( typeof( schedCMP ) !== 'undefined' )
    {
      console.log('Its open, update it');
      schedCMP.set('v.location', component.get('v.selectedLocation') );
      schedCMP.refresh();
    }
    helper.removeAllEventSourcesByLocation( component )
    .then( $A.getCallback( function() {
      helper.addAllSelectedEventSourcesByLocation( component );
    }));
  },

  filterToggle: function( component )
  {
    var isOpen = component.get('v.filterOpen');
    component.set('v.schedulableOpen', false);
    component.set('v.filterOpen', !isOpen);
  },

  scheduableToggle: function( component )
  {
    var isOpen = component.get('v.schedulableOpen');
    component.set('v.filterOpen', false);
    component.set('v.schedulableOpen', !isOpen );
  },

  handleSchedulableOpen: function( component )
  {
    var schedList = component.find('schedulables'),
        isOpen = component.get('v.schedulableOpen');
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
          location: component.get('v.selectedLocation'),
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