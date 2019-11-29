if (typeof jQuery.aljs === "undefined") { throw new Error("Please include the ALJS initializer file") }

(function($) {

    var Tabs = function(el, settings) {
        this.$el = $(el);
        this.settings = settings;
        this.initTabs();
      };

    Tabs.prototype = {
        constructor: Tabs,
        initTabs: function() {
            // Bind buttons
            var self = this;
            var $tabButtons = $(self.settings.tabLinkClass);//this.$el.find('a[data-aljs-show]');
            var children = $(self.settings.tabItemClass, this.$el);
            var tabsObj = {
                self: self,
                children: children
            }

            $tabButtons.on('click', function(e) {
                e.stopPropagation();
                self.selectTab($(e.target).data('aljs-show'));
                $(this).trigger('selected.aljs.tab'); // Custom aljs event
                return false;
            });

            // Show first tab
            if (this.settings.defaultTabId === '' || $('#' + this.settings.defaultTabId).length === 0) {
                this.selectTab($tabButtons.first().data('aljs-show'));
            } else {
                this.selectTab(this.settings.defaultTabId);
            }

            children.keyup(tabsObj, this.processKeypress);
        },
        selectTab: function(tabId) {
            var self = this;
            self.$el.find(self.settings.tabItemClass)
                .removeClass('slds-active')
                .find(self.settings.tabLinkClass)
                .attr('tabindex', '-1')
                .attr('aria-selected', 'false');
            self.$el.find(self.settings.tabContentClass)
                .hide();
            self.$el.find('[data-aljs-show="' + tabId + '"]')
                .closest('li')
                .addClass('slds-active')
                .find(self.settings.tabLinkClass)
                .attr('tabindex', '0')
                .attr('aria-selected', 'true')
                .focus();
            this.$el.find('#' + tabId).show()
                .trigger('shown.aljs.tabcontent'); // Custom aljs event

            this.id = tabId;
            this.settings.onChange(this);
        },
        processKeypress: function(e) {
            var children = e.data.children;
            var length = $(children).length - 1;
            var selectedPos = $('.slds-active', $(children).parent()).index();
            var tabId;

            if (e.which == 37) { // Left arrow
                if (selectedPos == 0) {
                    tabId = $(children).eq(length).find('[data-aljs-show]').data('aljs-show');
                } else {
                    tabId = $(children).eq((selectedPos - 1)).find('[data-aljs-show]').data('aljs-show');
                }
                e.data.self.selectTab(tabId);
            } else if (e.which == 39) { // Right arrow
                if (selectedPos == length) {
                    tabId = $(children).eq(0).find('[data-aljs-show]').data('aljs-show');
                } else {
                    tabId = $(children).eq((selectedPos + 1)).find('[data-aljs-show]').data('aljs-show');
                }
                e.data.self.selectTab(tabId);
            }
        }
    };

    $.fn.tabs = function(options) {
        var tabsArguments = arguments;
        var internalReturn;

        var settings = $.extend({
            // These are the defaults
            defaultTabId: '',
            tabItemClass: '.slds-tabs--default__item, .slds-tabs--scoped__item',
            tabLinkClass: '.slds-tabs--default__link, .slds-tabs--scoped__link',
            tabContentClass: '.slds-tabs--default__content, .slds-tabs--scoped__content',
            onChange: function(obj) {},
            assetsLocation: $.aljs.assetsLocation
        }, typeof options === 'object' ? options : {});

        this.each(function() {
            var $this = $(this);
            var data = $this.data('aljs-tabs');

            if (!data) {
                var tabsData = new Tabs(this, settings);
                $this.data('aljs-tabs', (data = tabsData));
            }

            if (typeof options === 'string') {
                internalReturn = data[options](tabsArguments[1], tabsArguments[2]);
            }
        });

        if (internalReturn === undefined || internalReturn instanceof Tabs) {
            return this;
        }

        if (this.length > 1) {
            throw new Error('Using only allowed for the collection of a single element (' + option + ' function)');
        } else {
            return internalReturn;
        }
    }
}(jQuery));
