'use strict';

angular.module('lpcApp', ['ngRoute', 'ngAnimate', 'ngForce', 'ngMaterial', 'appDirectives']);

angular.module('lpcApp')

.config(['$routeProvider', 'ngForceConfig', function( $routeProvider, ngForceConfig) {
  $routeProvider
  .when('/', {
    templateUrl: ngForceConfig.resourceUrl + '/templates/home.html',
    controllerAs: 'homeCtrl',
    controller: 'homeController'
  })
  .when('/f1', {
    templateUrl: ngForceConfig.resourceUrl + '/templates/f1.html',
    controllerAs: 'f1Ctrl',
    controller: 'f1Controller'
  })
  .when('/f2', {
    templateUrl: ngForceConfig.resourceUrl + '/templates/f2.html',
    controllerAs: 'f2Ctrl',
    controller: 'f2Controller'
  })
  .when('/f3', {
    templateUrl: ngForceConfig.resourceUrl + '/templates/f3.html',
    controllerAs: 'f3Ctrl',
    controller: 'f3Controller'
  })
  .otherwise({ redirectTo: '/' });
}]);



'use strict';

angular.module('lpcApp')
.controller('appController', ['$scope', '$mdSidenav', '$mdUtil', '$log', 'vfr', '$location', 'SF_USER_INFO',
  function($scope, $mdSidenav, $mdUtil, $log, vfr, $location, SF_USER_INFO) {
    var vm = this,
    /**
     * Build handler to open/close a SideNav; when animation finishes
     * report completion in console
    **/
      navToggler = function(navID) {
        var debounceFn =  $mdUtil.debounce(function(){
              $mdSidenav(navID)
                .toggle()
                .then(function () {
                  $log.debug('toggle ' + navID + ' is done');
                });
            },100);
        return debounceFn;
      };

      console.log(SF_USER_INFO);

    // vfr.query('SELECT Id, FirstName, LastName, AccountId FROM User WHERE Id = \'' + SF_USER_INFO.id + '\'')
    // .then( function(user) {
    //   console.log('why not running');
    //   vm.user = user.records[0];
    //   console.log(user.records[0]);
    // });

    // vfr.query('SELECT Id, Name FROM Account')
    // .then( function(r) { console.log(r.records); });

    vm.toggleLeft = navToggler('leftNav');
    vm.toggleRight = navToggler('rightNav');
    vm.activeNavItem = $location.path();
    vm.sideNavItems = [
      {'label': 'Home', 'url': '/', 'icon': 'home'},
      {'label': 'Function  1', 'url': '/f1', 'icon': 'build'},
      {'label': 'Function  2', 'url': '/f2', 'icon': 'face'},
      {'label': 'Function  3', 'url': '/f3', 'icon': 'settings'}
    ];

    $scope.$on('$routeChangeSuccess', function( scope, current ) {
      vm.activeNavItem = current.$$route.originalPath;
      if( $mdSidenav('leftNav').isOpen() &&
          !$mdSidenav('leftNav').isLockedOpen() )
      {
        $mdSidenav('leftNav').close();
      }
    });
  }
]);

'use strict';

angular.module('appDirectives', []);

angular.module('appDirectives')

.directive('sideNavContent', ['ngForceConfig', function(ngForceConfig) {
  return {
    restrict: 'E',
    scope: {
      navItems: '=',
      activeItem: '='
    },
    templateUrl: ngForceConfig.resourceUrl + '/templates/side-nav-content.html',
    link: function(scope) {
      scope.logoUrl = ngForceConfig.resourceUrl + '/img/logo_gray.png';
      scope.logOutUrl = ngForceConfig.absoluteSitePrefix + '/secur/logout.jsp';
    }
  };
}])

.directive('topToolbar', ['ngForceConfig','SF_USER_INFO', function(ngForceConfig, SF_USER_INFO) {
  return {
    restrict: 'E',
    controller: function() {
      this.user = SF_USER_INFO;
      this.logoUrl = ngForceConfig.resourceUrl + '/img/full_logo_200x29.png';
    },
    controllerAs: 'toolBarCtrl',
    templateUrl: ngForceConfig.resourceUrl + '/templates/top-toolbar.html'
  };
}]);

'use strict';

function F1Controller()
{
  this.title = 'This is the function 1 page';
}

angular.module('lpcApp')
.controller('f1Controller', F1Controller);

'use strict';

function F2Controller()
{
  this.title = 'This is the Function 2 page';
}

angular.module('lpcApp')
.controller('f2Controller', F2Controller);



'use strict';

function F3Controller()
{
  this.title = 'This is the function 3 page';
}

angular.module('lpcApp')
.controller('f3Controller', F3Controller);



'use strict';

function HomeController()
{
  this.title = 'This is the home page';
}

angular.module('lpcApp')
.controller('homeController', HomeController);

