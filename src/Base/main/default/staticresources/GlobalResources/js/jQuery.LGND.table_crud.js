(function($, document, window, undefined) {

  var privates, methods;

  privates = {

    initHandlers: function()
    {
      var self = this;

      $(self).on('click', function(e) {
        e.preventDefault();
        $(this).addClass('open');
        self.settings.$editContainer.addClass( self.settings.editingRowClass );
      });
    }

  }

  methods = {

    init: function()
    {
      var self = this,
          $this = $(this);

      self.settings = $.extend( {
        editingRowClass: 'editing',
        $editContainer: $this.closest('tr'),
        saveFunction: function(){}
      }, options);
    }
    $this.addClass('dropMenu');
    self.privates.initHandlers.call(self);

  }

  $.fn.lgndTableCRUD = function( method ) {
    var args = arguments;

    return this.each(function () {
      var $this = $(this);
      if ( methods[method] ) {
        methods[method].apply( $this, Array.prototype.slice.call( args, 1 ));
      } else if ( typeof method === 'object' || ! method ) {
        methods.init.apply( $this, args );
      } else {
        $.error( 'Method ' +  method + ' does not exist on jQuery.lgndTableCRUD' );
      }
    });
  };

})(jQuery, document, window);
