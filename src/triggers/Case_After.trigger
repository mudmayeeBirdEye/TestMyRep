trigger Case_After on Case (after insert, after update, after delete) {
	
	if(Trigger.isUpdate || Trigger.isInsert) {
	
		MilestoneUtils.closeCaseMilestone(trigger.oldMap, trigger.newMap);
		if(Trigger.isUpdate) {
		   try{ 
		        Schema.DescribeSObjectResult result = Case.SObjectType.getDescribe();
		        Map<ID,Schema.RecordTypeInfo> rtMapByName = result.getRecordTypeInfosById();
		      
		        Set<Id> setAccountId = new Set<Id>();
		        List<case> lstCase=new List<case>();
		        Map<ID,Account> mapAccount=new Map<ID,Account>();
		         
		        for(Case caseObj : trigger.new) {
		           if((rtMapByName.get(caseObj.RecordTypeId ).getName() == 'Migration Request') && 
		                (trigger.oldMap.get(caseObj.Id).Status!='Closed' && (caseObj.Status=='Closed' || caseObj.IsClosed))
		                  && Trigger.isUpdate && caseObj.AccountId!=null ){
		                  lstCase.add(caseObj);
		                  setAccountId.add(caseObj.AccountId);
		            }
		        }
		        
				if(lstCase.size()>0 && setAccountId.size()>0){
		             mapAccount=new Map<ID,Account>([Select id,AccMigrationFlag__c from Account where id IN:setAccountId]);
		             for(Case caseObj : lstCase) {
		                mapAccount.get(caseObj.AccountId).AccMigrationFlag__c='OFFICE2012.'+caseObj.ClosedDate;
		             }
		           update mapAccount.values();
		        }
		        if(TriggerHandler.BY_PASS_CASE_Trigger == false) {
			        if(TriggerHandler.ALLOW_TRIGGER_REQUEST_ONCE()){
						PortingESBHelper.validateOnAfterUpdateEvent(trigger.new, trigger.oldMap, rtMapByName);
		            }
		        }
		        
		        for(Case caseObj : Trigger.New) {
		        	Case oldCaseObj = Trigger.oldMap.get(caseObj.Id);
		        	System.debug('>>>TriggerHandler.BY_PASS_CASE_Trigger 11>>'+TriggerHandler.BY_PASS_CASE_Trigger);
		            if( 
		            ((oldCaseObj.isLastCaseCommentPublic__c != caseObj.isLastCaseCommentPublic__c 
		                 	|| oldCaseObj.Last_Case_Comment__c != caseObj.Last_Case_Comment__c 
		                 	|| oldCaseObj.Last_Public_Comment__c != caseObj.Last_Public_Comment__c 
		                 	|| oldCaseObj.Last_Public_Comment_Timestamp__c != caseObj.Last_Public_Comment_Timestamp__c) 
		                 	&& TriggerHandler.BY_PASS_CASE_Trigger == true) 
		             ) {
	                    TriggerHandler.BY_PASS_CASE_Trigger = false; 
		            } 
		            System.debug('>>>TriggerHandler.BY_PASS_CASE_Trigger 22>>'+TriggerHandler.BY_PASS_CASE_Trigger);
		        }
		        
		        /*for(case newCaseObj : trigger.new){
	                  Case oldCaseObj = trigger.oldMap.get(newCaseObj.Id);
	                	if(rtMapByName.get(newCaseObj.RecordTypeId ).getName() == 'Porting - In (NeuStar)'
						|| rtMapByName.get(newCaseObj.RecordTypeId ).getName() == 'Porting - In (RC UK)'
						|| rtMapByName.get(newCaseObj.RecordTypeId ).getName() == 'Porting - In (RC)'){
		            		Boolean errorOccured = false;
							if(newCaseObj.RC_Porting_Order_ID__c == null) {
	                        	newCaseObj.RC_Porting_Order_ID__c.addError('Porting Order Id must not be blank.');
	                        	errorOccured = true;
	                        }
	                       	if(String.isBlank(newCaseObj.RC_User_Id__c)) {
								newCaseObj.RC_User_Id__c.addError('User Id must not be blank in associate Account.');
								errorOccured = true;
	                       	}
	                       	if(newCaseObj.Status == null) {
								newCaseObj.Status.addError('Status can not be none.');
								errorOccured = true;
	                       	}
	                       	if(newCaseObj.Porting_last_status_change_date__c == null) {
	                           newCaseObj.Porting_last_status_change_date__c.addError('Porting last status change date can not be empty');
	                           errorOccured = true;
	                       	}
	                       	if(newCaseObj.Status == 'Rejected' && newCaseObj.Porting_Reject_Reason__c == null) {
								newCaseObj.Porting_Reject_Reason__c.addError('Porting Reason is missing.');	
								errorOccured = true;
	                       	}
	                       	if(newCaseObj.Status == 'Transfer Date Confirmed' && newCaseObj.Porting_Estimated_Completion_Date__c == null) {
	                       		//newCaseObj.Porting_Estimated_Completion_Date__c.addError('Porting Estimated Completion Date is Missing.');
	                       		// errorOccured = true;
	                       	}
	                       	Boolean updateESB = false;
	                       	/*if((newCaseObj.status != oldCaseObj.status 
		                  		|| newCaseObj.Porting_Reject_Reason__c != oldCaseObj.Porting_Reject_Reason__c)
		                  		&& rtMapByName.get(newCaseObj.RecordTypeId ).getName() == 'Porting - In'
	                  		) { 
	                  			if(!errorOccured) {
	                  				updateESB = true;
		                       	}
	                  		}*/
							/*if((newCaseObj.Porting_last_status_change_date__c != oldCaseObj.Porting_last_status_change_date__c)
		                  		&& (rtMapByName.get(newCaseObj.RecordTypeId ).getName() == 'Porting - In (RC UK)'
		                  			|| rtMapByName.get(newCaseObj.RecordTypeId ).getName() == 'Porting - In (RC)')
	                  		) { 
	                  			if(!errorOccured) {
	                  				updateESB = true;
		                       	}
	                  		}
	                  		if(updateESB) {
	                  			if(!Test.isRunningTest()) {
	                  				RC_ESB_PortingOrderHelper.updatePortingOrder(newCaseObj.id);
	                  			}
	                  		}
			           }
					}*/ 
		        
		   }catch(Exception e){} 
		   try {
		        if(EntitlementHelper.IsEntitlementsEnabled())
		            EntitlementHelper.closeCaseAssignedMilestone(trigger.new, trigger.oldMap);
		    } catch(Exception e) {}
		}
		
		if(TriggerHandler.BY_PASS_CASE_ON_UPDATE || TriggerHandler.BY_PASS_CASE_ON_INSERT){
			System.debug('### RETURNED FROM CASE AFTER TRG ###');
			return;
		} else {
			System.debug('### STILL CONTINUE FROM CASE AFTER TRG ###');
		}
		
		if(TriggerHandler.BY_PASS_AFTER){
	        System.debug('### RETURNED FROM CASE AFTER TRG FOR STANDARD LAYOUT ###');
	        return;
	    } else {
	        TriggerHandler.BY_PASS_AFTER = true;
	        System.debug('### SETTING BY PASS FOR STANDARD LAYOUT ON CASE AFTER TRG ###');
	    } 
	    
		try {
			Severity1_CaseHelperClass.checkForEmail(trigger.newMap, (trigger.isInsert ? null : trigger.oldMap));
		} catch(Exception e) {}
		try {
			/*************************** Telus S2S Code included here Starts *************************/
			// runs after inser and update and check if case is closed then stop sharing with TELUS
			TelusExternalSharingHelperCls.stopSharingForClosedCases(trigger.new);
			if(Trigger.isInsert) {
	        	NewHireTriggerClass.createNewHireCases(trigger.newMap);
	        	TerminationRequest.internalBusinessServices(trigger.newMap);
	        	/*Set<Id> caseSet = new Set<Id>();
	        	for(Case cas : Trigger.new){ 
	        		if(cas.ConnectionReceivedId != NULL){
	        			caseSet.add(cas.Id);
	        		}
	        	}
	        	TelusExternalSharingHelperCls.mapContactOnTelusSharedCases(caseSet);*/
	        	TelusExternalSharingHelperCls.updateBackToPartner(Trigger.new); 
	        	TelusExternalSharingHelperCls.shareCasesWithTelus(Trigger.new);   
	    	} else if(Trigger.isUpdate) {
	    		/*Set<Id> caseSet = new Set<Id>();
	        	for(Case cas : Trigger.new){ 
	        		if(cas.ConnectionReceivedId != NULL){
	        			caseSet.add(cas.Id);
	        		}
	        	}
	        	TelusExternalSharingHelperCls.mapContactOnTelusSharedCases(caseSet);*/
	        	NewHireTriggerclass.newHireupdate(trigger.newMap,trigger.oldMap);
	        	TelusExternalSharingHelperCls.shareCasesWithTelus(trigger.new);
	    	}
	    	/*************************** Telus S2S Code included here ENDS *************************/  
	   	} catch(Exception e) {
	   		System.debug(LoggingLevel.Error, '###### Exception occured while updating Telus Case Fields  -' + e.getMessage()); 
	   		//trigger.new[0].addError(e);
	   	}  
	   	
	   	/*******************************************************************
		 * @Description.: updating the Account's lastTouchbySalesAgent     *
		 * @updatedBy...: India team                                       *
		 * @updateDate..: 19/03/2014                                       *
		 * @Case Number.: 02432238                                         *
		 *******************************************************************/
		/*********************************************Code for Case Number:02432238 Start from here *****************************************/
		try{
			if(UserInfo.getProfileId() != NULL){
				User userObj =  [SELECT Id, FirstName, Lastname, Name, Email, Phone, ProfileId FROM User WHERE Id =: UserInfo.getUserId()];
				Profile objpro = new Profile();
		    	List<Profile> profList = new List<Profile>([select Name from Profile where Id = :UserInfo.getProfileId() limit 1 ]);
		    	if(profList.size()>0){
		    		objpro = profList[0];
		    	}
		    
				List<Account> accountList = new List<Account>();
				if(objpro.Name.toLowerCase().contains('sales') && !objpro.Name.toLowerCase().contains('engineer') ){
					for(Case caseObj: trigger.New) {
						if(caseObj.AccountId != null ) {
							accountList.add(new Account(Id=caseObj.AccountId));
						}
					}
					AccountTriggerHelperExt.updateLastTouchedSalesPerson(accountList, userObj);
				}
			}	
		}catch(Exception Ex){
			system.debug('#### Error on line - '+ex.getLineNumber());
			system.debug('#### Error message - '+ex.getMessage());
		}
		/******************************************Code for Case Number:02432238 End's here*************************************************/
		
		/*  Graduation Score Completion Rate calculation Over Case records insertion.*/
	   	try{
	   			GraduationScoreCardHelper.calculateGraduationCompletionRateOverCase(Trigger.new, trigger.oldMap);
	   		}catch(Exception ex){
	   			system.debug('#### Error on line - '+ex.getLineNumber());
				system.debug('#### Error message - '+ex.getMessage());
				}
	   		
	}
	
	/*  Graduation Score Completion Rate calculation Over Case records deletion.*/
	if(Trigger.isDelete){
		try{
			system.debug('Called case afetr--->'+Trigger.old);
	   			GraduationScoreCardHelper.calculateGraduationCompletionRateOverCase(Trigger.old, null);
	   			
	   		}catch(Exception ex){
	   			system.debug('#### Error on line - '+ex.getLineNumber());
				system.debug('#### Error message - '+ex.getMessage());
				}
	}
}