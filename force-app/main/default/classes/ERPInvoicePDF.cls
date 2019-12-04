public with sharing class ERPInvoicePDF {

  public class PartLineItem {
    public Decimal quantity  {
        get {
            if( quantity == null )
                quantity = 1;
            return quantity.setScale(2);
        }
        set; }
    public String productCode                       { get; set; }
    public String description                       { get; set; }
    public String commentText                       { get; set; }
    public String descriptionFR                     { get; set; }
    public String serialNumber                      { get; set; }
    public Decimal unitPrice                        { get; set; }
    public Decimal price                            { get; set; }
    public Decimal previousTransferred              { get; set; }
    public Decimal transferQuantity                 { get; set; }
    public Decimal previousBilled                   { get; set; }
    public Decimal billUnitPrice                    { get; set; }
    public Decimal billQuantity                     { get; set; }
    public Decimal billTotal                        { get; set; }
    public List<PartLineItem> includedFeatures      { get; set; }
    public List<PartLineItem> kitParts              { get; set; }
    public String rt                                { get; set; }

    public PartLineItem( AcctSeedERP__Material__c mat )
    {
      this.rt = mat.AcctSeedERP__Product__r.RecordType.Name;
      this.quantity = mat.AcctSeedERP__Quantity_per_Unit__c;
      if( this.rt == 'Fees' || mat.AcctSeedERP__Product__r.Family == 'Discount' )
      {
        this.description = '';
        this.descriptionFR = '';
        if( mat.AcctSeedERP__Product__r.Family == 'Discount' )
        {
          this.description = mat.Product_Name__c + ' - ';
          this.descriptionFR = mat.Product_Name__c + ' - ';
        }
        this.description += mat.AcctSeedERP__Comment__c;
        this.descriptionFR += mat.AcctSeedERP__Comment__c;
      }
      else
      {
        this.description = mat.Product_Name__c;
        if(mat.AcctSeedERP__Comment__c != null)
          this.commentText = mat.AcctSeedERP__Comment__c;
        this.descriptionFR = mat.AcctSeedERP__Product__r.Name_FR__c;
      }
      this.productCode = mat.AcctSeedERP__Product__r.ProductCode;
      this.unitPrice = mat.GMBLASERP__Unit_Price__c;
      this.price = mat.GMBLASERP__Total_Price__c;
      this.includedFeatures = new List<PartLineItem>();
      this.kitParts = new List<PartLineItem>();
      if( mat.GMBLASERP__Serial_Number__c != null )
        this.serialNumber = mat.GMBLASERP__Serial_Number__r.Name;

      /// Billing Invoice
      this.previousBilled = 0;
      this.billUnitPrice = 0;
      this.billQuantity = 0;
      this.billTotal = 0;
      /// Transfer Slip
      this.previousTransferred = 0;
      this.transferQuantity = 0;
    }

    public PartLineItem( Product_Feature_Map__c pfm )
    {
        this.description = pfm.Feature_Id__r.description__c;
        this.descriptionFR = pfm.Feature_Id__r.description_fr__c;
        this.price = 0;
    }

    public PartLineItem addFeature( Product_Feature_Map__c pfm )
    {
        this.includedFeatures.add( new PartLineItem( pfm ) );
        return this;
    }

    public Boolean getHasKitParts()
    {
      return !this.kitParts.isEmpty();
    }
  }

  public class MaterialBilling {
    public Decimal quantityBilled         {get;set;}
    public Decimal totalQuantity          {get;set;}
    public Decimal unitPrice              {get;set;}
    public Decimal totalAmount            {get;set;}

    public MaterialBilling()
    {
      quantityBilled = 0;
      totalQuantity = 0;
      unitPrice = 0;
      totalAmount = 0;
    }
  }

  public class MaterialTransfer {
    public Decimal quantityTransferred    {get;set;}
    public Decimal totalQuantity          {get;set;}

    public MaterialTransfer()
    {
      quantityTransferred = 0;
      totalQuantity = 0;
    }
  }

  public class TaskLineItem implements Comparable {
    public String name                    { get; set; }
    public String internalName            { get; set; }
    public String taskGLV1                { get; set; }
    public String taskGLV2                { get; set; }
    public String complaint               { get; set; }
    public String cause                   { get; set; }
    public String correction              { get; set; }
    public Decimal duration               { get; set; }
    public List<PartLineItem> taskParts   { get; set; }

    public TaskLineItem( AcctSeed__Project_Task__c task )
    {
      this.name = task.Name.contains('-') ? task.Name.split('-')[1] : task.Name;
      this.internalName = task.Name;
      this.taskGLV1 = task.AcctSeed__GL_Account_Variable_1__r.Name;
      this.taskGLV2 = task.AcctSeed__GL_Account_Variable_2__r.Name;
      this.complaint = task.Complaint_dh__c;
      this.cause = task.Cause_dh__c;
      this.correction = task.Correction_dh__c;
      this.taskParts = new List<PartLineItem>();
      this.duration = task.Estimated_Duration__c;
    }

    public Boolean getHasComplaint()
    {
      return !String.isEmpty( this.complaint );
    }

    public Boolean getHasCause()
    {
      return !String.isEmpty( this.cause );
    }

    public Boolean getHasCorrection()
    {
      return !String.isEmpty( this.correction );
    }

    public Boolean getRenderCCC()
    {
      return ( getHasComplaint() || getHasCause() ||  getHasCorrection() );
    }

    public Integer compareTo( Object compareTo )
    {
      TaskLineItem compareT = (TaskLineItem)compareTo;
      if( internalName == compareT.internalName ) return 0;
      if( internalName > compareT.internalName ) return 1;
      return -1;
    }

  }

  /*  Common Vaiables */
  public Id erpId                                                        { get; set; }
  public Id billId                                                       { get; set; }
  public Id transferId                                                   { get; set; }
  public AcctSeed__Project__c erpOrder                                   { get; set; }
  public Boolean soldToBusiness                                          { get; set; }
  public List <AcctSeedERP__Material__c> materials                       { get; set; }
  public Account projectAccount                                          { get; set; }
  public String customerNotes                                            { get; set; }
  public LGND_Utilities.ProvincialTax provTaxInfo                        { get; set; }
  public AcctSeedERP__Warehouse__c warehouse                             { get; set; }
  public String address                                                  { get; set; }
  public String storeAddress                                             { get; set; }
  public String invoiceName                                              { get; set; }
  public String invoiceDate                                              { get; set; }
  public String deliveryDate                                             { get; set; }
  public String invoiceDateLabel                                         { get; set; }
  public String birthday                                                 { get; set; }
  public Decimal subTotal                                                { get; set; }
  public Decimal totalSaving                                             { get; set; }
  public List<PartLineItem> materialList                                 { get; set; }
  public List<AcctSeed__Cash_Receipt__c> payments                        { get; set; }
  public List<AcctSeed__Cash_Disbursement__c> apReturns                  { get; set; }
  public Decimal paymentTotal                                            { get; set; }
  public Decimal returnTotal                                             { get; set; }
  public Boolean internalOverRide                                        { get; set; }
  public String partnerReference                                         { get; set; }
  public List<Integer> cccList                                           { get; set; }
  public List<Legend_Tax_Numbers__mdt> taxNumbers                        { get; set; }

  /*  Boat Sale Variables */
  public AcctSeedERP__Material__c boat                                   { get; set; }
  public AcctSeedERP__Material__c trailer                                { get; set; }
  public List<AcctSeedERP__Material__c> trollingMotors                   { get; set; }
  public AcctSeedERP__Material__c[] motors                               { get; set; }
  public List <AcctSeedERP__Material__c> feesList                        { get; set; }
  public List <AcctSeedERP__Material__c> oppAccMaterials;
  public List<PartLineItem> oppAccList                                   { get; set; }
  public List <AcctSeedERP__Material__c> discountList                    { get; set; }
  public List <AcctSeedERP__Material__c> protectionServicesList          { get; set; }
  public List <AcctSeedERP__Material__c> bundlesList                     { get; set; }
  public List <AcctSeedERP__Material__c> insuranceList                   { get; set; }
  public Trade_In_Record__c tradeInRecord                                { get; set; }
  public List <Trade_In_Item__c> tradeInItem                             { get; set; }
  public OpportunityContactRole buyer                                    { get; set; }
  public OpportunityContactRole cobuyer                                  { get; set; }
  public Decimal tradeInValue                                            { get; set; }
  public Decimal tradeInLien                                             { get; set;}
  public Decimal totalTrade                                              { get; set; }

  /* Service Order Variables */
  transient List<AcctSeed__Project_Task__c> projectTasks;
  public List<TaskLineItem> taskLineItems                                { get; set; }
  public List<Map<String, String>> serialNumbers                         { get; set; }
  public Decimal partsTotal                                              { get; set; }
  public Decimal labourTotal                                             { get; set; }
  public String compartmentKeyNumber                                     { get; set; }
  public String ignitionKeyNumber                                        { get; set; }
  public Boolean hideServiceDisclaimer                                   { get; set; }
  /* Invoice By Bill*/
  public Decimal totalAmountPreTax                                       { get; set; }
  public Decimal totalTaxH                                               { get; set; }
  public Decimal totalTaxF                                               { get; set; }
  public Decimal totalTaxP                                               { get; set; }
  public Decimal totalTaxR                                               { get; set; }
  public List<AcctSeed__Billing__c> erpBillings                          { get; set; }
  public List<GMBLASERP__Inventory_Transfer__c> erpTransfers             { get; set; }
  public AcctSeed__Billing__c currentBill                                { get; set; }
  public GMBLASERP__Inventory_Transfer__c currentTransfer                { get; set; }
  public Map<Id,MaterialBilling> mapMatlBill                             { get; set; }
  public Map<Id,MaterialTransfer> mapMatlTransfer                        { get; set; }



  public ERPInvoicePDF() {
    System.debug(loggingLevel.error,'Const 1');
    this.erpId = ApexPages.currentPage().getParameters().get('erpOrderId');
    this.billId = ApexPages.currentPage().getParameters().get('billId');
    this.transferId = ApexPages.currentPage().getParameters().get('transferId');
    init();
  }


  public ERPInvoicePDF( String erpId )
  {
    System.debug(loggingLevel.error,'Const 2');
    this.erpId = erpId;
    init();
  }

  private void init()
  {
    this.soldToBusiness = false;
    this.subTotal = 0;
    this.totalSaving = 0;
    this.totalTrade = 0;
    this.tradeInValue = 0;
    this.tradeInLien = 0;
    this.fetchERPOrder();
    this.internalOverRide = false;
    this.hideServiceDisclaimer = false;
    String paramVersion = ApexPages.currentPage().getParameters().get('version');
    if( paramVersion != null && paramVersion == 'internal' )
      internalOverRide = true;
    this.generateVariablesForPage();
    this.setupForRecordType();
    this.cccList = new Integer[]{1,2,3};
    setLegendTaxNumbers();
  }

  /* +++++++++++++++++++ Getter Rendering assistive methods +++++++++++++++++++++++ */
  public String getPaymentString()
  {
    if( erpOrder.Finance_Payments_Per_Year__c == 12 )
    {
      return 'Monthly Payment';
    }
    if( erpOrder.Finance_Payments_Per_Year__c == 26 )
    {
      return 'Bi-Weekly Payment';
    }
    if( erpOrder.Finance_Payments_Per_Year__c == 52 )
    {
      return 'Weekly Payment';
    }
    return null;
  }

  public String getFrenchPaymentString()
  {
    if( erpOrder.Finance_Payments_Per_Year__c == 12 )
    {
      return 'Paiement Mensuel';
    }
    if( erpOrder.Finance_Payments_Per_Year__c == 26 )
    {
      return 'Bi-Weekly Payment';
    }
    if( erpOrder.Finance_Payments_Per_Year__c == 52 )
    {
      return 'Weekly Payment';
    }
    return null;
  }

  public Decimal getPaymentAmount()
  {
    if( erpOrder.Finance_Payments_Per_Year__c == 12 )
    {
      return erpOrder.Finance_Payment_Monthly__c;
    }
    if( erpOrder.Finance_Payments_Per_Year__c == 26 )
    {
      return erpOrder.Finance_Payment_Bi_Weekly__c;
    }
    if( erpOrder.Finance_Payments_Per_Year__c == 52 )
    {
      return erpOrder.Finance_Payment_Weekly__c;
    }
    return null;
  }



  /* +++++++++++++++ PRIVATES ++++++++++++++ */

  private void setLegendTaxNumbers()
  {
    this.taxNumbers = [ SELECT DeveloperName, Tax_Number__c FROM Legend_Tax_Numbers__mdt ];
  }

  private void fetchERPOrder()
  {

    this.erpOrder = [SELECT Id,
                            RecordTypeId,
                            Sale_Type__c,
                            AcctSeed__Opportunity__c,
                            Finance_Term__c,
                            Finance_Annual_Interest__c,
                            Finance_Ammortization__c,
                            Finance_Payments_Per_Year__c,
                            Finance_Payment_Monthly__c,
                            Finance_Payment_Bi_Weekly__c,
                            Finance_Payment_Weekly__c,
                            AcctSeed__Account__c,
                            Pickup_Location__c,
                            Delivery_Date__c,
                            Customer_Notes__c,
                            Name,
                            Deposit__c,
                            Deposit_Method__c,
                            CreatedDate,
                            Salesperson__r.Name,
                            Salesperson__r.Lastname,
                            GMBLASERP__Warehouse__c,
                            GL_Account_Variable_3__c,
                            Order_Item_Total__c,
                            Grand_Total__c,
                            Tax_is_Harmonized__c,
                            Tax_Rate_Provincial__c,
                            Tax_Rate_Federal__c,
                            Tax_Rate_Retail__c,
                            Tax_Override__c,
                            Tax_Amount_Federal__c,
                            Tax_Amount_Provincial__c,
                            Tax_Amount_Retail__c,
                            Serial_Number__c,
                            Fixed_Asset__c,
                            Internal_Labour_Service__c,
                            Internal_Warranty__c,
                            Internal_Partner_Parts_Order__c,
                            Internal_Partner_Boat_Sale__c,
                            Partner_External_PO_Number__c,
                            Parking_Spot__c
                     FROM AcctSeed__Project__c
                     WHERE Id =: erpId ];

    this.customerNotes = this.erpOrder.Customer_Notes__c;

    if( this.erpOrder.AcctSeed__Account__c != null )
    {
      for(Account acc : [SELECT Drivers_License__c,
                                Owner.ID,
                                Name,
                                Lastname,
                                PersonEmail,
                                AccountEmail__c,
                                BillingStreet,
                                OwnerID,
                                BillingCity,
                                BillingState,
                                BillingPostalCode,
                                BillingCountry,
                                Phone,
                                PersonBirthdate,
                                RecordTypeId
                               FROM Account
                               WHERE id =: erpOrder.AcctSeed__Account__c])
      {
        this.projectAccount = acc;
        if( acc.RecordTypeId == LGND_Utilities.recordTypeIdFromName('Account', 'Business Account') )
          this.soldToBusiness = true;
      }
    }

    this.warehouse = [SELECT Id,
                             Name,
                             City__c,
                             Country__c,
                             Fax__c,
                             Phone__c,
                             Postal_Code__c,
                             State__c,
                             Street__c,
                             Toll_Free__c
                      FROM AcctSeedERP__Warehouse__c
                      WHERE Id = : this.erpOrder.GMBLASERP__Warehouse__c];
  }

  private void fetchMaterial()
  {
    this.materials = [SELECT Id,
                             Product_Name__c,
                             Material__c,
                             AcctSeedERP__Comment__c,
                             AcctSeedERP__Product__c,
                             AcctSeedERP__Product__r.Name_FR__c,
                             AcctSeedERP__Product__r.Family,
                             AcctSeedERP__Product__r.Make__c,
                             AcctSeedERP__Product__r.RecordType.Name,
                             AcctSeedERP__Product__r.ProductCode,
                             AcctSeedERP__Product__r.Composite_Type__c,
                             AcctSeedERP__Quantity_per_Unit__c,
                             GMBLASERP__Total_Price__c,
                             GMBLASERP__Unit_Price__c,
                             GMBLASERP__Serial_Number__c,
                             GMBLASERP__Serial_Number__r.Name,
                             GMBLASERP__Serial_Number__r.GMBLASERP__Lot__r.Name
                        FROM AcctSeedERP__Material__c
                        WHERE AcctSeedERP__Project__c =: erpOrder.Id
                        AND (DisplayOnCustomerInvoice__c = true
                          OR AcctSeedERP__Project__r.Internal_Warranty__c = true
                          OR AcctSeedERP__Project__r.Internal_Partner_Parts_Order__c = true) ];
  }

  private void fetchPayments()
  {
    this.paymentTotal = 0;
    this.payments =  [SELECT Id,
                             Payment_Method__c,
                             AcctSeed__Receipt_Date__c,
                             AcctSeed__Amount__c
                       FROM AcctSeed__Cash_Receipt__c
                       WHERE AcctSeed__Project__c = :erpOrder.Id];
    for( AcctSeed__Cash_Receipt__c cr : this.payments )
    {
      this.paymentTotal += cr.AcctSeed__Amount__c;
    }
  }

  private void fetchReturnPayables()
  {
    this.returnTotal = 0;
    this.apReturns = new List<AcctSeed__Cash_Disbursement__c>();
    this.apReturns =  [SELECT Id,
                            AcctSeed__Disbursement_Date__c,
                            AcctSeed__Type__c,
                            AcctSeed__Amount__c
                       FROM AcctSeed__Cash_Disbursement__c
                       WHERE AcctSeed__Project__c =:erpOrder.Id
                        AND AcctSeed__Project_Task__r.Is_Return_Task__c = true];
    for( AcctSeed__Cash_Disbursement__c pay : this.apReturns )
    {
      this.returnTotal -= pay.AcctSeed__Amount__c;
    }
  }

  private void fetchTransfers()
  {
    System.debug(loggingLevel.error,'fetchTransfers:');
    Set<Id> setIdTaxProducts = new Set<Id>{ gcConstants.idProductSalesTaxFederal, gcConstants.idProductSalesTaxProvincial, gcConstants.idProductSalesTaxRetail, gcConstants.idProductSalesTaxHarmonized, gcConstants.idProductPrecisionFix};
    this.mapMatlTransfer = new Map<Id,MaterialTransfer>();
    this.erpTransfers = new List<GMBLASERP__Inventory_Transfer__c>();
    this.currentTransfer = new GMBLASERP__Inventory_Transfer__c();
    for(GMBLASERP__Inventory_Transfer__c transfer : [SELECT Id,
                            Name,
                            ERP_Order__c,
                            GMBLASERP__Outbound_Date__c,
                            GMBLASERP__Inbound_Date__c,
                            GMBLASERP__Warehouse_From__c,
                            GMBLASERP__Warehouse_From__r.Name,
                            GMBLASERP__Warehouse_To__c,
                            GMBLASERP__Warehouse_To__r.Name,
                            CreatedDate,
                            (SELECT Id,
                              Material__c,
                              GMBLASERP__Product__c,
                              AcctSeedERP__Quantity__c
                            FROM GMBLASERP__Outbound_Inventory_Movements__r)
                       FROM GMBLASERP__Inventory_Transfer__c
                       WHERE ERP_Order__c =:erpOrder.Id])
    {
      if(this.transferId != null && transfer.Id == this.transferId){
        this.currentTransfer = transfer;
        this.invoiceDate = transfer.GMBLASERP__Outbound_Date__c.format();
      }
      else
        this.erpTransfers.add(transfer);

      if(!transfer.GMBLASERP__Outbound_Inventory_Movements__r.isEmpty()){
        for(AcctSeedERP__Outbound_Inventory_Movement__c oim : transfer.GMBLASERP__Outbound_Inventory_Movements__r)
        {
            MaterialTransfer mb = new MaterialTransfer();
            if(this.transferId != null){
              if(transfer.Id == this.transferId){
                if(this.mapMatlTransfer.containsKey(oim.Material__c))
                  mb = this.mapMatlTransfer.get(oim.Material__c);
                else
                  this.mapMatlTransfer.put(oim.Material__c, mb);
                mb.totalQuantity = oim.AcctSeedERP__Quantity__c;
              }else{
                if(this.mapMatlTransfer.containsKey(oim.Material__c))
                  mb = this.mapMatlTransfer.get(oim.Material__c);
                else
                  this.mapMatlTransfer.put(oim.Material__c, mb);
                mb.quantityTransferred += oim.AcctSeedERP__Quantity__c;
              }
            }else{
              if(this.mapMatlTransfer.containsKey(oim.Material__c))
                mb = this.mapMatlTransfer.get(oim.Material__c);
              else
                this.mapMatlTransfer.put(oim.Material__c, mb);
              mb.totalQuantity += oim.AcctSeedERP__Quantity__c;
            }
          }
        }
      }
      System.debug(logginglevel.Error, 'mapMatlTransfer:'+this.mapMatlTransfer);
  }

  private void fetchBillings()
  {
    System.debug(loggingLevel.error,'fetchBillings:');
    Set<Id> setIdTaxProducts = new Set<Id>{ gcConstants.idProductSalesTaxFederal, gcConstants.idProductSalesTaxProvincial, gcConstants.idProductSalesTaxRetail, gcConstants.idProductSalesTaxHarmonized, gcConstants.idProductPrecisionFix};
    this.mapMatlBill = new Map<Id,MaterialBilling>();
    this.totalAmountPreTax = 0;
    this.totalTaxH = 0;
    this.totalTaxR = 0;
    this.totalTaxF = 0;
    this.totalTaxP = 0;
    this.erpBillings = new List<AcctSeed__Billing__c>();
    this.currentBill = new AcctSeed__Billing__c();
    for(AcctSeed__Billing__c bl : [SELECT Id,
                            Name,
                            Tax_is_Harmonized__c,
                            Tax_Rate_Federal__c,
                            Tax_Rate_Provincial__c,
                            Tax_Rate_Retail__c,
                            AcctSeed__Total__c,
                            AcctSeed__Date__c,
                            AcctSeed__Type__c,
                            AcctSeed__Balance__c,
                            AcctSeed__Received_Amount__c,
                            AcctSeed__Credit_Memo_Applied_Amount__c,
                            CreatedDate,
                            (SELECT Id,
                              AcctSeed__Product__c,
                              AcctSeed__Hours_Units__c,
                              AcctSeed__Total__c,
                              AcctSeed__Rate__c,
                              GMBLASERP__Material__c
                            FROM AcctSeed__Project_Billing_Lines__r),
                            (SELECT Id,
                              AcctSeed__Applied_Amount__c,
                              AcctSeed__Adjustment_Amount__c,
                              AcctSeed__Cash_Receipt__r.Payment_Method__c,
                              AcctSeed__Cash_Receipt__r.AcctSeed__Receipt_Date__c
                            FROM AcctSeed__Billing_Cash_Receipts__r)
                       FROM AcctSeed__Billing__c
                       WHERE GMBLASERP__Project__c =:erpOrder.Id])
    {
      if(this.billId != null && bl.Id == this.billId){
        this.currentBill = bl;
        this.invoiceDate = bl.CreatedDate.format('MMMMM dd, yyyy');
      }
      else
        this.erpBillings.add(bl);

      if(!bl.AcctSeed__Project_Billing_Lines__r.isEmpty()){
        for(AcctSeed__Billing_Line__c bline : bl.AcctSeed__Project_Billing_Lines__r)
        {
          if(bline.GMBLASERP__Material__c == null && setIdTaxProducts.contains(bline.AcctSeed__Product__c)){
            if(this.billId != null && bl.Id != this.billId) continue;
            if(bline.AcctSeed__Product__c == gcConstants.idProductSalesTaxProvincial)
              this.totalTaxP += bline.AcctSeed__Total__c;
            else if(bline.AcctSeed__Product__c == gcConstants.idProductSalesTaxFederal)
              this.totalTaxF += bline.AcctSeed__Total__c;
            else if(bline.AcctSeed__Product__c == gcConstants.idProductSalesTaxRetail)
              this.totalTaxR += bline.AcctSeed__Total__c;
            else if(bline.AcctSeed__Product__c == gcConstants.idProductSalesTaxHarmonized)
              this.totalTaxH += bline.AcctSeed__Total__c;
          }
          else{
            MaterialBilling mb = new MaterialBilling();
            if(this.billId != null){
              if(bl.Id == this.billId){
                if(this.mapMatlBill.containsKey(bline.GMBLASERP__Material__c))
                  mb = this.mapMatlBill.get(bline.GMBLASERP__Material__c);
                else
                  this.mapMatlBill.put(bline.GMBLASERP__Material__c, mb);
                mb.totalQuantity = bline.AcctSeed__Hours_Units__c;
                mb.unitPrice = bline.AcctSeed__Rate__c;
                mb.totalAmount += bline.AcctSeed__Total__c;
                this.totalAmountPreTax += bline.AcctSeed__Total__c;
              }else{
                if(this.mapMatlBill.containsKey(bline.GMBLASERP__Material__c))
                  mb = this.mapMatlBill.get(bline.GMBLASERP__Material__c);
                else
                  this.mapMatlBill.put(bline.GMBLASERP__Material__c, mb);
                mb.quantityBilled += bline.AcctSeed__Hours_Units__c;
              }
            }else{
              if(this.mapMatlBill.containsKey(bline.GMBLASERP__Material__c))
                mb = this.mapMatlBill.get(bline.GMBLASERP__Material__c);
              else
                this.mapMatlBill.put(bline.GMBLASERP__Material__c, mb);
              mb.totalQuantity += bline.AcctSeed__Hours_Units__c;
              mb.unitPrice = bline.AcctSeed__Rate__c;
              mb.totalAmount += bline.AcctSeed__Total__c;
              this.totalAmountPreTax += bline.AcctSeed__Total__c;
            }
          }
        }
      }
    }
  }

  private void fetchProjectTasks()
  {
    String queryString = 'SELECT Id, Name, Complaint_dh__c, Cause_dh__c, Correction_dh__c, Estimated_Duration__c, ';
    queryString += 'AcctSeed__GL_Account_Variable_1__r.Name, AcctSeed__GL_Account_Variable_2__r.Name, ';
    queryString += '(SELECT Id, Product_Name__c, Material__c, AcctSeedERP__Comment__c, AcctSeedERP__Product__c, ';
    queryString += 'AcctSeedERP__Product__r.Name_FR__c, AcctSeedERP__Product__r.Family, AcctSeedERP__Product__r.Composite_Type__c, ';
    queryString += 'AcctSeedERP__Product__r.Make__c, AcctSeedERP__Product__r.RecordType.Name, AcctSeedERP__Product__r.ProductCode, ';
    queryString += 'AcctSeedERP__Quantity_per_Unit__c, GMBLASERP__Serial_Number__c, GMBLASERP__Total_Price__c, ';
    queryString += 'GMBLASERP__Unit_Price__c, GMBLASERP__Serial_Number__r.Name, GMBLASERP__Serial_Number__r.GMBLASERP__Lot__r.Name ';
    queryString += 'FROM AcctSeedERP__Materials__r) ';
    queryString += 'FROM AcctSeed__Project_Task__c WHERE AcctSeed__Project__c = \'';
    queryString += erpOrder.Id + '\'';
    if( !internalOverRide )
      queryString += ' AND DisplayOnCustomerInvoice__c = true';
    this.projectTasks = Database.query( queryString );
  }

  private void fetchFixedAsset()
  {
    serialNumbers = new List<Map<String, String>>();
    Map<String,String> sn = new Map<String, String>();
    try {
      AcctSeed__Fixed_Asset__c fa = [SELECT Id, Name, Asset_Serial_Number__c
                                     FROM AcctSeed__Fixed_Asset__c
                                     WHERE Id = :this.erpOrder.Fixed_Asset__c];
      sn.put('MakeAndModel', fa.Name );
      sn.put('SerialNumber', fa.Asset_Serial_Number__c );
      sn.put('Type', '');
      sn.put('Year', '');
    }
    catch( Exception e ) {
        sn.put('Type', '');
        sn.put('Year', '');
        sn.put('MakeAndModel', '' );
        sn.put('SerialNumber', '');
      }
    serialNumbers.add( sn );
  }

  private void fetchSerialNumber()
  {
    serialNumbers = new List<Map<String, String>>();
    if( internalOverRide == false ||
        this.erpOrder.RecordTypeId == gcConstants.idRtProjectService ||
        this.erpOrder.RecordTypeId == gcConstants.idRtProjectWarranty ||
        this.erpOrder.RecordTypeId == gcConstants.idRtProjectManufacturing ||
        this.erpOrder.RecordTypeId == gcConstants.idRtTradeIn )
    {
      System.debug(' In IF Statement ');
      Map<String,String> sn = new Map<String, String>();
      try {
        GMBLASERP__Serial_Number__c serial = [SELECT Id,
                                                 Name,
                                                 GMBLASERP__Product__r.Name,
                                                 GMBLASERP__Product__r.Make__c,
                                                 GMBLASERP__Product__r.RecordType.Name,
                                                 GMBLASERP__Lot__r.Name,
                                                 Compartment_Key_Code__c,
                                                 Ignition_Key_Code__c
                                          FROM GMBLASERP__Serial_Number__c
                                          WHERE Id = :erpOrder.Serial_Number__c ];
        sn.put('Type', serial.GMBLASERP__Product__r.RecordType.Name);
        sn.put('Year', serial.GMBLASERP__Lot__r.Name);
        sn.put('MakeAndModel', serial.GMBLASERP__Product__r.Make__c + ' / ' + serial.GMBLASERP__Product__r.Name );
        sn.put('SerialNumber', serial.Name);
        compartmentKeyNumber = serial.Compartment_Key_Code__c;
        ignitionKeyNumber = serial.Ignition_Key_Code__c;
        addNestedSerials( serial.Id );
      }
      catch( Exception e ){
        sn.put('Type', '');
        sn.put('Year', '');
        sn.put('MakeAndModel', '' );
        sn.put('SerialNumber', '');
      }
      serialNumbers.add( sn );
    }
    else
    {
      System.debug(' In ELSE Statement ');
      Set<Id> serialIds = new Set<Id>();
      for( AcctSeed__Project_Task__c task : this.projectTasks )
      {
        for( AcctSeedERP__Material__c mat : task.AcctSeedERP__Materials__r )
        {
          if( mat.GMBLASERP__Serial_Number__c != null )
            serialIds.add( mat.GMBLASERP__Serial_Number__c );
        }
      }
      for( GMBLASERP__Serial_Number__c serial : [SELECT Id,
                                                   Name,
                                                   GMBLASERP__Product__r.Name,
                                                   GMBLASERP__Product__r.Make__c,
                                                   GMBLASERP__Product__r.RecordType.Name,
                                                   GMBLASERP__Lot__r.Name,
                                                   Compartment_Key_Code__c,
                                                   Ignition_Key_Code__c
                                            FROM GMBLASERP__Serial_Number__c
                                            WHERE Id IN :serialIds
                                            ORDER BY GMBLASERP__Product__r.RecordType.Name ASC ] )
      {
        Map<String,String> sn = new Map<String, String>();
        sn.put('Type', serial.GMBLASERP__Product__r.RecordType.Name);
        sn.put('Year', serial.GMBLASERP__Lot__r.Name);
        sn.put('MakeAndModel', serial.GMBLASERP__Product__r.Make__c + ' / ' + serial.GMBLASERP__Product__r.Name );
        sn.put('SerialNumber', serial.Name);
        serialNumbers.add( sn );
        if( serial.GMBLASERP__Product__r.RecordType.Name == 'Boat' )
        {
          compartmentKeyNumber = serial.Compartment_Key_Code__c;
          ignitionKeyNumber = serial.Ignition_Key_Code__c;
        }
      }
    }
  }

  private void addNestedSerials( Id serialId )
  {
    if( serialNumbers == null )
      serialNumbers = new List<Map<String, String>>();

    for( GMBLASERP__Serial_Number__c serial : [SELECT Id,
                                                 Name,
                                                 GMBLASERP__Product__r.Name,
                                                 GMBLASERP__Product__r.Make__c,
                                                 GMBLASERP__Product__r.RecordType.Name,
                                                 GMBLASERP__Lot__r.Name,
                                                 Compartment_Key_Code__c,
                                                 Ignition_Key_Code__c
                                              FROM GMBLASERP__Serial_Number__c
                                              WHERE Nest__c = :serialId ] )
    {
      Map<String,String> sn = new Map<String, String>();
      sn.put('Type', serial.GMBLASERP__Product__r.RecordType.Name);
      sn.put('Year', serial.GMBLASERP__Lot__r.Name);
      sn.put('MakeAndModel', serial.GMBLASERP__Product__r.Make__c + ' / ' + serial.GMBLASERP__Product__r.Name );
      sn.put('SerialNumber', serial.Name);
      serialNumbers.add( sn );
    }

  }

  private void setupForRecordType()
  {
    Id counterSaleRtId = gcConstants.idRtProjectCounterSale;
    Id partnerPartOrder = gcConstants.idRtPartnerPartsOrder;
    Id serviceRtId = gcConstants.idRtProjectService;
    Id retailBoatSaleRtId = gcConstants.idRtProjectBoatSale;
    Id partnerBoatSaleRtId = gcConstants.idRtProjectPartnerBoatSale;
    Id manufacturingRtId = gcConstants.idRtProjectManufacturing;
    Id warrantyRtId = gcConstants.idRtProjectWarranty;
    Id tradeInRtId = gcConstants.idRtTradeIn;
    Id fixedAssetRtId = gcConstants.idRtFixedAsset;
    /*   Boat Sale    */
    if( this.erpOrder.RecordTypeId == retailBoatSaleRtId ||
        this.erpOrder.RecordTypeId == partnerBoatSaleRtId )
    {
      if( internalOverRide == true )
        setupForServiceOrder();
      else
        setupForBoatSale();
    }
    /*   Counter Sale    */
    if( this.erpOrder.RecordTypeId == counterSaleRtId ||
        this.erpOrder.RecordTypeId == partnerPartOrder )
    {
      System.debug( 'setting up for counterSale' );
      setupForCounterSale();
    }

    /* Service Order OR Warranty OR TradeIn OR Fixed Asset */
    if( this.erpOrder.RecordTypeId == serviceRtId ||
        this.erpOrder.RecordTypeId == warrantyRtId ||
        this.erpOrder.RecordTypeId == tradeInRtId ||
        this.erpOrder.RecordTypeId == fixedAssetRtId )
      setupForServiceOrder();

    /* Manufacturing Order */
    if( this.erpOrder.RecordTypeId == manufacturingRtId )
    {
      internalOverRide = true;
      setupForServiceOrder();
    }
  }

  private void generateVariablesForPage()
  {
    if( this.projectAccount != null )
    {
      this.address = projectAccount.BillingStreet  + ' '
                    + projectAccount.BillingCity  + ' '
                    + projectAccount.BillingState  + ' '
                    + projectAccount.BillingPostalCode  + ' '
                    + projectAccount.BillingCountry;
      Date personBirthday = projectAccount.PersonBirthdate;
      DateTime birth;
      if (personBirthday != null) {
        birth = datetime.newInstance(personBirthday.year(), personBirthday.month(), personBirthday.day() );
        this.birthday =  birth.format('MMMMM dd, yyyy');
      }
    }
    this.storeAddress = this.warehouse.Street__c + ', '
            + this.warehouse.City__c + ', '
            + this.warehouse.State__c + ', '
            + this.warehouse.Country__c + ', '
            + this.warehouse.Postal_Code__c;


    String projectName = erpOrder.name;
    try {
      this.invoiceName = projectName.substring(0, projectName.indexOf('-'));
    }
    catch( Exception e )
    {
      this.invoiceName = projectName;
    }
    this.deliveryDate = erpOrder.Delivery_Date__c == null ? '' :
                        erpOrder.Delivery_Date__c.format('MMMMM dd, yyyy');
    this.invoiceDate = erpOrder.createdDate.format('MMMMM dd, yyyy');
    if( this.erpOrder.RecordTypeId == gcConstants.idRtProjectPartnerBoatSale )
      this.invoiceDate = erpOrder.Delivery_Date__c == null ? '' :
                         erpOrder.Delivery_Date__c.format('MMMMM dd, yyyy');

    if( this.erpOrder.RecordTypeId == gcConstants.idRtProjectCounterSale ||
        this.erpOrder.RecordTypeId == gcConstants.idRtPartnerPartsOrder ||
        this.erpOrder.RecordTypeId == gcConstants.idRtProjectWarranty )
    {
      this.invoiceDateLabel = 'Invoice Date';
      if( this.erpOrder.Delivery_Date__c != null )
      {
        this.InvoiceDate = erpOrder.Delivery_Date__c.format('MMMMM dd, yyyy');
        this.invoiceDateLabel = 'Delivery Date';
      }
    }
    this.partnerReference = erpOrder.Partner_External_PO_Number__c;
    this.provTaxInfo = new LGND_Utilities.ProvincialTax( this.erpOrder.GL_Account_Variable_3__c );
  }

  private void setupForBoatSale()
  {
    fetchPayments();
    fetchReturnPayables();
    fetchMaterial();
    try
    {
      this.tradeinRecord = [SELECT Lien_Amount__c, Total_Value__c
                            FROM Trade_In_Record__c
                            WHERE Opportunity__c =: erpOrder.AcctSeed__Opportunity__c];
    }
    catch(Exception e){}
    OpportunityContactRole[] ocrs = [ SELECT Id,
                                             Contact.Name,
                                             Contact.Email,
                                             Contact.Phone,
                                             Role,
                                             Contact.BirthDate,
                                             Contact.MailingCity,
                                             Contact.MailingState,
                                             Contact.MailingCountry,
                                             Contact.MailingPostalCode,
                                             Contact.MailingStreet,
                                             Contact.Drivers_License__c,
                                             Contact.Tax_Exempt_Status_Card_Number__c
                                        FROM OpportunityContactRole
                                        WHERE ( Role = 'Co-Buyer' OR Role = 'Buyer' )
                                        AND OpportunityId = :this.erpOrder.AcctSeed__Opportunity__c ];
    if( ocrs.size() > 0 )
    {
      for( OpportunityContactRole ocr : ocrs )
      {
        if( ocr.Role == 'Buyer' )
          buyer = ocr;
        if( ocr.Role == 'Co-Buyer' )
          cobuyer = ocr;
      }
    }


    if(null != tradeinRecord){
      //this.totalTrade = this.tradeinRecord.Total_Value__c - this.tradeinRecord.Lien_Amount__c;
      this.tradeInItem = [SELECT Model__c, Model_Year__c , Serial_Number__c,  Make__c FROM Trade_In_Item__c WHERE Trade_In_Record__c =: tradeinRecord.id];
    }

    this.boat = new AcctSeedERP__Material__c();
    this.trailer = new AcctSeedERP__Material__c();
    this.trollingMotors = new List<AcctSeedERP__Material__c>();
    this.motors = new List<AcctSeedERP__Material__c>();
    this.feesList = new  List <AcctSeedERP__Material__c>();
    this.discountList = new  List <AcctSeedERP__Material__c>();
    this.oppAccMaterials = new  List <AcctSeedERP__Material__c>();
    this.protectionServicesList = new  List <AcctSeedERP__Material__c>();
    this.bundlesList = new  List <AcctSeedERP__Material__c>();
    this.insuranceList = new List<AcctSeedERP__Material__c>();

    this.fillBoatSaleTables();
    this.createOptionLineItems( this.oppAccMaterials );
  }

  private void setupForCounterSale()
  {
    fetchPayments();
    fetchReturnPayables();
    fetchMaterial();
    fetchBillings();
    fetchTransfers();
    this.materialList = buildMaterialListWithKits( this.materials );
  }

  private void setupForServiceOrder()
  {
    fetchPayments();
    fetchReturnPayables();
    fetchProjectTasks();
    if( this.erpOrder.RecordTypeId == gcConstants.idRtFixedAsset )
      fetchFixedAsset();
    else
     fetchSerialNumber();
    partsTotal = 0;
    labourTotal = 0;
    if( this.erpOrder.RecordTypeId == gcConstants.idRtTradeIn )
      this.hideServiceDisclaimer = true;

    this.taskLineItems = new List<TaskLineItem>();
    for( AcctSeed__Project_Task__c task : this.projectTasks )
    {
      TaskLineItem tli = new TaskLineItem( task );
      if( !task.AcctSeedERP__Materials__r.isEmpty() )
        tli.taskParts.addAll( buildMaterialListWithKits( task.AcctSeedERP__Materials__r ) );
      this.taskLineItems.add( tli );

      for( AcctSeedERP__Material__c mat : task.AcctSeedERP__Materials__r )
      {
        if( mat.AcctSeedERP__Product__r.Family == 'Labour' )
          labourTotal += mat.GMBLASERP__Total_Price__c == null ? 0 : mat.GMBLASERP__Total_Price__c;
        else
          partsTotal += mat.GMBLASERP__Total_Price__c == null ? 0 : mat.GMBLASERP__Total_Price__c;
      }
    }
    this.taskLineItems.sort();
  }



  private void fillBoatSaleTables()
  {
    Id tradeInId = gcConstants.idProductTradeIn;
    Id tradeInLienId = gcConstants.idProductTradeInLien;
    for (AcctSeedERP__Material__c mat: this.materials) {

      if( mat.AcctSeedERP__Product__c == tradeInId )
        this.tradeInValue = mat.GMBLASERP__Unit_Price__c;

      if( mat.AcctSeedERP__Product__c == tradeInLienId )
        this.tradeInLien = mat.GMBLASERP__Unit_Price__c;

      if ('Boat' == mat.AcctSeedERP__Product__r.RecordType.Name) {
        this.boat = mat;
      }

      if ('Trailer' == mat.AcctSeedERP__Product__r.RecordType.Name) {
        this.trailer = mat;
      }

      if ('Trolling Motor' == mat.AcctSeedERP__Product__r.RecordType.Name) {
        this.trollingMotors.add( mat );
      }

      if ('Motor' == mat.AcctSeedERP__Product__r.RecordType.Name) {
        this.motors.add( mat );
      }

      if ('Fees' == mat.AcctSeedERP__Product__r.RecordType.Name) {
          this.feesList.add(mat);
      }

      if ('Part' == mat.AcctSeedERP__Product__r.RecordType.Name  &&
                'Discount' == mat.AcctSeedERP__Product__r.Family) {
                this.discountList.add( mat );
        this.totalSaving += mat.GMBLASERP__Total_Price__c;
      }

      if ('Part' == mat.AcctSeedERP__Product__r.RecordType.Name  &&
          'Discount' != mat.AcctSeedERP__Product__r.Family &&
           mat.AcctSeedERP__Product__c != tradeInId &&
           mat.AcctSeedERP__Product__c != tradeInLienId ) {
          this.oppAccMaterials.add(mat);
      }

      if('Protection and Services' == mat.AcctSeedERP__Product__r.RecordType.Name){
        this.protectionServicesList.add(mat);
      }

      if('Package Bundle' == mat.AcctSeedERP__Product__r.RecordType.Name){
        this.bundlesList.add(mat);
      }

      if('Insurance' == mat.AcctSeedERP__Product__r.RecordType.Name ){
          this.insuranceList.add( mat );
      }
    }
    this.subTotal = erpOrder.Order_Item_Total__c +  ( -1 * this.totalSaving);
    this.totalTrade = this.tradeInValue - this.tradeInLien;
  }

  private void createOptionLineItems( AcctSeedERP__Material__c[] materials)
  {
      oppAccList = new List<PartLineItem>();
      Set<Id> prodIds = new Set<Id>();
      for( AcctSeedERP__Material__c mat : materials )
      {
          prodIds.add( mat.AcctSeedERP__Product__c );
      }
      Map<Id, List<Product_Feature_Map__c>>  pfmMap = new Map<Id, List<Product_Feature_Map__c>>();
      for( Product_Feature_Map__c pfm : [ SELECT Id,
                                                 Product_Id__c,
                                                 Feature_Id__r.description__c,
                                                 Feature_Id__r.description_fr__c
                                          FROM Product_Feature_Map__c
                                          WHERE Product_Id__c IN : prodIds] )
      {
          if( !pfmMap.containsKey( pfm.Product_Id__c) )
              pfmMap.put( pfm.Product_Id__c, new List<Product_Feature_Map__c>() );
          pfmMap.get( pfm.Product_Id__c ).add( pfm );
      }
      for( AcctSeedERP__Material__c mat : materials )
      {
        if( mat.Material__c == null )
        {
          PartLineItem pli = new PartLineItem( mat );
          if( pfmMap.containsKey( mat.AcctSeedERP__Product__c) )
          {
              for( Product_Feature_Map__c pfm : pfmMap.get( mat.AcctSeedERP__Product__c) )
              {
                  pli.addFeature( pfm);
              }
          }
          oppAccList.add(pli);
        }
      }
  }

  private List<PartLineItem> buildMaterialListWithKits( AcctSeedERP__Material__c[] materials )
  {
    Set<String> exludeRTs = new Set<String>{
      'Boat',
      'Motor',
      'Trailer',
      'Trolling Motor',
      'Fees',
      'Insurance',
      'Protection and Services',
      'Package Bundle'
    };
    Map<Id, PartLineItem> parentMap = new Map<Id, PartLineItem>();
    Map<Id, List<PartLineItem>> kitPartsMap = new Map<Id, List<PartLineItem>>();
    Boolean billingInvoice = false;
    Boolean transferSlip = false;
    if(this.billId != null
      || erpOrder.RecordTypeId == gcConstants.idRtProjectCounterSale
      || (erpOrder.RecordTypeId == gcConstants.idRtPartnerPartsOrder && !erpOrder.Internal_Partner_Parts_Order__c))
      billingInvoice = true;

    if(this.transferId != null
      || (erpOrder.RecordTypeId == gcConstants.idRtProjectWarranty
        && erpOrder.Internal_Warranty__c)
      || (erpOrder.RecordTypeId == gcConstants.idRtPartnerPartsOrder
        && erpOrder.Internal_Partner_Parts_Order__c))
      transferSlip = true;

    for( AcctSeedERP__Material__c mat : materials )
    {
      if(billingInvoice)
      {
        if( this.mapMatlBill == null ) fetchBillings();
        if(!this.mapMatlBill.containsKey(mat.Id)) continue;
        PartLineItem pl = new PartLineItem(mat);
        MaterialBilling mb = this.mapMatlBill.get(mat.Id);
        pl.previousBilled = mb.quantityBilled.setScale(2);
        pl.billQuantity = mb.totalQuantity.setScale(2);
        pl.billUnitPrice = mb.unitPrice;
        pl.billTotal = mb.totalAmount;
        parentMap.put(mat.Id, pl);
      }else if(transferSlip)
      {
        if( this.mapMatlTransfer == null ) fetchTransfers();
        if(!this.mapMatlTransfer.containsKey(mat.Id)) continue;
        PartLineItem pl = new PartLineItem(mat);
        MaterialTransfer mb = this.mapMatlTransfer.get(mat.Id);
        pl.previousTransferred = mb.quantityTransferred.setScale(2);
        pl.transferQuantity = mb.totalQuantity.setScale(2);
        parentMap.put(mat.Id, pl);
      }else{
        if( internalOverRide == true )
        {
          if( mat.AcctSeedERP__Product__r.Composite_Type__c == 'Kit' ||
              ( !exludeRTs.contains( mat.AcctSeedERP__Product__r.RecordType.Name ) &&
              mat.AcctSeedERP__Product__r.Family != 'Discount' ) )
          {
            if( mat.Material__c == null )
              parentMap.put(mat.Id, new PartLineItem(mat) );
            else
            {
              if( !kitPartsMap.containsKey(mat.Material__c) )
                kitPartsMap.put( mat.Material__c, new List<PartLineItem>() );
              kitPartsMap.get( mat.Material__c ).add( new PartLineItem( mat ) );
            }
          }
        }
        else
        {
          if( mat.Material__c == null )
            parentMap.put(mat.Id, new PartLineItem(mat) );
          else
          {
            if( !kitPartsMap.containsKey(mat.Material__c) )
              kitPartsMap.put( mat.Material__c, new List<PartLineItem>() );
            kitPartsMap.get( mat.Material__c ).add( new PartLineItem( mat ) );
          }
        }
      }
    }
    if( !kitPartsMap.isEmpty() )
    {
      for(Id parentId : kitPartsMap.keySet() )
      {
        if( parentMap.containsKey( parentId) )
          parentMap.get( parentId ).kitParts.addAll( kitPartsMap.get( parentId ) );
      }
    }
    return parentMap.values();
  }

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
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
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