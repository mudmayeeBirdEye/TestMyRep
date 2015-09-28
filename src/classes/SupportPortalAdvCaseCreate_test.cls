/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class SupportPortalAdvCaseCreate_test {
	static{
		List<Portals_List__c> lstPortal = new List<Portals_List__c>();
		lstPortal.add(new Portals_List__c(Name = 'success.ringcentral.com', Brand__c = 'RC US'));
		insert lstPortal;
		
		List<Product_Assistance_List__c> lstProductAss = new List<Product_Assistance_List__c>();
		lstProductAss.add(new Product_Assistance_List__c(Name = 'Company Settings', Portal__c = 'RC US, RC CA, RC UK, BT'));
		insert lstProductAss;
		
		TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = true;
    	TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = true;
    	TriggerHandler.BY_PASS_CONTACT_ON_INSERT = true;
    	TriggerHandler.BY_PASS_CONTACT_ON_UPDATE = true;
    	TriggerHandler.BY_PASS_CASE_ON_INSERT = true;
    	TriggerHandler.BY_PASS_CASE_ON_UPDATE = true;
	}
	
    static testMethod void myUnitTest() {
        // TO DO: implement unit test
        
        	EntitlementEnable__c mycs = EntitlementEnable__c.getValues('IsEntitlementsEnabled__c');
			  if(mycs == null) {
			    mycs = new EntitlementEnable__c();
			    mycs.IsEntitlementsEnabled__c = true;
			    mycs.Name = 'IsEntitlementsEnabled';
			    insert mycs;
		  	}
		  	
		  	Account acctest = new Account(RC_Brand__c = 'test');
            acctest.Name = 'TestAccount';
            acctest.RecordTypeId  = '01280000000UERq';
            insert acctest; 
            
            List<Contact> lstCont = new List<Contact>();
            
            Contact contObj = new Contact();
            contObj.AccountId =  acctest.Id;
            contObj.Email = 'abc2@test.com';
            contObj.LastName = 'Test Last2';
            contObj.FirstName = 'Test First2';
            contObj.Phone_Ext__c = Integer.valueOf('1234');
            lstCont.add(contObj);
            
            Contact contObj1 = new Contact();
            contObj1.AccountId =  acctest.Id;
            contObj1.FirstName = 'Manish';
            contObj1.LastName = 'Singh';
            contObj1.Email = 'manish@simplion.com';
            contObj1.Phone= '1234567891';
            contObj1.Phone_Ext__c = Integer.valueOf('1234');
            lstCont.add(contObj1);
		  	
		  	insert lstCont;
		  	
		  	Case caseObj = new Case();
            caseObj.AccountId = acctest.Id;
            caseObj.ContactId = contObj.id;
            caseObj.Subject = 'Test Case';
            caseObj.Description = 'Test Case Desc';
            insert caseObj;
            
            List<CaseComment> lstcasecomment  = new List<CaseComment>();
            CaseComment casecommentObj1 = new CaseComment();
            casecommentObj1.CommentBody = 'Test';
            casecommentObj1.ParentId = caseObj.id;
            lstcasecomment.add(casecommentObj1);
            
            CaseComment casecommentObj2 = new CaseComment();
            casecommentObj2.CommentBody = 'Test1';
            casecommentObj2.ParentId = caseObj.id;
            lstcasecomment.add(casecommentObj2);
            insert lstcasecomment;
            
            Portal_Cases_Record_Types__c cs1 = new Portal_Cases_Record_Types__c();
            cs1.Name = 'Support - T1';
            insert cs1;
            
	  		Profile p = [SELECT Id FROM Profile WHERE Name='Customer Portal User']; 
		 	
		 	User LoginUser = new User( ContactId = lstCont[1].Id ,FirstName = 'Manish',LastName = 'Singh',Alias = 'standt', Email='manish@simplion.com',	
		 							   EmailEncodingKey='UTF-8',  LanguageLocaleKey='en_US', LocaleSidKey='en_US', ProfileId = p.Id,
		 							   TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg.com');
            insert LoginUser;
             System.runAs(LoginUser) {
             	Test.startTest();
	            ApexPages.currentPage().getParameters().put('parentId', caseObj.id);
	            SupportPortalAdvCaseCreate createcaseObj1 = new SupportPortalAdvCaseCreate(new ApexPages.StandardController(new Case()));
	           
	            system.debug('loginUser========='+loginUser);
	            createcaseObj1.ConDetail.FirstName = 'Manish';
			  	createcaseObj1.ConDetail.LastName = 'Singh';
			  	createcaseObj1.ConDetail.Email = 'manish@simplion.com';
			  	createcaseObj1.ConDetail.Phone = '12345679999';
			  	createcaseObj1.ConDetail.Phone_Ext__c = Double.valueOf('1134');
			  	createcaseObj1.PhoneExt = '1122';
			    createcaseObj1.selectedViewOptions1 = 'All Open Cases';
			  	createcaseObj1.selectedProduct = 'test';
			  	createcaseObj1.selectedProduct2  = 'test';
			  	createcaseObj1.selectedProduct3 = 'test';
			  	createcaseObj1.setPortalQuestion();
			  	createcaseObj1.createCase();
			  	createcaseObj1.SummitCase();
			  	createcaseObj1.assistanceChange();
			  	createcaseObj1.showArticleList();
			  	Test.stopTest();
             	
             }
    
    }
}