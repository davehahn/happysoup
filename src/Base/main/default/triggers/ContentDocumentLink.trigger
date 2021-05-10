/**
 * Created by dave on 2019-12-31.
 */

trigger ContentDocumentLink on ContentDocumentLink (before insert,
                                                    before update,
                                                    before delete,
                                                    after insert,
                                                    after update,
                                                    after delete,
                                                    after undelete)
{
  new ContentDocumentLink_TriggerHandler().run();
}