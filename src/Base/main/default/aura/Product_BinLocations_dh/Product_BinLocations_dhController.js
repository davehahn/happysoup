({
	doInit : function(component, event, helper)
  {
    console.log('doInit');
    helper.fetchLocationInfo( component )
    .then(
      $A.getCallback( function( result ) {
        console.log( result );
        component.set('v.binLocations', result.binLocations );
        component.set('v.productName', result.productName );
        component.set('v.productFamily', result.productFamily );
        component.set('v.productCode', result.productCode );
        component.set('v.productDescription', result.productDescription );
        var binOpts = [];
        var imageContainer = document.getElementById("product-image");
        imageContainer.innerHTML = result.imageURL;
        var image = imageContainer.firstChild;
        image.style.width = '125px';
        image.style.height = '125px';
        for( var whName in result.binLocations )
        {
          if( result.binLocations.hasOwnProperty( whName ) )
            binOpts.push( whName );
        }
        component.set('v.warehouseOptions', binOpts );
        component.set('v.selectedWarehouse', result.userWarehouse );
        // helper.fetchInventory( component )
        // then(
        //   $A.getCallback( function( result ) {
        //     console.log( result );
            component.set('v.loaded', true);
        //   }),
        //   $A.getCallback( function( err ) {
        //     alert(err);
        //   })
        // );
      }),
      $A.getCallback( function( err ) {
        alert( err );
      })
    )
	},

  // doScripts: function( component, event, helper)
  // {
  //   console.log( 'scripts loaded' );
  //   console.log( new LightningApex() );
  // },

  warehouseChanged: function( component, event, helper  )
  {
    var wh = component.get('v.selectedWarehouse'),
        binLocations = component.get('v.binLocations');
    if( binLocations && wh && binLocations.hasOwnProperty( wh ) )
      component.set('v.selectedBinLocations', binLocations[ wh ] );

    if( wh )
    {
      helper.fetchInventory( component )
      .then(
        $A.getCallback( function( result) {
          if( result.length > 0 )
          {
            console.log( 'result' );
            console.log( result );
            var obj = {
              inventoryParts2: parseFloat(result[0].inventoryParts2),
              all: parseFloat(result[0].inventoryParts),
              required: parseFloat(result[0].required),
              available: parseFloat(result[0].inventory2),
              onOrder: parseFloat(result[0].purchasing),
              afterRecieving: parseFloat(result[0].expected2)
            }
            component.set('v.selectedInventoryDetail', obj );
          }
        }),
        $A.getCallback( function( err ) {
          alert(err);
        })
      );
    }
  }
})