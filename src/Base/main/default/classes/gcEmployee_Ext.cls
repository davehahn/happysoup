public with sharing class gcEmployee_Ext {
  public gcEmployee_Ext() {
  }
  public gcEmployee_Ext(ApexPages.StandardController c) {
  }

  @RemoteAction
  public static string findOrCreateTimeCard(Id idEmployee, Id idTimeCardPeriod) {
    for (Employee__c empx : [SELECT Id, User__c FROM Employee__c WHERE Id = :idEmployee ORDER BY CreatedDate LIMIT 1])
      return gcTimeCardPeriod_Ext.findOrCreateTimeCard(empx.User__c, idTimeCardPeriod);

    return '';
  }

  @RemoteAction
  @ReadOnly
  public static list<map<string, string>> retrieveTimeCardPeriods(Id idEmployee, Id idTimeCard) {
    //convert employee Id to user Id.
    for (Employee__c empx : [SELECT Id, User__c FROM Employee__c WHERE Id = :idEmployee ORDER BY CreatedDate LIMIT 1])
      idEmployee = empx.User__c;

    map<Id, map<string, string>> mapHours = new Map<Id, map<string, string>>();

    if (idTimeCard == null) {
      for (AcctSeed__Time_Card_Period__c tcpx : [
        SELECT Id
        FROM AcctSeed__Time_Card_Period__c
        WHERE AcctSeed__Start_Date__c <= TODAY
        ORDER BY AcctSeed__Start_Date__c DESC
        LIMIT 52
      ]) {
        mapHours.put(tcpx.Id, new Map<string, string>());
      }
    } else {
      for (AcctSeed__Time_Card__c tcx : [
        SELECT Id, AcctSeed__Time_Card_Period__c
        FROM AcctSeed__Time_Card__c
        WHERE Id = :idTimeCard
      ]) {
        mapHours.put(tcx.AcctSeed__Time_Card_Period__c, new Map<string, string>());
      }
    }

    list<AggregateResult> listAggRes = new List<AggregateResult>();
    listAggRes.addAll(
      [
        SELECT
          AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__r.AcctSeed__Time_Card_Period__c idTimeCardPeriod,
          max(AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__c) idTimeCard,
          sum(AcctSeed__Hours__c) hours,
          sum(Hours_RT__c) hoursRT,
          sum(Hours_OT__c) hoursOT,
          sum(Hours_DT__c) hoursDT,
          sum(Wages__c) wages
        FROM AcctSeed__Time_Card_Day__c
        WHERE
          AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__r.AcctSeed__Employee__c = :idEmployee
          AND AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__r.AcctSeed__Time_Card_Period__c IN :mapHours.keySet()
        GROUP BY AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__r.AcctSeed__Time_Card_Period__c
      ]
    );

    for (AggregateResult aggRes : listAggRes) {
      map<string, string> m = new Map<string, string>();

      m.put('hours', String.valueOf(((Decimal) aggRes.get('hours')).setScale(2)));
      m.put('hoursRT', String.valueOf(((Decimal) aggRes.get('hoursRT')).setScale(2)));
      m.put('hoursOT', String.valueOf(((Decimal) aggRes.get('hoursOT')).setScale(2)));
      m.put('hoursDT', String.valueOf(((Decimal) aggRes.get('hoursDT')).setScale(2)));
      m.put('wages', String.valueOf(((Decimal) aggRes.get('wages')).setScale(2)));
      m.put('idTimeCard', String.valueOf((Id) aggRes.get('idTimeCard')));

      mapHours.put((Id) aggRes.get('idTimeCardPeriod'), m);
    }

    listAggRes.clear();
    listAggRes.addAll(
      [
        SELECT
          AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__r.AcctSeed__Time_Card_Period__c idTimeCardPeriod,
          AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card_Variable_1__r.Uniquefier__c uniquefier,
          sum(AcctSeed__Hours__c) hours
        FROM AcctSeed__Time_Card_Day__c
        WHERE
          AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__r.AcctSeed__Employee__c = :idEmployee
          AND AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__r.AcctSeed__Time_Card_Period__c IN :mapHours.keySet()
          AND AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card_Variable_1__r.Exclude_from_Overtime__c = TRUE
        GROUP BY
          AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card__r.AcctSeed__Time_Card_Period__c,
          AcctSeed__Time_Card_Line__r.AcctSeed__Time_Card_Variable_1__r.Uniquefier__c

      ]
    );

    for (AggregateResult aggRes : listAggRes) {
      mapHours.get((Id) aggRes.get('idTimeCardPeriod'))
        .put((String) aggRes.get('uniquefier'), String.valueOf(((Decimal) aggRes.get('hours')).setScale(2)));

      Decimal hoursRT = Decimal.valueOf(mapHours.get((Id) aggRes.get('idTimeCardPeriod')).get('hoursRT'));
      hoursRT -= (Decimal) aggRes.get('hours');
      mapHours.get((Id) aggRes.get('idTimeCardPeriod')).put('hoursRT', String.valueOf(hoursRT.setScale(2)));
    }

    for (AcctSeed__Time_Card_Period__c tcpx : [
      SELECT Id, Name, AcctSeed__Start_Date__c, AcctSeed__End_Date__c, AcctSeed__Status__c
      FROM AcctSeed__Time_Card_Period__c
      WHERE Id IN :mapHours.keySet()
    ]) {
      map<string, string> m = mapHours.get(tcpx.Id);

      m.put('timeCardPeriodName', tcpx.Name);
      m.put('idTimeCardPeriod', tcpx.Id);
      m.put('startDate', tcpx.AcctSeed__Start_Date__c.format());
      m.put('endDate', tcpx.AcctSeed__End_Date__c.format());
      m.put('status', tcpx.AcctSeed__Status__c);

      if (!m.containsKey('hours'))
        m.put('hours', '0.00');
      if (!m.containsKey('hoursRT'))
        m.put('hoursRT', '0.00');
      if (!m.containsKey('hoursOT'))
        m.put('hoursOT', '0.00');
      if (!m.containsKey('hoursDT'))
        m.put('hoursDT', '0.00');
      if (!m.containsKey('PTO'))
        m.put('PTO', '0.00');
      if (!m.containsKey('HOLIDAY'))
        m.put('HOLIDAY', '0.00');
      if (!m.containsKey('BEREAVEMENT'))
        m.put('BEREAVEMENT', '0.00');
      if (!m.containsKey('wages'))
        m.put('wages', '0.00');
    }
    return mapHours.values();
  }
}
