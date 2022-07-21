/**
 * Created by dave on 2022-06-01.
 */

@IsTest
private class Flow_Bypasser_T {
  private static final String SOBJECTNAME = 'Account';
  private static final String FLOWNAME = 'Test_Flow';
  private static List<Flow_Bypasser.FlowBypasserDescriptor> descriptorList;

  private static void init() {
    descriptorList = new List<Flow_Bypasser.FlowBypasserDescriptor>();
    Flow_Bypasser.FlowBypasserDescriptor bypasserDescriptor = new Flow_Bypasser.FlowBypasserDescriptor();
    bypasserDescriptor.sObjectName = SOBJECTNAME;
    bypasserDescriptor.flowName = FLOWNAME;
    descriptorList.add(bypasserDescriptor);
  }

  @IsTest
  static void isNotBypassed() {
    init();
    Test.startTest();
    List<Boolean> result = Flow_Bypasser.isFlowBypassed(descriptorList);
    Test.stopTest();

    System.assertEquals(false, result[0], 'The flow should not be bypassed');
  }

  @IsTest
  static void isBypassedByClass() {
    init();
    TriggerBase.bypass(SOBJECTNAME);
    Test.startTest();
    List<Boolean> result = Flow_Bypasser.isFlowBypassed(descriptorList);
    Test.stopTest();

    System.assertEquals(true, result[0], 'The flow should be bypassed');
  }

  @IsTest
  static void isBypassedByFlow() {
    init();
    TriggerActionFlow.bypass(FLOWNAME);
    Test.startTest();
    List<Boolean> result = Flow_Bypasser.isFlowBypassed(descriptorList);
    Test.stopTest();

    System.assertEquals(true, result[0], 'The flow should be bypassed');
  }

  @IsTest
  static void isBypassedByUnitTest() {
    init();
    descriptorList[0].alwaysBypassDuringApexUnitTests = true;
    Test.startTest();
    List<Boolean> result = Flow_Bypasser.isFlowBypassed(descriptorList);
    Test.stopTest();

    System.assertEquals(true, result[0], 'The flow should be bypassed');
  }
}
