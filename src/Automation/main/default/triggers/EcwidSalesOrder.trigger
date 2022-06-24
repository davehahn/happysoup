/**
 * Created by Legend on 16/5/22.
 */

trigger EcwidSalesOrder on Ecwid_Sales_Order__e (after insert)
{
    new MetadataTriggerHandler().run();
}