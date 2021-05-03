(function ($) {

  var privates = {

    addBoxMarkup: function() {
      var self = this,
      options = self.data('options'),
      $box = $('#qEditContainer');
      console.log( options);

      if($box.length > 0) {
        return;
      }
      $box = $('<div></div>').attr('id', 'qEditContainer');
      $box.addClass('edit')
        // .append( $('<div />').attr('id', 'arrow-left'))
        // .append( $('<div />').attr('id', 'arrow-right'))
        .append($('<a>X</a>').attr({href: '#', id: 'qEditClose'}))
        .append($('<h1></h1>'))
        .append($('<div></div>').addClass('content'))
        .appendTo( options.parentElement );
      //$('body').append($('<style />').attr({id: 'dynamic-style', type: 'text/css'}));
    },

    clickHandler: function () {
      console.log('setting up click handler');
      var self = this,
        options = self.data('options'),
        buildForm,
        $form,
        $this;

      $(options.link).on('click.quickEdit', function(e) {
        console.log('link clicked');
        e.preventDefault();
         $this = $(this);

         $.when( methods.showIndicator.apply(self) ).done( function() {
          $.when( privates.addContent.apply(self) ).done ( function() {
            $.when( privates.positionBox.apply(self) ).done(
              methods.openBox.apply(self) );
          });
         });

        // reallyStupidCheck = function() {
        //   setTimeout(function () {
        //       if(typeof($form) !== 'undefined') {
        //          $('#qEditContainer .content').append($form);
        //          privates.positionBox.apply(self)
        //         privates.openBox.apply(self);
        //         return;
        //       }
        //       reallyStupidCheck()
        //     },30);
        // }
        //  $.when( privates.showIndicator.apply(self) ).done(function() {
        //     $form =  options.formBuilderFunction.call(self);
        //     reallyStupidCheck();
        //  })



        //build the form form external function and return it
        // buildForm = function() {
        //   return options.formBuilderFunction.call(self);
        // }
        // $.when( buildForm() ).done(function($form) {
        //   $('#qEditContainer .content').append($form);
        //   $.when ( privates.positionBox.apply(self) ).done(function () {
        //     reallyStupidCheck();

        //   });
        // })

      });

    },

    addContent: function() {
      var self = this,
        options = self.data('options'),
        $content,
        contentCheck;

      return $.Deferred( function() {
        d_self = this;

        // contentCheck = function() {
        //   setTimeout(function () {
        //     console.log('checking for content')
        //       if( !$('#qEditContainer .content').is(':empty') ) {
        //       console.log('I have content');
        //         d_self.resolve();
        //         return;
        //       }
        //       contentCheck()
        //     },30);
        // }


          if( typeof(options.content) === 'function' ) {
            $.when( options.content.call(self) ).done( function(result) {
              console.log(result)
              $('#qEditContainer .content').append(result)
             d_self.resolve();
            })
          }else if( typeof(options.content) === 'object'  && options.content instanceof jQuery) {
            $('#qEditContainer .content').append(options.content);
             d_self.resolve();
          }else {
            throw " 'content' needs to be either a jquery object to insert into the box or a function that returns a jQuery object";
          }


        // $.when( buildContent() ).done(function(content) {
        //    $content = content;
        //   $('#qEditContainer .content').append($content);
        //   contentCheck();
        // });

      });

    },

    positionBox: function() {
      console.log('positioning form');
      var self = this,
        options = self.data('options'),
        $box = $('#qEditContainer'),
        title = options.title,
        $link = options.link;

      return $.Deferred( function() {
        d_self = this;
        privates.addOverlay.apply(self);

        if(options.boxPos === 'left'){
          left = $link.offset().left;
          topOffset = $link.offset().top - (0.5 * $link.height()) - (0.5 * $box.height() );
          width = $box.outerWidth();
          //styles = document.getElementById("dynamic-style");
          //styles.innerHTML = "#qEditContainer:before {top: " + (topOffset) + "px} #qEditContainer:after {top: " + (topOffset +1) + "px}";
          $box.find('h1').html(title);
          $('#arrow-right').show();
          console.log('top = '  + topOffset);
          console.log('top position = ' + $link.position().top)
          console.log(' left = ' + left);
           /* the minus 36 is for
              12px of ponter arrow,
              16px for the indicator that was added
               and a little extra padding
          */
          $box.css({ top: topOffset, left: (left - width - 36)})
            .addClass('arrow-right');
        }
        if(options.boxPos === 'right'){
          offset = $link.offset(),
          leftOffset = offset.left + $link.width();
          topOffset = offset.top - (0.5 * $link.height()) - (0.5 * $box.height() );
          // styles = document.getElementById("dynamic-style");
          // styles.innerHTML = "#qEditContainer:before {top: " + (topOffset) + "px} #qEditContainer:after {top: " + (topOffset + 1 ) + "px}";
          $box.find('h1').html(title);
          // $('#arrow-left').css('top',  '120px').show();
          $box.css({ top: topOffset, left: leftOffset})
            .addClass('arrow-left');
        }
        d_self.resolve();
      });

    },



    addOverlay: function() {
      console.log('adding overlay');
      var self = this,
        $overlay = $('<div></div>');

      $overlay.addClass('overlay').appendTo( $('body') ).on('click', function () {
        methods.closeBox.apply(self);
      });

    },

    removeOverlay: function() {
      console.log('removing overlay');
      var self = this;
      $('.overlay').remove();
    }


  }; //privates


  var methods = {

    init: function(options) {

      var self = this,
        settings;

      settings = $.extend( {
        link: this,
        boxPos: 'left',
        content: null,
        title: '',
        parentElement: $('body'),
        onBoxOpen: function() {},
        onBoxClose: function() {}
      }, options);

      self.data('options', settings);

      privates.addBoxMarkup.apply(self);
      privates.clickHandler.apply(self);

    }, //init

    openBox: function() {
      console.log('opening box');
      var self = this,
        options = self.data('options');

      return $.Deferred( function () {
        d_self = this;
        $('#qEditContainer').show();
        $('#qEditClose').click(function(e) {
          e.preventDefault();
          methods.closeBox.apply(self);
        });
        methods.removeIndicator.apply(self);
        if( typeof(options.onBoxOpen) === 'function' ){
          options.onBoxOpen.call(self);
        }
        d_self.resolve();
      })

    }, //openBox,

    closeBox: function() {
      console.log('closing box');

      var self = this,
        options = self.data('options');
      $('#qEditContainer').removeClass('arrow-left arrow-right').hide()
         .find('.content').html('');
      $('.editActive').removeClass('editActive');
        //.closest('div.optionTableContainer').css('overflow', 'auto');
      privates.removeOverlay.apply(self);
      if( typeof(options.onBoxClose) === 'function' ){
        options.onBoxClose.call(self);
      }
    }, // closeBox

    showIndicator: function() {
      console.log('showing indicator');
      var self = this;
      return $.Deferred(function() {
        var self1 = this,
          options = self.data('options'),
        $spinner = $('<div></div>').attr('id', 'smallBarSpinner');
        $(options.link).css('visibility', 'hidden')
         .before($spinner);
         console.log('im done carry on');
        self1.resolve();
      })

    },  //showIndicator

    removeIndicator: function() {
      console.log('removing indicator');
      var self = this,
        options = self.data('options');
      $('#smallBarSpinner').remove();
      $(options.link).css('visibility', 'visible');
    } //removeIndicator

  };//methods



  $.fn.quickBox = function( method ) {
    var args = arguments;

    return this.each(function () {
      var $this = $(this);
      if ( methods[method] ) {
        methods[method].apply( $this, Array.prototype.slice.call( args, 1 ));
      } else if ( typeof method === 'object' || ! method ) {
        methods.init.apply( $this, args );
      } else {
        $.error( 'Method ' +  method + ' does not exist on jQuery.quickEdit' );
      }
    });
  };

})(jQuery);
