({
  treatAsUTC: function(date) {
    var result = new Date(date);
    result.setMinutes(result.getMinutes() - result.getTimezoneOffset());
    return result;
  },

  daysBetween: function(startDate, endDate) {
      var self = this,
          millisecondsPerDay = 24 * 60 * 60 * 1000;
      return Math.round((self.treatAsUTC(endDate) - self.treatAsUTC(startDate)) / millisecondsPerDay);
  }
})