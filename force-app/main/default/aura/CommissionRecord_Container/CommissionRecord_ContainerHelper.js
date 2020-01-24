/**
 * Created by dave on 2020-02-27.
 */

({
  recordStatues: ['New', 'Reviewed', 'Approved'],

  doInit: function( component )
  {
    var self = this;
    self.fetchRecord( component )
    .then(
      $A.getCallback( function( result ) {
        component.set('v.record', result );
        var currentIdx = self.recordStatues.indexOf( result.status );
        component.set('v.statusLabel', self.recordStatues[ currentIdx + 1 ] );
      }),
      $A.getCallback( function( error ) {
        LightningUtils.errorToast(error);
      })
    );
  },

  fetchRecord: function( component )
  {
    var action = component.get('c.fetchCommissionRecord'),
        record = component.get('v.record');
    if( record )
    {
      return new Promise( function( resolve ){
        resolve( record );
      });
    }
    action.setParams({
      recordId: component.get('v.recordId')
    });
    return new LightningApex( this, action ).fire();
  },

  updateStatus: function( component, status )
  {
    var action = component.get('c.updateCommissionRecordStatus'),
        params = {
          recordId: component.get('v.record').id,
          status: status
        };

    action.setParams(params);
    return new LightningApex( this, action ).fire();
  },

  addPublisher: function( component, recordId, feedCmp )
  {
    return new Promise( function( resolve, reject )
    {
      $A.createComponent( "forceChatter:publisher",
        {
          "context": "RECORD",
          "recordId": recordId
        },
        function(recordPublisher)
        {
          if (component.isValid())
          {
            var body = feedCmp.get("v.body");
            body.push(recordPublisher);
            feedCmp.set("v.body", body);
            resolve('created publisher');
          }
          else
          {
            reject('Error rendering Publisher component');
          }
        }
      );
    });
  },

  addFeed: function( component, recordId, feedCmp )
  {
    return new Promise( function( resolve, reject )
    {
      $A.createComponent( "forceChatter:feed",
        {
          "type": "Record",
          "subjectId": recordId
        },
        function(recordFeed)
        {
          if( component.isValid() )
          {
            var body = feedCmp.get("v.body");
            body.push(recordFeed);
            feedCmp.set("v.body", body);
            resolve('created feed');
          }
          else
          {
            reject( 'Error rendering Feed component');
          }
        }
      );
    });
  }
});