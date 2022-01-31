/**
 * Created by dhavalmacbook on 20/01/22.
 */

public inherited sharing class TA_DealerOrderLine_HandlePartnerProg_AU implements TriggerAction.AfterUpdate{

    public void afterUpdate(List<SObject> newList, List<SObject> oldList) {
        DealerOrderLine_Service.handlePartnerProgram (newList);
    }
}