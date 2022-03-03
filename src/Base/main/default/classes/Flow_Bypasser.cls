/**
 * Created by dave on 2022-03-02.
 */

public with sharing class Flow_Bypasser
{
  private static Flow_Bypasser instance = null;

  public Boolean isBypassed( String sObjectName, String flowName ){
    return TriggerBase.isBypassed( sObjectName ) || TriggerActionFlow.isBypassed( flowName );
  }

  private Flow_Bypasser(){}

  public static Flow_Bypasser getInstance(){
    if( instance == null ) instance = new Flow_Bypasser();
    return instance;
  }

  public class FlowBypasserDescriptor {
    @InvocableVariable
    public String sObjectName;
    @InvocableVariable
    public String flowName;

    public FlowBypasserDescriptor(){}
  }

  @InvocableMethod(
    Label='Is FLow Disabled?'
    Description='Checks if Flow TriggerBase has been bypassed for the sObject or TriggerActionFlow.bypass has be set for this Flows name'
    Category='Application Utilities'
  )
  public static List<Boolean> isFlowBypassed( List<FlowBypasserDescriptor> descriptors ){
    List<Boolean> result = new List<Boolean>();
    for( FlowBypasserDescriptor d : descriptors ){
      result.add(Flow_Bypasser.getInstance().isBypassed(descriptors[0].sObjectName, descriptors[0].flowName) );
    }
    return result;
  }
}