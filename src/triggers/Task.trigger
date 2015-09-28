/*************************************************
Trigger on Task object
After Insert & Update: Throw error if due date is past. 
                       Set Responded and Last Touched fields as needed.
/************************************************/

trigger Task on Task (before insert, before update) {
    Profile prof = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId() ];
    // by passing the system admin
 	/*List For Opportunity & Lead*/
 	List<Opportunity> opp_list = new  List<Opportunity>();
 	List<Lead> lead_list = new  List<Lead>();
 	/*Set for What & Who Id*/
  	Set<id> whatids = new Set<id>();
  	Set<id> whoids = new Set<id>();
  	for(Task task_obj:trigger.new){
  		whatids.add(task_obj.WhatId);
  		whoids.add(task_obj.WhoId);
  	}
  	Map<id,Opportunity> opp_map = new Map<id,Opportunity>([SELECT id,Responded_Date__c,Responded_By__c,Last_Touched_Date__c,
                Last_Touched_By__c FROM Opportunity WHERE id IN:whatids]);
  	Map<id,Lead> Lead_map = new Map<id,Lead>([SELECT id,Responded_Date__c,Responded_By__c,Last_Touched_Date__c,
                Last_Touched_By__c FROM Lead WHERE id IN:whoids]);	              
    if (!'System Administrator'.equalsIgnoreCase(prof.Name)) {
		for(Task taskObj: trigger.new) {
			if((taskObj.ActivityDate < Date.Today()) && trigger.isInsert){
				taskObj.ActivityDate.addError('Your task due date cannot be past due.');
            }
           	try { 
            	Opportunity opp = opp_map.get(taskObj.WhatId);
                if(opp != null) {
                    if(opp.Responded_Date__c == null && opp.Responded_By__c == null){
                        opp.Responded_Date__c = Datetime.now();
                        opp.Responded_By__c = UserInfo.getUserId();
                    }
                    opp.Last_Touched_Date__c  = Datetime.now();
                    opp.Last_Touched_By__c = UserInfo.getUserId();
                    opp_list.add(opp);
                }
                Lead leadObj =  Lead_map.get(taskObj.WhoId);   
                if(leadObj != null) {                
                    if(leadObj.Responded_Date__c == null && leadObj.Responded_By__c == null){
                        leadObj.Responded_Date__c = Datetime.now();
                        leadObj.Responded_By__c = UserInfo.getUserId();
                    }
                    leadObj.Last_Touched_Date__c  = Datetime.now();
                    leadObj.Last_Touched_By__c = UserInfo.getUserId();
                  	lead_list.add(leadObj);
                }                
	        } catch(Exception e){taskObj.addError(e);}
        }
        try {
        	if(lead_list!=null && lead_list.size() > 0){
        		TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT();
        		update lead_list;
        		TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT = false;
        	}
        } catch(Exception e){ }
        try {
        	if(opp_list!=null && opp_list.size() > 0){
        		TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE();
        		update opp_list;
        		TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE = false;
        	}
        } catch(Exception e){}
    }
}