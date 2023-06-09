/**
 * Created by dave on 2019-08-22.
 */

public inherited sharing class Material_Service {
  public static AcctSeedERP__Material__c buildFromOpportunityLineItem(OpportunityLineItem oli, Id erpId, Id taskId) {
    return new AcctSeedERP__Material__c(
      AcctSeedERP__Product__c = oli.Product2Id,
      AcctSeedERP__Project_Task__c = taskId,
      AcctSeedERP__Project__c = erpId,
      Parent_Product__c = oli.ParentProductId__c,
      AcctSeedERP__Comment__c = oli.Description,
      GMBLASERP__Unit_Price__c = oli.UnitPrice,
      GMBLASERP__Price_Override__c = (oli.UnitPrice == oli.ListPrice ? false : true),
      AcctSeedERP__Quantity_Per_Unit__c = (oli.Quantity == null ? 0 : oli.Quantity),
      Insurance_Rate__c = oli.Insurance_Rate__c,
      Insurance_Coverage__c = oli.InsuranceCoverage__c
    );
  }

  public class Material_Builder {
    public Id projectId;
    public Id businessOfficeTaskId;
    public Id salesTaskId;

    public Material_Builder(Id projectId, Id salesTaskId, Id businessOfficeTaskId) {
      this.projectId = projectId;
      this.businessOfficeTaskId = businessOfficeTaskId;
      this.salesTaskId = salesTaskId;
    }

    public AcctSeedERP__Material__c buildFromOppLineItem(OpportunityLineItem oli) {
      if (LGND_Constants.productRtId_Insurance == oli.Product2.RecordTypeId) {
        return buildInsuranceMaterial(oli);
      }
      if (oli.Product2Id == LGND_Constants.ppsaProductId) {
        return buildPPSAMaterial(oli);
      }
      if (
        LGND_Constants.productRtId_Protection == oli.Product2.RecordTypeId ||
        oli.Product2.Family == 'Extended Warranty' ||
        LGND_Constants.productRtId_Bundle == oli.Product2.RecordTypeId ||
        (oli.Product2.Family != null && oli.Product2.Family.contains('Maintenance Package'))
      ) {
        return buildProtectionAndServicesMaterial(oli);
      }
      return buildStandardMaterial(oli);
    }

    private AcctSeedERP__Material__c buildStandardMaterial(OpportunityLineItem oli) {
      return new AcctSeedERP__Material__c(
        AcctSeedERP__Product__c = oli.Product2Id,
        AcctSeedERP__Project__c = this.projectId,
        AcctSeedERP__Project_Task__c = this.salesTaskId,
        AcctSeedERP__Comment__c = oli.Description,
        AcctSeedERP__Quantity_per_Unit__c = (oli.Quantity == null ? 0 : oli.Quantity),
        GMBLASERP__Unit_Price__c = oli.UnitPrice,
        GMBLASERP__Price_Override__c = (oli.UnitPrice == oli.ListPrice ? false : true)
      );
    }

    private AcctSeedERP__Material__c buildInsuranceMaterial(OpportunityLineItem oli) {
      AcctSeedERP__Material__c mat = buildStandardMaterial(oli);
      mat.AcctSeedERP__Project_Task__c = this.businessOfficeTaskId;
      mat.Insurance_Rate__c = oli.Insurance_Rate__c;
      mat.Insurance_Coverage__c = oli.InsuranceCoverage__c;
      mat.GMBLASERP__Price_Override__c = true;
      return mat;
    }

    private AcctSeedERP__Material__c buildPPSAMaterial(OpportunityLineItem oli) {
      System.debug('BUILDING PPSA MATERIAL');
      AcctSeedERP__Material__c mat = buildStandardMaterial(oli);
      mat.AcctSeedERP__Project_Task__c = this.businessOfficeTaskId;
      mat.GMBLASERP__Price_Override__c = true;
      return mat;
    }

    private AcctSeedERP__Material__c buildProtectionAndServicesMaterial(OpportunityLineItem oli) {
      AcctSeedERP__Material__c mat = buildStandardMaterial(oli);
      mat.AcctSeedERP__Project_Task__c = this.businessOfficeTaskId;
      mat.Parent_Product__c = oli.ParentProductId__c;
      mat.GMBLASERP__Price_Override__c = true;
      return mat;
    }
  }

  public static List<AcctSeedERP__Material__c> buildTradeInMaterialsFromOpportunity(
    Opportunity opp,
    Id projectId,
    Id taskId
  ) {
    List<AcctSeedERP__Material__c> mats = new List<AcctSeedERP__Material__c>();
    if (opp.Trade_In_Value__c <> 0) {
      mats.add(
        new AcctSeedERP__Material__c(
          AcctSeedERP__Product__c = gcConstants.idProductTradeIn,
          AcctSeedERP__Project__c = projectId,
          AcctSeedERP__Project_Task__c = taskId,
          AcctSeedERP__Comment__c = 'Trade In Value',
          AcctSeedERP__Quantity_per_Unit__c = -1,
          GMBLASERP__Unit_Price__c = opp.Trade_In_Value__c,
          GMBLASERP__Price_Override__c = true
        )
      );
      Decimal lienAmount = opp.Trade_In_Value__c - opp.Trade_In_Amount__c;
      if (lienAmount <> 0) {
        mats.add(
          new AcctSeedERP__Material__c(
            AcctSeedERP__Product__c = gcConstants.idProductTradeInLien,
            AcctSeedERP__Project__c = projectId,
            AcctSeedERP__Project_Task__c = taskId,
            AcctSeedERP__Comment__c = 'Trade In Lien Amount',
            AcctSeedERP__Quantity_per_Unit__c = 1,
            GMBLASERP__Unit_Price__c = lienAmount,
            GMBLASERP__Price_Override__c = true
          )
        );
      }
    }
    return mats;
  }

  public static List<AcctSeedERP__Material__c> buildForBackOrder(
    List<AcctSeedERP__Material__c> transferredMaterials,
    Map<Id, Map<String, String>> quantityById
  ) {
    List<AcctSeedERP__Material__c> result = new List<AcctSeedERP__Material__c>();
    Decimal totalTransfer = 0;
    for (AcctSeedERP__Material__c mat : transferredMaterials) {
      Decimal qty = Decimal.valueOf(quantityById.get(mat.Id).get('quantity'));
      if (
        quantityById.get(mat.Id).get('parentMatId') == null ||
        (quantityById.get(mat.Id).get('parentMatId') != null &&
        !quantityById.containsKey(quantityById.get(mat.Id).get('parentMatId')))
      ) {
        result.add(
          new AcctSeedERP__Material__c(
            AcctSeedERP__Product__c = mat.AcctSeedERP__Product__c,
            AcctSeedERP__Product__r = mat.AcctSeedERP__Product__r,
            AcctSeedERP__Quantity_Per_Unit__c = qty,
            GMBLASERP__Unit_Price__c = mat.GMBLASERP__Unit_Price__c,
            GMBLASERP__Price_Override__c = mat.GMBLASERP__Price_Override__c,
            AcctSeedERP__Comment__c = mat.AcctSeedERP__Comment__c
          )
        );
        totalTransfer += qty * mat.GMBLASERP__Unit_Price__c;
      }
    }
    Id backOrderCreditId = Utility_Products__c.getOrgDefaults().Back_Order_Credit__c;
    Product2 boCreditProduct = [SELECT Id, Name FROM Product2 WHERE Id = :backOrderCreditId];
    result.add(
      new AcctSeedERP__Material__c(
        AcctSeedERP__Product__c = boCreditProduct.Id,
        AcctSeedERP__Product__r = boCreditProduct,
        AcctSeedERP__Quantity_Per_Unit__c = 1,
        GMBLASERP__Unit_Price__c = -1 * totalTransfer,
        GMBLASERP__Price_Override__c = true,
        AcctSeedERP__Comment__c = 'Back Order Credit'
      )
    );
    return result;
  }

  public static List<AcctSeedERP__Material__c> buildFromPromotionalIncentiveProducts(
    List<Promotion_Incentive_Product__c> promoProducts,
    Id projectId,
    Id projectTaskId,
    String comment
  ) {
    List<AcctSeedERP__Material__c> result = new List<AcctSeedERP__Material__c>();
    for (Promotion_Incentive_Product__c iProd : promoProducts) {
      result.add(
        new AcctSeedERP__Material__c(
          AcctSeedERP__Project__c = projectId,
          AcctSeedERP__Project_Task__c = projectTaskId,
          AcctSeedERP__Product__c = iProd.Product__c,
          AcctSeedERP__Quantity_Per_Unit__c = iProd.Quantity__c,
          GMBLASERP__Unit_Price__c = 0,
          GMBLASERP__Price_Override__c = true,
          AcctSeedERP__Comment__c = comment
        )
      );
    }
    return result;
  }
}
