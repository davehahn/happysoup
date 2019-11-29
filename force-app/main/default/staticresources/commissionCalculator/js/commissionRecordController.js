(function($, document, window, undefined)
{
  window.CommissionRecordJSController = function($container, templates)
  {
    this.$container = $container;
    this.templates = templates;
    this.records = [];
    var self = this;

    self.initOffice = function()
    {
      self.Service = new OfficeService();
      self.Renderer = new Renderer(self.templates, self.$container);
      initialize.call(self);
    };

    function initialize()
    {
      var that = this;
      that.Renderer.loadIndicator('Retrieving Commission Records .....');
      $.when( that.Service.fetchRecords() )
      .done( function(records)
      {
        that.Renderer.displayRecords(records);
      })
      .fail(function(message)
      {
        LGND.alert('There was an error!', message);
      });
    }

  }

  function OfficeService(){}

  OfficeService.prototype = {
    constructor: OfficeService,
    fetchRecords: function()
    {
      var dfd = new $.Deferred();
      CommissionRecordController.fetchCommissionRecords( function(result, event){
        if( event.status )
        {
          dfd.resolve(result);
        }
        else
        {
          message = event.message.indexOf('Logged in?') !== -1 ?
            ' Your session has expired.  Please refresh your browser and log in.' :
            event.message;
          dfd.reject(message);
        }
      });
      return dfd.promise();
    }
  }

  function Renderer(templates, $container){
    this.$container = $container;
    this.templates = templates;
  }

  Renderer.prototype = {
    constructor: Renderer,
    loadIndicator: function(message)
    {
      this.$container.html( this.templates.indicator(message));
    },
    displayRecords: function(records)
    {
      this.$container.html( this.templates.table(records));
    }

  }



})(jQuery.noConflict(), document, window);



