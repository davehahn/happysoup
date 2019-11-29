(function($, document, window, undefined)
{

  window.LGND = {

    HandlebarsHelpers: {

      templateLoader: function(templateMap)
      {
        var requests = [],
         dfd = new $.Deferred(),
         tmpls = {};
        $.each(templateMap, function(name, url) {
          requests.push($.ajax({
            url: url,
            cache: true,
            success: function(data) {
              tmpls[name] = Handlebars.compile(data);
            }
          }));
        });

        $.when.apply(undefined, requests).done(function() {
          dfd.resolve(tmpls);
        });

        return dfd.promise();
      }

    }// /HandleBarsHelpers

  };


})
(jQuery.noConflict(), document, window);




function confirmCancel() {
   var isCancel = confirm("Are you sure you wish to cancel?");
   if (isCancel) return true;

   return false;
}

function determineUI(theme)
{
  switch( theme )
  {
    case 'Theme3':
      return 'classic';
      break;
    case 'Theme4d':
      return 'lex';
      break;
    case 'Theme4t':
      return 'sf1';
      break;
    default:
      alert('Can Not Determine Your User Experience!');
  }
}
