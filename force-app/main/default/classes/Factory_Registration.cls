@isTest
public with sharing class Factory_Registration {
	public static Registration__c buildRegistration(String byAccount,
																									String toAccount,
																									String serno) {
		return new Registration__c(
			Account__c = toAccount,
			RegisteredByAccount__c = byAccount,
			SerialNumber__c = serno
		);
	}

	public static Registration__c createRegistration(String account, String serno) {
		Registration__c reg = buildRegistration( account, account, serno);
		insert reg;
		return reg;
	}


}