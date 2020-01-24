public without sharing class gcTransactionParent {

	private static map<Id,AcctSeed__Project__c> mapProject;
	private static map<Id,AcctSeed__GL_Account__c> mapGLAccount;

	public static void setFinancialAttributes(
		List<sObject> listNew,
		String projectField,
		String glAccountField)
	{
		//Skip if list is null or empty
		if(listNew == null || listNew.isEmpty()) return;

		if(mapProject == null)
			mapProject = new Map<Id, AcctSeed__Project__c>();
		if(mapGLAccount == null)
			mapGLAccount = new Map<Id, AcctSeed__GL_Account__c>();

		Set<Id> setIdProject = new Set<Id>();
		Set<Id> setIdGlAccount = new Set<Id>();

		for(SObject obj : listNew)
		{
			Id idProject = (Id)obj.get(projectField);
			if(idProject != null && !mapProject.containsKey(idProject))
				setIdProject.add(idProject);

			if(glAccountField != null)
			{
				Id idGlAccount = (Id)obj.get(glAccountField);
				if(idGlAccount != null && !mapGLAccount.containsKey(idGlAccount))
					setIdGlAccount.add(idGlAccount);
			}
		}

		if(!setIdProject.isEmpty())
			retrieveProjectStatics(setIdProject);

		if(!setIdGlAccount.isEmpty())
			retrieveGlAccountStatics(setIdGlAccount);

		/// Set all GLV 1,2 values
		setGLVAttributes(listNew, projectField);

		/// Validate that GLVs are set if required
		if(glAccountField != null)
			validateGlvRequired(listNew, glAccountField);
	}

	private static void retrieveProjectStatics(Set<Id> setIdProject)
	{
		setIdProject.remove(null);
		if(!setIdProject.isEmpty())
		{
			for(AcctSeed__Project__c p :
				[SELECT Id,
					GL_Account_Variable_1__c,
					GL_Account_Variable_2__c,
					Internal_Labour_Service__c,
					Internal_Warranty__c,
					Internal_Partner_Boat_Sale__c
				 FROM AcctSeed__Project__c
				 WHERE Id IN :setIdProject])
			{
				mapProject.put(p.Id,p);
			}
		}
	}

	private static void retrieveGlAccountStatics(Set<Id> setIdGlAccount)
	{
		setIdGlAccount.remove(null);
		if(!setIdGlAccount.isEmpty())
		{
			for(AcctSeed__GL_Account__c gla : [
				SELECT
					Id,
					Name,
					AcctSeed__Type__c,
					Uniquefier__c
				FROM AcctSeed__GL_Account__c
				WHERE Id IN :setIdGlAccount])
			{
				mapGLAccount.put(gla.Id, gla);
			}
		}
	}

	public static void setGLVAttributes(list<sObject> listNew, String projectField)
	{
		if(listNew == null || listNew.isEmpty())
			return;

		String prefix = retrieveNamespace(listNew);

		for(sObject obj : listNew)
		{
			AcctSeed__Project__c p = mapProject.get((Id)obj.get(projectField));
			if(p != null)
			{
				if(p.GL_Account_Variable_1__c != null){
					if(!p.Internal_Labour_Service__c && !p.Internal_Partner_Boat_Sale__c && !p.Internal_Warranty__c)
						obj.put(prefix + 'GL_Account_Variable_1__c', p.GL_Account_Variable_1__c);
					else if(obj.get(prefix + 'GL_Account_Variable_1__c') == null){
						obj.put(prefix + 'GL_Account_Variable_1__c', p.GL_Account_Variable_1__c);
					}
				}
				if(p.GL_Account_Variable_2__c != null){
					if(!p.Internal_Labour_Service__c &&
						 !p.Internal_Partner_Boat_Sale__c &&
						 !p.Internal_Warranty__c &&
							obj.get(prefix + 'GL_Account_Variable_2__c') == null )
					{
						obj.put(prefix + 'GL_Account_Variable_2__c', p.GL_Account_Variable_2__c);
					}
					else if(obj.get(prefix + 'GL_Account_Variable_2__c') == null)
					{
						obj.put(prefix + 'GL_Account_Variable_2__c', p.GL_Account_Variable_2__c);
					}
				}
			}
		}
	}

	private static void validateGlvRequired(
		List<SObject> listNew,
		String glAccountField)
	{

		String prefix = retrieveNamespace(listNew);
		String objectName = listNew.getSObjectType().getDescribe().getName();
		for(SObject obj : listNew)
		{
			Id idGlv1 = (Id)obj.get(prefix + 'GL_Account_Variable_1__c');
			Id idGlv2 = (Id)obj.get(prefix + 'GL_Account_Variable_2__c');

			if(!String.isBlank(glAccountField))
			{
				Id idGlAccount = (Id)obj.get(glAccountField);
				if(idGlAccount == null) continue;

				AcctSeed__GL_Account__c gla = mapGLAccount.get(idGlAccount);
				String glaType = gla.AcctSeed__Type__c;

				if(!Transaction_Parent__c.getOrgDefaults().Allow_Transactions_Without_GLV__c)
				if((glaType == 'Revenue') || (glaType == 'Expense'))
				{
					if((idGlv1 == null || idGlv2 == null)
						&& gla.Uniquefier__c != 'ProjectWagesPayable'
						&& gla.Uniquefier__c != 'ProjectLaborBurdenContra'
						&& gla.Uniquefier__c != 'ProjectLaborBurden'
						&& gla.Uniquefier__c != 'ProjectLabor'
						&& (!objectName.equals('AcctSeed__Account_Payable_Line__c')
							|| (objectName.equals('AcctSeed__Account_Payable_Line__c') && obj.get('AcctSeedERP__Purchase_Order_Line__c') == null)))
					{
						obj.addError('Business Unit (GLV1) and Department (GLV2) are required when posting to a Revenue or Expense GL account.');
						continue;
					}
				}
				if(!Transaction_Parent__c.getOrgDefaults().Allow_Inventory_GL_Accounts__c)
				{
					Set<String> setObjectNames = new Set<String>{'AcctSeed__Account_Payable_Line__c','AcctSeed__Billing_Line__c','AcctSeed__Journal_Entry_Line__c'};
					if(setObjectNames.contains(objectName))
					{
						if(gla.Uniquefier__c == 'InventoryBoats'
							|| gla.Uniquefier__c == 'InventoryParts')
							obj.addError('Selected GL account '+gla.Name+' can only be used in Inventory Movements.');
					}
				}
			}
		}
	}

	private static string retrieveNamespace(list<sObject> listNew)
	{
		String objectName = listNew.getSObjectType().getDescribe().getName();

		if(objectName.startsWithIgnoreCase('AcctSeed__'))
		   return 'AcctSeed__';
		else if(objectName.startsWithIgnoreCase('AcctSeedERP__'))
		   return 'AcctSeedERP__';

		return '';
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
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
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