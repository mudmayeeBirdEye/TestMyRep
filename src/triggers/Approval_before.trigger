/******************************
Trigger On Approval Object To Update The Current Owner,
When Status Is changed
****************/

trigger Approval_before on Approval__c (before update,before insert) {
     System.Debug('>>TriggerHandler.BY_PASS_Approver_Trigger>>>'+TriggerHandler.BY_PASS_Approver_Trigger);
     if(TriggerHandler.BY_PASS_Approver_Trigger == true) {
        return;
     }
     Set<Id> idUserSet = new Set<Id>();
     Set<Id> idAgentCreditSet = new Set<Id>();
     // populating values for recordtypeName 
     ApprovalHelperCls.describeRecordTypesByName(); // Direct to var
     ApprovalHelperCls.describeRecordTypesById(); // Direct to Var
     Set<Id> accountIdSet = new Set<id>(); // Direct to Var
     
     Set<id> OpportunityIds = new Set<id>();
     for(Approval__c appr: Trigger.new) {
        if(appr.Ownerid != null && !idUserSet.contains(appr.Ownerid)) {  
            idUserSet.add(appr.Ownerid);
        }
        // Direct to Var
        if(appr.Opportunity__c != null){
           OpportunityIds.add(appr.Opportunity__c);
        }
        // Direct to Var
        if(appr.Account__c != null){
           accountIdSet.add(appr.Account__c);
        }
        /*if(appr.Credit_Transfer_From_Agent__c != null && !idSet.contains(appr.Credit_Transfer_From_Agent__c)) {  
            idSet.add(appr.Credit_Transfer_From_Agent__c);
        }*/
        if(appr.Agent_Credit__c != null && !idAgentCreditSet.contains(appr.Agent_Credit__c)) {  
            idAgentCreditSet.add(appr.Agent_Credit__c);
        }
        if(appr.Credit_Transfer_To_Agent__c != null && !idUserSet.contains(appr.Credit_Transfer_To_Agent__c)) {  
            idUserSet.add(appr.Credit_Transfer_To_Agent__c);
        }
     } 
     // Direct to Var
     Map<id,Opportunity> OpportunityMap = new Map<id,Opportunity>([SELECT Partner_Owner__c,AccountId,Effective_No_of_Employees_Range__c,Forecasted_Users__c, 
     																	Partner_ID__c,Partner_Lead_Source__c,Ultimate_Parent_Account_Partner_ID__c,OwnerId, 
     																	Inside_Sales_Rep__c
     																	FROM Opportunity WHERE id IN: OpportunityIds]);
     ApprovalHelperCls.opportunityStaticMap = OpportunityMap.clone();
     // Direct to Var
     ApprovalHelperCls.accountStaticMap = new Map<id,Account>([SELECT id,MRR_Transfer_Effective_date__c,Current_Owner__c,Partner_ID__c,Inside_Sales_Rep__c, 
     														  Ultimate_Partner_ID__c,Ultimate_Partner_Name__c,RC_Account_Status__c
     														  FROM Account WHERE ID IN:accountIdSet]);
     //Direct to VAR
 	 if(Trigger.isUpdate){ 
 	 	ApprovalHelperCls.approvalNewStaticMap = Trigger.newMap;
 		ApprovalHelperCls.oldApprovalStaticMap = Trigger.oldMap;
 		/* createAccntSplitDirToVar method does the following :- 
 			1. Updates the Approval record itself with status (thats why in before trigger)
 			2. Creates lists of related records and those lists are eventually being updated/inserted in Approval_After Trigger.  			
 		*/
 		ApprovalHelperCls.createAccntSplitDirToVar();  
 	 }
     
     map<Id,Id> agentCreditMap;
     if(idAgentCreditSet != null && idAgentCreditSet.size()>0) {
        List<Agent_Credit__c> agentCreditList = [select Id,OwnerId from Agent_Credit__c where ID IN :idAgentCreditSet];
        if(agentCreditList != null && agentCreditList.size()>0) {
            agentCreditMap = new map<Id,Id>();
            for(Agent_Credit__c agentCreditObj : agentCreditList) {
                agentCreditMap.put(agentCreditObj.Id,agentCreditObj.OwnerId);
                idUserSet.add(agentCreditObj.OwnerId);
            }
        }
     }
         
     map<Id,User> userMap;
     if(idUserSet != null && idUserSet.size()>0) {
        userMap = new map<Id,User>([select Email,Id,ManagerID,Manager.Email,
                                    Division, FirstName, LastName, Manager.FirstName, Manager.LastName, UserRole.Name, PID__c, Team__c  
                                    from User where ID IN :idUserSet and IsActive=true]);
     }
     
     //Schema.DescribeSObjectResult result = Approval__c.SObjectType.getDescribe();
     //Map<ID,Schema.RecordTypeInfo> rtMapByName = result.getRecordTypeInfosById();
     Set<Id> refundOwnerIdSet = new  Set<Id>();
     for(Approval__c appr : Trigger.new) {
        if(appr.RecordTypeId != null && ApprovalHelperCls.rtMapByName.get(appr.recordtypeId).getName() == 'Refund Approval' && appr.Refund_Owner__c != null) {
            refundOwnerIdSet.add(appr.Refund_Owner__c);
        }
     }   
     
     map<Id,user> refundOwnerMap = new map<Id,user>();
     if(refundOwnerIdSet != null && refundOwnerIdSet.size()>0) {
        refundOwnerMap  = new map<Id,user>([select ManagerID from User where ID IN :refundOwnerIdSet and IsActive=true]);
     }   
    
     if(trigger.IsInsert){
        User currentUser = new User();
        User userIdentifiesManager = new User();
        Set<id> CaseIds = new Set<id>();
        
        Set<id> AgentCreditIds = new Set<id>();
        Set<id> ContactIds = new Set<id>(); 
        
        // getting the loggedIn user detail //
        currentUser = [SELECT Id,ContactId,Contact.Account.Inside_Sales_Rep__c,ManagerId, profile.Name, Manager.ManagerId, Manager.Manager.ManagerId,
                                Contact.Account.Inside_Sales_Rep__r.ManagerId,Contact.Account.Inside_Sales_Rep__r.Manager.ManagerId,
                                Contact.Account.Current_Owner__c,Contact.Account.Current_Owner__r.ManagerId,Contact.Account.Current_Owner__r.Manager.ManagerId
                                FROM User WHERE Id =: UserInfo.getUserId()];
        Id userIdentifiesManagerId ;
        for(Approval__c appr:Trigger.new){
            if(appr.Case__c != null){
                CaseIds.add(appr.Case__c);
            }else if(appr.Opportunity__c != null){
                OpportunityIds.add(appr.Opportunity__c);
            }else if(appr.Agent_Credit__c != null){
                AgentCreditIds.add(appr.Agent_Credit__c);
            }else if(appr.Contact__c != null){
                ContactIds.add(appr.Contact__c);
            }
            if(appr.RecordTypeId != null && ApprovalHelperCls.rtMapByName.get(appr.recordtypeId).getName() == 'QuoteApprovalProcess'){
                if(currentUser != null && currentUser.profile.Name.contains('RC Partner')){
                    if(currentUser.Contact.Account.Inside_Sales_Rep__c != NULL){
                        userIdentifiesManagerId = currentUser.Contact.Account.Inside_Sales_Rep__c;
                    }else if(currentUser.Contact.Account.Inside_Sales_Rep__c == NULL && currentUser.Contact.Account.Current_Owner__c!= NULL){
                        userIdentifiesManagerId = currentUser.Contact.Account.Current_Owner__c;
                    }    
                }
            }   
	    }
        if(currentUser != null && currentUser.profile.Name.contains('RC Partner') && userIdentifiesManagerId != NULL){
            userIdentifiesManager = [SELECT Id,Manager_Id__c,Manager_Manager_ID__c FROM USER WHERE Id =: userIdentifiesManagerId];
        }
                  
        
        Map<id,Case> CaseMap = new Map<id,Case>([SELECT AccountId FROM Case WHERE id IN : CaseIds]);
        
        
        Map<id,Agent_Credit__c> AgentCMap = new Map<id,Agent_Credit__c>([SELECT Account__c FROM Agent_Credit__c WHERE id IN: AgentCreditIds]);
        Map<id,Contact> ContactMap = new Map<id,Contact>([SELECT Accountid FROM Contact WHERE id IN: ContactIds]);
        
        Integer i=0;
            for(Approval__c appr:Trigger.new) {
                if(agentCreditMap != null && appr.Agent_Credit__c != null && agentCreditMap.containskey(appr.Agent_Credit__c)) {
                    appr.Credit_Transfer_From_Agent__c = agentCreditMap.get(appr.Agent_Credit__c);
                }
                if(userMap != null && appr.Ownerid != null && userMap.containskey(appr.Ownerid)) {
                        appr.Submitter_Email__c = userMap.get(appr.Ownerid).Email; 
                        appr.Manager_Email__c =  userMap.get(appr.Ownerid).Manager.Email;   
                }
                if(userMap != null && appr.Credit_Transfer_From_Agent__c != null && userMap.containskey(appr.Credit_Transfer_From_Agent__c)) {
                    //appr.Transfer_from_Mgr_Email__c = userMap.get(appr.Credit_Transfer_From_Agent__c).Manager.Email; 
                    appr.Transfer_from_Mgr_Name__c = userMap.get(appr.Credit_Transfer_From_Agent__c).ManagerId;     
                }
                if(userMap != null && appr.Credit_Transfer_To_Agent__c != null && userMap.containskey(appr.Credit_Transfer_To_Agent__c)) {
                    //appr.Transfer_to_Mgr_Email__c = userMap.get(appr.Credit_Transfer_To_Agent__c).Manager.Email; 
                    appr.Transfer_to_Mgr_Name__c = userMap.get(appr.Credit_Transfer_To_Agent__c).ManagerId;      
                }
                
                if(appr.RecordTypeId != null && ApprovalHelperCls.rtMapByName.get(appr.recordtypeId).getName() == 'Refund Approval' && appr.Refund_Owner__c != null
                    && refundOwnerMap != null && refundOwnerMap.get(appr.Refund_Owner__c) != null) {
                    appr.Refund_Owner_Manager__c = refundOwnerMap.get(appr.Refund_Owner__c).ManagerID;
                }
                /*These field must be filled in insertion time, They are hidden from page layout and used in email notification */
                      //appr.Submitter_Email__c = [SELECT Email FROM User WHERE id =: appr.Ownerid ].Email;
                      //appr.Manager_Email__c = [SELECT Email FROM User WHERE id =:[SELECT ManagerID FROM User WHERE id=:appr.Ownerid].ManagerID ].Email;
               /* Default To Manager */
                 //        appr.Level1Approver__c = [SELECT ManagerID FROM User WHERE id=:appr.Ownerid].ManagerID;
                 
                  /********************************************************************************************************
                   *    @Description    :   Verifying if current user the profile name contains  Sales or Sales Manager   *
                   *                        or Sales Director then on the basis of profile name, providing values for     *
                   *                        following field Level1Approver, Level2Approver, Level3Approver.               *  
                   *    @Created By     :   India Team.                                                                   *
                   *    @case Number    :   02739719.                                                                     * 
                   *    Created Dated   :   03-July-2014.                                                                 *  
                   *******************************************************************************************************/
               try{
                    /* verifying the if profile name contains  Sales or Sales Manager or Sales Director and on the basis of profile name, providing 
                       values for  following field Level1Approver, Level2Approver ,Level3Approver. */
                    if(currentUser != null && appr.RecordTypeId != null && (ApprovalHelperCls.rtMapByName.get(appr.recordtypeId).getName() == 'QuoteApprovalProcess' 
					    || ApprovalHelperCls.rtMapByName.get(appr.recordtypeId).getName() == 'POC Account')){
                        if(currentUser.ManagerId != null){
                            if(((ApprovalHelperCls.rtMapByName.get(appr.recordtypeId).getName() == 'QuoteApprovalProcess') && (currentUser.profile.Name == 'Sales Agent'
                                || currentUser.profile.Name == 'Sales Agent 3.0'
                                || currentUser.profile.Name == 'Sales Director 3.0'
                                || currentUser.profile.Name == 'Sales Manager'
                                || currentUser.profile.Name == 'Channel Sales'
                                || currentUser.profile.Name == 'Channel Sales Manager')) || (ApprovalHelperCls.rtMapByName.get(appr.recordtypeId).getName() == 'POC Account')){
                                appr.Level1Approver__c = currentUser.ManagerId;     
                                If(currentUser.Manager.ManagerId != Null){  
                                    appr.Level2Approver__c = currentUser.Manager.ManagerId;                 
                                    if(currentUser.Manager.Manager.ManagerId != null ){
                                        appr.Level3Approver__c = currentUser.Manager.Manager.ManagerId; 
                                    }
                                }
                            }
                        }
                        if(currentUser.profile.Name.contains('RC Partner')){
                            if(userIdentifiesManager != NULL ){
                                appr.Level1Approver__c = userIdentifiesManager.id;
                                if(userIdentifiesManager.Manager_Id__c != NULL){
                                    appr.Level2Approver__c = userIdentifiesManager.Manager_Id__c;
                                    if(userIdentifiesManager.Manager_Manager_ID__c != NULL){
                                        appr.Level3Approver__c = userIdentifiesManager.Manager_Manager_ID__c;
                                    }
                                }
                            }
                        }
                    }   
                }catch(Exception ex){
                    system.debug('####### Exception Message #### '+ex.getMessage());
                    system.debug('####### Exception Line Number #### '+ex.getLineNumber());
                }
                /****************************************************************************************************************
                *   @Description    :   Updating the AccountId in Approval if it is null , working on Sepecific RecordTypeIds   *  
                *   @Created By     :   India Team.                                                                             *
                *   @case Number    :   02739719.                                                                               *   
                *   Created Dated   :   03-July-2014.                                                                           *    
                ****************************************************************************************************************/
                
                try{
                    if(appr.Account__c == null && appr.recordtypeId != null && (ApprovalHelperCls.rtMapByName.get(appr.recordtypeId).getName() == 'Farming Claim Owner' 
                                               || ApprovalHelperCls.rtMapByName.get(appr.recordtypeId).getName() == 'Agent Credit Transfers')){
                        System.debug('====appr.Case__c===='+appr.Case__c);
                        if(appr.Case__c != null && CaseMap.get(appr.Case__c).AccountID != null){
                            appr.Account__c = CaseMap.get(appr.Case__c).AccountID;
                        }else if(appr.Opportunity__c != null && OpportunityMap.get(appr.Opportunity__c).AccountID != null){
                            appr.Account__c = OpportunityMap.get(appr.Opportunity__c).AccountID;
                        }else if(appr.Agent_Credit__c != null && AgentCMap.get(appr.Agent_Credit__c).Account__c != null){
                            appr.Account__c = AgentCMap.get(appr.Agent_Credit__c).Account__c;
                        }else if(appr.Contact__c != null && ContactMap.get(appr.Contact__c).AccountId != null){
                            appr.Account__c = ContactMap.get(appr.Contact__c).AccountId;
                        }
                    }
                }catch(Exception ex){
                    system.debug('####### Exception Message #### '+ex.getMessage());
                    system.debug('####### Exception Line Number #### '+ex.getLineNumber());
                } 
            }
     }
    
    
    if(trigger.IsUpdate){
        
             Set<id> userIds = new Set<Id>();
            
             Map<id, User> managerIDs;
             Map<id, RecordType> recordTypeMap = new Map<id, RecordType>([Select  Name, IsActive, Id From RecordType r 
                                                                          WHERE SobjectType ='Approval__c' AND isActive = true]); 
             Map<String,ID> queueMap = new Map<String,ID>();
            
            for(Group gp : [Select Name, Id From Group  WHERE  Type='Queue' AND (Name ='Bid Desk' OR Name='Support Approval Queue')]) {
                queueMap.put(gp.Name, gp.Id);
            }
            for(Approval__c appr:Trigger.new){
                userIds.add(appr.OwnerID);
            }
            if(userIds.size()>0) {
                managerIDs  = new Map<id, User>([SELECT  ManagerId FROM User WHERE Id IN:userIds]);
            }
        
        
        
      Integer i = 0;
           List<Agent_Credit__c> agentCreditList =  new List<Agent_Credit__c>();
           List<Account> accListTOUPD = new List<Account>();
           for(Approval__c appr:Trigger.new) {
            
            Approval__c apprOld = Trigger.oldMap.get(appr.id);
            
            if(appr.RecordTypeId != null && ApprovalHelperCls.rtMapByName.get(appr.recordtypeId).getName() == 'Refund Approval' && appr.Refund_Owner__c != null
                    && refundOwnerMap != null && refundOwnerMap.get(appr.Refund_Owner__c) != null) {
                    appr.Refund_Owner_Manager__c = refundOwnerMap.get(appr.Refund_Owner__c).ManagerID;
            }
            
             /*if(appr.Status__c == 'PendingL1Approval' && trigger.old[i].Status__c =='New' && recordTypeMap.get(appr.RecordTypeId).Name =='Refund Approval'){
                  try{
                       //appr.Ownerid= [Select ManagerId from User where Id=:appr.Ownerid ].ManagerId;
                       appr.Ownerid =  managerIDs.get(appr.Ownerid).ManagerId;  
                  }catch(Exception e){Trigger.new[i].addError(e);}
             }*/
              //if the amount is $1000 or above,(0058000000371o2AAA,Ryan Azus Main user id)
              if(appr.Status__c == 'PendingL2Approval' && trigger.old[i].Status__c =='PendingL1Approval' && (appr.Total_Refund_Amount__c != null && Integer.ValueOf(appr.Total_Refund_Amount__c) != 0 && 
                              appr.Total_Refund_Amount__c>=1000)
                && recordTypeMap.get(appr.RecordTypeId).Name =='Refund Approval'){
                  try{
                          //appr.Ownerid = [Select id from User where Name='Ryan Azus Main' OR id='0058000000371o2AAA'].id ;    
                       }catch(Exception e){Trigger.new[i].addError(e);}
             }
             /*if(appr.Status__c == 'PendingL2Approval' && trigger.old[i].Status__c =='PendingL1Approval'){
                   try{
                       appr.Ownerid = [Select id from group where Type=:'Queue' and Name=:'Bid Desk'].id ;  
                       }catch(Exception e){Trigger.new[i].addError(e);}
             }*/
            
             if( recordTypeMap.get(appr.RecordTypeId).Name =='Refund Approval' && (appr.Status__c == 'PendingL1Approval' && trigger.old[i].Status__c =='New' && 
                         (appr.Total_Refund_Amount__c != null && Integer.ValueOf(appr.Total_Refund_Amount__c) != 0 && appr.Total_Refund_Amount__c<20)) 
                    || (appr.Status__c == 'PendingL2Approval' && trigger.old[i].Status__c =='PendingL1Approval' && 
                            (appr.Total_Refund_Amount__c != null && Integer.ValueOf(appr.Total_Refund_Amount__c) != 0 && 
                                    appr.Total_Refund_Amount__c < 1000))
                    || (appr.Status__c == 'PendingL3Approval' && trigger.old[i].Status__c =='PendingL2Approval')){
                     
                     try{
                          appr.Status__c='PendingL3Approval';
                          //appr.Ownerid = [Select id from group where Type=:'Queue' and Name=:'Bid Desk'].id ;
                          //appr.Ownerid =   queueMap.get('Bid Desk');    
                       }catch(Exception e){Trigger.new[i].addError(e);}
                    
                    }
             /*Commaon Code for both RecordType*/       
             /*if(appr.Status__c == 'New' && trigger.old[i].Status__c != 'New'){
                        appr.Ownerid = appr.CreatedById;
             }
             if(appr.Status__c == 'Returned' && trigger.old[i].Status__c != 'Returned'){
                        appr.Ownerid = appr.CreatedById;
             }*/
             
             /*Manual Refunds*/
             
             /*if(appr.Status__c == 'Approved By Manager' && recordTypeMap.get(appr.RecordTypeId).Name == 'Manual Refunds') {
                    try {
                         appr.Ownerid =  managerIDs.get(appr.Ownerid).ManagerId;
                    } catch(Exception e) {  appr.addError(e);   }   
             }
             if (appr.Status__c == 'Approved By Queue' && recordTypeMap.get(appr.RecordTypeId).Name == 'Manual Refunds' ) {
                    appr.Ownerid =  queueMap.get('Support Approval Queue');
             }
             if (appr.Status__c == 'Approved' && apprOld.Status__c != 'New' && recordTypeMap.get(appr.RecordTypeId).Name == 'Manual Refunds') {
                    appr.Ownerid =  queueMap.get('Bid Desk');
             }
             if (appr.Status__c == 'Approved' && apprOld.Status__c == 'New' && recordTypeMap.get(appr.RecordTypeId).Name == 'Manual Refunds') {
                    try {
                         appr.Ownerid =  managerIDs.get(appr.Ownerid).ManagerId;
                    } catch(Exception e) {  appr.addError(e);   } 
             }*/
             if(agentCreditMap != null && appr.Agent_Credit__c != null && agentCreditMap.containskey(appr.Agent_Credit__c)) {
                appr.Credit_Transfer_From_Agent__c = agentCreditMap.get(appr.Agent_Credit__c);
             }
             if(userMap != null && appr.Credit_Transfer_From_Agent__c != null && userMap.containskey(appr.Credit_Transfer_From_Agent__c)) {
                    //appr.Transfer_from_Mgr_Email__c = userMap.get(appr.Credit_Transfer_From_Agent__c).Manager.Email; 
                    appr.Transfer_from_Mgr_Name__c = userMap.get(appr.Credit_Transfer_From_Agent__c).ManagerId;     
             }
             if(userMap != null && appr.Credit_Transfer_To_Agent__c != null && userMap.containskey(appr.Credit_Transfer_To_Agent__c)) {
                    //appr.Transfer_to_Mgr_Email__c = userMap.get(appr.Credit_Transfer_To_Agent__c).Manager.Email; 
                    appr.Transfer_to_Mgr_Name__c = userMap.get(appr.Credit_Transfer_To_Agent__c).ManagerId;     
             }
             if (appr.Status__c == 'Approved' && apprOld.Status__c != 'Approved' &&                 // apprOld.Status__c == 'PendingL1Approval'
                    recordTypeMap.get(appr.RecordTypeId).Name == 'Agent Credit Transfers') {
                    try {
                        if(appr.Agent_Credit__c != null && userMap.containskey(appr.Credit_Transfer_To_Agent__c)) {
                            Agent_Credit__c agenCrdObj = new Agent_Credit__c(Id = appr.Agent_Credit__c);
                            agenCrdObj.OwnerId = appr.Credit_Transfer_To_Agent__c;
                            agenCrdObj.Agent_Email__c = userMap.get(appr.Credit_Transfer_To_Agent__c).Email;
                            //agenCrdObj.X12M_Sales_Booking_Amount__c = appr.Amount_of_the_transfer__c;
                            agenCrdObj.Agent_Division__c = userMap.get(appr.Credit_Transfer_To_Agent__c).Division;
                            agenCrdObj.Agent_First_Name__c = userMap.get(appr.Credit_Transfer_To_Agent__c).FirstName;
                            agenCrdObj.Agent_Last_Name__c = userMap.get(appr.Credit_Transfer_To_Agent__c).LastName;
                            agenCrdObj.Agent_Manager_Email__c= userMap.get(appr.Credit_Transfer_To_Agent__c).Manager.Email;
                            agenCrdObj.Agent_Manager_First_Name__c = userMap.get(appr.Credit_Transfer_To_Agent__c).Manager.FirstName;
                            agenCrdObj.Agent_Manager_Last_Name__c = userMap.get(appr.Credit_Transfer_To_Agent__c).Manager.LastName;
                            agenCrdObj.Agent_Role__c = userMap.get(appr.Credit_Transfer_To_Agent__c).UserRole.Name;
                            agenCrdObj.Agent_SPID__c = userMap.get(appr.Credit_Transfer_To_Agent__c).PID__c;
                            agenCrdObj.Agent_Team__c = userMap.get(appr.Credit_Transfer_To_Agent__c).Team__c;
                            //update agenCrdObj;
                            agentCreditList.add(agenCrdObj);
                        } 
                    } catch(Exception e) {  appr.addError(e);   } 
             }
             
             // Invoice Approval
             
             if (appr.Status__c == 'Completed' && apprOld.Status__c == 'Pending Finance Approval' && 
                    recordTypeMap.get(appr.RecordTypeId).Name == 'Invoicing Request') {
                    try {
                        if(appr.Account__c != null) {
                            Account accountTOUpdate = new Account (Id = appr.Account__c);
                            accountTOUpdate.Sign_up_Purchase_Limit__c = appr.Sign_up_Purchase_Limit__c;
                            accountTOUpdate.Payment_Method__c = 'Invoice';
                            accountTOUpdate.Monthly_Credit_Limit__c = appr.Monthly_Credit_Limit__c;
                            accountTOUpdate.Approval_Date__c = appr.Completed_Date__c;
                            accountTOUpdate.Active_Invoice_Approval__c = appr.Id;
                            accountTOUpdate.Invoice_Terms__c = appr.Invoice_Terms__c;
                            accountTOUpdate.Payment_Terms__c = appr.Payment_Terms__c;
                            accListTOUPD.add(accountTOUpdate);
                        }     
                    } catch(Exception e) {  appr.addError(e);   } 
             }
          i++;
          }
          try {
            if(agentCreditList != null && agentCreditList.size()>0) {
                update agentCreditList;
            }
            
            if(accListTOUPD != null && accListTOUPD.size()>0) {
                update accListTOUPD;
            }
          } catch(Exception ex) {}
          
          //===== Farming Claim Owner Change Approved ====
          // All the Approved Requests will be processed
          // The related account will be updated with Audit fields
         
          //Map<id,Account> AccountMap;
          List<Account> AccToUpdate = new List<Account>();
          Map<Id,Approval__c> AccountToApprovalMap = new Map<Id,Approval__c>();
          for(Approval__c appr:Trigger.new){
            if( appr.Status__c=='Approved' && 
                recordTypeMap.get(appr.RecordTypeId).Name =='Farming Claim Owner' && 
                appr.Account__c != null) 
            {
                AccountToApprovalMap.put(appr.Account__c,appr);
            }           
          }
          
          if(AccountToApprovalMap.keyset().size()>0)
          // Diirect to Var
          //ApprovalHelperCls.accountStaticMap = new Map<id,Account>([Select id,MRR_Transfer_Effective_date__c from Account Where ID IN:AccountToApprovalMap.keyset()]);
          
          for(ID accID:AccountToApprovalMap.keyset())
          {
            Approval__c appr = new Approval__c();
            appr = AccountToApprovalMap.get(accID);
            Account acc = new Account();
            // Direct To VAR
            acc = ApprovalHelperCls.accountStaticMap.get(accID);
            
            if(appr.Status__c=='Approved')
            {
                //Set the MRR Transfer Effective Date to the date based on
                //      If Referral OR Existing Customer, then = Current Date
                //      If Internal Transfer, then = First day of the next month
                
                
                if(appr.Transfer_Type__c =='Referral'||appr.Transfer_Type__c =='Existing Customer')
                    acc.MRR_Transfer_Effective_date__c = Date.today();
                
               
                if(appr.Transfer_Type__c =='Internal Transfer')
                    acc.MRR_Transfer_Effective_date__c = Date.today().toStartOfMonth().addMonths(1);
                
                // Update the account's new Current Owner and audit the previous current owner.
                 acc.Current_Owner_Previous__c = appr.Current_Owner__c;
                 acc.Current_Owner__c = appr.Claiming_Requestor__c;
                 AccToUpdate.add(acc);
            }
            
          }
          if(AccToUpdate.size()>0) Update AccToUpdate;
          
        }
}