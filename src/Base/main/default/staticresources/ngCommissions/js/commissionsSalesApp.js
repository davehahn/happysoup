var di = ['ngRoute',
          'ngAnimate',
          'ui.bootstrap',
          'ngForce',
          'customFilters',
          'CommissionDirectives',
          'LocalStorageModule'
          ],
    app = angular.module('commissionsSalesApp', di)

.config(['$routeProvider', 'ngForceConfig', function( $routeProvider, ngForceConfig) {
  $routeProvider
  .when('/', {
    templateUrl: ngForceConfig.resourceUrl + '/templates/salesRecords.html',
    controller: 'commissionRecordsController'
  })
  .otherwise({redirectTo: '/'});
}])

.config(function (localStorageServiceProvider) {
  localStorageServiceProvider
    .setPrefix('commissionRecord');
})
.value('userType', 'sales')
;
