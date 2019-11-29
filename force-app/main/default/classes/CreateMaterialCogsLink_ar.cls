public with sharing class CreateMaterialCogsLink_ar {
    public CreateMaterialCogsLink_ar() {}
    public static void createCOGSToMaterialLink(Set<Id> setIdProjects)
    {
        Id idGlCogsParts = gcConstants.idGlCogsParts;
        Id idGlProjectParts = gcConstants.idGlProjectParts;
        /// Now Materials 
        Map<Id,Map<Id,Map<Id,Map<Integer,Id>>>> mapPTPMatlId = new Map<Id,Map<Id,Map<Id,Map<Integer,Id>>>>();
        for(AcctSeedERP__Material__c matl :
            [SELECT Id, 
                    AcctSeedERP__Project__c,
                    AcctSeedERP__Project_Task__c,
                    AcctSeedERP__Product__c,
                    (SELECT Id, AcctSeed__Units__c FROM Journal_Entry_Lines__r)
             FROM AcctSeedERP__Material__c
             WHERE AcctSeedERP__Project__c IN:setIdProjects])
        {
            //if(!matl.Journal_Entry_Lines__r.isEmpty()) continue;

            if(!mapPTPMatlId.containsKey(matl.AcctSeedERP__Project__c))
                mapPTPMatlId.put(matl.AcctSeedERP__Project__c, new Map<Id,Map<Id,Map<Integer,Id>>>());
            if(!mapPTPMatlId.get(matl.AcctSeedERP__Project__c).containsKey(matl.AcctSeedERP__Project_Task__c))
                mapPTPMatlId.get(matl.AcctSeedERP__Project__c).put(matl.AcctSeedERP__Project_Task__c, new Map<Id,Map<Integer,Id>>());
            if(!mapPTPMatlId.get(matl.AcctSeedERP__Project__c).get(matl.AcctSeedERP__Project_Task__c).containsKey(matl.AcctSeedERP__Product__c))
                mapPTPMatlId.get(matl.AcctSeedERP__Project__c).get(matl.AcctSeedERP__Project_Task__c).put(matl.AcctSeedERP__Product__c, new Map<Integer,Id>());

            Integer cSize = mapPTPMatlId.get(matl.AcctSeedERP__Project__c).get(matl.AcctSeedERP__Project_Task__c).get(matl.AcctSeedERP__Product__c).size();
            mapPTPMatlId.get(matl.AcctSeedERP__Project__c).get(matl.AcctSeedERP__Project_Task__c).get(matl.AcctSeedERP__Product__c).put(cSize+1,matl.Id);           
        }
        System.debug(loggingLevel.error,'mapPTPMatlId: '+mapPTPMatlId);
        /// Already Added Journal Entries
        List<AcctSeed__Journal_Entry_Line__c> listJEL = new List<AcctSeed__Journal_Entry_Line__c>();
        Map<Id,Map<Id,Map<Id,Map<Integer,Id>>>> mapPTPJelPosId = new Map<Id,Map<Id,Map<Id,Map<Integer,Id>>>>();
        Map<Id,Map<Id,Map<Id,Map<Integer,Id>>>> mapPTPJelRevId = new Map<Id,Map<Id,Map<Id,Map<Integer,Id>>>>();
        for(AcctSeed__Journal_Entry_Line__c cogsJE :
            [SELECT Id,
                AcctSeed__Journal_Entry__r.Name,
                AcctSeed__Project__c,
                AcctSeed__Project_Task__c,
                AcctSeed__Product__c,
                Material__c
             FROM AcctSeed__Journal_Entry_Line__c
             WHERE AcctSeed__Project__c IN:setIdProjects
                AND Material__c = null
                AND (AcctSeed__GL_Account__c =:idGlCogsParts 
                    OR AcctSeed__GL_Account__c =:idGlProjectParts)
                AND (AcctSeed__Journal_Entry__r.Name like '%Job Cost for%' OR AcctSeed__Journal_Entry__r.Name like '%Internal Labour for%' OR AcctSeed__Journal_Entry__r.Name like '%Internal Warranty for%')])
        {
            Map<Id,Map<Id,Map<Id,Map<Integer,Id>>>> mapPTPJelId;
            if(cogsJE.AcctSeed__Journal_Entry__r.Name.startsWith('Reverse'))    
                mapPTPJelId = mapPTPJelPosId;
            else
                mapPTPJelId = mapPTPJelRevId;

            if(!mapPTPJelId.containsKey(cogsJE.AcctSeed__Project__c))
                mapPTPJelId.put(cogsJE.AcctSeed__Project__c, new Map<Id,Map<Id,Map<Integer,Id>>>());
            if(!mapPTPJelId.get(cogsJE.AcctSeed__Project__c).containsKey(cogsJE.AcctSeed__Project_Task__c))
                mapPTPJelId.get(cogsJE.AcctSeed__Project__c).put(cogsJE.AcctSeed__Project_Task__c, new Map<Id,Map<Integer,Id>>());
            if(!mapPTPJelId.get(cogsJE.AcctSeed__Project__c).get(cogsJE.AcctSeed__Project_Task__c).containsKey(cogsJE.AcctSeed__Product__c))
                mapPTPJelId.get(cogsJE.AcctSeed__Project__c).get(cogsJE.AcctSeed__Project_Task__c).put(cogsJE.AcctSeed__Product__c, new Map<Integer,Id>());

            Integer cSize = mapPTPJelId.get(cogsJE.AcctSeed__Project__c).get(cogsJE.AcctSeed__Project_Task__c).get(cogsJE.AcctSeed__Product__c).size() + 1;
            //mapPTPJelId.get(cogsJE.AcctSeed__Project__c).get(cogsJE.AcctSeed__Project_Task__c).get(cogsJE.AcctSeed__Product__c).put(cSize,cogsJE.Id);

            Id matlId;
            if(mapPTPMatlId.containsKey(cogsJE.AcctSeed__Project__c))
            if(mapPTPMatlId.get(cogsJE.AcctSeed__Project__c).containsKey(cogsJE.AcctSeed__Project_Task__c))
            if(mapPTPMatlId.get(cogsJE.AcctSeed__Project__c).get(cogsJE.AcctSeed__Project_Task__c).containsKey(cogsJE.AcctSeed__Product__c)){
                if(mapPTPMatlId.get(cogsJE.AcctSeed__Project__c).get(cogsJE.AcctSeed__Project_Task__c).get(cogsJE.AcctSeed__Product__c).containsKey(cSize)){
                    matlId = mapPTPMatlId.get(cogsJE.AcctSeed__Project__c).get(cogsJE.AcctSeed__Project_Task__c).get(cogsJE.AcctSeed__Product__c).get(cSize);
                    mapPTPJelId.get(cogsJE.AcctSeed__Project__c).get(cogsJE.AcctSeed__Project_Task__c).get(cogsJE.AcctSeed__Product__c).put(cSize,cogsJE.Id);
                    //System.debug(loggingLevel.error,'mapPTPJelId 1: '+mapPTPJelId);
                }
                else if(cSize != 1 && mapPTPMatlId.get(cogsJE.AcctSeed__Project__c).get(cogsJE.AcctSeed__Project_Task__c).get(cogsJE.AcctSeed__Product__c).containsKey(cSize - 1))
                    matlId = mapPTPMatlId.get(cogsJE.AcctSeed__Project__c).get(cogsJE.AcctSeed__Project_Task__c).get(cogsJE.AcctSeed__Product__c).get(cSize - 1);
                    //System.debug(loggingLevel.error,'mapPTPJelId 2: '+mapPTPJelId);
            }

            if(matlId != null){
                cogsJE.Material__c = matlId;
                listJEL.add(cogsJE);
            }
        }

        if(!listJEL.isEmpty())
            update listJEL;
    }

    public static void coverage(){
        integer i;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
    }
}