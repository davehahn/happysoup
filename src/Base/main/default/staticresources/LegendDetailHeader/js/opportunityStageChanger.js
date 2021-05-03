(function($, window, document, undefined) {

  window.OpportunityStageChanger = {

    init: function(stage, opportunityId, probability)
    {
      // this.stageMap = {'Business Office Approval Pending':1,
      //                  'Tagging Pending': 2,
      //                  'Orientation Specialist Add-On Call': 3,
      //                  'Pending Work Order': 4,
      //                  'Pending Rigging': 5,
      //                  'Pending Inspection': 6,
      //                  'Pending Pickup': 7,
      //                  'Picked Up / Won': 8};
      this.stageMap = {'Quoting': 1,
                       'Sales Manager Approval Pending': 2,
                       'Business Office Approval Pending': 3,
                       'Pending ERP': 4,
                       'Sent to ERP': 5 };
      this.linkCount = 4;
      this.currentProbability = parseInt(probability);
      this.oppId = opportunityId;
      this.$container = $('.oppStageChanger');
      this.probabilityChart = new LGND_CircleIndicator();
      var self = this;
      $.when(
        self.makeItFit.call(self),
        self.setupStageChanger.call(self, stage)
        //self.clickHandler.call(self)
      ).done( function() {
        self.$container.css('visibility', 'visible');
        self.probabilityChart.insertIn( $j('#probabilityContainer') );
        self.probabilityChart.updateValue(self.currentProbability);
      });
    },

    makeItFit: function()
    {
      var self = this,
          dfd = new $.Deferred(),
          indivBtnWidth,
          maxWidth = self.$container.parent().width();

      //we will leave 10px of padding on each side of the bar
      maxWidth -= 45;
      indivBtnWidth = ( maxWidth / self.linkCount ) - 36;

      self.$container.children('a').each(function(inx, ele){
        var $this = $(ele),
          oWidth = $this.outerWidth();

        //just for looks we will add 36 pxs to the first button in the row
        if( inx == 0 )
        {
          $this.css('width', (indivBtnWidth + 36) );
        }
        else
        {
          $this.css('width', indivBtnWidth );
        }

        $this.data({'link-index': inx, 'orig-width': oWidth})
        .on({
          mouseenter: function() {
            if( $this.data('orig-width') > indivBtnWidth )
            {
              var diff = $this.data('orig-width') - indivBtnWidth;
              //The first button in the Row, remeber it is 36px bigger then the rest
              //and we only resize the next button
              if( $this.data('link-index') === 0 )
              {
                $this.css('width', $this.data('orig-width') + 16 )
                .next().css('width', ( indivBtnWidth + 36 - diff - 16) );
              }
              //this is the last link so we only resize the previous button
              else if( $this.data('link-index') === (self.linkCount - 1) )
              {
                $this.css('width', $this.data('orig-width') + 16 )
                .prev().css('width', ( indivBtnWidth - diff - 16) );
              }
              //this is the second link, since the first link is a different size then
              //the rest we need to deal with it seperately
              else if( $this.data('link-index') === 1 )
              {
                $this.css('width', $this.data('orig-width') + 15 );
                $this.prev().css('width', ( indivBtnWidth + 36 - ( diff / 2 ) - 8 ) );
                $this.next().css('width', ( indivBtnWidth - ( diff / 2 ) - 8 ) );
              }
              //this is the middle buttons and we resize buttons on either side
              else
              {
                $this.css('width', $this.data('orig-width') + 15 );
                $this.prev().css('width', ( indivBtnWidth - ( diff / 2 ) - 8 ) );
                $this.next().css('width', ( indivBtnWidth - ( diff / 2 ) - 8 ) );
              }
            }
          },
          mouseleave: function() {
            if( $this.data('orig-width') > indivBtnWidth )
            {
              if( $this.data('link-index') === 0 )
              {
                $this.css('width', indivBtnWidth + 36 )
                .next().css('width', indivBtnWidth );
              }
              else if( $this.data('link-index') === (self.linkCount - 1) )
              {
                $this.css('width', indivBtnWidth )
                .prev().css('width', indivBtnWidth );
              }
              else if( $this.data('link-index') === 1 )
              {
                $this.css('width', indivBtnWidth );
                $this.prev().css('width', indivBtnWidth + 36 );
                $this.next().css('width', indivBtnWidth  );
              }
              else
              {
                $this.css('width', indivBtnWidth );
                $this.prev().css('width', indivBtnWidth  );
                $this.next().css('width', indivBtnWidth  );
              }
            }
          }
        }); // end on handler

      }); // end link each loop
      dfd.resolve();
      return dfd.promise();
    },

    setupStageChanger: function (current_stage){
      var self = this,
        dfd = new $.Deferred(),
        linkNum,
        stageNumber = self.stageMap[current_stage],
        $links = $('.oppStageChanger a'),
        $link;
      if( stageNumber !== undefined){
        $links.each(function() {
          $link = $(this);
          $link.removeClass();
          linkNum =  self.stageMap[$link.data('new-stage')]  ;
          if( linkNum === stageNumber ){
            $link.addClass('complete');
            if( $link.data('click-state') === undefined || !$link.data('click-state') === 'off' ){
              $link.addClass('retractable');
            }
          }
          else if (linkNum < stageNumber){
            $link.addClass('complete');
          }
          else if( linkNum === (stageNumber +1) ){
            $link.addClass('available');
          }
          //else {
            //$link.addClass('disabled');
          //}
        });
      } else {
        $links.addClass('disabled').first().removeClass().addClass('available');
      }
      dfd.resolve();
      return dfd.promise();
    },// /setupStageChnager

    clickHandler: function()
    {
      var self = this,
          dfd = new $.Deferred();

      $('.oppStageChanger').on('click', 'a', function(e){
        e.preventDefault();
        var $this = $(this);
        if( ( $this.data('click-state') === undefined || !$this.data('click-state') === 'off' )
            && ( $this.hasClass('available') || $this.hasClass('retractable') ) ){
          self.stageChange.call(self, this);
        }
      });
      dfd.resolve();
      return dfd.promise();
    }, // /clickHandler

    stageChange: function(link)
    {
      var self = this,
        $link = $(link),
        stage = $link.data('new-stage'),
        origHTML = $link.html();

      $link.html( self.indicator() );
      OpportunityDetailExt.updateStage(
        self.oppId, stage, function(result, events){
        if( result !== null ){
          $link.html( origHTML );
          $('#stageName').html(result.StageName);
          // $('#Probability__c').html(result.Probability+'%');
          self.currentProbability = parseInt(result.Probability);
          self.probabilityChart.updateValue( self.currentProbability );
          self.setupStageChanger.call(self, result.StageName);
          refreshFeed();
        } else {
          console.log(events)
          alert(" we do not have " + stage + " as a StageName");
        }
      });

    },// /stageChange

    indicator: function()
    {
      return '<span><ul class="change-indicator"><li></li><li></li><li></li></ul></span>';
    }


  }
})(jQuery, window, document);
