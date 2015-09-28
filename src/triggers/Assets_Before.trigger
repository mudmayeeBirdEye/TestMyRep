trigger Assets_Before on Asset__c (before insert, before update) {
    for(Asset__c asset : trigger.new) {
        
        //asset.Selected_IT_Team_Member__c = asset.IT_Team_Member__c;// replicate IT member value to Selected IT member
     //   asset.IT_Team_Member__c = null; // And set IT member to null
        
        if(asset.Manufacturer__c != 'Other') {
            asset.Manufacturer_Other__c = '';//asset.Manufacturer__c;
        }  
        if(asset.Model__c != 'Other') {
            asset.Model_Other__c = '';//asset.Model__c;
        }
        
    }
}