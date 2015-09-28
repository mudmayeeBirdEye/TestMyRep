trigger Approval_After on Approval__c (after insert, after update) {
	 System.Debug('>>TriggerHandler.BY_PASS_Approver_Trigger>>>'+TriggerHandler.BY_PASS_Approver_Trigger);
	 if(TriggerHandler.BY_PASS_Approver_Trigger == true) {
	 	return;
	 }	
	 try {
	 		 	
	 	List<Approval__c> approvalListTOUpdWithOwner = new List<Approval__c>();
	 	set<Id> accountIdSet = new set<Id>();
	    for(Approval__c appr : Trigger.new) {
	    	if(appr.Account__c != null) {
	    		accountIdSet.add(appr.Account__c);
	    	}
	    }
	    // Direct to Var
	    /********************************************************/
	    if(Trigger.isUpdate){
	    	ApprovalHelperCls.doDMLOpertnInAfterTgr();
	    	ApprovalHelperCls.chnageOpportunityRecordType(Trigger.new,'isUpdate'); 
	    }
	    if(Trigger.isInsert){
	    	ApprovalHelperCls.chnageOpportunityRecordType(Trigger.new,'isInsert'); 
	    	  
	    	/*
	       	if approval.recordType == 'Channel Cross Sell' && approval.Type__c = 'VAR to Direct' && Approval.module__c == 'Auto'
	       */
	    	ApprovalHelperCls.vARtoDirectAutoSubmitApproval(Trigger.new);
	    	/*******************************************************/
	    }
	    
	    Schema.DescribeSObjectResult result1 = Case.SObjectType.getDescribe();
	    Map<string,Schema.RecordTypeInfo> rtMapByName1 = result1.getRecordTypeInfosByName(); 
	    
	    Schema.DescribeSObjectResult result = Approval__c.SObjectType.getDescribe();
	    Map<Id,Schema.RecordTypeInfo> rtMapByName = result.getRecordTypeInfosById(); 
	    
	   
	    map<Id,Account> accountCurrentOwnerMap = new map<Id,Account>([select Name,Number_of_POC_Users__c,Current_Owner__c,Current_Owner__r.Name, Current_Owner__r.ManagerId
	    																from Account where Id IN :accountIdSet]);
	    																
	   																
	    List<Account> accountToUpdateList = new List<Account>();
	    Id manilaQueue = [Select Type, Name, Id From Group where type = 'Queue' and Name = 'Manila Retention Queue' limit 1].id; 
	    Id SupportRefundQueue = [Select Type, Name, Id From Group where type = 'Queue' and Name = 'Support Refund Approval Queue' limit 1].id; 
	    
	    for(Approval__c appr : Trigger.new) {
	    	// Case NUMBER : 02989446 // APPROVAL POC ACCOUNT // Deployed 7th October,2014
	    	if(Trigger.isUpdate && appr.RecordTypeId != null && rtMapByName.get(appr.RecordTypeId).getName() == 'POC Account'
	    	       && appr.Status__c=='Approved' && accountCurrentOwnerMap != NULL && accountCurrentOwnerMap.get(appr.Account__c) != NULL
	    	       && appr.Number_of_POC_Users__c != NULL){
				account acc = accountCurrentOwnerMap.get(appr.Account__c);
				acc.Number_of_POC_Users__c = appr.Number_of_POC_Users__c;
				accountToUpdateList.add(acc);
	    	}
	    	//System.Debug('>>11>>'+ appr.Refund_Approval_BU__c);
	    	//System.Debug('>>22>>'+ rtMapByName.get(appr.RecordTypeId).getName());
	    	//System.Debug('>>33>>'+ Trigger.oldMap.get(appr.Id).Reassign_Refund_To__c);
	    	//System.Debug('>>44>>'+ appr.Reassign_Refund_To__c);
	    	//System.Debug('>>55>>'+ Trigger.oldMap.get(appr.Id).Reassign_Refund_To__c);
	    	/*if((appr.Refund_Approval_BU__c  == 'Sales' && rtMapByName.get(appr.RecordTypeId).getName() == 'Refund Approval') && 
	    		(Trigger.IsInsert || (Trigger.isUpdate && ( 	
	    		  Trigger.oldMap.get(appr.Id).Refund_Approval_BU__c  != 'Sales')))) */
    		 if(Trigger.isUpdate && appr.RecordTypeId != null && rtMapByName.get(appr.RecordTypeId).getName() == 'Refund Approval' && 
	    		  //rtMapByName.get(Trigger.oldMap.get(appr.Id).RecordTypeId).getName() == 'Manual Refunds'
	    		   appr.Refund_Approval_BU__c  == 'Sales' && Trigger.oldMap.get(appr.Id).Refund_Approval_BU__c  != 'Sales') {
	    		  	Approval__c approvalObjTOUpd1 = new Approval__c(id = appr.id);
	    		/*if(accountCurrentOwnerMap != null &&
		    		appr.Account__c != null && accountCurrentOwnerMap.get(appr.Account__c) != null && 
		    		accountCurrentOwnerMap.get(appr.Account__c).Current_Owner__c != null &&
		    		accountCurrentOwnerMap.get(appr.Account__c).Current_Owner__r.Name != 'RCSF Sync' && appr.Total_Refund_Amount__c >= 200) {
		    			approvalObjTOUpd1.OwnerId = accountCurrentOwnerMap.get(appr.Account__c).Current_Owner__c;
		    	} else {
		    		approvalObjTOUpd1.OwnerId = manilaQueue;
	    		}*/
	    		approvalListTOUpdWithOwner.add(approvalObjTOUpd1); 
	    	}
	    	/*if((appr.Refund_Approval_BU__c  == 'Support') && rtMapByName.get(appr.RecordTypeId).getName() == 'Manual Refunds' && 	
	    		((Trigger.isUpdate && ( 	// Trigger.IsInsert ||
	    		  rtMapByName.get(Trigger.oldMap.get(appr.Id).RecordTypeId).getName() == 'Refund Approval' &&  
	    		  Trigger.oldMap.get(appr.Id).Refund_Approval_BU__c  != 'Support'))) && appr.Account__c != null &&
	    		  accountCurrentOwnerMap != null) */
    		  if(Trigger.isUpdate && appr.RecordTypeId != null && rtMapByName.get(appr.RecordTypeId).getName() == 'Manual Refunds' && 
	    		  rtMapByName.get(Trigger.oldMap.get(appr.Id).RecordTypeId).getName() == 'Refund Approval' && appr.Account__c != null &&
	    		  accountCurrentOwnerMap != null) {
    		  	Approval__c approvalObjTOUpd2 = new Approval__c(id = appr.id);
    			Case caseObj = new Case();
    			caseObj.AccountId = appr.Account__c;
    			caseObj.subject = 'Refund Approval Transfer from Sales for ' + accountCurrentOwnerMap.get(appr.Account__c).Name;
    			caseObj.Description  = appr.JustificationandDescription__c;
    			caseObj.Origin = 'Walk In';
    			caseObj.OwnerId = SupportRefundQueue;
    			caseObj.RecordTypeId = rtMapByName1.get('Support Refund Approval').getRecordTypeId(); //'012S00000004dNG';
    			insert caseObj;
    			if(caseObj.id != null) {
    				approvalObjTOUpd2.Case__c = caseObj.id;
    			}
    			//approvalObjTOUpd2.OwnerId = SupportRefundQueue;
    			approvalListTOUpdWithOwner.add(approvalObjTOUpd2); 
	    	}
	    }
	    if(approvalListTOUpdWithOwner != null && approvalListTOUpdWithOwner.size()>0) {
	    	update approvalListTOUpdWithOwner; 
    	}
		if(accountToUpdateList.size() > 0 ){
			TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
			update accountToUpdateList;
			TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
		}
	    
	 	set<Id> setAllUser = new set<Id>();
     	for(Approval__c appr : Trigger.new) {
     		setAllUser.add(appr.createdById); 
     		if(appr.Refund_Owner__c != null) {
     			setAllUser.add(appr.Refund_Owner__c);
     		}
     		if(appr.OwnerId != null) {
     			setAllUser.add(appr.OwnerId);
     		}
     	}
	     
     	map<Id,user> allUserManagerMap = new map<Id,user>();
     	if(setAllUser != null && setAllUser.size()>0) {
     		allUserManagerMap = new map<Id,user>([select ManagerID from User where ID IN :setAllUser and IsActive=true]);
     	}
	     
     	map<Id,map<string,Id>> mapPossibleAppToManagerId  = new map<Id,map<string,Id>>();
     	for(Approval__c appr : Trigger.new) {
	     	if(appr.Possible_Approval_From__c != null) {
	     		System.Debug('>>1>>');
	     		Map<string,Id> possibleValueToManagerIdMap = new Map<string,Id>();
	     		if(appr.Possible_Approval_From__c == 'Owner' && appr.OwnerId != null) {
	     			System.Debug('>>1>>');
	     			possibleValueToManagerIdMap.put(appr.Possible_Approval_From__c,appr.OwnerId);
	     		} else if(appr.Possible_Approval_From__c == 'Record Submitter') {
	     			System.Debug('>>2>>');
	     			possibleValueToManagerIdMap.put(appr.Possible_Approval_From__c,appr.createdById);
	     		} else if(appr.Possible_Approval_From__c == 'Refund Owner' && appr.Refund_Owner__c != null) {
	     			System.Debug('>>3>>');
	     			possibleValueToManagerIdMap.put(appr.Possible_Approval_From__c,appr.Refund_Owner__c);
	     		}
	     		mapPossibleAppToManagerId.put(appr.id,possibleValueToManagerIdMap);
	     	}
     	}
	     
	    system.Debug('>>>>44>>>'+ mapPossibleAppToManagerId);
	    
	    List<Approval__c> approvalListToUpd = new List<Approval__c>();
	    for(Approval__c appr : Trigger.new) {
		    if((appr.Possible_Approval_From__c != '' && appr.Possible_Approval_From__c != null) && (Trigger.isInsert || (trigger.isUpdate 
		    		&& (Trigger.oldMap.get(appr.id).Possible_Approval_From__c != appr.Possible_Approval_From__c || 
		    			Trigger.oldMap.get(appr.id).OwnerId != appr.OwnerId ||
		    			Trigger.oldMap.get(appr.id).Refund_Owner__c != appr.Refund_Owner__c)))) {
		    	if(mapPossibleAppToManagerId != null && mapPossibleAppToManagerId.get(appr.id) != null && 
		    		mapPossibleAppToManagerId.get(appr.id).get(appr.Possible_Approval_From__c) != null &&
		    		allUserManagerMap != null && allUserManagerMap.get(mapPossibleAppToManagerId.get(appr.id).get(appr.Possible_Approval_From__c)) != null) {
		    		Approval__c appObjtoUpd =  new Approval__c(Id = appr.Id);
		    		if(appr.RecordTypeId != null && rtMapByName.get(appr.recordtypeId).getName() != 'QuoteApprovalProcess'){
		    			appObjtoUpd.Level1Approver__c = allUserManagerMap.get(mapPossibleAppToManagerId.get(appr.id).get(appr.Possible_Approval_From__c)).ManagerId;
		    		}
	        		approvalListToUpd.add(appObjtoUpd);
		    	}
		    }
	    }
	    if(approvalListToUpd != null && approvalListToUpd.size()>0) {
	    	update  approvalListToUpd;
	    }
	    
	    /****************************************** Code for Quote Approval Status Starts ****************************************/
		try{
			Map<Id,RC_Quote__c> rcQuoteApprovalMap = new Map<Id,RC_Quote__c>();
			Set<Id> rcQuoteIdSet = new set<Id>();
		    for(Approval__c appr : Trigger.new) {
		    	if(appr.RC_Quote__c != null
		    		&& rtMapByName!= NULL && rtMapByName.get(appr.RecordTypeId)!= NULL  
		    		&& (rtMapByName.get(appr.RecordTypeId).getName()=='QuoteApprovalProcess') 
		    		&& (String.valueOf(appr.Status__c).containsIgnoreCase('Pending') || appr.Status__c=='Approved' || appr.Status__c=='Rejected' || appr.Status__c=='Returned')) {
		    		rcQuoteIdSet.add(appr.RC_Quote__c);
		    	}
	    	}
	    	Map<Id,RC_Quote__c> rcQuoteMap = new Map<Id,RC_Quote__c>([SELECT Id,Name,Approved_Status__c FROM RC_Quote__c WHERE Id IN :rcQuoteIdSet ]);
	    	List<RC_Quote__c> rcQuoteUpdateList = new List<RC_Quote__c>();
	    	for(Approval__c appr : Trigger.new){
	    		if(rcQuoteMap!= NULL && rcQuoteMap.containsKey(appr.RC_Quote__c) && rcQuoteMap.get(appr.RC_Quote__c)!= NULL){
	    			rcQuoteApprovalMap.put(appr.Id,rcQuoteMap.get(appr.RC_Quote__c));
	    			if(String.valueOf(appr.Status__c).containsIgnoreCase('Pending')){ 
	    				rcQuoteApprovalMap.get(appr.Id).Approved_Status__c = 'Submitted'; 
	    			}else if(appr.Status__c == 'Approved'){
	    				rcQuoteApprovalMap.get(appr.Id).Approved_Status__c = 'Approved';
	    			}else if(appr.Status__c == 'Rejected'){
	    				rcQuoteApprovalMap.get(appr.Id).Approved_Status__c = 'Rejected';
	    			}else if(appr.Status__c == 'Returned'){
	    				rcQuoteApprovalMap.get(appr.Id).Approved_Status__c = 'Required';
	    			}
	    			rcQuoteUpdateList.add(rcQuoteApprovalMap.get(appr.Id));
	    		}
	    	}
	    	if(!rcQuoteUpdateList.isEmpty()){
	    		update rcQuoteUpdateList;
	    	}
	    	
	    	/************** Update LineItems with Updated Approval Status of Quote Starts ***************/
	    	List<Line_Item__c> lineItemsList = new List<Line_Item__c>();
	        Map<Id,List<Line_Item__c>> quoteLineItemsMap = new Map<Id,List<Line_Item__c>>();
	    	lineItemsList=[SELECT Id,Approval_Status__c,Total_12_Month_Price__c,Quantity__c,Total_Price__c,Charge_Term__c,Total_Initial_Price__c,MRR__c,
  										 Category__c,Approval_Required__c,RC_Quote__c,Discount__c,Total_Initial_Discount__c,Total_12M_Discount__c FROM Line_Item__c
  										 WHERE RC_Quote__c IN:rcQuoteUpdateList];
  			 for(RC_Quote__c rcQuote : rcQuoteUpdateList){
				List<Line_Item__c> lineItemsToUpdateList = new List<Line_Item__c>();
				for(Line_Item__c lineItemObj : lineItemsList){
					if(lineItemObj.RC_Quote__c == rcQuote.Id){
						lineItemsToUpdateList.add(lineItemObj);
						quoteLineItemsMap.put(lineItemObj.RC_Quote__c,lineItemsToUpdateList);	
					}
				}
			}
			List<Line_Item__c> lineItemsWithApprovalStatusList = new List<Line_Item__c>(); 	
			for(RC_Quote__c rcQuoteObj : rcQuoteUpdateList){
		    	if(quoteLineItemsMap != NULL && quoteLineItemsMap.containsKey(rcQuoteObj.Id) && quoteLineItemsMap.get(rcQuoteObj.Id)!= NULL){
		    		List<Line_Item__c> tempLineItemList = new List<Line_Item__c>();
		    		for(Line_Item__c lineItemObj : quoteLineItemsMap.get(rcQuoteObj.Id)){ 
		    			if(rcQuoteObj.Approved_Status__c == 'Approved' || rcQuoteObj.Approved_Status__c == 'Rejected' || rcQuoteObj.Approved_Status__c == 'Submitted'){
							lineItemObj.Approval_Status__c = rcQuoteObj.Approved_Status__c;
							lineItemsWithApprovalStatusList.add(lineItemObj);
						}	
		    		}	
		    	}
			}								 
			TriggerHandler.BY_PASS_LINEITEM_ON_UPDATE();
		    update lineItemsWithApprovalStatusList; 
		    TriggerHandler.BY_PASS_LINEITEM_ON_UPDATE = false;
		    /************** Update LineItems with Updated Approval Status of Quote Ends ***************/	
		}catch(Exception ex) {
			Trigger.new[0].addError('Error : '+ex.getMessage());	
		}
	    /****************************************** Code for Quote Approval Status Ends ****************************************/
  	} catch(Exception ex) {}

	if(Trigger.isUpdate) {
		try {
			List<Approval.ProcessWorkitemRequest> listApprvProcess;
			map<Id,Approval__c> approvalMap = new map<Id,Approval__c>([Select id,name,createdDate,
		 											(Select Id, TargetObjectId,targetObject.type From ProcessInstances where Status = 'Pending') 
	                                  					From Approval__c where RecordType.Name = 'Agent Credit Transfers' and status__c = 'Rejected'
														and ID IN : Trigger.newMap.keyset() and IsAutoRejected__c = true order by createdDate desc]);
			Set<Id> setInstanceId = new set<ID>();
			for(Approval__c approvalObj : Trigger.New) {
				//setInstanceId = new set<ID>();
				Approval__c approvalNewObj = Trigger.newMap.get(approvalObj.Id);
				Approval__c approvalOldObj = Trigger.oldMap.get(approvalObj.Id);
				if(approvalOldObj.Status__c == 'PendingL1Approval' && approvalNewObj.Status__c == 'Rejected' 
				 && approvalNewObj.IsAutoRejected__c == true) {
					if(approvalMap != null && approvalMap.get(approvalObj.Id) != null && approvalMap.get(approvalObj.Id).ProcessInstances != null) {
						for(ProcessInstance processObj : approvalMap.get(approvalObj.Id).ProcessInstances) {
							setInstanceId.add(processObj.Id);
						}
					}	
				}	
			}
			if(setInstanceId != null && setInstanceId.size()>0) {
		        List<ProcessInstanceWorkitem> listworkItem = [Select ProcessInstanceId, Id From ProcessInstanceWorkitem 
		        												where ProcessInstanceId IN :setInstanceId];
			    if(listworkItem != null && listworkItem.size()>0) {
			    	listApprvProcess = new List<Approval.ProcessWorkitemRequest>();
			        for(ProcessInstanceWorkitem workItemObj : listworkItem) {
			        	//User userObj = new User(Id = '005800000036sJJ');
			        	//system.runAs(userObj) {
			        	 	System.Debug('>>>222>>'+UserInfo.getUserId());
			        		Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
				            req.setComments('Auto Reject.');
				            req.setAction('Reject');
				            //req.setNextApproverIds(new Id[]{'005800000036sJJ'});
				            req.setWorkitemId(workItemObj.Id);
				            listApprvProcess.add(req);		
			        	//}
			        }
			    }
			}
			
			/*for(Approval__c approvalObj : Trigger.New) {
				Approval__c approvalNewObj = Trigger.newMap.get(approvalObj.Id);
				Approval__c approvalOldObj = Trigger.oldMap.get(approvalObj.Id);
				if(approvalOldObj.Status__c == 'PendingL1Approval' && approvalNewObj.Status__c == 'Rejected' 
					&& approvalNewObj.IsAutoRejected__c == true) {
						if(approvalMap != null && approvalMap.get(approvalObj.Id) != null) {
							AgentCreditAutoRejectHelper appAutoRejectHelper = new AgentCreditAutoRejectHelper();
							List<Approval__c> approvallist = new List<Approval__c>();
							approvallist.add(approvalMap.get(approvalObj.Id));
							listApprvProcess = appAutoRejectHelper.AgentCreditAutoReject(approvallist);		
						}	
					
				}	
			}*/
		 	if(listApprvProcess != null && listApprvProcess.size()>0) {
		        	List<Approval.ProcessResult> result =  Approval.process(listApprvProcess); 
    	 	}	
		} catch(Exception ex) {}
		set<Id> setApprovalId = new set<Id>();
		for(Approval__c obj : Trigger.New) {
			setApprovalId.add(obj.id);
		}
		try {
			ApprovalFuture.getApprovalSteps(setApprovalId);
		} catch(Exception ex) {}
	}
}