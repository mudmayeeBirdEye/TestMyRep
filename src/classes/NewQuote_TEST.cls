/**
 * This class contains unit tests for validating the behavior of Apex classes
 */
@isTest
private class NewQuote_TEST {/*
	static PageReference pref;
	
	//test method for new quote page
    static testMethod void testMethod1() {
    	EntitlementEnable__c mycs = EntitlementEnable__c.getValues('IsEntitlementsEnabled__c');
              if(mycs == null) {
                mycs = new EntitlementEnable__c();
                mycs.IsEntitlementsEnabled__c = true;
                mycs.Name = 'IsEntitlementsEnabled';
                insert mycs;
            }
        // Create the quote object
        Account acc = Z_TestFactory.makeAccount();
        Opportunity opp = Z_TestFactory.makeOpportunity(acc);
        zqu__Quote__c quote = Z_TestFactory.makeQuote(opp);
        
        Test.startTest();
        pref = Page.NewQuote;
    	pref.getParameters().put('eid',opp.id);
    	pref.getParameters().put('quoteType','');
    	Test.setCurrentPage(pref);
    	
    	ApexPages.StandardController con = new ApexPages.StandardController(quote);
    	QuoteController objCont = new QuoteController(con); 
    	objCont.save();
    	objCont.cancel();
        Test.stopTest();
    }
    
    // test method for New Sales agreement Page
    static testMethod void testMethod2() {
    	EntitlementEnable__c mycs = EntitlementEnable__c.getValues('IsEntitlementsEnabled__c');
              if(mycs == null) {
                mycs = new EntitlementEnable__c();
                mycs.IsEntitlementsEnabled__c = true;
                mycs.Name = 'IsEntitlementsEnabled';
                insert mycs;
            }
        // Create the quote object
        Account acc = Z_TestFactory.makeAccount();
        Opportunity opp = Z_TestFactory.makeOpportunity(acc);
        zqu__Quote__c quote = Z_TestFactory.makeQuote(opp);
        
        Test.startTest();
        pref = Page.NewSalesAgreement;
    	pref.getParameters().put('eid',opp.id);
    	pref.getParameters().put('quoteType','salesAgreement');
    	Test.setCurrentPage(pref);
    	
    	ApexPages.StandardController con = new ApexPages.StandardController(quote);
    	QuoteController objCont = new QuoteController(con); 
    	objCont.save();
    	objCont.cancel();
        Test.stopTest();
    }
    
    
        // test method for ConvertToSalesAgreement Page
    static testMethod void testMethod3() {
    	EntitlementEnable__c mycs = EntitlementEnable__c.getValues('IsEntitlementsEnabled__c');
              if(mycs == null) {
                mycs = new EntitlementEnable__c();
                mycs.IsEntitlementsEnabled__c = true;
                mycs.Name = 'IsEntitlementsEnabled';
                insert mycs;
            }
        // Create the quote object
        Account acc = Z_TestFactory.makeAccount();
        Opportunity opp = Z_TestFactory.makeOpportunity(acc);
        zqu__Quote__c quote = Z_TestFactory.makeQuote(opp);
        
        Test.startTest();
        pref = Page.ConvertToSalesAgreement;
    	pref.getParameters().put('id',quote.id);
    	Test.setCurrentPage(pref);
    	
    	ApexPages.StandardController con = new ApexPages.StandardController(quote);
    	ConvertToSalesAgreementExtn objCont = new ConvertToSalesAgreementExtn(con); 
    	objCont.validateQuote();
    	objCont.back();
        Test.stopTest();
    }
    
        // Negative test method for ConvertToSalesAgreement Page
    static testMethod void testMethod4() {
    	EntitlementEnable__c mycs = EntitlementEnable__c.getValues('IsEntitlementsEnabled__c');
              if(mycs == null) {
                mycs = new EntitlementEnable__c();
                mycs.IsEntitlementsEnabled__c = true;  
                mycs.Name = 'IsEntitlementsEnabled';
                insert mycs;
            }
        // Create the quote object
        Account acc = Z_TestFactory.makeAccount();
        Opportunity opp = Z_TestFactory.makeOpportunity(acc);
        zqu__Quote__c quote = Z_TestFactory.makeQuote(opp);
        quote.zqu__StartDate__c = system.today();
        quote.zqu__InitialTerm__c = 12;
        quote.zqu__RenewalTerm__c = 12;
        update quote;
        Test.startTest();
        pref = Page.ConvertToSalesAgreement;
    	pref.getParameters().put('id',quote.id);
    	Test.setCurrentPage(pref);
    	
    	ApexPages.StandardController con = new ApexPages.StandardController(quote);
    	ConvertToSalesAgreementExtn objCont = new ConvertToSalesAgreementExtn(con); 
    	objCont.validateQuote();
    	objCont.back();
        Test.stopTest();
    }*/
}