trigger UserAfterTgr on User (after insert,after update) {
  map<Id,User> userMap = new map<Id,User>();
  set<Id> accountIdSet = new set<Id>();
  map<Id,Account> accountMap = new map<Id,Account>();
  userMap = new map<Id,User>([select Profile.Name, Contact.Account.Okta_Enabled__c,ContactId, Contact.AccountId,OKTAUserID__c 
                  from User where Id IN : Trigger.newMap.keySet()]);
  if(userMap != null && userMap.values() != null) {
    for(User userObj1 : userMap.values()) {
      accountIdSet.add(userObj1.Contact.AccountId);
    }
  }                
  if(accountIdSet != null && accountIdSet.size()>0) {
    accountMap = new map<Id,Account>([select Okta_Enabled__c from Account where Id IN : accountIdSet]);
  }                 
  
  if(Trigger.isInsert) { //  || Trigger.isUpdate
    for(User userObj : trigger.New) {
      System.Debug('>>><<<>>>'+userObj.ContactId);
      System.Debug('>>><<<>>>'+userObj.Contact.Account.Okta_Enabled__c);
      if(userMap != null && userMap.get(userObj.id) != null && userMap.get(userObj.id).Profile.Name.contains('RC Partner') &&
        userMap.get(userObj.id).Profile.Name.contains('Full') && String.isBlank(userMap.get(userObj.id).OKTAUserID__c)
        && userObj.Enable_Okta__c == true && accountMap != null && userMap.get(userObj.id).Contact.AccountId != null &&
        accountMap.get(userMap.get(userObj.id).Contact.AccountId).Okta_Enabled__c == 'Partner Enabled') {
        BatchOktaUser oktaBatchObj = new BatchOktaUser();
        oktaBatchObj.strQuery =  'Select Profile.Name from User where Id =\''+String.escapeSingleQuotes((userObj.id)).trim()+'\'';
        system.Debug('>>>>111>>>' + oktaBatchObj.strQuery);
        Database.executeBatch(oktaBatchObj,1);
      } else if(userMap != null && userMap.get(userObj.id) != null && 
          userMap.get(userObj.id).Profile.Name.contains('RC Partner') &&
        !userMap.get(userObj.id).Profile.Name.contains('Full')
        && userObj.Enable_Okta__c == true && 
        accountMap.get(userMap.get(userObj.id).Contact.AccountId).Okta_Enabled__c == 'Partner Enabled'
        && !Test.isRunningTest()) {
        userObj.addError('This Partner has Customer Accounts enabled in Okta. Please select an Okta-compatible Profile (e.g.' + 
          'RC Partner Modify Okta).');
      }
    }
  } else if(Trigger.isUpdate) {
    
  }
  
}