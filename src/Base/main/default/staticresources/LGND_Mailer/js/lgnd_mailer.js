(function($, document, window, undefined) {

  var handlers = {},
  LGND_Mailer = {

    init: function(objectId)
    {
      this.objectId = objectId;
      handlers.initTemplateSelect.call(this);
      handlers.initSendBtn.call(this);
    }
  };

  handlers.initTemplateSelect = function()
  {
    var mailer = this;

    $('#templateSelect').on('change', function(e) {
      e.preventDefault();
      var $wrapper = $('.wrapper'),
          templateId = $(this).val();
          //$ind = $('#indicator');

      $wrapper.addClass('busy');
      //$ind.show();
      fetchTemplate( templateId, mailer.objectId )
      .then( function( result )
      {
        $.each( result, function(k,v) {
          $('*[data-email-attr="' + k +'"]').val( decodeString(v) );
        });
        $wrapper.removeClass('busy');
        //$ind.hide();
      })
      .fail( function(message)
      {
        $wrapper.removeClass('busy');
        //$ind.hide();
        //alert(message);
      });
    });

  }

  handlers.initSendBtn = function()
  {
    var mailer = this;

    $('#sendEmail').on('click', function(e) {
      e.preventDefault();
      var formParams = {};
      $('.wrapper').addClass('busy');
      $('.emailFormField').each( function(indx, ele) {
        var $ele = $(ele);
        if( $ele.data('email-attr') === 'toAddresses' )
        {
          formParams[ $ele.data('email-attr') ] = $ele.val().split(',');
        }
        else
        {
          formParams[ $ele.data('email-attr') ] = $ele.val();
        }
      });
      sendEmail( formParams )
      .then( function() {
        if(sforce.one)
        {
          sforce.one.navigateToSObject(mailer.objectId);
        }
      })
      .fail( function(message) {
        $('.wrapper').removeClass('busy');
        alert(message);
      });
    });

  }

  function fetchTemplate(templateId, objectId)
  {
    var dfd = new $.Deferred();
    LGND_MailerController.templateChanged( templateId, objectId, function( result, event) {
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

  function sendEmail(data)
  {
    var dfd = new $.Deferred();
    LGND_MailerController.sendEmail(JSON.stringify(data), function(result, event) {
      if( event.status )
      {
        dfd.resolve();
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

  function decodeString(html) {
    var txt = document.createElement("textarea");
    txt.innerHTML = html;
    return txt.value;
  }

  window.LGND_Mailer = LGND_Mailer;

})(jQuery.noConflict(), document, window);
