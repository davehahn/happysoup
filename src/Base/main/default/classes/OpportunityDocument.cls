global with sharing class OpportunityDocument {

  public BoatBuilder boatBuilder { get; private set; }
  public String renderType { get; private set; }
  public Boolean renderSeperateTaxes { get; private set; }
  public TaxRate__c provTaxRate { get; private set; }

  global OpportunityDocument()
  {
    Id oppId = ApexPages.currentPage().getParameters().get('opportunity_id');
    if( oppId == null )
    {
      oppId = ApexPages.currentPage().getParameters().get('id');
    }
    String rType = ApexPages.currentPAge().getParameters().get('render_type');
    //String validDate = ApexPages.currentPage().getParameters().get('valid_quote_date');
    //Date quoteDate;
    //if( validQuoteDate !== null )
    //  quoteDate = Date.parse( validDate );
    renderType = '';
    if( rType != null )
    {
      renderType = rType;
    }
    if( oppId != null )
    {
      this.boatBuilder = new BoatBuilder(oppId);
      //this.provTaxRate = TaxRate__c.getAll().get( this.boatBuilder.opportunity.TaxationProvince__c );
    }
  }

  global OpportunityDocument(ApexPages.StandardController ctr){ }

  global static void triggerHandler
    (map<Id,Opportunity_Document__c> oldMap,
     map<Id,Opportunity_Document__c> newMap,
     list<Opportunity_Document__c> listNew,
     Boolean boolIsBefore,
     Boolean boolIsInsert,
     Boolean boolIsUpdate,
     Boolean boolIsDelete)
  {

    if(oldMap == NULL) oldMap = new map<Id,Opportunity_Document__c>();
    if(newMap == NULL) newMap = new map<Id,Opportunity_Document__c>();
    if(listNew == NULL) listNew = new list<Opportunity_Document__c>();

    if(boolIsBefore)
    {
      //if(boolIsInsert)
      //{
      //  return;
      //}
      //if(boolIsUpdate)
      //{
      //  return;
      //}
      //if(boolIsDelete)
      //{
      //  return;
      //}
    }
    else //i.e. trigger.isAfter
    {
      //if(boolIsInsert)
      //{
      //  return;
      //}
      //if(boolIsUpdate)
      //{
      //  return;
      //}
      if(boolIsDelete)
      {
        Set<Id> docIds = new Set<Id>();
        for( Opportunity_Document__c od : oldMap.values() )
        {
          docIds.add(od.Document_Id__c);
        }
        if( !docIds.isEmpty() )
        {
          List<Document> docs = [SELECT Id FROM Document WHERE Id IN :docIds];
          delete docs;
        }
        return;
      }
    }


  }// /triggerHandler
}