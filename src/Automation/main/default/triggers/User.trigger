/**
 * Created by dhavalmacbook on 03/01/22.
 */

trigger User on User (before insert,
        before update,
        before delete,
        after insert,
        after update,
        after delete,
        after undelete )
{
    new MetadataTriggerHandler().run();
}