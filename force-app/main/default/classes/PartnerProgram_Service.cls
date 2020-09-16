/**
 * Created by dave on 2020-07-24.
 */

public with sharing class PartnerProgram_Service
{
  public Set<Id> dealerOrderIds;
  public Map<Id, Dealer_Order__c> dealerOrderMap;
  public Map<Id, DealerOrderWrapper> dealerOrderWrappers;
  public Map<String, Partner_Booking_Order__c> bookingOrderMap;
  public Map<Id, List<AcctSeed__Project__c>> erpsByDealerOrder;
  public Map<Id, Result> result;

  public class Result
  {
    public List<String> appliedDiscountNames;
    public List<Map<String, Object>> appliedDiscounts;
    public List<String> errors;
    public Decimal totalSavings;

    public Result()
    {
      this.totalSavings = 0;
      this.appliedDiscountNames = new List<String>();
      this.appliedDiscounts = new List<Map<String, Object>>();
      this.errors = new List<String>();
    }

    public void addAppliedDiscount( PartnerProgramItem_I promo )
    {
      if(promo.getResult().totalSaving != null && promo.getResult().totalSaving <> 0) {
        this.appliedDiscountNames.add(promo.getDiscountPercent() + '% - ' + promo.getName());
        this.totalSavings += promo.getResult().totalSaving == null ? 0 : promo.getResult().totalSaving;
        this.appliedDiscounts.add(new Map<String, Object>{
            'name' => promo.getName(),
            'percentage' => promo.getDiscountPercent()
        });
      }
    }

    public void addError( String err )
    {
      this.errors.add( err );
    }

  }

  public class ErpWrapper
  {
    public AcctSeed__Project__c erp;
    public Id boatId;
    public String boatFamily;
    public Decimal boatCost;
    public AcctSeedERP__Material__c boatLine;
    public List<AcctSeedERP__Material__c> allLines;
    public List<AcctSeedERP__Material__c> savingLines;

    public ErpWrapper( AcctSeed__Project__c erp )
    {
      Id boatRtId = LGND_Constants.productRtId_Boat;
      Id savingsProductId = LGND_Constants.savingsProductId;
      this.erp = erp;
      this.allLines = erp.AcctSeedERP__Project_Materials__r;
      this.savingLines = new List<AcctSeedERP__Material__c>();
      for( AcctSeedERP__Material__c mat : this.erp.AcctSeedERP__Project_Materials__r )
      {
        if(mat.AcctSeedERP__Product__r.RecordTypeId == boatRtId )
        {
          this.boatLine = mat;
          this.boatId = mat.AcctSeedERP__Product__c;
          this.boatCost = mat.GMBLASERP__Unit_Price__c;
          this.boatFamily = mat.AcctSeedERP__Product__r.Family;
        }
        if( mat.AcctSeedERP__Product__r.Id == savingsProductId )
        {
          this.savinglines.add( mat );
        }
      }
    }

    public Boolean promotionClaimed( String programItemName )
    {
      Boolean result = false;
      if( this.savingLines.size() == 0 ) return result;
      for( AcctSeedERP__Material__c mat : this.savingLines )
      {
        if( mat.Applied_Partner_Program_Discount__c == programItemName )
        {
          result = true;
          break;
        }
      }
      return result;
    }

    public AcctSeedERP__Material__c buildDiscountLine( String programItemName,
                                                       Decimal amount )
    {
      Id discountProdId = LGND_Constants.savingsProductId;
      AcctSeedERP__Material__c mat = new AcctSeedERP__Material__c(
        Id = findExistingSavingsId( programItemName ),
        AcctSeedERP__Project__c = this.erp.Id,
        AcctSeedERP__Project_Task__c = this.erp.AcctSeed__Project_Tasks__r[0].Id,
        GMBLASERP__Unit_Price__c = -1 * amount,
        GMBLASERP__Price_Override__c = true,
        AcctSeedERP__Comment__c = programItemName,
        Applied_Partner_Program_Discount__c = programItemName,
        AcctSeedERP__Product__c = discountProdId,
        AcctSeedERP__Quantity_Per_Unit__c = 1
      );
      if( mat.Id == null )
        this.allLines.add( mat );
      return mat;
    }

    private Id findExistingSavingsId( String programItemName )
    {
      Id matId = null;
      for( AcctSeedERP__Material__c mat : this.savingLines )
      {
        if( mat.Applied_Partner_Program_Discount__c == programItemName )
        {
          matId = mat.Id;
          break;
        }
      }
      return matId;
    }
  }

  public class ResultMessage
  {
    public String success;
    public List<String> errors;
    public Decimal totalSaving;
    public Account updateAccount;
    public ResultMessage()
    {
      this.errors = new List<String>();
    }
  }

  public class DealerOrderWrapper
  {
    public Dealer_Order__c dealerOrder;
    public Date createdDate;
    public Id dealerOrderId;
    public Boolean isBookingOrder;
    public Boolean isCashOrder;
    public String programYear;
    public String bookingOrderUniquifier;
    public Partner_Booking_Order__c bookingOrder;
    public PartnerProgram_Service.Result result;
    public Set<String> appliedPrograms;
    public List<PartnerProgram_Service.ErpWrapper> erpWrappers;

    public DealerOrderWrapper( Dealer_Order__c dealerOrder,
                               List<AcctSeed__Project__c> erps,
                               Partner_Booking_Order__c bookingOrder )
    {
      this.result = new PartnerProgram_Service.Result();
      this.dealerOrder = dealerOrder;
      this.appliedPrograms = new Set<String>();
      if( dealerOrder.Applied_Partner_Program_Discounts__c != null )
      {
        this.appliedPrograms = new Set<String>(
          dealerOrder.Applied_Partner_Program_Discounts__c.split(';')
        );
      }
      this.erpWrappers = new List<PartnerProgram_Service.ErpWrapper>();
      this.dealerOrderId = dealerOrder.Id;
      this.isBookingOrder = dealerOrder.Is_Booking_Order__c;
      this.isCashOrder = dealerOrder.Payment_Method__c == 'Cash';
      this.createdDate = Date.newInstance(
        dealerOrder.CreatedDate.year(),
        dealerOrder.CreatedDate.month(),
        dealerOrder.CreatedDate.day()
      );
      this.programYear = dealerOrder.Program_Year__c;
      this.bookingOrderUniquifier = this.programYear + '-' + dealerOrder.Account__c;
      if( this.isBookingOrder && bookingOrder == null )
      {
        this.bookingOrder = new Partner_Booking_Order__c(
          Dealer_Order__c = this.dealerOrderId,
          Name = this.programYear,
          Account__c = dealerOrder.Account__c
        );
      }
      else
      {
        this.bookingOrder = bookingOrder;
      }
      if( erps != null )
        wrapERPs( erps );
    }

    public void updateDealerOrder()
    {
      if( this.appliedPrograms.size() > 0 )
      {
        this.dealerOrder.Applied_Partner_Program_Discounts__c = setToMultiSelect(this.appliedPrograms);
        TriggerHandler.bypass('DealerOrder_TriggerHandler');
        update this.dealerOrder;
        TriggerHandler.clearBypass('DealerOrder_TriggerHandler');
      }
    }

    private void wrapERPs( List<AcctSeed__Project__c> erps )
    {
      for( AcctSeed__Project__c erp : erps )
      {
        PartnerProgram_Service.ErpWrapper wrapper = new PartnerProgram_Service.ErpWrapper( erp );
        this.erpWrappers.add( wrapper );
      }
    }

    private String setToMultiSelect( Set<String> names )
    {
      String result = '';
      for( String name : names )
      {
        result += name + ';';
      }
      result = result.removeEnd(';');
      return result;
    }

  }


  public PartnerProgram_Service( Set<Id> dealerOrderIds )
  {
    this.dealerOrderIds = dealerOrderIds;
    this.dealerOrderWrappers = new Map<Id, DealerOrderWrapper>();
    this.bookingOrderMap = new Map<String, Partner_Booking_Order__c>();
    this.result = new Map<Id,Result>();
    this.erpsByDealerOrder = new Map<Id, List<AcctSeed__Project__c>>();
    init();
  }

  private void init()
  {
    fetchDealerOrders();
    fetchBookingOrders();
    fetchErps();
    for( Id doId : this.dealerOrderIds )
    {
      Dealer_Order__c theDO = this.dealerOrderMap.get(doId);
      String uniq = theDO.Program_Year__c + '-' + theDO.Account__c;
      Partner_Booking_Order__c pbo = this.bookingOrderMap.containsKey( uniq ) ?
        this.bookingOrderMap.get( uniq ) : null;

      this.dealerOrderWrappers.put( doId, new DealerOrderWrapper(
        this.dealerOrderMap.get( doId ),
        this.erpsByDealerOrder.get( doId ),
        pbo
      ) );
      this.result.put( doId, new Result() );
    }
  }

  public void checkAndApply()
  {
    for( Id doId : this.dealerOrderIds )
    {
      new PartnerProgram_Executor().execute(
        this.dealerOrderWrappers.get( doId )
      );
    }
  }

  private void fetchDealerOrders()
  {
    this.dealerOrderMap = new Map<Id, Dealer_Order__c>(
      [ SELECT
          Id,
          CreatedDate,
          Is_Booking_Order__c,
          Program_Year__c,
          Account__c,
          Payment_Method__c,
          Applied_Partner_Program_Discounts__c
        FROM Dealer_Order__c
        WHERE Id IN :this.dealerOrderIds ]
    );
  }

  private void fetchBookingOrders()
  {
    Set<Id> acctIds = new Set<Id>();
    for( Dealer_Order__c dOrder : this.dealerOrderMap.values() )
    {
      acctIds.add( dOrder.Account__c );
    }
    for( Partner_Booking_Order__c pbo : [ SELECT Id,
                                                 Name,
                                                 Account__c,
                                                 Pontoon_Volume_Discount_Percent__c,
                                                 V_Hull_Discount_Percent__c,
                                                 Dealer_Order__c,
                                                 Uniquifier__c
                                          FROM Partner_Booking_Order__c
                                          WHERE Account__c IN :acctIds ])
    {
      this.bookingOrderMap.put( pbo.Uniquifier__c, pbo );
    }
  }

  private void fetchERPs()
  {
    Map<Id, Id> erpId2DealerOrderId = new Map<Id, Id>();
    for( Dealer_Order_Line__c dol : [ SELECT Id,
                                             ERP_Order__c,
                                             Dealer_Order__c
                                      FROM Dealer_Order_Line__c
                                      WHERE Dealer_Order__c IN :this.dealerOrderIds ] )
    {
      erpId2DealerOrderId.put( dol.ERP_Order__c, dol.Dealer_Order__c );
    }
    for( AcctSeed__Project__c erp : [ SELECT Id, Name,
                                      ( SELECT Id
                                        FROM AcctSeed__Project_Tasks__r ),
                                      ( SELECT Id,
                                        AcctSeedERP__Project__c,
                                        AcctSeedERP__Project_Task__c,
                                        GMBLASERP__Unit_Price__c,
                                        AcctSeedERP__Comment__c,
                                        Applied_Partner_Program_Discount__c,
                                        AcctSeedERP__Product__c,
                                        AcctSeedERP__Product__r.Id,
                                        AcctSeedERP__Product__r.Stack_Size__c,
                                        AcctSeedERP__Product__r.Name,
                                        AcctSeedERP__Product__r.RecordTypeId,
                                        AcctSeedERP__Product__r.Family,
                                        AcctSeedERP__Product__r.AcctSeedERP__Serialized__c
                                      FROM AcctSeedERP__Project_Materials__r )
                                      FROM AcctSeed__Project__c
                                      WHERE Id IN :erpId2DealerOrderId.keySet() ] )
    {
      if( !this.erpsByDealerOrder.containsKey( erpId2DealerOrderId.get(erp.Id) ) )
        this.erpsByDealerOrder.put( erpId2DealerOrderId.get(erp.Id), new List<AcctSeed__Project__c>() );
      this.erpsByDealerOrder.get( erpId2DealerOrderId.get(erp.Id) ).add( erp );
    }
  }

}