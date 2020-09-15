/**
 * Created by dave on 2020-02-11.
 */

public class CommissionWrapper
{

  public class Record {

    @AuraEnabled public String id;
    @AuraEnabled public String factoryPricebookId;
    @AuraEnabled public String taxationProvince;
    @AuraEnabled public String calculationMethod;
    @AuraEnabled public String status;
    @AuraEnabled public String approvedById;
    @AuraEnabled public String approvedByName;
    @AuraEnabled public String projectId;
    @AuraEnabled public String taskId;
    @AuraEnabled public String taskName;
    @AuraEnabled public Boolean isViewable;
    @AuraEnabled public Boolean projectIsClosedLost;

    @AuraEnabled public Boolean canViewAllCommissions = LGND_Utilities.CustomPermissions.canViewAllCommissionRecord;
    @AuraEnabled public Boolean canUndoApproved = LGND_Utilities.CustomPermissions.canReOpenCommissionRecord;
    @AuraEnabled public Boolean canChangeStage = Schema.sObjectType.CommissionRecord2__c.fields.Status__c.isUpdateable();

    public Record(){}

    public Record( CommissionRecord2__c cRec )
    {
      this.id = cRec.Id;
      this.factoryPricebookId = cRec.Factory_Pricebook__c;
      this.taxationProvince = cRec.TaxProvince__c;
      this.calculationMethod = cRec.Calculation_Method__c;
      this.status = cRec.Status__c;
      this.approvedById = cRec.Approved_By__c;
      this.approvedByName = cRec.Approved_By__r.Name;
      this.projectId = cRec.Project__c;
      this.taskId = cRec.Project_Task__c;
      this.taskName = cRec.Project_Task__r.Name;
      this.isViewable = checkAccess( cRec.Commission_Payments__r );
      this.projectIsClosedLost = cRec.Project__r.Stage__c == 'Closed Lost';
    }

    private Boolean checkAccess( List<CommissionPayment2__c> payments )
    {
      if( this.canViewAllCommissions )
        return true;
      Boolean result = false;
      Id userId = UserInfo.getUserId();
      for( CommissionPayment2__c p : payments )
      {
        if( userId == p.Owner__c )
        {
          result = true;
          break;
        }
      }
      return result;
    }
  }


  public class LineItems {
    public List<LineItem> items;

    public LineItems()
    {
      this.items = new List<LineItem>();
    }

    public void addAll( List<CommissionLineItem2__c> clis )
    {
      for( CommissionLineItem2__c cli : clis )
      {
        add( cli );
      }
    }

    public void add( CommissionLineItem2__c cli )
    {
      this.items.add( new LineItem( cli ) );
    }

    public List<LineItem> groupKits()
    {
      List<LineItem> grouped = new List<LineItem>();
      Map<String, List<LineItem>> parentId_item_map = new Map<String, List<LineItem>>();
      for( LineItem li : this.items )
      {
        if( !parentId_item_map.containsKey( li.parentMatId) )
        {
          parentId_item_map.put( li.parentMatId, new List<LineItem>() );
        }
        parentId_item_map.get( li.parentMatId ).add( li );
      }
      for( LineItem li : this.items )
      {
        if( li.parentMatId == null )
        {
          if( li.matId != null && parentId_item_map.containsKey( li.matId ) )
          {
            li.kitParts.addAll( parentId_item_map.get(li.matId) );
          }
          grouped.add( li );
        }
      }
      this.items = new List<LineItem>();
      this.items.addAll( grouped );
      return this.items;
    }
  }


  public class LineItem {
    @AuraEnabled public String id;
    @AuraEnabled public String description;
    @AuraEnabled public String productId;
    @AuraEnabled public String comment;
    @AuraEnabled public Decimal salePrice;
    @AuraEnabled public Decimal unitCost;
    @AuraEnabled public Decimal totalSale;
    @AuraEnabled public Decimal totalCost;
    @AuraEnabled public Decimal totalLabour;
    @AuraEnabled public Decimal quantity;
    @AuraEnabled public Decimal labourCost;
    @AuraEnabled public Decimal profit;
    @AuraEnabled public Decimal commissionRate;
    @AuraEnabled public Decimal payment;
    @AuraEnabled public Boolean basedOnProfit;
    @AuraEnabled public Boolean hasMultiple;
    @AuraEnabled public List<LineItem> kitParts;
    @AuraEnabled public String matId;
    @AuraEnabled public String parentMatId;
    @AuraEnabled public String commissionRecordId;
    @AuraEnabled public String commissionRecordStatus;
    @AuraEnabled public Boolean isCustomItem;
    @AuraEnabled public Boolean isEditable;

    public LineItem(){}

    public LineItem( CommissionLineItem2__c cli )
    {
      this.id = cli.Id;
      this.description = cli.Product__c != null ? cli.Product__r.Name : cli.Description__c;
      this.productId = cli.Product__c;
      this.comment = cli.Comment__c;
      this.salePrice = cli.Sale_Price__c;
      this.unitCost = cli.Cost__c;
      this.totalSale = cli.Total_Sale__c;
      this.totalCost = cli.Total_Cost__c;
      this.quantity = cli.Quantity__c;
      this.labourCost = cli.Labour_Cost__c;
      this.totalLabour = cli.Total_Labour__c;
      this.profit = cli.Profit__c;
      this.commissionRate = cli.Commission_Rate__c;
      this.basedOnProfit = cli.Payment_Based_on_Profit__c;
      this.payment = cli.Payment_Amount__c;
      this.hasMultiple = cli.Quantity__c > 1;
      this.matId = cli.Material__c;
      this.parentMatId = cli.Material__r.Material__c;
      this.commissionRecordId = cli.CommissionRecord2__c;
      this.commissionRecordStatus = cli.CommissionRecord2__r.Status__c;
      this.isCustomItem = cli.Material__c == null;
      this.isEditable = this.isCustomItem && this.commissionRecordStatus != 'Approved';
      this.kitParts = new List<LineItem>();
    }

    public LineItem upsertLineItem()
    {
      CommissionLineItem2__c cli = this.toSObject();
      upsert cli;
      return new LineItem( CommissionLineItem2_Selector.allById( new Set<Id>{ cli.Id } )[0] );
    }

    private CommissionLineItem2__c toSObject()
    {
      return new CommissionLineItem2__c(
        Id = this.id,
        Description__c = this.description,
        Comment__c = this.comment,
        Sale_Price__c = this.SalePrice,
        Cost__c = this.unitCost,
        Labour_Cost__c = this.labourCost,
        Quantity__c = this.quantity,
        CommissionRecord2__c = this.commissionRecordId,
        Commission_Rate__c = this.commissionRate
      );
    }

  }

  public class Payment
  {
    @AuraEnabled public String id;
    @AuraEnabled public String cType;
    @AuraEnabled public String mcType;
    @AuraEnabled public String owner;
    @AuraEnabled public String ownerId;
    @AuraEnabled public String avatarURL;
    @AuraEnabled public String status;
    @AuraEnabled public String commissionRecordId;
    @AuraEnabled public String commissionRecordStatus;
    @AuraEnabled public Boolean usesGrossCalculation;
    @AuraEnabled public Decimal amount;
    @AuraEnabled public Decimal totalProfit;
    @AuraEnabled public Decimal totalPayment;
    @AuraEnabled public Decimal split;
    @AuraEnabled public Decimal grossMarginPaymentPercent;

    public Payment(){}

    public Payment( CommissionPayment2__c p )
    {
      this.id = p.Id;
      this.cType = p.Type__c == null ? 'Standard' : p.Type__c;
      this.mcType = p.Manager_Commission_Type__c == null ? 'Gross Margin' : p.Manager_Commission_Type__c;
      this.owner = p.Owner__r.Name;
      this.ownerId = p.Owner__c;
      this.commissionRecordId = p.Commission_Record2__c;
      this.commissionRecordStatus = p.Commission_Record2__r.Status__c;
      this.avatarURL = p.Owner__r.SmallPhotoUrl;
      this.status = p.Status__c;
      this.usesGrossCalculation = p.Use_Gross_Margin_Calculation__c;
      this.amount = p.Amount__c;
      this.totalProfit = p.Commission_Record2__r.Total_Profit__c;
      this.totalPayment = p.Commission_Record2__r.Total_Payment_Amount__c;
      this.split = p.Split_Percent__c;
      this.grossMarginPaymentPercent = p.Gross_Margin_Payment_Percent__c;
    }

    public CommissionPayment2__c toSObject()
    {
      return new CommissionPayment2__c(
        Id = this.id,
        Owner__c = this.ownerId,
        Split_Percent__c = this.split,
        Type__c = this.cType,
        Commission_Record2__c = this.commissionRecordId
      );
    }
  }
}