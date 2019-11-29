(function($, document, window, undefined) {

  window.TopButtonRowBuilder = {

    init: function( visibleLinkCount, containerId, menuPos )
    {
      var self = this, btnMarkup;
      self.$container = $('#' + containerId);
      self.$btnRow = $('#topButtonRow').hide();
      self.menuLeft= menuPos === 'left' ? true : false;
      self.visibleLinkCount = visibleLinkCount;
      self.links = self.$btnRow.find('input[type="button"]');

      //hide the Salesforce bottomButton Row as well
      $('#bottomButtonRow').hide();

      self.$container.hide()
      .append( buildMarkup.call(self) );
      self.$container.show();
      $('.lgnd-menu-btn').lgndMenuBtn();

    }

  }

  function buildMarkup()
  {
    var self = this,
        $btnContainer = $('<div></div>').addClass('lgnd-menu-btn').attr('data-menu-left', self.menuLeft),
        $menuCtrl = $('<a href="#"></a>').addClass('menu-ctrl').html( $('<i></i>').addClass('fa fa-caret-down') ),
        $menu = $('<ul></ul>');

    self.links.each( function(idx) {
      if( idx < self.visibleLinkCount )
      {
        $btnContainer.append( buildLinkFromInput(this) );
      }
      else
      {
        $menu.append( $('<li></li>').append( buildLinkFromInput(this) ) );
      }
    });

    $btnContainer.append( $menuCtrl ).append( $menu );
    return $btnContainer;

  }

  function buildLinkFromInput(input)
  {
    var $input = $(input),
        $link = $('<a href="#"></a>');

    $link.attr( 'onclick', $input.attr('onclick') );
    $link.attr( 'name', $input.attr('name') );
    $link.html( $input.attr('title') );
    return $link;
  }

})(jQuery, document, window);
