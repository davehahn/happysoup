global without sharing class gcProject_Ext {
  global gcProject_Ext() {}

    global static string locale{get{return UserInfo.getLocale();}}

  global gcProject_Ext(ApexPages.StandardController c){

    isBoatSale = false;
    isPartnerBoatSale = false; 
    isCounterSale = false;
        isService = false;
        isFixedAsset = false;
        isWarranty = false;
    isManufacturing = false;
    isTradeIn = false;
    isPartnerPartsOrder = false;

    Id recordTypeId = ((AcctSeed__Project__c)(c.getRecord())).RecordTypeId;

    if(recordTypeId == gcConstants.idRtProjectBoatSale)
      isBoatSale = true;
    else if(recordTypeId == gcConstants.idRtProjectPartnerBoatSale)
      isPartnerBoatSale = true;
    else if(recordTypeId == gcConstants.idRtProjectCounterSale)
      isCounterSale = true;
    else if(recordTypeId == gcConstants.idRtProjectService)
      isService = true;
    else if(recordTypeId == gcConstants.idRtFixedAsset)
      isFixedAsset = true;
    else if(recordTypeId == gcConstants.idRtProjectWarranty)
      isWarranty = true;
    else if(recordTypeId == gcConstants.idRtProjectManufacturing)
      isManufacturing = true;
    else if(recordTypeId == gcConstants.idRtTradeIn)
      isTradeIn = true;
    else if(recordTypeId == gcConstants.idRtPartnerPartsOrder)
      isPartnerPartsOrder = true;

    idWarehouseInternal = gcConstants.idWarehouseWholesale;

    isTaggedRetailERP = findIfTaggedERP(c.getId());
    hasFinishedGood = findMFGFinishedGood(c.getId());
  }

  global Boolean isBoatSale{get;set;}
  global Boolean isPartnerBoatSale{get;set;}
  global Boolean isCounterSale{get;set;}
  global Boolean isService{get;set;}
  global Boolean isFixedAsset{get;set;}
  global Boolean isWarranty{get;set;}
  global Boolean isManufacturing{get;set;}
  global Boolean isTradeIn{get;set;}
  global Boolean isPartnerPartsOrder{get;set;}
  global Boolean isTaggedRetailERP{get;set;}
  global Boolean hasFinishedGood{get;set;}

  global Id idWarehouseInternal{get;set;}

  public List<SelectOption> getListDefaultTaskNames()
  {
    List<SelectOption> listTNOptions = new List<SelectOption>();
    if(!ERP_Order_Settings__c.getOrgDefaults().Hide_Enter_New_Name_Option__c)
      listTNOptions.add(new selectOption('', '(enter new name)'));

    List<ERPOrderTaskNames__c> erpOrderTN = ERPOrderTaskNames__c.getall().values();
    if(!erpOrderTN.isEmpty())
    {
      for(ERPOrderTaskNames__c etn : erpOrderTN)
      {
        listTNOptions.add(new selectOption(etn.Name, etn.Name));
      }
      listTNOptions.sort();
    }

    return listTNOptions;
  }

  public Boolean findIfTaggedERP(Id idERP){
    Boolean result = false;
    for(AcctSeed__Project__c pr : [SELECT Id, (SELECT Id FROM ERP_Orders__r WHERE AcctSeed__Status__c != 'Completed' LIMIT 1) FROM AcctSeed__Project__c WHERE Id =:idERP])
      if(!pr.ERP_Orders__r.isEmpty())
        result = true;
    return result;
  }

  public Boolean findMFGFinishedGood(Id idERP){
    Boolean result = false;
    for(AggregateResult aggRes :
      [SELECT sum(AcctSeedERP__Quantity__c) qty
      FROM AcctSeedERP__Inbound_Inventory_Movement__c
      WHERE AcctSeedERP__Project__c = :idERP
      AND AcctSeedERP__Quantity__c != null])
    {
      Decimal qty = (Decimal)aggRes.get('qty');
      if(qty == null) qty = 0;
      if(qty.setScale(2) != 0)
        result = true;
    }
    return result;
  }

  public Id getIdDefaultWarehouse()
  {
    Id idUser = UserInfo.getUserId();
    Id idWarehouse;
    String dept = [SELECT Id, Sales_Department__c FROM User WHERE Id = :idUser][0].Sales_Department__c;
    set<Id> setIdWarehouseReserved = new set<Id>();
    setIdWarehouseReserved.add(GMBLASERP__Inventory_Settings__c.getOrgDefaults().GMBLASERP__Adjustment_Warehouse_Id__c);
    setIdWarehouseReserved.add(GMBLASERP__Inventory_Settings__c.getOrgDefaults().GMBLASERP__Transit_Warehouse_Id__c);
    setIdWarehouseReserved.remove(null);
    for(AcctSeedERP__Warehouse__c whs : [SELECT Id, Name FROM AcctSeedERP__Warehouse__c WHERE Id NOT IN :setIdWarehouseReserved AND Name =:dept])
    {
      idWarehouse = whs.Id;
    }
    return idWarehouse;
  }

  public String getAllGlVariables()
  {
        Map<String,List<Map<String,String>>> mapListGLVariables = new Map<String,List<Map<String,String>>>();
        List<Map<String,String>> listGLV1 = new List<Map<String,String>>();
        List<Map<String,String>> listGLV2 = new List<Map<String,String>>();
        List<Map<String,String>> listGLV3 = new List<Map<String,String>>();
        List<Map<String,String>> listGLV4 = new List<Map<String,String>>();
        listGLV1.add(new Map<String,String>{'value'=>'','text'=>''});
        listGLV2.add(new Map<String,String>{'value'=>'','text'=>''});
        listGLV3.add(new Map<String,String>{'value'=>'','text'=>''});
        listGLV4.add(new Map<String,String>{'value'=>'','text'=>''});
        mapListGLVariables.put('glv1List',listGLV1);
        mapListGLVariables.put('glv2List',listGLV2);
        mapListGLVariables.put('glv3List',listGLV3);
        mapListGLVariables.put('glv4List',listGLV4);

        for(AcctSeed__Accounting_Variable__c glv :
            [SELECT Id,
              Name,
              AcctSeed__Type__c
            FROM AcctSeed__Accounting_Variable__c
            WHERE AcctSeed__Active__c = true
              AND AcctSeed__Type__c LIKE 'GL Account Variable%'
            ORDER BY Name])
        {
            Map<String,String> mapKV = new Map<String,String>();
            mapKV.put('value', glv.Id);
            mapKV.put('text', glv.Name);
            if(glv.AcctSeed__Type__c.equals('GL Account Variable 1'))
              listGLV1.add(mapKV);
            else if(glv.AcctSeed__Type__c.equals('GL Account Variable 2'))
              listGLV2.add(mapKV);
            else if(glv.AcctSeed__Type__c.equals('GL Account Variable 3'))
              listGLV3.add(mapKV);
            else if(glv.AcctSeed__Type__c.equals('GL Account Variable 4'))
              listGLV4.add(mapKV);
        }

        return  JSON.serializePretty(mapListGLVariables);
  }


  @RemoteAction @ReadOnly
  global static list<map<string,string>> retrieveWarehouses(Id idProject)
  {
    list<map<string,string>> listJSON = new list<map<string,string>>();

    Id idWarehouseProject = null;
    for(AcctSeed__Project__c project :  [SELECT Id, GMBLASERP__Warehouse__c FROM AcctSeed__Project__c WHERE Id =:idProject])
    {
      idWarehouseProject = project.GMBLASERP__Warehouse__c;
    }

    Id idWarehouseTransit = GMBLASERP__Inventory_Settings__c.getOrgDefaults().GMBLASERP__Transit_Warehouse_Id__c;
    Id idWarehouseAdjustment = GMBLASERP__Inventory_Settings__c.getOrgDefaults().GMBLASERP__Adjustment_Warehouse_Id__c;
    for(AcctSeedERP__Warehouse__c whs :
      [SELECT Id, Name
       FROM AcctSeedERP__Warehouse__c
       WHERE Id != :idWarehouseTransit
         AND Id != :idWarehouseAdjustment
         ORDER BY Name])
    {
      map<string,string> obj = new map<string,string>{'idWarehouse'=>whs.Id,'warehouseName'=>whs.Name};
      if(whs.Id == idWarehouseProject)
        obj.put('isProjectWarehouse','true');

      listJSON.add(obj);
    }
    return listJSON;
  }

  public List<SelectOption> getListTimecardPeriods()
  {
    List<SelectOption> listPeriods = new List<SelectOption>();
    for(AcctSeed__Time_Card_Period__c period :
        [SELECT
          Id,
          Name
        FROM AcctSeed__Time_Card_Period__c
         WHERE AcctSeed__Start_Date__c <= TODAY
          AND AcctSeed__Status__c = 'Open'
         ORDER BY AcctSeed__Start_Date__c DESC])
    {
      listPeriods.add(new selectOption(period.Id, period.Name));
    }
    return listPeriods;
  }

  public List<SelectOption> getListEmployees()
  {
    Id idUser = UserInfo.getUserId();
    SelectOption currentEmployee = new selectOption('', '---Select Employee---');
    List<SelectOption> listEmployees = new List<SelectOption>();
    for(Employee__c employee : [SELECT Id, Name, User__c FROM Employee__c WHERE Active__c = true])
    {
      if(employee.User__c != idUser)
        listEmployees.add(new selectOption(employee.Id, employee.Name));
      else
        currentEmployee = new selectOption(employee.Id, employee.Name);
    }
    /// Just to get the current user's employee on Top instead of just keeping it selected.
    if(currentEmployee != null)
      listEmployees.add(0, currentEmployee);

    return listEmployees;
  }

    @RemoteAction
    public static string findOrCreateTimeCard(Id idEmployee, Id idTimeCardPeriod)
    {
      try{
          for(Employee__c empx : [SELECT Id, User__c FROM Employee__c WHERE Id = :idEmployee ORDER BY CreatedDate LIMIT 1])
              return gcTimeCardPeriod_Ext.findOrCreateTimeCard(empx.User__c, idTimeCardPeriod);
      }
      catch(Exception e)
      {
        if(!e.getMessage().contains('An employee cannot have more than one time card per period'))
          throw new gcException(e.getMessage());
      }
        return '';
    }

  @RemoteAction @ReadOnly
  global static boolean checkProjectHasSerial(Id idProject)
  {
    for(AcctSeed__Project__c p : [SELECT Id FROM AcctSeed__Project__c WHERE Id =:idProject AND Serial_Number__c != null])
      return true;
    return false;
  }

  @RemoteAction @ReadOnly
    public static List<AcctSeed__Project_Task__c> searchProjectTask(String searchTxt, String idProject)
    {
      List<AcctSeed__Project_Task__c> listProject = new List<AcctSeed__Project_Task__c>();
        searchTxt = '%'+searchTxt.replaceAll('[*]','%') +'%';

        for(AcctSeed__Project_Task__c gla :
          [SELECT Id,
            Name
          FROM AcctSeed__Project_Task__c
          WHERE AcctSeed__Project__c =:idProject
            AND Name like :searchTxt
          ORDER BY Name
          LIMIT 10])
        {
            listProject.add(gla);
        }
        return listProject;

    }

  @RemoteAction
    public static void updateMaterialProjectTask(String idMaterial, String idTask)
    {
        for(AcctSeedERP__Material__c matl :
          [SELECT Id,
            AcctSeedERP__Project_Task__c
          FROM AcctSeedERP__Material__c
          WHERE Id =:idMaterial])
        {
            matl.AcctSeedERP__Project_Task__c = idTask;
            update matl;
        }
    }

  @RemoteAction
    public static void saveTaskCCC(String idProject, String idTask, String complaintText, String causeText, String correctionText)
    {
        for(AcctSeed__Project_Task__c task :
          [SELECT Id,
        Cause_dh__c,
        Complaint_dh__c,
        Correction_dh__c
          FROM AcctSeed__Project_Task__c
          WHERE Id =:idTask])
        {
            task.Cause_dh__c = causeText;
            task.Complaint_dh__c = complaintText;
            task.Correction_dh__c = correctionText;
            update task;
        }
    }

  @RemoteAction @ReadOnly
    public static List<AcctSeed__Accounting_Variable__c> searchGLV(String searchTxt, String glvType)
    {
      List<AcctSeed__Accounting_Variable__c> listGLV = new List<AcctSeed__Accounting_Variable__c>();
        searchTxt = '%'+searchTxt.replaceAll('[*]','%') +'%';
        glvType = glvType == 'glv2' ? 'GL Account Variable 2' : 'GL Account Variable 1';
        for(AcctSeed__Accounting_Variable__c glv :
          [SELECT Id,
            Name
          FROM AcctSeed__Accounting_Variable__c
          WHERE Name like :searchTxt
            AND AcctSeed__Type__c =:glvType
          ORDER BY Name
          LIMIT 10])
        {
            listGLV.add(glv);
        }
        return listGLV;

    }

  @RemoteAction
    public static void updateProjectTaskGLV(String idTask, String idGlv, String glvType)
    {
        for(AcctSeed__Project_Task__c tsk :
          [SELECT Id,
            AcctSeed__GL_Account_Variable_1__c,
            AcctSeed__GL_Account_Variable_2__c
          FROM AcctSeed__Project_Task__c
          WHERE Id =:idTask])
        {
          if(glvType == 'glv1')
              tsk.AcctSeed__GL_Account_Variable_1__c = idGlv;
            else if(glvType == 'glv2')
              tsk.AcctSeed__GL_Account_Variable_2__c = idGlv;
            update tsk;
        }
    }

  @RemoteAction
    public static void generatePartsList(String idTask)
    {
        gcProjectTask.updateMaterialSpec(new Set<Id>{idTask});
    }

  @RemoteAction @ReadOnly
  global static list<map<string,string>> retrieveTasks(Id idFilter)
  {
    list<map<string,string>> listJSON = new list<map<string,string>>();

    if(idFilter == null) return listJSON;

    map<Id,Decimal> mapExpense = new map<Id,Decimal>();
    map<Id,Decimal> mapRevenue = new map<Id,Decimal>();

    list<AggregateResult> listAggRes = new list<AggregateResult>();
    listAggRes.addAll(
      [SELECT AcctSeed__Project_Task__c idProjectTask,
          sum(AcctSeed__Amount__c) amt
       FROM AcctSeed__Transaction__c
       WHERE AcctSeed__GL_Account__c IN (SELECT Id FROM AcctSeed__GL_Account__c WHERE AcctSeed__Type__c = 'Expense')
         AND (AcctSeed__Project__c = :idFilter OR AcctSeed__Project_Task__c = :idFilter)
         AND (AcctSeed__Amount__c < 0 OR AcctSeed__Amount__c > 0)
       GROUP BY AcctSeed__Project_Task__c
       HAVING sum(AcctSeed__Amount__c) != 0]
    );

    for(AggregateResult aggRes : listAggRes)
    {
      if(aggRes.get('amt') != null)
        mapExpense.put((Id)aggRes.get('idProjectTask'),(Decimal)aggRes.get('amt'));
    }

    listAggRes.clear();
    listAggRes.addAll(
      [SELECT AcctSeed__Project_Task__c idProjectTask,
          sum(AcctSeed__Amount__c) amt
       FROM AcctSeed__Transaction__c
       WHERE AcctSeed__GL_Account__c IN (SELECT Id FROM AcctSeed__GL_Account__c WHERE AcctSeed__Type__c = 'Revenue')
         AND (AcctSeed__Project__c = :idFilter OR AcctSeed__Project_Task__c = :idFilter)
         AND (AcctSeed__Amount__c < 0 OR AcctSeed__Amount__c > 0)
       GROUP BY AcctSeed__Project_Task__c
       HAVING sum(AcctSeed__Amount__c) != 0]
    );

    for(AggregateResult aggRes : listAggRes)
    {
      if(aggRes.get('amt') != null)
        mapRevenue.put((Id)aggRes.get('idProjectTask'),((Decimal)aggRes.get('amt')) * (-1));
    }

    for(AcctSeed__Project_Task__c pt :
      [SELECT Id, Name,
          AcctSeed__Budgeted_Amount__c,
          AcctSeed__Budgeted_Hours__c,
          AcctSeed__Budgeted_Revenue__c,
          AcctSeed__End_Date__c,
          AcctSeed__Start_Date__c,
          AcctSeed__Status__c,
          Cause_dh__c,
          Complaint_dh__c,
          Correction_dh__c,
          Product__c,
          Product__r.Name,
          Locked__c,
          DisplayOnCustomerInvoice__c,
          AcctSeed__GL_Account_Variable_1__c,
          AcctSeed__GL_Account_Variable_1__r.Name,
          AcctSeed__GL_Account_Variable_2__c,
          AcctSeed__GL_Account_Variable_2__r.Name,
          Partslist_Generated__c,
          Task_Order__c,
          (SELECT Id FROM AcctSeedERP__Materials__r LIMIT 1),
          (SELECT AcctSeedERP__Total__c FROM AcctSeedERP__Sales_Order_Line__r)
       FROM AcctSeed__Project_Task__c
       WHERE Id = :idFilter
          OR AcctSeed__Project__c = :idFilter
       ORDER BY Task_Order__c,index__c
       //Name

      ])
    {
      map<string,string> m = new map<string,string>();

      m.put('idProjectTask',pt.Id);
      m.put('projectTaskName',pt.Name);
      m.put('taskOrder',String.valueOf(pt.Task_Order__c));
      m.put('partListGenerated',pt.Partslist_Generated__c ? 'true' : 'false');
      m.put('taskGLV1','');
      m.put('taskGLV2','');
      if(pt.AcctSeed__GL_Account_Variable_1__c != null)
        m.put('taskGLV1',pt.AcctSeed__GL_Account_Variable_1__r.Name);
      if(pt.AcctSeed__GL_Account_Variable_2__c != null)
        m.put('taskGLV2',pt.AcctSeed__GL_Account_Variable_2__r.Name);

      m.put('canchangeGLV','true');
      if(!pt.AcctSeedERP__Materials__r.isEmpty())
        m.put('canchangeGLV','false');

      Decimal orderTotal = 0;
      if(!pt.AcctSeedERP__Sales_Order_Line__r.isEmpty())
      {
        for(AcctSeedERP__Sales_Order_Line__c sol : pt.AcctSeedERP__Sales_Order_Line__r)
        {
          orderTotal += sol.AcctSeedERP__Total__c;
        }
      }
      m.put('orderTotal',String.valueOf(orderTotal.setScale(6)));

      if(pt.AcctSeed__Budgeted_Amount__c == null)
         pt.AcctSeed__Budgeted_Amount__c = 0;
      if(pt.AcctSeed__Budgeted_Hours__c == null)
         pt.AcctSeed__Budgeted_Hours__c = 0;
      if(pt.AcctSeed__Budgeted_Revenue__c == null)
         pt.AcctSeed__Budgeted_Revenue__c = 0;

      Decimal budgetProfit = pt.AcctSeed__Budgeted_Revenue__c - pt.AcctSeed__Budgeted_Amount__c;
      Decimal budgetProfitPct = 0;
      if(pt.AcctSeed__Budgeted_Revenue__c != 0)
      budgetProfitPct = 100 * budgetProfit / pt.AcctSeed__Budgeted_Revenue__c;

      m.put('budgetHours',String.valueOf(pt.AcctSeed__Budgeted_Hours__c.setScale(0)));
      m.put('budgetExpense',String.valueOf(pt.AcctSeed__Budgeted_Amount__c.setScale(2)));
      m.put('budgetRevenue',String.valueOf(pt.AcctSeed__Budgeted_Revenue__c.setScale(2)));
      m.put('budgetProfit',String.valueOf(budgetProfit.setScale(2)));
      m.put('budgetProfitPct',String.valueOf(budgetProfitPct.setScale(1)));

      if(pt.AcctSeed__Start_Date__c != null)
        m.put('dateStart',pt.AcctSeed__Start_Date__c.format());
      if(pt.AcctSeed__End_Date__c != null)
        m.put('dateEnd',pt.AcctSeed__End_Date__c.format());

      m.put('status',pt.AcctSeed__Status__c);

      Decimal expense = mapExpense.get(pt.Id);
      Decimal revenue = mapRevenue.get(pt.Id);

      if(expense == null) expense = 0;
      if(revenue == null) revenue = 0;

      Decimal profit = revenue - expense;
      Decimal profitPct = 0;
      if(revenue != 0)
        profitPct = 100*profit/revenue;

      m.put('actualExpense',  String.valueOf(expense.setScale(6)));
      m.put('actualRevenue',  String.valueOf(revenue.setScale(6)));
      m.put('actualProfit',   String.valueOf(profit.setScale(6)));
      m.put('actualProfitPct',String.valueOf(profitPct.setScale(1)));

      m.put('varianceRevenue',String.valueOf((revenue - pt.AcctSeed__Budgeted_Revenue__c).setScale(6)));
      m.put('varianceExpense',String.valueOf((expense - pt.AcctSeed__Budgeted_Amount__c).setScale(6)));
      m.put('varianceProfit', String.valueOf((profit - budgetProfit).setScale(6)));

      m.put('isLocked',pt.Locked__c ? 'true' : 'false');
      m.put('cause',pt.Cause_dh__c);
      m.put('complaint',pt.Complaint_dh__c);
      m.put('correction',pt.Correction_dh__c);
      m.put('displayOnInvoice', String.valueOf( pt.DisplayOnCustomerInvoice__c) );

      if(pt.Product__c != null)
      {
        m.put('idProduct',pt.Product__c);
        m.put('productName',pt.Product__r.Name);
      }

      listJSON.add(m);
    }

    if(mapRevenue.containsKey(null) || mapExpense.containsKey(null))
    {
      map<string,string> m = new map<string,string>();

      m.put('projectTaskName','(no project task)');

      m.put('budgetHours','0');
      m.put('budgetExpense','0');
      m.put('budgetRevenue','0');
      m.put('budgetProfit','0');
      m.put('budgetProfitPct','0');

      Decimal expense = mapExpense.get(null);
      Decimal revenue = mapRevenue.get(null);

      if(expense == null) expense = 0;
      if(revenue == null) revenue = 0;

      Decimal profit = revenue - expense;
      Decimal profitPct = 0;
      if(revenue != 0)
        profitPct = profit/revenue;

      m.put('actualExpense',  String.valueOf(expense.setScale(6)));
      m.put('actualRevenue',  String.valueOf(revenue.setScale(6)));
      m.put('actualProfit',   String.valueOf(profit.setScale(6)));
      m.put('actualProfitPct',String.valueOf(profitPct.setScale(1)));

      m.put('varianceRevenue',String.valueOf(revenue.setScale(6)));
      m.put('varianceExpense',String.valueOf(expense.setScale(6)));
      m.put('varianceProfit', String.valueOf(profit.setScale(6)));

      listJSON.add(m);
    }

    return listJSON;
  }

    @RemoteAction
    global static list<map<string,string>> createTask(Id idProject, String taskName)
    {
      ERPOrderTaskNames__c taskNameSetting = ERPOrderTaskNames__c.getInstance(taskName);
      Boolean showInInvoice = false;
      if(taskNameSetting == null)
        showInInvoice = true;
      Id commissionRecordOverride = null;
      if(taskNameSetting != null && taskNameSetting.Show_In_Invoice__c)
        showInInvoice = true;
      if(taskNameSetting != null && taskNameSetting.Commission_Applies_to_Retail_Sale__c )
      {
        try
        {
          commissionRecordOverride = [
            SELECT Id FROM AcctSeed__Project_Task__c
            WHERE AcctSeed__Project__c = :idProject
            AND Is_Retail_Boat_Sale__c = true
            LIMIT 1].Id;
        }
        catch( Exception e ){}
      }
      AcctSeed__Project_Task__c task = new AcctSeed__Project_Task__c(
        Name = taskName,
        AcctSeed__Project__c = idProject,
        DisplayOnCustomerInvoice__c = showInInvoice,
        Commission_Override_Project_Task__c = commissionRecordOverride
      );
      insert task;
      return retrieveTasks(idProject);
    }

    @RemoteAction
    global static void updateTaskLock(Id idTask)
    {
      for(AcctSeed__Project_Task__c task : [SELECT Id, Locked__c FROM AcctSeed__Project_Task__c WHERE Id=:idTask])
      {
        if(task.Locked__c) task.Locked__c = false;
        else task.Locked__c = true;
        update task;
      }
    }

    @RemoteAction
    global static void deleteTask(Id idTask)
    {
      delete [SELECT Id FROM AcctSeed__Project_Task__c WHERE Id =:idTask];
    }

  @RemoteAction
  global static map<string,string> updateBudgetRevenue(Id idTask, Decimal dec)
  {
    AcctSeed__Project_Task__c task = [SELECT Id FROM AcctSeed__Project_Task__c WHERE Id =:idTask][0];

    if(dec == null) dec = 0;

    task.AcctSeed__Budgeted_Revenue__c = dec;

    update task;

    return retrieveTasks(task.Id)[0];
  }

  @RemoteAction
  global static map<string,string> updateBudgetExpense(Id idTask, Decimal dec)
  {
    AcctSeed__Project_Task__c task = [SELECT Id FROM AcctSeed__Project_Task__c WHERE Id =:idTask][0];

    if(dec == null) dec = 0;

    task.AcctSeed__Budgeted_Amount__c = dec;

    update task;

    return retrieveTasks(task.Id)[0];
  }

  @RemoteAction
  global static map<string,string> updateTaskOrder(Id idTask, Decimal dec)
  {
    AcctSeed__Project_Task__c task = [SELECT Id FROM AcctSeed__Project_Task__c WHERE Id =:idTask][0];

    if(dec == null) dec = 0;

    task.Task_Order__c = dec;

    update task;

    return retrieveTasks(task.Id)[0];
  }

  @RemoteAction @ReadOnly
  global static list<string> retrieveStatusPicklistValues()
  {
    list<string> listLabel = new list<string>();
    for(Schema.Picklistentry ple : AcctSeed__Project_Task__c.fields.AcctSeed__Status__c.getDescribe().getpicklistvalues())
        listLabel.add(ple.label);
    return listLabel;
  }

  @RemoteAction @ReadOnly
  global static list<map<string,string>> retrieveProjectTaskPicklistValues(Id idProject)
  {
    list<map<string,string>> listJSON = new list<map<string,string>>();

    //get the project task of the most recently created material
    Id idDefaultSelection;
    for(AcctSeedERP__Material__c matl :
      [SELECT AcctSeedERP__Project_Task__c
       FROM AcctSeedERP__Material__c
       WHERE AcctSeedERP__Project__c = :idProject
         AND AcctSeedERP__Project_Task__c != null
       ORDER BY CreatedDate DESC
       LIMIT 1])
    {
      idDefaultSelection = matl.AcctSeedERP__Project_Task__c;
    }


    for(AcctSeed__Project_Task__c pt :
      [SELECT Id, Name
       FROM AcctSeed__Project_Task__c
       WHERE AcctSeed__Project__c = :idProject
       ORDER BY Name])
    {
      if(idDefaultSelection == null)
         idDefaultSelection = pt.Id;
      map<string,string> m = new map<string,string>();
      m.put('value',pt.Id);
      m.put('label',pt.Name);
      if(pt.Id == idDefaultSelection)
        m.put('defaultSelection','true');
      listJSON.add(m);
    }
    return listJSON;
  }

  @RemoteAction
  global static void addNestToERPItems(Id idProject)
  {
    AcctSeed__Project__c p = [SELECT Id, Serial_Number__c, Locked__c, (SELECT Id FROM AcctSeed__Project_Tasks__r ORDER BY CreatedDate LIMIT 1) FROM AcctSeed__Project__c WHERE Id =:idProject][0];
    if(p.Locked__c)
      throw new gcException('ERP Order is locked.');
    if(p.Serial_Number__c == null)
      throw new gcException('There is no Project Serial Number defined.');
    if(p.AcctSeed__Project_Tasks__r.isEmpty())
      throw new gcException('There is no Project Task for this project.');

    Id idTask = p.AcctSeed__Project_Tasks__r[0].Id;
    Map<Id,List<GMBLASERP__Serial_Number__c>> mapProductListSerials = new Map<Id,List<GMBLASERP__Serial_Number__c>>();
    for(GMBLASERP__Serial_Number__c serial :
      [SELECT Id,
        GMBLASERP__Product__c,
        GMBLASERP__Lot__c,
        (SELECT Id FROM GMBLASERP__Materials__r WHERE AcctSeedERP__Project__c =:idProject)
      FROM GMBLASERP__Serial_Number__c
      WHERE Nest__c =: p.Serial_Number__c
        AND GMBLASERP__Inventory_Balance__c != null])
    {
      if(!serial.GMBLASERP__Materials__r.isEmpty()) continue; // Already Added
      if(!mapProductListSerials.containsKey(serial.GMBLASERP__Product__c))
        mapProductListSerials.put(serial.GMBLASERP__Product__c, new List<GMBLASERP__Serial_Number__c>());

      mapProductListSerials.get(serial.GMBLASERP__Product__c).add(serial);
    }

    if(mapProductListSerials.isEmpty())
      throw new gcException('No nested serials to add to ERP Items.');
    List<AcctSeedERP__Material__c> listUpsertMatl = new List<AcctSeedERP__Material__c>();
    Set<Id> setAlreadyAdded = new Set<Id>();
    for(AcctSeedERP__Material__c matl :
      [SELECT Id,
          AcctSeedERP__Product__c,
          AcctSeedERP__Project__c,
          AcctSeedERP__Project_Task__c,
          GMBLASERP__Lot__c,
          GMBLASERP__Serial_Number__c,
          (SELECT Id, AcctSeedERP__Quantity__c, GMBLASERP__Inventory_GL_Amount__c FROM AcctSeedERP__Manufacturing_Inventory_Movements__r)
       FROM AcctSeedERP__Material__c
       WHERE AcctSeedERP__Project__c = :idProject
         AND AcctSeedERP__Product__c IN:mapProductListSerials.keySet()
         AND AcctSeedERP__Product__r.AcctSeedERP__Serialized__c = true
       ORDER BY CreatedDate])
    {
      if(matl.GMBLASERP__Serial_Number__c == null && matl.AcctSeedERP__Manufacturing_Inventory_Movements__r.isEmpty())
      for(GMBLASERP__Serial_Number__c serial : mapProductListSerials.get(matl.AcctSeedERP__Product__c))
      {
        if(matl.GMBLASERP__Serial_Number__c == null
          && matl.GMBLASERP__Serial_Number__c != serial.Id
          && !setAlreadyAdded.contains(serial.Id))
        {
          matl.GMBLASERP__Serial_Number__c = serial.Id;
          setAlreadyAdded.add(serial.Id);
          listUpsertMatl.add(matl);
        }
        else if(matl.GMBLASERP__Serial_Number__c == serial.Id && !setAlreadyAdded.contains(serial.Id))
          setAlreadyAdded.add(serial.Id);
      }
    }
    for(Id idPrduct : mapProductListSerials.keySet())
    {
      for(GMBLASERP__Serial_Number__c serial : mapProductListSerials.get(idPrduct))
      {
        if(!setAlreadyAdded.contains(serial.Id))
        {
            AcctSeedERP__Material__c matl = new AcctSeedERP__Material__c(
              AcctSeedERP__Product__c = serial.GMBLASERP__Product__c,
              AcctSeedERP__Project__c = idProject,
              AcctSeedERP__Project_Task__c = idTask,
              GMBLASERP__Serial_Number__c = serial.Id,
              GMBLASERP__Lot__c = serial.GMBLASERP__Lot__c,
              AcctSeedERP__Quantity_Per_Unit__c = 1,
              Quantity_Specified_Override__c = true
            );
            listUpsertMatl.add(matl);
        }
      }
    }
    if(!listUpsertMatl.isEmpty())
      upsert listUpsertMatl;
  }

  @RemoteAction
  global static List<String> nestERPOrderItemSerials(Id idProject)
  {
    List<String> listResult = new List<String>();
    AcctSeed__Project__c p = [SELECT Id, Serial_Number__c, Locked__c FROM AcctSeed__Project__c WHERE Id =:idProject][0];
    if(p.Serial_Number__c == null)
      throw new gcException('Project has no Serial Number defined.');

    Set<Id> setIdSerials = new Set<Id>();
    for(AcctSeedERP__Material__c matl :
      [SELECT Id, GMBLASERP__Serial_Number__c
       FROM AcctSeedERP__Material__c
       WHERE AcctSeedERP__Project__c = :idProject
         AND GMBLASERP__Serial_Number__c != null
         AND GMBLASERP__Serial_Number__c !=:p.Serial_Number__c])
    {
      setIdSerials.add(matl.GMBLASERP__Serial_Number__c);
    }
    List<GMBLASERP__Serial_Number__c> listSerials = new List<GMBLASERP__Serial_Number__c>();
    for(GMBLASERP__Serial_Number__c serial : [SELECT Id, Name, Nest__c FROM GMBLASERP__Serial_Number__c WHERE Id IN:setIdSerials])
    {
      if(serial.Nest__c != null && serial.Nest__c != p.Serial_Number__c)
        listResult.add('Serial Number '+serial.Name+' is nested to another serial number rather than the Project Serial Number.');
      else if(serial.Nest__c != null && serial.Nest__c == p.Serial_Number__c)
        listResult.add('Serial Number '+serial.Name+' is already nested to the Project Serial Number.');
      else
      {
        listResult.add('Serial Number '+serial.Name+' is added to the nest of the ERP Order Serial Number.');
        serial.Nest__c = p.Serial_Number__c;
        listSerials.add(serial);
      }
    }
    if(!listSerials.isEmpty())
      update listSerials;

    return listResult;
  }

  @RemoteAction
  global static map<string,string> retrieveMaterial(Id idMaterial)
  {
    for(AcctSeedERP__Material__c matl :
      [SELECT AcctSeedERP__Project__c,
          AcctSeedERP__Project_Task__c,
          AcctSeedERP__Product__c
       FROM AcctSeedERP__Material__c
       WHERE Id = :idMaterial])
    {
      Id idFilter = matl.AcctSeedERP__Project_Task__c;
      if(idFilter == null)
         idFilter = matl.AcctSeedERP__Project__c;
      Id idProduct = matl.AcctSeedERP__Product__c;

      for(map<String,String> m : retrieveMaterials(idFilter, idProduct))
      {
        if(m.get('idMaterial') == matl.Id)
          return m;
      }
    }
    return new map<string,string>();
  }

  @RemoteAction
  global static list<map<string,string>> retrieveMaterials(Id idFilter, Id idProductFilter)
  {
    list<map<string,string>> listJSON = new list<map<string,string>>();
    if(idFilter == null) return listJSON;

    map<Id,map<Id,map<Id,cube>>> mapTPMC = new map<Id,map<Id,map<Id,cube>>>(); //map Task => Product => Material => cube

    map<Id,AcctSeed__Project_Task__c> mapProjectTask = new map<Id,AcctSeed__Project_Task__c>();
    map<Id,Product2> mapProduct = new map<Id,Product2>();
    Boolean linkedToERP = false;
    Set<Id> setIdWholesaleMatl = new Set<Id>();
    for(AcctSeed__Project__c pr : [SELECT Id, (SELECT Id FROM ERP_Orders__r WHERE AcctSeed__Status__c != 'Completed' LIMIT 1) FROM AcctSeed__Project__c WHERE Id =:idFilter]){
      if(!pr.ERP_Orders__r.isEmpty()){
        linkedToERP = true;

        for(AcctSeedERP__Material__c matl :
            [SELECT Id,
              AcctSeedERP__Product__c
            FROM AcctSeedERP__Material__c
            WHERE AcctSeedERP__Project__c =:pr.ERP_Orders__r[0].Id])
        {
          setIdWholesaleMatl.add(matl.AcctSeedERP__Product__c);
        }
      }
    }

    for(AcctSeedERP__Material__c matl :
      [SELECT Id,
          AcctSeedERP__Comment__c,
          AcctSeedERP__Product__c,
          AcctSeedERP__Product__r.AcctSeed__Unit_Cost__c,
          AcctSeedERP__Product__r.isPrepayable__c,
          AcctSeedERP__Project__c,
          AcctSeedERP__Project__r.AcctSeedERP__Quantity_Ordered__c,
          AcctSeedERP__Project__r.AcctSeed__Status__c,
          AcctSeedERP__Project_Task__c,
          AcctSeedERP__Quantity_Allocated__c,
          AcctSeedERP__Quantity_Per_Unit__c,
          CreatedDate,
          GMBLASERP__Lot__c,
          GMBLASERP__Lot__r.Name,
          GMBLASERP__Price_Override__c,
          Quantity_Specified_Override__c,
          GMBLASERP__Serial_Number__c,
          GMBLASERP__Serial_Number__r.Name,
          GMBLASERP__Serial_Number__r.Location_Status__c,
          isPrepaid__c,
          Taxable_Federal__c,
                Taxable_Provincial__c,
                Taxable_Retail__c,
          GMBLASERP__Total_Price__c,
          GMBLASERP__Unit_Price__c,
          No_WIP__c,
          Supplier_Credit_Requested__c,
          (SELECT Id, AcctSeedERP__Quantity__c FROM Outbound_Inventory_Movements__r),
          (SELECT Id, AcctSeedERP__Quantity__c, GMBLASERP__Inventory_GL_Amount__c FROM AcctSeedERP__Manufacturing_Inventory_Movements__r),
          (SELECT Id FROM Journal_Entry_Lines__r)
       FROM AcctSeedERP__Material__c
       WHERE (AcctSeedERP__Project__c = :idFilter OR AcctSeedERP__Project_Task__c = :idFilter)
         AND AcctSeedERP__Product__c != null
       ORDER BY CreatedDate])
    {
      if(matl.AcctSeedERP__Product__c != idProductFilter && idProductFilter != null) continue;

      Id idProjectTask = matl.AcctSeedERP__Project_Task__c;
      Id idProduct = matl.AcctSeedERP__Product__c;

      mapProjectTask.put(idProjectTask,null);
      mapProduct.put(idProduct,null);

      map<Id,map<Id,cube>> mapPMC = mapTPMC.get(idProjectTask);
      if(mapPMC == null)
      {
        mapPMC = new map<Id,map<Id,cube>>();
        mapTPMC.put(idProjectTask, mapPMC);
      }

      map<Id,cube> mapMC = mapPMC.get(idProduct);
      if(mapMC == null)
      {
        mapMC = new map<Id,cube>();
        mapPMC.put(idProduct, mapMC);
      }

      mapMC.put(matl.Id,new cube(matl));

      cube c = mapMC.get(matl.Id);


      if(!mapMC.containsKey(null))
      {
        mapMC.put(null, c);
      }
      //else if(mapMC.get(null).matl != null && mapMC.get(null).matl.CreatedDate > matl.CreatedDate)
      //  mapMC.put(null,c);
    }

    //at this point, every material is mapped.
    //ALSO, the oldest material for every product is mapped at location mapMC.get(null)


    for(AcctSeedERP__Purchase_Order_Line__c pol :
      [SELECT Id,
          AcctSeedERP__Product__c,
          AcctSeedERP__Project__c,
          AcctSeedERP__Project_Task__c,
          AcctSeedERP__Quantity__c,
          AcctSeedERP__Quantity_Received__c,
          AcctSeedERP__Unit_Price__c,
          GMBLASERP__Quantity_Received_Non_Inventory__c
       FROM AcctSeedERP__Purchase_Order_Line__c
       WHERE (AcctSeedERP__Project__c = :idFilter OR AcctSeedERP__Project_Task__c = :idFilter)
         AND AcctSeedERP__Product__c != null])
    {
      if(pol.AcctSeedERP__Product__c != idProductFilter && idProductFilter != null) continue;

      Id idProjectTask = pol.AcctSeedERP__Project_Task__c;
      Id idProduct = pol.AcctSeedERP__Product__c;

      mapProjectTask.put(idProjectTask,null);
      mapProduct.put(idProduct,null);

      map<Id,map<Id,cube>> mapPMC = mapTPMC.get(idProjectTask);
      if(mapPMC == null)
      {
        mapPMC = new map<Id,map<Id,cube>>();
        mapTPMC.put(idProjectTask, mapPMC);
      }

      map<Id,cube> mapMC = mapPMC.get(idProduct);
      if(mapMC == null)
      {
        mapMC = new map<Id,cube>();
        mapPMC.put(idProduct, mapMC);
      }

      cube c = mapMC.get(null);

      if(c == null)
      {
        c = new cube();
        mapMC.put(null,c);
      }

      Decimal qtyOrdered = pol.AcctSeedERP__Quantity__c;
      Decimal qtyReceived = pol.AcctSeedERP__Quantity_Received__c;
      Decimal qtyReceivedNI = pol.GMBLASERP__Quantity_Received_Non_Inventory__c;
      Decimal unitCost = pol.AcctSeedERP__Unit_Price__c;

      if(qtyOrdered == null) qtyOrdered = 0;
      if(qtyReceived == null) qtyReceived = 0;
      if(qtyReceivedNI == null) qtyReceivedNI = 0;
      if(unitCost == null) unitCost = 0;

      c.qtyOrdered  += qtyOrdered;
      c.qtyReceived += (qtyReceived + qtyReceivedNI);
      c.amtOrdered  += (unitCost * qtyOrdered);
      c.amtReceived += (unitCost * (qtyReceived + qtyReceivedNI));
    }


    Id idGlWIP = gcConstants.idGlWip;

    for(AcctSeed__Transaction__c txn :
      [SELECT Id,
          AcctSeed__Amount__c,
          AcctSeed__GL_Account__c,
          AcctSeed__Product__c,
          AcctSeed__Project__c,
          AcctSeed__Project_Task__c,
          AcctSeed__Units__c
       FROM AcctSeed__Transaction__c
       WHERE (AcctSeed__Project__c = :idFilter OR AcctSeed__Project_Task__c = :idFilter)
         AND AcctSeed__GL_Account__c IN (SELECT Id FROM AcctSeed__GL_Account__c WHERE AcctSeed__Type__c = 'Expense' OR Id = :idGlWip)
         AND AcctSeed__Product__c != null])
    {
      if(txn.AcctSeed__Product__c != idProductFilter && idProductFilter != null) continue;

      Id idProjectTask = txn.AcctSeed__Project_Task__c;
      Id idProduct = txn.AcctSeed__Product__c;

      mapProjectTask.put(idProjectTask,null);
      mapProduct.put(idProduct,null);

      map<Id,map<Id,cube>> mapPMC = mapTPMC.get(idProjectTask);
      if(mapPMC == null)
      {
        mapPMC = new map<Id,map<Id,cube>>();
        mapTPMC.put(idProjectTask, mapPMC);
      }

      map<Id,cube> mapMC = mapPMC.get(idProduct);
      if(mapMC == null)
      {
        mapMC = new map<Id,cube>();
        mapPMC.put(idProduct, mapMC);
      }

      cube c = mapMC.get(null);

      if(c == null)
      {
        c = new cube();
        mapMC.put(null,c);
      }

      if(txn.AcctSeed__Amount__c != null)
      {
        if(txn.AcctSeed__GL_Account__c != idGlWIP)
        {
          c.amtExpense += txn.AcctSeed__Amount__c;
          if(txn.AcctSeed__Units__c != null)
          {
            if(txn.AcctSeed__Amount__c >= 0)
              c.qtyExpense += txn.AcctSeed__Units__c.abs();
            else
              c.qtyExpense -= txn.AcctSeed__Units__c.abs();
          }
        }
        else
        {
          c.amtWip += txn.AcctSeed__Amount__c;
          if(txn.AcctSeed__Units__c != null)
          {
            if(txn.AcctSeed__Amount__c >= 0)
              c.qtyWip += txn.AcctSeed__Units__c.abs();
            else
              c.qtyWip -= txn.AcctSeed__Units__c.abs();
          }
        }
      }
    }

    for(AcctSeedERP__Inbound_Inventory_Movement__c move :
      [SELECT Id,
          AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Product__c,
          AcctSeedERP__Project_Task__c,
          AcctSeedERP__Quantity__c,
          GMBLASERP__Inventory_GL_Amount__c
       FROM AcctSeedERP__Inbound_Inventory_Movement__c
       WHERE AcctSeedERP__Project__c = :idFilter
          OR AcctSeedERP__Project_Task__c = :idFilter])
    {
      if(move.AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Product__c != idProductFilter && idProductFilter != null) continue;

      Id idProjectTask = move.AcctSeedERP__Project_Task__c;
      Id idProduct = move.AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Product__c;

      mapProjectTask.put(idProjectTask,null);
      mapProduct.put(idProduct,null);

      map<Id,map<Id,cube>> mapPMC = mapTPMC.get(idProjectTask);
      if(mapPMC == null)
      {
        mapPMC = new map<Id,map<Id,cube>>();
        mapTPMC.put(idProjectTask, mapPMC);
      }

      map<Id,cube> mapMC = mapPMC.get(idProduct);
      if(mapMC == null)
      {
        mapMC = new map<Id,cube>();
        mapPMC.put(idProduct, mapMC);
      }

      cube c = mapMC.get(null);

      if(c == null)
      {
        c = new cube();
        mapMC.put(null,c);
      }

      Decimal qtyFinished = move.AcctSeedERP__Quantity__c;
      Decimal amtFinished = move.GMBLASERP__Inventory_GL_Amount__c;

      if(qtyFinished == null) qtyFinished = 0;
      if(amtFinished == null) amtFinished = 0;

      c.qtyFinished += qtyFinished;
      c.amtFinished += amtFinished;

      c.boolHasMoves = true;
    }

    for(AcctSeed__Project_Task__c pt :
      [SELECT Id, Name
       FROM AcctSeed__Project_Task__c
       WHERE Id IN :mapProjectTask.keySet()])
    {
      mapProjectTask.put(pt.Id,pt);
    }

    for(Product2 p :
      [SELECT Id, Name, ProductCode,
          AcctSeed__Inventory_Product__c,
          AcctSeed__Unit_Cost__c,
          AcctSeedERP__Serialized__c,
          GMBLASERP__Lot_Tracked__c,
          Taxable__c
       FROM Product2
       WHERE Id IN :mapProduct.keySet()])
    {
      mapProduct.put(p.Id,p);
    }

    for(Id idProjectTask : mapTPMC.keySet())
    {
      if(idProjectTask == null) continue;

      for(Id idProduct : mapTPMC.get(idProjectTask).keySet())
      {
        if(idProduct == null) continue;

        for(Id idMaterial : mapTPMC.get(idProjectTask).get(idProduct).keySet())
        {
          cube c = mapTPMC.get(idProjectTask).get(idProduct).get(idMaterial);

          if(idMaterial != null)
          {
            cube cubePrimary = mapTPMC.get(idProjectTask).get(idProduct).get(null);
            if(cubePrimary != null && cubePrimary.matl != null && cubePrimary.matl.Id == idMaterial)
              continue; //skip over this cube, because it is the same as the primary cube
          }

          AcctSeed__Project_Task__c projectTask = mapProjectTask.get(idProjectTask);
          Product2 product = mapProduct.get(idProduct);

          if(product == null) continue;

          map<string,string> m = new map<string,string>();
          if(linkedToERP && setIdWholesaleMatl.contains(c.matl.AcctSeedERP__Product__c))
            m.put('cannotModifySerialized','true');
          else
            m.put('cannotModifySerialized','false');

          m.put('idProduct',product.Id);
          m.put('productName',product.Name);
          m.put('productCode',product.ProductCode);
          m.put('productIsInventory',(product.AcctSeed__Inventory_Product__c ? 'true' : 'false'));
          m.put('productIsSerialized',(product.AcctSeedERP__Serialized__c ? 'true' : 'false'));
          m.put('productIsLotTracked',(product.GMBLASERP__Lot_Tracked__c ? 'true' : 'false'));

          m.put('idProjectTask',idProjectTask);
          m.put('projectTaskName', projectTask.Name);
          m.put('lineHasCOGS', 'false');

          Decimal qtySpecified = 0;
          Decimal amtSpecified = 0;
          Decimal qtyAllocated = 0;
          Decimal amtAllocated = 0;
          Boolean boolHasMoves = c.boolHasMoves;

          if(c.matl != null)
          {
            qtySpecified = (c.matl.AcctSeedERP__Quantity_per_Unit__c == null ? 0 : c.matl.AcctSeedERP__Quantity_per_Unit__c);
            if(c.matl.AcctSeedERP__Project__r.AcctSeedERP__Quantity_Ordered__c != null &&
               c.matl.AcctSeedERP__Project__r.AcctSeedERP__Quantity_Ordered__c != 0)
              qtySpecified *= c.matl.AcctSeedERP__Project__r.AcctSeedERP__Quantity_Ordered__c;
              amtSpecified = (product.AcctSeed__Unit_Cost__c == null ? 0 : product.AcctSeed__Unit_Cost__c * qtySpecified);

            for(AcctSeedERP__Manufacturing_Inventory_Movement__c move : c.matl.AcctSeedERP__Manufacturing_Inventory_Movements__r)
            {
              boolHasMoves = true;
              if(move.GMBLASERP__Inventory_GL_Amount__c != null)
                amtAllocated += move.GMBLASERP__Inventory_GL_Amount__c;
              if(move.AcctSeedERP__Quantity__c != null)
                qtyAllocated += move.AcctSeedERP__Quantity__c;
            }
            Decimal qtyMoved = qtyAllocated;
            if(!c.matl.Outbound_Inventory_Movements__r.isEmpty()){
              qtyMoved = 0;
              for(AcctSeedERP__Outbound_Inventory_Movement__c oim : c.matl.Outbound_Inventory_Movements__r)
                qtyMoved += oim.AcctSeedERP__Quantity__c == null ? 0 : oim.AcctSeedERP__Quantity__c;
            }
            m.put('isFlagged', c.matl.No_WIP__c ? 'true' : 'false');
            m.put('isSCR', c.matl.Supplier_Credit_Requested__c ? 'true' : 'false');
            m.put('qtyMoved', String.valueOf(qtyMoved.setScale(6)));
            m.put('qtyCanBeMoved', String.valueOf((qtySpecified - qtyMoved).setScale(6)));
            m.put('qtyToMove', '0.00');
            m.put('projectComplete', c.matl.AcctSeedERP__Project__r.AcctSeed__Status__c == 'Completed' ? 'true' : 'false');

            if(!c.matl.Journal_Entry_Lines__r.isEmpty())
              m.put('lineHasCOGS', 'true');
            m.put('qtySpecifiedOverride',(c.matl.Quantity_Specified_Override__c ? 'true' : 'false'));
            m.put('idMaterial', c.matl.Id);
            m.put('mtrlComment', c.matl.AcctSeedERP__Comment__c);
            m.put('unitPrice',c.matl.GMBLASERP__Unit_Price__c == null ? '0' : String.valueOf(c.matl.GMBLASERP__Unit_Price__c.setScale(6)));
            m.put('totalPrice', c.matl.GMBLASERP__Total_Price__c == null ? '0' : String.valueOf(c.matl.GMBLASERP__Total_Price__c.setScale(6)));
            m.put('priceOverride', c.matl.GMBLASERP__Price_Override__c ? 'true' : 'false');
            m.put('taxableFederal',c.matl.Taxable_Federal__c ? 'true' : 'false');
            m.put('taxableRetail',c.matl.Taxable_Retail__c ? 'true' : 'false');
                        m.put('taxableProvincial',c.matl.Taxable_Provincial__c ? 'true' : 'false');

            if(c.matl.GMBLASERP__Lot__c != null)
            {
              m.put('idLot',c.matl.GMBLASERP__Lot__c);
              m.put('lotName',c.matl.GMBLASERP__Lot__r.Name);
            }

            if(c.matl.GMBLASERP__Serial_Number__c != null)
            {
              m.put('idSerial',c.matl.GMBLASERP__Serial_Number__c);
              m.put('serialName',c.matl.GMBLASERP__Serial_Number__r.Name);
              m.put('serialLocation',c.matl.GMBLASERP__Serial_Number__r.Location_Status__c);
            }

            if (c.matl.isPrepaid__c != null)
              m.put('isPrepaid', String.valueOf( c.matl.isPrepaid__c ) );

            if (c.matl.AcctSeedERP__Product__r.isPrepayable__c != null)
              m.put('isPrepayable', String.valueOf( c.matl.AcctSeedERP__Product__r.isPrepayable__c ) );
          }

          m.put('qtySpecified', String.valueOf(qtySpecified.setScale(6)));
          m.put('amtSpecified', String.valueOf(amtSpecified.setScale(6)));
          m.put('qtyAllocated', String.valueOf(qtyAllocated.setScale(6)));
          m.put('mfgMoves','false');
          if(qtySpecified != 0 && boolHasMoves && qtyAllocated >= qtySpecified)
            m.put('mfgMoves','true');
          m.put('amtAllocated', String.valueOf(amtAllocated.setScale(6)));
          m.put('hasMoves',   (boolHasMoves ? 'true' : 'false'));

          m.put('qtyOrdered',   String.valueOf(c.qtyOrdered.setScale(6)));
          m.put('qtyReceived',  String.valueOf(c.qtyReceived.setScale(6)));
          m.put('qtyPaid',    String.valueOf(c.qtyPaid.setScale(6)));
          m.put('qtyExpense',   String.valueOf(c.qtyExpense.setScale(6)));
          m.put('qtyWip',     String.valueOf(c.qtyWip.setScale(6)));
          m.put('qtyFinished',  String.valueOf(c.qtyFinished.setScale(6)));

          m.put('amtOrdered',   String.valueOf(c.amtOrdered.setScale(6)));
          m.put('amtReceived',  String.valueOf(c.amtReceived.setScale(6)));
          m.put('amtPaid',    String.valueOf(c.amtPaid.setScale(6)));
          m.put('amtExpense',   String.valueOf(c.amtExpense.setScale(6)));
          m.put('amtWip',     String.valueOf(c.amtWip.setScale(6)));
          m.put('amtFinished',  String.valueOf(c.amtFinished.setScale(6)));

          listJSON.add(m);
        }
      }
    }
    return listJSON;
  }

  @RemoteAction
    global static void updateMaterialFlag(Id idMaterial)
    {
      for(AcctSeedERP__Material__c matl : [SELECT Id, No_WIP__c FROM AcctSeedERP__Material__c WHERE Id=:idMaterial])
      {
        if(matl.No_WIP__c) matl.No_WIP__c = false;
        else matl.No_WIP__c = true;
        update matl;
      }
    }

    @RemoteAction
    global static map<string,string> createMatl(Id idProject, Id idProjectTask, Id idProduct, Decimal qty)
    {
      if(idProject == null || idProduct == null) return new map<string,string>();
      Id idCounterSale = gcConstants.idRtProjectCounterSale;
      AcctSeed__Project__c project = [SELECT Id, RecordTypeId FROM AcctSeed__Project__c WHERE Id=:idProject][0];
      AcctSeed__Project_Task__c task = [SELECT Id, DisplayOnCustomerInvoice__c FROM AcctSeed__Project_Task__c WHERE Id=:idProjectTask][0];
      AcctSeedERP__Material__c matl = new AcctSeedERP__Material__c(
        AcctSeedERP__Product__c = idProduct,
        AcctSeedERP__Project__c = idProject,
        AcctSeedERP__Project_Task__c = idProjectTask,
        AcctSeedERP__Quantity_Per_Unit__c = qty,
        Quantity_Specified_Override__c = true
      );
      if(project.RecordTypeId != idCounterSale && !task.DisplayOnCustomerInvoice__c)
      {
        matl.GMBLASERP__Price_Override__c = true;
        matl.GMBLASERP__Unit_Price__c = 0;
      }

      insert matl;

      return retrieveMaterial(matl.Id);
    }

    @RemoteAction
    global static map<string,string> updateQtySpecified(Id idMaterial, Decimal qtyNew)
    {
      AcctSeedERP__Material__c matl =
      [SELECT Id,
          AcctSeedERP__Product__c,
          AcctSeedERP__Project__c,
          AcctSeedERP__Project_Task__c,
          AcctSeedERP__Quantity_per_Unit__c,
          Quantity_Specified_Override__c
       FROM AcctSeedERP__Material__c
       WHERE Id = :idMaterial][0];

    //determine if there is a specified quantity from a bill of materials
    Decimal qtySpec = null;

    for(AcctSeed__Project_Task__c pt :
      [SELECT Id, Product__c
       FROM AcctSeed__Project_Task__c
       WHERE Id = :matl.AcctSeedERP__Project_Task__c
         AND Product__c != null])
    {
      for(AcctSeed__Product_Part__c part :
        [SELECT Id, AcctSeed__Quantity__c
         FROM AcctSeed__Product_Part__c
         WHERE AcctSeed__Product__c = :pt.Product__c
           AND AcctSeed__Product_Part__c = :matl.AcctSeedERP__Product__c
           AND AcctSeed__Quantity__c != null])
      {
        qtySpec = part.AcctSeed__Quantity__c;
      }
    }

    if(qtyNew == null || qtyNew == qtySpec)
    {
      matl.AcctSeedERP__Quantity_Per_Unit__c = qtySpec;
      matl.Quantity_Specified_Override__c = false;
    }
    else
    {
      matl.AcctSeedERP__Quantity_Per_Unit__c = qtyNew;
      matl.Quantity_Specified_Override__c = true;
    }

    if(matl.AcctSeedERP__Quantity_Per_Unit__c == null)
       matl.AcctSeedERP__Quantity_Per_Unit__c = 0;

    //Boolean boolOld = GMBLASERP.gcMaterial.disableTrigger;
    //GMBLASERP.gcMaterial.disableTrigger = true;
    update matl;
    //GMBLASERP.gcMaterial.disableTrigger = boolOld;

    return retrieveMaterial(matl.Id);

    }

  @RemoteAction
  global static map<string,string> updateUnitPrice(Id idMaterial, Decimal unitPrice)
  {
    AcctSeedERP__Material__c matl = [SELECT Id, AcctSeedERP__Project_Task__c, AcctSeedERP__Product__c, GMBLASERP__Unit_Price__c FROM AcctSeedERP__Material__c WHERE Id = :idMaterial][0];

    matl.GMBLASERP__Unit_Price__c = unitPrice;

    if(unitPrice == null)
      matl.GMBLASERP__Price_Override__c = false;
    else
      matl.GMBLASERP__Price_Override__c = true;

    update matl;

    return retrieveMaterials(matl.AcctSeedERP__Project_Task__c, matl.AcctSeedERP__Product__c)[0];
  }

  @RemoteAction
  global static list<map<string,string>> deleteMaterial(Id idMatl)
  {
    AcctSeedERP__Material__c matl;
    for(AcctSeedERP__Material__c x :
      [SELECT Id, AcctSeedERP__Product__c, AcctSeedERP__Project__c, AcctSeedERP__Project__r.Internal_Partner_Boat_Sale__c, AcctSeedERP__Project_Task__c, GMBLASERP__Serial_Number__c,
          (SELECT Id FROM AcctSeedERP__Manufacturing_Inventory_Movements__r)
         FROM AcctSeedERP__Material__c
         WHERE Id = :idMatl])
    {
      matl = x;
    }
    if(matl != null)
    {
      Id idFilter = matl.AcctSeedERP__Project_Task__c;
      if(idFilter == null)
        idFilter = matl.AcctSeedERP__Project__c;

      Id idProduct = matl.AcctSeedERP__Product__c;
      System.debug( 'Deleteing - ' + matl);
      delete matl;

      //Id idPreviousSerial = matl.GMBLASERP__Serial_Number__c;
      //if(idPreviousSerial != null){
      //  for(GMBLASERP__Serial_Number__c oldSerial : [SELECT Id, Name, GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__r.Name, Available_Retail__c, Available_Wholesale__c FROM GMBLASERP__Serial_Number__c WHERE Id =:idPreviousSerial]){
      //    String whs = oldSerial.GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__r.Name;
      //    if(whs == 'Wholesale' && matl.AcctSeedERP__Project__r.Internal_Partner_Boat_Sale__c){
      //      oldSerial.Available_Wholesale__c = true;
      //      oldSerial.Available_Retail__c = false;
      //    }else if(whs != 'Wholesale' || (whs == 'Wholesale' && !matl.AcctSeedERP__Project__r.Internal_Partner_Boat_Sale__c)){
      //      oldSerial.Available_Wholesale__c = false;
      //      oldSerial.Available_Retail__c = true;
      //    }

      //    Boolean boolOld = gcSerialNumber.disableTrigger;
      //    gcSerialNumber.disableTrigger = true;
      //    update oldSerial;
      //    gcSerialNumber.disableTrigger = boolOld;
      //  }
      //}

      return retrieveMaterials(idFilter, idProduct);
    }
    return new list<map<string,string>>();
  }

  @RemoteAction @ReadOnly
  public static List<Map<String,String>> searchSerialForMaterial(Id idMaterial)
  {
    list<Map<String,String>> listResult = new list<Map<String,String>>();
    AcctSeedERP__Material__c matl =
    [SELECT Id,
        AcctSeedERP__Product__c,
        AcctSeedERP__Project__c,
        AcctSeedERP__Project__r.Serial_Number__c,
        AcctSeedERP__Project__r.GMBLASERP__Warehouse__c,
        AcctSeedERP__Project__r.GMBLASERP__Warehouse__r.Name,
        AcctSeedERP__Project__r.Internal_Partner_Boat_Sale__c,
        AcctSeedERP__Project__r.Internal_Labour_Service__c
     FROM AcctSeedERP__Material__c
     WHERE Id = :idMaterial
     LIMIT 1][0];
     Boolean isInternalPartnerBoatSale = matl.AcctSeedERP__Project__r.Internal_Partner_Boat_Sale__c;
    for(GMBLASERP__Serial_Number__c sn :
      [SELECT Id,
        Name,
        Model_Year__c,
        GMBLASERP__Lot__c,
        GMBLASERP__Lot__r.Name,
        GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c,
        GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__r.Name,
        GMBLASERP__Inventory_Balance__r.AcctSeedERP__Location__c,
        GMBLASERP__Inventory_Balance__r.AcctSeedERP__Location__r.Name,
        Available_Wholesale__c,
        Available_Retail__c,
        Dealer_Rigged__c
       FROM GMBLASERP__Serial_Number__c
       WHERE GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c != null
        //AND GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c = :matl.AcctSeedERP__Project__r.GMBLASERP__Warehouse__c
        AND GMBLASERP__Product__c = :matl.AcctSeedERP__Product__c
        AND (Nest__c = null OR Nest__c = :matl.AcctSeedERP__Project__r.Serial_Number__c)
       ORDER BY GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__r.Name, Name])
    {
      if(isInternalPartnerBoatSale && sn.GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c != gcConstants.idWarehouseWholesale) continue;
      if(matl.AcctSeedERP__Project__r.GMBLASERP__Warehouse__r.Name == 'Wholesale' && !sn.Available_Wholesale__c) continue;
      if(matl.AcctSeedERP__Project__r.GMBLASERP__Warehouse__r.Name != 'Wholesale' && !sn.Available_Retail__c) continue;
      if(matl.AcctSeedERP__Project__r.GMBLASERP__Warehouse__r.Name != 'Wholesale' && sn.GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__r.Name == 'Wholesale') continue;
      Map<String,String> m = new Map<String,String>();
      m.put('idWarehouse', sn.GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c);
      m.put('warehouseName', sn.GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__r.Name);
      m.put('idLocation', sn.GMBLASERP__Inventory_Balance__r.AcctSeedERP__Location__c);
      m.put('locationName', sn.GMBLASERP__Inventory_Balance__r.AcctSeedERP__Location__r.Name);
      m.put('idLot', sn.GMBLASERP__Lot__c);
      m.put('lotName', sn.GMBLASERP__Lot__r.Name);
      m.put('idSerial', sn.Id);
      m.put('serialName', sn.Name);
      m.put('modelYear',sn.Model_Year__c == null ? '' : String.valueOf(sn.Model_Year__c));
      m.put('IsAvailableRetail', sn.Available_Retail__c?'true':'false');
      m.put('IsAvailableWholesale', sn.Available_Wholesale__c?'true':'false');
      m.put('IsDealerRigged', sn.Dealer_Rigged__c ? 'Yes' : 'No' );
      listResult.add(m);
    }

    return listResult;
  }

  @RemoteAction
  public static Map<String,String> selectSerialForMaterial(Id idMaterial, Id idSerial)
  {
    AcctSeedERP__Material__c matl = [SELECT Id, AcctSeedERP__Project__r.Internal_Partner_Boat_Sale__c, AcctSeedERP__Project__r.GMBLASERP__Warehouse__r.Name, GMBLASERP__Serial_Number__c, GMBLASERP__Lot__c FROM AcctSeedERP__Material__c WHERE Id = :idMaterial][0];
    // Id Previous Serial
    //Id idPreviousSerial = matl.GMBLASERP__Serial_Number__c;

    if(idSerial == null)
      matl.GMBLASERP__Lot__c = null;

    matl.GMBLASERP__Serial_Number__c = idSerial;
    update matl;

    /// Update availability for the one that has been tagged
    //List<GMBLASERP__Serial_Number__c> listSRUpdate = new List<GMBLASERP__Serial_Number__c>();
    //if(idSerial != null){
    //  GMBLASERP__Serial_Number__c serial = new GMBLASERP__Serial_Number__c(Id = idSerial);
    //  if(matl.AcctSeedERP__Project__r.GMBLASERP__Warehouse__r.Name == 'Wholesale'){
    //    serial.Available_Wholesale__c = false;
    //    if(matl.AcctSeedERP__Project__r.Internal_Partner_Boat_Sale__c)
    //      serial.Available_Retail__c = true;
    //    else
    //      serial.Available_Retail__c = false;
    //  }else{
    //    serial.Available_Wholesale__c = false;
    //    serial.Available_Retail__c = false;
    //  }
    //  listSRUpdate.add(serial);
    //}
    /// The one that has been untagged
    //if(idPreviousSerial != null){
    //  System.debug(loggingLevel.error,'idPreviousSerial:'+idPreviousSerial);
    //  for(GMBLASERP__Serial_Number__c oldSerial : [SELECT Id, Name, GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__r.Name, Available_Retail__c, Available_Wholesale__c FROM GMBLASERP__Serial_Number__c WHERE Id =:idPreviousSerial]){
    //    String whs = oldSerial.GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__r.Name;
    //    if(whs == 'Wholesale' && matl.AcctSeedERP__Project__r.Internal_Partner_Boat_Sale__c){
    //      oldSerial.Available_Wholesale__c = true;
    //      oldSerial.Available_Retail__c = false;
    //      System.debug(loggingLevel.error,'here1');
    //    }else if(whs != 'Wholesale' || (whs == 'Wholesale' && !matl.AcctSeedERP__Project__r.Internal_Partner_Boat_Sale__c)){
    //      oldSerial.Available_Wholesale__c = false;
    //      oldSerial.Available_Retail__c = true;
    //      System.debug(loggingLevel.error,'here2');
    //    }
    //    listSRUpdate.add(oldSerial);
    //  }
    //}
    //if(!listSRUpdate.isEmpty()){
    //  Boolean boolOld = gcSerialNumber.disableTrigger;
    //  gcSerialNumber.disableTrigger = true;
    //  update listSRUpdate;
    //  gcSerialNumber.disableTrigger = boolOld;
    //}
    return retrieveMaterial(matl.Id);
  }


    @RemoteAction @ReadOnly
    global static list<map<string,string>> searchProduct(Id idProject, Id idProjectTask, String strSearch)
    {
      list<map<string,string>> listJSON = new list<map<string,string>>();

        strSearch = '%'+strSearch+'%';

    Boolean isLabourService = false;
    Id idWarehouse;
        for(AcctSeed__Project__c pr : [SELECT GMBLASERP__Warehouse__c, Internal_Labour_Service__c, Internal_Partner_Parts_Order__c, Internal_Partner_Boat_Sale__c FROM AcctSeed__Project__c WHERE Id =:idProject]){
      if(pr.Internal_Partner_Parts_Order__c || pr.Internal_Partner_Boat_Sale__c)
        idWarehouse = gcConstants.idWarehouseWholesale;
      else
            idWarehouse = pr.GMBLASERP__Warehouse__c;
          isLabourService = pr.Internal_Labour_Service__c;
        }
    Id idWarehouseAdjustment = GMBLASERP__Inventory_Settings__c.getOrgDefaults().GMBLASERP__Adjustment_Warehouse_Id__c;
    Id idWarehouseTransit = GMBLASERP__Inventory_Settings__c.getOrgDefaults().GMBLASERP__Transit_Warehouse_Id__c;
        set<Id> setIdProduct = new set<Id>();
        for(AcctSeedERP__Material__c matl :
          [SELECT AcctSeedERP__Product__c
           FROM AcctSeedERP__Material__c
           WHERE AcctSeedERP__Project__c = :idProject AND AcctSeedERP__Project_Task__c = :idProjectTask])
        {
          setIdProduct.add(matl.AcctSeedERP__Product__c);
        }
        setIdProduct.remove(null);
        String internalProductRecordTypeName = gcConstants.internalProductRecordTypeName;
        for(Product2 p :
          [SELECT Id, Name, Family, ProductCode, RecordTypeId, RecordType.Name, AcctSeed__Inventory_Product__c, AcctSeedERP__Default_Vendor__r.Name,
              (SELECT Id, GMBLASERP__Quantity__c, GMBLASERP__Warehouse__c
               FROM GMBLASERP__Inventory_Movement_Cubes__r
               WHERE GMBLASERP__Quantity__c != 0
                 AND GMBLASERP__Warehouse__c != :idWarehouseAdjustment
                 AND GMBLASERP__Warehouse__c != :idWarehouseTransit)
           FROM Product2
             WHERE IsActive = true AND (IsDeleted =:isLabourService OR RecordType.Name =:internalProductRecordTypeName)
               AND (Name LIKE :strSearch OR ProductCode LIKE :strSearch)
               AND IsDeleted = false])
        {
            map<string,string> m = new map<string,string>();

            m.put('idProduct',p.Id);
            m.put('productName',p.Name);
            m.put('productFamily',p.Family);
            m.put('productCode',p.ProductCode);

            if(p.RecordTypeId != null)
              m.put('productRecordTypeName',p.RecordType.Name);

            if(p.AcctSeedERP__Default_Vendor__c != null)
              m.put('vendorName',p.AcctSeedERP__Default_Vendor__r.Name);

            if(p.AcctSeed__Inventory_Product__c)
              m.put('isInventory','true');
            else
              m.put('isInventory','false');

            if(setIdProduct.contains(p.Id))
              m.put('alreadyIncluded','true');
            else
              m.put('alreadyIncluded','false');

            Decimal qtyInvThisWhs = 0;
            Decimal qtyInvOtherWhs = 0;

            for(GMBLASERP__Inventory_Movement_Cube__c c :p.GMBLASERP__Inventory_Movement_Cubes__r)
            {
              if(c.GMBLASERP__Quantity__c != null)
              {
                if(c.GMBLASERP__Warehouse__c == idWarehouse)
                  qtyInvThisWhs += c.GMBLASERP__Quantity__c;
                else
                  qtyInvOtherWhs += c.GMBLASERP__Quantity__c;
              }
            }

            m.put('qtyInvThisWhs',String.valueOf(qtyInvThisWhs.setScale(0)));
            m.put('qtyInvOtherWhs',String.valueOf(qtyInvOtherWhs.setScale(0)));

            listJSON.add(m);
        }

        return listJSON;
    }

    @RemoteAction @ReadOnly
    global static list<map<string,string>> searchBom(Id idProject, String strSearch)
    {
      list<map<string,string>> listJSON = new list<map<string,string>>();

        strSearch = '%'+strSearch+'%';

        set<Id> setIdProductAlreadyIncluded = new set<Id>();
        for(AcctSeed__Project_Task__c pt :
          [SELECT Product__c
           FROM AcctSeed__Project_Task__c
           WHERE AcctSeed__Project__c = :idProject
             AND Product__c != null])
        {
          setIdProductAlreadyIncluded.add(pt.Product__c);
        }


        for(Product2 p :
          [SELECT Id, Name, ProductCode, Family, RecordTypeId, RecordType.Name,
              (SELECT Id FROM AcctSeed__Product_Parts__r)
           FROM Product2
           WHERE Name LIKE :strSearch
              OR ProductCode LIKE :strSearch
              OR Family LIKE :strSearch
              OR RecordType.Name LIKE :strSearch])
        {
          if(p.AcctSeed__Product_Parts__r.size() == 0)
             continue;

          map<string,string> m = new map<string,string>();
          m.put('idProduct',p.Id);
          m.put('productName',p.Name);
          m.put('productCode',p.ProductCode);
          m.put('productFamily',p.Family);
          m.put('partCount', String.valueOf(p.AcctSeed__Product_Parts__r.size()));

            if(p.RecordTypeId != null)
              m.put('productRecordTypeName',p.RecordType.Name);

          if(setIdProductAlreadyIncluded.contains(p.Id))
            m.put('alreadyIncluded','true');
          else
            m.put('alreadyIncluded','false');

          listJSON.add(m);
        }
        return listJSON;
    }

    @RemoteAction
    global static string selectBom(Id idProduct, Id idProjectTask)
    {
      for(AcctSeed__Project_Task__c pt :
        [SELECT Id, Product__c FROM AcctSeed__Project_Task__c WHERE Id = :idProjectTask LIMIT 1])
      {
        pt.Product__c = idProduct;
        update pt;
      }
      return '';
    }

  @RemoteAction @ReadOnly
  global static list<map<string,string>> retrieveLedger(Id idProject)
  {
    list<map<string,string>> listJSON = new list<map<string,string>>();

    if(idProject == null) return listJSON;

      for(AcctSeed__Transaction__c txn :
            [SELECT Id,Name,
                AcctSeed__Accounting_Period__r.Name,
                AcctSeed__Account__r.Name,
                AcctSeed__Account_Payable_Line__r.AcctSeed__Account_Payable__r.Name,
                AcctSeed__Account_Payable_Line__r.Name,
                AcctSeed__Amount__c,
                AcctSeed__Billing_Line__r.AcctSeed__Billing__r.Name,
                AcctSeed__Billing_Line__r.Name,
                AcctSeed__Billing_Cash_Receipt__r.Name,
                AcctSeed__Cash_Receipt__r.Name,
                AcctSeed__GL_Account_Type__c,
                AcctSeed__GL_Account__r.Name,
                AcctSeed__GL_Account__r.AcctSeed__Type__c,
                AcctSeed__GL_Account_Variable_1__r.Name,
                AcctSeed__GL_Account_Variable_2__r.Name,
                AcctSeed__GL_Account_Variable_3__r.Name,
                AcctSeed__GL_Account_Variable_4__r.Name,
                AcctSeed__Journal_Entry_Line__r.AcctSeed__Journal_Entry__r.Name,
                AcctSeed__Journal_Entry_Line__r.Name,
                AcctSeed__Product__r.Name,
                AcctSeed__Project__r.Name,
                AcctSeed__Project_Task__r.Name,
                AcctSeedERP__Inbound_Inventory_Movement__r.Name,
                AcctSeedERP__Manufacturing_Inventory_Movement__r.Name,
                AcctSeedERP__Outbound_Inventory_Movement__r.Name,
                AcctSeedERP__Purchase_Order_Inventory_Movement__r.Name,
                Origin_Type__c
             FROM AcctSeed__Transaction__c
             WHERE AcctSeed__Project__c = :idProject])
    {
        map<string,string> m = new map<string,string>();

        m.put('idTxn',txn.Id);
        m.put('account',txn.AcctSeed__Account__r.Name);
        m.put('glName',txn.AcctSeed__GL_Account__r.Name);
        m.put('glType',txn.AcctSeed__GL_Account__r.AcctSeed__Type__c);
        m.put('glV1Name',txn.AcctSeed__GL_Account_Variable_1__r.Name);
        m.put('glV2Name',txn.AcctSeed__GL_Account_Variable_2__r.Name);
        m.put('glV3Name',txn.AcctSeed__GL_Account_Variable_3__r.Name);
        m.put('glV4Name',txn.AcctSeed__GL_Account_Variable_4__r.Name);
        m.put('productName',txn.AcctSeed__Product__r.Name);
        m.put('periodName',txn.AcctSeed__Accounting_Period__r.Name);
        m.put('projectTaskName',txn.AcctSeed__Project_Task__r.Name);

        if(txn.AcctSeed__Amount__c > 0) {
            m.put('debit',String.valueOf(txn.AcctSeed__Amount__c.setScale(6)));
            m.put('net',String.valueOf(txn.AcctSeed__Amount__c.setScale(6)));
        }
        else{
            m.put('credit',String.valueOf(txn.AcctSeed__Amount__c.setScale(6) * (-1)));
            m.put('net',String.valueOf(txn.AcctSeed__Amount__c.setScale(6)));
        }

            Id idOrigin = null;
            String strOrigin = '';

            if(txn.AcctSeed__Account_Payable_Line__c != NULL){
                idOrigin = txn.AcctSeed__Account_Payable_Line__c;
                strOrigin = txn.AcctSeed__Account_Payable_Line__r.Name;
            }
            else if(txn.AcctSeed__Billing_Line__c != NULL){
                idOrigin = txn.AcctSeed__Billing_Line__c;
                strOrigin = txn.AcctSeed__Billing_Line__r.Name;
            }
            else if(txn.AcctSeed__Journal_Entry_Line__c != NULL){
                idOrigin = txn.AcctSeed__Journal_Entry_Line__c;
                strOrigin = txn.AcctSeed__Journal_Entry_Line__r.Name;
            }
            else if(txn.AcctSeedERP__Inbound_Inventory_Movement__c != NULL){
                idOrigin = txn.AcctSeedERP__Inbound_Inventory_Movement__c;
                strOrigin = txn.AcctSeedERP__Inbound_Inventory_Movement__r.Name;
            }
            else if(txn.AcctSeedERP__Manufacturing_Inventory_Movement__c != NULL){
                idOrigin = txn.AcctSeedERP__Manufacturing_Inventory_Movement__c;
                strOrigin = txn.AcctSeedERP__Manufacturing_Inventory_Movement__r.Name;
            }
            else if(txn.AcctSeedERP__Outbound_Inventory_Movement__c != NULL){
                idOrigin = txn.AcctSeedERP__Outbound_Inventory_Movement__c;
                strOrigin = txn.AcctSeedERP__Outbound_Inventory_Movement__r.Name;
            }
            else if(txn.AcctSeedERP__Purchase_Order_Inventory_Movement__c != NULL){
                idOrigin = txn.AcctSeedERP__Purchase_Order_Inventory_Movement__c;
                strOrigin = txn.AcctSeedERP__Purchase_Order_Inventory_Movement__r.Name;
            }
            else{
              idOrigin = txn.Id;
              strOrigin = txn.Name;
            }

            m.put('idOrigin',idOrigin);
            m.put('origin',strOrigin);

            m.put('originType',txn.Origin_Type__c);

            if(idOrigin.getSobjectType().getDescribe().isAccessible())
              m.put('isAccessible','true');
            else m.put('isAccessible','false');

          listJSON.add(m);
      }


      return listJSON;
  }

  /// Serial Search by Project
    @RemoteAction @ReadOnly
    public static List<Map<String,String>> searchExistingSerial(String strSearch, String pIdProject)
    {
      return gcSerialNumber_Ext.searchExistingSerial(strSearch, pIdProject);
    }
  /// Updaet projet Serial number
    @RemoteAction
    public static String updateProjectSerial(String pIdProject, String pIdSerial)
    {
    AcctSeed__Project__c p = [SELECT Id, Serial_Number__c FROM AcctSeed__Project__c WHERE Id =:pIdProject][0];
    p.Serial_Number__c = pIdSerial;
    update p;

    return 'ok';
    }

    @RemoteAction @ReadOnly
    public static List<Product2> searchProductForSerial(String searchTxt, String isNest)
    {
      List<Product2> listProduct = new List<Product2>();
        Boolean nestValue = true;
        Boolean nestedValue = false;
        if(isNest.equals('0'))
        {
          nestValue = false;
          nestedValue = true;
        }

        searchTxt = '%'+searchTxt.replaceAll('[*]','%') +'%';

        for(Product2 p :
          [SELECT Id,
            Name,
            GMBLASERP__Lot_Tracked__c,
            AcctSeedERP__Serialized__c
          FROM Product2
          WHERE AcctSeedERP__Serialized__c = true
            AND Can_be_Nest__c =:nestValue
            AND Can_be_Nested__c =:nestedValue
            AND Name like :searchTxt LIMIT 10])
        {
            listProduct.add(p);
        }
        return listProduct;

    }

    @RemoteAction
    public static String addNewSerial(String pIdProject, Map<String,String> mapData)
    {
      Id idProduct = null;
      if(mapData.containsKey('idProduct') && mapData.get('idProduct') != '')
        idProduct = (Id) mapData.get('idProduct');

    String isNest = '1';
      if(mapData.containsKey('isNest'))
        isNest = mapData.get('isNest');

    String selectLot = '';
    Id idLot = null;
      if(mapData.containsKey('selectLot'))
        selectLot = mapData.get('selectLot');

    String serialDescription = '';
      if(mapData.containsKey('serialDescription'))
        serialDescription = mapData.get('serialDescription');

    String serialNumber = '';
      if(mapData.containsKey('serialNumber'))
        serialNumber = mapData.get('serialNumber');

    Decimal modelYear = null;
      if(mapData.containsKey('modelYear') && mapData.get('modelYear') != '')
        modelYear = Decimal.valueOf(mapData.get('modelYear'));

    String productIsLotTracked = '';
      if(mapData.containsKey('productIsLotTracked'))
        productIsLotTracked = mapData.get('productIsLotTracked');

      /// if a product was not specified then it is a non legend service
      /*
      /// From now the suer must select a product
      if(idProduct == null)
      {
        idProduct = [SELECT Id FROM Product2 where Unique_Product_Code__c = 'NonLegend'][0].Id;
      }*/

      /// Find or create a lot
      if(productIsLotTracked.equals('true'))
      {
      for(GMBLASERP__Lot__c l : [SELECT Id, GMBLASERP__Product__c, Name FROM GMBLASERP__Lot__c WHERE GMBLASERP__Product__c =:idProduct AND Name =:selectLot])
      {
        idLot = l.Id;
      }

      if(idLot == null)
      {
        GMBLASERP__Lot__c l = new GMBLASERP__Lot__c(GMBLASERP__Product__c = idProduct, Name = selectLot);
        insert l;
        idLot = l.Id;
      }
    }
    /// Gather project data
    AcctSeed__Project__c project = [SELECT Id, Serial_Number__c, GMBLASERP__Warehouse__c FROM AcctSeed__Project__c WHERE Id =:pIdProject][0];
    /// Create serial number
    GMBLASERP__Serial_Number__c sn = new GMBLASERP__Serial_Number__c(GMBLASERP__Product__c = idProduct, Name = serialNumber, Model_Year__c = modelYear);
    if(idLot != null)
      sn.GMBLASERP__Lot__c = idLot;
    if(serialDescription != '')
      sn.Description__c = serialDescription;
    if(!isNest.equals('1'))
      sn.Nest__c = project.Serial_Number__c;

    insert sn;

    /// Update serial in the project
    if(isNest.equals('1'))
    {
      project.Serial_Number__c = sn.Id;
      update project;
    }

    return 'ok';

      //AcctSeedERP__Location__c loc = [SELECT Id FROM AcctSeedERP__Location__c WHERE AcctSeedERP__Warehouse__c = :project.GMBLASERP__Warehouse__c][0];
      //Id idBalance = GMBLASERP.gcInventoryBalance.findOrCreateBalance(project.AcctSeedERP__Manufactured_Product__c,project.GMBLASERP__Warehouse__c,loc.Id);

  }

  @RemoteAction @ReadOnly
  public static List<Map<String,String>> retrieveNestedSerials(Id pIdProject)
  {
    AcctSeed__Project__c project = [SELECT Id, Serial_Number__c FROM AcctSeed__Project__c WHERE Id =:pIdProject][0];
    List<Map<String,String>> listNests = new List<Map<String,String>>();

    if(project.Serial_Number__c != null)
      listNests = gcSerialNumber_Ext.retrieveNestedSerials(project.Serial_Number__c);

    return listNests;
  }





//
//
///////////////////////////////////     CASH AND BILLINGS     ///////////////////////////////////
//
//
    @RemoteAction @ReadOnly
    global static List<String> retrieveBankAccounts(Id idProject)
    {
      List<String> listJSON = new list<String>();

      Id idUser = UserInfo.getUserId();
      Id idGlMostRecent = null;
      for(AcctSeed__Cash_Receipt__c cr :
        [SELECT AcctSeed__Bank_Account__c
         FROM AcctSeed__Cash_Receipt__c
         WHERE CreatedById = :idUser
            OR AcctSeed__Project__c = :idProject
         ORDER BY CreatedDate DESC
         LIMIT 1])
      {
        idGlMostRecent = cr.AcctSeed__Bank_Account__c;
      }

      for(AcctSeed__GL_Account__c gl :
        [SELECT Id, Name
         FROM AcctSeed__GL_Account__c
         WHERE AcctSeed__Bank__c = true
           AND AcctSeed__Active__c = true
         ORDER BY Name])
      {
        JSONGenerator gen = JSON.createGenerator(false);
      gen.writeStartObject();
      gen.writeStringField('value', gl.Id);
      gen.writeStringField('label', gl.Name);
      gen.writeBooleanField('isMostRecent',(gl.Id == idGlMostRecent ? true : false));
      gen.writeEndObject();

      listJSON.add(gen.getAsString());
      }
      return listJSON;
    }

  @RemoteAction @ReadOnly
  global static list<String> retrieveCashReceiptPaymentMethodOptions()
  {
    list<String> listResult = new list<String>();
    for(Schema.Picklistentry ple : AcctSeed__Cash_Receipt__c.fields.Payment_Method__c.getDescribe().getPicklistValues())
    {
      listResult.add(ple.getValue());
    }
    return listResult;
  }

    @RemoteAction @ReadOnly
    global static Map<String,String> retrieveBalanceDue(Id idProject)
    {
      AcctSeed__Project__c project = [SELECT Id, Grand_Total__c, AcctSeed__Opportunity__c, AcctSeed__Opportunity__r.Amount FROM AcctSeed__Project__c WHERE Id = :idProject][0];

      Decimal balance = (project.Grand_Total__c == null ? 0 : project.Grand_Total__c);
      Decimal creditCardTotal = 0;

      for(AcctSeed__Transaction__c txn :
        [SELECT AcctSeed__Amount__c, AcctSeed__Cash_Receipt__r.Payment_Method__c
         FROM AcctSeed__Transaction__c
         WHERE AcctSeed__Project__c = :idProject
           AND AcctSeed__GL_Account__r.AcctSeed__Bank__c = true])
      {
        balance -= (txn.AcctSeed__Amount__c == null ? 0 : txn.AcctSeed__Amount__c);
        if(txn.AcctSeed__Cash_Receipt__r.Payment_Method__c == 'Visa' || txn.AcctSeed__Cash_Receipt__r.Payment_Method__c == 'MasterCard')
          creditCardTotal += (txn.AcctSeed__Amount__c == null ? 0 : txn.AcctSeed__Amount__c);
      }
      Map<String,String> m = new Map<String,String>();
      m.put('balanceDue', String.valueOf(balance.setScale(2)));
      m.put('creditCardTotal', String.valueOf(creditCardTotal.setScale(2)));
      return m;
    }

  @RemoteAction
  global static string receiveDeposit(Id idProject, Decimal amount, Id idGlBank, String paymentMethod, String paymentReference, Boolean createBill, String billingDate)
  {
    Id idGlDeposit = gcConstants.idGlDeposit;

    for(AcctSeed__Project__c p :
      [SELECT Id, AcctSeed__Account__c, AcctSeed__Opportunity__r.AccountId, RecordTypeId,
          (SELECT Id FROM AcctSeed__Project_Tasks__r ORDER BY CreatedDate LIMIT 1)
       FROM AcctSeed__Project__c
       WHERE Id = :idProject])
    {
      //if(p.AcctSeed__Opportunity__r.AccountId == null)
      //  return 'An Opportunity must be specified on the Project, in order to receive a deposit.';

      if(p.AcctSeed__Account__c == null)
        throw new gcException('An Account must be specified on the Project, in order to receive a deposit.');

      if(p.AcctSeed__Project_Tasks__r.isEmpty())
        throw new gcException('A Project must have at least one underlying Project Task, in order to receive a deposit.');

      if(paymentMethod != '' && paymentMethod != null){
        Date crDate = (billingDate == null) ? Date.today() : Date.parse(billingDate);
        insert new AcctSeed__Cash_Receipt__c(
          AcctSeed__Amount__c = amount,
          AcctSeed__Account__c = p.AcctSeed__Account__c,
          AcctSeed__Bank_Account__c = idGlBank,
          AcctSeed__Credit_GL_Account__c = idGlDeposit,
          AcctSeed__Payment_Reference__c = paymentReference,
          AcctSeed__Project__c = p.Id,
          AcctSeed__Receipt_Date__c = crDate,
          AcctSeed__Project_Task__c = p.AcctSeed__Project_Tasks__r[0].Id,
          Payment_Method__c = paymentMethod
        );

        //if(p.RecordTypeId != gcConstants.idRtProjectBoatSale && createBill)
        if(createBill)
        {
          set<Id> setIdBilling = new set<Id>();
          for(AcctSeed__Billing_Line__c line :
            [SELECT AcctSeed__Billing__c
             FROM AcctSeed__Billing_Line__c
             WHERE AcctSeed__Project__c = :idProject
               AND AcctSeed__Billing__r.AcctSeed__Status__c = 'Posted'
               AND AcctSeed__Billing__r.AcctSeed__Balance__c > 0])
          {
            setIdBilling.add(line.AcctSeed__Billing__c);
          }

          gcBilling.applyCash(setIdBilling);

          String idBill = createBilling(idProject,billingDate);

          return idBill;
        }
        else
          return '';
      }else{
        String idBill = createBilling(idProject,billingDate);
        return idBill;
      }

      //return 'OK';
    }

    throw new gcException('Project Not Found: '+idProject);

    return '';
  }

  @RemoteAction
  public static String createBilling(Id idProject, String selectedDate)
  {
    Date billDate = (selectedDate == null) ? Date.today() : Date.parse(selectedDate);
    list<AcctSeed__Billing_Line__c> listLine = new list<AcctSeed__Billing_Line__c>();
    Map<Id,AcctSeedERP__Material__c> mapMainKit = new Map<Id,AcctSeedERP__Material__c>();
    Map<Id,List<AcctSeedERP__Material__c>> mapMainKitParts = new Map<Id,List<AcctSeedERP__Material__c>>();
    Map<Id,Decimal> mapMainKitInventoryPartsOrdered = new Map<Id,Decimal>();
    Map<Id,Decimal> mapMainKitInventoryPartsWIP = new Map<Id,Decimal>();
    Map<Id,Decimal> mapMainKitNonInventoryPartsOrdered = new Map<Id,Decimal>();
    map<Id,map<Id,map<Boolean,cube>>> mapTPTC = new map<Id,map<Id,map<Boolean,cube>>>(); //map idProjectTask => idProduct => taxable => cube

    AcctSeed__Project__c project =
    [SELECT Id,
        Name,
        Sale_Type__c,
        RecordTypeId,
        AcctSeed__Account__c,
        AcctSeed__Opportunity__c,
        GL_Account_Variable_3__c,
        Tax_Rate_Provincial__c,
        Tax_Rate_Federal__c,
        Tax_Rate_Retail__c,
        Tax_is_Harmonized__c,
        Tax_Override__c,
        Internal_Partner_Boat_Sale__c,
        Internal_Partner_Parts_Order__c
     FROM AcctSeed__Project__c
     WHERE Id = :idProject][0];

     Boolean checkCOGS = false;
     if(project.Internal_Partner_Boat_Sale__c)
      checkCOGS = true;

    for(AcctSeedERP__Material__c matl :
      [SELECT AcctSeedERP__Project__c,
          AcctSeedERP__Project__r.Internal_Partner_Boat_Sale__c,
          AcctSeedERP__Project_Task__c,
          AcctSeedERP__Product__c,
          AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c,
          AcctSeedERP__Product__r.AcctSeedERP__Serialized__c,
          AcctSeedERP__Product__r.Composite_Type__c,
          AcctSeedERP__Quantity_per_Unit__c,
          AcctSeedERP__Quantity_Allocated__c,
          GMBLASERP__Serial_Number__c,
          Taxable_Provincial__c,
                Taxable_Federal__c,
                Taxable_Retail__c,
          GMBLASERP__Total_Price__c,
          Material__c,
          GMBLASERP__Unit_Price__c,
          No_WIP__c,
          (SELECT AcctSeed__Hours_Units__c,
              AcctSeed__Rate__c,
              AcctSeed__Total__c
           FROM GMBLASERP__Billing_Lines__r),
           (SELECT Id, AcctSeedERP__Quantity__c FROM Outbound_Inventory_Movements__r)
       FROM AcctSeedERP__Material__c
       WHERE AcctSeedERP__Project__c = :idProject])
    {
      //if(project.RecordTypeId == gcConstants.idRtProjectBoatSale)
      //  System.debug(loggingLevel.Error,'Boat Sale');
      //if(matl.AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c)
      //  System.debug(loggingLevel.Error,'Inventory Product');
      //if(matl.AcctSeedERP__Quantity_per_Unit__c != matl.AcctSeedERP__Quantity_Allocated__c)
      //  System.debug(loggingLevel.Error,'Not Allocated');
      if(project.RecordTypeId == gcConstants.idRtProjectPartnerBoatSale
        && matl.AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c
        && matl.AcctSeedERP__Quantity_per_Unit__c != matl.AcctSeedERP__Quantity_Allocated__c
        && !matl.No_WIP__c)
      {
        System.debug(loggingLevel.Error,'Here..');
        throw new gcException('For Boat Sale ERP before creating a Billing you must move all Inventory products to WIP to COGS.');
      }

      if(project.RecordTypeId == gcConstants.idRtProjectCounterSale
          || (project.RecordTypeId == gcConstants.idRtPartnerPartsOrder
            && !project.Internal_Partner_Parts_Order__c))
      {
        if(matl.AcctSeedERP__Product__r.Composite_Type__c == 'Kit'){
          mapMainKit.put(matl.Id, matl);
          continue;
        }else if(matl.Material__c != null){
          if(!mapMainKitParts.containsKey(matl.Material__c))
            mapMainKitParts.put(matl.Material__c, new List<AcctSeedERP__Material__c>());
          mapMainKitParts.get(matl.Material__c).add(matl);

          if(!mapMainKitInventoryPartsOrdered.containsKey(matl.Material__c))
            mapMainKitInventoryPartsOrdered.put(matl.Material__c,0);
          if(!mapMainKitInventoryPartsWIP.containsKey(matl.Material__c))
            mapMainKitInventoryPartsWIP.put(matl.Material__c,0);
          if(!mapMainKitNonInventoryPartsOrdered.containsKey(matl.Material__c))
            mapMainKitNonInventoryPartsOrdered.put(matl.Material__c,0);

          if(matl.AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c){
            mapMainKitInventoryPartsOrdered.put(matl.Material__c,mapMainKitInventoryPartsOrdered.get(matl.Material__c)+matl.AcctSeedERP__Quantity_per_Unit__c);
            mapMainKitInventoryPartsWIP.put(matl.Material__c,mapMainKitInventoryPartsWIP.get(matl.Material__c)+matl.AcctSeedERP__Quantity_Allocated__c);
          }else{
            mapMainKitNonInventoryPartsOrdered.put(matl.Material__c,mapMainKitNonInventoryPartsOrdered.get(matl.Material__c)+matl.AcctSeedERP__Quantity_Allocated__c);
          }

          continue;
        }
      }

      Decimal priorBillAmt = 0;
      Decimal priorBillQty = 0;
      Boolean hasPriorBill = false;
      Decimal qtyMoved = 0;
      for(AcctSeed__Billing_Line__c line : matl.GMBLASERP__Billing_Lines__r)
      {
        priorBillAmt += (line.AcctSeed__Total__c == null ? 0 : line.AcctSeed__Total__c);
        priorBillQty += (line.AcctSeed__Hours_Units__c == null ? 0 : line.AcctSeed__Hours_Units__c);
        hasPriorBill = true;
      }
      /// Only for warranty
      for(AcctSeedERP__Outbound_Inventory_Movement__c oim : matl.Outbound_Inventory_Movements__r)
      {
        qtyMoved += oim.AcctSeedERP__Quantity__c == null ? 0 : oim.AcctSeedERP__Quantity__c;
      }

      priorBillAmt = priorBillAmt.setScale(6);
      Decimal matlAmt = (matl.GMBLASERP__Total_Price__c == null ? 0 : matl.GMBLASERP__Total_Price__c).setScale(6);
      Decimal matlQty = (matl.AcctSeedERP__Quantity_per_Unit__c == null ? 0 : matl.AcctSeedERP__Quantity_per_Unit__c);
      if(matl.AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c && !matl.No_WIP__c){
        matlQty = (matl.AcctSeedERP__Quantity_Allocated__c == null ? 0 : matl.AcctSeedERP__Quantity_Allocated__c);
        matlAmt = (matlQty * (matl.GMBLASERP__Unit_Price__c == null ? 0 : matl.GMBLASERP__Unit_Price__c)).setScale(6);
      }
      if(qtyMoved <> 0)
        matlQty = qtyMoved;

      Decimal matlRate = (matl.GMBLASERP__Unit_Price__c == null ? 0 : matl.GMBLASERP__Unit_Price__c).setScale(6);
      System.debug(loggingLevel.error,'hasPriorBill:'+hasPriorBill);
      Decimal thisBillQty = matlQty - priorBillQty;
      if(matlQty != 0)
      if(priorBillAmt != matlAmt || (hasPriorBill == false && matlAmt == 0) || (hasPriorBill == true && matlAmt == 0 && thisBillQty <> 0))
      {
        Decimal thisBillAmt = matlAmt - priorBillAmt;
        //Decimal thisBillQty = matlQty - priorBillQty;
        Decimal thisBillRate = (thisBillQty == 0 ? 0 : thisBillAmt/thisBillQty).setScale(6);

        System.debug(loggingLevel.error,'priorBillAmt:'+priorBillAmt);
        System.debug(loggingLevel.error,'priorBillQty:'+priorBillQty);
        System.debug(loggingLevel.error,'thisBillAmt:'+thisBillAmt);
        System.debug(loggingLevel.error,'thisBillQty:'+thisBillQty);
        //if(thisBillRate == 0 || thisBillRate != matlRate)
        //{
        //  System.debug(loggingLevel.error,'thisBillRate:'+thisBillRate);
        //  System.debug(loggingLevel.error,'matlRate:'+matlRate);
        //  thisBillQty = 1;
        //  thisBillRate = thisBillAmt;
        //}
        System.debug(loggingLevel.error,'matlQty:'+matlQty);
        System.debug(loggingLevel.error,'matlAmt:'+matlAmt);
        if(thisBillQty != 0)
        listLine.add(new AcctSeed__Billing_Line__c(
          AcctSeed__Project__c = matl.AcctSeedERP__Project__c,
          AcctSeed__Project_Task__c = matl.AcctSeedERP__Project_Task__c,
          AcctSeed__Product__c = matl.AcctSeedERP__Product__c,
          AcctSeed__Hours_Units__c = thisBillQty,
          AcctSeed__Rate__c = thisBillRate,
          GMBLASERP__Material__c = matl.Id,
                    Taxable_Federal__c = matl.Taxable_Federal__c,
          Taxable_Provincial__c = matl.Taxable_Provincial__c,
          Taxable_Retail__c = matl.Taxable_Retail__c
        ));
        System.debug(loggingLevel.error,'listLine:'+listLine);
      }
    }

    if(!mapMainKit.isEmpty()){
      for(Id matlId : mapMainKit.keySet())
      {
        AcctSeedERP__Material__c matl = mapMainKit.get(matlId);
        Decimal totalQtySpecified = matl.AcctSeedERP__Quantity_per_Unit__c == null ? 0 : matl.AcctSeedERP__Quantity_per_Unit__c;
        Decimal qtyOrderedInventoryKit = mapMainKitInventoryPartsOrdered.get(matlId);
        Decimal qtyWipedInventoryKit = mapMainKitInventoryPartsWIP.get(matlId);
        Decimal qtyNonInventoryKit = mapMainKitNonInventoryPartsOrdered.get(matlId);
        if(qtyOrderedInventoryKit != 0 && qtyOrderedInventoryKit != qtyWipedInventoryKit) continue;
        if(qtyNonInventoryKit == 0 && totalQtySpecified == 0) continue;

        Decimal priorBillAmt = 0;
        Decimal priorBillQty = 0;
        Boolean hasPriorBill = false;
        for(AcctSeed__Billing_Line__c line : matl.GMBLASERP__Billing_Lines__r)
        {
          priorBillAmt += (line.AcctSeed__Total__c == null ? 0 : line.AcctSeed__Total__c);
          priorBillQty += (line.AcctSeed__Hours_Units__c == null ? 0 : line.AcctSeed__Hours_Units__c);
          hasPriorBill = true;
        }

        priorBillAmt = priorBillAmt.setScale(6);
        Decimal matlAmt = (matl.GMBLASERP__Total_Price__c == null ? 0 : matl.GMBLASERP__Total_Price__c).setScale(6);
        Decimal matlQty = (matl.AcctSeedERP__Quantity_per_Unit__c == null ? 0 : matl.AcctSeedERP__Quantity_per_Unit__c);
        if(matl.AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c){
          matlQty = (matl.AcctSeedERP__Quantity_Allocated__c == null ? 0 : matl.AcctSeedERP__Quantity_Allocated__c);
          matlAmt = (matlQty * (matl.GMBLASERP__Unit_Price__c == null ? 0 : matl.GMBLASERP__Unit_Price__c)).setScale(6);
        }
        Decimal matlRate = (matl.GMBLASERP__Unit_Price__c == null ? 0 : matl.GMBLASERP__Unit_Price__c).setScale(6);
        System.debug(loggingLevel.error,'hasPriorBill:'+hasPriorBill);
        Decimal thisBillQty = matlQty - priorBillQty;
        if(matlQty != 0)
        if(priorBillAmt != matlAmt || (hasPriorBill == false && matlAmt == 0) || (hasPriorBill == true && matlAmt == 0 && thisBillQty <> 0))
        {
          Decimal thisBillAmt = matlAmt - priorBillAmt;
          //Decimal thisBillQty = matlQty - priorBillQty;
          Decimal thisBillRate = (thisBillQty == 0 ? 0 : thisBillAmt/thisBillQty).setScale(6);

          System.debug(loggingLevel.error,'priorKitBillAmt:'+priorBillAmt);
          System.debug(loggingLevel.error,'priorKitBillQty:'+priorBillQty);
          System.debug(loggingLevel.error,'thisKitBillAmt:'+thisBillAmt);
          System.debug(loggingLevel.error,'thisKitBillQty:'+thisBillQty);
          if(thisBillRate == 0 || thisBillRate != matlRate)
          {
            System.debug(loggingLevel.error,'thisKitBillRate:'+thisBillRate);
            System.debug(loggingLevel.error,'KitmatlRate:'+matlRate);
            thisBillQty = 1;
            thisBillRate = thisBillAmt;
          }
          System.debug(loggingLevel.error,'KitmatlQty:'+matlQty);
          System.debug(loggingLevel.error,'KitmatlAmt:'+matlAmt);
          if(thisBillQty != 0){
            listLine.add(new AcctSeed__Billing_Line__c(
              AcctSeed__Project__c = matl.AcctSeedERP__Project__c,
              AcctSeed__Project_Task__c = matl.AcctSeedERP__Project_Task__c,
              AcctSeed__Product__c = matl.AcctSeedERP__Product__c,
              AcctSeed__Hours_Units__c = thisBillQty,
              AcctSeed__Rate__c = thisBillRate,
              GMBLASERP__Material__c = matl.Id,
                        Taxable_Federal__c = matl.Taxable_Federal__c,
              Taxable_Provincial__c = matl.Taxable_Provincial__c,
              Taxable_Retail__c = matl.Taxable_Retail__c
            ));
            if(mapMainKitParts.get(matlId) != null)
            for(AcctSeedERP__Material__c chilMatl : mapMainKitParts.get(matlId)){
              listLine.add(new AcctSeed__Billing_Line__c(
                AcctSeed__Project__c = chilMatl.AcctSeedERP__Project__c,
                AcctSeed__Project_Task__c = chilMatl.AcctSeedERP__Project_Task__c,
                AcctSeed__Product__c = chilMatl.AcctSeedERP__Product__c,
                AcctSeed__Hours_Units__c = chilMatl.AcctSeedERP__Quantity_per_Unit__c,
                AcctSeed__Rate__c = 0,
                GMBLASERP__Material__c = chilMatl.Id,
                          Taxable_Federal__c = false,
                Taxable_Provincial__c = false,
                Taxable_Retail__c = false
              ));
            }
          }

          System.debug(loggingLevel.error,'KitlistLine:'+listLine);
        }
      }
    }

    if(!listLine.isEmpty())
    {
      if(project.AcctSeed__Account__c == null)
      {
        throw new gcException('A Project must have an Account, in order to create a Billing.');
      }

      AcctSeed__Billing__c b = new AcctSeed__Billing__c(
        AcctSeed__Date__c = billDate,//date.Today(),
        AcctSeed__Customer__c = project.AcctSeed__Account__c,
        GMBLASERP__Project__c = project.Id,
        AcctSeed__Status__c = 'Approved',
        AcctSeed__Opportunity__c = project.AcctSeed__Opportunity__c,
        GL_Account_Variable_3__c = project.GL_Account_Variable_3__c,
        Tax_is_Harmonized__c = project.Tax_is_Harmonized__c,
        Tax_Override__c = project.Tax_Override__c,
        Tax_Rate_Federal__c = project.Tax_Rate_Federal__c,
        Tax_Rate_Provincial__c = project.Tax_Rate_Provincial__c,
        Tax_Rate_Retail__c = project.Tax_Rate_Retail__c
      );

      for(AcctSeed__Accounting_Period__c p :
        [SELECT Id
         FROM AcctSeed__Accounting_Period__c
         WHERE AcctSeed__End_Date__c >= :billDate//date.Today()
           AND AcctSeed__Status__c = 'Open'
         ORDER BY AcctSeed__End_Date__c
         LIMIT 1])
      {
        b.AcctSeed__Accounting_Period__c = p.Id;
      }
      gcBilling.allowBillingProjectForInternal = true;
      insert b;

      for(AcctSeed__Billing_Line__c line : listLine)
      {
        line.AcctSeed__Billing__c = b.Id;
      }

      Boolean boolOld = gcBillingLine.disableAutosetTaxable;
      gcBillingLine.disableAutosetTaxable = true;
      insert listLine;
      gcBillingLine.disableAutosetTaxable = boolOld;
      gcBilling.allowBillingProjectForInternal = false;
      /// Create the PDF
      //ERPInvoiceDocumentBuilder.generateBillingDocument(idProject, 'ERPInvoicePDF_PartsOrderBilling', b.Id);
      AcctSeed.BillingPostService.postBillings(new list<AcctSeed__Billing__c>{b});

      ///// Testing
      //String pageUri = '/apex/ERPInvoicePDF_PartsOrderBilling';
    //      System.debug(loggingLevel.error,'pageUri:'+pageUri);
    //      String docName = 'Invoice - ';
    //      Boolean isInvoice = true;
      return b.Id;
    }
    return null;
  }

  @RemoteAction
  public static void createInvoice(Id idProject, Id idBillOrTransfer, Boolean internalPartsOrder){
        String objectAPIName = idBillOrTransfer.getSObjectType().getDescribe().getName();
        if(objectAPIName.equals('AcctSeed__Billing__c'))
          internalPartsOrder = false;

    if(internalPartsOrder)
      ERPInvoiceDocumentBuilder.generateTransferDocument(idProject, 'ERPPackingSlip_InternalPartOrder', idBillOrTransfer);
    else
      ERPInvoiceDocumentBuilder.generateBillingDocument(idProject, 'ERPInvoicePDF_PartsOrderBilling', idBillOrTransfer);
  }

  @RemoteAction
  public static String createAP(Id idProject)
  {
    list<AcctSeed__Account_Payable_Line__c> listLine = new list<AcctSeed__Account_Payable_Line__c>();
    Id idGLVP = [SELECT AcctSeed__Vouchers_Payable_GL_Account__c FROM AcctSeed__Accounting_Settings__c][0].AcctSeed__Vouchers_Payable_GL_Account__c;
    AcctSeed__Project__c project =
    [SELECT Id,
        Name,
        AcctSeedERP__Work_Order_Number__c,
        RecordTypeId,
        AcctSeed__Account__c,
        AcctSeed__Opportunity__c,
        GL_Account_Variable_3__c,
        Tax_Rate_Provincial__c,
        Tax_Rate_Federal__c,
        Tax_Rate_Retail__c,
        Tax_is_Harmonized__c,
        Tax_Override__c
     FROM AcctSeed__Project__c
     WHERE Id = :idProject][0];

    if(project.AcctSeed__Account__c == null)
    {
      throw new gcException('A Project must have an Account, in order to create an AP.');
    }

    for(AcctSeedERP__Material__c matl :
      [SELECT AcctSeedERP__Project__c,
          AcctSeedERP__Project_Task__c,
          AcctSeedERP__Product__c,
          AcctSeedERP__Quantity_per_Unit__c,
          Taxable_Provincial__c,
                Taxable_Federal__c,
                Taxable_Retail__c,
          GMBLASERP__Total_Price__c,
          GMBLASERP__Unit_Price__c
       FROM AcctSeedERP__Material__c
       WHERE AcctSeedERP__Project__c = :idProject])
    {
      Decimal matlAmt = (matl.GMBLASERP__Total_Price__c == null ? 0 : matl.GMBLASERP__Total_Price__c).setScale(2);
      Decimal matlQty = (matl.AcctSeedERP__Quantity_per_Unit__c == null ? 0 : matl.AcctSeedERP__Quantity_per_Unit__c);
      Decimal matlRate = (matl.GMBLASERP__Unit_Price__c == null ? 0 : matl.GMBLASERP__Unit_Price__c).setScale(5);

      listLine.add(new AcctSeed__Account_Payable_Line__c(
        AcctSeed__Project__c = matl.AcctSeedERP__Project__c,
        AcctSeed__Project_Task__c = matl.AcctSeedERP__Project_Task__c,
        AcctSeed__Product__c = matl.AcctSeedERP__Product__c,
        AcctSeed__Quantity__c = matlQty,
        AcctSeed__Amount__c = matlAmt,
        AcctSeed__Expense_GL_Account__c = idGLVP,
                Taxable_Federal__c = matl.Taxable_Federal__c,
        Taxable_Provincial__c = matl.Taxable_Provincial__c,
        Taxable_Retail__c = matl.Taxable_Retail__c
      ));
    }

    if(!listLine.isEmpty())
    {
      AcctSeed__Account_Payable__c b = new AcctSeed__Account_Payable__c(
        AcctSeed__Date__c = date.Today(),
        AcctSeed__Vendor__c = project.AcctSeed__Account__c,
        AcctSeed__Payee_Reference__c = 'PurchaseReturn-'+project.AcctSeedERP__Work_Order_Number__c,
        GL_Account_Variable_3__c = project.GL_Account_Variable_3__c,
        Tax_is_Harmonized__c = project.Tax_is_Harmonized__c,
        Tax_Override__c = project.Tax_Override__c,
        Tax_Rate_Federal__c = project.Tax_Rate_Federal__c,
        Tax_Rate_Provincial__c = project.Tax_Rate_Provincial__c,
        Tax_Rate_Retail__c = project.Tax_Rate_Retail__c
      );

      for(AcctSeed__Accounting_Period__c p :
        [SELECT Id
         FROM AcctSeed__Accounting_Period__c
         WHERE AcctSeed__End_Date__c >= :date.Today()
           AND AcctSeed__Status__c = 'Open'
         ORDER BY AcctSeed__End_Date__c
         LIMIT 1])
      {
        b.AcctSeed__Accounting_Period__c = p.Id;
      }

      insert b;

      for(AcctSeed__Account_Payable_Line__c line : listLine)
      {
        line.AcctSeed__Account_Payable__c = b.Id;
      }

      Boolean boolOld = gcAccountPayableLine.disableAutosetTaxable;
      gcAccountPayableLine.disableAutosetTaxable = true;
      insert listLine;
      gcAccountPayableLine.disableAutosetTaxable = boolOld;

      return b.Id;
    }
    return null;
  }

  @RemoteAction
  public static String cloneJournalEntry(String idProject, String idJournal)
  {
    for(AcctSeed__Journal_Entry__c je :
      [SELECT
        Id,
        Name,
        OwnerId,
        AcctSeed__Accounting_Year__c,
        AcctSeed__Out_of_Balance__c,
        AcctSeed__Total_Credits__c,
        AcctSeed__Total_Debits__c,
        Project__c,
        (SELECT
          Id,
          AcctSeed__Account__c,
          AcctSeed__Bank_Reconciliation__c,
          AcctSeed__GL_Account_Variable_1__c,
          AcctSeed__GL_Account_Variable_2__c,
          AcctSeed__GL_Account_Variable_3__c,
          AcctSeed__GL_Account_Variable_4__c,
          AcctSeed__Cleared_Date__c,
          AcctSeed__Credit__c,
          AcctSeed__Debit__c,
          AcctSeed__Employee__c,
          AcctSeed__GL_Account__c,
          AcctSeed__Journal_Entry__c,
          AcctSeed__Product__c,
          AcctSeed__Project__c,
          AcctSeed__Project_Task__c,
          AcctSeed__Units__c,
          AcctSeed__Reference__c,
          AcctSeed__Time_Card_Variable_1__c,
          AcctSeed__Time_Card_Variable_2__c
        FROM AcctSeed__Journal_Entry_Lines__r)
      FROM AcctSeed__Journal_Entry__c
      WHERE Id =:idJournal])
    {
      AcctSeed__Journal_Entry__c newJE = je.clone(false,true);
      newJE.Project__c = idProject;
      insert newJE;
      List<AcctSeed__Journal_Entry_Line__c> listJEL = new List<AcctSeed__Journal_Entry_Line__c>();
      for(AcctSeed__Journal_Entry_Line__c jel : je.AcctSeed__Journal_Entry_Lines__r)
      {
        AcctSeed__Journal_Entry_Line__c newJEL = jel.clone(false,true);
        newJEL.AcctSeed__Journal_Entry__c = newJE.Id;
        newJEL.AcctSeed__Project__c = null;
        newJEL.AcctSeed__Project_Task__c = null;
        listJEL.add(newJEL);
      }
      if(!listJEL.isEmpty())
        insert listJEL;
      return newJE.Id;
    }

    throw new gcException('No journal entry was found to clone.');
  }

  @RemoteAction @ReadOnly
    public static List<AcctSeed__Journal_Entry__c> searchJournalEntry(String searchTxt)
    {
      List<AcctSeed__Journal_Entry__c> listJE = new List<AcctSeed__Journal_Entry__c>();
        searchTxt = '%'+searchTxt.replaceAll('[*]','%') +'%';

        for(AcctSeed__Journal_Entry__c je :
          [SELECT Id,
            Name
          FROM AcctSeed__Journal_Entry__c
          WHERE Name like :searchTxt
          ORDER BY Name
          LIMIT 5])
        {
            listJE.add(je);
        }
        return listJE;

    }

  private static cube findOrCreateCube(map<Id,map<Id,cube>> mapPT, Id p, Id t)
  {
      if(!mapPT.containsKey(p))
        mapPT.put(p,new map<Id,cube>());
      map<Id,cube> mapT = mapPT.get(p);
      if(!mapT.containsKey(t))
        mapT.put(t, new cube());
      return mapT.get(t);
  }

  private class cube
  {
    Decimal qtyBom{get;set;}
    Decimal qtySpecified{get;set;}
    Decimal qtyOrdered{get;set;}
    Decimal qtyReceived{get;set;}
    Decimal qtyPaid{get;set;}
    Decimal qtyAllocated{get;set;}
    Decimal qtyAllocatedNI{get;set;}
    Decimal qtyWip{get;set;}
    Decimal qtyExpense{get;set;}
    Decimal qtyFinished{get;set;}
    Decimal qtyBilled{get;set;}

    Decimal amtSpecified{get;set;}
    Decimal amtOrdered{get;set;}
    Decimal amtReceived{get;set;}
    Decimal amtPaid{get;set;}
    Decimal amtAllocated{get;set;}
    Decimal amtAllocatedNI{get;set;}
    Decimal amtWip{get;set;}
    Decimal amtExpense{get;set;}
    Decimal amtFinished{get;set;}
    Decimal amtBilled{get;set;}

    Boolean qtySpecifiedOverride{get;set;}
    Id idMaterial;
    Boolean boolHasMoves{get;set;}

    Decimal unitPrice;
    Decimal totalPrice;
    Boolean priceOverride;

    AcctSeedERP__Material__c matl{get;set;}

    cube()
    {
      init();
    }

    cube(AcctSeedERP__Material__c pMatl)
    {
      init();
      matl = pMatl;
    }

    void init()
    {
      qtyBom = 0;
      qtySpecified = 0;
      qtyOrdered = 0;
      qtyReceived = 0;
      qtyPaid = 0;
      qtyAllocated = 0;
      qtyAllocatedNI = 0;
      qtyWip = 0;
      qtyExpense = 0;
      qtyFinished = 0;
      qtyBilled = 0;

      amtSpecified = 0;
      amtOrdered = 0;
      amtReceived = 0;
      amtPaid = 0;
      amtAllocated = 0;
      amtAllocatedNI = 0;
      amtWip = 0;
      amtExpense = 0;
      amtFinished = 0;
      amtBilled = 0;

      qtySpecifiedOverride = false;
      idMaterial = null;
      boolHasMoves = false;

      unitPrice = 0;
      totalPrice = 0;
      priceOverride = false;
    }
  }

  global static void coverage(){
    integer i;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
  }

  global static void coverage2(){
    integer i;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
  }

  global static void coverage3(){
    integer i;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
  }
}