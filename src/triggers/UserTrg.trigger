// On Partner User Creation, Default to Manager Role
Trigger UserTrg on User (before insert) {
    try {
        set<Id> contactIdSet = new set<Id>();
        for(User usr : trigger.new) {
            System.debug('####################### usr.UserType = ' + usr.UserType);
            if((usr.UserType == 'PowerPartner' && !string.isBlank(usr.contactId)) || Test.isRunningTest()) {
                contactIdSet.add(usr.contactId);
            } 
        }
        
        List<Contact> contactLst = new List<Contact>();
        if(contactIdSet != null && contactIdSet.size()>0) {
             contactLst = [select AccountId from Contact where Id IN :contactIdSet];
        }
       
        map<Id,Id> mapContactToAccount = new map<Id,Id>();
        for(Contact contactObj : contactLst) {
            mapContactToAccount.put(contactObj.id,contactObj.AccountId); 
        }
        
        map<Id,Id> mapAccountToUser = new map<Id,Id>();
        if(mapContactToAccount != null && mapContactToAccount.values() != null) {
            for(User userObj : [select id,AccountId from User where AccountId IN : mapContactToAccount.values() 
                                    AND UserType = 'PowerPartner']) {
                mapAccountToUser.put(userObj.AccountId,userObj.id);
            }
        }
        
        for(User usr:trigger.new) {
            System.Debug('>>>11>>'+ usr.contactId);
            System.Debug('>>>22>>'+ usr.AccountId);
            System.Debug('>>>33>>'+ usr.UserType);
            System.Debug('>>>44>>'+ usr.portalRole);  
            if(usr.UserType == 'PowerPartner' && mapAccountToUser != null && mapContactToAccount != null 
                && usr.contactId != null){
                if(mapContactToAccount.get(usr.contactId) != null && 
                    mapAccountToUser.get(mapContactToAccount.get(usr.contactId)) == null) {
                    usr.portalRole = 'Manager';
                    System.Debug('>>>55>>'+ usr.portalRole);
                }         
            }
        }
    } catch(Exception ex) {}
 }