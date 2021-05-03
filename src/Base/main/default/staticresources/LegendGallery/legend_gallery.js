/*
LegendGallery.init({
  SF_parentId: '{!product.Id}',
  images_per_page: parseInt("{!imageLimit}"),
  $indicator: $j('#ajaxInd'),
  $header: $j('.headerNav').first(),
  $container: $j('.photo_container:first'),
  $overlay: $j('#overlay'),
  row_grid_options: {
    minMargin: 10,
    maxMargin: 25,
    itemSelector: ".marketing_image",
    resize: true
  },
});

*/
(function($, window, document, undefined){

  var calcWidth = function(oH, oW){
        return Math.round( (oW * ( 200 / oH)) );
      };

  window.LegendGallery = {

    init: function( config )
    {
      this.awsSettings = config.awsSettings;
      this.SF_parentId = config.SF_parentId;
      this.default_image_id = config.defaultImageId;
      this.images_per_page = config.images_per_page;
      this.indicator = config.indicator;
      this.header = config.header;
      this.container = config.container;
      this.containerHeight = config.containerHeight;
      this.overlay = config.overlay;
      this.viewer = config.viewer;
      this.row_grid_options = config.row_grid_options;
      this.imageData = {};
      this.pagination_offset = 0;
      this.zoomable = config.zoomable;
      this.selectable = config.selectable;
      this.fetchImagesFunction = config.retrieveImages;
      this.onSelected = config.onSelected;
      this.onUnSelected = config.onUnSelected;
      this.cache();
      this.compile_templates();
      this.bind_events();
      this.initialize();
    },

    cache: function()
    {
      this.$indicator = $(this.indicator);
      this.$header = $(this.header);
      this.headerHeight = this.$header.offset().top;
      this.$container = $(this.container);
      this.$overlay = $(this.overlay);
      this.$viewer = $(this.viewer);
    }, //cache

    compile_templates: function() {
      var self = this;

      self.HDLBRS_Image_Version_View_template = Handlebars.compile( $('#image_version_view').html() );
      //Helper to display the view(large) versions of the Images in the Image Version function
      // imageVersion = Salesforce Marketing_Image_Version__c object
      Handlebars.registerHelper('imageVersionView', function(imageVersion) {
        return new Handlebars.SafeString( self.HDLBRS_Image_Version_View_template( imageVersion ) );
      });

      //helper to calculate the dimensions of the image and image_container
      //this is required for jQueryRowGrid to function properly
      Handlebars.registerHelper('boxWidth', function(s3Object) {
        return calcWidth(s3Object.Image_Height, s3Object.Image_Width) +"px";
      });

      Handlebars.registerHelper('containerClass', function(s3Object) {
        return self.default_image_id != '' && s3Object.GalleryImageId.indexOf(self.default_image_id) > -1 ?
          "gallery_image defaultImage" :
          "gallery_image";
      });

      Handlebars.registerHelper('overlayClass', function() {
        return self.zoomable ? 'selectedOverlay zoomable' : 'selectedOverlay';
      });

      Handlebars.registerHelper('selectLink', function(imageWrapper) {
        if(self.selectable)
        {
          return new Handlebars.SafeString('<a class="selectImage" data-image-id="' + imageWrapper.GalleryImageId + '"><i class="fa fa-check-square-o"></i></a>');
        }
        return '';
      });

      Handlebars.registerHelper('toDateString', function(ms) {
        var d = new Date(ms);
        return new Handlebars.SafeString(d.toDateString());
      })

      Handlebars.registerHelper('activeImage', function(awsId){
        var klassString = awsId === self.Zoomer.active_image_id ? 'active-image' : '';
        return new Handlebars.SafeString(klassString);
      });

      //the "x"px x 200px image thumb template
      self.HDLBRS_thumb_template =  Handlebars.compile( $('#thumbTemplate').html() );
    }, //complie_templates

    initialize: function()
    {
      var self = this,
          $cont = $(self.container),
          addMoreImages = function()
          {
            var runningW = 0,
                rows = 0,
                maxW = self.$container.width();

            $('.gallery_image').each(function( i,ele ) {
              runningW += $(ele).width();
              if( runningW > maxW )
              {
                rows += 1;
                runningW = $(ele).width();
              }
            });
            console.log(rows)
            return ( rows * 200 ) < self.containerHeight;
          };

      $cont.css('height', ( self.containerHeight ) +'px');

      $.when( self.fetchImages() ).done( function(images){
        if( Object.keys(images).length > 0 ){
          $.when( self.insertImages(images) ).done(function(){
            if( addMoreImages() ){
              self.pagination_offset += self.images_per_page;
              self.initialize();
              return false;
            }
          });
        }

       self.$container.rowGrid(self.row_grid_options);
      });
    }, //initialize

    bind_events: function()
    {
      var self = this;

      self.$container.on('scroll', function() {self.handleWindowScroll.apply(self);});
      //gallery thumb image click event (show viewer)
      if( self.zoomable )
      {
        self.$container.on('click', self.row_grid_options.itemSelector + ':not(.selected) > .selectedOverlay', function(e) {
          e.preventDefault();
          self.Zoomer.init({
            super: self,
            link: $(this).prev()
          })
        });

        self.$overlay.on('click', function(e){
          self.Zoomer.close_viewer();
        });
      }
      //If the image is selectable
      if( self.selectable )
      {
        self.$container.on('click', self.row_grid_options.itemSelector + ' > .selectedOverlay a.selectImage', function(e){
          e.preventDefault();
          self.handleSelectState( this );
        });
      }
    },

    handleWindowScroll: function()
    {
      var self = this,
          $cont = self.$container,
          atBottom = parseInt( $cont.scrollTop() + $cont.innerHeight() ) >= parseInt( $cont[0].scrollHeight );

      if(self.$container.data('fully-loaded') != 'true' && atBottom ) {
        self.addImages();
      }

    }, //handleWindowScroll

    handleSelectState: function(link)
    {
      var self = this,
        $link = $(link),
        $container = $link.closest( self.row_grid_options.itemSelector );

      if( $container.hasClass('selected') ){
        $container.removeClass('selected');
        if(self.selectable && self.onUnSelected && typeof( self.onUnSelected ) === 'function' )
        {
          self.onUnSelected.call(self, $link.data('image-id') );
        }
      } else {
        $container.addClass('selected');
        if(self.selectable && self.onSelected && typeof( self.onSelected ) === 'function' )
        {
          self.onSelected.call(self, $link.data('image-id') );
        }
      }

    }, //handleSelectState

    addImages: function()
    {
      var self = this;
      self.pagination_offset += self.images_per_page;
      self.$indicator.show();
      $.when( self.fetchImages() ).done( function(images) {
        if(images){
          $j.when( self.insertImages(images) ).done(function(){
            self.$container.rowGrid(self.row_grid_options);
            //self.$container.rowGrid('appended');
            self.$indicator.hide();
            if( Object.keys(images).length < (self.images_per_page - 1) ){
              self.$container.data('fully-loaded', 'true');
              console.log( 'I guess there are no more images');
            }
          });
        }
      });
    }, //addImages

    fetchImages: function()
    {
      var self = this,
        result,
        dfd = new $.Deferred();
        $.when( self.fetchImagesFunction.apply(self) ).done( function(result){
          if(result)
          {
            dfd.resolve(result);
          }
          else
          {
            dfd.resolve();
          }
        });
        return dfd.promise();
      // });
    }, // fetchImages

    insertImages: function(images)
    {
      var self = this,
          dfd;

      return $.Deferred( function() {
        dfd = this;
        $.each(images, function( idx, obj) {
          self.imageData[obj.GalleryImageId] = obj;
          self.$container.append( self.buildImage(obj) )
        });
        $("img:not('.loaded')").on('load', function() {
          $(this).off('load').addClass('loaded');
        })
        .each( function(indx, ele) {
          var $ele = $(ele);
          $ele.attr('src', $ele.data('src') );
        });
        dfd.resolve();
      });
    }, //insertImages

    buildImage: function(obj)
    {
      return this.HDLBRS_thumb_template(obj);
    },

    updateThumbAfterVersionChange: function()
    {
      var self = this,
        galleryImageId = self.Zoomer.image_id,
        obj = self.imageData[galleryImageId],
        $thumb = $( self.buildImage(obj) ),
        $img =  $thumb.find('img');

      $img.on({
        load: function()
        {
          $(this).off('load').addClass('loaded');
        },
        error: function()
        {
          var $this = $(this);
          $this.removeAttr('src');
          setTimeout( function() {
            $this.attr('src', obj.URL_Gallery);
          }, 1000);
        }
      });

      $('#'+galleryImageId).replaceWith( $thumb );
      $img.attr('src', obj.URL_Gallery);
      self.$container.rowGrid(self.row_grid_options);
    }, //.updateThumbAfterVersionChange

    Zoomer: {

      init: function( config )
      {
        this.super = config.super;
        this.$link = config.link;
        this.image_id = this.$link.data('image-data-id');

        this.imageData = this.super.imageData[ this.image_id ];
        this.active_image_id = this.imageData.Id;
        this.image_url = this.imageData.URL_1280w;
        //this.s3Data = this.imageData.AWS_S3_Object__r;
        this.load_template();
        this.cache();
        this.bind_events();
        this.init_viewer();
      }, //init

      load_template: function()
      {
        var self = this;
        //a partial used to display image descriptions in the viewer
        // also gets rerender after description update/edit
        Handlebars.registerPartial( "descriptions", $j("#imageDescriptionTemplate").html() );
        Handlebars.registerPartial( "association", $j("#associationTmp").html() );
        Handlebars.registerHelper('defaultLinkContent', function() {
          if(self.$link.parent().hasClass('defaultImage') )
          {
            return new Handlebars.SafeString('<i class="fa fa-ban"></i> Remove Default');
          }
          else
          {
            return new Handlebars.SafeString('<i class="fa fa-asterisk"></i> Set Default');
          }
        });
        this.viewerTemplate = Handlebars.compile( $j('#viewerTemplate').html() );
        this.associations_result_template = Handlebars.compile( $('#associationResultsTmp').html() );
        this.super.$viewer.append( this.viewerTemplate( this.imageData ) );
      }, //load_template

      cache: function()
      {
        this.$indicator = $('#zoomIndicator');
        this.$linkContainer = $("#AWS_links");
        this.$viewerWrapper = $('#viewerWrapper');
        this.$col1 = this.$viewerWrapper.children('div').first();
        this.$col2 = this.$col1.next();
        this.$imageContainer = $('#imageContainer');
        this.$descriptionContainer = $j('#descriptionContainer');
        this.$deleteModal = $('#deleteModal');
        this.$img = $('<img></img>');
        this.$imageVersions = $('#imageVersions');
        this.editFormElements = {
          $form: $('#imageForm'),
          $engDescription: $('#engDesc'),
          $frDescription: $('#frDesc')
        }
      }, //cache

      bind_events: function()
      {
        var self = this;
        // image menu
        $('#imgMenuButtons > a').on('click', function(e){
          e.preventDefault();
          switch( $(this).data('href') ) {
            case 'replace':
            self.show_replace_image_form.call(self);
            break;

            case 'versions':
            self.show_image_versions.call(self);
            break;

            case 'edit':
            self.show_edit_form();
            break;

            case 'delete':
            self.delete_image();
            break;

            case 'default':
            self.set_default_image(this);
            break;
          }
        });

        //close form button
        $('.closePageOverlay').on('click', function(e) {
          e.preventDefault();
          self.close_overlay_page();
        });

        //submit edit form
        $('#submitForm').on('click', function(e) {
          e.preventDefault();
          //$(this).off('click');
          self.submit_edit_form();
        });

        //extra functions on tab clicks
        $('.tabs').on('click', 'a', function() {
          var $this = $(this);
          switch( $this.attr('href') )
          {
            case '#descriptions':
              $('#submitForm').show();
              break;

            case '#associations':
              self.fetch_associated($this);
              break;
          }
        });

        //remove image association
        $('#associationResults').on('click', 'a.unAssociateImage', function(e) {
          var $this = $(this);

          $this.find('i').addClass('fa-spin');
          LegendGalleryRemoter.deleteImageAssociation($this.data('gallery-image-id'), $this.data('product-id'), function(events, result) {
            if(result.statusCode === 200)
            {
              $this.parent('li').animate({'height': 0}, 500, function() {
                $(this).remove();
              });
            }
            else
            {
              alert(result.message);
            }
          });
        });

      }, //bind_events

      init_viewer: function()
      {
        var self = this;
        //self.set_viewer_size();
        //show overlay
        self.super.$overlay.css('opacity', 1).show();
        //show indicator
        self.$indicator.show();

        //show the viewer
        self.super.$viewer.show();
        //initialize foundation for the tabs on the edit form
        $(document).foundation();

        $.when( self.set_viewer_size() ).done( function() {
          self.display_viewer();
        });
      }, //open_viewer

      set_viewer_size: function()
      {
        var self = this,
            dfd = new $.Deferred(),
            $window = $(window),
            dimensions ={};
            dimensions.viewer_w = $window.width() * 0.95, // total width of viewer = 95% window
            dimensions.viewer_h = $window.height() * 0.95, // total height of viewer = 95% window
            dimensions.col1_w = dimensions.viewer_w * 0.7, // col1 width = 70% of viewer, this is the image
            dimensions.col2_w = dimensions.viewer_w - dimensions.col1_w, // col2 width = remainder of viewer, this is the details
            dimensions.p_top = ( $window.height()  / 2 ) - ( dimensions.viewer_h / 2 ), // center the top
            dimensions.p_left = ( $window.width() / 2 ) - ( dimensions.viewer_w / 2 ); // center left


        self.$col1.css('width', dimensions.col1_w ); // set width of col1
        self.$col2.css('width', dimensions.col2_w); // set width of col2

        //set the starting position and dimensions of the viewer
        self.super.$viewer.css({
          width: dimensions.viewer_w,
          height: dimensions.viewer_h,
          top: dimensions.p_top,
          left: dimensions.p_left
        });

        dimensions.img_max_h = (dimensions.viewer_h * 0.98);
        dimensions.o_img_max_h = self.$imageContainer.height();
        dimensions.img_max_w = (dimensions.col1_w * 0.99);
        dimensions.o_img_max_w = self.$imageContainer.width();

        $.when( self.setup_image(dimensions) ).done( function() {
          dfd.resolve();
        });

        return dfd.promise();

      }, //set_viewer_size

      setup_image: function( dimensions )
      {
        var dfd = $.Deferred(),
        self = this;
        self.$img.css({
          'max-width': dimensions.img_max_w,
          'max-height': dimensions.img_max_h
        })
        .on('load', function() {
          //change the dimensions based on the orientation of the image
          if( self.$img.width() != dimensions.img_max_w)
          {
            var diff = dimensions.img_max_w - self.$img.width();
            self.$col1.css('width', dimensions.col1_w - diff);
            self.super.$viewer.css({width: dimensions.viewer_w - diff, left: dimensions.p_left + (diff/2) });
          }
          if( self.$img.height() != dimensions.img_max_h )
          {
            var diff = dimensions.img_max_h - self.$img.height();
            self.super.$viewer.css({height: dimensions.viewer_h - diff, top: dimensions.p_top + (diff/2) })
          }

          //500ms delay to make it all seem a little smoother
          setTimeout(function()
          {
            self.$viewerWrapper.css('opacity', 1);
            self.$indicator.hide();
            self.$img.fadeIn();
          }, 500);
        });
        return dfd.resolve().promise();
      },

      display_viewer: function() {
        this.super.$viewer.css('opacity', 1);
        this.$imageContainer.append(this.$img);
        this.$img.attr('src', this.image_url );
      },

      close_viewer: function()
      {
        var self = this;
        self.super.$viewer.removeAttr('style');
        self.super.$overlay.css('opacity', 0);
        setTimeout( function() {
          self.super.$viewer.hide().empty();
          self.super.$overlay.hide();
          delete self;
        }, 750);
      }, //close_viewer

      show_image_versions: function()
      {
        var self = this,
         calcH = ( self.calcContentHeight() ) + 'px';
        self.$viewerWrapper.addClass('blur');
        self.$imageVersions.addClass('open')
        .find('.image-versions-container')
        .css({ 'max-height':  calcH,
               'min-height': calcH });

        self.awsDropTarget = new AwsDropTarget(
          $('.slider-container'),
          self.super.awsSettings,
          self.super.HDLBRS_Image_Version_View_template,
          self.imageData.GalleryImageName );

        self.initVersionEvents.call(self);

        self.awsDropTarget.target.on('imageUploadSuccess', function(e) {

          var newImageData = e.originalEvent.detail.imageData,
            SF_ImageData = {
              File_Name: newImageData.name,
              GalleryImageId: self.imageData.GalleryImageId,
              Bucket_Name: self.super.awsSettings.aws_Bucket,
              Path: self.super.awsSettings.aws_FileKey,
              Image_Width: newImageData.width,
              Image_Height: newImageData.height
            };

          LegendGalleryRemoter.addNewVersion( JSON.stringify(SF_ImageData), function( result, event) {
            if( event.status )
            {
              if(result === null || result.length === 0)
              {
                LGND.alert('Something went wrong', 'No information was returned');
              }
              else
              {
                //we set the src because the image will not be available from S3 yet,
                //as it has to go through the ruby image processor at imgr.legendboats.com
                result.AWS_S3_Object__r.URL_1280w__c = newImageData.src;
                var currentSlide = 0,//self.awsDropTarget.$sliderView.slick('slickCurrentSlide'),
                  newImage =  self.super.HDLBRS_Image_Version_View_template(result),
                  view = self.awsDropTarget.$sliderView;

                // $.when( LGND.confirm('Set as Active?', 'Would you like to make this the Active Image?') )
                // .done( function(response){
                //   if(response)
                //   {
                    view.slick('slickRemove', currentSlide);
                    view.slick('slickAdd', newImage, currentSlide , 'addBefore');
                    var $image_container = view.find('.slick-slide[data-slick-index="' + currentSlide + '"]');
                    self.setActiveImage.call(self, result.Legend_Gallery_Image__c, result.AWS_S3_Object__c, $image_container );
                //   }
                //   else
                //   {
                //     self.awsDropTarget.$sliderView.slick('slickRemove', currentSlide);
                //     self.awsDropTarget.$sliderView.slick('slickAdd', newImage, currentSlide , 'addBefore');
                //   }
                // })

              }
            }
            else
            {
             LGND.alert('Something went wrong', event.message);
            }

          });
        })
      },

      cleanUpVersions: function()
      {
        var self = this;
        self.awsDropTarget.target.off();
        self.awsDropTarget.destroy();
        delete self.awsDropTarget;
      },

      initVersionEvents: function()
      {
        var self = this,
         awsDropTarget = self.awsDropTarget;

        awsDropTarget.target.on('click', '.delete-image', function(e) {
          e.preventDefault();
          var $this = $(this),
            awsId = $this.data('aws-id'),
            currentSlideIndex = awsDropTarget.$sliderView.slick('slickCurrentSlide');
          $.when( LGND.confirm("Are You Sure", "This will permanently delete this image") )
          .done( function(response) {
            if(response)
            {

              $this.closest('.slick-slide').addClass('busy');
              LegendGalleryRemoter.deleteVersion( awsId, function(result, event) {
                if( event.status )
                {
                  awsDropTarget.$sliderView.slick('slickRemove', currentSlideIndex);
                  awsDropTarget.$sliderNav.slick('slickRemove', currentSlideIndex);
                  if( currentSlideIndex > 0 )
                  {
                    awsDropTarget.$sliderNav.slick('slickGoTo', currentSlideIndex -1);
                  }
                  //remove the reference to the imageVersion in self.imageData and
                  //update self.super.imageData[self.imgae_id]
                  $.each(self.imageData.ImageVersions, function(idx, v) {
                    if( awsId === v.AWS_S3_Object__c )
                    {
                      delete self.imageData.ImageVersions[idx];
                    }
                  })
                  self.super.imageData[self.image_id] = self.imageData;
                }
                else
                {
                  LGND.alert('An Error has occured!', event.message);
                  $this.closest('.slick-slide').removeClass('busy');
                }
              });
            }
          })
        })
        .on('click', '.set-active', function(e) {
          e.preventDefault();
          var $this = $(this);
          self.setActiveImage.call(self, $this.data('record-id'),  $this.data('aws-id'), $this.closest('.slick-slide') );
        });

      },

      show_edit_form: function()
      {
        this.editFormElements.$engDescription.val(this.imageData.ENG_Description);
        this.editFormElements.$frDescription.val(this.imageData.FR_Description);
        this.$viewerWrapper.addClass('blur');
        this.editFormElements.$form.addClass('open')
        .find('.tabs-content').css('max-height', (this.calcContentHeight() ) + 'px');

      }, //show_edit_form

      calcContentHeight: function() {
        return this.super.$viewer.height() - (
          this.super.$viewer.find('h2:first').outerHeight() +
          this.super.$viewer.find('.tabs:first').outerHeight() +
          this.super.$viewer.find('.row.buttons').outerHeight()
          ) - 70;
      },

      close_overlay_page: function()
      {
        $('.page-overlay.open').removeClass('open');
        this.$viewerWrapper.removeClass('blur');
       if( this.awsDropTarget )
        {
          this.cleanUpVersions.call(this);
        }
      }, //close_edit_form

      submit_edit_form: function()
      {
        var self = this,
         data = {},
         template = Handlebars.partials['descriptions'];

        self.super.$indicator.show();

        data.english =  self.editFormElements.$engDescription.val().replace(/['"]/g, '');
        data.french = self.editFormElements.$frDescription.val().replace(/['"]/g, '');

        LegendGalleryRemoter.updateDescriptions(self.imageData.GalleryImageId, JSON.stringify(data), function(events, result) {
          self.super.$indicator.hide();
          if( result.statusCode === 200 )
          {
            self.imageData.FR_Description = result.result.FR_Description__c;
            self.imageData.ENG_Description = result.result.ENG_Description__c;
            self.super.imageData[ self.image_id ] = self.imageData;
            //populateDescriptions( s3Data );

            if (typeof template === 'function') {
              self.$descriptionContainer.empty().append( template( self.imageData ) );
            }

            self.close_overlay_page();
          }
          else
          {
            alert(result.message);
          }
        });
      }, //submit_edit_form

      fetch_associated: function($tabLink)
      {
        var self = this

        $('#submitForm').hide();
        if( $tabLink.data('loaded') != true)
        {
          LegendGalleryRemoter.associatedParents(self.imageData.GalleryImageId, self.super.SF_parentId, function (events, result) {
            $tabLink.data('loaded', true);
            $($tabLink.attr('href')).find('.loadingContentIndicator').hide();
            $('#associationResults').append( self.associations_result_template(result.result) );    // Add the result to the page
          });
        }
      }, //fetch_associated

      set_default_image: function(link)
      {
        var self = this,
          $link = $(link),
          wasDefault = self.$link.parent().hasClass('defaultImage');

        self.super.$indicator.show();
        LegendGalleryRemoter.setDefault(self.imageData.GalleryImageId, self.super.SF_parentId, function (events, result) {
          self.super.$indicator.hide();
          if(result.statusCode === 200)
          {
            $(self.super.row_grid_options.itemSelector + '.defaultImage').removeClass('defaultImage');
            if( wasDefault )
            {
              self.super.default_image_id = '';
            }
            else
            {
              self.$link.parent().addClass('defaultImage');
              self.super.default_image_id = self.imageData.GalleryImageId;
            }
            self.close_viewer();
          }
          else
          {
            alert(result.message);
          }
        });
      }, //set_default_image

      setActiveImage: function(gallery_image__c, aws_s3_object__c, $image_container)
      {
        var self = this,
          jsonData = {
            'Id': gallery_image__c,
            'Active_S3_Object__c':aws_s3_object__c
          };
        $image_container.addClass('busy');
        LegendGalleryRemoter.setActiveImage( JSON.stringify(jsonData), function(result, event) {
          if(event.status)
          {
            self.imageData = result;
            self.super.imageData[result.GalleryImageId] = result;
            self.active_image_id = result.Id;
            self.image_url = result.URL_Original;
            self.$img.attr('src', self.image_url );
            self.updateAWSLinks.call(self);
            self.super.updateThumbAfterVersionChange.call(self.super);
            setTimeout( function() {
              self.awsDropTarget.resetSliderHeight.call(self.awsDropTarget);
              $image_container.closest('.slick-track').find('.active-image').removeClass('active-image');
              $image_container.addClass('active-image');
              $image_container.removeClass('busy');
             }, 550);
          }
          else
          {
            LGND.alert('There was an Error!', event.message);
            $image_container.removeClass('busy');
          }


        });

      }, //setActiveImage

      updateAWSLinks: function()
      {
        var self = this;
        $('#s500').attr('href', self.imageData.URL_500x500);
        $('#700w').attr('href', self.imageData.URL_700w);
        $('#1280w').attr('href', self.imageData.URL_1280w);
        $('#original').attr('href', self.imageData.URL_Original);
        $('#imageDimensions').html(self.imageData.Image_Width + ' x ' + self.imageData.Image_Height);
      }, //updateAWSLinks

      delete_image: function()
      {
        var self = this;
        $.when( self.show_delete_options() ).done( function(result) {
          if(result)
          {
            if(result.statusCode === 200)
            {
              self.$deleteModal.foundation('reveal', 'close')
              .find('a').removeClass('jsDisabled');
              self.$link.parent().remove();
              self.super.$container.rowGrid( self.super.row_grid_options );
              self.close_viewer();
            }
            else
            {
              alert(result.message);
            }
          }
        });
      }, //delete_image

      show_delete_options: function()
      {
        var dfd = $.Deferred(),
          self = this,
          origBtnText,
          $this;

        self.$deleteModal.foundation('reveal', 'open')
        .find('a').on('click', function(e) {
          e.preventDefault();
          $this = $(this);
          self.$deleteModal.find('a').addClass('jsDisabled')
          .off('click');
          switch( $this.data('href') )
          {
            case 'cancel':
            $this.removeClass('jsDisabled').siblings('a').removeClass('jsDisabled');
            self.$deleteModal.foundation('reveal', 'close');
            dfd.resolve();
            break;

            case 'thisProduct':
              origBtnText = $this.html();
              $this.html( 'Deleting..' ).append( $('<i class="fa fa-spin fa-cog"></i>') );
              LegendGalleryRemoter.deleteImageAssociation(self.imageData.GalleryImageId, self.super.SF_parentId, function(events, result) {
                $this.html(origBtnText);
                dfd.resolve(result);
              });
            break;

            case 'allProducts':
              origBtnText = $this.html();
              $this.html( 'Deleting..' ).append( $('<i class="fa fa-spin fa-cog"></i>') );
              LegendGalleryRemoter.deleteImage(self.imageData.GalleryImageId, function(events, result) {
                $this.html(origBtnText);
                dfd.resolve(result);
              });
            break;

          }
        });
        return dfd.promise();
      }//show_delete_options

    } //Zoomer

  }


})(jQuery, window, document);





