
(function( $ ){

  var privates = {
    constructHtml: function() {
      var self = this,
          options = self.data('options'),
          $results = $('<div></div>').attr('class', options.resultsContainerClass).append('<ul></ul>');
      $results.on('click', 'a', function(e) {
        e.preventDefault();
        options.selectHandler.call(self, $(this).data('objectId'), $(this).html(), $(this).parent('li').data('resultObject') );
        methods.close.apply(self);
      });
      self.attr('autocomplete', 'off').after($results);
    },

    initKeyHandler: function() {
      var self = this,
          options = self.data('options'),
          $list,
          $selectedLi,
          $items,
          $listContainer,
          selectedPos;
          //contHeight;
      self.on({
        keydown: function(e) {
          if(!$listContainer){
            $listContainer = self.next();
            $list = $listContainer.children('ul:first');
          }
          //contHeight = $listContainer.height();
          //capture "ENTER" key
          if( e.keyCode === 13 ) {
            e.preventDefault();
            if($selectedLi){
              var $link = $selectedLi.find('a:first');
              //$(this).val( $link.html() );
              $link.click();
            }
          }
          //capture "TAB" key
          if( e.keyCode === 9 ){
            methods.clearForm.call(self);
            methods.close.apply(self);
          }
          //capture down arrow
          if( e.keyCode === 40 ){
            e.preventDefault();
            if($selectedLi){
                $selectedLi.removeClass('selected');
                next = $selectedLi.next('li');
                if(next.length > 0){
                    if( next.hasClass('divider') )
                    {
                      next = next.next('li')
                    }
                    $selectedLi = next.addClass('selected');
                }else{
                   // $selectedLi = $items.eq(0).addClass('selected'); moves back to top
                   $selectedLi.addClass('selected');
                }
            }else{
                $selectedLi = $items.eq(0).addClass('selected');
            }
            privates.doQuickSelect.call(self, $selectedLi);
            selectedPos = $selectedLi.position().top;
            if(selectedPos <= 0){
              $listContainer.animate({'scrollTop': 0});
            }
            if($selectedLi.position().top >= $listContainer.height()){
              //we nee to scroll the list container down
              var newTop = $listContainer.scrollTop() + $selectedLi.outerHeight();
              $listContainer.scrollTop(newTop);
            }
          }// keycode 40
          //capture up arrow
          if( e.keyCode === 38){
            e.preventDefault();
            if($selectedLi)
            {
              $selectedLi.removeClass('selected');
              next = $selectedLi.prev('li');
              if(next.length > 0 && !next.hasClass('divider'))
              {
                $selectedLi = next.addClass('selected');
                selectedPos = $selectedLi.position().top;
              }
              else if( next.hasClass('divider') )
              {
                next = next.prev('li');
                if( next.length > 0 )
                {
                  $selectedLi = next.addClass('selected');
                  selectedPos = $selectedLi.position().top;
                }
                else
                {
                  $selectedLi.addClass('selected');
                  selectedPos = -1;
                }
              }
              else
              {
                $selectedLi.addClass('selected');
                selectedPos = $selectedLi.position().top;
              }
            }
            else
            {
              $selectedLi = $items.last().addClass('selected');
              selectedPos = $selectedLi.position().top;
            }
            privates.doQuickSelect.call(self, $selectedLi);

            if(selectedPos < 0){
              //we nee to scroll the list container down
              var newTop = $listContainer.scrollTop() - $selectedLi.outerHeight();
              $listContainer.scrollTop(newTop);
            }
          }// keyCode 38
        },
        keyup: function(e){
          var $this = $(this),
           text = $this.val(),
           $results = $this.next();

          if( [38, 40, 13, 9].indexOf( e.keyCode ) >= 0 ){
            return false;
          }
          if( e.keyCode === 27 || text === '' || text === undefined || text.length < 3){
            methods.clearForm.call(self);
            methods.close.apply(self);
          }
          else
          {
            $.when(options.searchFunction.call(self, text)).done(function(results) {
              console.log(results);
              if( results === false)
              {
                console.log('return false so search is busy');
                self.requiresRequery = true;
                // setTimeout( function() {
                //   $this.keyup();
                //   console.log('i waited 500ms, gonna fire a keyup event');
                // }, 500);
              }
              else if( results === null || $.isEmptyObject(results) )
              {
                console.log('empty results')
                methods.clearForm.call(self);
                methods.close.call(self);
              }
              else
              {
                console.log('valid results')
                $.when(privates.searchResultsHandler.call(self, results))
                .done( function() {
                  $items = $list.children('li');
                  $selectedLi = $list.find('.selected:first');
                  if( $selectedLi.length > 0 )
                  {
                    methods.open.call(self);
                  }
                  if( self.requiresRequery )
                  {
                    self.requiresRequery = false;
                    $this.keyup();
                  }
                });
              }

            });
          }
        }// keyup
      });// /comboBox click handler
    },

    searchResultsHandler: function(results) {
      var self = this,
          options = self.data('options'),
          defer,
          $cont = self.next().children('ul'),
          buildLineItem = function(data) {
            return $('<li></li>')
              .data('resultObject', data)
              .append(
                $('<a href="#"></a>').html( data[options.textFieldName] )
                  .data('objectId', data[options.idFieldName])
                  .attr('tabIndex', '-1')
                );
          };


      return $.Deferred( function() {
        defer = this;
        $cont.html('');
        if( !self.is(":focus") || results === null || $.isEmptyObject(results) )
        {
          methods.close.call(self);
        }
        else
        {
          if( options.multiResultType )
          {
            $.each(results, function( label, values) {
              $cont.append( $('<li></li>').html(label).addClass('divider') );
              $.each( values, function() {
                $cont.append( buildLineItem(this) );
              });
            });

          }
          else
          {
            $.each(results, function() {
              $cont.append( buildLineItem(this) );
            });
          }

          $cont.children('li:not(".divider")').first().addClass('selected');
          privates.doQuickSelect.call(self, $cont.children('li:first') );
        }
        defer.resolve();
      });
    },

    doQuickSelect: function($selectedLi){
      var self = this,
        options = this.data('options');
      if( options.quickSelectHandler != null && typeof(options.quickSelectHandler) === 'function'){
        options.quickSelectHandler.call(self, $selectedLi.data('resultObject'));
      }
    }
  },

  methods = {
     init : function( options ) {

        var self = this,
            $this,
            settings;

        settings = $.extend( {

          resultsContainerClass: 'comboBoxResults',
          idFieldName: 'Id',
          textFieldName: 'Text',
          multiResultType: false,
          searchFunction: function() {},
          selectHandler: function() {},
          quickSelectHandler: null,
          clearFormFields: null,
          onClose: function() {}
        }, options);

        self.data('options', settings);
        privates.constructHtml.apply(self);
        privates.initKeyHandler.apply(self);
    },
    open: function() {
      var self = this,
          $results = self.next(),
          r_left = self.position().left,
          r_top = self.position().top + self.outerHeight(),
          r_minWidth;

      if( self.hasClass('has-postfix') )
      {
        r_minWidth = self.closest('.row').outerWidth();
      }
      else
      {
        r_minWidth = self.outerWidth() -1;
      }
      $results.css({'top': r_top,
                'left': r_left,
                'min-width': r_minWidth,
                'max-width': r_minWidth})
      .scrollTop(0);
      if(!$results.hasClass('active')){
        $results.addClass('active').show();
        $('body').on('click.closeComboBox', function(e) {
          methods.close.apply(self);
          $(this).off('click.closeComboBox');
        });
      }
    },
    close: function() {
      var self = this,
        options = self.data('options');
      self.next().removeClass('active').hide().children('ul').html('');
      if( typeof(options.onClose === 'function') ){
        options.onClose.call(self);
      }

    },
    clearForm: function() {
      var self = this,
        options = self.data('options');
      if( options.clearFormFields != null && typeof(options.clearFormFields) === 'function')
      {
        options.clearFormFields();
      }
    }
  };

  $.fn.legendForceComboBox = function( method ) {
    var args = arguments;

    return this.each(function () {
      var $this = $(this);
      if ( methods[method] ) {
        methods[method].apply( $this, Array.prototype.slice.call( args, 1 ));
      } else if ( typeof method === 'object' || ! method ) {
        methods.init.apply( $this, args );
      } else {
        $.error( 'Method ' +  method + ' does not exist on jQuery.legendForceComboBox' );
      }
    });

  };

})( jQuery );


