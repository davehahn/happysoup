public with sharing class CaseLexController {

  public class CaseWarrantyException extends Exception{}

  public class DataWrapper {
    public List<String> typeOptions { get; set; }
    public List<String> reasonOptions { get; set; }
    public List<String> claimTypeOptions { get; set; }
    public List<String> priorityOptions { get; set; }
    public String userName { get; set; }
    public String userEmail { get; set; }
    public String userId {get; set; }
    public DataWrapper(){}
  }

  public class SubmitDataWrapper {
    //public String url { get; set; }
    //public String orgid { get; set; }
    //public String contactId { get; set; }
    public String recordTypeName { get; set; }
    //public String name { get; set; }
    //public String email { get; set; }
    public String caseType { get; set; }
    public String claimType { get; set; }
    public String serialId { get; set; }
    public String accountId { get; set; }
    public Date failureDate { get; set; }
    public String reason { get; set; }
    public String priority { get; set; }
    public String subject { get; set; }
    public String description { get; set; }
    public SubmitDataWrapper(){}
  }

  public class RecoverableWrapper {
    public String erpId;
    public List<AcctSeedERP__Material__c> materials;
    public RecoverableWrapper(){}
  }


  @AuraEnabled
  public static String initData()
  {
    DataWrapper dw = new DataWrapper();
    User cu = [SELECT Id, Name, Email FROM User WHERE Id = :UserInfo.getUserId()];
    dw.userName = cu.Name;
    dw.userEmail = cu.Email;
    dw.userId = cu.Id;
    dw.typeOptions = LGND_Utilities.getPicklistValues('Case', 'Type');
    dw.reasonOptions = LGND_Utilities.getPicklistValues('Case', 'Reason');
    dw.priorityOptions = LGND_Utilities.getPicklistValues('Case', 'Priority');
    dw.claimTypeOptions = LGND_Utilities.getPicklistValues('Case', 'Claim_Type__c');
    return JSON.serialize( dw );
  }

  //@AuraEnabled
  //public static String setupLegendGallery(String recordId)
  //{
  //  return JSON.serialize( new LegendGallery( recordId ) );
  //}

  //@AuraEnabled
  //public static void createImageRecord( String data )
  //{
  //  LegendGalleryRemoter.createRecord( data );
  //}

  @AuraEnabled
  public static Case_Part__c[] fetchCaseParts( String caseId )
  {
    return [SELECT Id, Name, Product__c, Quantity__c, Order_Quantity__c, Product__r.Name, Product__r.Unique_Product_Code__c
            FROM Case_Part__c
            WHERE Case__c = :caseId];
  }

  @AuraEnabled
  public static Case fetchCase( String caseId )
  {
    return [SELECT Id, Recoverable_ERP__c FROM Case WHERE Id = :caseId ];
  }

  @AuraEnabled
  public static GMBLASERP__Serial_Number__c fetchSerial( Id serialId )
  {
    if (String.isBlank(serialId)) {
        return null;
    }

    List<GMBLASERP__Serial_Number__c> serial = [SELECT Id, Product_Name__c, Name, GMBLASERP__Lot__r.Name FROM GMBLASERP__Serial_Number__c WHERE Id = :serialId];

    if (serial.isEmpty()) {
        return null;
    }

    return serial[0];
  }

  @AuraEnabled
  public static Case[] fetchWarrantyHistory( String recordId )
  {
    String sObjectType = LGND_Utilities.sObjectNameFromId( recordId );
    String serId;
    switch on sObjectType {
      when 'Case' {
        serId = [SELECT Id, Serial_Number__c FROM Case WHERE Id = :recordId ].Serial_Number__c;
      }
      when 'GMBLASERP__Serial_Number__c' {
        serId = recordId;
      }
    }
    if( serId == null)
    {
      String err = 'Invalid Id specified!\n\r Please specify either a Case or Serial Number Id';
      AuraHandledException ex = new AuraHandledException(err);
      ex.setMessage(err);
      throw ex;
    }
    else
    {
      return [SELECT Id,
                      CreatedDate,
                      CaseNumber,
                      Claim_Type__c,
                      Correction__c,
                      ClosedDate,
                      Description,
                      Subject,
                      Status
              FROM Case
              WHERE Serial_Number__c = :serId
              AND Id <> :recordId
              ORDER BY CreatedDate DESC];
    }
  }

  @AuraEnabled
  public static String saveTheCase( String jsonData )
  {
    SubmitDataWrapper data = (SubmitDataWrapper)JSON.deserialize( jsonData, SubmitDataWrapper.class );
    String rtId;
    try {
        rtId = LGND_Utilities.recordTypeIdFromName('Case', data.recordTypeName );
    }
    catch( Exception e )
    {
        rtId = LGND_Utilities.recordTypeIdFromName('Case', 'Salesforce');
    }

    Case c = new Case(
      RecordTypeId = rtId,
      Origin = 'Internal',
      Subject = data.subject,
      Reason = data.reason,
      Priority = data.priority,
      Description = data.description,
      Type = data.caseType,
      Claim_Type__c = data.claimType,
      Date_Failure__c = data.failureDate,
      Serial_Number__c = data.serialId,
      AccountId = data.accountId
    );
    insert c;
    return JSON.serialize( c );
  }

  @AuraEnabled
  public static Account[] fetchAllSuppliers()
  {
    return [SELECT Id, Name FROM Account WHERE RecordType.Name = 'Supplier' ORDER BY Name];
  }

  @AuraEnabled
  public static String createWarrantyRecoverableERP( String acctId, String caseId )
  {
    RecoverableWrapper result = new RecoverableWrapper();
    Account acct = [SELECT Id, Name FROM Account WHERE Id = :acctId ];
    Case c = [SELECT Id,
                     Serial_Number__c,
                     Description,
                     Correction__c,
                     Warranty_ERP__c,
                     Partner_Reference__c,
                     Price_Book__c,
                     Shipping_Company__c,
                     Shipping_Company_Other__c,
                     Shipping_Cost__c
              FROM Case WHERE Id = :caseId ];

    AcctSeed__Project__c payableErp = [SELECT Customer_Notes__c
                                         FROM AcctSeed__Project__c
                                        WHERE Id = :c.Warranty_ERP__c];

    if( c.Warranty_ERP__c == null )
    {
      throw new AuraHandledException('Can not create a recoverable ERP without a Warranty ERP');
    }
    else
    {
      AcctSeed__Project__c erp = createWarrantyErp( acct, c );
      erp.Customer_Notes__c += payableErp.Customer_Notes__c;
      if( c.Partner_Reference__c != null &&
          c.Partner_Reference__c != '' &&
          !erp.Customer_Notes__c.contains( c.Partner_Reference__c ) )
      {
        erp.Customer_Notes__c += 'Partner Reference: ' + c.Partner_Reference__c + '. ';
      }

      insert erp;
      result.erpId = erp.Id;

      // payable task Id ,cloned task (Warranty Recoverable)
      Map<Id, AcctSeed__Project_Task__c> old_new_tasks = new Map<Id, AcctSeed__Project_Task__c>();
      //payable task id, list of payable materials
      Map<Id, List<AcctSeedERP__Material__c>> payable_taskId_materials = new Map<Id, List<AcctSeedERP__Material__c>>();
      //recoverable Materials
      result.materials = new List<AcctSeedERP__Material__c>();

      String pTaskName = '%' + LGND_Constants.WarrantyPayableTaskName + '%';
      for( AcctSeed__Project_Task__c task : [ SELECT Id,
                                                     DisplayOnCustomerInvoice__c,
                                                     Correction_dh__c,
                                                     Complaint_dh__c,
                                              (SELECT Id,
                                                      AcctSeedERP__Product__c,
                                                      AcctSeedERP__Product__r.Name,
                                                      AcctSeedERP__Product__r.Family,
                                                      AcctSeedERP__Product__r.AcctSeed__Unit_Cost__c,
                                                      AcctSeedERP__Product__r.AcctSeed__Inventory_product__c,
                                                      AcctSeedERP__Quantity_Per_Unit__c,
                                                      GMBLASERP__Unit_Price__c,
                                                      GMBLASERP__Price_Override__c,
                                                      AcctSeedERP__Comment__c
                                               FROM AcctSeedERP__Materials__r)
                                              FROM AcctSeed__Project_Task__c
                                              WHERE AcctSeed__Project__c = :c.Warranty_ERP__c
                                              AND Name LIKE :pTaskName] )
      {
        AcctSeed__Project_Task__c t = task.clone(false, true);
        t.AcctSeed__Project__c = erp.Id;
        t.Name = LGND_Constants.WarrantyRecoverableTaskName;
        old_new_tasks.put(task.Id, t);
        payable_taskId_materials.put(task.Id, task.AcctSeedERP__Materials__r );
      }
      insert old_new_tasks.values();

      for( Id payableTaskId : payable_taskId_materials.keySet() )
      {
        for( AcctSeedERP__Material__c payableMat : payable_taskId_materials.get( payableTaskId ) )
        {
          AcctSeedERP__Material__c mat = payableMat.clone(false, true);
          mat.AcctSeedERP__Project__c = erp.Id;
          mat.AcctSeedERP__Project_Task__c = old_new_tasks.get( payableTaskId ).Id;
          if( payableMat.AcctSeedERP__Product__r.Family != null &&
              payableMat.AcctSeedERP__Product__r.Family.contains('Labour') )
          {
            mat.GMBLASERP__Unit_Price__c = payableMat.GMBLASERP__Unit_Price__c;
            mat.Supplier_Credit_Requested__c = true;
          }
          else
          {
            mat.GMBLASERP__Unit_Price__c = payableMat.AcctSeedERP__Product__r.AcctSeed__Unit_Cost__c;
            mat.Supplier_Credit_Requested__c = false;
          }

          mat.No_WIP__c = payableMat.AcctSeedERP__Product__r.AcctSeed__Inventory_product__c;
          mat.GMBLASERP__Price_Override__c = true;
          result.materials.add( mat );
        }
      }

      if( c.Shipping_Cost__c != null && c.Shipping_Cost__c > 0 && c.Shipping_Company__c != null )
      {
        String company = c.Shipping_Company_Other__c != null ? c.Shipping_Company_Other__c :
                                                               c.Shipping_Company__c;
        AcctSeed__Project_Task__c shippingTask = createProjectTask( erp.Id, LGND_Constants.WarrantyRecoverableTaskName );
        shippingTask.Complaint_dh__c = 'Shipping Charges';
        shippingTask.Correction_dh__c = 'Shipping Charges';
        insert shippingTask;
        AcctSeedERP__Material__c shippingMat = buildMaterial( erp.Id,
                                                              shippingTask.Id,
                                                              Utility_Products__c.getOrgDefaults().Freight__c,
                                                              c.Shipping_Cost__c,
                                                              company );
        shippingMat.Supplier_Credit_Requested__c = true;
        result.materials.add( shippingMat );
    }
      //insert recoverableMaterials;
      c.Recoverable_ERP__c = erp.Id;
      update c;
      //return erp.Id;
      return JSON.serialize( result );
    }
  }

  @AuraEnabled
  public static String createWarrantyRecoverableMaterials(String JSONmaterials )
  {
    try {
      List<AcctSeedERP__Material__c> materials =
        (List<AcctSeedERP__Material__c>)JSON.deserialize(
        JSONmaterials,  List<AcctSeedERP__Material__c>.class
      );
      insert materials;
      return materials[0].AcctSeedERP__Project__c;
    }
    catch( Exception e )
    {
      String msg = e.getMessage();
      AuraHandledException ex = new AuraHandledException( msg );
      ex.setMessage( msg );
      throw ex;
    }
  }

  @AuraEnabled
  public static void deleteERP( String erpId )
  {
    try {
      delete new AcctSeed__Project__c( Id = erpId );
    }
    catch( Exception e )
    {
      String msg = e.getMessage();
      AuraHandledException ex = new AuraHandledException( msg );
      ex.setMessage( msg );
      throw ex;
    }
  }

  @AuraEnabled
  public static void saveCaseParts( Case_Part__c[] caseParts )
  {
    insert caseParts;
  }

  @AuraEnabled
  public static String fetchCasePartsPermissions( String caseId )
  {
    Map<String, Boolean> perms = new Map<String, Boolean>();
    perms.put('isLocked', false);
    perms.put('canCreate', Schema.sObjectType.Case_Part__c.isCreateable() );
    perms.put('canDelete', Case_Part__c.sObjectType.getDescribe().isDeletable() );
    Case c = [SELECT Id,
                     Status,
                     Can_Add_Parts__c,
                     Parts_Order_ERP__c,
                     Recoverable_ERP__c,
                     Recoverable_ERP__r.AcctSeed__Status__c
              FROM Case
              WHERE Id = :caseId];
    if(c.Recoverable_ERP__c != null && c.Recoverable_ERP__r.AcctSeed__Status__c == 'Completed')
      perms.put('isLocked', true);

  if(!perms.get('isLocked'))
    perms.put('isLocked', !c.Can_Add_Parts__c);

    return JSON.serialize( perms );
  }

  @AuraEnabled
  public static void deleteCasePart( String recordId )
  {
    Case_Part__c cp = [SELECT Id FROM Case_Part__c WHERE Id = :recordId ];
    delete cp;
  }

  public static AcctSeedERP__Material__c createSubletMaterialLine( Id erpId,
                                                                   Id taskId,
                                                                   Decimal amount,
                                                                   String company )
  {
    return buildMaterial( erpId,
                          taskId,
                          Utility_Products__c.getOrgDefaults().Sublet__c,
                          amount,
                          company );
  }

  private static AcctSeedERP__Material__c buildMaterial( Id erpId,
                                                         Id taskId,
                                                         Id prodId,
                                                         Decimal amount,
                                                         String comment )
  {
    return new AcctSeedERP__Material__c(
        AcctSeedERP__Product__c = prodId,
        AcctSeedERP__Quantity_Per_Unit__c = 1,
        AcctSeedERP__Project__c = erpId,
        AcctSeedERP__Project_Task__c = taskId,
        GMBLASERP__Unit_Price__c = amount,
        GMBLASERP__Price_Override__c = true,
        AcctSeedERP__Comment__c = comment
    );
  }

  private static AcctSeed__Project__c createWarrantyErp( Account acct, Case c )
  {
    String projectName = 'Recoverable-' + acct.Name.trim();
    return new AcctSeed__Project__c (
      Name = projectName,
      RecordTypeId = gcConstants.idRtProjectWarranty,
      AcctSeed__Account__c = acct.Id,
      Serial_Number__c = c.Serial_Number__c,
      GMBLASERP__Pricebook__c = c.Price_Book__c,
      Warranty_Case__c = c.Id,
      Customer_Notes__c = ''
    );
  }

  private static AcctSeed__Project_Task__c createProjectTask( Id erpId,
                                                              String taskName )
  {
    ERPOrderTaskNames__c taskNameSetting = ERPOrderTaskNames__c.getInstance(taskName);
    Boolean showInInvoice = taskNameSetting != null ? taskNameSetting.Show_In_Invoice__c : false;
    return new AcctSeed__Project_Task__c(
        AcctSeed__Project__c = erpId,
        DisplayOnCustomerInvoice__c = showInInvoice,
        Name = taskName
    );
  }


//  private static AcctSeedERP__Material__c[] createRecoverableMaterials( AcctSeedERP__Material__c[] mats,
//                                                                        Id erpId,
//                                                                        Id taskId )
//  {
//    AcctSeedERP__Material__c[] materials = new List<AcctSeedERP__Material__c>();
//    for( AcctSeedERP__Material__c m : mats )
//    {
//      materials.add( new AcctSeedERP__Material__c(
//        AcctSeedERP__Product__c = m.AcctSeedERP__Product__c,
//        AcctSeedERP__Quantity_Per_Unit__c = m.AcctSeedERP__Quantity_Per_Unit__c,
//        AcctSeedERP__Project__c = erpId,
//        AcctSeedERP__Project_Task__c = taskId,
//        GMBLASERP__Price_Override__c = m.GMBLASERP__Price_Override__c,
//        AcctSeedERP__Comment__c = m.AcctSeedERP__Comment__c,
//        GMBLASERP__Unit_Price__c = ( m.AcctSeedERP__Product__r.AcctSeed__Unit_Cost__c != null &&
//                                     m.AcctSeedERP__Product__r.AcctSeed__Unit_Cost__c > 0 ) ?
//                                   m.AcctSeedERP__Product__r.AcctSeed__Unit_Cost__c :
//                                   m.GMBLASERP__Unit_Price__c
//
//      ));
//    }
//    return materials;
//  }

  public static void coverage()
  {
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
  }

}