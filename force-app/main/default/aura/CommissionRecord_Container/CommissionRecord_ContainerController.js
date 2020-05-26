/**
 * Created by dave on 2020-03-04.
 */

({
  onRender: function( component, event, helper )
  {
    let feed = component.find('feed'),
        record = component.get('v.record');
console.log( JSON.parse( JSON.stringify( record ) ) );
    if( record && record.isViewable && typeof( feed ) !== 'undefined' )
    {
      feed.set('v.body', []);

      helper.addPublisher( component, record.id, feed )
      .then(
        $A.getCallback( function(r) {
          console.log(r);
          component.set('v.publisherLoaded', true );
          return helper.addFeed( component, record.id, feed );
        })
      )
      .then(
        $A.getCallback( function(r) {
          console.log(r);
          component.set('v.feedLoaded', true );
        })
      )
      .catch(
        $A.getCallback( function( error ) {
          console.log( error);
        })
      );
    }
  },

  handleRecordChange: function( component, event, helper )
  {
    helper.setRecordVisibility( component );
  },

  doInit: function( component, event, helper )
  {
    helper.doInit( component );
  },

  handleStatusClick: function( component, event, helper )
  {
    event.preventDefault();
    var status = event.getSource().get('v.value'),
        spinner = component.find('spinner'),
        record = component.get('v.record');

    if( record.status === status ||
        record.status == 'Disputed' && status != 'Approved' )
      return;

    spinner.toggle();
    helper.updateStatus( component, status )
    .then(
      $A.getCallback( function( result ) {
        component.set('v.record', result );
        LightningUtils.showToast( 'success', 'Success!', 'Status was updated');
        component.find('payments').commissionRecordStatusChanged();
        component.find('commissionLines').commissionRecordStatusChanged();
      }),
      $A.getCallback( function( error ) {
        LightningUtils.errorToast( error );
      })
    )
    .finally( $A.getCallback( function() {
      spinner.toggle();
    }));
  },

  handlePaymentEdit: function( component )
  {
    component.set('v.isEditing', !component.get('v.isEditing'));
    component.find('payments').handlePaymentEdit();
  },

  handleAddPayment: function( component )
  {
    var component.target
    component.find('payments').handleAddPayment(typeCP);
  },

  handlePaymentChange: function( component, event )
  {
    component.set('v.paymentsValid', event.getParam('isValid'));
  },

  handlePaymentUpdate: function( component )
  {
    component.find('payments').handlePaymentUpdate();
  },

  handlePaymentUpdateComplete: function( component, event, helper )
  {
    if( event.getParam('status') === 'success' )
    {
      component.set('v.isEditing', false );
    }
  },

  handleDisputedPayments: function( component, event, helper )
  {
    var record = component.get('v.record'),
        dupe = Object.assign({}, record);
    dupe.status = 'Disputed';
    component.set('v.record', dupe);
  },

  handleAddLineItem: function( component )
  {
    component.find('commissionLines').handleAddLine();
  }
});