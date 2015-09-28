trigger Sales_Agreement on Quote (after insert, after update) {
	Map<Id, Id> oppToAccountMap = new Map<Id, Id>();
	Set<Id> oppIds = new Set<Id>();
	for(Quote quoteObj: Trigger.new) {
		oppIds.add(quoteObj.OpportunityID);
	}
	for(Opportunity oppObj : [SELECT  AccountID from Opportunity WHERE ID IN :oppIds]) {
		oppToAccountMap.put(oppObj.Id, oppObj.AccountID);
	}
	List<Id> accountIds = oppToAccountMap.values();
	Map<Id,Account> accMap = new Map<Id, Account>([SELECT ID, Active_Sales_Agreement__c, Previous_Sales_Agreement_End_Date__c, Active_Sales_Agreement__r.Status FROM Account WHERE Id IN :accountIds]);
    List<Account> filteredAccounts = new List<Account>();
	if(Trigger.isInsert){
	    for(Quote quoteObj: Trigger.new){
			try{        
               if(quoteObj.status == 'Active'){
               		Account accObj = accMap.get(oppToAccountMap.get(quoteObj.OpportunityID));
                   	if(accObj != null && accObj.Active_Sales_Agreement__r.Status != 'Active'){
           			    accObj.Active_Sales_Agreement__c = quoteObj.id;
                		filteredAccounts.add(accObj);
                   	} else {	
                    	quoteObj.addError('Associated Account Already In Active Sales Agreement');
                    }
               }
	        }catch(QueryException e){
	            quoteObj.addError(e);
	        }
        }
        if(filteredAccounts.size()>0){
        	update filteredAccounts;
        }
}


	if(Trigger.isUpdate){
		for(Quote quoteObj: Trigger.new){
			try {        
	        	Account accObj = accMap.get(oppToAccountMap.get(quoteObj.OpportunityID));
				if(Trigger.oldMap.get(quoteObj.Id).status !='Active' && quoteObj.status == 'Active'){
					if(accObj != null && accObj.Active_Sales_Agreement__r.Status != 'Active'){
	   			       accObj.Active_Sales_Agreement__c = quoteObj.id;
	            		filteredAccounts.add(accObj);
	               	}else{	
	                	quoteObj.addError('Associated Account Already In Active Sales Agreement');
	                }
		        }
		        if(Trigger.oldMap.get(quoteObj.Id).status =='Active' && quoteObj.status != 'Active'){
                    accObj.Active_Sales_Agreement__c = null;
                    accObj.Previous_Sales_Agreement_End_Date__c = Trigger.oldMap.get(quoteObj.Id).End_Date__c;
                   	filteredAccounts.add(accObj);
                 }
            }catch(Exception e){
              quoteObj.addError(e);
            }
        }
        if(filteredAccounts.size()>0){
        	update filteredAccounts;
        }
    }    
}