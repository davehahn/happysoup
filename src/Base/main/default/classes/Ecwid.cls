@RestResource(urlMapping='/Ecwid/Order')
global with sharing class Ecwid{
    @HttpPost
    global static void postItems () {
        
        Map<String,String> paramsMap = RestContext.request.params;
        System.debug('body= '+paramsMap );
        RestRequest  req = RestContext.request;
        RestResponse res = RestContext.response;
        
        System.debug('[ Post req --> ]' + JSON.serializePretty( req ) ) ; 
         System.debug('req.requestBody= '+req.requestBody); 
        Map<String, String> autoResponse =  req.params;
        System.debug('[ autoResponse --> ]' + JSON.serializePretty( autoResponse ) ) ;  
        
        res.statusCode = 300;
        
        String itemName             = autoResponse.get('itemName');
        String itemId               = autoResponse.get('itemID');
        String eventType            = autoResponse.get('eventType');
        String itemType             = autoResponse.get('itemType');
        String itemParentFolderId   = autoResponse.get('itemParentFolderId');
 
        /*if( 'folder' != itemType ){

            // Get the list of Box_Rest__c that match the account_name sent in the request.
            List<Box_Rest__c> boxRestItem = [SELECT Id, Name , Item_Id__c ,Previewed_number__c,
                                             Downloaded_number__c
                                            FROM Box_Rest__c
                                             WHERE Item_Id__c =: itemId ];
            //delted                          
            if( !boxRestItem.isEmpty() && 'deleted' == eventType ){
                delete boxRestItem ;
                return;  
                }
            
            //create Box_Rest obj for : upsert
            Box_Rest__c box = new Box_Rest__c (Name = itemName , Item_Id__c = itemId ,
                                               Last_Event_Type__c = eventType,
                                               item_Parent_Folder_Id__c = itemParentFolderId );
            
            //created or updeted
            if( 'previewed' != eventType &&  'deleted' != eventType && 
                'downloaded' != eventType){ 
                    upsert box Item_Id__c;
                    return ;
               }

            //update preview counter   
            if( !boxRestItem.isEmpty() && 'previewed' == eventType ){ 
                    box.Previewed_number__c = boxRestItem[0].Previewed_number__c + 1;  
                    upsert box Item_Id__c;
                    return ;
               }//update downloaded counter   
            if( !boxRestItem.isEmpty() && 'downloaded' == eventType ){ 
                    box.Downloaded_number__c = boxRestItem[0].Downloaded_number__c + 1;  
                    upsert box Item_Id__c;
                    return ;
               }
            //never should be here 
            System.debug('[ Hi .. you shouldn\'t be here, check "global class BoxRest"  ]' ) ; 
        }//END folder IF
        return;*/
    }
}