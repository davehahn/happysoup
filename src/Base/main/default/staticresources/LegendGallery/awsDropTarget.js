(function ($, document, window, undefined){

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
    }

  }

  function AwsDropTarget(element, awsSettings, view_image_template, imageName)
  {
    this.target = $(element);
    this.awsSettings = awsSettings;
    this.view_image_template = view_image_template;
    this.imageName = imageName;
    this.init();

  }

  AwsDropTarget.prototype = {
    constructor : AwsDropTarget,

    init: function()
    {
      var self = this;
      self.setupSlider.call(self);
      self.dropHandlers.call(self);
      //initImageControls(self);

    }, // /init

    setupSlider: function()
    {
      var self = this,
        $sliderView = $('.slider-for'),
        $sliderNav =  $('.slider-nav');

      $sliderView.on('init reInit', function(e, slick) {
        slick.$slideTrack.find('.image-overlay').each( function(idx, ele) {
          var $ele = $(ele),
            wid = $ele.prev('img').width(),
            parentW = $ele.parent('.slick-slide').width(),
            shiftLeft = (parentW - wid) / 2;
          $ele.css({
           'width': wid,
           'left': shiftLeft + 'px'
          });
        });
      });

      // $sliderNav.on('reInit', function(e, slick) {
      //   console.log('slick nav reinitialized');
      // })

      this.$sliderView = $sliderView;
      this.$sliderNav = $sliderNav;

      $sliderView.slick({
        slidesToShow: 1,
        slidesToScroll: 1,
        arrows: false,
        fade: false,
        asNavFor : 'slider-nav'
      });

      $sliderNav.slick({
        asNavFor: '.slider-for',
        dots: true,
        infinite: false,
        arrows: false,
        centerMode: true,
        variableWidth: true,
        focusOnSelect: true
      });

    }, // /setupSlider


    resetSliderHeight: function()
    {
      var self = this;
      self.$sliderView.trigger('reInit', [self.$sliderView.slick('getSlick')]);
      self.$sliderNav.trigger('reInit', [self.$sliderNav.slick('getSlick')]);

    }, // /restSliderHeight
    dropHandlers: function()
    {
      var self = this;

      self.target.on( 'dragenter.aws-target', function(e) {
        e.stopPropagation();
        e.preventDefault();
        $(this).addClass('dropNow');
      })
      .on( 'dragover.aws-target', function(e) {
        e.stopPropagation();
        e.preventDefault();
      })
      .on( 'drop.aws-target', function(e) {
        e.preventDefault();

        var files = e.originalEvent.dataTransfer.files;
        self.handleDroppedFiles.call(self, files);
      });

      $(document).on('dragenter.aws-target', function (e) {
        e.stopPropagation();
        e.preventDefault();
      })
      .on('dragover.aws-target', function (e) {
        e.stopPropagation();
        e.preventDefault();
        self.target.removeClass('dropNow');
      })
      .on('drop.aws-target', function (e) {
          e.stopPropagation();
          e.preventDefault();
      });
    },// /dropHandlers

    handleDroppedFiles: function(files)
    {
      var self = this,
        imageType = /image.*/,
        uniqueFileName = function(fName) {
          var nameArry = fName.split('.');
          nameArry.splice(nameArry.length-1, 0, Date.now());
          return nameArry.join('.');
        };

      if( files.length > 1 )
      {
        self.target.removeClass('dropNow');
        LGND.alert('Too Many Files!', 'You tried to upload ' + files.length + ' images.  Please upload a single file only.');
      }
      else
      {
        if (files[0].type.match(imageType)) {
          self.imageData = {
            file: files[0],
            name: uniqueFileName(self.imageName) };
          self.uploadToAWS.call(self);
        } else {
          LGND.alert("File not supported!", "Please upload only image files");
          self.target.removeClass('dropNow');
        }

      }
    },// /handleDroppedFiles


    uploadToAWS: function()
    {
      var self = this,
        $dropZone = $('.drop-zone'),
        readFile = function(file) {
          var reader = new FileReader(),
            dfd = new $.Deferred();

          reader.onload = function() {
            var img = new Image;

            img.onload = function() {
              dfd.resolve(file, img);
            }
            img.src = reader.result;
          }
          reader.readAsDataURL(file);
          return dfd.promise();
        },
        imageUploadSuccess = function(imageData)
        {
          var cEvent = new CustomEvent('imageUploadSuccess',{ detail:{ imageData: imageData } , bubbles: true, cancelable: true });
          self.target[0].dispatchEvent(cEvent);
        };

      self.indicator = new LGND_CircleIndicator();

      $dropZone.addClass('busy');

      readFile( self.imageData.file )
      .then( function(file, img) {

        self.imageData.height = img.height;
        self.imageData.width = img.width;
        self.imageData.src = img.src;

        self.appendImage.call(self, img);
        $dropZone.removeClass('busy');

        //self.fakeUploadToAWS.call(self)
        self.sendFile.call(self)
        .then( function(a,b,c) {
          //self.indicator.remove();
          //$('.image-uploading').removeClass('image-uploading')
          //.find('.progress-container').remove();
          imageUploadSuccess(self.imageData);
        })
        .fail( function(a,b,c) {
          LGND.alert('Upload Falied', 'There was a problem uploading your image.<br />  Please contact your system administrator with the following error: <br /> " ' + c + ' "');
          self.$sliderView.slick('slickRemove', 0, 'removeBefore');
          self.$sliderNav.slick('slickRemove', 0, 'removeBefore');
          console.log( 'upload failed');
          console.log(a);
          console.log(b);
          console.log(c);
        })
        .always( function() {
          console.log('this fires always')
        });
      });

    },

    appendImage: function(img)
    {
      var self = this,
         $newImage = $('<div></div>').addClass('image-uploading');

      $newImage.append(img);
      $newImage = self.indicator.insertIn( $newImage );
      self.target.removeClass('dropNow');

      self.$sliderNav.slick('slickAdd', '<div><img src="'+img.src+'"></img</div>', 0, 'addBefore')
      self.$sliderView.slick('slickAdd', $newImage, 0, 'addBefore');
      self.$sliderNav.slick('slickGoTo', 0 , true);

      self.$newImageElement = $newImage;
    }, /* /appendImage */

    sendFile: function()
    {
      var self = this,
        indicator = self.indicator,
        createFormData = function(awsSettings, imageData)
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
        };

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

    }, /* /sendFile */

    fakeUploadToAWS: function()
    {
      var self = this,
        countdown = function(options) {
          var timer,
          instance = this,
          counter = 0,
          count = options.count || 10,
          updateStatus = options.onUpdateStatus || function () {},
          counterEnd = options.onCounterEnd || function () {};

          function incrementCounter() {
            updateStatus(counter);
            if (count === counter) {
              counterEnd();
              instance.stop();
            }
            counter++;
          }

          this.start = function () {
            clearInterval(timer);
            timer = 0;
            count = options.count;
            timer = setInterval(incrementCounter, 50);
          };

          this.stop = function () {
            clearInterval(timer);
          };
        },
        fakeFileUpload = function() {
          var dfd = new $.Deferred(),
              indicator = self.indicator,

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
    },/* /fakeUploadToAWS */

    destroy: function()
    {
      this.target.off('dragenter.aws-target dragover.aws-target drop.aws-target imageUploadSuccess');
      $(document).off('dragenter.aws-target dragover.aws-target drop.aws-target');
      setTimeout( function() {
        $('.slider-for').slick('unslick');
        $('.slider-nav').slick('unslick');
      }, 500 );
    }

  }

  window.AwsDropTarget = AwsDropTarget;

})(jQuery.noConflict(), document, window);
