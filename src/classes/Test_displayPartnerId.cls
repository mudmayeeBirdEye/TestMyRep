@isTest  
private class Test_displayPartnerId {
static testMethod void myUnitTestdisplayPartnerId () {
List<Account> lstacc = new List<Account> ();
   Account acc = new Account ();
   acc.name = 'TEstREst';
   acc.Partner_ID__c = '78383';
   lstacc.add(acc);   
   insert lstacc;

   List<contact> lstCon = new List<contact> ();
   Contact con = new Contact();
   con.Lastname = 'test1';
   //con.RecordType= 'Partner';
   con.OwnerId = userinfo.getuserId();
   con.AccountId = acc.id;   
   lstCon.add(con);
   insert lstCon;   
   
   displayPartnerId mail = new displayPartnerId();
   Test.startTest();   
   Test.stopTest();
 }
}