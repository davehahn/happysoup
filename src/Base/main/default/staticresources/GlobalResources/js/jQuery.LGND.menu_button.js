(function($, document, window, undefined) {

  var privates, methods;

  privates = {

    positionMenu: function()
    {
      var self = this,
          leftPos,
          pos = self.$menuCtrl.position(),
          btnHeight = self.$menuCtrl.height(),
          btnWidth = self.$menuCtrl.outerWidth();

      if( self.$btnContainer.data('menu-left') )
      {
        leftPos = pos.left - self.menuWidth + btnWidth - 4;
      }
      else
      {
        leftPos = pos.left;
      }

      self.$menu.css({
        top: pos.top + btnHeight + 5,
        left: leftPos
      });
    }, // /positionMenu

    enableMenuControl: function()
    {
      var self = this;

      self.$menuCtrl.on('mouseenter', function(e){
        e.preventDefault();
        self.$btnContainer.addClass('menu-open');
      });
      self.$btnContainer.on('mouseleave',function(e){
        e.preventDefault();
        self.$btnContainer.removeClass('menu-open');
      });
    }

  }

  methods = {

    init: function(options)
    {
      var self = this,
          $this = $(this),
          settings;

      settings = $.extend( {
        onOpen: function() {},
        onClose: function() {}
      }, options);

      self.data('options', settings);
      self.$btnContainer = $this;
      self.$menuCtrl  = $this.find('.menu-ctrl:first');
      self.$menu = $this.children('ul:first');
      self.menuWidth = self.$menu.outerWidth();

      privates.positionMenu.call(self);
      privates.enableMenuControl.call(self);
    }// / init

  }// /methods

  $.fn.lgndMenuBtn = function( method ) {
    var args = arguments;

    return this.each(function () {
      var $this = $(this);
      if ( methods[method] ) {
        methods[method].apply( $this, Array.prototype.slice.call( args, 1 ));
      } else if ( typeof method === 'object' || ! method ) {
        methods.init.apply( $this, args );
      } else {
        $.error( 'Method ' +  method + ' does not exist on jQuery.lgndMenuBtn' );
      }
    });
  };


})(jQuery, document, window);
