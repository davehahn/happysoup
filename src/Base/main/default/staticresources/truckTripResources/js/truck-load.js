(function($, document, window, undefined) {

  var TruckLoad = (function() {

    /* CONSTRUCTOR */
    function TruckLoad( tripId )
    {
      this.tripId = null;
      this.items = [];
    }

    function _loadView()
    {
      var self = this;
      if( self.items.length === 0 )
      {
        $('#truck-load').html('');
        return false;
      }
      $('#truck-load').html( LGND.templates.truck_load( {
        items: self.items,
        truckPositions: LGND.selectOptions.trailerPositions,
        pdfURL: LGND.truckLoadPdfURL + '&id=' + self.tripId,
        bolPDF_URL: LGND.truckLoad_BOL_PDF + '&id=' +self.tripId },
      ) );
      _setupDragging.call(self);
      _initClickHandlers.call(self);
    }

    function _setupDragging()
    {
      var self = this,
          dragContainers = [],
          containers = document.querySelectorAll('.drop-container');
      if( self.drake )
      {
        self.drake.destroy();
      }

      for( var i=0; i < containers.length; i++ )
      {
        dragContainers.push( containers[i] );
      }

      self.drake = dragula(dragContainers, {
        revertOnSpill: true,
        mirrorContainer: document.getElementById('truck-load')
      })
      .on('drop', function(el, container, source) {
        _handleItemDrop.call(self, $(container).data('truck-position'), $(el).data('truck-delivery-item-id') )
        .fail( function() {
          $(source).append( $(el) );
        });
      });
    }

    function _findItemById( itemId )
    {
      var self = this, result;
      $.each( self.items, function(idx, item) {
        if( itemId === item.Id )
          result = item;
      });
      return result;
    }

    function _initClickHandlers()
    {
      var self = this;
      $('#truck-load').on('click', 'a[role="menuitem"]', function(e) {
        e.preventDefault();
        var $this = $(this);
        if( $this.data('destination-id') )
          self.serialSelector = SerialSelector.init(  _findItemById.call( self, $this.data('destination-id') ) );
        if( $this.data('erp-id') )
          _navigateToERP( $this.data('erp-id') );
      });
    }

    function _navigateToERP( erpId )
    {
      if( typeof(sforce) === 'undefined' )
      {
        window.top.location.href = window.location.origin + '/' +erpId;
      }
      else
      {
        sforce.one.navigateToSObject( erpId );
      }
    }

    function _handleItemDrop( position, truckDeliveryItemId )
    {
      var self = this, dfd = new $.Deferred();
      TripHelper.addPageIndicator();
      TripHelper.updateTruckDeliveryItemPosition( position, truckDeliveryItemId )
      .then( function() {
        TripHelper.removePageIndicator();
        _updateItemPosition( position, truckDeliveryItemId );
        dfd.resolve();
      })
      .fail( function(msg) {
        TripHelper.removePageIndicator();
        LGND.alert('There was an error !', msg);
        dfd.reject()
      });
      return dfd.promise();
    }

    function _updateItemPosition( position, id )
    {
      var self = this;
      $.each( self.items, function( idx, item) {
        if( item.Id === id )
        {
          item.Position = position;
          return true;
        }
      });
    }

    TruckLoad.prototype = {
      addItems: function( deliveryItems )
      {
        this.items = deliveryItems;
      },
      reloadView: function()
      {
        _loadView.call(this);
      }
    };

    return TruckLoad;

  })();

  window.TruckLoad = TruckLoad;

  Handlebars.registerHelper('truckLoadItem', function( position, records) {
    var items = [];
    $.each( records, function(key, rec) {
      //$.each( rec.deliveryItems, function(idx, item) {
        if( parseInt( rec.Position ) === parseInt( position ) )
          items.push(rec);
      //});
    });
    return new Handlebars.SafeString( LGND.templates.truck_load_items( {items: items} ) );
  });

  Handlebars.registerHelper('truckDeliveryItem', function( deliveryItem ) {
    return new Handlebars.SafeString( LGND.templates.truck_delivery_item( deliveryItem ) );
  });

  Handlebars.registerHelper('itemCount', function( position, items ) {
    var str, count = 0;

    $.each( items, function(key, rec) {
      if( parseInt( rec.Position ) === parseInt( position ) )
        count ++;
    });
    str = count == 1 ? '1 item' : count + ' items';
    return new Handlebars.SafeString( str);
  });

})(jQuery.noConflict(), document, window)
