(function($, window, document, undefined){

  window.BTSelector = function(selectCallback) {
    var that = this;
    that.slideContainer = $('#slideSelector');
    that.fixedContainer = $('#originalSelector');
    that.triggerEl = $('#slideTrigger');
    that.state = 'closed';
    that.onSelected = function(boatType){
      if(typeof(selectCallback) === 'function'){
        selectCallback(boatType);
      }
    }

  }

  BTSelector.prototype.changeState = function() {
    this.state = this.state === 'closed' ? 'open' : 'closed';
    $('.sld_trigger').toggleClass('open');
    $('.sliding').toggleClass('open');
    $('.sliding_row').toggleClass('open');
    return false;
  }

  BTSelector.prototype.initSlideFunctionallity = function(selected){
    var self = this;
    self.slideContainer.css('visibility', 'visible')
    .find('a[data-boat-type="' + selected + '"]').parent().addClass('selected');

    self.triggerEl.on('click', function(e){
      e.preventDefault();
      self.changeState();
    });

    $('body').on('click', '.selectOption', function(e) {
      e.preventDefault();
      var $this = $(this),
          $box = $this.parent();

      if( self.state === 'open' && !$box.hasClass('selected') )
      {
        $('.sliding').removeClass('selected');
        $box.addClass('selected');
        self.onSelected( $this.data('boat-type') );
      }
      self.changeState();
    });
  };

   BTSelector.prototype.init = function(bt){
    var self = this;

    if( typeof(bt) === 'string' && bt != '' )
    {
      self.fixedContainer.hide();
      self.initSlideFunctionallity(bt);
    }
    else
    {
      var endOffset = self.slideContainer.offset();

      self.fixedContainer.find('a').on('click', function(e){
        e.preventDefault();

        var $this = $(this),
          thisOffset = $this.offset(),
          $clone = $this.parent().clone();

        self.onSelected( $this.data('boat-type') );

        $clone.prop('id', 'clone').css({
          'z-index': 1000,
          left: thisOffset.left,
          top: thisOffset.top,
          position:'fixed'
        });

        $('body').append($clone);
        $this.parent().css('visibility', 'hidden');

        $clone.animate({left: endOffset.left,
                        top: ( endOffset.top + parseInt( self.slideContainer.css('padding-top') ) )},
                        400,
                        function() {
          self.initSlideFunctionallity( $this.data('boat-type') );
          self.fixedContainer.slideUp();
          setTimeout( function() { $clone.remove() }, 300);
        });

      });
    }

  };


})(jQuery, window, document);
