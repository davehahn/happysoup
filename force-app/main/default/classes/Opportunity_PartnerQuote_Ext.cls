public with sharing class Opportunity_PartnerQuote_Ext {

  public Boolean isForCustomer { get; set; }
  public final Id quoteId;
  public final Id oppId;
	public Opportunity opp { get; set; }
  public Quote qt { get; set ;}
  public Account customer { get; set; }
  public Contact buyer { get; set; }
  public Contact cobuyer { get; set; }
  public Account partner { get; set; }
  public CPQ theCPQ { get; set; }
  public List<CPQ_Lib_dh.Fee> allFees { get; set; }
  public CPQ_Lib_dh.TradeIn tradeIn { get; set; }
  public Date expireDate { get; set; }
  public Decimal deposit { get; set; }
  public Decimal totalSavings { get; set; }
  public String logo { get; set; }
  public Boolean displayPayments { get; set; }

  public Opportunity_PartnerQuote_Ext()
  {
    quoteId = ApexPages.currentPage().getParameters().get('quoteId');
    String showPayments = ApexPages.currentPage().getParameters().get('show_payments');
    displayPayments = showPayments == null ? false : Boolean.valueOf(showPayments);
    qt = [SELECT Id,
                 OpportunityId,
                 Deposit__c,
                 Name,
                 QuoteNumber,
                 TotalPrice,
                 Total_Amount__c,
                 Grand_Total__c,
                 Tax_Amount_Federal__c,
                 Tax_Amount_Provincial__c,
                 Tax_Rate_Federal__c,
                 Tax_Rate_Provincial__c,
                 Total_Before_Tax__c,
                 Tax_Amount_Total__c,
                 Monthly_Payment__c,
                 Bi_Weekly_Payment__c,
                 Weekly_Payment__c,
                 ExpirationDate,
                 TradeInAmount__c,
                 TradeInLien__c,
                 TradeInValue__c
          FROM Quote
          WHERE Id = :quoteId];
    oppId = qt.OpportunityId;
    init();
  }

  public Opportunity_PartnerQuote_Ext(ApexPages.StandardController stdController)
  {
    oppId = stdController.getId();
    init();
  }

  public void init()
  {
    this.deposit = qt.Deposit__c;
    this.expireDate = qt.ExpirationDate;
    this.opp = [SELECT Id,
                       Amount,
                       //Trade_In_Amount__c,
                       Deposit__c,
                       AccountId,
                       Customer_Notes__c,
                       Name,
                       OwnerId,
                       Owner.FirstName,
                       Owner.LastName,
                       Amount_Financed__c,
                       Invoice_Number_BarCode__c,
                       InvoiceNumber__c,
                       ContactEmail__c,
                       Boat_Model_Year__c,
                       Trailer_Model_Year__c,
                 ( SELECT Id,
                          IsPrimary,
                          Role,
                          Contact.Name,
                          Contact.Email,
                          Contact.Phone,
                          Contact.Birthdate,
                          Contact.Drivers_License__c,
                          Contact.Tax_Exempt_Status_Card_Number__c,
                          Contact.MailingStreet,
                          Contact.MailingCity,
                          Contact.MailingState,
                          Contact.MailingPostalCode,
                          Contact.MailingCountry
                  FROM OpportunityContactRoles )
                FROM Opportunity
                WHERE Id = :oppId ];
    setBuyers();
    this.partner = findPartner();
    this.customer = findCustomer();
    this.isForCustomer = customer.isPersonAccount;
    this.theCPQ = new CPQ('retail', qt.Id);
    this.theCPQ.selectBoat();
    this.theCPQ.theMotor = setUpgrade( this.theCPQ.theBoat.standardMotorId,
                                       this.theCPQ.motorId );
    this.theCPQ.theTrailer = setUpgrade( this.theCPQ.theBoat.standardTrailerId,
                                         this.theCPQ.trailerId );
    this.theCPQ.theTrollingMotor = setUpgrade( this.theCPQ.theBoat.standardTrollingMotorId,
                                               this.theCPQ.trollingMotorId );
    groupFees();
    setupTradeInInfo();
    calcSavings();
  }

  private void setBuyers()
  {
    for( OpportunityContactRole ocr : opp.OpportunityContactRoles )
    {
      switch on ocr.Role {
        when 'Buyer' {
          this.buyer = ocr.Contact;
        }
        when 'Co-Buyer' {
          this.cobuyer = ocr.Contact;
        }
      }
    }
  }

  private Account findPartner()
  {
    User u = [SELECT Id, AccountId FROM User WHERE Id = :opp.OwnerId];
    if( u.AccountId != null )
    {
      return [SELECT Id,
                     Name,
                     Phone,
                     Fax,
                     WebSite,
                     AccountEmail__c,
                     BillingStreet,
                     BillingCity,
                     BillingState,
                     BillingCountry,
                     BillingPostalCode,
                     Company_Logo__c
              FROM Account
              WHERE Id = :u.AccountId ];
    }
    return null;
  }

  private Account findCustomer()
  {
    return [SELECT Id,
                   Name,
                   Phone,
                   FirstName,
                   LastName,
                   AccountEmail__c,
                   PersonBirthdate,
                   Drivers_License__c,
                   Tax_Exempt_Status_Card_Number__pc,
                   BillingStreet,
                   BillingCity,
                   BillingState,
                   BillingCountry,
                   BillingPostalCode,
                   IsPersonAccount
            FROM Account
            WHERE Id = :this.opp.AccountId ];
  }

  private CPQ_Lib_dh.UpgradeProduct setUpgrade( String fromId, String toId )
  {
    if( toId == null )
      return null;

      return CPQ.setUpgrade( fromId,
                             toId,
                             String.valueOf( this.theCPQ.activePricebookId ),
                             this.theCPQ.saleProvince );
  }

  private void groupFees()
  {
    this.allFees = new List<CPQ_Lib_dh.Fee>();
    if( theCPQ.theBoat != null )
    {
      this.allFees.addAll( theCPQ.theBoat.fees );
    }
    if( theCPQ.theMotor != null )
    {
      this.allFees.addAll( theCPQ.theMotor.fees );
    }
    if( theCPQ.theTrailer != null )
    {
      this.allFees.addAll( theCPQ.theTrailer.fees );
    }
    if( theCPQ.theTrollingMotor != null )
    {
      this.allFees.addAll( theCPQ.theTrollingMotor.fees );
    }
  }

  private void setupTradeInInfo()
  {
    try {
      Trade_In_Record__c tir = [SELECT Id, Lien_Amount__c, Total_Value__c,
                                ( SELECT Id, Make__c, Model__c, Model_Year__c, Serial_Number__c
                                  FROM Trade_In_Items__r )
                                FROM Trade_In_Record__c
                                WHERE Quote__c = :quoteId ];
      this.tradeIn = new CPQ_Lib_dh.TradeIn( tir );
    }
    catch( Exception e )
    {
      this.tradeIn = new CPQ_Lib_dh.TradeIn();
    }
  }

  private void calcSavings()
  {
    this.totalSavings = 0;
    for( CPQ_Lib_dh.SavingsLine sl : theCPQ.savings )
    {
      this.totalSavings += sl.amount;
    }
  }

}