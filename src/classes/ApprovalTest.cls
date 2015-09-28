/**
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class ApprovalTest {

    static testMethod void myUnitTest() {
    	Schema.DescribeSObjectResult result = Approval__c.SObjectType.getDescribe();
        Map<string,Schema.RecordTypeInfo> rtMapByName = result.getRecordTypeInfosByName();
        
        // Create User
        Profile p = [SELECT Id,UserType FROM Profile WHERE Name='Sales Agent 3.0']; 
           
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                        UserName='standarduser00001@testorg.com',
                        EmailEncodingKey='UTF-8', LastName='Testing', 
                        LanguageLocaleKey='en_US', 
                        LocaleSidKey='en_US', ProfileId = p.Id,
                        TimeZoneSidKey='America/Los_Angeles');
         insert(u);               
        
    	Agent_Credit__c agCredit = (Agent_Credit__c)SmartFactory.createSObject('Agent_Credit__c');
    	insert agCredit;
    	
        Approval__c app = (Approval__c)SmartFactory.createSObject('Approval__c');
        app.Agent_Credit__c = agCredit.Id;
        app.RecordTypeId = rtMapByName.get('Refund Approval').getRecordTypeID();
        app.Refund_Owner__c = u.Id;
        app.Credit_Transfer_To_Agent__c = u.Id;
        insert app ;
        
        app.Status__c ='PendingL2Approval';
        update app;
    }
    
    /*static testMethod void unitTestForFarmingClaimOwner() {
    	Schema.DescribeSObjectResult result = Approval__c.SObjectType.getDescribe();
        Map<string,Schema.RecordTypeInfo> rtMapByName = result.getRecordTypeInfosByName();
        
        // Create User
        Profile p = [SELECT Id,UserType FROM Profile WHERE Name='Sales Agent 3.0']; 
           
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                        UserName='standarduser00001@testorg.com',
                        EmailEncodingKey='UTF-8', LastName='Testing', 
                        LanguageLocaleKey='en_US', 
                        LocaleSidKey='en_US', ProfileId = p.Id,
                        ManagerId = System.Userinfo.getUserId(),
                        TimeZoneSidKey='America/Los_Angeles');
         insert(u);               
        // Create Agent Credit
    	Agent_Credit__c agCredit = (Agent_Credit__c)SmartFactory.createSObject('Agent_Credit__c');
    	insert agCredit;
    	// Create Account record 
    	Account accountObj = (Account)SmartFactory.createSObject('Account');
    	insert accountObj;
    	// Create Opportunity record 
    	Opportunity opportunityObj = (Opportunity)SmartFactory.createSObject('Opportunity');
    	opportunityObj.AccountId = accountObj.Id;
    	insert opportunityObj;
    	// Create Approval Record.
        Approval__c app = (Approval__c)SmartFactory.createSObject('Approval__c');
        app.Agent_Credit__c = agCredit.Id;
        app.RecordTypeId = rtMapByName.get('Farming Claim Owner').getRecordTypeID();
        app.Refund_Owner__c = u.Id;
        app.Credit_Transfer_To_Agent__c = u.Id;
        app.Opportunity__c = opportunityObj.Id;
        System.runAs(u){
        	insert app ;
        }
        
        app.Status__c ='PendingL2Approval';
        update app;
    }*/
    static testMethod void unitTestForQuoteApprovalProcess() {
    	Schema.DescribeSObjectResult result = Approval__c.SObjectType.getDescribe();
        Map<string,Schema.RecordTypeInfo> rtMapByName = result.getRecordTypeInfosByName();
        
        // Create User
        Profile p = [SELECT Id,UserType FROM Profile WHERE Name='Sales Agent 3.0']; 
           
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                        UserName='standarduser00001@testorg.com',
                        EmailEncodingKey='UTF-8', LastName='Testing', 
                        LanguageLocaleKey='en_US', 
                        LocaleSidKey='en_US', ProfileId = p.Id,
                        ManagerId = System.Userinfo.getUserId(),
                        TimeZoneSidKey='America/Los_Angeles');
         insert(u);               
        
    	Agent_Credit__c agCredit = (Agent_Credit__c)SmartFactory.createSObject('Agent_Credit__c');
    	insert agCredit;
    	
        Approval__c app = (Approval__c)SmartFactory.createSObject('Approval__c');
        app.Agent_Credit__c = agCredit.Id;
        app.RecordTypeId = rtMapByName.get('QuoteApprovalProcess').getRecordTypeID();
        app.Refund_Owner__c = u.Id;
        app.Credit_Transfer_To_Agent__c = u.Id;
        System.runAs(u){
        	insert app ;
        }
        
        app.Status__c ='PendingL2Approval';
        update app;
    }
}