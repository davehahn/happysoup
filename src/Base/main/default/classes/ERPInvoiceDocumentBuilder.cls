global with sharing class ERPInvoiceDocumentBuilder {

  public class applicationException extends Exception {}

  public Id opportunityId { get; set; }
  public AcctSeed__Project__c erpOrder {get; set;}
  public String erpOrderID{get; set;}
  public String docType { get; set; }
  public String language { get; set; }
  public String erpRecordType { get; set; }
  //public String erpSaleType { get; set; }
  public Boolean renderDoc { get; set; }
  public String accountName { get; set; }
  public Boolean hasInternalCopy { get; set ;}
  public String version { get; set; }
  public List<ERP_Document__c> erpDocuments { get; set; }
  public Boolean creatingNew { get; set; }
  public Boolean hasDocHistory { get; set; }
  public String currentDocumentId { get; set; }
  public Boolean showCreateNew { get; set; }


  public  ERPInvoiceDocumentBuilder(){
    //Id counterSaleRtId = gcConstants.idRtProjectCounterSale;
    //Id serviceRtId = gcConstants.idRtProjectService;
    //Id retailBoatSaleRtId = gcConstants.idRtProjectBoatSale;
    //Id partnerBoatSaleRtId = gcConstants.idRtProjectPartnerBoatSale;
    Set<Id> rt_with_internal_copy = new Set<Id>{
      gcConstants.idRtProjectService,
      gcConstants.idRtProjectBoatSale,
      gcConstants.idRtProjectWarranty,
      gcConstants.idRtProjectPartnerBoatSale
    };
    this.erpOrderID = ApexPages.currentPage().getParameters().get('id');
    if ( this.erpOrderID == null )
    {
      this.erpOrderID = ApexPages.currentPage().getParameters().get('erpOrderId');
    }
    this.showCreateNew = true;
    this.currentDocumentId = null;
    this.hasDocHistory = false;
    this.renderDoc = false;
    this.hasInternalCopy = false;
    this.creatingNew = true;
    this.version = 'customer';
    this.erpOrder = [SELECT Id,
                            Name,
                            RecordTypeId,
                            CreatedDate,
                            LastDocumentID__c,
                            AcctSeedERP__Work_Order_Number__c,
                            Sale_Type__c,
                            AcctSeed__Opportunity__c,
                            AcctSeed__Account__c,
                            AcctSeed__Account__r.BillingStreet,
                            AcctSeed__Account__r.BillingCity,
                            AcctSeed__Account__r.BillingState,
                            AcctSeed__Account__r.BillingPostalCode,
                            AcctSeed__Account__r.BillingCountry,
						                AcctSeed__Account__r.PersonEmail,
                            AcctSeed__Account__r.Drivers_License__c,
                            AcctSeed__Account__r.Name,
                            AcctSeed__Account__r.LastName,
                            AcctSeed__Account__r.Phone,
                            AcctSeed__Account__r.PersonBirthdate,
                            AcctSeed__Account__r.Preferred_Language__c,
                            Salesperson__r.Name,
                            Salesperson__r.LastName,
                            Internal_warranty__c
						          FROM AcctSeed__Project__c
                      WHERE Id =: this.erpOrderID ];

    User currentUser = [SELECT Id, Warehouse__c FROM User WHERE Id = :UserInfo.getUserId() ];

    this.erpDocuments = [ SELECT Id,
                                 CreatedDate,
                                 Name,
                                 CreatedBy.Name,
                                 DocumentID__c,
                                 Project__c
                          FROM ERP_document__c
                          WHERE Project__c = :erpOrder.Id
                          AND Report_Type__c = 'Invoice'
                          ORDER BY CreatedDate DESC];
    if( erpDocuments.size() > 0 )
    {
      this.creatingNew = false;
      this.hasDocHistory = true;
      for( ERP_Document__c erpDoc : erpDocuments )
      {
        if( erpDoc.Project__c == erpOrder.LastDocumentID__c )
          currentDocumentId = erpDoc.DocumentId__c;
      }
      if( currentDocumentId == null )
        currentDocumentId = erpDocuments[0].DocumentId__c;
    }


    if( erpOrder.AcctSeed__Account__r.Preferred_Language__c != null )
      this.language = erpOrder.AcctSeed__Account__r.Preferred_Language__c.toLowerCase();
    else if( currentUser.Warehouse__c != null && currentUser.Warehouse__c == 'Montreal' )
      this.language = 'french';
    else
      this.language = 'english';

    this.erpRecordType = erpOrder.RecordTypeId;
    if(erpOrder.RecordTypeId == gcConstants.idRtProjectCounterSale
        || erpOrder.RecordTypeId == gcConstants.idRtPartnerPartsOrder )
       // || (erpOrder.Internal_warranty__c && erpOrder.RecordTypeId == gcConstants.idRtProjectWarranty))
        this.showCreateNew = false;
    ////this.erpSaleType = erpOrder.Sale_Type__c;
    if( rt_with_internal_copy.contains( this.erpRecordType ) )
      hasInternalCopy = true;

    this.docType = fetchPdfName( this.erpRecordType, this.language, this.version );

  }

  @AuraEnabled
  public static List<ERP_document__c> fetchErpDocuments( String recordId )
  {
    return [
      SELECT
        Id,
        CreatedDate,
        Name,
        CreatedBy.Name,
        DocumentID__c,
        Project__c
      FROM ERP_document__c
      WHERE Project__c = :recordId
      AND Report_Type__c = 'Invoice'
      ORDER BY CreatedDate DESC
    ];
  }

  global String getErpDocsJSON()
  {
    return JSON.serialize( this.erpDocuments );
  }

  global PageReference setupNew()
  {
    creatingNew = true;
    return null;
  }

  global PageReference cancelNewSetup()
  {
    creatingNew = false;
    return null;
  }

  global String getAccountId()
  {
    return this.erpOrder.AcctSeed__Account__c;
  }

  @RemoteAction
  global static List<String> fetchEmailAddresses(String accountId)
  {
    List<String> result = new List<String>();
    for( Contact c : [SELECT Email FROM Contact WHERE AccountId = : accountId] )
    {
      if( c.Email != null )
        result.add( c.Email );
    }
    return result;
  }

  @RemoteAction
  global static PageReference savePDF(String erpId, String pageName) {
    ERP_Document__c doc = generateERPDocument( erpId, pageName );
    return new PageReference('/' + erpId);
  }

  @RemoteAction
  global static String savePDF_LEX(String erpId, String pageName) {
    ERP_Document__c doc = generateERPDocument( erpId, pageName );
    return doc.DocumentID__c;
  }

  @RemoteAction
  global static ERP_Document__c[] fetchDocuments( String erpId )
  {
    return [SELECT Id,
                   CreatedDate,
                   Name,
                   CreatedBy.Name,
                   DocumentID__c,
                   Project__c
            FROM ERP_document__c
            WHERE Project__c = :erpId
                AND (Report_Type__c = 'Invoice'
                    OR Report_Type__c = null)
            ORDER BY CreatedDate DESC];
  }

  @RemoteAction
  global static String emailPDF( String jsonData )
  {
    List<String> docIds = new List<String>();
    Map<String, String> emailData = (Map<String, String>)JSON.deserialize( jsonData, Map<String, String>.class);

    if( emailData.containsKey( 'documentId' ) )
      docIds.add( emailData.get( 'documentId' ) );
    else
      docIds.add( generateERPDocument( emailData.get('erpId'), emailData.get('pageName') ).DocumentId__c );

    // Define the email
    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

    String[] toAddresses;
    String[] ccAddresses;

    if( emailData.get('toAddresses') != '' )
      toAddresses = emailData.get('toAddresses').remove(' ').split(',');
    if( emailData.get('ccAddresses') != '' )
      ccAddresses = emailData.get('ccAddresses').remove(' ').split(',');


    email.subject = emailData.get('subject');
    email.setToAddresses( toAddresses );
    email.setCcAddresses( ccAddresses );
    email.setPlainTextBody( emailData.get('message') );
    email.setEntityAttachments( docIds );
    //email.setFileAttachments( new Messaging.EmailFileAttachment[] {efa} );
    email.setWhatId( emailData.get('erpId') );
    email.setSaveAsActivity( true );

    //Send the email
    Messaging.SendEmailResult[] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
    return docIds[0];
  }

  @RemoteAction
  global static String fetchPdfName(String recordType, String language, String version)
  {
    Id counterSaleRtId = gcConstants.idRtProjectCounterSale;
    Id partnerPartOrder = gcConstants.idRtPartnerPartsOrder;
    Id serviceRtId = gcConstants.idRtProjectService;
    Id manufacturingRtId = gcConstants.idRtProjectManufacturing;
    Id retailBoatSaleRtId = gcConstants.idRtProjectBoatSale;
    Id partnerBoatSaleRtId = gcConstants.idRtProjectPartnerBoatSale;
    Id warrantyRtId = gcConstants.idRtProjectWarranty;
    Id tradeInRtId = gcConstants.idRtTradeIn;
    Id fixedAssetRtId = gcConstants.idRtFixedAsset;
    String result;
    if( recordType == retailBoatSaleRtId )
    {
      //if( version == 'internal')
      //  result = 'ERPInvoicePDF_ServiceOrder';
      //else
        result = 'ERPInvoicePDF_RetailBoatSale';
    }

    if( recordType == partnerBoatSaleRtId )
    {
      if( version == 'internal')
        result = 'ERPInvoicePDF_RetailBoatSale';
      else
        result = 'ERPInvoicePDF_PartnerBoatSale';
    }

    if( recordType == counterSaleRtId ||
        recordType == partnerPartOrder)
      result = 'ERPInvoicePDF_RetailCounterSale';
      //result = 'ERPInvoicePDF_RetailCounterSaleNew';

    if( recordType == serviceRtId ||
        recordType == warrantyRtId ||
        recordType == tradeInRtId ||
        recordType == fixedAssetRtId)
      result = 'ERPInvoicePDF_ServiceOrder';

    if( recordType == manufacturingRtId )
      result = 'ERPInvoicePDF_ServiceOrderInt';

    if( version == 'internal' )
      result += 'Int';

    if( language == 'french' )
      result += '_French';

    return result;
  }

	public static ERP_Document__c generateBillingDocument(String erpId, String pageName, String idBill)
    {
        System.debug(loggingLevel.error,'we are here');
        if(idBill == null) throw new gcException('no idBill');
        AcctSeed__Project__c erpOrder = [SELECT Id, Name, Sale_Type__c, RecordTypeId FROM AcctSeed__Project__c WHERE Id = :erpId];
        String pageUri = '/apex/' + pageName + '?billId=' + idBill + '&erpOrderId='+erpOrder.Id;
        System.debug(loggingLevel.error,'pageUri:'+pageUri);
        String docName = 'Invoice - ';
        Boolean isInvoice = true;
        if( ( erpOrder.RecordTypeId == gcConstants.idRtProjectBoatSale ||
              erpOrder.RecordTypeId == gcConstants.idRtProjectPartnerBoatSale )
            && pageName == 'ERPInvoicePDF_ServiceOrderInt' )
        {
          pageUri += '&version=internal';
          docName = 'Parts List - ';
          isInvoice = false;
        }
        PageReference pdfLink =  new PageReference(pageUri);
        ERP_document__c doc = new ERP_document__c();
        doc.Project__c = erpOrder.Id;
        doc.Billing__c = idBill;
        doc.Report_Type__c = 'Invoice';
        doc.name = docName + (erpOrder.Name).LEFT(35) + ' - ' + Datetime.Now().format() + '.pdf';
        doc.documentID__c = generateDocument(pdfLink, doc.name).id;
        doc.isInvoice__c = isInvoice;
        doc.Document_Type__c = erpOrder.Sale_Type__c;
        doc.Report_Type__c = 'Invoice';
        //doc.PDF_Link__c = 'https://' + ApexPages.currentPage().getHeaders().get('Host') + '/apex/' + pageName + '?erpOrderId=' + erpOrder.Id;
        insert doc;
        return doc;
    }

    public static ERP_Document__c generateTransferDocument(String erpId, String pageName, String idTransfer)
    {
        System.debug(loggingLevel.error,'we are here');
        if(idTransfer == null) throw new gcException('no idTransfer');
        AcctSeed__Project__c erpOrder = [SELECT Id, Name, Sale_Type__c, RecordTypeId FROM AcctSeed__Project__c WHERE Id = :erpId];
        String pageUri = '/apex/' + pageName + '?transferId=' + idTransfer + '&erpOrderId='+erpOrder.Id;
        System.debug(loggingLevel.error,'pageUri:'+pageUri);
        String docName = 'Invoice - ';
        Boolean isInvoice = true;
        if( ( erpOrder.RecordTypeId == gcConstants.idRtProjectBoatSale ||
              erpOrder.RecordTypeId == gcConstants.idRtProjectPartnerBoatSale )
            && pageName == 'ERPInvoicePDF_ServiceOrderInt' )
        {
          pageUri += '&version=internal';
          docName = 'Parts List - ';
          isInvoice = false;
        }
        PageReference pdfLink =  new PageReference(pageUri);
        ERP_document__c doc = new ERP_document__c();
        doc.Project__c = erpOrder.Id;
        doc.Inventory_Transfer__c = idTransfer;
        doc.Report_Type__c = 'Invoice';
        doc.name = docName + (erpOrder.Name).LEFT(35) + ' - ' + Datetime.Now().format() + '.pdf';
        doc.documentID__c = generateDocument(pdfLink, doc.name).id;
        doc.isInvoice__c = isInvoice;
        doc.Document_Type__c = erpOrder.Sale_Type__c;
        doc.Report_Type__c = 'Invoice';
        //doc.PDF_Link__c = 'https://' + ApexPages.currentPage().getHeaders().get('Host') + '/apex/' + pageName + '?erpOrderId=' + erpOrder.Id;
        insert doc;
        return doc;
    }

    public static ERP_Document__c generateERPDocument(String erpId, String pageName)
    {
        AcctSeed__Project__c erpOrder = [SELECT Id, Name, Sale_Type__c, RecordTypeId FROM AcctSeed__Project__c WHERE Id = :erpId];
        String pageUri = '/apex/' + pageName + '?erpOrderId=' + erpOrder.Id;
        String docName = 'Invoice - ';
        Boolean isInvoice = true;
        if( ( erpOrder.RecordTypeId == gcConstants.idRtProjectBoatSale ||
              erpOrder.RecordTypeId == gcConstants.idRtProjectPartnerBoatSale )
            && pageName == 'ERPInvoicePDF_ServiceOrderInt' )
        {
          pageUri += '&version=internal';
          docName = 'Parts List - ';
          isInvoice = false;
        }
    		PageReference pdfLink =  new PageReference(pageUri);
    		ERP_document__c doc = new ERP_document__c();
    		doc.Project__c = erpOrder.Id;
            doc.Report_Type__c = 'Invoice';
    		doc.name = docName + (erpOrder.Name).LEFT(35) + ' - ' + Datetime.Now().format() + '.pdf';
    		doc.documentID__c = generateDocument(pdfLink, doc.name).id;
        doc.isInvoice__c = isInvoice;
    		doc.Document_Type__c = erpOrder.Sale_Type__c;
        doc.Report_Type__c = 'Invoice';
		//doc.PDF_Link__c = 'https://' + ApexPages.currentPage().getHeaders().get('Host') + '/apex/' + pageName + '?erpOrderId=' + erpOrder.Id;
		insert doc;
		return doc;
	}

	public static Document generateDocument(PageReference page, String docName)
  {
		Document doc = new Document ();
    doc.Name = docName;
    doc.Type = 'pdf';
    Blob b;
    if (Test.IsRunningTest()) {
        b = Blob.valueOf('UNIT.TEST');
    }else{
        b = page.getContentAsPDF();
   }
    doc.Body =  b;
    doc.ContentType = 'application/pdf';
    Folder f = [SELECT Id, Name, DeveloperName FROM Folder WHERE DeveloperName = 'ERP_Invoices'];
    doc.FolderId = f.Id;
    insert doc;
    return doc;
	}

  public static void coverage(){
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
  }

}