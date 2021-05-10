app.controller('commissionRecordsController',
  ['$scope', 'CommissionRecords', 'userType',
    function($scope, CommissionRecords, userType)
  {

    $scope.ComRec = new CommissionRecords(userType);


    $scope.$watch("ComRec.records", function(value) {
      $scope.hasRecords = typeof(value) === 'undefined' ? false : true;
    });

    $scope.$watch("ComRec.queryParams.currentMonth", function(n, o) {
      if(n !== o)
        $scope.ComRec.queryParamsChanged();
    });

    $scope.$watch("ComRec.queryParams.currentYear", function(n, o) {
      if( n !== o )
        $scope.ComRec.queryParamsChanged();
    });

    $scope.$watch("ComRec.queryParams.selectedStage", function(newValue, oldValue) {
      if(newValue !== oldValue)
        $scope.ComRec.queryParamsChanged(true);
    });

    $scope.ComRec.queryParamsChanged();

    $scope.viewComm = function(idFieldName, recId)
    {
      var url = '/apex/CommissionCalculator?' + idFieldName  +'=' + recId + '&retURL=/apex/CommissionRecordDispatcher';
      console.log(url);
      if( (typeof sforce != 'undefined') && (sforce != null) )
      {
        sforce.one.navigateToURL(url);
      }
      else
      {
        window.top.location.href = url;
      }
    }

}]);

