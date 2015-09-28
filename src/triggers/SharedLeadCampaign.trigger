trigger SharedLeadCampaign on CampaignMember (after insert) {
    List<Exception_And_Notification_History__c> sendEmails = new List<Exception_And_Notification_History__c>();
    List<Id> leadList = new List<Id>();
    List<Id> contactList = new List<Id>();
    List<Id> campaignList = new List<Id>();
    for(CampaignMember campaignMemberObj : trigger.new) {
    	if(campaignMemberObj.LeadId != null) {
        	leadList.add(campaignMemberObj.LeadId);
    	}
    	if(campaignMemberObj.ContactId != null) {
        	contactList.add(campaignMemberObj.ContactId);
    	}
    	campaignList.add(campaignMemberObj.campaignId);
    }
    Map<Id,Lead> leadMap = new Map<Id, Lead>([SELECT Id, Name, Email, Duplicate_lead__c, Most_Recent_Campaign__c, Shared_Lead_Counter__c, 
    											Phone, Description, OwnerId, NumberOfEmployees__c, BMID__c FROM Lead 
    											WHERE Id IN: leadList and isConverted = false]);
    Map<Id,Contact> contactMap = new Map<Id, Contact>([SELECT Id, Name, Email, Most_Recent_Campaign__c, Phone, Description, OwnerId, BMID__c FROM Contact WHERE Id IN: contactList]);
    Map<Id, Campaign> campaignMap = new Map<Id, Campaign>([SELECT Id, Name, Shared_Lead_Campaign__c FROM Campaign WHERE Id IN: campaignList]);
    
    List<Lead> updatingLeads = new List<Lead>();
    List<Contact> updatingContacts = new List<Contact>();
    
    for(CampaignMember campaignMemberObj : trigger.new) {
    	Campaign campaignObj = campaignMap.get(campaignMemberObj.campaignId);
    	// INCLUDE Most Recent Campaign 
    	if(campaignMemberObj.LeadId != null) { 
    		Lead leadObj = leadMap.get(campaignMemberObj.LeadId);
    		if(leadObj!=null){
		    	if(leadObj.Duplicate_Lead__c != true) {
		    		leadObj.Most_Recent_Campaign__c = campaignMemberObj.campaignId;
		    		//Updating Primary Campaign for LAR.
	                leadObj.Primary_Campaign__c = campaignObj.Id;
	                //End of code
		    		if(campaignObj.Shared_Lead_Campaign__c) {
		    			Integer counter = Integer.valueOf(leadObj.Shared_Lead_Counter__c == null ? 0 :  leadObj.Shared_Lead_Counter__c);
		    			leadObj.Shared_Lead_Counter__c = ++counter;
		    		}
			    	updatingLeads.add(leadObj);
		    	}
    		}
        /*
    		if(campaignObj.Shared_Lead_Campaign__c) {
		    	if(leadObj.Duplicate_Lead__c != true) {
			        Exception_And_Notification_History__c sendEmail = new Exception_And_Notification_History__c();
			        sendEmail.recordTypeId = ExceptionAndNotificationHelper.getRcId(ExceptionAndNotificationHelper.NOTIFICATION_RECORD_TYPE);
			        sendEmail.Record_Owner__c= leadObj.OwnerId;
			        sendEmail.Object_Type__c = 'Lead';
			         
			        sendEmail.content_label_01__c = 'Lead Name';
			        sendEmail.content_var_01__c = leadObj.Name;
			        
			        sendEmail.content_label_02__c = 'Lead Email';
			        sendEmail.content_var_02__c = leadObj.Email;
			        
			        sendEmail.content_label_03__c = 'Lead Phone';
			        sendEmail.content_var_03__c = leadObj.Phone;
			        
			        sendEmail.content_label_04__c = 'Lead Range';
			        sendEmail.content_var_04__c = leadObj.NumberOfEmployees__c;
			        
			        sendEmail.content_label_05__c = 'Lead BMID';
			        sendEmail.content_var_05__c = leadObj.BMID__c;        
			    
			        sendEmail.content_label_06__c = 'Lead Description';
			        sendEmail.content_var_06__c = leadObj.Description;
			        
			        sendEmail.content_label_07__c = 'Lead Id';
			        sendEmail.content_var_07__c = (String)leadObj.Id;
			        
			        sendEmail.content_label_08__c = 'Shared Lead Campaign';
			        sendEmail.content_var_08__c = (campaignObj.Shared_Lead_Campaign__c != true ? 'FALSE' : 'TRUE');
			        
			        sendEmail.isEmailSent__c = true;
			        sendEmails.add(sendEmail);
		    	}
    		}
    		*/
    	}
    	if(campaignMemberObj.ContactId != null) {
			Contact contactObj = contactMap.get(campaignMemberObj.ContactId);
			contactObj.Most_Recent_Campaign__c = campaignMemberObj.campaignId;
			if(TriggerHandler.UPDATE_CONTACT_BMID){
				contactObj.BMID__c='SOLVETHENSELL';  
				contactObj.AID__c='';
				contactObj.PID__c='';
			}
			updatingContacts.add(contactObj);
    	}
    }
    try {
        if(!updatingLeads.isEmpty()){
                TriggerHandler.BY_PASS_LEAD_UPDATE = true;
                update updatingLeads;
                if(Test.isRunningTest()) {
                	TriggerHandler.BY_PASS_LEAD_UPDATE = false;
                }
            }
    } catch(Exception e) {}
    try {
        if(!updatingContacts.isEmpty()){
            TriggerHandler.BY_PASS_CONTACT_ON_UPDATE = true;
            update updatingContacts;
            TriggerHandler.BY_PASS_CONTACT_ON_UPDATE = false;
        }
    } catch(Exception e) {}
    // trigger.new[0].addError('########### '+ sendEmails.size());
    /*
    try {
    	ExceptionAndNotificationHelper.notificationPerWorkflow(sendEmails);
    } catch(Exception e) {
    	// trigger.new[0].addError('########### '+ e);
    }*/
}