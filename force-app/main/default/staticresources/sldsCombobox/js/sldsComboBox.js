/*!
 * jQuery lightweight plugin boilerplate
 * Original author: @ajpiano
 * Further changes, comments: @addyosmani
 * Licensed under the MIT license
 */

// the semi-colon before the function invocation is a safety
// net against concatenated scripts and/or other plugins
// that are not closed properly.
;(function ( $, window, document, undefined ) {

    // undefined is used here as the undefined global
    // variable in ECMAScript 3 and is mutable (i.e. it can
    // be changed by someone else). undefined isn't really
    // being passed in so we can ensure that its value is
    // truly undefined. In ES5, undefined can no longer be
    // modified.

    // window and document are passed through as local
    // variables rather than as globals, because this (slightly)
    // quickens the resolution process and can be more
    // efficiently minified (especially when both are
    // regularly referenced in your plugin).

    // Create the defaults once
    var pluginName = "sldsComboBox",
        defaults = {
            sldsAssetLocation: null,
            templateAssetLocation: null,
            dropdownPos: 'left',
            selectOptions: [],
            matchWidth: false,
            onSelectOpen: function(){},
            onSelectClose: function(){}
        };

    // The actual plugin constructor
    function SldsComboBox( element, options ) {
        var privates = {
            initialize: function()
            {
              var self = this;
              self._data.isOpen = false;
              self._data.width = self.$element.outerWidth();
              self.$element.parent().wrap("<div class='slds-picklist'></div>");
              //load the select options list box template
              $.ajax({
                url: options.templateAssetLocation + '/templates/_select-menu.tpl.html',
                cache: true,
                success: function(data) {
                  self._data.optionsContainer_hb = Handlebars.compile(data);
                  privates.initHandlers.call(self);
                }
              });
              //add a handlebars helper to set active class on select list options
              Handlebars.registerHelper('selectOptionClass', function( option_value , current_value) {
                var klass = 'slds-dropdown__item';
                if( option_value == current_value )
                {
                  klass += ' slds-is-selected';
                }
                return new Handlebars.SafeString( klass );
              });
            },
            initHandlers: function()
            {
              var self = this,
                  $element = self.$element;
              $element.prev('svg')
              .css('cursor', 'pointer')
              .on('click', function(e) {
                e.preventDefault();
                e.stopPropagation();
                if( !self._data.isOpen )
                {
                  privates.openSelect.call(self).then( function() {
                    var $container = $element.parent().next(),
                        $ul = $container.children('ul:first'),
                        $eleToScroll,
                        $selected = $container.find('.slds-is-selected');
                    if($selected)
                    {
                      if( $container.css('overflow-y') === 'auto' )
                      {
                        $eleToScroll = $container;
                      }
                      if( $ul.css('overflow-y') === 'auto' )
                      {
                        $eleToScroll = $ul;
                      }
                      if( $eleToScroll !== null )
                      {
                        $eleToScroll.scrollTop( ($selected.index() - 2) * $selected.outerHeight() );
                        // $eleToScroll.animate( {
                        //   'scrollTop': ($selected.index() - 2) * $selected.outerHeight()
                        // }, 500);
                      }
                    }
                    $element.parent().next().find('.slds-combobox-select-option').on('click', function(e) {
                      e.preventDefault();
                      self._current_value = $(this).data('select-value');
                      $element.val( self._current_value );
                      privates.closeSelect.call(self);
                    });
                  });
                }
                else
                {
                  privates.closeSelect.call(self);
                }
              });
            },
            openSelect: function()
            {
              var dfd = new $.Deferred(),
                  self = this
                  content = {};

              content.selectOptions = self.options.selectOptions;
              content.dropdownPos = self.options.dropdownPos;
              content.current_value = self._current_value;
              if( self.options.matchWidth )
              {
                content.eleStyle = "max-width:" + self._data.width +"px; min-width: " + self._data.width +"px;"
              }
              self.$element.parent()
              .after( self._data.optionsContainer_hb(content) );
              self._data.isOpen = true;
              $('body').on('click.sldsComboboxClose', function(e) {
                e.preventDefault();
                privates.closeSelect.call(self);
              });
              dfd.resolve();
              return dfd.promise();
            },
            closeSelect: function()
            {
              this.$element.parent().next().remove();
              $('body').off('click.sldsComboboxClose');
              this._data.isOpen = false;
            }
          };

        this.element = element;
        this.$element = $(element);
        if( this.$element.data('dropdown-pos') )
        {
          options.dropdownPos = this.$element.data('dropdown-pos');
        }
        // jQuery has an extend method that merges the
        // contents of two or more objects, storing the
        // result in the first object. The first object
        // is generally empty because we don't want to alter
        // the default options for future instances of the plugin
        this.options = $.extend( {}, defaults, options) ;
        this._data = {};
        this._defaults = defaults;
        this._current_value = this.$element.val();
        this._name = pluginName;
        privates.initialize.call(this);
    }

    SldsComboBox.prototype = {

        init: function() {
            // Place initialization logic here
            // You already have access to the DOM element and
            // the options via the instance, e.g. this.element
            // and this.options
            // you can add more functions like the one below and
            // call them like so: this.yourOtherFunction(this.element, this.options).
        },

        yourOtherFunction: function(el, options) {
            // some logic
        }
    };

    // A really lightweight plugin wrapper around the constructor,
    // preventing against multiple instantiations
    $.fn[pluginName] = function ( options ) {
        return this.each(function () {
            if (!$.data(this, "plugin_" + pluginName)) {
                $.data(this, "plugin_" + pluginName,
                new SldsComboBox( this, options ));
            }
        });
    };

})( jQuery, window, document );
