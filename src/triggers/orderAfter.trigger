trigger orderAfter on Order__c (after insert, after update) {
	if(Trigger.isAfter) {
		 // try {	
		  	    List<Account> accountList = new List<Account>();
			  	if(Trigger.isInsert) {
				  	for(Order__c orderValue : Trigger.New) {
				  		if(orderValue.X12M_Company_Booking_Amount__c != null && orderValue.X12M_Company_Booking_Amount__c > 0) {
				  			if(orderValue.Account__c != null  &&  String.valueOf(orderValue.Order_Date__c) != null && 
				  				String.valueOf(orderValue.Order_Date__c) != '') {
				  				Account accObj = new Account(Id = orderValue.Account__c);
				  				accObj.Last_Upsold_Date__c = orderValue.Order_Date__c;
				  				accountList.add(accObj);
				  			}
				  		}
				  	}
			  	}
			  	if(Trigger.isUpdate) {
				  	for(Order__c orderValue : Trigger.New) {
				  		Order__c oldOrderValue = Trigger.oldMap.get(orderValue.Id);
				  		if(orderValue.Account__c != null  && orderValue.X12M_Company_Booking_Amount__c != null && 
				  			orderValue.X12M_Company_Booking_Amount__c > 0) {
				  			if(String.valueOf(orderValue.Order_Date__c) != null && String.valueOf(orderValue.Order_Date__c) != '') {
				  				//if((oldOrderValue.Order_Date__c != orderValue.Order_Date__c) || (oldOrderValue.X12M_Company_Booking_Amount__c <=0)) {
				  					Account accObj = new Account(Id = orderValue.Account__c);
				  					accObj.Last_Upsold_Date__c = orderValue.Order_Date__c;
				  					accountList.add(accObj);
				  			//	}
				  			}
				  		} /* else if(orderValue.Account__c != null  && orderValue.X12M_Company_Booking_Amount__c != null && 
			  					   orderValue.X12M_Company_Booking_Amount__c <= 0 && oldOrderValue.X12M_Company_Booking_Amount__c > 0) {
						  			Account accObj = new Account(Id = orderValue.Account__c);
						  			accObj.Last_Upsold_Date__c = null;
						  			accountList.add(accObj);
				  		} */
				  	}
				}
				
				map<Id,Account> accountMap = new map<Id,Account>();
			    if(accountList != null && accountList.size()> 0) {
			    	for(Account accObj : accountList) {
			    		accountMap.put(accObj.Id,accObj);
			    	}
			    	List<Account> accListToUpd = new List<Account>();
			    	if(accountMap != null && accountMap.values() != null && accountMap.values().size()>0) {
			    		try {
			    			accListToUpd = 	accountMap.values();
		    				update accListToUpd;	
			    		} catch(Exception ex) {}		
			    	}
			  	}
				
			    /*if(accountList != null && accountList.size()> 0) {
			    	for(Account accObj : accountList)
			  			update accObj;
			  	}*/
			  			
		// } catch(Exception ex) {}  
	}
}