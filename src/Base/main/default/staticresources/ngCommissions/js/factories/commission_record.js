app.factory('CommissionRecords', ['vfr', 'localStorageService', function(vfr, localStorageService) {
  var today = new Date(),
      functs,
      remoteActions = {
        'office': 'CommissionRecordController.fetchCommissionRecords',
        'sales': 'CommissionRecordController.fetchSalesCommissionRecords'
      },
      defaultStage = {
        'office': 'Pending Manager Approval',
        'sales': 'Pending Sales Approval'
      },
      CommissionRecords = function(userType) {
        this.loading = true;
        this.userType = userType;
        functs.initQueryParams.call(this);
      };

  CommissionRecords.prototype.queryParamsChanged = function()
  {
    functs.fetchRecords.call(this);
  }


  functs = {

    initQueryParams: function()
    {
      var self = this;
      if( localStorageService.isSupported &&  localStorageService.keys().indexOf('queryParams') > -1 )
      {
        self.queryParams = angular.fromJson( localStorageService.get('queryParams') );
      }
      else
      {
        self.queryParams = {
          selectedStage: defaultStage[this.userType],
          currentYear: today.getFullYear(),
          currentMonth:  today.getMonth()
        };
      }
    },

    saveQueryParams: function()
    {
      if( localStorageService.isSupported )
      {
        localStorageService.set('queryParams', angular.toJson( this.queryParams ) );
      }
    },

    fetchRecords: function()
    {
      var self = this,
          comQuery = vfr.send(remoteActions[self.userType], {escape: false, timeout: 10000}, true);

      self.loading = true;
      functs.saveQueryParams.call(self);
      comQuery( JSON.stringify( self.queryParams ) ).then(
        function(result) {
          self.records = result;
          self.loading = false;
        },
        function(error) {
          console.log(error)
        }
      );
    }
  }

  return CommissionRecords;

}]);
