
(function( $, document, window, undefined ){

  var privates = {

    initFileExplorer: function() {
      var self = this,
          options = self.options;
      $('#'+options.openFileExporerButtonId ).on('click', function(e) {
        e.preventDefault();
        privates.initFileExporerInput.call( self );
      })
    },

    initFileExporerInput: function() {
      var self = this,
          options = self.options,
          $input = $('<input type="file" style="display:none" multiple></input>');

      self.$ele.append( $input );
      $input.on('change', function(e) {
        var files = e.target.files;
        $(this).remove();
        privates.handleDroppedFiles.call(self, files);
      });
      $input.click();
    },

    initHandlers: function() {
      var self = this;

      self.on('dragenter.drop2AWS', function (e) {
        e.stopPropagation();
        e.preventDefault();
        $(this).addClass('dropNow');
      });
      self.on('dragover.drop2AWS', function (e) {
        e.stopPropagation();
        e.preventDefault();
      });
      self.on('drop.drop2AWS', function (e) {
        $(this).removeClass('dropNow');
        e.preventDefault();
        var files = e.originalEvent.dataTransfer.files;
        console.log( files )
        //We need to send dropped files to Server
        privates.handleDroppedFiles.call(self, files);
      });
      $(document).on('dragenter.drop2AWS', function (e) {
        e.stopPropagation();
        e.preventDefault();
      });
      $(document).on('dragover.drop2AWS', function (e) {
        e.stopPropagation();
        e.preventDefault();
        self.removeClass('dropNow');
      });
      $(document).on('drop', function (e) {
          e.stopPropagation();
          e.preventDefault();
      });
    },

    offHandlers: function() {
      var self = this;

      self.off('.drop2AWS');
      $(document).off('.drop2AWS');
    },

    editDescription: function( link )
    {
      console.log( 'Description Link Clicked' );
      var $modal = $('#descriptionModal'),
          $eng = $('#engDesc'),
          $fr =  $('#frDesc'),
          status = $(link).data('status');

      $modal.find('h2').html('Add a description to ' + status.getFileName() );
      $eng.val(status.descriptions.english);
      $fr.val(status.descriptions.french);

      $('#preview').attr( 'src', status.imgSRC );
      $modal.foundation('reveal', 'open');

      $('#saveDesc').on('click', function(e) {
        e.preventDefault();
        status.descriptions.english = $eng.val();
        status.descriptions.french = $fr.val();

        if( $eng.val() != '' || $fr.val() != '' )
        {
          status.descriptionLink.addClass('edit').html("Edit Descriptions");
        }
        else if( status.descriptionLink.hasClass('edit') )
        {
          status.descriptionLink.removeClass('edit').html("Add Descriptions");
        }

        $(link).off('click');
        $modal.foundation('reveal', 'close');
      });
    },

    handleDroppedFiles: function(files){

      console.log(" begin processing dropped files");
      console.log( files.length );
      var self = this,
        filesContainer = $('#filesContainer'),
        options = self.options,
        key,
        fd,
        fileObj,

      createStatusbar = function(obj) {
        obj.activeUploadCount++;
        this.statusbar = $("<div class='statusbar'></div>");
        console.log( options );
        if( options.fullImagePreview )
        {
          filesContainer.addClass('full-image');
          this.thumbnail = $("<img></img>").appendTo( this.statusbar );
          this.filename = $("<div class='filename'><input type='text' class='slds-input'></input></div>").appendTo(this.statusbar);
          this.size = $("<div class='filesize'></div>").appendTo(this.statusbar);
          this.progressBar = $("<div class='progressBar'><div></div></div>").appendTo(this.statusbar);
          this.buttons = $("<div class='buttons'></div>")
          .append( $("<a href='#' class='removeBtn slds-button'>Remove</a>") ).appendTo(this.statusbar);
          if( options.allowDefault )
          {
            this.defaultCheckbox = $("<input type='checkbox' name='default-checkbox'></input><label class='slds-form-element__label'>Default Image?</label>")
            .appendTo( this.buttons );
          }
        }
        else
        {
          this.filename = $("<div class='filename'><input type='text' class='slds-input'></input></div>").appendTo(this.statusbar);
          this.size = $("<div class='filesize'></div>").appendTo(this.statusbar);
          this.progressBar = $("<div class='progressBar'><div></div></div>").appendTo(this.statusbar);
           this.buttons = $("<div class='buttons'></div>");
          if( options.allowDescriptions )
          {
            this.descriptionLink = $("<a href='#' class='descBtn slds-button'>Add Descriptions</a>").data('status', this)
            .appendTo( this.buttons );
          }
          if( options.allowDefault )
          {
            this.defaultCheckbox = $("<input type='checkbox' name='default-checkbox'></input><label class='slds-form-element__label'>Default Image?</label>")
            .appendTo( this.buttons );
          }
          this.buttons.append( this.descriptionLink )
          .append( $("<a href='#' class='removeBtn slds-button'>Remove</a>") ).appendTo(this.statusbar);
        }
        filesContainer.append(this.statusbar);
        this.descriptions = {};
        this.isDefault = false;

        this.setFileNameSize = function(name,size) {
          var sizeStr="";
          var sizeKB = size/1024;
          if(parseInt(sizeKB) > 1024) {
            var sizeMB = sizeKB/1024;
            sizeStr = sizeMB.toFixed(2)+" MB";
          } else {
            sizeStr = sizeKB.toFixed(2)+" KB";
          }
          this.filename.find('input').val(name);
          this.size.html(sizeStr);
        }
        this.setUploading = function() {
          this.statusbar.addClass('uploading');
        }
        this.setupImage = function(img){
          this.imageWidth = img.width;
          this.imageHeight = img.height;
          this.imgSRC = img.src;
          console.log( this.thumbnail );
          if( this.thumbnail )
          {
            this.thumbnail.attr('src',img.src);
            console.log( this.thumbnail.height() );
            this.buttons.css({top: (this.thumbnail.height() - 26) +'px'});
          }
        }
        this.setProgress = function(progress)  {
          var progressBarWidth =progress*this.progressBar.width()/ 100;
          this.progressBar.find('div').animate({ width: progressBarWidth }, 10);
          if(parseInt(progress) >= 100) {
            this.buttons.hide();
          }
        }
        this.setDefault = function() {
          var status = this;
          status.buttons.find('input[type="checkbox"]').change( function(e) {
            var th = $(this),
                checked = th.is(':checked'),
                name = th.prop('name');
            if( checked )
              $(':checkbox[name="' + name + '"]').not( $(this) ).prop('checked', false).change();

            status.isDefault = checked;
          })
        }
        this.getFileName = function() {
          return this.filename.find('input').val();
        }
        this.setRemove = function() {
          var status = this, sb = this.statusbar;
          status.buttons.find('a.removeBtn').on('click', function(e) {
            e.preventDefault();
            removeFile(status);
          });
        }
        this.setAbort = function(jqxhr) {
          var status = this;
          this.buttons.find('a.removeBtn').off('click').html('Abort').on('click', function() {
            jqxhr.abort();
            //sb.hide();
          });
        }
        this.setProgressText = function(text) {
          this.progressBar.find('div').html(text);
        }
        this.initDescLink = function() {
          this.descriptionLink.on('click', function(e) {
            e.preventDefault();
            options.editDescriptionClickHandler.call(self, this);
            // var $modal = $('#descriptionModal'),
            //   $eng = $('#engDesc'),
            //   $fr =  $('#frDesc'),
            //   status = $(this).data('status');

            // $modal.find('h2').html('Add a description to ' + status.getFileName() );
            // $eng.val(status.descriptions.english);
            // $fr.val(status.descriptions.french);

            // $('#preview').attr( 'src', status.imgSRC );
            // $modal.foundation('reveal', 'open');

            // $('#saveDesc').on('click', function(e) {
            //   e.preventDefault();
            //   status.descriptions.english = $eng.val();
            //   status.descriptions.french = $fr.val();

            //   if( $eng.val() != '' || $fr.val() != '' )
            //   {
            //     status.descriptionLink.addClass('edit').html("Edit Descriptions");
            //   }
            //   else if( status.descriptionLink.hasClass('edit') )
            //   {
            //     status.descriptionLink.removeClass('edit').html("Add Descriptions");
            //   }

            //   $(this).off('click');
            //   $modal.foundation('reveal', 'close');
           // });

          });
        }
      },

      removeFile = function(status) {
        privates.removeFileFromList.call(self, status);
      },

      getDimensions = function(file) {
        var self, fr;
        return $.Deferred( function() {
          self = this;
          fr = new FileReader;
          if( file.type.indexOf('image') >= 0 ){
            fr.onload = function() { // file is loaded
              var img = new Image;

              img.onload = function() {
                self.resolve(file, img);
              }
              img.src = fr.result; // is the data URL because called with readAsDataURL
            }
            fr.readAsDataURL(file);
          } else {
            self.resolve(file);
          }
        });
      },

      fileValid = function(file){
        if(file.type){
          if(options.fileTypeOnly === null){
            return true;
          }
          if( file.type.indexOf( options.fileTypeOnly) >= 0 ){
            return true;
          }
        }
        return false;
      },

      processAll = function(files) {
        var defer, valid = 0, complete=0;
        return $.Deferred( function () {
          defer = this;

          for (var i = 0; i < files.length; i++) {
            if( fileValid( files[i] ) ){
              valid ++;

              $.when( getDimensions(files[i]) ).done( function(file, img) {
                fileObj = new Object();

                var status = new createStatusbar(self); //Using this we can set progress.
                var timeStamp = new Date().getTime().toString();
                var nameSplit = file.name.split('.');
                var fileExt = nameSplit[ nameSplit.length - 1 ];
                timeStamp += '.';
                timeStamp += fileExt;
                status.setFileNameSize( timeStamp, file.size);
                status.setRemove();
                if( options.allowDescriptions )
                  status.initDescLink();
                if( options.allowDefault )
                  status.setDefault();
                //status.loadThumbnail(file);
                if(img){
                  console.log("Setting image dimensions of " + img.width + 'x' + img.height);
                  status.setupImage(img);
                }
                //fileObj.formData = fd;
                fileObj.file = file;
                fileObj.status = status;
                self.fileMap.push(fileObj);

                complete++;

                if( valid === complete) {
                   if( !self.submitButton.is(':visible') ) privates.activateSubmitButton.apply(self);
                   defer.resolve();
                }
              });

            }

          } // end for

        }); // end Deferred

      };

       console.log(self)
      $(self).addClass('processing');

      $.when( processAll(files) ).done( function() {
        console.log("finished processing dropped files");
        options.onFileChange.call( self, self.activeUploadCount );
        $(self).removeClass('processing');
      });

    },

    removeFileFromList: function(status, removeStatusBar){
      var self = this,
        fileMap = self.fileMap;
      removeStatusBar = typeof removeStatusBar === 'undefined' ? true : removeStatusBar;
      for(var i=0;i < self.fileMap.length; i++){
        if( self.fileMap[i].status === status){
          self.fileMap.splice(i, 1);
          self.fileCount--;
          if(removeStatusBar)
          {
            status.statusbar.animate({height:0}, 300, function() { $(this).remove();});
            self.activeUploadCount --;
          }
        }
      }
      if(self.fileMap.length === 0){
        privates.deactivateSubmitButton.call(self);
      }
      self.options.onFileChange.call( self, self.activeUploadCount );
    },

    activateSubmitButton: function() {
      var self = this;
        self.submitButton.show().on('click', function(e) {
          e.preventDefault();
          if( !$(this).hasClass('active') ){
            $(this).addClass('active');
            privates.processFiles.apply(self);
          }
        });
    },

    deactivateSubmitButton: function() {
      var self = this;
      self.submitButton.removeClass('active')
      .off('click')
      .hide();
    },

    processFiles: function() {
      var self = this,
        fileMap = self.fileMap;
      for(var i=0;i< fileMap.length;i++){
        privates.sendFileToServer.call(self, fileMap[i].file, fileMap[i].status);
      }
    },

    sendFileToServer: function(file, status){
      status.buttons.find('.descBtn').fadeOut();

      var self = this,
        options = self.options,
        jqXHR,
        formData,
        key;

      privates.offHandlers.apply(self);
      formData = new FormData();
      key =  options.aws_FileKey + '/' + status.getFileName();
      formData.append('key', key);
      formData.append('acl', options.aws_Acl);
      formData.append('Content-Type', file.type);
      formData.append('AWSAccessKeyId', options.aws_AccessKey);
      formData.append('policy', options.aws_Policy)
      formData.append('signature', options.aws_Signature);
      formData.append('file', file);
      // key =  options.aws_FileKey + status.getFileName();
      // formData.append('key', key);

      jqXHR=$.ajax({
              xhr: function() {
              var xhrobj = $.ajaxSettings.xhr();
              status.setUploading();
              if (xhrobj.upload) {
                      xhrobj.upload.addEventListener('progress', function(event) {
                          var percent = 0;
                          var position = event.loaded || event.position;
                          var total = event.total;
                          if (event.lengthComputable) {
                              percent = Math.ceil(position / total * 100);
                          }
                          //Set progress
                          status.setProgress(percent);
                      }, false);
                  }
              return xhrobj;
          },
        url: options.uploadUrl,
        type: "POST",
        contentType:false,
        processData: false,
        cache: false,
        data: formData,
        error: function(a,b,c){
          console.log(a);
          console.log(b);
          console.log(c);
          self.activeUploadCount--;
          if(b === 'abort'){
            console.log("we aborted");
            privates.removeFileFromList.call(self, status);
          } else {
            status.progressBar.addClass('error');
            status.setProgressText(b +": " + c);
            privates.removeFileFromList.call(self, status, false);
          }
          if(self.activeUploadCount === 0 ){
            privates.deactivateSubmitButton.apply(self);
          }
        },
        success: function(){
          console.log('finished uploading ' + status.getFileName());
          status.progressBar.addClass('stage2');
          status.setProgressText('Almost Complete! Processing ....');
          status.setProgress(100);
          //create the SalesForce Record Here
          options.onUploadComplete.call(self,
                                        status.getFileName(),
                                        status.isDefault,
                                        status.descriptions,
                                        status.imageWidth,
                                        status.imageHeight )
          .then(
            function() {
              self.activeUploadCount--;
              self.options.onFileChange.call( self, self.activeUploadCount );
              status.progressBar.removeClass('stage2').addClass('complete');
              status.setProgressText('Complete');
              status.statusbar.slideUp();
              if(self.activeUploadCount === 0 ){
                privates.initHandlers.apply(self);
                options.onAllComplete();
                self.fileMap = [];
                privates.deactivateSubmitButton.apply(self);
              }
            },
            function(err) {
              alert(err);
            }
          );
          // $.when(options.onUploadComplete.call(self, status.getFileName(), status.descriptions, status.imageWidth, status.imageHeight )).done(function() {
          //   self.activeUploadCount--;
          //   status.progressBar.removeClass('stage2').addClass('complete');
          //   status.setProgressText('Complete');
          //   status.statusbar.slideUp();
          //   if(self.activeUploadCount === 0 ){
          //     privates.initHandlers.apply(self);
          //     options.onAllComplete.call(self);
          //     self.fileMap = [];
          //     privates.deactivateSubmitButton.apply(self);
          //   }
          // })
        }
      });

      status.setAbort(jqXHR);
    }

  },


  methods = {
     init : function( options ) {

      var self = this,
          $this,
          settings;

      settings = $.extend( {
        aws_FileKey: '',
        aws_Acl: '',
        aws_AccessKey: '',
        aws_Policy: '',
        aws_Signature: '',
        submitButtonId: 'submitButton',
        fileTypeOnly: null,
        uploadUrl: null,
        openFileExporerButtonId: null,
        allowDescriptions: true,
        allowDefault: false,
        fullImagePreview: false,
        editDescriptionClickHandler: function(link) {
          privates.editDescription.call(self, link);
        },
        onUploadComplete: function() { return Promise.resolve() },//$.Deffered( function() {this.resolve(); }); },
        onAllComplete: function() {},
        onFileChange: function(){}
      }, options);

      self.options = settings;
      if( self.options.uploadUrl === null ){
        throw( 'LegendForceDropToAWS ERROR = uploadUrl was not specified and is required');
      }
      self.$ele = $(this);
      self.activeUploadCount = 0;
      self.submitButton = $('#' +self.options.submitButtonId );
      self.fileMap = [];

      if( self.options.openFileExporerButtonId !== null )
        privates.initFileExplorer.call(self);
      self.processFiles = function() {
        privates.processFiles.call(self);
      };
      self.addImage = function()
      {
        privates.initFileExporerInput.call( self );
      };
      self.destroy = function()
      {
        privates.deactivateSubmitButton.call( self );
        privates.offHandlers.call( self );
        $('#'+settings.openFileExporerButtonId ).off('click');
        $(this).removeData('pluginData');
      };
      $(this).data('pluginData', self);
      privates.initHandlers.apply(self);

    },

    addImage: function()
    {
      $(this).data('pluginData').addImage();
    },

    doUpload: function()
    {
      $(this).data('pluginData').processFiles();
    },

    destroy: function()
    {
      $(this).data('pluginData').destroy();
    }

  };

  $.fn.legendForceDropToAWS = function( method ) {
    var args = arguments;

    return this.each(function () {
      var $this = $(this);
      if ( methods[method] ) {
        methods[method].apply( $this, Array.prototype.slice.call( args, 1 ));
      } else if ( typeof method === 'object' || ! method ) {
        methods.init.apply( $this, args );
      } else {
        $.error( 'Method ' +  method + ' does not exist on jQuery.legendForceDropToAWS' );
      }
    });

  };

})( jQuery, document, window );


