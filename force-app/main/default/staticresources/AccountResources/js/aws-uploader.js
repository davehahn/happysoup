(function($, document, window, undefined) {

  function LGND_CircleIndicator(message)
  {
    this.message = typeof(message) === 'undefined' ? 'Uploading...' : message;
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
        $message = $('<span></span>').html(self.message);
        $percent_value = $('<span></span>')

      $progress.append( $progress_fill );
      $percent.append( $percent_wrapper.append( $message ).append( $percent_value ) );
      $wrapper.append( $progress ).append( $percent );
      $container.append( $wrapper );
      //self.element.addClass('progress-pie-chart').append($progress)
      //  .append($percent);
      self.element = $container;
      self.wrapper = $wrapper;
      self.gauge = $progress_fill;
      self.message = $message;
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
      self.numeric_output.html(percent+'%');
    },
    remove: function()
    {
      this.element.remove();
    },
    insertIn: function( $element )
    {
      return $element.append( this.element );
    },
    goCrazy: function(message)
    {
      var self = this,
          myCounter = new countdown({
            count: 100,
            infinite: true,
            onUpdateStatus: function(sec){
              self.updateValue(sec);
            },
            onCounterEnd: function() {
              self.element.toggleClass('invert');
            }
          });
      self.numeric_output.hide();
      self.message.html(message);
      //self.$message.html('Creating SalesForce Record');
      myCounter.start();
    }
  }

  function AwsUploader(awsSettings, containerEl) {
    this.awsSettings = awsSettings;
    this.containerEl = containerEl;
    this.indicator = new LGND_CircleIndicator();
    this.init();
  }

  AwsUploader.prototype = (function() {
    var createFormData = function(awsSettings, imageData)
        {
          var formData = new FormData();

          formData.append('key', awsSettings.aws_FileKey + '/' + imageData.name);
          formData.append('acl', awsSettings.aws_Acl);
          formData.append('Content-Type', imageData.file.type);
          formData.append('AWSAccessKeyId', awsSettings.aws_AccessKey);
          formData.append('policy', awsSettings.aws_Policy);
          formData.append('signature', awsSettings.aws_Signature);
          formData.append('file', imageData.file);
          return formData;
        },
        uploadToAws = function() {
          var self = this,
            indicator = self.indicator;

          return $.ajax({
            xhr: function() {
              var xhrobj = $.ajaxSettings.xhr();
              if(xhrobj.upload)
              {
                xhrobj.upload.addEventListener('progress', function(event) {
                  var percent = 0,
                   position = event.loaded || event.position,
                   total = event.total;
                  if (event.lengthComputable) {
                      percent = Math.ceil(position / total * 100);
                  }
                  //Set progress
                  indicator.updateValue(percent);
                }, false);
              }
              return xhrobj;
            },
            url: self.awsSettings.uploadUrl,
            type: 'POST',
            contentType: false,
            processData: false,
            cache: false,
            data: createFormData(self.awsSettings, self.imageData)
          });
        },

        imageUploadSuccess = function(imageData,container) {
          var cEvent = new CustomEvent('AwsUploadComplete',{ detail:{ imageData: imageData } , bubbles: true, cancelable: true });
          container.dispatchEvent(cEvent);
        };

    return {
      constructor: AwsUploader,
      init: function() {
      },

      uploadFile: function(imageData)
      {
        var self = this;

        self.imageData = imageData;
        self.indicator.insertIn( self.containerEl );
        //self.indicator.goCrazy('Creating SalesForce Record');
        uploadToAws.call(self)
        .then( function(a,b,c) {
          imageUploadSuccess( self.imageData, self.containerEl[0] );
        })
        .fail( function(a,b,c) {
          alert('FAIL');
          console.log(a);
          console.log(b);
          console.log(c);
        });

        // fakeUploadToAWS( self.indicator ).then( function() {
        //   imageUploadSuccess( {fileName: 'fakeFile.jpg'}, self.containerEl[0] );
        // })
      }
    }

  })();

  function countdown(options) {
    var timer,
        instance = this,
        counter = 0,
        count = options.count || 10,
        infinite = options.infinite || false,
        updateStatus = options.onUpdateStatus || function () {},
        counterEnd = options.onCounterEnd || function () {};

    function incrementCounter() {
      updateStatus(counter);
      if (count === counter) {
        counterEnd();
        if( infinite )
        {
          counter = 0;
        }
        else
        {
          instance.stop();
        }
      }
      counter++;
    }

    this.start = function () {
      clearInterval(timer);
      timer = 0;
      count = options.count;
      timer = setInterval(incrementCounter, 5);
    };

    this.stop = function () {
      clearInterval(timer);
    };
  }

  function fakeUploadToAWS(indicator)
  {
    var fakeFileUpload = function() {
        var dfd = new $.Deferred(),

            myCounter = new countdown({
              count: 100,
              onUpdateStatus: function(sec){
                indicator.updateValue(sec);
              },
              onCounterEnd: function() {
                indicator.remove();
                dfd.resolve();
              }
            });
        myCounter.start();
        return dfd.promise();
      };
    return fakeFileUpload();
  }

  window.AwsUploader = AwsUploader;

})(jQuery.noConflict(), document, window);
