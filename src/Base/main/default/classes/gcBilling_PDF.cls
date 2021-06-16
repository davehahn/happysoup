global without sharing class gcBilling_PDF{

	global gcBilling_PDF(ApexPages.StandardController c){

		bill = (AcctSeed__Billing__c)(c.getRecord());

		init();
	}

	global transient AcctSeed__Billing__c bill{get;set;}
	global transient List<Map<String,String>> polList{get;set;}

	global void init()
	{

		bill =	[SELECT Id, 
						Name,
						CreatedDate,
						AcctSeed__Date__c,
						AcctSeed__Due_Date2__c,
						AcctSeed__Billing_City__c,
						AcctSeed__Billing_Contact__c,
						AcctSeed__Billing_PostalCode__c,
						AcctSeed__Billing_Country__c,
						AcctSeed__Billing_Street__c,
						AcctSeed__Billing_State__c,
						AcctSeed__Shipping_City__c,						
						AcctSeed__Shipping_Country__c,
						AcctSeed__Shipping_PostalCode__c,
						AcctSeed__Shipping_State__c,
						AcctSeed__Shipping_Street__c,
						AcctSeed__Customer__c,
						AcctSeed__Customer__r.Name,
						AcctSeed__Customer__r.AcctSeed__Shipping_Contact__c,
						AcctSeed__Customer__r.AcctSeed__Shipping_Contact__r.Name,
						AcctSeed__Total__c,
						AcctSeed__Billing_Comment__c,
						Owner.Name,
						(SELECT Id,
								AcctSeed__GL_Account_Variable_1__r.Name,
								AcctSeed__GL_Account_Variable_2__r.Name,
								AcctSeed__GL_Account_Variable_3__r.Name,
								AcctSeed__GL_Account_Variable_4__r.Name,																								
								AcctSeed__Product__c,
								AcctSeed__Product__r.Name,
								AcctSeed__Product__r.Description,
								AcctSeed__Product__r.ProductCode,
								AcctSeed__Product__r.Unique_Product_Code__c,
								AcctSeed__Product__r.Product_Type__c,
								AcctSeed__Hours_Units__c,
								AcctSeed__Total__c,
		                        AcctSeed__Rate__c,
		                        AcctSeed__Comment__c
						 FROM AcctSeed__Project_Billing_Lines__r
						 ORDER BY AcctSeed__Product__r.Name)
				 FROM AcctSeed__Billing__c
				 WHERE Id = :bill.Id][0];

		if(!bill.AcctSeed__Project_Billing_Lines__r.isEmpty())
		{
			polList = new List<Map<String,String>>();
			for(AcctSeed__Billing_Line__c line : bill.AcctSeed__Project_Billing_Lines__r)
			{
				Map<String,String> m = new Map<String,String>();
				m.put('glv1', line.AcctSeed__GL_Account_Variable_1__r.Name == null?'':line.AcctSeed__GL_Account_Variable_1__r.Name);
				m.put('glv2', line.AcctSeed__GL_Account_Variable_2__r.Name == null?'':line.AcctSeed__GL_Account_Variable_2__r.Name);
				m.put('glv3', line.AcctSeed__GL_Account_Variable_3__r.Name == null?'':line.AcctSeed__GL_Account_Variable_3__r.Name);
				m.put('glv4', line.AcctSeed__GL_Account_Variable_4__r.Name == null?'':line.AcctSeed__GL_Account_Variable_4__r.Name);
				m.put('idProduct', line.AcctSeed__Product__c);
				m.put('productName', line.AcctSeed__Product__r.Name);
				m.put('productDescription', line.AcctSeed__Product__r.Description == null?'':line.AcctSeed__Product__r.Description);
				m.put('productCode', line.AcctSeed__Product__r.ProductCode == null?'':line.AcctSeed__Product__r.ProductCode);
				m.put('productUniqueCode', line.AcctSeed__Product__r.Unique_Product_Code__c == null?'':line.AcctSeed__Product__r.Unique_Product_Code__c);
				m.put('productType', line.AcctSeed__Product__r.Product_Type__c == null?'':line.AcctSeed__Product__r.Product_Type__c);
				m.put('quantity', String.valueOf((line.AcctSeed__Hours_Units__c == null?0:line.AcctSeed__Hours_Units__c).setScale(2)));
				m.put('totalAmount', String.valueOf((line.AcctSeed__Total__c == null?0:line.AcctSeed__Total__c).setScale(2)));
				m.put('unitPrice', String.valueOf((line.AcctSeed__Rate__c == null?0:line.AcctSeed__Rate__c).setScale(2)));
				m.put('comment', line.AcctSeed__Comment__c == null?'NoC':line.AcctSeed__Comment__c);

				polList.add(m);
			}
		}
	}


}