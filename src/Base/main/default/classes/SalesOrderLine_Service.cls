public without sharing class SalesOrderLine_Service{
	public static Set<Id> productId_Set = new Set<Id>();
    public static Map<Id,Product2>mapProduct = new Map<Id,Product2>();
    
    public static void setTaxes(List<AcctSeedERP__Sales_Order_Line__c> salesOrderLine_list){
        for(AcctSeedERP__Sales_Order_Line__c sol :salesOrderLine_list){
            productId_Set.add(sol.AcctSeedERP__Product__c);
        }
        if(! productId_Set.isEmpty()){
            getProductDetails(productId_Set);
        }
        for(AcctSeedERP__Sales_Order_Line__c sol :salesOrderLine_list){
            if(mapProduct.containsKey(sol.AcctSeedERP__Product__c)){
                Product2 product = mapProduct.get(sol.AcctSeedERP__Product__c);
                sol.Taxable_Federal__c = product.Taxable__c;
                sol.Taxable_Provincial__c = product.Taxable__c;
                sol.Taxable_Retail__c = false;    
            }
        }
    }
    private static void getProductDetails(Set<Id> productId_Set){
        for(Product2 p :
				[SELECT Id,
						GMBLASERP__Lot_Tracked__c,
						AcctSeedERP__Serialized__c,
                 		RecordType.Name,
						Taxable__c
				 FROM Product2
				 WHERE Id IN :productId_Set])
			{
				mapProduct.put(p.Id,p);
			}
    }
    public static void updateSalesTax(set<Id> salesOrder_Id_Set)
        { 
        Id idProductSalesTaxFederal    = gcConstants.idProductSalesTaxFederal;
        Id idProductSalesTaxProvincial = gcConstants.idProductSalesTaxProvincial;
        Id idProductSalesTaxRetail = gcConstants.idProductSalesTaxRetail;
        Id idProductSalesTaxHarmonized = gcConstants.idProductSalesTaxHarmonized;
        Id idProductPrecisionFix = gcConstants.idProductPrecisionFix;
        Id idProductInternalLabour = gcConstants.idProductInternalLabour;
        Id idProductInternalBilling = gcConstants.idProductInternalBilling;
        Id idProductInternalBalance = gcConstants.idProductInternalBalance;
        String internalProductRecordTypeName = gcConstants.internalProductRecordTypeName;

        Id idGlv1HeadOfficeOverhead = gcConstants.idGlv1HeadOfficeOverhead;
        Id idGlInternalLabour = gcConstants.idGlInternalLabour;
        Id idGLInternalWarrantyClearing = gcConstants.idGLInternalWarrantyClearing;
        Id idGlv2Sales = gcConstants.idGlv2Sales;
        Id idGlv3Others = gcConstants.idGlv3Others;

        List<AcctSeedERP__Sales_Order_Line__c> salesOrderLine_List = new List<AcctSeedERP__Sales_Order_Line__c>();
        List<AcctSeedERP__Sales_Order_Line__c> salesOrderLine_ToBe_Deleted_List = new List<AcctSeedERP__Sales_Order_Line__c>();
        //List<AcctSeedERP__Sales_Order__c> salesOrder_List = SalesOrder_Selector.allBySalesOrderIdIncludingLineItems(salesOrder_Id_Set);
            System.debug('salesOrder_Id_Set = '+salesOrder_Id_Set);
            for(AcctSeedERP__Sales_Order__c salesOrder :
                [SELECT Id,
                        GL_Account_Variable_3__c,
                        Tax_is_Harmonized__c,
                        Tax_Rate_Federal__c,
                        Tax_Rate_Provincial__c,
                        Tax_Rate_Retail__c,
                        Revenue__c,
                        Expense__c,
                        Profit__c,
                    (SELECT Id,
                     
                        AcctSeedERP__GL_Account_Variable_1__c,
                        AcctSeedERP__GL_Account_Variable_2__c,
                        AcctSeedERP__GL_Account_Variable_3__c,
                        AcctSeedERP__Product__c,
                        AcctSeedERP__Product__r.RecordType.Name,
                        AcctSeedERP__Total__c,
                        AcctSeedERP__Unit_Price__c,
                        Taxable_Federal__c,
                        Taxable_Provincial__c,
                        Taxable_Retail__c,
                        GMBLASERP__Serial_Number__c,
                        GMBLASERP__Revenue__c,
                        Review_Price__c,
                        AcctSeedERP__Quantity_Ordered__c
            
                    FROM AcctSeedERP__Sales_Order_Line__r
                    ORDER BY CreatedDate)
                FROM AcctSeedERP__Sales_Order__c
                WHERE Id IN :salesOrder_Id_Set
                    AND AcctSeedERP__Status__c != 'Posted'])
        //for(AcctSeedERP__Sales_Order__c salesOrder :salesOrder_List)        
        {
            System.debug('in loop');
            AcctSeedERP__Sales_Order_Line__c taxLineFederal;
            AcctSeedERP__Sales_Order_Line__c taxLineProvincial;
            AcctSeedERP__Sales_Order_Line__c taxLineRetail;
            AcctSeedERP__Sales_Order_Line__c taxLineHarmonized;
            AcctSeedERP__Sales_Order_Line__c lineProductPrecisionFix;
            AcctSeedERP__Sales_Order_Line__c lineInternalBillingRevenue;
            AcctSeedERP__Sales_Order_Line__c lineInternalBillingBalance;
            AcctSeedERP__Sales_Order_Line__c lineInternalWarrantyBalance;
            Map<Id,AcctSeed__Billing_Line__c> mapTaskLabour = new Map<Id,AcctSeed__Billing_Line__c>();

            Decimal taxRateFederal = (salesOrder.Tax_Rate_Federal__c == null ? 0 : salesOrder.Tax_Rate_Federal__c)/100;
            Decimal taxRateProvincial = (salesOrder.Tax_Rate_Provincial__c == null ? 0 : salesOrder.Tax_Rate_Provincial__c)/100;
            Decimal taxRateRetail = (salesOrder.Tax_Rate_Retail__c == null ? 0 : salesOrder.Tax_Rate_Retail__c)/100;
            Decimal taxRateHarmonized = (salesOrder.Tax_is_Harmonized__c == true ? (taxRateFederal + taxRateProvincial) : 0);
            System.debug('taxRateFederal= '+taxRateFederal);
            System.debug('taxRateProvincial= '+taxRateProvincial);
            System.debug('taxRateHarmonized= '+taxRateHarmonized);
            System.debug('salesOrder.Tax_is_Harmonized__c= '+salesOrder.Tax_is_Harmonized__c);
            if(salesOrder.Tax_is_Harmonized__c)
            {
                taxRateFederal = 0;
                taxRateProvincial = 0;
            }

            Decimal taxableAmountFederal = 0;
            Decimal taxableAmountProvincial = 0;
            Decimal taxableAmountRetail = 0;
            Decimal taxableAmountHarmonized = 0;
            Decimal totalLineAmount = 0;
            Decimal totalSerialRevenue = 0;
            Map<Id,Decimal> mapTotalLabour = new Map<Id,Decimal>();
            //Decimal totalLabour = 0;
            for(AcctSeedERP__Sales_Order_Line__c bl : salesOrder.AcctSeedERP__Sales_Order_Line__r)
            {
                
                System.debug('bl.AcctSeedERP__Product__c= '+bl.AcctSeedERP__Product__c);
                System.debug('idProductSalesTaxHarmonized= '+idProductSalesTaxHarmonized);
                
                if(bl.AcctSeedERP__Product__c == idProductSalesTaxHarmonized)
                {
                    if(taxRateHarmonized == 0 || taxLineHarmonized != null)
                        salesOrderLine_ToBe_Deleted_List.add(bl);
                    else
                        taxLineHarmonized = bl;
                    continue;
                }
                
                System.debug('bl.AcctSeedERP__Total__c = '+bl.AcctSeedERP__Total__c );
                System.debug('totalLineAmount before='+totalLineAmount);
                totalLineAmount += (bl.AcctSeedERP__Total__c == null ? 0 : bl.AcctSeedERP__Total__c);
                System.debug('totalLineAmount='+totalLineAmount);
                
                if(bl.Taxable_Federal__c)
                    taxableAmountFederal += (bl.AcctSeedERP__Total__c == null ? 0 : bl.AcctSeedERP__Total__c);
                if(bl.Taxable_Provincial__c)
                    taxableAmountProvincial += (bl.AcctSeedERP__Total__c == null ? 0 : bl.AcctSeedERP__Total__c);
                if(bl.Taxable_Provincial__c || bl.Taxable_Federal__c)
                    taxableAmountHarmonized += (bl.AcctSeedERP__Total__c == null ? 0 : bl.AcctSeedERP__Total__c);
                if(bl.Taxable_Retail__c)
                    taxableAmountRetail += (bl.AcctSeedERP__Total__c == null ? 0 : bl.AcctSeedERP__Total__c);

                System.debug('taxableAmountFederal= '+taxableAmountFederal);
                System.debug('taxableAmountProvincial= '+taxableAmountProvincial);
                System.debug('taxableAmountHarmonized= '+taxableAmountHarmonized);
                System.debug('taxableAmountRetail= '+taxableAmountRetail);
                if(bl.AcctSeedERP__GL_Account_Variable_3__c != salesOrder.GL_Account_Variable_3__c)
                {
                    bl.AcctSeedERP__GL_Account_Variable_3__c = salesOrder.GL_Account_Variable_3__c;
                    salesOrderLine_List.add(bl);
                }

                
            }

            if(taxableAmountFederal == 0)
            {
                if(taxLineFederal != null)
                    salesOrderLine_ToBe_Deleted_List.add(taxLineFederal);
            }
            else
            {
                if(taxRateFederal != 0)
                {
                    if(taxLineFederal != null)
                    {
                        if(taxLineFederal.AcctSeedERP__Quantity_Ordered__c != taxRateFederal.setScale(5) ||
                           taxLineFederal.AcctSeedERP__Unit_Price__c  != taxableAmountFederal.setScale(2) ||
                           taxLineFederal.AcctSeedERP__GL_Account_Variable_3__c != salesOrder.GL_Account_Variable_3__c ||
                           taxLineFederal.AcctSeedERP__GL_Account_Variable_3__c == null ||
                           taxLineFederal.Taxable_Federal__c == true)
                        {
                            taxLineFederal.AcctSeedERP__Quantity_Ordered__c = taxRateFederal.setScale(5);
                            taxLineFederal.AcctSeedERP__Unit_Price__c  = taxableAmountFederal.setScale(2);
                            if(taxLineFederal.AcctSeedERP__GL_Account_Variable_3__c == null)
                                taxLineFederal.AcctSeedERP__GL_Account_Variable_3__c = salesOrder.GL_Account_Variable_3__c;
                            taxLineFederal.Taxable_Federal__c = false;
                            salesOrderLine_List.add(taxLineFederal);
                        }
                    }
                    else
                    {
                        taxLineFederal = new AcctSeedERP__Sales_Order_Line__c(
                            AcctSeedERP__Sales_Order__c = salesOrder.Id,
                            AcctSeedERP__GL_Account_Variable_3__c = salesOrder.GL_Account_Variable_3__c,
                            AcctSeedERP__Product__c = idProductSalesTaxFederal,
                            AcctSeedERP__Quantity_Ordered__c = taxRateFederal.setScale(5),
                            AcctSeedERP__Unit_Price__c  = taxableAmountFederal.setScale(2),
                            Taxable_Federal__c = false
                        );
                        salesOrderLine_List.add(taxLineFederal);
                    }
                    totalLineAmount += (taxRateFederal.setScale(5) * taxableAmountFederal.setScale(2)).setScale(2);
                }
            }

            if(taxableAmountProvincial == 0)
            {
                if(taxLineProvincial != null)
                    salesOrderLine_ToBe_Deleted_List.add(taxLineProvincial);
            }
            else
            {
                if(taxRateProvincial != 0)
                {
                    if(taxLineProvincial != null)
                    {
                        
                        if(taxLineProvincial.AcctSeedERP__Quantity_Ordered__c != taxRateProvincial.setScale(5) ||
                           taxLineProvincial.AcctSeedERP__Unit_Price__c  != taxableAmountProvincial.setScale(2) ||
                           taxLineProvincial.AcctSeedERP__GL_Account_Variable_3__c != salesOrder.GL_Account_Variable_3__c ||
                           taxLineProvincial.AcctSeedERP__GL_Account_Variable_3__c == null ||
                           taxLineProvincial.Taxable_Provincial__c == true)
                        {
                            taxLineProvincial.AcctSeedERP__Quantity_Ordered__c = taxRateProvincial.setScale(5);
                            taxLineProvincial.AcctSeedERP__Unit_Price__c  = taxableAmountProvincial.setScale(2);
                            if(taxLineProvincial.AcctSeedERP__GL_Account_Variable_3__c == null)
                                taxLineProvincial.AcctSeedERP__GL_Account_Variable_3__c = salesOrder.GL_Account_Variable_3__c;
                            taxLineProvincial.Taxable_Provincial__c = false;
                            salesOrderLine_List.add(taxLineProvincial);
                        }
                    }
                    else
                    {
                        taxLineProvincial = new AcctSeedERP__Sales_Order_Line__c(
                            AcctSeedERP__Sales_Order__c = salesOrder.Id,
                            AcctSeedERP__GL_Account_Variable_3__c = salesOrder.GL_Account_Variable_3__c,
                            AcctSeedERP__Product__c = idProductSalesTaxProvincial,
                            AcctSeedERP__Quantity_Ordered__c = taxRateProvincial.setScale(5),
                            AcctSeedERP__Unit_Price__c  = taxableAmountProvincial.setScale(2),
                            Taxable_Provincial__c = false
                        );
                        salesOrderLine_List.add(taxLineProvincial);
                    }
                    totalLineAmount += (taxRateProvincial.setScale(5) * taxableAmountProvincial.setScale(2)).setScale(2);
                }
            }

            if(taxableAmountRetail == 0)
            {
                if(taxLineRetail != null)
                    salesOrderLine_ToBe_Deleted_List.add(taxLineRetail);
            }
            else
            {
                if(taxRateRetail != 0)
                {
                    if(taxLineRetail != null)
                    {
                        if(taxLineRetail.AcctSeedERP__Quantity_Ordered__c != taxRateRetail.setScale(5) ||
                           taxLineRetail.AcctSeedERP__Unit_Price__c  != taxableAmountRetail.setScale(2) ||
                           taxLineRetail.AcctSeedERP__GL_Account_Variable_3__c != salesOrder.GL_Account_Variable_3__c ||
                           taxLineRetail.AcctSeedERP__GL_Account_Variable_3__c == null ||
                           taxLineRetail.Taxable_Retail__c == true)
                        {
                            taxLineRetail.AcctSeedERP__Quantity_Ordered__c = taxRateRetail.setScale(5);
                            taxLineRetail.AcctSeedERP__Unit_Price__c  = taxableAmountRetail.setScale(2);
                            if(taxLineRetail.AcctSeedERP__GL_Account_Variable_3__c == null)
                                taxLineRetail.AcctSeedERP__GL_Account_Variable_3__c = salesOrder.GL_Account_Variable_3__c;
                            taxLineRetail.Taxable_Retail__c = false;
                            salesOrderLine_List.add(taxLineRetail);
                        }
                    }
                    else
                    {
                        taxLineRetail = new AcctSeedERP__Sales_Order_Line__c(
                            AcctSeedERP__Sales_Order__c = salesOrder.Id,
                            AcctSeedERP__Product__c = idProductSalesTaxRetail,
                            AcctSeedERP__Quantity_Ordered__c = taxRateRetail.setScale(5),
                            AcctSeedERP__Unit_Price__c = taxableAmountRetail.setScale(2),
                            AcctSeedERP__GL_Account_Variable_3__c = salesOrder.GL_Account_Variable_3__c,
                            Taxable_Retail__c = false
                        );
                        salesOrderLine_List.add(taxLineRetail);
                    }
                    totalLineAmount += (taxRateRetail.setScale(5) * taxableAmountRetail.setScale(2)).setScale(2);
                }
            }
            System.debug('taxableAmountHarmonized= '+taxableAmountHarmonized);
            if(taxableAmountHarmonized == 0)
            {
                if(taxLineHarmonized != null)
                    salesOrderLine_ToBe_Deleted_List.add(taxLineHarmonized);
            }
            else
            {
                if(taxRateHarmonized != 0)
                {
                    if(taxLineHarmonized != null)
                    { 
                        if(taxLineHarmonized.AcctSeedERP__Quantity_Ordered__c != taxRateHarmonized.setScale(5) ||
                           taxLineHarmonized.AcctSeedERP__Unit_Price__c  != taxableAmountHarmonized.setScale(2) ||
                           taxLineHarmonized.AcctSeedERP__GL_Account_Variable_3__c != salesOrder.GL_Account_Variable_3__c ||
                           taxLineHarmonized.AcctSeedERP__GL_Account_Variable_3__c == null ||
                           taxLineHarmonized.Taxable_Provincial__c == true)
                        {
                            taxLineHarmonized.AcctSeedERP__Quantity_Ordered__c = taxRateHarmonized.setScale(5);
                            taxLineHarmonized.AcctSeedERP__Unit_Price__c  = taxableAmountHarmonized.setScale(2);
                            if(taxLineHarmonized.AcctSeedERP__GL_Account_Variable_3__c == null)
                                taxLineHarmonized.AcctSeedERP__GL_Account_Variable_3__c = salesOrder.GL_Account_Variable_3__c;
                            taxLineHarmonized.Taxable_Provincial__c = false;
                            salesOrderLine_List.add(taxLineHarmonized);
                        }
                    }
                    else
                    {
                        System.debug('@@ in else');
                        taxLineHarmonized = new AcctSeedERP__Sales_Order_Line__c(
                            AcctSeedERP__Sales_Order__c = salesOrder.Id,
                            AcctSeedERP__Product__c = idProductSalesTaxHarmonized,
                            AcctSeedERP__Quantity_Ordered__c = taxRateHarmonized.setScale(5),
                            AcctSeedERP__Unit_Price__c  = taxableAmountHarmonized.setScale(2),
                            AcctSeedERP__GL_Account_Variable_3__c = salesOrder.GL_Account_Variable_3__c,
                            Taxable_Provincial__c = false
                        );
                        salesOrderLine_List.add(taxLineHarmonized);
                    }
                    totalLineAmount += (taxRateHarmonized.setScale(5) * taxableAmountHarmonized.setScale(2)).setScale(2);
                }
            }

            Decimal actualValue = totalLineAmount.setScale(6);
            Decimal acctSeedValue = totalLineAmount.setScale(2,System.RoundingMode.HALF_UP);
            Decimal currentPrecision = (acctSeedValue - actualValue).setScale(6);
            if(currentPrecision != 0)
            {
                //if(currentPrecision < 0.005) currentPrecision = currentPrecision * -1;
                if(lineProductPrecisionFix != null)
                {
                    lineProductPrecisionFix.AcctSeedERP__Quantity_Ordered__c = 1;
                    lineProductPrecisionFix.AcctSeedERP__Unit_Price__c  = currentPrecision;
                    lineProductPrecisionFix.Taxable_Federal__c = false;
                    lineProductPrecisionFix.Taxable_Provincial__c = false;
                    lineProductPrecisionFix.Taxable_Retail__c = false;
                    salesOrderLine_List.add(lineProductPrecisionFix);
                }
                else
                {
                    lineProductPrecisionFix = new AcctSeedERP__Sales_Order_Line__c(
                        AcctSeedERP__Sales_Order__c = salesOrder.Id,
                        AcctSeedERP__GL_Account_Variable_3__c = idGlv3Others,
                        AcctSeedERP__Product__c = idProductPrecisionFix,
                        AcctSeedERP__Quantity_Ordered__c = 1,
                        AcctSeedERP__Unit_Price__c  = currentPrecision,
                        Taxable_Federal__c = false,
                        Taxable_Provincial__c = false,
                        Taxable_Retail__c = false
                    );
                    salesOrderLine_List.add(lineProductPrecisionFix);
                }
            }
            else
            {
                if(lineProductPrecisionFix != null)
                    salesOrderLine_ToBe_Deleted_List.add(lineProductPrecisionFix);
            }

            
        }
            
            
        System.debug('salesOrderLine_ToBe_Deleted_List= '+salesOrderLine_ToBe_Deleted_List);
        System.debug('salesOrderLine_List= '+salesOrderLine_List);
        if(!salesOrderLine_ToBe_Deleted_List.isEmpty() || !salesOrderLine_List.isEmpty())
        {
            TriggerBase.bypass('AcctSeedERP__Sales_Order__c');
            TriggerBase.bypass('AcctSeedERP__Sales_Order_Line__c');
            if (!salesOrderLine_ToBe_Deleted_List.isEmpty())
                delete salesOrderLine_ToBe_Deleted_List;
            if (!salesOrderLine_List.isEmpty())
                upsert salesOrderLine_List;
            TriggerBase.clearAllBypasses();
        }
    }

    /// Product Kitting
    public static void insertKitParts(set<Id> setIdsolKit)
    {
        list<AcctSeedERP__Sales_Order_Line__c> listSOLKit = new list<AcctSeedERP__Sales_Order_Line__c>();
        map<Id,Product2> mapKit = new map<Id,Product2>();
        list<AcctSeedERP__Sales_Order_Line__c> listSOLComp = new list<AcctSeedERP__Sales_Order_Line__c>();

        for(AcctSeedERP__Sales_Order_Line__c solKit :
        [SELECT Id,
                AcctSeedERP__Sales_Order__c,
                AcctSeedERP__Sales_Order__r.GL_Account_Variable_1__c,
                AcctSeedERP__Sales_Order__r.GL_Account_Variable_2__c,
                AcctSeedERP__Sales_Order__r.GL_Account_Variable_3__c,
                AcctSeedERP__Product__c,
                AcctSeedERP__Project__c,
                AcctSeedERP__Project_Task__c,
                AcctSeedERP__Quantity_Ordered__c,
                Part_Quantity_Specified_Multiplier__c
        FROM AcctSeedERP__Sales_Order_Line__c
        WHERE Id IN :setIdsolKit
        AND AcctSeedERP__Product__r.Composite_Type__c = 'Kit'
        AND AcctSeedERP__Product__r.RecordTypeId != :LGND_Constants.productRtId_Bundle])
        {
            if(!mapKit.containsKey(solKit.AcctSeedERP__Product__c))
                mapKit.put(solKit.AcctSeedERP__Product__c,null);

            listSOLKit.add(solKit);
        }
        for(Product2 kit :
        [SELECT Id,
        (SELECT Id,
                AcctSeed__Product__c,
                AcctSeed__Product_Part__c,
                AcctSeed__Quantity__c
        FROM AcctSeed__Product_Parts__r
        WHERE AcctSeed__Product__r.RecordTypeId != :LGND_Constants.productRtId_Bundle)
        FROM Product2
        WHERE Id In :mapKit.keySet()
        AND RecordTypeId != :LGND_Constants.productRtId_Bundle])
        {
            mapKit.put(kit.Id,kit);
        }

        for(AcctSeedERP__Sales_Order_Line__c solKit : listSOLKit)
        {
            Product2 kit = mapKit.get(solKit.AcctSeedERP__Product__c);

            for(AcctSeed__Product_Part__c comp : kit.AcctSeed__Product_Parts__r)
            {
                listSOLComp.add(new AcctSeedERP__Sales_Order_Line__c(
                        AcctSeedERP__Product__c = comp.AcctSeed__Product_Part__c,
                        Sales_Order_Line__c = solKit.Id,
                        GMBLASERP__Price_Override__c = true,
                        AcctSeedERP__Unit_Price__c = 0,
                        AcctSeedERP__Sales_Order__c = solKit.AcctSeedERP__Sales_Order__c,
                        AcctSeedERP__Project__c = solKit.AcctSeedERP__Project__c,
                        AcctSeedERP__Project_Task__c = solKit.AcctSeedERP__Project_Task__c,
                        AcctSeedERP__GL_Account_Variable_1__c = solKit.AcctSeedERP__Sales_Order__r.GL_Account_Variable_1__c,
                        AcctSeedERP__GL_Account_Variable_2__c = solKit.AcctSeedERP__Sales_Order__r.GL_Account_Variable_2__c,
                        Part_Quantity_Specified_Multiplier__c = (comp.AcctSeed__Quantity__c == null ? 0 : comp.AcctSeed__Quantity__c),
                        AcctSeedERP__Quantity_Ordered__c = (comp.AcctSeed__Quantity__c == null ? 0 : comp.AcctSeed__Quantity__c) * (solKit.AcctSeedERP__Quantity_Ordered__c == null ? 0 : solKit.AcctSeedERP__Quantity_Ordered__c)
                ));
            }
        }

        if(!listSOLComp.isEmpty())
        {
            MetadataTriggerHandler.bypass('TA_SalesOrderLine_KIT_AI');
            MetadataTriggerHandler.bypass('TA_SalesOrderLine_KIT_AU');
            insert listSOLComp;
            MetadataTriggerHandler.clearBypass('TA_SalesOrderLine_KIT_AI');
            MetadataTriggerHandler.clearBypass('TA_SalesOrderLine_KIT_AU');
        }
    }

    public static void cascadeDeleteKitMaterial(set<Id> setIdMatl)
    {
        setIdMatl.remove(null);
        if(!setIdMatl.isEmpty())
        {
            MetadataTriggerHandler.bypass('TA_SalesOrderLine_KIT_BD');
            delete [SELECT Id FROM AcctSeedERP__Sales_Order_Line__c WHERE Sales_Order_Line__c IN :setIdMatl AND Id NOT IN:setIdMatl];
            MetadataTriggerHandler.clearBypass('TA_SalesOrderLine_KIT_BD');
        }
    }

    public static void updateMaterialSpec(set<Id> setIdsolKit)
    {
        setIdsolKit.remove(null);
        if(setIdsolKit.isEmpty()) return;

        list<AcctSeedERP__Sales_Order_Line__c> listSOL = new list<AcctSeedERP__Sales_Order_Line__c>();

        for(AcctSeedERP__Sales_Order_Line__c matl :
        [SELECT Id,
                Sales_Order_Line__r.AcctSeedERP__Quantity_Ordered__c,
                AcctSeedERP__Quantity_Ordered__c,
                Part_Quantity_Specified_Multiplier__c
        FROM AcctSeedERP__Sales_Order_Line__c
        WHERE Sales_Order_Line__c IN :setIdsolKit])
        {
            Decimal qtySpecified = (matl.Sales_Order_Line__r.AcctSeedERP__Quantity_Ordered__c == null ? 0 : matl.Sales_Order_Line__r.AcctSeedERP__Quantity_Ordered__c) * (matl.Part_Quantity_Specified_Multiplier__c == null ? 0 : matl.Part_Quantity_Specified_Multiplier__c);
            qtySpecified = qtySpecified.setScale(6);

            if(matl.AcctSeedERP__Quantity_Ordered__c == null || matl.AcctSeedERP__Quantity_Ordered__c.setScale(6) != qtySpecified)
            {
                matl.AcctSeedERP__Quantity_Ordered__c = qtySpecified;
                listSOL.add(matl);
            }
        }

        if(!listSOL.isEmpty())
        {
            MetadataTriggerHandler.bypass('TA_SalesOrderLine_BU');
            update listSOL;
            MetadataTriggerHandler.clearBypass('TA_SalesOrderLine_BU');
        }
    }
    
}
