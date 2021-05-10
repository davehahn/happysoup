/**
 * Created by Tim on 2021-04-29.
 */

public with sharing class FactoryStore_FlowController {
    //get instance of the flow
    public Flow.Interview.Factory_Store_Simple_Lead_Form leadFlow { get; set; }

    @AuraEnabled(Cacheable=true)
    public static void passBoatModelId(String modelId){
        // Call the Flow
        Map<String, Object> params = new Map<String, Object>();
        params.put('BoatModel', modelId);
        try{
            Flow.Interview.Factory_Store_Simple_Lead_Form passId = new Flow.Interview.Factory_Store_Simple_Lead_Form(params);
//            passId.start();
//
//            // Obtain the results
//            String returnValue = (String) passId.getVariableValue('ReturnValue');
//            System.debug('Flow returned ' + returnValue);
        }
        catch( Exception e){
            System.debug('The following exception has occurred: ' + e.getMessage());
        }

    }

}