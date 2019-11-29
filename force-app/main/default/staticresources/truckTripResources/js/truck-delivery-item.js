(function($, document, window, undefined) {

  var TruckDeliveryItem = (function() {

    /* CONSTRUCTOR */
    function TruckDeliveryItem( obj )
    {
      this.Id = obj.Id ? obj.Id : null;
      this.Position = obj.Position ? obj.Position : null
      this.ErpWrapper = obj.ErpWrapper ? obj.ErpWrapper : null;
      this.DestinationId = obj.DestinationId ? obj.DestinationId : null;
      //this.BoatSerial = obj.BoatSerial ? obj.BoatSerial : null;
      //this.TrailerSerial = obj.TrailerSerial ? obj.TrailerSerial : null;
    }

    TruckDeliveryItem.prototype = {
      updateMaterialWrapperSerialInfo: function( material )
      {
        var self = this;
        $.each( self.ErpWrapper.MaterialWrappers, function(idx, mat) {
          if( mat.Id === material.Id )
          {
            mat.SerialId = material.SerialId;
            mat.SerialNumber = material.SerialNumber;
            $('[data-destination-material-id="'+mat.Id+'"]').replaceWith( LGND.templates.destination_material_row( mat ) );
          }
        });
        $('[data-truck-delivery-item-id="'+self.Id+'"]').replaceWith( LGND.templates.truck_delivery_item( self ) );
      },
      findMaterialWrapper: function( materialId )
      {
        var self = this, result;
        $.each( self.ErpWrapper.MaterialWrappers, function( idx, mat) {
          if( mat.Id === materialId )
            result = mat;
        });
        return result;
      }

    };

    return TruckDeliveryItem;

  })();

  window.TruckDeliveryItem = TruckDeliveryItem;

  Handlebars.registerHelper('shippingRequiredClass', function( materialWrapper ) {
    if( materialWrapper.requiresShipping )
      return new Handlebars.SafeString('shipping-required');
  });

  Handlebars.registerHelper('serialNumber', function( serialNumber ) {
    var resultString = '';
    if( serialNumber )
    {
      resultString += '( ';
      resultString += serialNumber;
      resultString += ' )';
    };
    return new Handlebars.SafeString( resultString );
  })

})(jQuery.noConflict(), document, window)
