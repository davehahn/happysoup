(function($, window, document, undefined) {

  var StatusPath = (function() {

    var stageMap = [
      'New',
      'Reviewed',
      'Approved',
      'Sales Accepted'
    ];

    function StatusPath( commRecord, status_path_template, spinnerURLs )
    {
      this.commRecord = commRecord;
      this.template = status_path_template;
      this.spinnerURLs = spinnerURLs;
      this.$statusPathContainer = $('#status-path-container-'+commRecord.Id).parent();
      _initialize.call(this);
    }

    function _initialize()
    {
      var self = this;
      self.$statusPathContainer
      .on( 'click', 'a.slds-tabs--path__link', function(e) {
        _handleStatusChange.call( self, $(this) );
      })
      .on( 'mouseover', 'a.slds-tabs--path__link', function(e) {
        _showToolTip.call(self, $(this) );
      })
      .on( 'mouseleave', 'a.slds-tabs--path__link', function(e) {
        $('.slds-popover').remove();
      });
    }

    function _showToolTip( $stageLink )
    {
      var approvedBy = $stageLink.data('approved-by'),
          wasAutoAccepted = $stageLink.data('was-auto-accepted'),
          left, top, width, aDate, approver, $ttContainer;

      if( approvedBy || wasAutoAccepted )
      {
        width = $stageLink.width();
        left = $stageLink.offset().left;
        top = $stageLink.offset().top - $('.lgnd').offset().top;
        approver = wasAutoAccepted ? 'Auto Accepted' : $stageLink.data('approved-by');
        aDate = new Date( $stageLink.data('approved-on') );
        aDateFormat = aDate.toLocaleDateString('en-US', {weekday: "short", year: "numeric", month: "short", day: "numeric", hour: "2-digit", minute: "2-digit"});
        $ttContainer = $('<div class="slds-popover slds-popover--tooltip slds-nubbin--bottom-left" role="tooltip"></div>');
        $ttContainer.css({ position:'absolute', top: top, left: left, width: width, visibility: 'hidden' })
        .append( $('<div class="slds-popover__body"></div>').html( '<b>By</b>: ' + approver + '<br /> <b>On</b>: ' +  aDateFormat) );
        $('.lgnd').append( $ttContainer );
        $ttContainer.css({'visibility': 'visible', top: ( top - $ttContainer.outerHeight() ) });
      }
    }

    function _saveStage( stageName )
    {
      var self = this,
        dfd = new $.Deferred();
      CommissionCalculatorController.changeStage( self.commRecord.Id, stageName, function(result, event) {
        if( event.status )
        {
          if(result === null || result.length === 0)
          {
            dfd.resolve(null);
          }
          else
          {
            dfd.resolve(result);
          }
       }
       else
        {
         dfd.reject(event.message);
        }
      });
      return dfd.promise();
    }

    function _handleStatusChange( $stageLink )
    {
      var self = this,
          statusNum = $stageLink.data('status-number'),
          $currentLi = $stageLink.parent(),
          spinnerUrl = $currentLi.hasClass('slds-is-complete') ? self.spinnerURLs.white : self.spinnerURLs.gray,
          $indicator = $('<span class="indicator"></span>').append( $('<img></img>').attr('src', spinnerUrl) ),
          doUpdate = function()
          {
            $stageLink.append( $indicator );
            $currentLi.addClass('busy');
            _saveStage.call(self, stageMap[statusNum] )
            .then( function( result ) {
              self.commRecord = result;
              self.$statusPathContainer.html( self.template( {comRecord: result} ) );
              _publishStageChange.call(self);
            })
            .fail( function( message ) {
              LGND.alert('There was an error', message);
              $('.slds-popover').remove();
              $currentLi.removeClass('busy').find('.indicator').remove();
            });
          }

      if( $currentLi.hasClass('slds-is-current') ||
          ( !$currentLi.prev().hasClass('slds-is-current') &&
            !$currentLi.hasClass('slds-is-complete') )
        )
      {
        return false;
      }
      else
      {
        if( stageMap.indexOf( self.commRecord.Stage__c ) > statusNum )
        {
          LGND.confirm('Are you sure?', 'This will undo the current approval status')
          .then( function( result ) {
            if( result )
            {
              doUpdate();
            }
            else
            {
              return false;
            }
          });
        }
        else
        {
          doUpdate();
        }
      }
    }

    function _publishStageChange()
    {
      var self = this,
          event = new CustomEvent('status-changed', {'detail': {comRecord: self.commRecord} } );

      self.$statusPathContainer[0].dispatchEvent( event );
    }



    StatusPath.prototype = {
      reInit: function( comRecord )
      {
        this.$statusPathContainer.empty();
        this.comRecord = comRecord;
        this.$statusPathContainer.html( this.template({comRecord: comRecord}) );
      }
    };

    return StatusPath;

  })();

  window.StatusPath = StatusPath;

})(jQuery.noConflict(), window, document);
