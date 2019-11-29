public with sharing class OpportunityDocumentBuilder {

  public class applicationException extends Exception {}

  public Id opportunityId { get; set; }
  public Opportunity opp {get; set;}
  public Boolean isSaveable { get
    {
      if( isSaveable == null ){
        isSaveable = false;
      }
      return isSaveable;
     } set;
  }

  public Id attachId{ get; set; }
  public static Map<String, Map<String,String>> pageMap = new Map<String, Map<String, String>>{
    'english' => new Map<String, String> { 'quote' => 'opportunityQuotePDF',
                                           'invoice' => 'opportunityInvoicePDF' },
    'french' => new Map<String, String> { 'quote' => 'opportunityQuoteFrenchPDF',
                                         'invoice' => 'opportunityInvoiceFrenchPDF'}
  };
  public String docType { get; set; }
  public String docTypePage { get; set; }
  public String language { get; set; }
  public String taxProvince { get; set; }
  public Boolean renderDoc { get; set; }
  public String quoteValidDate { get; set; }
  public Task fakeTask {get; set;}
  public Date validDate { get; set; }

  public  OpportunityDocumentBuilder()
  {
    this.renderDoc = false;
    fakeTask = new Task(ActivityDate = Date.today() +7);
    validDate = Date.today() + 7;
  }

  public  OpportunityDocumentBuilder(Id oppId)
  {
    this.opportunityId = oppId;
    fetchOpportunity();
  }

  public void preview()
  {
    this.opportunityId = this.opportunityId == null ? ApexPages.currentPage().getParameters().get('id')
                                                    : this.opportunityId;
    fetchOpportunity();
    taxProvince = opp.taxationProvince__c;
    this.docType = ApexPages.currentPage().getParameters().get('docType');
    this.language = taxProvince == 'Quebec' ? 'french' : 'english';
    if( docType == 'quote' )
    {
      this.isSaveable = true;
    }
    if( docType == 'invoice' )
    {
      //this.renderDoc = true;
      if( opp.StageName != 'Quoting'  && !opportunityLocked() )
      {
        this.isSaveable = true;
      }
    }
    this.docTypePage = pageMap.get(this.language).get(docType);
  }

  public void viewOnlyQuote()
  {
    this.opportunityId = ApexPages.currentPage().getParameters().get('opportunity_id');
  }

  public void setQuoteValidDate(){
    renderDoc = true;
    if( docType == 'quote' )
    {
      quoteValidDate = ApexPages.currentPage().getParameters().get('quote_valid_date');
      if( quoteValidDate == null )
      {
        Datetime d = Datetime.now() + 7;
        quoteValidDate = d.format('d/MM/yy');
      }
    }
    language = ApexPages.currentPage().getParameters().get('language');
    language = language == null ? 'english' : language;
    docTypePage = pageMap.get(language).get(docType);
  }

  public List<SelectOption> getLanguageOptions()
  {
    List<SelectOption> options = new List<SelectOption>();
    options.add( new SelectOption('english', 'English') );
    options.add( new SelectOption('french', 'French') );
    return options;
  }

  public List<SelectOption> getProvinceOptions()
  {
    List<SelectOption> options = new List<SelectOption>();
    options.add( new SelectOption('', '-- Select Province --') );
    for( String prov : TaxRate__c.getAll().keySet() )
    {
      options.add( new SelectOption(prov, prov) );
    }
    return options;
  }

  public PageReference savePDF()
  {
    //closeWindow = true;
    return saveThatDoc();
  }

  public PageReference saveAndEmail()
  {
    //closeWindowEmail = true;
    return saveThatDoc();
  }

  private PageReference saveThatDoc()
  {
      System.debug('LANGUAGE ' + language);
      if( this.docType == 'quote' )
      {
        String bName = boatName();
        String fileName = buildFileName(bName);
        Opportunity_Document__c pdf = buildQuotePdf(opportunityId,
                                                    language,
                                                    bName,
                                                    fileName,
                                                    quoteValidDate );
        attachId = pdf.Document_Id__c;
      }
      if( this.docType == 'invoice' )
      {
        Document doc = buildInvoicePDF(opp, language);
        opp.Invoice_Document_Id__c = doc.Id;
        update opp;
        attachId = doc.Id;
      }
      return new PageReference('/'+opportunityId);
  }

  public static Document buildInvoicePDF(Opportunity o, String lang)
  {
    String docName = o.Name + ' - ' + Datetime.Now().format() + '.pdf';
    if( docName.length() > 80 )
    {
      Integer over = docName.length() - 80;
      String shortenedOppName = o.Name.substring(0, (o.Name.length() - over) );
      docName = shortenedOppName + ' - ' + Datetime.Now().format() + '.pdf';
    }
    Document doc = buildPdfDoc( 'Invoice', lang, docName, o.Id);
    insert doc;
    Opportunity_Document__c oppDoc = new Opportunity_Document__c();
    oppDoc.Name = doc.Name;
    oppDoc.Opportunity__c = o.Id;
    oppDoc.Document_Id__c = doc.Id;
    oppDoc.Document_Type__c = 'Invoice';
    insert oppDoc;
    return doc;
  }

  public static Opportunity_Document__c buildQuotePDF(Id oppId,
                                                 String language,
                                                 String bName,
                                                 String fileName)
  {
    String docName = 'Quote - '  + fileName + ' - ' + Datetime.Now().format() + '.pdf';
    Document doc = buildPdfDoc( 'Quote', language, docName, oppId );
    insert doc;

    Opportunity_Document__c oppDoc = new Opportunity_Document__c();
    oppDoc.Name = bName + ' - ' + Datetime.Now().format() + '.pdf';
    oppDoc.Opportunity__c = oppId;
    oppDoc.Document_Type__c = 'Quote';
    oppDoc.Document_Id__c = doc.Id;
    insert oppDoc;

    return oppDoc;

  }

  public static Opportunity_Document__c buildQuotePDF(Id oppId,
                                                 String language,
                                                 String bName,
                                                 String fileName,
                                                 String validDate )
  {
    String docName = 'Quote - '  + fileName + ' - ' + Datetime.Now().format() + '.pdf';
    Document doc = buildPdfDoc( 'Quote', language, docName, oppId, validDate );
    insert doc;

    Opportunity_Document__c oppDoc = new Opportunity_Document__c();
    oppDoc.Name = bName + ' - ' + Datetime.Now().format() + '.pdf';
    oppDoc.Opportunity__c = oppId;
    oppDoc.Document_Type__c = 'Quote';
    oppDoc.Document_Id__c = doc.Id;
    insert oppDoc;

    return oppDoc;

  }

  public static Opportunity_Document__c buildQuotePDF(Id oppId,
                                                  Id attachOppId,
                                                  String language,
                                                 String bName,
                                                 String fileName)
  {
    String docName = 'Quote - '  + fileName + ' - ' + Datetime.Now().format() + '.pdf';
    Document doc = buildPdfDoc( 'Quote', language, docName, oppId );
    insert doc;
    Opportunity_Document__c oppDoc = new Opportunity_Document__c();
    oppDoc.Name = bName + ' - ' + Datetime.Now().format() + '.pdf';
    oppDoc.Opportunity__c = attachOppId;
    oppDoc.Document_Id__c = doc.Id;
    oppDoc.Document_Type__c = 'Quote';
    insert oppDoc;

    return oppDoc;

  }

  private Boolean opportunityLocked()
  {
    Id uId = UserInfo.getUserId();
    CustomPermissionsReader cpr = new CustomPermissionsReader();
    if( cpr.hasPermission('CanEditLockedOpportunity') )
      return false;

    Set<String> statuses = new Set<String>{'Pending', 'Approved'};
    Set<String> approverIds = new Set<String>();
    List<Processinstance> pis = [SELECT Id, Status, LastActorId,
                              (SELECT Id, ActorId From WorkItems)
                            FROM Processinstance
                            WHERE TargetObjectId = :opportunityId
                            AND Status IN :statuses
                            AND IsDeleted = false];
    for(ProcessInstance pi : pis)
    {
      for(ProcessInstanceWorkItem piwi : pi.WorkItems)
      {
        approverIds.add(piwi.ActorId);
      }
    }
    if( !pis.isEmpty() )
    {
      if( approverIds.contains(uId) )
      {
        return false;
      }
      return true;
    }
    return false;
  }

  private static Document buildPdfDoc( String docType, String language, String docName, Id oppId )
  {
    Folder docFolder = docFolder(docType);
    PageReference pdf = pdfPage(docType, language);
    pdf.getParameters().put('opportunity_id', oppId);

    Document doc = new Document ();

    doc.Body =  !Test.isRunningTest() ?  pdf.getContentAsPDF() : Blob.valueOf('This is Just a Test');
    doc.Name = docName;
    doc.Type = 'pdf';
    doc.ContentType = 'application/pdf';
    doc.FolderId = docFolder.Id;
    return doc;
  }

  private static Document buildPdfDoc( String docType,
                                       String language,
                                       String docName,
                                       Id oppId,
                                       String validDate )
  {
    Folder docFolder = docFolder(docType);
    PageReference pdf = pdfPage(docType, language);

    pdf.getParameters().put('opportunity_id', oppId);
    pdf.getParameters().put('quote_valid_date', validDate );
    System.debug('HERE ' + pdf );
    System.debug( validDate );

    Document doc = new Document ();

    doc.Body =  !Test.isRunningTest() ?  pdf.getContentAsPDF() : Blob.valueOf('This is Just a Test');
    doc.Name = docName;
    doc.Type = 'pdf';
    doc.ContentType = 'application/pdf';
    doc.FolderId = docFolder.Id;
    return doc;
  }

  private void fetchOpportunity()
  {
     opp = [SELECT Name, Id, Pricebook2Id, TaxationProvince__c,  AccountId, Account.Name, Account.BillingState, Owner.Id, Owner.Name, ContactEmail__c, StageName,
            (SELECT Id, isPrimary, Role, ContactId, Contact.Name, Contact.Email
             FROM OpportunityContactRoles
             WHERE (Role = 'Buyer'
             OR Role = 'Co-Buyer')
             AND Contact.Email != null),
            (SELECT Id, PricebookEntry.Product2.Name
             FROM OpportunityLineItems
             WHERE PricebookEntry.Product2.RecordType.Name = 'Boat' LIMIT 1)
            FROM Opportunity
            WHERE Id = :opportunityId];
  }

  Private String boatName()
  {
    String name = '';
    if( opp.OpportunityLineItems.size() > 0 )
    {
      name += opp.OpportunityLineItems[0].PricebookEntry.Product2.Name + ' - ';
    }
    return name;
  }

  private String buildFileName(String bName)
  {
    String fileName = bName;
    fileName += opp.Account.Name;
    return fileName;
  }



  private static Folder docFolder(String dType)
  {
    String folderName = 'Opportunity_' + dType + 's';
    try {
      Folder f = [SELECT Id, Name, DeveloperName FROM Folder WHERE DeveloperName = :folderName];
      return f;
    }
    catch(Exception e)
    {
      throw new applicationException('No Opportunity Quotes folder found.  Please contact an Administrator');
    }
  }

  private static PageReference pdfPage(String docType, String lang)
  {
    try
    {
      return new PageReference( '/apex/' + pageMap.get(lang.toLowerCase()).get(docType.toLowerCase()) );
    }
    catch(Exception e)
    {
      return null;
    }
  }

}