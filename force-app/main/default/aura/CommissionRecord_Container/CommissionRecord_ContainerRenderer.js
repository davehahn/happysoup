/**
 * Created by dave on 2020-02-27.
 */

({
  rerender: function( component, helper )
  {
    var result = this.superRerender();
    var feed = component.find('feed'),
        recordId = component.get('v.record').id;
    console.log( 'rerender' );
    console.log( feed );
    feed.set('v.body', []);

    helper.addPublisher( component, recordId, feed )
    .then(
      $A.getCallback( function(r) {
        console.log(r);
        component.set('v.publisherLoaded', true );
        return helper.addFeed( component, recordId, feed );
      })
    )
    .then(
      $A.getCallback( function(r) {
        console.log(r);
        component.set('v.feedLoaded', true );
        return result;
      })
    )
    .catch(
      $A.getCallback( function( error ) {
        console.log( error);
      })
    );
  }

});