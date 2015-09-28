/*************************************************
Trigger on Refund object
Before Insert: For each refund fill in Assigned Agent at Creation and Brand/Service/Tier.
			   When tring to complete these tasks in refundController.cls the results were not reliable.
/************************************************/
trigger Refund_Before on Refund__c (before insert) {
    if(trigger.isInsert){
        for(Refund__c r: trigger.new){
        	
        	if(r.Assigned_Agent_At_Creation__c == null || r.Assigned_Agent_At_Creation__c == ''){
        		r.Assigned_Agent_At_Creation__c = [SELECT id, email FROM User WHERE id =: UserInfo.getUserId()].email;
        	}
        	try{
	    		Account a = [SELECT id, RC_Brand__c, RC_Service_name__c,RC_Tier__c FROM Account WHERE id =: r.Account__c];
	    		r.Brand__c = a.RC_Brand__c;
	    		r.Service__c = a.RC_Service_name__c;
	    		r.Tier__c = a.RC_Tier__c;
        	}catch(System.QueryException e){
        		
        	}
        }
    } 
}