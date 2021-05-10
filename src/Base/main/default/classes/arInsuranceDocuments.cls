public without sharing class arInsuranceDocuments {
  @AuraEnabled
  public static String retrieveERPDetails(Id idProject) {
    Map<String,Object> m = new Map<String,Object>();
    m.put('canDelete', String.valueOf( LGND_Utilities.CustomPermissions.canDeleteInsuranceDocuments ) );
    AcctSeed__Project__c erp = [
      SELECT
        Id,
        Name,
        GL_Account_Variable_3__r.Name,
        First_Payment_Date__c,
      (
        SELECT
          Id,
          AcctSeedERP__Product__r.InsurancePlan__r.Name
        FROM AcctSeedERP__Project_Materials__r
        WHERE AcctSeedERP__Product__r.RecordTypeId = :LGND_Constants.productRtId_Insurance
        LIMIT 1
      )
      FROM AcctSeed__Project__c
      WHERE Id =:idProject
    ];
    m.put('projectName', erp.Name);
    m.put('taxZone', erp.GL_Account_Variable_3__r.Name);
    m.put('hasFirstPaymentDate', erp.First_Payment_Date__c != null);
    m.put('insuranceType', '');
    m.put('hasInsurance', 'false');
    if(!erp.AcctSeedERP__Project_Materials__r.isEmpty()){
      String planName = erp.AcctSeedERP__Project_Materials__r[0].AcctSeedERP__Product__r.InsurancePlan__r.Name;
      m.put('insuranceType', planName);
      if(planName.equals('Companion II'))
        m.put('planPageName', 'InsurancePDFComp_II');
      else if(planName.equals('Advantage 70-P'))
        m.put('planPageName', 'InsurancePDFAdvan');
      else
        m.put('planPageName', 'InsurancePDFComp_Maxum');
      m.put('hasInsurance', 'true');

    }
    return JSON.serialize(m);
  }
  @AuraEnabled
  public static String deleteDocument(Id idProject, Id idErpDoc, Id idDoc) {
    try{
      delete [select Id FROM Document WHERE Id=:idDoc];
      delete [select Id FROM ERP_document__c WHERE Id=:idErpDoc];
      return retrieveERPInsuranceDocuments(idProject);
    }catch(Exception e){
      throw new AuraHandledException(e.getMessage());
    }
  }
  @AuraEnabled
  public static String retrieveERPInsuranceDocuments(Id idProject) {
    List<Map<String,String>> listDocs = new List<Map<String,String>>();
    for(ERP_document__c doc :
    [SELECT Id,
      CreatedDate,
      Name,
      CreatedBy.Name,
      DocumentID__c,
      Project__c
    FROM ERP_document__c
    WHERE Project__c = :idProject
    AND (Report_Type__c != 'Invoice' AND Report_Type__c != null)
    ORDER BY CreatedDate DESC])
    {
      Map<String,String> m = new Map<String,String>();
      m.put('idErpDoc', doc.Id);
      m.put('Name', doc.Name);
      m.put('idDoc', doc.DocumentID__c);
      listDocs.add(m);
    }
    return JSON.serialize(listDocs);
  }



  @AuraEnabled
  public static String generateInsurancePDF(
    String idProject,
    String insuranceType
  )
  {
    return generateInsurancePDF(idProject, insuranceType, 'Eng');
  }

  @AuraEnabled
  public static String generateInsurancePDF(
    String idProject,
    String insuranceType,
    String language
  )
  {
    Savepoint sp = Database.setSavepoint();
    try{
      String pageName = '';
      if(insuranceType.equals('Companion II'))
        pageName = 'InsurancePDFComp_II';
      else if(insuranceType.equals('Advantage 70-P'))
        pageName = 'InsurancePDFAdvan_' + language; // Options: 'Eng' or 'Fr'
      else
        pageName = 'InsurancePDFComp_Maxum';
      AcctSeed__Project__c erpOrder = [SELECT Id, Name, AcctSeedERP__Work_Order_Number__c, Sale_Type__c, RecordTypeId FROM AcctSeed__Project__c WHERE Id = :idProject];
      /// insert the new document
      ERP_document__c doc = new ERP_document__c();
      doc.Project__c = erpOrder.Id;
      doc.Report_Type__c = insuranceType;
      doc.name = erpOrder.AcctSeedERP__Work_Order_Number__c + ' - ' + Datetime.Now().format() + '.pdf';
      doc.documentID__c = null;
      doc.isInvoice__c = false;
      insert doc;
      String certNo = [SELECT Formatted_Certificate_Number__c  FROM ERP_document__c WHERE Id=:doc.Id][0].Formatted_Certificate_Number__c;
      System.debug('certNo: ' + certNo);
      String pageUri = '/apex/' + pageName + '?id=' + erpOrder.Id+'&certNo='+certNo;
      String newName = erpOrder.AcctSeedERP__Work_Order_Number__c + ' - ' + certNo + ' - ' + Datetime.Now().format() + '.pdf';
      PageReference pdfLink =  new PageReference(pageUri);
      Document nd = generateDocument(pdfLink, newName);
      System.debug(nd);
      doc.Name = newName;
      doc.documentID__c = nd.Id;
      update doc;
      /*Map<String,String> m = new Map<String,String>();
      m.put('Name', doc.Name);
      m.put('idDoc', doc.DocumentID__c);
      return JSON.serialize(m);*/
      return retrieveERPInsuranceDocuments(idProject);
    }catch(Exception e){
      Database.rollback(sp);
      throw new AuraHandledException(e.getMessage());
    }
  }

  private static Document generateDocument(PageReference page, String docName)
  {
    System.debug('generateDocument');
    System.debug('page: ' + page);
    System.debug('docName: ' + docName);
    Document doc = new Document ();
    doc.Name = docName;
    doc.Type = 'pdf';
    Blob b;
    if (Test.IsRunningTest()) {
      b = Blob.valueOf('UNIT.TEST');
    }else{
      b = page.getContentAsPDF();
    }
    System.debug('dead yet?');
    doc.Body =  b;
    doc.ContentType = 'application/pdf';
    Folder f = [SELECT Id, Name, DeveloperName FROM Folder WHERE DeveloperName = 'ERP_Invoices'];
    doc.FolderId = f.Id;
    insert doc;
    System.debug(doc);
    return doc;
  }
}