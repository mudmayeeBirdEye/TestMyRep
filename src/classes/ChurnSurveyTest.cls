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
private class ChurnSurveyTest {

    static testMethod void churnSurveyTest() {
        // TO DO: implement unit test
        
        Test.startTest();
        
        ApexPages.currentPage().getParameters().put('id', 'abcd');
        ChurnSurveyController churnSurveyController = new ChurnSurveyController();
        churnSurveyController = new ChurnSurveyController();
        ApexPages.currentPage().getParameters().put('id', '');
        churnSurveyController = new ChurnSurveyController();
        
        Account account = new Account(Name='Test',RC_Account_Status__c='disabled',Total_DLs__c=5,RC_Churn_Date__c=system.now().addDays(-7));
        insert account;
        
        Contact con = new Contact(LastName='test', AccountId=account.Id,Email='test@cc.com');
        
        insert con;
        
        ChurnSurveyScheduler churnSurveyScheduler = new ChurnSurveyScheduler();
        String dailyCronExpression = '0 0 13 * * ?';
        System.schedule('Test', dailyCronExpression, churnSurveyScheduler);
        
        Survey__c survey = new Survey__c(SurveyType__c='Churn Feedback Survey', Name='Churn Survey');
        insert survey;
        
        churnSurveyController = new ChurnSurveyController();
        ApexPages.currentPage().getParameters().put('id', survey.Id);
        churnSurveyController = new ChurnSurveyController();
       // churnSurveyController.getQuestion2OPtions();
       // churnSurveyController.Question2seletedOptions.add('Couldn’t get it working');
       // churnSurveyController.Question2seletedOptions.add('Missing Features');
        churnSurveyController.save();
        survey.Responded__c = 1;
        churnSurveyController = new ChurnSurveyController();
        ApexPages.currentPage().getParameters().put('id', '');
        churnSurveyController = new ChurnSurveyController();
        Test.stopTest();
        
    }
    
    static testMethod void churnSurveyBatchTest() {
    	Test.startTest();
	    	Account account = new Account(Name='Test',RC_Account_Status__c='disabled',Total_DLs__c=5,RC_Churn_Date__c=system.now().addDays(-7));
	        insert account;
	        Contact con = new Contact(LastName='test', AccountId=account.Id,Email='vineet.srivastava@simplion.com');
	        insert con;
	    	ChurnSurveyBatch c = new ChurnSurveyBatch ();
	    	Database.executeBatch(c, 100); 
    	Test.stopTest();
    }
    
}