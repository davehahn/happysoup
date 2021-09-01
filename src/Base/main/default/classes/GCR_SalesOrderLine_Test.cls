/**
 * Created by Legend on 31/8/21.
 */

@IsTest
private class GCR_SalesOrderLine_Test {
    @IsTest
    static void testBehavior() {
        GCR_SalesOrderLine.rollup(new Set<Id>());
    }
}