(function ($) {

  var privates = {

    verifyRequirements: function()
    {

    },//verifyRequirements

    initialize: function()
    {
      var self = this
          options = self.data('options'),
          appData = self.data('appData');

      self.parent().wrap( "<div class='slds-picklist'></div>");

      $.ajax({
        url: options.templateAssetLocation + '/templates/_select-menu.tpl.html',
        cache: true,
        success: function(data) {
          appData.selectTemplate = Handlebars.compile(data);
          privates.setupHandlers.call(self);
        }
      });
    },//compileTemplate

    setupHandlers: function()
    {
      var self = this,
          options = self.data('options'),
          appData = self.data('appData');

      appData.element.prev('svg')
      .css('cursor', 'pointer').on('click', function(e) {
        e.preventDefault();
        if( !appData.isOpen )
        {
          privates.openSelect.call(self)
          .then( function() {
            appData.element.parent().next().find('.slds-combobox-select-option').on('click', function(e) {
              e.preventDefault();
              e.stopPropagation();
              appData.element.val( $(this).data('select-value') );
              privates.closeSelect.call(self);
            });
          });
        }
        else
        {
          privates.closeSelect.call(self);
        }
      });
    },//setupHandlers

    openSelect: function()
    {
      var self = this,
          options = self.data('options'),
          appData = self.data('appData'),
          dfd = new $.Deferred();
console.log(appData)
      appData.optionsContainer = appData.selectTemplate({ selectOptions: options.selectOptions,
                                                  dropdownPos: options.dropdownPos });
      appData.element.parent().after( appData.optionsContainer );
      appData.isOpen = true;
      dfd.resolve();
      return dfd.promise();

    },//openSelect

    closeSelect: function()
    {
      var self = this,
          appData = self.data('appData');
      appData.element.parent().next().remove();
      appData.optionsContainer = null;
      appData.isOpen = false;
      $('body').off('click.closeSldsCombobox');
    }


  }; //privates


  var methods = {

    init: function(options) {

      var self = this,
        appData = {},
        settings;

      settings = $.extend( {
        sldsAssetLocation: null,
        templateAssetLocation: null,
        dropdownPos: self.data('dropdown-pos') ? self.data('dropdown-pos') : 'left',
        selectOptions: [],
        onSelectOpen: function() {},
        onSelectClose: function() {}
      }, options);

      self.data('options', settings);
      appData.isOpen = false;
      appData.element = $(self);
      self.data('appData', appData);

      privates.verifyRequirements.call(self);
      privates.initialize.call(self);

    } //init

  };//methods



  $.fn.sldsComboBox = function( method ) {
    var args = arguments;

    return this.each(function () {
      var $this = $(this);
      if ( methods[method] ) {
        methods[method].apply( $this, Array.prototype.slice.call( args, 1 ));
      } else if ( typeof method === 'object' || ! method ) {
        methods.init.apply( $this, args );
      } else {
        $.error( 'Method ' +  method + ' does not exist on jQuery.sldsComboBox' );
      }
    });
  };

})(jQuery);
