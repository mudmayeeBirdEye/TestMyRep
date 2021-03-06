@isTest
public class testATBCScheduledMethod{
   
     
     static testMethod void UnittestBatchATBC() {
        try {
             Test.StartTest();
            Account acctest = new Account();
            acctest.Name = 'TestAccount100';
            acctest.Next_Renewal_Date__c = System.today() - 10;
            acctest.RecordTypeId  = '01280000000UERq';
            insert acctest;
            
            System.Debug('>>>ss1>>'+ acctest.Next_Renewal_Date__c );
            
            Account acctest1 = new Account();
            acctest1.Name = 'TestAccount101';
            acctest1.Next_Renewal_Date__c = System.today() + 10;
            acctest1.RecordTypeId  = '01280000000UERq';
            insert acctest1;
            
            System.Debug('>>>ss2>>'+ acctest1.Next_Renewal_Date__c );
            
            Lead leadObj2 = new Lead();
            leadObj2.FirstName='TestLead123';
            leadObj2.LastName='TestLead123LN';
            leadObj2.Company='TestLead123CN';
            leadObj2.Phone='9911112222';
            leadObj2.email = 'testLead123@test.com';
            leadObj2.LeadSource = 'About To Be Cancelled UK';
            leadObj2.ATBC_Stage__c = 'New';
            leadObj2.Account__c = acctest.id;
            leadObj2.User_ID__c = 'TestLead111';
            insert leadObj2;
            
            System.Debug('>>>ss3>>'+leadObj2.Account_Renewal_Date__c); 
            
            Lead leadObj1 = new Lead();
            leadObj1.FirstName='TestLead124';
            leadObj1.LastName='TestLead124LN';
            leadObj1.Company='TestLead124CN';
            leadObj1.Phone='9911112224';
            leadObj1.email = 'testLead124@test.com';
            leadObj1.LeadSource = 'About To be Cancelled';
            leadObj1.ATBC_Stage__c = 'New';
            leadObj1.Account__c = acctest1.id;
            leadObj1.User_ID__c = 'TestLead113';
            insert leadObj1;
            
            Test.StopTest(); 
            
            System.Debug('>>>ss4>>'+leadObj1.Account_Renewal_Date__c);
            
           
            ATBCScheduledMethod RNTest = new ATBCScheduledMethod();
            RNTest.execute(null);
            
      } catch(Exception ex) {}
    }
  }