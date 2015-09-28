/*************************************************
Trigger on Attachment object
After Insert & Update: Set Responded and Last Touched fields as needed.
					   Send email to case owner of new attachment if parentId is a case.	
/************************************************/

trigger Attachment on Attachment (after insert, after update) {
    Profile prof = [select Name from Profile where Id = :UserInfo.getProfileId()];
    if (!'System Administrator'.equalsIgnoreCase(prof.Name)) {
    	Set<Id> attParentIdSet = new Set<Id>();
        for(Attachment attVal : Trigger.New) {
        	if(attVal != null && attVal.ParentId !=null) {        
				attParentIdSet.add(attVal.ParentId);
        	}
        }
        Map<Id,Opportunity> opportunityMap;
        Map<Id,Lead> leadMap;
        Map<Id,Case> caseMap;
        Map<Id,Group> groupMap;
        Map<Id,User> userMap;
        if(attParentIdSet != null && attParentIdSet.size() >0) {
        	 opportunityMap = new Map<Id,Opportunity>([SELECT id,Responded_Date__c,Responded_By__c,Last_Touched_Date__c,Last_Touched_By__c FROM Opportunity where id in : attParentIdSet]);
        	 leadMap = new Map<Id,Lead>([SELECT id,Responded_Date__c,Responded_By__c,Last_Touched_Date__c,Last_Touched_By__c from Lead WHERE id in : attParentIdSet]);
        	 caseMap = new Map<Id,Case>([SELECT id,Subject,Description,CaseNumber,Ownerid,Owner.Name FROM Case WHERE id in : attParentIdSet]);
        	 if(caseMap != null && caseMap.size() > 0) {
        	 	Set<Id> caseOwnerId = new Set<Id>(); 
        	 	for(Case casVal : caseMap.values()) {
        	 	  caseOwnerId.add(casVal.OwnerId);
        	 	}
        	 	if(caseOwnerId !=null && caseOwnerId.size()>0) {
	        	 	groupMap = new Map<Id,Group>([SELECT email FROM Group WHERE Id IN :caseOwnerId ]);
	        	 	userMap = new Map<Id,User>([SELECT email FROM User WHERE Id IN :caseOwnerId]);
        	 	}
			}
        }
   
        List<Opportunity> oppLst = new  List<Opportunity>();
        List<Lead> leadLst = new  List<Lead>();
        Set<Id> leadId = new  Set<Id>();
        Set<Id> opportunityId = new  Set<Id>();
        
        for(Attachment attVal : Trigger.New) {
        	if(opportunityMap != null && attVal.ParentId != null) {
				Opportunity oppVal = opportunityMap.get(attVal.ParentId);
	              if(oppVal != null) {  
	                if(oppVal.Responded_Date__c == null && oppVal.Responded_By__c == null) {
	                    oppVal.Responded_Date__c = Datetime.now();
	                    oppVal.Responded_By__c = UserInfo.getUserId();
	                }
	                oppVal.Last_Touched_Date__c  = Datetime.now();
	                oppVal.Last_Touched_By__c = UserInfo.getUserId();
	                if(opportunityId != null && !(opportunityId.Contains(attVal.ParentId))) {
	                  	oppLst.add(oppVal);
	                  	opportunityId.add(attVal.ParentId);
	           		}
	             }
        	}
        	
    	   if(leadMap != null && attVal.ParentId != null) {
	   	        Lead leadVal = leadMap.get(attVal.ParentId);
    	   	    if(leadVal != null) {                            
	            	if(leadVal.Responded_Date__c == null && leadVal.Responded_By__c==null) {
	                    leadVal.Responded_Date__c = Datetime.now();
	                    leadVal.Responded_By__c = UserInfo.getUserId();
	                }
	                leadVal.Last_Touched_Date__c  = Datetime.now();
	                leadVal.Last_Touched_By__c = UserInfo.getUserId();
	                if(leadId != null && !(leadId.Contains(attVal.ParentId))) {
	                  	leadLst.add(leadVal);
	                  	leadId.add(attVal.ParentId);
	           		}
       	    	} 
    	   }
          
          if(caseMap != null && attVal.ParentId != null) {
  		 	 Case caseVal = caseMap.get(attVal.ParentId);
  		 	 if(caseVal != null) {
  		 		String email = '';
            	/* ownerId may belong to a group, so need to get the email from group if exists
            	   The below loop will run for one iteration only, so need not to worry about performance.
            	*/
            	/* for(Group groupObj: [SELECT Email FROM Group WHERE Id=: caseVal.Ownerid LIMIT 1]) {
            		email = groupObj.email;
            	} */
            	
            	if(groupMap != null) {
            		if(caseVal.Ownerid != null && groupMap.containsKey(caseVal.Ownerid))
            			email = groupMap.get(caseVal.Ownerid).email;
            	}
            	/* if the owner does not belong to group, need to check it from User and get the email from the same
            		below the for loop will run for one iteration only,The below pattern will handle  the assignment exceptions so no need to worry about performance.
            		
            	*/
            	if(email == '') {
            		/*for(User userdata: [Select Email from User where id =:  caseVal.Ownerid LIMIT 1]) {
            			email = userdata.email;
            		}*/
            		if(userMap != null) {
            			if(caseVal.Ownerid != null && userMap.containsKey(caseVal.Ownerid))
            				email = userMap.get(caseVal.Ownerid).email;
            		}
            	}
            	/*
            	The email will be sent if the email is not blank, the below check will handle the exception
            	*/
            	if(email != '') {
            	  MailHelper mailObj = new MailHelper();
	              try {
						 /*mailObj.createMail('Attachment Description: ' + caseVal.Description + ' Added' , null, null , null, true, 'Salesforce Support',
						 'New Attachment has been Added to : ' + (caseVal.Subject == null ? ' case #' + caseVal.CaseNumber : caseVal.Subject), email);*/
						 mailObj.createMail('Attachment Description: ' + caseVal.Description + ' Added' , null, null , null, true, 'Salesforce Support',
						 'New Attachment has been Added to Case : ' + caseVal.CaseNumber + ' '+(String.isBlank(caseVal.Subject) ? '' : caseVal.Subject), email);
	              } catch(Exception ex) { }
            	}
  		 	 }
           }
        }
        if(oppLst != null && oppLst.size() > 0) {
        	try {
        		update oppLst;
        	} catch(DMLException e) { }
        }
        if(leadLst != null && leadLst.size() > 0) {
        	try {
        		update leadLst;
    		} catch(DMLException e){}
        } 
    }
    
    set<Id> caseIdPortingSet = new set<Id>();
    for(Attachment attVal : Trigger.New) {
    	if(attVal != null && attVal.ParentId != null && string.valueOf(attVal.ParentId).startsWith('500')) {        
			caseIdPortingSet.add(attVal.ParentId);
    	}
    }
    
    map<Id,Case> caseMapPorting = new map<Id,Case>([select Id from Case where ID IN : caseIdPortingSet 
    												and (RecordType.Name = 'Porting - In (NeuStar)' 
    														OR RecordType.Name = 'Porting - In (RC)' OR RecordType.Name = 'Porting - In (TELUS)' OR  RecordType.Name = 'Porting - In (RC UK)')]);
    List<Case> caseListTOuUpd = new List<Case>();														
    for(Attachment attVal : Trigger.New) {
    	if(attVal != null && attVal.ParentId != null && string.valueOf(attVal.ParentId).startsWith('500')) {        
			if(caseMapPorting != null && caseMapPorting.get(attVal.ParentId) != null && prof.Name != 'System Administrator'  
				&& prof.Name != 'Support Agent - Porting' && prof.Name != 'Support Manager - Porting' && UserInfo.getName() != 'RCESB') {
					/*Case caseObjTOUpd = new Case(Id = attVal.ParentId); 
					caseObjTOUpd.IsUpdatePermitted__c = false;
					caseListTOuUpd.add(caseObjTOUpd);*/
				attVal.addError('Not Authorized to add Attachments.');
			}
    	}
    }
    
   	/*try {
   		if(caseListTOuUpd != null && caseListTOuUpd.size()>0) {
   			update caseListTOuUpd;	
   		}
	} catch(Exception ex) {}*/
}