var di = ['ngRoute',
          'ngAnimate',
          'ui.bootstrap',
          'ngForce',
          'customFilters',
          'CommissionDirectives',
          'LocalStorageModule'
          ],
  app = angular.module('commissionsOfficeApp', di)

.config(['$routeProvider', 'ngForceConfig', function( $routeProvider, ngForceConfig) {
  $routeProvider
  .when('/', {
    templateUrl: ngForceConfig.resourceUrl + '/templates/officeRecords.html',
    controller: 'commissionRecordsController'
  })
  .when('/testroute', {
    templateUrl: ngForceConfig.resourceUrl + '/templates/test.html',
    controller: 'testController'
  })
  .otherwise({redirectTo: '/'});
}])

.config(function (localStorageServiceProvider) {
  localStorageServiceProvider
    .setPrefix('commissionRecord');
})

.value('userType', 'office')


;


