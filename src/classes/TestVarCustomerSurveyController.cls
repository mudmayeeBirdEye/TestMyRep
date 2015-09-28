/**
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class TestVarCustomerSurveyController {

    static testMethod void VARCustomerSurveyControllertest() {
    	
    	Schema.DescribeSObjectResult result = Account.SObjectType.getDescribe();
        Map<string,Schema.RecordTypeInfo> rtMapByName = result.getRecordTypeInfosByName();
    	
    	Account acctest = new Account();
        acctest.Name = 'TestAccount';
        acctest.RecordTypeId =rtMapByName.get('Customer Account').getRecordTypeID();
        insert acctest; 
        
        Contact contObj = new Contact();
	    contObj.AccountId =  acctest.Id;
	    contObj.Email = 'test@test.com';
	    contObj.LastName = 'Test Last1';
	    contObj.FirstName = 'Test First1';
      	insert contObj;
	      	
    	Survey__c surveyObj1 = new Survey__c();
    	surveyObj1.SurveyType__c = 'VAR Customer';
    	surveyObj1.Name = 'Test Impl';
    	surveyObj1.Contact__c = contObj.Id;
    	surveyObj1.Contact_Email__c = 'test@test.com';
    	insert surveyObj1;
    	
    	Survey__c surveyObj2 = new Survey__c();
    	surveyObj2.SurveyType__c = 'Sales1';
    	surveyObj2.Name = 'Test Impl';
    	surveyObj2.Contact__c = contObj.Id;
    	surveyObj2.Contact_Email__c = 'test@test.com';
    	insert surveyObj2;
    	
    	Test.startTest();
    	
    	Pagereference pageRef = Page.VARSurvey;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', surveyObj1.id);
    	
    	VARCustomerSurveyController csatsurvey2 = new VARCustomerSurveyController();	    
        VARCustomerSurveyController csatsurvey1 = new VARCustomerSurveyController();
        csatsurvey1.getValues1();
        csatsurvey1.getValues2();
        csatsurvey1.getValues3();
        csatsurvey1.getValues4();
        csatsurvey1.getValues5();
        csatsurvey1.save();
        csatsurvey1.answer1 = '1.00';
        csatsurvey1.answer2 = '2.00';
        csatsurvey1.answer31 = '2.00';
        csatsurvey1.answer32 = 'Yes';
        csatsurvey1.showdealerExpCall();
        csatsurvey1.answer33 = '3.00';
        //csatsurvey1.answer34 = '3.00';
        //csatsurvey1.surveyObj.X4_Survey__c = 'Yes';
        csatsurvey1.answer5 = '3.00';
        csatsurvey1.surveyObj.Comments__c = 'Test Comment';
        csatsurvey1.save();
        csatsurvey1.setResponseValue();
        csatsurvey1.checkSurveyAlreadyFilled();
        ApexPages.currentPage().getParameters().put('id', surveyObj2.id);
        
        VARCustomerSurveyController csatsurvey3 = new VARCustomerSurveyController();
        Test.stopTest();
    
    }
}