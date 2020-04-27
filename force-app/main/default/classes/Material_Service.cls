/**
 * Created by dave on 2019-08-22.
 */

public with sharing class Material_Service
{

  public class Material_Builder {
    public Id projectId;
    public Id businessOfficeTaskId;
    public Id salesTaskId;

    public Material_Builder( Id projectId, Id salesTaskId, Id businessOfficeTaskId )
    {
      this.projectId = projectId;
      this.businessOfficeTaskId = businessOfficeTaskId;
      this.salesTaskId = salesTaskId;
    }

    public AcctSeedERP__Material__c buildFromOppLineItem( OpportunityLineItem oli )
    {
      if( LGND_Constants.productRtId_Insurance == oli.Product2.RecordTypeId )
      {
        return buildInsuranceMaterial( oli );
      }
      if( oli.Product2Id == LGND_Constants.ppsaProductId )
      {
        return buildPPSAMaterial( oli );
      }
      if( LGND_Constants.productRtId_Protection == oli.Product2.RecordTypeId ||
          oli.Product2.Family == 'Extended Warranty' ||
          LGND_Constants.productRtId_Bundle == oli.Product2.RecordTypeId ||
        ( oli.Product2.Family != null && oli.Product2.Family.contains('Maintenance Package') ) )
      {
        return buildProtectionAndServicesMaterial( oli );
      }
      return buildStandardMaterial( oli );
    }

    private AcctSeedERP__Material__c buildStandardMaterial( OpportunityLineItem oli )
    {
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

    private AcctSeedERP__Material__c buildInsuranceMaterial( OpportunityLineItem oli )
    {
      AcctSeedERP__Material__c mat = buildStandardMaterial( oli );
      mat.AcctSeedERP__Project_Task__c = this.businessOfficeTaskId;
      mat.Insurance_Rate__c = oli.Insurance_Rate__c;
      mat.Insurance_Coverage__c = oli.InsuranceCoverage__c;
      mat.GMBLASERP__Price_Override__c = true;
      return mat;
    }

    private AcctSeedERP__Material__c buildPPSAMaterial( OpportunityLineItem oli )
    {
      System.debug( 'BUILDING PPSA MATERIAL' );
      AcctSeedERP__Material__c mat = buildStandardMaterial( oli );
      mat.AcctSeedERP__Project_Task__c = this.businessOfficeTaskId;
      mat.GMBLASERP__Price_Override__c = true;
      return mat;
    }

    private AcctSeedERP__Material__c buildProtectionAndServicesMaterial( OpportunityLineItem oli )
    {
      AcctSeedERP__Material__c mat = buildStandardMaterial( oli );
      mat.AcctSeedERP__Project_Task__c = this.businessOfficeTaskId;
      mat.Parent_Product__c = oli.ParentProductId__c;
      mat.GMBLASERP__Price_Override__c = true;
      return mat;
    }

  }

  public static List<AcctSeedERP__Material__c> buildTradeInMaterialsFromOpportunity(
    Opportunity opp,
    Id projectId,
    Id taskId )
  {
    List<AcctSeedERP__Material__c> mats = new List<AcctSeedERP__Material__c>();
    if(opp.Trade_In_Value__c <> 0)
    {
      mats.add(new AcctSeedERP__Material__c(
        AcctSeedERP__Product__c = gcConstants.idProductTradeIn,
        AcctSeedERP__Project__c = projectId,
        AcctSeedERP__Project_Task__c = taskId,
        AcctSeedERP__Comment__c = 'Trade In Value',
        AcctSeedERP__Quantity_per_Unit__c = -1,
        GMBLASERP__Unit_Price__c = opp.Trade_In_Value__c,
        GMBLASERP__Price_Override__c = true
      ));
      Decimal lienAmount = opp.Trade_In_Value__c - opp.Trade_In_Amount__c;
      if (lienAmount <> 0)
      {
        mats.add(new AcctSeedERP__Material__c(
          AcctSeedERP__Product__c = gcConstants.idProductTradeInLien,
          AcctSeedERP__Project__c = projectId,
          AcctSeedERP__Project_Task__c = taskId,
          AcctSeedERP__Comment__c = 'Trade In Lien Amount',
          AcctSeedERP__Quantity_per_Unit__c = 1,
          GMBLASERP__Unit_Price__c = lienAmount,
          GMBLASERP__Price_Override__c = true
        ));
      }
    }
    return mats;
  }



}