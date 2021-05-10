@isTest
private class ImportBatch_Test {
	
	@isTest static void test_method_one() {
		tempIAIUpdateProductWarehouseBatch.coverage();
		tempIAVUpdatOrCreateProduct.coverage();
		importUpdateWithInboundBatch.coverage();
		createAdjustmentFromImportBatch.coverage();
		createValueAdjustmentFromImportBatch.coverage();
	}
	
}