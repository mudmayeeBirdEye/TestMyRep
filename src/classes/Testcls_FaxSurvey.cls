@isTest
private class Testcls_FaxSurvey {

    static testMethod void myUnitTest() {
      	
      	Schema.DescribeSObjectResult result = Account.SObjectType.getDescribe();
        Map<string,Schema.RecordTypeInfo> rtMapById = result.getRecordTypeInfosByName();
      	
    	Account acctest = new Account();
        acctest.Name = 'TestAccount';
        //acctest.RecordTypeId  = '01280000000UERq';
        acctest.RecordTypeId =rtMapById.get('Customer Account').getRecordTypeID();
        acctest.Survey_Expiry_Date__c = System.today().addDays(4);
        insert acctest; 
        
        Contact contObj = new Contact();
	    contObj.AccountId =  acctest.Id;
	    contObj.Email = 'abc1111@test.com';
	    contObj.LastName = 'Test Last1';
	    contObj.FirstName = 'Test First1';
      	insert contObj;
      	
      	PageReference pageRef = Page.FaxSurvey;
      	Test.setCurrentPage(pageRef);
      	ApexPages.currentPage().getParameters().put('conId', contObj.Id);
      	
      	cls_FaxSurvey obj = new cls_FaxSurvey();
      	// Add parameters to page URL
        obj.recomRCRating = 'test';
        obj.ratingDescription = 'Test';
        obj.addCommentsValue = 'test';
        obj.custSupportValue = '3';
        obj.FeatFunctValue = '3';
        obj.easeImpValue = '3';
        obj.easeUseValue = '3';
        obj.custSupResValue = '3';
        obj.SubmitSurvey();
        
    }
}