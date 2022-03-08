/**
 * Created by dave on 2021-06-07.
 */

public inherited sharing class TA_ProductRequired_DeleteMaterials implements TriggerAction.BeforeDelete
{

  public static void beforeDelete(
    List<ProductRequired> oldList
  )
  {
    Material_ServiceFSL.deleteMaterials( oldList );
  }

}