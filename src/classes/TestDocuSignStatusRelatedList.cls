/*******************************************************************************************************
* Project Name..........: TestDocuSignStatusRelatedList                                                *
* File..................: TestDocuSignStatusRelatedList.class                                          *
* Version...............: 1.0                                                                          *
* Created by............: eugenebasianomutya                                                           *
* Created Date..........: 24-04-2015                                                                   *
* Last Modified by......: eugenebasianomutya                                                           *
* Last Modified Date....: 24-04-2015                                                                   *
* Description...........: This is a utility class to for:                                              *
*               TestDocuSignStatusRelatedList Class                                       *
*               TestDocuSignStatusRelatedList vfPage                                      *
********************************************************************************************************/
@isTest
public with sharing class TestDocuSignStatusRelatedList {

  static testMethod void myUnitTest(){
        //1 Create Account
        //2 Create DocuSign
                
        //1 Create Account
        Schema.DescribeSObjectResult result = Account.SObjectType.getDescribe();
        Map<string,Schema.RecordTypeInfo> rtMapById = result.getRecordTypeInfosByName();
        
        Account acctest1 = new Account();
        acctest1.Name = 'TestAccount';
        acctest1.RC_Account_Status__c = 'Paid';
        acctest1.RecordTypeId =rtMapById.get('Partner Account').getRecordTypeID();        
        insert acctest1;
        
        //2 Create DocuSign
        dsfs__DocuSign_Status__c dss = new dsfs__DocuSign_Status__c();
        dss.dsfs__Sender_Email__c = 'eugene.mutya@ringcentral.com';
        dss.dsfs__Subject__c = 'Subject';
        dss.dsfs__Envelope_Status__c= 'Status';
        insert dss;
        
        Test.StartTest();
        Test.setCurrentPage(Page.DocuSignStatusRelatedList);
        DocuSignStatusRelatedList cntlr = new DocuSignStatusRelatedList(new ApexPages.StandardController(acctest1));
        cntlr.getDocuSignStatus();
        Test.StopTest();
        
  }
  
  
  
}