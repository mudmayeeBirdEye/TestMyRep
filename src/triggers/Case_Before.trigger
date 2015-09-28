/*************************************************
Trigger on Case object
Before Insert: Check owners email to determine if this is an Internal case.
/************************************************/

trigger Case_Before on Case (before insert,before update) { 
	/************** IF MEDALLIA IS ACTIVE *******************/
	Boolean isMedallia = (Medallia_Credentials__c.getInstance('Medallia') != null && Medallia_Credentials__c.getInstance('Medallia').isMedallia__c) ? true : false;
	/*Get Collection of record Type*/
    Schema.DescribeSObjectResult result = Case.SObjectType.getDescribe();
    Map<ID,Schema.RecordTypeInfo> rtMapByName = result.getRecordTypeInfosById();
    Map<string,Schema.RecordTypeInfo> rtMapById = result.getRecordTypeInfosByName();
    Profile prof = new Profile();
    if(UserInfo.getProfileId() != NULL){
    	List<Profile> profList = new List<Profile>([select Name from Profile where Id = :UserInfo.getProfileId() limit 1 ]);
    	if(profList.size()>0){
    		prof = profList[0];
    	}
    }
    /* List Containing New Trigger Records using in all over the methods*/
    List<case> NewCaseList = new List<case>(Trigger.new);
    /* Getting all Record Types of Case from Custom Setting Support Record Type as per Functionality */
    Map<String,SupportRecordType__c> SupportRecordTypeMap = SupportRecordType__c.getAll();
    if(SupportRecordTypeMap.size() == 0){
    	CaseBeforeTrigHelper.CustomSupportRecordType();
    	SupportRecordTypeMap = SupportRecordType__c.getAll();
    }
    /* Getting all Record Types of Case from Custom Setting Support Record Type as per Functionality */
    
    /*********************** Only allow RCESB user to create 'Porting - In (NeuStar)' && 'Porting - In (RC)' && 'Porting - In (TELUS)' porting cases******************/
    
    if(trigger.isInsert) {  
    	/*************************** Telus S2S Code Starts *************************/    
    	TelusExternalSharingHelperCls.populateVendorContactFieds(Trigger.new); 
    	TelusExternalSharingHelperCls.mapTelusAddressToRCAddress(Trigger.new); 
    	/*************************** Telus S2S Code Ends *************************/       
        PortingESBHelper.validateOnBeforeInsertEvent(Trigger.new, rtMapByName);
        PortingESBHelper.populatePrimaryContactForPortingCase(Trigger.new, rtMapByName);// To Populate Porting Case contact if on case insert/Update its empty.
    }
    
    EntitlementHelper.entitleAssignmentOncase(trigger.new, '');
    /***************************************************************************************************************************************/
    
    if(trigger.isUpdate){
    	/*************************** Telus S2S Code Starts *************************/ 
    	TelusExternalSharingHelperCls.mapTelusAddressToRCAddress(Trigger.new);
    	TelusExternalSharingHelperCls.populateVendorContactFieds(Trigger.new);  
    	/*************************** Telus S2S Code Ends *************************/ 
	    if(TriggerHandler.BY_PASS_CASE_Trigger == false) {
	    	/**************************** Change of Status, Reject Reason or Estimated completion date ***************************/
	        PortingESBHelper.validateOnBeforeUpdateEvent(trigger.new, trigger.oldMap, rtMapByName, rtMapById, prof);
	    }
	    PortingESBHelper.populatePrimaryContactForPortingCase(Trigger.new, rtMapByName);// To Populate Porting Case contact if on case insert/Update its empty.
    }
    
    if(TriggerHandler.BY_PASS_CASE_ON_UPDATE || TriggerHandler.BY_PASS_CASE_ON_INSERT){
		System.debug('### RETURNED FROM CASE BEFORE TRG ###');
		return;
	} else {
		System.debug('### STILL CONTINUE FROM CASE BEFORE TRG ###');
	} 
	
	if(TriggerHandler.BY_PASS_BEFORE){
        System.debug('### RETURNED FROM CASE BEFORE TRG FOR STANDARD LAYOUT ###');
        return;
    } else {
        TriggerHandler.BY_PASS_BEFORE = true;
        System.debug('### SETTING BY PASS FOR STANDARD LAYOUT TRG ###');
    } 
    
    //IF CASE IS SHARED FROM TELUS 
    /*************************** Telus S2S Code Starts *************************/ 
    TelusExternalSharingHelperCls.mapFieldsForTelusCases(Trigger.new); 
	/*************************** Telus S2S Code Ends ***************************/
    Set<Id> setUserId=new Set<Id>();
    
    set<string> setOPSBussUnit = new set<String>();
    for(Case caseObj : trigger.new){ 
        setUserId.add(caseObj.CreatedById);
        setUserId.add(caseObj.OwnerId);
        if(caseObj.Ops_Bussiness_Units__c != null) {
            string bussUnit = 'OPS '+ caseObj.Ops_Bussiness_Units__c;
            setOPSBussUnit.add(bussUnit);   
        }
    }
    
 	if(trigger.isInsert) {
    	CaseITHelpDeskHelper obj = new CaseITHelpDeskHelper();
    	obj.checkContact(trigger.new, rtMapByName);
    	CaseITHelpDeskHelper.findMissingAccount(Trigger.new);
    	List<Case> newCaseIdsList = new List<Case>();
    	for(Case caseObj : trigger.new) {
    		if(caseObj.AccountId != null)
    			newCaseIdsList.add(caseObj);
    	}
    	if(newCaseIdsList.size() != 0)
    		TelusExternalSharingHelperCls.mapContactOnTelusSharedCases(newCaseIdsList);
    }
    
    Map<id, Employee__c> empMap = new Map<id, Employee__c>();
    for(Employee__c empObj: [Select Manager_Employee_Number__r.Last_Name__c, Manager_Employee_Number__r.First_Name__c, 
                                Manager_Employee_Number__c, User__c From Employee__c Where User__c IN:  setUserId]){
        empMap.put(empObj.User__c , empObj);        
    }

    Map<id,User> mapUser = new Map<Id,User>([SELECT ProfileId, Team__c, Manager.Name, Manager.Email , UserRoleId, IsActive, ManagerId, Name, 
                                                Email FROM User WHERE Id IN:setUserId]);
    
    Map<Id, String> profileIdMap = new Map<Id, String>();
    for(Id userId : mapUser.keySet()) {
        profileIdMap.put(userId, mapUser.get(userId).ProfileId);
    }
    List<Id> profileIds =  profileIdMap.values();
    profileIds.add(UserInfo.getProfileId());
    Map<Id,Profile> profMap = new Map<Id, Profile>([select Name from Profile where Id IN :profileIds]);
    
    
    map<string,Id> groupMapBussUnit = new map<string,Id>();
    System.Debug('>>>111>>'+setOPSBussUnit);
    if(setOPSBussUnit != null && setOPSBussUnit.size()>0) {
        List<Group> groupBussList = [Select id,Name from group where Type = 'Queue' and Name IN :setOPSBussUnit];
        System.Debug('>>>222>>'+groupBussList);
        for(Group gp : groupBussList) {
            groupMapBussUnit.put(gp.Name,gp.Id);    
        }
    } 

    if(trigger.isBefore) {
        /*New Code Added on 4/18/2012 */
        if(Trigger.isInsert) {
            for(Case caseObj : Trigger.new) {
                try {
                    if( rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Sales - Customer Issue Form' &&  mapUser != null) {
                            caseObj.Sales_Owner_Manager_Email__c = mapUser.get(caseObj.OwnerID).Manager.Email;
                    }
                } catch(Exception e) {
                    caseObj.Sales_Owner_Manager_Email__c = null;
                }   
            }
        }
        
        List<String> s = null;
        String emailStr;
        
        /*--------------------------------Insert Manger Field lookup For Support Record Type-----------------------------*/
          
          for(Case caseObj:trigger.new) { 
              Profile Pro = null;
              if(!UserInfo.getProfileId().equalsIgnoreCase('00e80000000l1hKAAQ')) {    // UserInfo.getProfileId() !='00e80000000l1hKAAQ'
                //  RecordType rt = [SELECT Name FROM RecordType Where  Id =: caseObj.RecordTypeId ];
                    /*    if(rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - CV'
                        || rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - Chat'
                        || rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - Customer Compliance'
                        || rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - Email'
                        || rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - Engineering'
                        || rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - Fraud Investigation'
                        || rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - Manager'
                        || rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - Shipping/Rec/RMA'
                        || rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - Snap'
                        || rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - T1'
                        || rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - T2'
                        || rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - T3'
                        || rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - Telecom (Ops)'
                        || rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - Fax Broadcast'
                        || rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - FeedBack'
                        || rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - Offline Case'
                        || rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - System Ops'
                        || rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - DSAT'
                        || rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - Tech Assist'
                        || rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support-Case'
                    )     {*/
                        /* Added New Record Type 'Support - System Ops' And 'Support - DSAT' On 6/23/2011 */
                        /* Added New Record Type 'Support - Tech Assist' on 7/7/2011 */
                        String idCheck = caseObj.OwnerId;
                        if(!idCheck.startsWith('00G') && !UserInfo.getProfileId().equalsIgnoreCase('00e80000000l1hKAAQ') && mapUser != null) { 
                            User user1 = mapUser.get(caseObj.OwnerId);
                            if(user1 != null) {
                                if(profMap != null && profMap.get(user1.ProfileId).Name != 'System Administrator' ) {
                                      //System.Debug('>1>>'+ empMap.get(caseObj.OwnerId));    
                                      //System.Debug('>2>>'+ empMap.get( caseObj.OwnerId).Manager_Employee_Number__r.First_Name__c);  
                                      //System.Debug('>3>>'+ empMap.get( caseObj.OwnerId).Manager_Employee_Number__r.Last_Name__c);   
                                      if(empMap != null && empMap.get( caseObj.OwnerId ) != NULL 
                                        && empMap.get( caseObj.OwnerId ).Manager_Employee_Number__r.First_Name__c != NULL
                                        && empMap.get( caseObj.OwnerId ).Manager_Employee_Number__r.Last_Name__c != NULL){
                                              String fName = empMap.get( caseObj.OwnerId ).Manager_Employee_Number__r.First_Name__c ;
                                              String LName = empMap.get( caseObj.OwnerId ).Manager_Employee_Number__r.Last_Name__c;
                                              caseObj.Support_Owner_Manager__c = fName +' '+lName ;
                                      }
                                        // //user.ManagerId;
                                } else {
                                      caseObj.Support_Owner_Manager__c = null;
                                }
                            }
                         
                      } else {
                          caseObj.Support_Owner_Manager__c = null;
                      }
           }
       }
     
     /*----------------------------------------End-------------------------------------------*/     
        
        // Start Ops Ticketing case //
        
        List<Account> listAccountOPS = [Select (Select Id,Email,Name From Contacts) From Account where Name='RC OPS Team'];
    
        set<Id> setOPSAssUser = new set<Id>();
        set<Id> setAssingnedToUser = new set<Id>();
        
        for(Case caseObj:Trigger.new) {
            if(caseObj.Assigned_OPS_User__c != null) {
                setOPSAssUser.add(caseObj.Assigned_OPS_User__c);
            } 
        }
        
        map<Id,OpsAssignmentRules__c> mapOPSAssRules = new map<Id,OpsAssignmentRules__c>();
        if(setOPSAssUser != null && setOPSAssUser.size()>0) {
            mapOPSAssRules = new map<Id,OpsAssignmentRules__c>([SELECT AssignToUser__c,User__c FROM OpsAssignmentRules__c where  
                                                                    id IN : setOPSAssUser]);
            if(mapOPSAssRules != null && mapOPSAssRules.values() != null) {
                for(OpsAssignmentRules__c Obj : mapOPSAssRules.values()) {
                    if(Obj.AssignToUser__c != null) {
                        setAssingnedToUser.add(Obj.AssignToUser__c);
                    }   
                }   
            }                                                       
        }
        
        map<Id,User> mapAssignedToUser = new map<Id,User>();
        map<Id,Id> mapAssignedUser1 = new map<Id,Id>();
        set<Id> setOPSTeam = new set<Id>();
        if(setAssingnedToUser != null && setAssingnedToUser.size()>0) {
            for(OpsAssignmentRules__c opsAssignedObj : [SELECT id,AssignToUser__c,User__c FROM OpsAssignmentRules__c where 
                                                        AssignToUser__c IN :setAssingnedToUser and User__c IN :setAssingnedToUser]) {
                if(opsAssignedObj.AssignToUser__c == opsAssignedObj.User__c) {
                    mapAssignedUser1.put(opsAssignedObj.AssignToUser__c,opsAssignedObj.Id);
                }       
            }
            mapAssignedToUser = new map<Id,User>([select Ops_TeamMemName__c from User where id IN : setAssingnedToUser and 
                                                    (Ops_LeaveToDate__c >= Today) and (Ops_LeaveFromDate__c<=Today)]);
            if(mapAssignedToUser != null && mapAssignedToUser.values() != null) {
                for(User userObj : mapAssignedToUser.values()) {
                    if(userObj.Ops_TeamMemName__c != null) {
                        setOPSTeam.add(userObj.Ops_TeamMemName__c);
                    }   
                }   
            }                                       
        }
        
        map<Id,Id> mapAssignedUser2 = new map<Id,Id>();
        if(setOPSTeam != null && setOPSTeam.size()>0) {
            for(OpsAssignmentRules__c opsAssignedObj : [SELECT id,AssignToUser__c,User__c FROM OpsAssignmentRules__c where 
                                                        AssignToUser__c IN :setOPSTeam and User__c IN :setOPSTeam]) {
                if(opsAssignedObj.AssignToUser__c == opsAssignedObj.User__c) {
                    mapAssignedUser2.put(opsAssignedObj.AssignToUser__c,opsAssignedObj.Id);
                }       
            }       
        }
        
        try {
          for(Case caseObj:Trigger.new) {
            if(!UserInfo.getProfileId().equalsIgnoreCase('00e80000000l1hKAAQ')) {  //Hack to bypass migration issues  
                if(rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Internal OPS to OPS') {
                        /* Escalation Check starts*/
                        // if case has been updated by RCSF Sync user, means escalation has fired
                    if(caseObj.IsEscalated  && caseObj.OPS_ESCALATED__c ==null) {
                                 caseObj.OPS_ESCALATED__c ='Yes';
                                 caseObj.Assign_To__c='User';
                                 caseObj.Status='Assigned' ;
                                 caseObj.OPS_Last_Action__c ='Take Assignment';
                    }//end escalation
                          
                    if(caseObj.ownerid!=userinfo.getUserId() && caseObj.OPS_Last_Action__c!='Recall' &&
                             caseObj.OPS_Last_Action__c !='Take Assignment' ) {
                         caseObj.OPS_Last_Action__c ='Error';
                    } else {                       
                            if(caseObj.Ops_Recall__c==null) {
                                caseObj.Ops_Recall__c=0; 
                            } 
                            if(caseObj.Ops_ReAssig__c==null) {
                                caseObj.Ops_ReAssig__c=0; 
                            }            
                            /*Case Overdue check starts*/
                            if(caseObj.Ops_Overdue__c==null) {
                                   // caseObj.Ops_Overdue__c='No';
                            }
                            if(caseObj.OPS_Overdue_Formula__c == 'Yes' && caseObj.Ops_Overdue__c == null) {
                                  // caseObj.Ops_Overdue__c='Yes';
                            }
                     
                            //For Ops Contact field update start
                            try {  
                                if(caseObj.OPS_Last_Action__c=='Recalled'){
                                      caseObj.OPS_Last_Action__c='';
                                }
                                /*for(User mail:[Select Email From User where id=:UserInfo.getUserId() limit 1 ]) {                
                                    for(Account con:[Select (Select Id,Email,Name From Contacts) From Account a where Name='RC OPS Team'] ) {
                                        for(Contact cont : con.Contacts) {
                                            if(mail.Email == cont.Email) {
                                                 caseObj.ContactId=cont.Id;
                                            }   
                                        }
                                    }
                                }*/
                                System.Debug('>>!!>>>'+listAccountOPS);
                                if(listAccountOPS != null) {
                                    for(Account accObj : listAccountOPS) {
                                        for(Contact cont : accObj.Contacts) {
                                            if(UserInfo.getUserEmail() == cont.Email) {
                                                caseObj.ContactId = cont.Id;
                                            }
                                        }   
                                    }
                                }
                            }
                            catch(Exception e)
                            {}
                            //For Ops Contact field update end
                            if(caseObj.Assign_To__c != null && caseObj.Assign_To__c.equals('Business Unit')) {
                                caseObj.Assigned_OPS_User__c = null;
                                /*for(Group gp:[Select id from group where Type=:'Queue' and Name=:'OPS '+caseObj.Ops_Bussiness_Units__c]) {
                                    caseObj.ownerid = gp.id; 
                                }*/
                                if(groupMapBussUnit != null && caseObj.Ops_Bussiness_Units__c != null) {
                                    string bussUnit = 'OPS '+ caseObj.Ops_Bussiness_Units__c;
                                    if(groupMapBussUnit.get(bussUnit) != null) {
                                        caseObj.ownerid = groupMapBussUnit.get(bussUnit);
                                        System.Debug('>>22>>>'+caseObj.ownerid);
                                    }
                                }
                            }
                            else if(caseObj.Assign_To__c != null && caseObj.Assign_To__c.equals('User')&& caseObj.Assigned_OPS_User__c!=null ) {
                                /*for(OpsAssignmentRules__c oppsAss :[SELECT AssignToUser__c,User__c FROM OpsAssignmentRules__c where  
                                                                id=:caseObj.Assigned_OPS_User__c ]) {
                                    caseObj.ownerid = oppsAss.AssignToUser__c;
                                    for(OpsAssignmentRules__c objOpsAssignmentRules1:[SELECT id FROM OpsAssignmentRules__c 
                                                                                        where AssignToUser__c=:oppsAss.AssignToUser__c 
                                                                                        and User__c=:oppsAss.AssignToUser__c  limit 1]) {
                                        caseObj.Assigned_OPS_User__c = objOpsAssignmentRules1.id;
                                    }
                                    //Start delegation process
                                    for(User u:[select Ops_TeamMemName__c from User u where id=:oppsAss.AssignToUser__c and 
                                                    (u.Ops_LeaveToDate__c >= Today) and (u.Ops_LeaveFromDate__c<=Today)]) {
                                        caseObj.ownerid = u.Ops_TeamMemName__c;
                                        for(OpsAssignmentRules__c objOpsAssignmentRules:[SELECT id FROM OpsAssignmentRules__c where 
                                                                                                AssignToUser__c=:u.Ops_TeamMemName__c
                                                                                                and User__c=:u.Ops_TeamMemName__c  limit 1]) {
                                            caseObj.Assigned_OPS_User__c=objOpsAssignmentRules.id;
                                        }
                                    } 
                                    //End delegation process
                          
                                    if(caseObj.OPS_Last_Action__c != 'Recall') {
                                        caseObj.status=caseObj.status=='New'?'Assigned':caseObj.status;
                                    }
                                }*/   
                                if(mapOPSAssRules != null && caseObj.Assigned_OPS_User__c != null && 
                                        mapOPSAssRules.get(caseObj.Assigned_OPS_User__c) != null) {
                                    System.Debug('>>10>>>'+ mapOPSAssRules.get(caseObj.Assigned_OPS_User__c));      
                                    OpsAssignmentRules__c oppAssignObj = mapOPSAssRules.get(caseObj.Assigned_OPS_User__c);
                                    System.Debug('>>11>>>'+ oppAssignObj);       
                                    caseObj.ownerid = oppAssignObj.AssignToUser__c;
                                    System.Debug('>>122>>>'+ caseObj.ownerid);  
                                    if(mapAssignedUser1 != null && oppAssignObj.AssignToUser__c != null &&  
                                            mapAssignedUser1.get(oppAssignObj.AssignToUser__c) != null) {
                                        	 	System.Debug('>>12>>>'+ mapAssignedUser1.get(oppAssignObj.AssignToUser__c));  
                                                System.Debug('>>13>>>'+ oppAssignObj);  
                                                caseObj.Assigned_OPS_User__c = mapAssignedUser1.get(oppAssignObj.AssignToUser__c);
                                                System.Debug('>>14>>>'+ caseObj.Assigned_OPS_User__c);  
                                    }
                                    //Start delegation process
                                    if(mapAssignedToUser != null && oppAssignObj.AssignToUser__c != null && 
                                        mapAssignedToUser.get(oppAssignObj.AssignToUser__c) != null) {
                                        User u = mapAssignedToUser.get(oppAssignObj.AssignToUser__c);
                                        caseObj.ownerid = u.Ops_TeamMemName__c;
                                        if(mapAssignedUser2 != null && u.Ops_TeamMemName__c != null && 
                                            mapAssignedUser2.get(u.Ops_TeamMemName__c) != null) {
                                            caseObj.Assigned_OPS_User__c = mapAssignedUser2.get(u.Ops_TeamMemName__c);
                                        }   
                                    }
                                    //End delegation process
                          
                                    if(caseObj.OPS_Last_Action__c != 'Recall') {
                                        caseObj.status = caseObj.status == 'New' ? 'Assigned' :caseObj.status;
                                    }
                                }
                            }
                        }
                   }
               }
            } //end
         }
         catch(System.Exception e) { 
            System.Debug('>>ex>>>'+ e.getmessage());
         }
    }
    
    if(trigger.isUpdate) {
    /*---------------------------------------------Support Case Owner change--------------*/
	Map<id,Case> OldCaseMap = new Map<id,Case>();
	    for(Case caseObj : NewCaseList){
	    	if(trigger.oldMap != null)
	    	OldCaseMap.put(caseObj.id,trigger.oldMap.get(caseObj.Id));
	    }
	    Case FirstRecordCaseNew = trigger.new[0];
     	CaseBeforeTrigHelper.SupportCaseOwnerChange(NewCaseList,OldCaseMap,rtMapByName,prof,FirstRecordCaseNew,SupportRecordTypeMap);
    /* for(Case caseObj:Trigger.new) {
         Integer i=0; 
         User user=null;
         //Profile Pro=null;
            // Commented for data migration
         if (rtMapByName.get(caseObj.RecordTypeId ).getName() == 'Support - CV'
                ||rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - Chat'
                ||rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - Customer Compliance'
                ||rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - Email'
                ||rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - Engineering'
                ||rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - Fraud Investigation'
                ||rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - Manager'
                ||rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - Shipping/Rec/RMA'
                ||rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - Snap'
                ||rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - T1'
                ||rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - T2'
                ||rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - T3'
                ||rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - Telecom (Ops)'
                ||rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - Fax Broadcast'
                ||rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - FeedBack'
                ||rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - Offline Case'
                ||rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - System Ops'
                ||rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - Tech Assist' ) {
             
             /* Added New Record Type 'Support - System Ops' On 6/23/2011 * /
             /* Added New Record Type 'Support - Tech Assist' on 7/7/2011 * /
                    //user =[select profileId from user where userid =:Userinfo. limit 1];
                    //Pro = [Select Name From Profile where id =:userinfo.getProfileId() limit 1];
                    if(prof != null && prof.Name !='System Administrator') {
                        String oldId = trigger.old[i].OwnerId;
                        String newId = trigger.new[i].OwnerId;
                        if(userinfo.getuserId() != caseObj.OwnerId) {
                            if(oldId.startsWith('00G')) {
                                if(trigger.old[i].Status != trigger.new[i].Status
                                      ||trigger.old[i].AccountId != trigger.new[i].AccountId 
                                      ||trigger.old[i].ContactId != trigger.new[i].ContactId
                                      ||trigger.old[i].Priority != trigger.new[i].Priority
                                /*    ||trigger.old[i].Support_Escalate_To__c != trigger.new[i].Support_Escalate_To__c
                                      ||trigger.old[i].OwnerId != trigger.new[i].OwnerId  :Commented For Case No.00323147,  
                                          When a user escalates a case, the owner and the recordtype should change.       * /
                                      ||trigger.old[i].Subject != trigger.new[i].Subject
                                      ||trigger.old[i].Description != trigger.new[i].Description
                                      ||trigger.old[i].Support_Disposition_Level_1__c != trigger.new[i].Support_Disposition_Level_1__c
                                      ||trigger.old[i].Support_Jira__c != trigger.new[i].Support_Jira__c
                                      ||trigger.old[i].Support_RC911_Contact__c != trigger.new[i].Support_RC911_Contact__c
                                      ||trigger.old[i].Support_Ops_Need_More_Info__c != trigger.new[i].Support_Ops_Need_More_Info__c
                                      ||trigger.old[i].Support_Chat_Required_Callback__c != trigger.new[i].Support_Chat_Required_Callback__c) {
                                    caseObj.OwnerId =Userinfo.getUserId();
                                }
                            }
                        }  
                    }
            }
    }*/
    

    /*-------------------------------------------End------------------------------------------------------------*/
        
    /* When any other tier escalate cases back to Support tier 1, 
       change the owner of the case to the case creator IF 
       creator is a support tier 1 agent (profile) and agent is active user. */
  
    for(Case caseObj : Trigger.new) {
        //User usr = [SELECT ProfileId, IsActive FROM User WHERE id =:caseObj.CreatedById  limit 1];
        if(mapUser != null && mapUser.get(caseObj.CreatedById) != null) {
            User usr = mapUser.get(caseObj.CreatedById);
            integer j =0;
            if(Trigger.old[j].Support_Escalate_To__c != 'Tier 1' && caseObj.Support_Escalate_To__c == 'Tier 1' 
                && caseObj.Support_Tier_1_Esc_Count__c >= 1 && usr.ProfileId == '00e80000001OKBB' && usr.IsActive == true) {
                System.debug(Trigger.old[j].Support_Escalate_To__c +'-------------'
                   +caseObj.Support_Escalate_To__c  +'--------------'
                   +caseObj.Support_Tier_1_Esc_Count__c+'----------'
                   +usr.ProfileId +'------------'
                   +usr.IsActive);     
                caseObj.ownerid = caseObj.createdByid;         
                j++;
            }   
        }
    }     
 
 /*******************************************End**********************************************************************/
    
    // Start Ops Ticketing case
    
    Set<Id> caseOwnerId = new Set<Id>();
    for(Case caseObj : trigger.new) {
        if(caseObj.OwnerId != null) {
             caseOwnerId.add(caseObj.OwnerId);  
        }
        caseOwnerId.add(UserInfo.getUserId());
    }
    map<Id,Group> groupMapDet = new  map<Id,Group>();
    map<Id,User> userMapDet = new  map<Id,User>();
    map<Id,Id> opsAssignRuleMap = new map<Id,Id>();
    if(caseOwnerId != null && caseOwnerId.size()>0) {
        groupMapDet = new map<Id,Group>([SELECT Email,Name FROM Group where id IN :caseOwnerId and type='Queue']);
        userMapDet = new map<Id,User>([SELECT Email,Name FROM User where id IN :caseOwnerId]);
        for(OpsAssignmentRules__c opsAssignedObj : [SELECT id,User__c,AssignToUser__c FROM OpsAssignmentRules__c where 
                                                        AssignToUser__c IN :caseOwnerId and User__c IN :caseOwnerId]) {
            if(opsAssignedObj.AssignToUser__c == opsAssignedObj.User__c) {
                opsAssignRuleMap.put(opsAssignedObj.AssignToUser__c,opsAssignedObj.Id);
            }       
        }
    }
       
    
     try {
        Integer i=0;
        for(Case caseObj:Trigger.new) {
            if(rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Internal OPS to OPS' && caseObj.OPS_Last_Action__c != 'Error') {
                String strRecallstatus='No';
                if( caseObj.OPS_Last_Action__c != null && caseObj.OPS_Last_Action__c.equals('Recall')) {
                    strRecallstatus = 'Yes';
                }
                // Assignment to Queue
                if(caseObj.Assign_To__c != null && caseObj.Assign_To__c.equals('Business Unit') && strRecallstatus.equals('No')) {
                    if(caseObj.OPS_Last_Action__c != null && !(caseObj.OPS_Last_Action__c.equals('Cancel') ||
                            caseObj.OPS_Last_Action__c.equals('Closed'))) {
                        caseObj.OPS_Last_Action__c=''; 
                    }
                    caseObj.Assigned_OPS_User__c = null;
                    /*for(Group gp:[Select id from group where Type=:'Queue' and Name=:'OPS '+caseObj.Ops_Bussiness_Units__c]) {
                        caseObj.ownerid = gp.id;
                        if(trigger.old[i].Ops_ReAssig__c == caseObj.Ops_ReAssig__c && caseObj.Ops_ReAssig__c!=null 
                                && caseObj.OPS_Last_Action__c == null) {
                            caseObj.Ops_ReAssig__c=caseObj.Ops_ReAssig__c+1;
                        }
                        //caseObj.OPS_Last_Action__c=''; 
                        if(caseObj.status!=null && !caseObj.status.equals('Cancelled')) { 
                            caseObj.status='New'; 
                        }
                    }*/   //Assignment to User
                    if(groupMapBussUnit != null && caseObj.Ops_Bussiness_Units__c != null) {
                        string bussUnit = 'OPS '+ caseObj.Ops_Bussiness_Units__c;
                        if(groupMapBussUnit.get(bussUnit) != null) {
                            caseObj.ownerid = groupMapBussUnit.get(bussUnit);
                            if(trigger.old[i].Ops_ReAssig__c == caseObj.Ops_ReAssig__c && caseObj.Ops_ReAssig__c != null 
                                && caseObj.OPS_Last_Action__c == null) {
                                caseObj.Ops_ReAssig__c = caseObj.Ops_ReAssig__c + 1;
                            }
                            //caseObj.OPS_Last_Action__c=''; 
                            if(caseObj.status!=null && !caseObj.status.equals('Cancelled')) { 
                                caseObj.status='New'; 
                            }
                        }
                    }
                }  
                else if(caseObj.Assign_To__c != null && caseObj.Assign_To__c.equals('User') && caseObj.Assigned_OPS_User__c != null 
                            && strRecallstatus.equals('No')) {
                     /// caseObj.OPS_Last_Action__c=''; 
                        if(caseObj.OPS_Last_Action__c != null && !(caseObj.OPS_Last_Action__c.equals('Cancel') ||
                                                caseObj.OPS_Last_Action__c.equals('Closed'))) {
                            caseObj.OPS_Last_Action__c=''; 
                        }
                        if(trigger.old[i].Ops_ReAssig__c == caseObj.Ops_ReAssig__c && caseObj.Ops_ReAssig__c != null &&  
                                caseObj.OPS_Last_Action__c == null) {
                            caseObj.Ops_ReAssig__c=caseObj.Ops_ReAssig__c+1;
                        }             
               } 
                // Take Assignment
                else if(caseObj.Assign_To__c != null && caseObj.Assign_To__c.equals('User') && caseObj.Assigned_OPS_User__c == null 
                        && strRecallstatus.equals('No') && caseObj.OPS_Last_Action__c =='Take Assignment') {
                        system.Debug('>>Take Assignment>>');    
                        /*for(OpsAssignmentRules__c objOpsAssignmentRules :[SELECT id FROM OpsAssignmentRules__c where 
                                                                            AssignToUser__c=:caseObj.ownerid and User__c=:caseObj.ownerid limit 1]) {
                            caseObj.Assigned_OPS_User__c = objOpsAssignmentRules.id;
                        }*/
                        system.Debug('>>caseObj.ownerid>>' + caseObj.ownerid);
                        if(opsAssignRuleMap != null && caseObj.ownerid != null && opsAssignRuleMap.get(caseObj.ownerid) != null) {
                            caseObj.Assigned_OPS_User__c = opsAssignRuleMap.get(caseObj.ownerid);
                            system.Debug('>>caseObj.Assigned_OPS_User__c>>'+caseObj.Assigned_OPS_User__c);
                        }
                        // caseObj.OPS_Last_Action__c='';
                } 
                // Recall
                // else if(strRecallstatus.equals('Yes'))
                else if(caseObj.OPS_Last_Action__c == 'Recall') { // Start Sends a mail to previous owner
                    try {
                        String strTo;
                        String strName;
                        String strFromUser;
                        /*for(User objUser:[SELECT Name FROM User where id=:userinfo.getUserId()]) {
                           strFromUser=objUser.Name ;
                        }*/
                        strFromUser = UserInfo.getUserName();
                        /*Integer iCount= [Select count() from Group where type='Queue' AND id=:caseObj.ownerid];
                        if(iCount>0) {
                            for(Group objGroup :[SELECT Email,Name FROM Group where id=:caseObj.ownerid]) {
                               strTo=objGroup .Email;
                               strName=objGroup .Name;
                            }
                        } else {
                            for(User objUser:[SELECT Email,Name FROM User where id=:caseObj.ownerid]) {
                                strTo=objUser.Email;
                                strName=objUser.Name ;
                            }
                        }*/
                        if(caseObj.ownerid != null && String.valueOf(caseObj.ownerid).startsWith('00G') && groupMapDet != null
                            && groupMapDet.get(caseObj.ownerid) != null) {
                            Group objGroup = groupMapDet.get(caseObj.ownerid);
                            strTo=objGroup.Email;
                            strName=objGroup.Name;
                        } else if(caseObj.ownerid != null && String.valueOf(caseObj.ownerid).startsWith('005') && userMapDet != null
                            && userMapDet.get(caseObj.ownerid) != null) {
                            User objUser = userMapDet.get(caseObj.ownerid);
                            strTo = objUser.Email;
                            strName = objUser.Name;
                        }
                        
                        try {
                            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                            system.Debug('>>>>'+strTo);
                            //system.Debug('>>>>'+strfrom);
                            String[] toAddresses = new String[] {strTo}; 
                            mail.setToAddresses(toAddresses);
                            mail.setSenderDisplayName(strFromUser);
                            mail.setSubject('Case has been Recalled');
                            mail.setPlainTextBody('Dear '+strName+',\n\n' +
                             'Following case has been Recalled \n\n Case Number: '+caseObj.CaseNumber+
                             '\n\n Case Description: '+caseObj.Description+
                             //'\n\n Please click https://na6.salesforce.com/'+caseObj.id+' to see the case details.'+
                             '\n\n Please click https://'+System.URL.getSalesforceBaseURL().getHost()+'/'+caseObj.id+' to see the case details.'+
                              '\n\n Thank You');              
                            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail }); 
                        } catch(Exception e) {}
                    } catch(System.Exception ex1){}
                    // End Sends a mail to previos owner       
                    caseObj.OPS_Last_Action__c='Recalled';
                    caseObj.Ops_Recall__c=caseObj.Ops_Recall__c+1;
                    caseObj.ownerid=userinfo.getUserId();
                    caseObj.Ops_Bussiness_Units__c=null;
                    caseObj.Ops_Department__c=null;
                    /*for(OpsAssignmentRules__c objOpsAssignmentRules:[SELECT id FROM OpsAssignmentRules__c where 
                                            AssignToUser__c=:caseObj.ownerid and User__c=:caseObj.ownerid limit 1]) {
                        caseObj.Assigned_OPS_User__c=objOpsAssignmentRules.id;
                    }*/
                    system.Debug('>>caseObj.ownerid>>'+caseObj.ownerid);
                    if(opsAssignRuleMap != null && caseObj.ownerid != null && opsAssignRuleMap.get(caseObj.ownerid) != null) {
                        caseObj.Assigned_OPS_User__c = opsAssignRuleMap.get(caseObj.ownerid);
                        system.Debug('>>caseObj.Assigned_OPS_User__c>>'+caseObj.Assigned_OPS_User__c);
                    }    
                }
            }
            i++;
        }
     }
     catch(System.Exception e) {
        System.debug('Exception============='+e);
     }
     
     //---------------------------------------End Ops Ticketing case------------------------------------ //
    
     // Optimized Code added On 29 Aug ------------------------------------------------------------------------------------------------
     
     
        for(Case caseObj : trigger.new) {
            System.debug('>>>CaseOwner>>11>>>'+ caseObj.OwnerId); 
            setUserId.add(caseObj.CreatedById);
            setUserId.add(caseObj.OwnerId);
        }
    
        mapUser.clear();
        
        mapUser = new Map<Id,User>([SELECT ProfileId, Team__c, Manager.Name, Manager.Email , UserRoleId, IsActive, ManagerId, Name, 
                                                    Id, Email,Username FROM User WHERE Id IN : setUserId]);
    
       
        map<Id,Case> casePortingSurveyMap = new map<Id,Case>([Select (Select Id From Surveys__r where SurveyType__c = 'Porting') From Case 
                                                                    where Id IN : trigger.NewMap.keyset()]); 
            
        map<Id,Case> caseRogersSurveyMap = new map<Id,Case>([Select (Select Id From Surveys__r where SurveyType__c = 'Support Rogers') From Case 
                                                                    where Id IN : trigger.NewMap.keyset()]);
                                                                    
        map<Id,Case> caseCSATSurveyMap = new map<Id,Case>([Select (Select Id From Surveys__r where SurveyType__c = 'Support CSAT' OR 
                                                                    SurveyType__c = 'Porting Phone Support' OR SurveyType__c = 'VAR Support CSAT') 
                                                                    From Case where Id IN : trigger.NewMap.keyset()]);                                                      
            
        set<Id> caseAccountIdSet = new set<Id>();
        set<Id> caseContactIdSet = new set<Id>();
            
        for(Case caseObj : Trigger.new) {
            caseAccountIdSet.add(caseObj.AccountId);
            caseContactIdSet.add(caseObj.contactId);
        }
            
        map<Id,Account> caseAccountMap = new map<Id,Account>();
        map<Id,Contact> caseContactMap = new map<Id,Contact>();
        map<Id,Contact> contactSurveyMap =  new map<Id,Contact>();
        map<Id,Contact> contactSurveyMap1 = new map<Id,Contact>();
        map<Id,contact> contactSurveyMapITHelpDesk = new map<Id,Contact>();
        map<Id,Integer> contactPortingSurveyCount = new map<Id,Integer>();
        
        if(caseAccountIdSet != null && caseAccountIdSet.size()>0) {
            caseAccountMap = new map<Id,Account>([SELECT RC_Brand__c,Premium_Support_Agent__c FROM Account WHERE Account.Id IN : caseAccountIdSet]);
        }
        
        if(caseContactIdSet != null && caseContactIdSet.size()>0) {
            caseContactMap = new map<Id,Contact>([SELECT id, firstName, email From Contact WHERE id IN : caseContactIdSet]);
            contactSurveyMap = new map<Id,Contact>([Select (Select Name From Surveys__r where createdDate = LAST_N_DAYS:7 AND 
                                                    (SurveyType__c =: 'Support CSAT' OR SurveyType__c = 'Porting Phone Support' OR  
                                                    SurveyType__c = 'VAR Support CSAT')) From Contact c where id IN : caseContactIdSet]);
            contactSurveyMap1 = new map<Id,Contact>([Select (Select Name From Surveys__r where createdDate = LAST_N_DAYS:7 AND 
                                                     SurveyType__c = :'Support Rogers') From Contact c where id IN : caseContactIdSet]);
                                                     
            contactSurveyMapITHelpDesk = new map<Id,contact>([Select (Select Name From Surveys__r where createdDate = LAST_N_DAYS:14 AND 
                                                     SurveyType__c = :'IT Helpdesk CSAT') From Contact c where id IN : caseContactIdSet]);
           for(AggregateResult objAggregateResult:[select count(Id) cnt, ContactId from Case where (Case.RecordType.Name = 'Porting - In' 
            											OR Case.RecordType.Name = 'Porting - In (NeuStar)' OR Case.RecordType.Name = 'Porting - In (RC UK)'
            											OR Case.RecordType.Name = 'Porting - In (RC)' OR Case.RecordType.Name = 'Porting - In (TELUS)' OR Case.RecordType.Name = 'Porting - Vanity') and 
            											ContactId != null and ContactId IN : caseContactIdSet 
                                                        and (Status = 'New' OR Status = 'Submitted' OR Status = 'Rejected' OR Status = 'Need Review') 
                                                        group by ContactId]) {
                contactPortingSurveyCount.put(String.valueOf(objAggregateResult.get('ContactId')),Integer.valueOf(objAggregateResult.get('cnt')));
            }                                                                                 
        }
            
        List<Survey__c> surveyToInsertList = new List<Survey__c>();
        List<Survey__c> surveyToInsertList1 = new List<Survey__c>();
        List<Survey__c> surveyToInsertList2 = new List<Survey__c>();
        List<Survey__c> surveyToInsertITHelp = new List<Survey__c>();
        
		/********************** MEDALLIA SURVEY LIST DECLARATION *************************************/
    	List<Case> medalliaSurveyCaseList = new List<Case>();
        /*********************************************************************************************/
        
		for(Case caseObj : Trigger.new) {
            Case caseOldObj = trigger.oldmap.get(caseObj.Id);
            /*
            If field is empty and the case status has changed from any status to “Submitted” populate this field 
            with the date from “Porting_Admin_Last_Change_Date” (set by RCAdmin). 
            */
            if(caseObj.Porting_First_Submit_Date__c == null) {
                if(caseOldObj.Status != 'Submitted' && caseObj.Status == 'Submitted'){
                    if(caseObj.Porting_Admin_Last_Change_Date__c != null)
                       { caseObj.Porting_First_Submit_Date__c = caseObj.Porting_Admin_Last_Change_Date__c;}
                    else{
                        caseObj.Porting_First_Submit_Date__c = Date.today();}
                }
            }
            /*
            Whenever the case status changes from any status to “Submitted” update this field with the date from 
            “Porting_Admin_Last_Change_Date” (set by RCAdmin)
            */
            if(caseOldObj.Status != 'Submitted' && caseObj.Status == 'Submitted') {
                if(caseObj.Porting_Admin_Last_Change_Date__c != null)
                    caseObj.Porting_Last_Submit_Date__c = caseObj.Porting_Admin_Last_Change_Date__c;
                else
                    caseObj.Porting_Last_Submit_Date__c = Date.today();
            }
            /*
            If field is empty and the case status has changed from any status to “Rejected” 
            update this field with the Porting_Reject_Reason. 
            UAT 01 -  Populate the first reject reason (Porting_First_Reject_Reason__c) 
            only if there is a first submit date (Porting_First_Submit_Date__c)
            */          
            if(caseObj.Porting_First_Submit_Date__c != null) {
                if(caseObj.Porting_First_Reject_Reason__c == null){
                    if(caseOldObj.Status != 'Rejected' && caseObj.Status == 'Rejected'){
                        caseObj.Porting_First_Reject_Reason__c = caseObj.Porting_Reject_Reason__c;
                    }
                }
            }
            /*Auto Populate the system date when you move the Porting Status to completed*/
            /*if(caseObj.Porting_Complete_Date__c == null) {
                if(caseOldObj.Status != 'Closed' && caseObj.Status == 'Closed'){                 
                    caseObj.Porting_Complete_Date__c = Date.today();             
                }
            }*/
            
            if(rtMapByName != null && caseObj.RecordTypeId != null && 
            	(rtMapByName.get(caseObj.RecordTypeId).getName() == 'Porting – In' || 
            	  rtMapByName.get(caseObj.RecordTypeId).getName() == 'Porting – Out' ||
            	  rtMapByName.get(caseObj.RecordTypeId).getName() == 'Porting – Bulk/Project')) {
            	if(caseObj.Porting_Complete_Date__c == null) {
	                if(caseOldObj.Status != 'Closed' && caseObj.Status == 'Closed') {                 
	                    caseObj.Porting_Complete_Date__c = Date.today();             
	                }
            	}	
            }
            
            /*
            UAT-01
             If Porting_RC_Review__c is “None” and Status is changed to “Submitted” 
             then update Porting_RC_Review__c to “Accepted”
            */
            system.debug(' here is the debug***' + caseObj.Porting_RC_Review__c);
            if(caseObj.Porting_RC_Review__c == null && caseObj.Status == 'Submitted'){
                caseObj.Porting_RC_Review__c = 'Accepted';                   
            }
            /*
            UAT-01
              If Porting_RC_Review__c is “None” and Status is changed to “Rejected” 
              then update Porting_RC_Review__c to “Rejected”  
            */
            if(caseObj.Porting_RC_Review__c == null && caseObj.Status == 'Rejected'){
                caseObj.Porting_RC_Review__c = 'Rejected';                   
            }
            /*UAT-01
            For the Porting RC Review Reject Reason we should do the following:     
            If Porting_RC_Review_Reject_Reason__c is “None” and Porting_RC_Review__c is changed “Rejected”  
                  i.  If Porting_Reject_Reason__c = “LEC request COB”, set Porting_RC_Review_Reject_Reason__c = “COB”   
                  ii. If Porting_Reject_Reason__c = “PIN not Found”, set Porting_RC_Review_Reject_Reason__c = “PIN” 
                  iii.If Porting_Reject_Reason__c = “Incorrect account number”, set Porting_RC_Review_Reject_Reason__c = “Account”  
                  iv. If Porting_Reject_Reason__c = “Illegible auth name missing or not found”, set Porting_RC_Review_Reject_Reason__c = “LOA”  
                  v.  Else Porting_RC_Review_Reject_Reason__c = [No Value]  
            */
            system.debug('debug*** 1'+ caseObj.Porting_RC_Review_Reject_Reason__c);
            if(caseObj.Porting_RC_Review_Reject_Reason__c == null && caseObj.Porting_RC_Review__c == 'Rejected'){
                if(caseObj.Porting_Reject_Reason__c == 'LEC request COB'){
                    caseObj.Porting_RC_Review_Reject_Reason__c = 'COB';
                }
                else if(caseObj.Porting_Reject_Reason__c == 'PIN not Found'){
                    caseObj.Porting_RC_Review_Reject_Reason__c = 'PIN';
                }
                else if(caseObj.Porting_Reject_Reason__c == 'Incorrect account number'){
                    caseObj.Porting_RC_Review_Reject_Reason__c = 'Account';
                }
                else if(caseObj.Porting_Reject_Reason__c == 'Illegible auth name/name missing'){
                    caseObj.Porting_RC_Review_Reject_Reason__c = 'LOA';
                }else{
                  caseObj.Porting_RC_Review_Reject_Reason__c = '[No Value]';
                }
            }
            /*
            Save data into Survey Object
            */


            system.debug('survey process' + caseObj.Status + '--' + caseOldObj.Status);
           /*Fileter from Record Types*/
			if((caseObj.Status == 'Closed' || caseObj.Status == 'Completed' || caseObj.Status == 'Closed - No Response') && caseOldObj.Status != caseObj.Status) {
				if(isMedallia) {
					if(MedalliaSurveyHelper.isMedalliaSupportForPorting(caseObj, caseOldObj, rtMapByName) 
						&& (caseObj.MedalliaRecordAlreadyCreated__c == null || caseObj.MedalliaRecordAlreadyCreated__c == false)
						&& !String.isBlank(caseObj.ContactId)	) {
						// surveyToInsertList.add(surveyObj); [NEED TO ADD CODE HERE]
						caseObj.MedalliaRecordAlreadyCreated__c = true;
						medalliaSurveyCaseList.add(caseObj);
					}
				} else {
					system.debug('IN');                     
	                Integer sCheck = -1;

	                try {
	                    if(casePortingSurveyMap != null && casePortingSurveyMap.containsKey(caseObj.Id) && 
	                       casePortingSurveyMap.get(caseObj.Id).Surveys__r != null) {
	                            List<Survey__c> surveyList = casePortingSurveyMap.get(caseObj.Id).Surveys__r;
	                            if(surveyList != null) {
	                                sCheck = surveyList.size(); 


	                            }
	                    }
	                } catch(System.QueryException e){}

	                if(sCheck == 0 && !String.isBlank(caseObj.ContactId)) {
	                    Survey__c surveyObj = new Survey__c();
	                    surveyObj.Case__c = caseObj.Id;

	                    try{
	                        surveyObj.Contact__c = caseObj.ContactId;
	                        /* confirm that the contact has no other port-in or port-out cases in status: New, Submitted, Rejected, or Need Review. 
	                        If no records are found, send out the survey, otherwise, do not send */
	                        Integer iCount = 0;
	                        /*iCount = [select count() from Case where ContactId=:caseObj.ContactId  and id !=:caseObj.id
	                                    and (Status ='New' OR Status ='Submitted' OR Status ='Rejected' OR Status ='Need Review')];*/
	                        if(contactPortingSurveyCount != null && caseObj.ContactId != null 
	                                && contactPortingSurveyCount.get(caseObj.ContactId) != null) {
	                            system.debug('<<>FFF>> ' + contactPortingSurveyCount.get(caseObj.ContactId));
	                            iCount = contactPortingSurveyCount.get(caseObj.ContactId) - 1;            
	                            system.debug('chkCounter.size IS --> ' + caseObj.ContactId + '------' + iCount); 

	                        }               
	                        //system.debug('chkCounter.size IS --> ' + caseObj.ContactId + '------' + iCount);


	                                                
							if(iCount == 0) {      
	                          	if(rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Porting - In'
	                              || rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Porting - In (NeuStar)'
								  || rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Porting - In (RC UK)'
								  || rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Porting - In (RC)' 
								  || rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Porting - In (TELUS)' 
								  || rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Porting - Vanity' 

								  ) {
	                                if(caseAccountMap != null && caseObj.AccountId != null && 
	                                    caseObj.ContactId != null  && caseAccountMap.containskey(caseObj.AccountId) != null) {
	                                    Account acc =   caseAccountMap.get(caseObj.AccountId);  
	                                    if(acc.RC_Brand__c != null && acc.RC_Brand__c.trim().equalsIgnoreCase('RingCentral')) {
	                                        Contact contactObj = caseContactMap.get(surveyObj.Contact__c);
	                                        surveyObj.Contact_Email__c = contactObj.email;                           
	                                        surveyObj.Name = 'Porting Survey - ' + Datetime.now().format();
	                                        surveyObj.SurveyType__c = 'Porting';
	                                        surveyObj.Agent_Email__c = 'portingsupport@ringcentral.com'; // Change as per Wilson March16 2011

	                                        
	                                        if(mapUser != null && caseObj.OwnerId != null && mapUser.containskey(caseObj.OwnerId)) {
	                                            User userObj = mapUser.get(caseObj.OwnerId);
	                                            surveyObj.Agent__c = userObj.Id;
	                                            surveyObj.Agent_Email__c = userObj.Email;
	                                            surveyObj.Agent_Name__c = userObj.Name;
	                                            surveyObj.Agent_Team__c = userObj.Team__c;
	                                            surveyObj.Account__c = caseObj.AccountId;
	                                            if(userObj.Manager.Email != null && userObj.Manager.Name != null) {
	                                                surveyObj.Agent_Manager_Email__c = userObj.Manager.Email;
	                                                surveyObj.Agent_Manager_Name__c = userObj.Manager.Name; 





	                                            }       
	                                        }
	                                        if(mapUser != null && mapUser.containskey(caseObj.CreatedById)) {
	                                              User userObj = mapUser.get(caseObj.CreatedById);
	                                              if(userObj != null && userObj.isActive == true) {
	                                                  surveyObj.ownerId = caseObj.CreatedById;


	                                              }
	                                        }
	                                        surveyToInsertList.add(surveyObj);




	                                    }
	                                }
	                            }
	                        }
	                    } catch(System.Exception e){caseObj.addError(e);}

					}
				}
            }
                
            /*--------------------------------CSAT Trigger-----------------------------*/
           
           if((rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - Chat'
               || rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - Email'
              // || rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - Engineering'
               || rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - Manager'
             //  || rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - Shipping/Rec/RMA'
               || rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - T1'
               || rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - T2'
               || rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - T3'
              // || rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - System Ops'
               || rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Porting - Phone'
              // || (rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - Tech Assist' && caseObj.Interacted_with_Customer__c == true)
               || rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - T1 (VAR & Partners)'
               || rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support – IA Inbound'
               || rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - PS'
               || rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - VIPFR'
               || rtMapByName.get(caseObj.RecordTypeId).getName() == 'Support-Case'
              // || rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - Fraud Investigation'
                
              	|| rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - Tech Assist'
              	|| rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - QoS'
				|| rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - Mobile'
				|| rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - TalkToRCMgmt'
				|| rtMapByName.get(caseObj.RecordTypeId).getName() == 'Service Engineer'
				|| rtMapByName.get(caseObj.RecordTypeId).getName() == 'Support - CV' 
				|| rtMapByName.get(caseObj.RecordTypeId).getName() == 'Support - Executive Response Team' 
				|| rtMapByName.get(caseObj.RecordTypeId).getName() == 'Support - Red Account'
				|| rtMapByName.get(caseObj.RecordTypeId).getName() == 'Support – Social Media'
				|| rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - Telus'
				|| rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - FeedBack'
              )
                 && (
                    	(caseObj.Support_Jira__c == null) 
                    	// || (caseObj.Support_Jira__c != null && caseObj.Status == 'PKI Hold')
                    )
            
			) {
        
                    /* Added New record Type 'Support - Tech Assist'  on 7/7/2011 */
                    /* Remove record Type 'Support - Tech Assist' on 1/4/2012 */     
                    
        	           //if(caseObj.Status == 'Closed' && caseOldObj.Status != 'Closed') { 
        	           if(
        	           	((caseObj.Status == 'Closed' && caseOldObj.Status != 'Closed') || 
                         (caseObj.Status == 'Closed - No Response' && caseOldObj.Status != 'Closed - No Response')
        	           	&& !(rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - FeedBack' 
        	           	   	|| rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - TalkToRCMgmt'
        	           	   	|| rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - Tech Assist'
							|| rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - Mobile'
							|| rtMapByName.get(caseObj.RecordTypeId).getName() == 'Service Engineer'
							|| rtMapByName.get(caseObj.RecordTypeId).getName() == 'Support - CV' 
							|| rtMapByName.get(caseObj.RecordTypeId).getName() == 'Support - Executive Response Team' 
							|| rtMapByName.get(caseObj.RecordTypeId).getName() == 'Support - Red Account'
							|| rtMapByName.get(caseObj.RecordTypeId).getName() == 'Support – Social Media'))
        	           /*||((!(rtMapByName.get(caseObj.RecordTypeId).getName() == 'Support - Chat'
						  	|| rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - Email'
               			  	|| rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - Manager'
               			  	))*/
               			  	 /* MODIFIED ON 3, JAN, 2014
               			  	 && (caseOldObj.Status != 'Closed - No response' && caseOldObj.Status != 'PKI Hold' && caseOldObj.Status != 'Closed')
               			  	 && (caseObj.Status == 'Closed - No response'|| caseObj.Status == 'PKI Hold'))
               			  	 */
               			  /*	 && (caseOldObj.Status != 'PKI Hold' && caseOldObj.Status != 'Closed')
               			  	 && caseObj.Status == 'PKI Hold')*/
               			){ 
		            	// When Dispositon Level 1 equals to 'Hot Issue' and Dispostionn Level 2 equals to 'Outage' then not survey
		            	// Other Conditions Added On 30 Aug 2012 
		            	/*if((caseObj.Support_Disposition_Level_1__c != 'Hot Issue' && caseObj.Support_Disposition_Level_2__c != 'Outage') &&
		            		 (!((caseObj.Support_Disposition_Level_1__c == 'Others') && 
			            		(rtMapByName.get(caseObj.RecordTypeId).getName() == 'Support - T1' || 
			            		 rtMapByName.get(caseObj.RecordTypeId).getName() == 'Support - T2' ||
			            		 rtMapByName.get(caseObj.RecordTypeId).getName() == 'Support - T1 (VAR & Partners)' ||
			            		 rtMapByName.get(caseObj.RecordTypeId).getName() == 'Support - PS' ||
			            		 rtMapByName.get(caseObj.RecordTypeId).getName() == 'Support - VIPFR' ||
			            		 rtMapByName.get(caseObj.RecordTypeId).getName() == 'Support – IA Inbound' ||
                                 rtMapByName.get(caseObj.RecordTypeId).getName() == 'Porting - Phone'))  &&
		            		 !((caseObj.Support_Disposition_Level_1__c == 'Feedback' && caseObj.Support_Disposition_Level_2__c == 'Feature Request') && 
		            			(rtMapByName.get(caseObj.RecordTypeId).getName() == 'Support - T1' || 
		            		 	rtMapByName.get(caseObj.RecordTypeId).getName() == 'Support - T2' ||
		            		 	rtMapByName.get(caseObj.RecordTypeId).getName() == 'Support - T1 (VAR & Partners)' ||
		            		 	rtMapByName.get(caseObj.RecordTypeId).getName() == 'Support - PS' ||
		            		 	rtMapByName.get(caseObj.RecordTypeId).getName() == 'Support - VIPFR' ||
		            		 	rtMapByName.get(caseObj.RecordTypeId).getName() == 'Support – IA Inbound' ||
                             	rtMapByName.get(caseObj.RecordTypeId).getName() == 'Porting - Phone')) &&
	            		 	!((caseObj.Support_Disposition_Level_1__c == 'Billing' && caseObj.Support_Disposition_Level_2__c == 'User Issue' &&
	            		 	   	caseObj.Support_Disposition_Level_3__c == 'Account Cancellation' && caseObj.Support_Disposition_Level_4__c != null &&
	            		 	   	caseObj.Support_Disposition_Level_5__c == 'Cancelled') && 
	            		 	  	(rtMapByName.get(caseObj.RecordTypeId).getName() == 'Support - T1' || 
	            		 		rtMapByName.get(caseObj.RecordTypeId).getName() == 'Support - T2' ||
	            		 		rtMapByName.get(caseObj.RecordTypeId).getName() == 'Support - T1 (VAR & Partners)' ||
	            		 		rtMapByName.get(caseObj.RecordTypeId).getName() == 'Support - PS' ||
	            		 		rtMapByName.get(caseObj.RecordTypeId).getName() == 'Support - VIPFR' ||
	            		 		rtMapByName.get(caseObj.RecordTypeId).getName() == 'Support – IA Inbound' ||
                             	rtMapByName.get(caseObj.RecordTypeId).getName() == 'Porting - Phone')) &&
            		 		!(caseObj.Support_Disposition_Level_1__c == 'Fraud' && 
            		 			rtMapByName.get(caseObj.RecordTypeId).getName() == 'Support - Fraud Investigation') &&
        		 			!((caseObj.Support_Disposition_Level_1__c != null) && 
        		 				(rtMapByName.get(caseObj.RecordTypeId).getName() == 'Support – Feedback' || 
        		 				 rtMapByName.get(caseObj.RecordTypeId).getName() == 'Support - TalkToRCMgmt')) &&
        		 			!((caseObj.Support_Disposition_Level_1__c != null) && 
        		 				(rtMapByName.get(caseObj.RecordTypeId).getName() == 'Support - T1 (Shipping)')) &&
        		 			//!((caseObj.Support_Disposition_Level_1__c != null) && 
        		 				//(rtMapByName.get(caseObj.RecordTypeId).getName() == 'Support - PS')) &&
        		 			!((caseObj.Support_Disposition_Level_1__c != null) && 
        		 				(rtMapByName.get(caseObj.RecordTypeId).getName() == 'Support - Tech Assist')))
	            		 		)*/
	            		 		/*if(
	            		 			//(!(A && (B OR C OR D)))
	            		 			(!(
	            		 				(rtMapByName.get(caseObj.RecordTypeId).getName() == 'Support - T1' || 
	            		 			  	 rtMapByName.get(caseObj.RecordTypeId).getName() == 'Support - T2' ||
	            		 		      	 rtMapByName.get(caseObj.RecordTypeId).getName() == 'Support - T1 (VAR & Partners)' ||
	            		 		         rtMapByName.get(caseObj.RecordTypeId).getName() == 'Support - PS' ||
	            		 	 	         rtMapByName.get(caseObj.RecordTypeId).getName() == 'Support - VIPFR' ||
	            		 		         rtMapByName.get(caseObj.RecordTypeId).getName() == 'Support – IA Inbound' ||
	            		 		         rtMapByName.get(caseObj.RecordTypeId).getName() == 'Support - Chat' ||
	            		 		         rtMapByName.get(caseObj.RecordTypeId).getName() == 'Support - Email' ||
	            		 		         rtMapByName.get(caseObj.RecordTypeId).getName() == 'Support - Engineering' ||
	            		 		         rtMapByName.get(caseObj.RecordTypeId).getName() == 'Support - Fraud Investigation' ||
	            		 		         rtMapByName.get(caseObj.RecordTypeId).getName() == 'Support - Manager' ||
	            		 		         rtMapByName.get(caseObj.RecordTypeId).getName() == 'Support - Shipping/Rec/RMA' ||
	            		 		         rtMapByName.get(caseObj.RecordTypeId).getName() == 'Support - System Ops' ||
	            		 		         rtMapByName.get(caseObj.RecordTypeId).getName() == 'Support - T3' ||
	            		 		         rtMapByName.get(caseObj.RecordTypeId).getName() == 'Support-Case' ||
	            		 		         rtMapByName.get(caseObj.RecordTypeId).getName() == 'Porting - Phone') &&
	            		 				(
	            		 				 (caseObj.Support_Disposition_Level_1__c == 'Additional Items') ||
	            		 				 (caseObj.Support_Disposition_Level_2__c == 'Feature Request') ||
	            		 				 (caseObj.Support_Disposition_Level_2__c == 'Outage')  || 
	            		 				 (caseObj.Support_Disposition_Level_2__c == 'Cancellation Request')  || 
	            		 				 ((caseObj.Support_Disposition_Level_2__c == 'Fraud Items') && 
	            		 				 	(caseObj.Support_Disposition_Level_3__c == 'Account Limit Adjustment' ||
	            		 				 	 caseObj.Support_Disposition_Level_3__c == 'Additional Numbers/Extensions' ||
	            		 				 	 caseObj.Support_Disposition_Level_3__c == 'High Amount Auto-Purchase' ||
	            		 				 	 caseObj.Support_Disposition_Level_3__c == 'Fax Broadcast' ||
	            		 				 	 caseObj.Support_Disposition_Level_3__c == 'International Calling' ||
	            		 				 	 caseObj.Support_Disposition_Level_3__c == 'Client Inquiry' || 
	            		 				 	 caseObj.Support_Disposition_Level_3__c == 'Non Client Inquiry' ||
	            		 				 	 ((caseObj.Support_Disposition_Level_3__c == 'Credit Card Authorization Form') && 
	            		 				 	    (caseObj.Support_Disposition_Level_4__c == 'Increase Transaction Limit' ||
	            		 				 	     caseObj.Support_Disposition_Level_4__c == 'International Calling Items' ||
	            		 				 	     caseObj.Support_Disposition_Level_4__c == 'More than 3 Accounts' ||
	            		 				 	     caseObj.Support_Disposition_Level_4__c == 'Fax Broadcasting' ||
	            		 				 	     caseObj.Support_Disposition_Level_4__c == 'Transaction Per Month Limit' ||
	            		 				 	     caseObj.Support_Disposition_Level_4__c == 'Dollar Amount Per Month Limit' ||
	            		 				 	     caseObj.Support_Disposition_Level_4__c == 'High Limit Auto-Purchase' ||
	            		 				 	     caseObj.Support_Disposition_Level_4__c == 'Non-US IP Account Activation' 
	            		 				 	 	)
	            		 				 	 ) ||
	            		 				 	caseObj.Support_Disposition_Level_3__c == 'Blacklisted Credit Card' 
	            		 				 	)
	            		 				 )  || 
	            		 				 ((caseObj.Support_Disposition_Level_2__c == 'Compliance') &&
	            		 				 	(caseObj.Support_Disposition_Level_3__c == 'Trunking Violation' ||
	            		 				 	 caseObj.Support_Disposition_Level_3__c == 'Call In Line Violation' ||
	            		 				 	 caseObj.Support_Disposition_Level_3__c == 'Spam Violation' ||
	            		 				 	 caseObj.Support_Disposition_Level_3__c == 'Auto Dialer Violation' ||
	            		 				 	 caseObj.Support_Disposition_Level_3__c == 'Other Violation' 
	            		 				 	)
	            		 				 )  || 
	            		 				 ((caseObj.Support_Disposition_Level_2__c == 'Implementations') &&
	            		 				 	(caseObj.Support_Disposition_Level_3__c == 'Consultation' ||
	            		 				 	 caseObj.Support_Disposition_Level_3__c == 'Setup/Configuration'
	            		 				 	)
	            		 				 )  || 
	            		 				 ((caseObj.Support_Disposition_Level_2__c == 'ACD Related') && 
	            		 				 	(caseObj.Support_Disposition_Level_3__c == 'Ghost Calls' ||
	            		 				 	 ((caseObj.Support_Disposition_Level_3__c == 'Transferred Call') &&
	            		 				 	    (caseObj.Support_Disposition_Level_4__c == 'Sales' ||
	            		 				 	     caseObj.Support_Disposition_Level_4__c == 'STS' ||
	            		 				 	     caseObj.Support_Disposition_Level_4__c == 'Implementations' ||
	            		 				 	     caseObj.Support_Disposition_Level_4__c == 'Tier 3' ||
	            		 				 	     caseObj.Support_Disposition_Level_4__c == '10+ Lines' ||
	            		 				 	     caseObj.Support_Disposition_Level_4__c == 'VAR & Partners' ||
	            		 				 	     caseObj.Support_Disposition_Level_4__c == 'Saves Team' 
	            		 				 	 	)
	            		 				 	 ) ||
	            		 				 	caseObj.Support_Disposition_Level_3__c == 'No Issue Given'
	            		 				 	) 
	            		 				 ) ||
	            		 				 (caseObj.Support_Disposition_Level_1__c == 'Fraud') ||
	            		 				 (caseObj.Support_Disposition_Level_1__c == 'Subpoena') ||
	            		 				 (caseObj.Support_Disposition_Level_1__c == 'Chargeback') || 
	            		 				 ((caseObj.Support_Disposition_Level_1__c == 'Billing/Warranty/Shipping') &&
	            		 				 	(caseObj.Support_Disposition_Level_2__c == 'International Calling') &&
	            		 				 	    (caseObj.Support_Disposition_Level_3__c == 'RingCentral Blocked Country')
	            		 				 )
	            		 				)	
	            		 			  )
	            		 			 ) 
	            		 		  )  */
							/********************************** MEDALLIA CODE FOR CSAT SURVEYs *****************************************************/
               				if(isMedallia) {
               					Account accObj =   caseAccountMap.get(caseObj.AccountId);  
               					Boolean isBrandTelus = (accObj != null && !String.IsBlank(accObj.RC_Brand__c) && accObj.RC_Brand__c.trim().containsIgnoreCase('Telus')) ? true : false;
								Boolean isrecordTypeIT = (String.valueOf(rtMapByName.get( caseObj.RecordTypeId ).getName()).contains('IT'))?true:false;
								// [DISPOSITIONS changes are taken cared by Medallia]
								if(!isBrandTelus 
									&& !isrecordTypeIT 
									// && MedalliaSurveyHelper.isMedalliaSupportForCSAT(caseObj, caseOldObj, rtMapByName) //[not required for now]
									&& (caseObj.MedalliaRecordAlreadyCreated__c == null || caseObj.MedalliaRecordAlreadyCreated__c == false)
									&& !String.isBlank(caseObj.ContactId)	) {
									caseObj.MedalliaRecordAlreadyCreated__c = true;
									medalliaSurveyCaseList.add(caseObj);
								}
							} else if((caseObj.Support_Disposition_Level_1__c != 'Internal Work Flow')
       							&& (caseObj.Support_Disposition_Level_2__c != 'Feature Request'
   									&& caseObj.Support_Disposition_Level_2__c != 'Outage'
   									&& caseObj.Support_Disposition_Level_2__c != 'Do Not Contact Request'
   									&& caseObj.Support_Disposition_Level_2__c != 'Cancellation Request')
       							&& (caseObj.Support_Disposition_Level_3__c != 'RingCentral Blocked Country')) {     	
				                	system.debug('IN CSAT');                     
					                Integer sCheck = -1;
					                Integer rCheck = -1;
					                String surveyType = null;
					                
					                try {
					            		if(caseCSATSurveyMap != null && caseCSATSurveyMap.containsKey(caseObj.Id)) {
			                				List<Survey__c> surveyList = caseCSATSurveyMap.get(caseObj.Id).Surveys__r;
			                				system.Debug('>>surveyList>>>'+surveyList);
			                				if(surveyList != null) {
			                					sCheck = surveyList.size();
			                					system.Debug('>>sCheck>>>'+sCheck);
			                				}
				                		}
				                		if(caseRogersSurveyMap != null && caseRogersSurveyMap.containsKey(caseObj.Id)) {
			                				List<Survey__c> surveyList = caseRogersSurveyMap.get(caseObj.Id).Surveys__r;
			                				system.Debug('>>surveyList>>>'+surveyList);
			                				if(surveyList != null) {
			                					rCheck = surveyList.size();
			                					system.Debug('>>rCheck>>>'+rCheck);
			                				}
				                		}
					                } catch(Exception e){}
		                               
					                if(sCheck == 0 || rCheck  == 0) {
					                  	//Survey__c s1 = new Survey__c();
					                	//s1.Case__c = caseObj.Id;
					                    //s1.Contact__c = caseObj.ContactId;
					                    Integer iCount = -1;
					                    Integer oCount = -1;
						            	if(contactSurveyMap != null && caseObj.ContactId != null && contactSurveyMap.containskey(caseObj.ContactId)) {
					             			List<Survey__c> surveyList = contactSurveyMap.get(caseObj.ContactId).Surveys__r;
			                				if(surveyList != null) {
			                					iCount = surveyList.size();
			                					system.Debug('>>iCount>>>'+iCount);
			                				}	
					             		}
					             		if(contactSurveyMap1 != null && caseObj.ContactId != null && contactSurveyMap1.containskey(caseObj.ContactId)) {
					             			List<Survey__c> surveyList = contactSurveyMap1.get(caseObj.ContactId).Surveys__r;
			                				if(surveyList != null) {
			                					oCount = surveyList.size();
			                					system.Debug('>>oCount>>>'+oCount);
			                				}	
					             		}
					                    // below code is used to create survey object according to brand of an Account, provided that, it should handle the input null values.
					                    // 1. getting the respective one record
					                    if(rtMapByName.get(caseObj.RecordTypeId ).getName() == 'Support - T1 (VAR & Partners)' 
					                    					&& iCount == 0 && caseObj.ContactId != null) {
					                        Survey__c surveyObj = new Survey__c();
				                            surveyObj.Case__c = caseObj.Id;
				                            try { 
				                                surveyObj.Contact__c = caseObj.ContactId;
				                                if(surveyObj.Contact__c != null && caseContactMap != null && caseContactMap.containskey(surveyObj.Contact__c)) {
				                                	Contact contactObj = caseContactMap.get(surveyObj.Contact__c);
				                                	surveyObj.Contact_Email__c = contactObj.email;    	
				                                }     
				                                // getting the user information per case owner id basis
				                                if(mapUser != null && caseObj.OwnerId != null && mapUser.containskey(caseObj.OwnerId)) {
				                                	User userObj = mapUser.get(caseObj.OwnerId);
				                                	surveyObj.Agent__c = userObj.Id;
				                                    surveyObj.Agent_Email__c = userObj.Email;
				                                    surveyObj.Agent_Name__c = userObj.Name;
				                                    surveyObj.Agent_Team__c = userObj.Team__c;
				                                    surveyObj.Account__c = caseObj.AccountId;
				                                    if(userObj.Manager.Email != null && userObj.Manager.Name != null) {
				                                    	surveyObj.Agent_Manager_Email__c = userObj.Manager.Email;
				                                        surveyObj.Agent_Manager_Name__c = userObj.Manager.Name;	
				                                    }		
				                        		}                       
				                                  surveyObj.Name = 'VAR Support CSAT' + ' '+ Datetime.now().format();
				                                  surveyObj.SurveyType__c = 'VAR Support CSAT';
				                                  //surveyObj.ownerId = caseObj.CreatedById;
				                                  if(mapUser != null && mapUser.containskey(caseObj.CreatedById)) {
			                                      	  User userObj = mapUser.get(caseObj.CreatedById);
			                                      	  if(userObj != null && userObj.isActive == true) {
		                                      			  surveyObj.ownerId = caseObj.CreatedById;
		                                      		  }
	                                      		  }
				                                  surveyToInsertList2.add(surveyObj); 
				                                  
				                             } catch(Exception e) {
				                                caseObj.addError(e);
				                            }
					                   } else {
					                   	if(caseAccountMap != null && caseObj.AccountId != null && caseAccountMap.containskey(caseObj.AccountId)) {
					                   		Account acc = 	caseAccountMap.get(caseObj.AccountId);
					               		    // 2. checking its not null values.
					                        if(acc.RC_Brand__c != null) {
					                            // 3. taking the default conditions per provided data, and created the variables per conditions.
					                            //Boolean ringCentralStatus = acc.RC_Brand__c.trim().equalsIgnoreCase('RingCentral');
					                            Boolean csatBrandStatus = false;
					                           	if((acc.RC_Brand__c.trim().startsWithIgnoreCase('RingCentral')
					                                ||acc.RC_Brand__c.trim().equalsIgnoreCase('AT&T Office@Hand')
					                                ||acc.RC_Brand__c.trim().equalsIgnoreCase('RingCentral Office@Hand from AT&T')
					                                ||acc.RC_Brand__c.trim().equalsIgnoreCase('Clearwire')
					                                || acc.RC_Brand__c.trim().containsIgnoreCase('Telus'))&& acc.Premium_Support_Agent__c == null) {
				                              			csatBrandStatus = true;
					                            }
					                            Boolean rogersStatus = acc.RC_Brand__c.trim().equalsIgnoreCase('Rogers');
					                            if(csatBrandStatus || rogersStatus) {
					                                // the below is the default logic that is done in each conditions,
					                                // for adding new condition, the below field logic can be overridden into below code
					                               Map<String, String> hm = new Map<String, String>();
					                               if(iCount == 0 && csatBrandStatus && rtMapByName.get( caseObj.RecordTypeId ).getName() != 'Porting - Phone') {
					                                    if(rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Support - Tech Assist') {
					    									hm.put('Survey-TechAssist', 'Support CSAT');                           			
					                               		} else if(caseObj.Product_Assistance__c != 'Product Feedback') {
						                                    hm.put('Survey-CSAT', 'Support CSAT');
					                               		}
					                                }
					                               if(oCount == 0 && rogersStatus && rtMapByName.get( caseObj.RecordTypeId ).getName() != 'Porting - Phone') {
					                                    hm.put('Support-Rogers', 'Support Rogers');
					                               }
					                               if(iCount == 0 && csatBrandStatus  && rtMapByName.get( caseObj.RecordTypeId ).getName() == 'Porting - Phone') {
					                                      hm.put('Porting-Phone-Support', 'Porting Phone Support');
					                               }
					                                
					                                for(String key: hm.keySet()) {
					                                    Survey__c surveyObj1 = new Survey__c();
					                                    surveyObj1.Case__c = caseObj.Id;
					                                    try { 
					                                        surveyObj1.Contact__c = caseObj.ContactId;
					                                        if(surveyObj1.Contact__c != null && caseContactMap != null && 
					                                        	caseContactMap.containskey(surveyObj1.Contact__c)) {
					                                        	Contact contactObj = caseContactMap.get(surveyObj1.Contact__c);
					                                        	surveyObj1.Contact_Email__c = contactObj.email;    	
					                                        }
					                                        // getting the user information per case owner id basis
					                                        System.debug('>>>CaseOwner>>11>>>'+ caseObj.OwnerId);	
					                                        System.debug('>>>mapUser>>11>>>'+ mapUser);	
					                                        if(mapUser != null && caseObj.OwnerId != null && mapUser.containskey(caseObj.OwnerId)) {
					                                        	User userObj = mapUser.get(caseObj.OwnerId);
					                                        	surveyObj1.Agent__c = userObj.Id;
					                                            surveyObj1.Agent_Email__c = userObj.Email;
					                                            surveyObj1.Agent_Name__c = userObj.Name;
					                                            surveyObj1.Agent_Team__c = userObj.Team__c;
					                                            surveyObj1.Account__c = caseObj.AccountId;
					                                            if(userObj.Manager.Email != null && userObj.Manager.Name != null) {
					                                            	surveyObj1.Agent_Manager_Email__c = userObj.Manager.Email;
					                                                surveyObj1.Agent_Manager_Name__c = userObj.Manager.Name;	
					                                            }		
				                                    		}
				                                         	surveyObj1.Name = key + ' '+ Datetime.now().format();
					                                      	surveyObj1.SurveyType__c = hm.get(key);
					                                      	//if(s.SurveyType__c == 'Support CSAT') {
		                                          			//surveyObj1.ownerId = caseObj.CreatedById;	
			                                          		//}
			                                          		if(mapUser != null && mapUser.containskey(caseObj.CreatedById)) {
					                                      		User userObj = mapUser.get(caseObj.CreatedById);
					                                      		if(userObj != null && userObj.isActive == true) {
					                                      			surveyObj1.ownerId = caseObj.CreatedById;
					                                      		}
					                                      	}
					                                      	surveyToInsertList1.add(surveyObj1); 
				                                 		} catch(Exception e) {
				                                        	caseObj.addError(e);
				                                      	}                             
				                               		}
		                           				}
		                        			}
			                   			} 
			                 		}
			              	 	}
          	 				}
	            		}               
                    } 
                /*--------------------------------CSAT Trigger  END-----------------------------*/ 
                
                /************* IT HelpDeskSurvey ****************************************/
                System.Debug('>>>Start ITHelp>');
                
                if((rtMapByName.get( caseObj.RecordTypeId ).getName() == 'IT Helpdesk')) {
                    Integer itSurveyCount = -1; 
                    if(caseObj.Status == 'Closed' && caseOldObj.Status != 'Closed') {
                        try {
                            if(contactSurveyMapITHelpDesk != null && caseObj.ContactId != null && 
                                    contactSurveyMapITHelpDesk.containsKey(caseObj.ContactId)) {
                                List<Survey__c> surveyList = contactSurveyMapITHelpDesk.get(caseObj.ContactId).Surveys__r;
                                system.Debug('>>surveyListIT>>>'+surveyList);
                                if(surveyList != null) {
                                    itSurveyCount = surveyList.size();
                                    system.Debug('>>itSurveyCount>>>'+itSurveyCount); 
                                }
                            }
                            
                            if(itSurveyCount == 0) {
                                Survey__c surveyObj1 = new Survey__c();
                                surveyObj1.Case__c = caseObj.Id;
                                surveyObj1.Contact__c = caseObj.ContactId;
                                if(surveyObj1.Contact__c != null && caseContactMap != null && 
                                    caseContactMap.containskey(surveyObj1.Contact__c)) {
                                    Contact contactObj = caseContactMap.get(surveyObj1.Contact__c);
                                    surveyObj1.Contact_Email__c = contactObj.email;     
                                }
                              
                                if(mapUser != null && caseObj.OwnerId != null && mapUser.containskey(caseObj.OwnerId)) {
                                    User userObj = mapUser.get(caseObj.OwnerId);
                                    surveyObj1.Agent__c = userObj.Id;
                                    surveyObj1.Agent_Email__c = userObj.Email;
                                    surveyObj1.Agent_Name__c = userObj.Name;
                                    surveyObj1.Agent_Team__c = userObj.Team__c;
                                    surveyObj1.Account__c = caseObj.AccountId;
                                    if(userObj.Manager.Email != null && userObj.Manager.Name != null) {
                                        surveyObj1.Agent_Manager_Email__c = userObj.Manager.Email;
                                        surveyObj1.Agent_Manager_Name__c = userObj.Manager.Name;    
                                    }       
                                }
                                surveyObj1.Name = 'IT Helpdesk CSAT' + ' '+ Datetime.now().format();
                                surveyObj1.SurveyType__c = 'IT Helpdesk CSAT';
                                /*if(mapUser != null && mapUser.containskey(caseObj.CreatedById)) {
                                    User userObj = mapUser.get(caseObj.CreatedById);
                                    if(userObj != null && userObj.isActive == true) {
                                        surveyObj1.ownerId = caseObj.CreatedById;
                                    }
                                }*/
                                surveyToInsertITHelp.add(surveyObj1);   
                            }
                        } catch(Exception ex) {
                            caseObj.addError(ex);
                        }   
                    }
                }
              /************* IT HelpDeskSurvey END ****************************************/  
        	}
        if(surveyToInsertList != null && surveyToInsertList.size()>0) {
            try {
                insert surveyToInsertList;
            } catch(Exception ex) {}
        }
        if(surveyToInsertList1 != null && surveyToInsertList1.size()>0) {
            try {
                insert surveyToInsertList1;
            } catch(Exception ex) {
            }
        }
        if(surveyToInsertList2 != null && surveyToInsertList2.size()>0) {
            try {
                insert surveyToInsertList2;
            } catch(Exception ex) {
            }
        }
        
        if(surveyToInsertITHelp != null && surveyToInsertITHelp.size()>0) {
            try {
                insert surveyToInsertITHelp;
            } catch(Exception ex) {}
        }
		/************************* Code edit for Medallia Survey Starts*********************************/
        if(medalliaSurveyCaseList != null && medalliaSurveyCaseList.size()>0) {
            try {
            	if(!TriggerHandler.BY_PASS_CASE_ON_UPDATE){
            		MedalliaSurveyHelper.insertSupportMedalliaSurvey(medalliaSurveyCaseList,rtMapByName);	
            	}
                TriggerHandler.BY_PASS_CASE_ON_UPDATE();
            } catch(Exception ex) {}
        }
        /************************* Code edit for Medallia Survey Ends*********************************/
    }
     
   try {  
    Set<Id> setAccountId = new Set<Id>();
    Map<Id,Account> mapToCaseAccount = new Map<Id,Account>();
	if((trigger.isInsert)||(trigger.isUpdate)){
		for(Case objcase:trigger.new) {
			if(objcase.RecordTypeId != null && objcase.AccountId != null){//&& rtMapByName.get(objcase.RecordTypeId).getName() == 'Porting - Out') //Commented Out for-
				//-case number 03092329 so that we can use same query for all cases. in following code we already have recordType check for PortOut cases-
				//-Deployed on 12/11/2014 : ....
				setAccountId.add(objcase.AccountId);   
			} 		
		}
		if(setAccountId != null && setAccountId.size()>0) {
			mapToCaseAccount = new Map<Id,Account>([SELECT Id,MRR__c,inContract__c,Sales_Agreement_End_Date__c,Number_of_DL_s__c,Account.Name,Current_Owner__c, 
													Current_Owner_Email__c,Most_Recent_Opportunity_Owner_Email__c,Sales_Agreement_Start_Date__c	
													FROM Account WHERE Id =:setAccountId]);
		}
	}
   	if(trigger.isInsert) {
    	for(Case objcase:trigger.new) {
    		try {
    			system.debug('********************* debug starts ************************');
	    		if(objcase.RecordTypeId != null && rtMapByName.get(objcase.RecordTypeId).getName() == 'Porting - Out' && objcase.AccountId != null) {
					if(mapToCaseAccount != null && objcase.AccountId != null && mapToCaseAccount.get(objcase.AccountId) != null) {
						Date startDate = mapToCaseAccount.get(objcase.AccountId).Sales_Agreement_Start_Date__c;
              			Date endDate = mapToCaseAccount.get(objcase.AccountId).Sales_Agreement_End_Date__c;
              			decimal n = 0.0;
						if(mapToCaseAccount.get(objcase.AccountId).MRR__c == null) {
							mapToCaseAccount.get(objcase.AccountId).MRR__c = 0;
						}
						if((endDate != null) && (startDate != null)){
							if(system.today() < startDate){
								n = Math.ceil(Decimal.valueOf((startDate.daysBetween(endDate)))/30);
								objcase.Account_Balance__c  = n * mapToCaseAccount.get(objcase.AccountId).MRR__c;
								system.debug('*********** 1 Account_Balance__c *******  '+ objcase.Account_Balance__c  );
							} else if(system.today() >= startDate && system.today() < endDate){
								n = Math.ceil(Decimal.valueOf((system.today().daysBetween(endDate)))/30);
								system.debug('----- n2----'+n);
								objcase.Account_Balance__c = n * mapToCaseAccount.get(objcase.AccountId).MRR__c;
								system.debug('***********2 Account_Balance__c *******  '+ objcase.Account_Balance__c  );
							}else if(system.today() >= endDate){
								objcase.Account_Balance__c = 0;
								system.debug('*********** 3 Account_Balance__c *******  '+ objcase.Account_Balance__c  );
							}
						}
						/*if((mapToCaseAccount.get(objcase.AccountId).Sales_Agreement_End_Date__c != null) && 
							(mapToCaseAccount.get(objcase.AccountId).Sales_Agreement_End_Date__c > system.today())){
							objcase.Account_Balance__c = mapToCaseAccount.get(objcase.AccountId).MRR__c * system.today().monthsBetween(mapToCaseAccount.get(objcase.AccountId).Sales_Agreement_End_Date__c);
						} else {
							objcase.Account_Balance__c = mapToCaseAccount.get(objcase.AccountId).MRR__c * 1;
						}*/
			   			if(String.isBlank(objcase.No_Phone_Numbers_to_Port_Out__c)) {
							objcase.No_Phone_Numbers_to_Port_Out__c = '0';
			   			}
			   			if(mapToCaseAccount.get(objcase.AccountId).Number_of_DL_s__c == null) {
			   				mapToCaseAccount.get(objcase.AccountId).Number_of_DL_s__c = 0;
			   			}	
						if(Integer.valueOf(objcase.No_Phone_Numbers_to_Port_Out__c) <= mapToCaseAccount.get(objcase.AccountId).Number_of_DL_s__c) {
							objcase.Full_or_Partial_Port_Out__c = 'Partial';
						} else {
							objcase.Full_or_Partial_Port_Out__c = 'Full';  
						}
					}
	    		}
   			} catch(Exception e){objcase.addError(e);}
    	}
   	}
   	
   	List<Exception_And_Notification_History__c> lstEANH = new List<Exception_And_Notification_History__c>();
   	String sUrlRewrite = System.URL.getSalesforceBaseUrl().getHost();
   	if((trigger.isInsert)||(trigger.isUpdate)){
   		system.debug('**********************************Porting Out Close case start here **************************************************');
   		try{
	   		for(Case objcase : trigger.new) {
	   			
	   			/****************************** Deployed on 12/11/2014 : Code for Case Number : 03092329 Starts here ****************************/
                if(mapToCaseAccount != null && objcase.AccountId != null && mapToCaseAccount.get(objcase.AccountId) != null) {
                    objcase.Account_Current_Owner__c = mapToCaseAccount.get(objcase.AccountId).Current_Owner__c ;
                }
            	/****************************** Code for Case Number : 03092329 Ends here *******************************************************/
	   			String strStatus = trigger.oldMap.get(objcase.id).Status;
	   			//System.Debug('>>>111>>' + rtMapByName.get(objcase.RecordTypeId).getName());
	   			if(objcase.RecordTypeId != null && rtMapByName.get(objcase.RecordTypeId).getName() == 'Porting - Out' 
	   				&& strStatus != 'Closed' 
					&& objcase.Status == 'Closed' 
					&& mapToCaseAccount != null 
					&& objcase.AccountId != null 
					&& mapToCaseAccount.get(objcase.AccountId) != null
					&& (mapToCaseAccount.get(objcase.AccountId).Number_of_DL_s__c != null 
						&& mapToCaseAccount.get(objcase.AccountId).Number_of_DL_s__c != 0)
				){
					sUrlRewrite = 'https://' + sUrlRewrite + '/' + objcase.id;
					String toAddress = '';
					if(!String.isBlank(mapToCaseAccount.get(objcase.AccountId).Current_Owner_Email__c)){
						toAddress = mapToCaseAccount.get(objcase.AccountId).Current_Owner_Email__c;
					} else {
						toAddress = mapToCaseAccount.get(objcase.AccountId).Most_Recent_Opportunity_Owner_Email__c;
					}
					if(!String.isBlank(toAddress) && toAddress != UserRC.rcsfSyncUserObj.Email__c) {
						Exception_And_Notification_History__c objEANH = new Exception_And_Notification_History__c();
						objEANH.Email_Subject__c = 'Customer '+ mapToCaseAccount.get(objcase.AccountId).Name +' has just completed a '+ objcase.Full_or_Partial_Port_Out__c;
						objEANH.To_Address_1__c = toAddress;
						objEANH.Object_Type__c = 'case - PortOut';
						objEANH.content_label_01__c = 'Account: ' ;
						objEANH.content_var_01__c = mapToCaseAccount.get(objcase.AccountId).Name;
						objEANH.content_label_02__c =' No. of DLs: ';
						objEANH.content_var_02__c =  mapToCaseAccount.get(objcase.AccountId).Number_of_DL_s__c == null ? '': 
														String.valueOf(mapToCaseAccount.get(objcase.AccountId).Number_of_DL_s__c);
						objEANH.content_label_03__c = 'Partial vs. Full: ';
						objEANH.content_var_03__c = + objcase.Full_or_Partial_Port_Out__c;
						objEANH.content_label_04__c = 'Account Balance on Port-Out: ';
						objEANH.content_var_04__c =  'USD '+ objcase.Account_Balance__c == null? '' : String.valueOf(objcase.Account_Balance__c);
						objEANH.content_label_05__c = 'Port Out Case Number: ';
						objEANH.content_var_05__c =  objcase.CaseNumber;
						objEANH.content_label_06__c = 'Port Out Case Link: ';
						objEANH.content_var_06__c = sUrlRewrite;
						lstEANH.add(objEANH); 
					}
				}
	   		}
	   		if(lstEANH != null && lstEANH.size()> 0){
	   			insert lstEANH;
	   		}
   		} catch(exception e ){}
		 // system.debug('**********************************Porting Out Close case ends here **************************************************');		
   	}
  } catch(Exception ex){} 
   
       /*for(Case caseObj : trigger.new) {
    	try {
				if(mapUser != null && caseObj.OwnerId != null && mapUser.containsKey(caseObj.OwnerId)){
					if(Trigger.oldmap == null ){
						caseObj.Case_Owner_Manager_Email__c =  mapUser.get(caseObj.OwnerId).Manager.Email;
					}else if(Trigger.oldmap.get(caseObj.Id).OwnerId != Trigger.newMap.get(caseObj.Id).OwnerId){
						// Create new sharing object for case.
						  ID loggedinUserId = userinfo.getUserId();
					      List<CaseShare> caseShrList = new List<CaseShare>(); 
					      CaseShare caseShrObj1 = new CaseShare();
					      CaseShare caseShrObj2 = new CaseShare();
					      caseShrObj1.CaseId = caseObj.Id;
					      caseShrObj2.CaseId = caseObj.Id;
					      caseShrObj1.UserOrGroupId = Trigger.newMap.get(caseObj.Id).OwnerId;
					      caseShrObj2.UserOrGroupId = loggedinUserId;
					      caseShrList.add(caseShrObj1);
					      if(loggedinUserId != Trigger.newMap.get(caseObj.Id).OwnerId){
					      	caseShrList.add(caseShrObj2);
					      }
					      
					      //String strUserId = String.valueOf(Trigger.newMap.get(caseObj.Id).OwnerId);
					     // system.debug('--------------strUserId------------------'+strUserId);
					      caseShrObj1.CaseAccessLevel = 'Edit';
					      caseShrObj2.CaseAccessLevel = 'Edit';
					      List<Database.SaveResult> sr1 = Database.insert(caseShrList,false);
					      integer counts = 0;
					      for(Database.SaveResult sr : sr1){
					      	if(sr.isSuccess()){
					        	counts++;
					      	 	system.debug('--------------Inside if user------------------');
					      	 	if(loggedinUserId == Trigger.newMap.get(caseObj.Id).OwnerId){
					      	 		caseObj.Case_Owner_Manager_Email__c =  mapUser.get(caseObj.OwnerId).Manager.Email;	
					      	 	}else{
					      	 		if(counts ==2){
					      	 			caseObj.Case_Owner_Manager_Email__c =  mapUser.get(caseObj.OwnerId).Manager.Email;
					      	 		}
					      	 	}
					      	}else {}
					      }
    				}
    		}else{
    				 system.debug('--------------Inside if not user------------------');
					      	caseObj.Case_Owner_Manager_Email__c = '';
    		}	
    	} catch(Exception ex) { }// caseObj.addError('INSIDE = ' + mapUser.get(caseObj.OwnerId).Manager.Email); }
    }*/
    
	try {
       Map<Id,CaseShare> mapCaseShare = new Map<Id,CaseShare>();
       for(CaseShare obj : [Select id,CaseId from CaseShare where UserOrGroupId = :UserInfo.getUserId() and   
                                CaseId =:Trigger.New]) {
            mapCaseShare.put(obj.CaseId,obj);                    
       }
       List<CaseShare> caseShrList = new List<CaseShare>();
       for(Case caseObj : trigger.new) {
    		if(mapUser != null && caseObj.OwnerId != null && mapUser.containsKey(caseObj.OwnerId)){
                if(Trigger.oldmap == null) {
                    caseObj.Case_Owner_Manager_Email__c =  mapUser.get(caseObj.OwnerId).Manager.Email;
                } else if(Trigger.oldmap.get(caseObj.Id).OwnerId != Trigger.newMap.get(caseObj.Id).OwnerId){
                 	caseObj.Case_Owner_Manager_Email__c = mapUser.get(caseObj.OwnerId).Manager.Email;
              		caseShrList = new List<CaseShare>(); 
                  	CaseShare caseShrObj1 = new CaseShare();
                  	caseShrObj1.CaseId = caseObj.Id;
                  	caseShrObj1.UserOrGroupId = Trigger.newMap.get(caseObj.Id).OwnerId;
                  	caseShrObj1.CaseAccessLevel = 'Edit';
                  	caseShrList.add(caseShrObj1);
                  	CaseShare caseShrObj2 = new CaseShare();
                  	caseShrObj2.CaseId = caseObj.Id;
                  	caseShrObj2.UserOrGroupId =  UserInfo.getUserId();
                  	caseShrObj2.CaseAccessLevel = 'Edit';
                  	if(UserInfo.getUserId() != Trigger.newMap.get(caseObj.Id).OwnerId){  
                		if(mapCaseShare != null && mapCaseShare.get(caseObj.Id) == null) {
                            caseShrList.add(caseShrObj2); 
                    	}                    
                  	}
                }
			} else {
                 system.debug('--------------Inside if not user------------------');
            	 caseObj.Case_Owner_Manager_Email__c = '';
        	}   
    	}
    	List<Database.SaveResult> sr1 = Database.insert(caseShrList,false);
    	system.debug('>>>>>Database.SaveResult>>>>>'+sr1);
    } catch(Exception ex) {}
}