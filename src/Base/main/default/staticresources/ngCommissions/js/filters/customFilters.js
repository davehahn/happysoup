angular.module('customFilters', [])

.filter('removeSpaces', [function() {
    return function(string) {
        if (!angular.isString(string)) {
            return string;
        }
        return string.replace(/[\s]/g, '');
    };
}])

.filter('sumOfValue', function () {
  return function (data, key) {
    if(!data || typeof(data) === 'undefined' || typeof(key) === 'undefined') {
        return 0;
    }
    var sum = 0;
    for (var i = 0; i < data.length; i++) {
        sum = sum + data[i][key];
    }
    return sum.toFixed(2);
  }
})

.filter('approvalPopOver', [function() {
    return function(record) {
        var string = '';
        if( record.ReviewedBy )
        {
            string += '<p class="accepted"><span>Reviewed</span> by '+ '<b>' + record.ReviewedBy
            + '</b> <br /> on <span>'
            + record.ReviewedOn + '</span></p>';
        }
       if( record.ApprovedBy )
        {
            string += '<p class="accepted"><span>Approveded</span> by '+ '<b>' + record.ApprovedBy
            + '</b> <br /> on <span>'
            + record.ApprovedOn + '</span></p>';
        }
        if( record.AcceptedBy )
        {
            string += '<p class="accepted"><span>Accepted</span> by '+ '<b>' + record.AcceptedBy
            + '</b> <br /> on <span>'
            + record.AcceptedOn + '</span></p>';
        }
        return string;
    }
}])
