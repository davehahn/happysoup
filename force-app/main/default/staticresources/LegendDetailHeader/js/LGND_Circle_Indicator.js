(function($, window, document, undefined) {
  function LGND_CircleIndicator(message)
  {
    this.message = typeof(message) === 'undefined' ? '' : message;
    this.value = 0;
    this.init();
  }

  LGND_CircleIndicator.prototype = {
    constructor: LGND_CircleIndicator,
    init: function()
    {
      var self = this;
      self.addMarkup.call(self);
      self.updateValue.call(self, self.value);
    },
    addMarkup: function()
    {
      var self = this,
        $container = $('<div></div>').addClass('progress-container'),
        $wrapper = $('<div></div>').addClass('progress-pie-chart'),
        $progress = $('<div></div>').addClass('ppc-progress'),
        $percent = $('<div></div>').addClass('ppc-percents'),
        $progress_fill = $('<div></div>').addClass('ppc-progress-fill'),
        $percent_wrapper =  $('<div></div>').addClass('pcc-percents-wrapper'),
        $message = $('<span class="label"></span>').html(self.message);
        $percent_value = $('<span class="percent-value odometer"></span>')

      $progress.append( $progress_fill );
      if( self.message )
      {
        $percent_wrapper.append( $message );
      }
      $percent.append( $percent_wrapper.append( $percent_value ).append( $('<span class="percent-sign">%</span>') ) );
      $wrapper.append( $progress ).append( $percent );
      $container.append( $wrapper );
      //self.element.addClass('progress-pie-chart').append($progress)
      //  .append($percent);
      self.element = $container;
      self.wrapper = $wrapper;
      self.gauge = $progress_fill;
      self.numeric_output = $percent_value;
    },
    updateValue: function(value)
    {
      var self = this,
      $ppc = self.wrapper,
      percent = parseInt(value),
      deg = 360*percent/100;
      if (percent < 50) {
        $ppc.removeClass('gt-50');
      }
      if (percent > 50)
      {
        $ppc.addClass('gt-50');
      }
      self.gauge.css('transform','rotate('+ deg +'deg)');
      self.numeric_output.html(percent);
    },
    remove: function()
    {
      this.element.remove();
    },
    insertIn: function( $element )
    {
      return $element.append( this.element );
    }

  }

  window.LGND_CircleIndicator = LGND_CircleIndicator;
})(jQuery, window, document);
