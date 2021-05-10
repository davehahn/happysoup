/**
 * Created by dave on 2019-09-10.
 */

public with sharing class PartnerPromotion {

  public static String sevenForSevenDiscountName = '7 for 7 Discount';
  public Id dealerOrderId;
  public List<ErpWrapper> erpWrappers;


  public class ResultMessage {
    public String success;
    public List<String> errors;
    public ResultMessage()
    {
      this.errors = new List<String>();
    }
  }

  public class ErpWrapper {
    public AcctSeed__Project__c erp;
    public Id boatId;
    public Decimal boatCost;
    public AcctSeedERP__Material__c boatLine;
    public AcctSeedERP__Material__c savingsLine;
    public Boolean promotionClaimed {
      get {
        return this.savingsLine == null ? false : true;
      }
    }

    public ErpWrapper( AcctSeed__Project__c erp )
    {
      Id boatRtId = LGND_Constants.productRtId_Boat;
      Id savingsProductId = LGND_Constants.savingsProductId;
      this.erp = erp;
      for( AcctSeedERP__Material__c mat : this.erp.AcctSeedERP__Project_Materials__r )
      {
        if(mat.AcctSeedERP__Product__r.RecordTypeId == boatRtId )
        {
          this.boatLine = mat;
          this.boatId = mat.AcctSeedERP__Product__c;
          this.boatCost = mat.GMBLASERP__Unit_Price__c;
        }
        if( mat.AcctSeedERP__Product__r.Id == savingsProductId &&
            mat.AcctSeedERP__Comment__c == PartnerPromotion.sevenForSevenDiscountName )
          this.savingsLine = mat;
      }
    }
  }

  public class BoatStack {
    public Integer stackSize;
    public Id boatId;
    public String boatName;
    public Decimal boatCost;
    public List<ErpWrapper> erpWrappers;
    public Integer count {
      get {
        return this.erpWrappers == null ? 0 : this.erpWrappers.size();
      }
    }
    public Integer completeStacks {
      get {
        return this.count / this.stackSize;
      }
    }
    public Integer incompleteCount {
      get {
        return this.count - ( this.completeStacks * this.stackSize );
      }
    }

    public String toGetPromotionMessage {
      get {
        if( incompleteCount == 0 ) return null;
        String msg =  'Add ' + ( this.stackSize - this.incompleteCount ) + ' - ' + this.boatName;
        if( this.stackSize - this.incompleteCount > 1 )
          msg += '\'s';
        msg += ' and receive a $' + String.valueOf( ((this.boatCost - (this.boatCost * 0.2)) * 0.07 ).setScale(2, RoundingMode.HALF_UP ) );
        msg += ' discount on each unit.';
        return msg;
      }
    }

    public BoatStack( Product2 boat, Decimal boatCost )
    {
      System.debug( boat );
      this.stackSize = boat.Stack_Size__c != null ? Integer.valueOf( boat.Stack_Size__c ) : null;
      this.boatId = boat.Id;
      this.boatName = boat.Name;
      this.boatCost = boatCost;
      this.erpWrappers = new List<ErpWrapper>();
    }
  }

  public class Seven4Seven_Promo {

    public Id dealerOrderId;
    public Map<Id, BoatStack> stacks;
    public final Integer qualifyingCount = 7;
    public final Decimal discountPercent = 0.07;
    public ResultMessage resultMessage;
    public Boolean isApplicable {
      get {
        Integer c = 0;
        for( BoatStack bs : this.stacks.values() )
        {
          if( bs.completeStacks > 0 )
            c += bs.completeStacks * bs.stackSize;
        }
        return c >= this.qualifyingCount;
      }
    }

    public Seven4Seven_Promo( Id dealerOrderId )
    {
      this.dealerOrderId = dealerOrderId;
      this.stacks = new Map<Id, BoatStack>();
      this.resultMessage = new ResultMessage();
      buildStacks();
    }

    public void buildStacks()
    {
      Id boatRtId = LGND_Constants.productRtId_Boat;
      Id savingsProdId = LGND_Constants.savingsProductId;
      Set<Id> erpIds = new Set<Id>();
      for( Dealer_Order_Line__c dol : [ SELECT Id,
                                               ERP_Order__c
                                        FROM Dealer_Order_Line__c
                                        WHERE Dealer_Order__c = :this.dealerOrderId ] )
      {
        erpIds.add( dol.ERP_Order__c );
      }
      for( AcctSeed__Project__c erp : [ SELECT Id, Name,
                                        ( SELECT Id,
                                                 AcctSeedERP__Project__c,
                                                 AcctSeedERP__Project_Task__c,
                                                 GMBLASERP__Unit_Price__c,
                                                 AcctSeedERP__Comment__c,
                                                 AcctSeedERP__Product__c,
                                                 AcctSeedERP__Product__r.Id,
                                                 AcctSeedERP__Product__r.Stack_Size__c,
                                                 AcctSeedERP__Product__r.Name,
                                                 AcctSeedERP__Product__r.RecordTypeId
                                          FROM AcctSeedERP__Project_Materials__r
                                          WHERE ( AcctSeedERP__Product__r.Stack_Size__c <> null
                                            AND AcctSeedERP__Product__r.RecordTypeId = :boatRtId )
                                          OR AcctSeedERP__Product__c = :savingsProdId )
                                        FROM AcctSeed__Project__c
                                        WHERE Id IN :erpIds] )
      {
        ErpWrapper ew = new ErpWrapper( erp );
        if( ew.boatLine != null )
        {
          if (!this.stacks.containsKey(ew.boatId))
            this.stacks.put(ew.boatId, new BoatStack(ew.boatLine.AcctSeedERP__Product__r, ew.boatCost));
          this.stacks.get(ew.boatId).erpWrappers.add(ew);
        }
      }
      if( this.stacks.keySet().size() > 0 )
      {
        for (BoatStack bs : this.stacks.values()) {
          if (bs.toGetPromotionMessage != null)
            this.resultMessage.errors.add(bs.toGetPromotionMessage);
        }
      }
    }

    public void apply()
    {
      Id discountProdId = LGND_Constants.savingsProductId;
      List<AcctSeedERP__Material__c> discounts = new List<AcctSeedERP__Material__c>();
      Decimal totalSavings = 0;
      Set<Id> erpIds_withSaving = new Set<Id>();
      for( BoatStack bs : this.stacks.values() )
      {
        if( bs.completeStacks > 0 )
        {
          for( Integer i=0; i<( bs.stackSize * bs.completeStacks ); i++ )
          {
            ErpWrapper wrapper = bs.erpWrappers[i];
            //Savings 7% AFTER coop discount which 2%
            Decimal savings = (wrapper.boatCost - ( wrapper.boatCost * 0.02 ) )  * this.discountPercent;
            if( !wrapper.promotionClaimed )
            {
              discounts.add(new AcctSeedERP__Material__c(
                AcctSeedERP__Project__c = wrapper.boatLine.AcctSeedERP__Project__c,
                AcctSeedERP__Project_Task__c = wrapper.boatLine.AcctSeedERP__Project_Task__c,
                GMBLASERP__Unit_Price__c = -1 * savings,
                AcctSeedERP__Quantity_Per_Unit__c = 1,
                GMBLASERP__Price_Override__c = true,
                AcctSeedERP__Comment__c = PartnerPromotion.sevenForSevenDiscountName,
                AcctSeedERP__Product__c = discountProdId
              ));
              erpIds_withSaving.add( wrapper.boatLine.AcctSeedERP__Project__c );
            }
            totalSavings += savings;
          }
        }
      }
      insert discounts;
      List<Dealer_Order_Line__c> dols = [SELECT Id, Order_Group_Id__c FROM Dealer_Order_Line__c WHERE ERP_Order__c IN :erpIds_withSaving];
      for( Dealer_Order_Line__c dol : dols )
      {
        dol.Order_Group_Id__c = dol.Order_Group_Id__c + '-747';
      }
      update dols;
      this.resultMessage.success = 'This order qualifies for the Legend Boats 7 for 7 Promotion and has been applied. <br /> You saved a total of <b>$' + String.valueOf( totalSavings.setScale(2, RoundingMode.HALF_UP) ) + '</b>';
    }
  }

}