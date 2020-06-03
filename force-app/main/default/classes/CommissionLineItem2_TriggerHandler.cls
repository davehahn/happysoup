/**
 * Created by dave on 2020-01-24.
 */

public without sharing class CommissionLineItem2_TriggerHandler extends TriggerHandler
{


//  protected override void bulkBefore()
//  {
//  }

//  protected override void bulkAfter()
//  {
//  }

  protected override void beforeInsert()
  {
    determineCostAndCommissionRate( (List<CommissionLineItem2__c>)Trigger.new );
    calculateValues( (List<CommissionLineItem2__c>)Trigger.new );
  }

  protected override void beforeUpdate()
  {
    System.debug('CommissionLineItem before Update');
    determineCostAndCommissionRate( (List<CommissionLineItem2__c>)Trigger.new );
    calculateValues( (List<CommissionLineItem2__c>)Trigger.new );
  }

//  protected override void beforeDelete()
//  {
//  }

  protected override void afterInsert()
  {
    handleChanges( (List<CommissionLineItem2__c>)Trigger.new, null );
  }

  protected override void afterUpdate()
  {
    handleChanges(
      (List<CommissionLineItem2__c>)Trigger.new,
      (Map<Id, CommissionLineItem2__c>)Trigger.oldMap
    );
  }

//  protected override void afterDelete()
//  {
//  }

//  protected override void afterUndelete()
//  {
//  }

//  protected override void finalActions()
//  {
//  }


  private static void determineCostAndCommissionRate( List<CommissionLineItem2__c> listNew )
  {
    CommissionLineItem2_Service.RateCostCalculator rateCalculator =
      new CommissionLineItem2_Service.RateCostCalculator( listNew );

    for( CommissionLineItem2__c cli : listNew )
    {
      if( cli.Product__c != null )
      {
        rateCalculator.calculate(cli);
      }
    }
  }


  private static void calculateValues( List<CommissionLineItem2__c> listNew )
  {
    for( commissionLineItem2__c cli : listNew )
    {
      Decimal riggingTime = cli.Product_Retail_Rigging_Time__c == null ? 0 : cli.Product_Retail_Rigging_Time__c;
      if( cli.Labour_Cost__c == null )
      {
        cli.Labour_Cost__c = LGND_Constants.retailLabourRate * riggingTime;
      }

      cli.Profit__c = (cli.Sale_Price__c - cli.Cost__c - cli.Labour_Cost__c) * cli.Quantity__c;

      if( cli.Payment_Based_on_Profit__c )
      {
        cli.Payment_Amount__c = cli.Profit__c * cli.Commission_Rate__c;
      }
      else
      {
        cli.Payment_Amount__c = cli.Sale_Price__c * cli.Quantity__c * cli.Commission_Rate__c;
      }
    }
  }

  private static void handleChanges( List<CommissionLineItem2__c> listNew,
    Map<Id, CommissionLineItem2__c> oldMap )
  {
    Map<Id, List<String>> changeMap = new Map<Id, List<String>>();
    for( CommissionLineItem2__c cli : listNew )
    {
      List<String> changes = new List<String>();
      if( oldMap == null )
      {
        changes.add(
          String.valueOf(cli.Quantity__c) + ' X ' + cli.Descriptor__c + ' has been added'
        );
      }
      else
      {
        CommissionLineItem2__c oldLine = oldMap.get( cli.Id );
        {
          if( cli.Quantity__c != oldLine.Quantity__c )
          {
            changes.add( 'Quantity of ' + cli.Descriptor__c + ' has changed from ' + oldLine.Quantity__c + ' to ' + cli.Quantity__c );
          }
          if( cli.Sale_Price__c != oldLine.Sale_Price__c )
          {
            changes.add( 'The Sale Price on ' + cli.Descriptor__c + ' has changed from $' + oldLine.Sale_Price__c + ' to $' + cli.Sale_Price__c );
          }
        }
      }
      if( !changeMap.containsKey( cli.CommissionRecord2__c ) )
      {
        changeMap.put(cli.CommissionRecord2__c, new List<String>());
      }
      changeMap.get( cli.CommissionRecord2__c ).addAll( changes );
    }
    CommissionLineItem2_Service.makeChatterPostsAboutChanges( changeMap );
    CommissionRecord2_Service.openIfClosed( changeMap.keySet() );
  }
}