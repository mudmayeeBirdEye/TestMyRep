@isTest
private class Testcls_OfficeProSurvey {

    static testMethod void myUnitTest() {
    	Schema.DescribeSObjectResult result = Account.SObjectType.getDescribe();
        Map<string,Schema.RecordTypeInfo> rtMapByName = result.getRecordTypeInfosByName();
        
        Account acctest = new Account();
        acctest.Name = 'TestAccount';
        //acctest.RecordTypeId  = '01280000000UERq';
        acctest.RecordTypeId =rtMapByName.get('Customer Account').getRecordTypeID();
        acctest.Survey_Expiry_Date__c = System.today().addDays(4);
        insert acctest; 
        
        Contact contObj = new Contact();
	    contObj.AccountId =  acctest.Id;
	    contObj.Email = 'abc1111@test.com';
	    contObj.LastName = 'Test Last1';
	    contObj.FirstName = 'Test First1';
      	insert contObj;
      	
      	PageReference pageRef = Page.OfficeProSurvey;
      	Test.setCurrentPage(pageRef);
      	ApexPages.currentPage().getParameters().put('conId', contObj.Id);
    	
        cls_OfficeProSurvey obj = new cls_OfficeProSurvey();
        obj.getCurrentQuarter();
        obj.SubmitSurvey();
    }
}