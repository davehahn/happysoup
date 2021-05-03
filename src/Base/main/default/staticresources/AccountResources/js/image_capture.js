(function($, document, window, undefined) {

  function ImageCapture(awsSettings,objectId)
  {
    this.parentObjectId = objectId;
    this.imageContainer = $('.image-container:first');
    this.fileInput = $('#image');
    this.fileName = $('#fileName');
    this.engDesc = $("#engDesc");
    this.frDesc = $("#frDesc");
    this.selectButton = $('#getPhoto');
    this.saveBtn = $('#saveImage');
    this.isSF1 = (typeof(sforce) != 'undefined') && (sforce != null);
    this.AwsUploader = new AwsUploader(awsSettings, this.imageContainer);
    this.init();
  }

  ImageCapture.prototype = (function() {
    var handlers = {}, sfOne = {},
        uniqueFileName = function(fName) {
          var nameArry = fName.split('.');
          nameArry.splice(nameArry.length-1, 0, Date.now());
          return nameArry.join('.');
        },
        readImageFile = function(file) {
          var reader = new FileReader(),
            dfd = new $.Deferred();

          reader.onload = function() {
            var img = new Image;

            img.onload = function() {
              dfd.resolve(img);
            }
            img.src = reader.result;
          }
          reader.readAsDataURL(file);
          return dfd.promise();
        },
        readVideoFile = function(file) {
          console.log('reading video file');
          var reader = new FileReader(),
            dfd = new $.Deferred();

          reader.onload = function() {
            var vidEle = document.createElement("video"),
              srcEle = document.createElement("source");

            // vidEle.onload = function() {
            //   console.log('source element loaded');
            //   dfd.resolve(vidEle);
            // }


            console.log( reader.result );
            srcEle.type = file.type;
            srcEle.src = reader.result;
            vidEle.appendChild(srcEle)
            vidEle.load();
            dfd.resolve(vidEle);
          }
          reader.readAsDataURL(file);
          return dfd.promise();
        },
        createSalesForceRecord = function() {
          var self = this,
            dfd = new $.Deferred(),
            SF_ImageData = {
              File_Name: self.imageData.name,
              descriptions: {
                english: self.engDesc.val(),
                french: self.frDesc.val()
              },
              parentObjectId: self.parentObjectId,
              Bucket_Name: self.AwsUploader.awsSettings.aws_Bucket,
              Path: self.AwsUploader.awsSettings.aws_FileKey,
              Image_Width: self.imageData.width,
              Image_Height: self.imageData.height
            };
          self.AwsUploader.indicator.goCrazy("Creating SalesForce Record ...");
          Account_Ext.createGalleryImage( JSON.stringify(SF_ImageData), function(result, event) {
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
        };

    sfOne.closePublisher = function() {
      Sfdc.canvas.publisher.publish({name: "publisher.close", payload:{ refresh:"false"}});
    }
    sfOne.enable = function() {
      var self = this;
      Sfdc.canvas.publisher.publish( {
        name: "publisher.setValidForSubmit",
        payload:"true"
      });

      Sfdc.canvas.publisher.subscribe({name: "publisher.post",
        onData:function(e) {
          //This subscribe fires when the user hits
          //Submit in the publisher
          self.imageData.name = uniqueFileName( self.fileName.val() );
          self.AwsUploader.uploadFile( self.imageData );
        }
      });
    }
    sfOne.disable = function() {
      Sfdc.canvas.publisher.publish( {
        name: "publisher.setValidForSubmit",
        payload:"false"
      });
    }

    handlers.captureButtonInit = function()
    {
      var self = this;
      self.selectButton.on('click', function(e) {
        e.preventDefault();
        self.fileInput.focus().click();
      });
    }
    handlers.fileInputInit = function()
    {
      var self = this,
          imageType = /image.*/,
          videoType = /video.*/;

      self.fileInput.on('change', function(e) {
        var file = this.files[0];

        if(file)
        {
          self.imageData = {
            file: file
          }
          self.imageContainer.addClass('loading');
          sfOne.disable();

          if( file.type.match(imageType) )
          {
            readImageFile(file)
            .then(function(img) {
              self.imageData.height = img.height;
              self.imageData.width = img.width;
              self.imageData.src = img.src;
              if( self.imageContainer.hasClass('loaded') )
              {
                self.imageContainer.find('img').first().prop('src', img.src);
              }
              else
              {
                self.imageContainer.addClass('loaded').find('#getPhoto').append(img);
              }
              self.imageContainer.removeClass('loading');
              self.fileName.val( file.name );
              $('.detailFields').show();
              sfOne.enable.call(self);
            });
          }
          else if( file.type.match(videoType) )
          {
            readVideoFile(file)
            .then(function(vidEle) {
              console.log( vidEle );
              self.imageData.src = vidEle.src;
              if( self.imageContainer.hasClass('loaded') )
              {
                self.imageContainer.find('video').first().prop('src', vidEle.src);
              }
              else
              {
                self.imageContainer.addClass('loaded').find('#getPhoto').append(vidEle);
              }
              self.imageContainer.removeClass('loading');
              sfOne.enable.call(self);
            });
          }
          else
          {
            alert('This file type type is not currently supported. Image files only!');
          }
        }

      });
    }
    handlers.uploadCompleteInit = function()
    {
      var self = this;
      self.imageContainer.on('AwsUploadComplete', function() {
        console.log( 'Upload Complete, Now Save Record to SalesForce' );
        createSalesForceRecord.call(self)
        .then( function(result) {
          self.AwsUploader.indicator.remove();
          if( self.onComplete && $.isFunction( self.onComplete ) )
          {
            self.onComplete.call(result);
          }
          else
          {
            sfOne.closePublisher();
          }
        })
        .fail( function(message) {
          alert(message);
        });
      });
    }

    return {
      constructor: ImageCapture,
      init: function()
      {
        var self = this;
        $.each(handlers, function(name, method) {
          method.call(self);
        })
      }
    }
  })();

  window.ImageCapture = ImageCapture;

})(jQuery.noConflict(), document, window);
