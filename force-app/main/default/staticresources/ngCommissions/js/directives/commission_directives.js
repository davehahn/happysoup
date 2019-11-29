angular.module('CommissionDirectives', [] );

angular.module('CommissionDirectives')

.directive('stageSelector', function() {
  return {
    template: '<select class="form-control" ng-model="selectedValue" ng-options="opt as opt.label for opt in stages"></select>',
    restrict: 'E',
    scope: {
      selectedStage: '='
    },
    link: function(scope, ele, attrs)
    {
      scope.stages = [
        { label: 'New', value: 'New' },
        { label: 'Reviewed', value: 'Reviewed' },
        { label: 'Approved', value: 'Approved' },
        { label: 'Complete', value: 'Sales Accepted' },
        { label: 'All', value: 'All'}
      ];

      var findStageNum = function(strgVal) {
        for(var i=0;i<scope.stages.length;i++)
        {
          if(strgVal === scope.stages[i].value)
            return i;
        }
        return null;
      };
      scope.selectedValue = scope.stages[ findStageNum(scope.selectedStage) ];
      scope.$watch("selectedValue", function(n,o){
        if( n !== o )
          scope.selectedStage = n.value;
      })
    }
  }
})

.directive('parentRecordLink', function() {
  return {
    template: '<a href="/{{recordId}}">{{recordName}}</a>',
    restrict: 'E',
    scope: false,
    link: function(scope, element, attrs)
    {
      console.log(attrs.comrecord);
      var record = JSON.parse( attrs.comrecord );
      console.log(record);
      if( record.ParentType === 'opportunity' )
      {
        scope.recordId = record.OpportunityId,
        scope.recordName = record.OpportunityName;
      }
      if( record.ParentType === 'erp_order' )
      {
        scope.recordId = record.ERPOrderId;
        scope.recordName = record.ERPOrderName;
      }
      console.log(scope);
    }
  }
})

.directive('recordLink', function() {
  return {
    template: '<a href="" ng-click="viewComm(fieldName, recordId)">{{recordName}}<span> - {{accountName}}</span></a>',
    restrict: 'E',
    scope: false,
    link: function(scope, element, attrs)
    {
      var record = JSON.parse( attrs.comrecord );
      console.log(record);
      scope.accountName = record.AccountName;
      if(record.ParentType === 'opportunity' )
      {
        scope.fieldName = 'opportunity_id';
        scope.recordId = record.OpportunityId;
        scope.recordName = record.OpportunityName;
      }
      if( record.ParentType === 'erp_order' )
      {
        scope.fieldName = 'erp_order_id',
        scope.recordId = record.ERPOrderId;
        scope.recordName = record.ERPOrderName;
      }
    console.log( scope );
    }
  }
})

.directive('dateFilter', function(ngForceConfig) {
  return {
    restrict: 'E',
    scope:{ selectedMonth: '=month',
            selectedYear: '=year' },
    templateUrl: ngForceConfig.resourceUrl + '/templates/_date_filter.html',
    controller: function($scope, $element)
    {
      $scope.filterClick = function(obj) {
        var direction = obj.currentTarget.attributes['data-function'].value,
            controlEl = obj.currentTarget.attributes['data-control'].value,
            currentValue = parseInt( document.getElementById(controlEl).value );

        if( controlEl === 'month' )
        {
          if(direction === 'decrease')
          {
            if( currentValue === 0 )// January && we have a lower year
            {
              if( $scope.year.value > $scope.lowestYear )
              {
                $scope.month = $scope.months[ 11 ]; //month = decemebr
                $scope.year = $scope.years[ $scope.findYearInSelect( $scope.year.value -1 ) ];// decrement year
              }
            }
            else
            {
              $scope.month = $scope.months[ currentValue - 1];
            }
          }// /decrease month
          if( direction === 'increase' )
          {
            if( currentValue === 11 )
            {
              if( $scope.year.value < $scope.highestYear )
              {
                $scope.month = $scope.months[ 0 ]; //month = january
                $scope.year = $scope.years[ $scope.findYearInSelect( $scope.year.value +1 ) ];// increment year
              }
            }
            else if( currentValue !== 12 ) //don't do anything if 'All' is selected
            {
              $scope.month = $scope.months[ currentValue + 1 ];
            }
          }
        }
        if( controlEl === 'year' )
        {
          if(direction === 'decrease' && currentValue != $scope.lowestYear )
          {
            $scope.year = $scope.years[ $scope.findYearInSelect(currentValue - 1) ];
          }
          if( direction === 'increase' && currentValue != $scope.highestYear )
          {
            $scope.year = $scope.years[ $scope.findYearInSelect(currentValue + 1) ];
          }
        }
      }
    },
    link: function(scope, element, attrs)
    {
      var today = new Date(),
          buildYearsSelect = function() {
            var result = [],
                diff = scope.highestYear - scope.lowestYear;
            for( var i=0; i<=diff; i++)
            {
              result.push( {value: ( scope.highestYear - i ) , label: ( scope.highestYear - i ) } );
            }
            return result;
          };

      scope.lowestYear = 2014;
      scope.highestYear = new Date().getFullYear();
      scope.years = buildYearsSelect();
      scope.months = [ { value: 0, label: 'January' },
                       { value: 1, label: 'February' },
                       { value: 2, label: 'March' },
                       { value: 3, label: 'April' },
                       { value: 4, label: 'May' },
                       { value: 5, label: 'June' },
                       { value: 6, label: 'July' },
                       { value: 7, label: 'August' },
                       { value: 8, label: 'September' },
                       { value: 9, label: 'October' },
                       { value: 10, label:  'November'},
                       { value: 11, label:  'December' },
                       { value: 12, label: 'All'}
                     ];
      scope.findYearInSelect = function(y) {
        for(var i=0; i<scope.years.length; i++)
        {
          if( y === scope.years[i].value )
            return i;
        }
        return;
      };
      scope.month = scope.months[ scope.selectedMonth ];
      scope.year = scope.years[ scope.findYearInSelect( scope.selectedYear ) ];

      scope.$watch('month', function(newValue, oldValue) {
        scope.selectedMonth = newValue.value;
      });
      scope.$watch('year', function(n,o){
        scope.selectedYear = n.value;
      })
    }
  }
});
