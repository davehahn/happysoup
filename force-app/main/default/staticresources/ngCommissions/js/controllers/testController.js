app.controller('testController',['$scope', 'vfr', function($scope, vfr) {
  $scope.title = "Here are the first 10 accounts that come to my head";

  var acctQuery = vfr.query("SELECT Id, Name FROM Account LIMIT 10");

  acctQuery.then( function(results) {
    $scope.accounts = results.records;
  })



}]);
