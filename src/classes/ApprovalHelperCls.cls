/**************************************************************************************************
*	@Class			:	ApprovalHelperCls
*	@Author			:	Rajesh Kumar
*   @CreatedDate	:	4th May,2015
*   @Description	:	Class to handle functionalities done on after insert event
***************************************************************************************************/
 
public without sharing class ApprovalHelperCls {
	
	// Static Opportunity Map<Id,opoortunity> 
	public static map <Id,Opportunity> opportunityStaticMap = new Map<Id,Opportunity>();
	
	// variables for recordType Describing By NAME
	public static Schema.DescribeSObjectResult result ;
	public static Map<ID,Schema.RecordTypeInfo> rtMapByName; 
	// variables for recordType Describing By ID
	public static Schema.DescribeSObjectResult resultByID ;
	public static Map<String,Schema.RecordTypeInfo> rtMapByID; 
	// Account Map Static Map
	public static Map<Id,Account> accountStaticMap = new Map<Id,Account>(); 
	// Newmap of Trigger.new
	public static Map<Id,Approval__c> approvalNewStaticMap = new Map<Id,Approval__c>();
	// Old map of trigger
	public static Map<Id,Approval__c> oldApprovalStaticMap = new Map<id,Approval__c>();
	// approval to AccountSplit ID map
	public static Map<Id,Account_Split__c> approvalToAcSplitMap = new Map<Id,Account_Split__c>();
	
	// All below 4 list are populted in Before Approval trigger and will be inserted/updated in After trigger.
	public static List<Account_Split__c> accntSpltToInsertList = new List<Account_Split__c>();
	public static List<OpportunityTeamMember> optyTeamMembrToInsertList = new List<OpportunityTeamMember>();
	public static List<AccountTeamMember> accntTeamMembrToInsertList = new List<AccountTeamMember>();
	public static List<Opportunity> opptyToUpdateList = new List<Opportunity>();
	public static List<Account> customeraAcountTOUpdateList = new List<Account>();
	
	 
	/*************************************************************************************************	
	*	@Method			:	describeRecordTypesByName
	*   @CreatedDate	:	4th May,2015
	*   @Params			:	void
	***************************************************************************************************/
	public static void describeRecordTypesByName(){
		try{
			result = Approval__c.SObjectType.getDescribe();
    		rtMapByName = result.getRecordTypeInfosById();
		}catch(Exception e){
			System.debug('########## Exception occurred in Method describeRecordTypesByName : '+ e.getMessage());
		}
	}
	
	/*************************************************************************************************	
	*	@Method			:	describeRecordTypesById
	*   @CreatedDate	:	4th May,2015
	*   @Params			:	void
	***************************************************************************************************/
	public static void describeRecordTypesById(){
		try{
			resultByID = Approval__c.SObjectType.getDescribe();
    		rtMapByID= resultByID.getRecordTypeInfosByName();
		}catch(Exception e){
			System.debug('########## Exception occurred in Method describeRecordTypesById : '+ e.getMessage());
		}
	}
	
	
	/*************************************************************************************************	
	*	@Method			:	createAccountSplitsDirectToVar
	*   @CreatedDate	:	4th May,2015
	*   @Params			:	Trigger.new (Approval__c)
	*   @returnType		:   void
	*   @author			:   Rajesh Kumar
	***************************************************************************************************/
	public static void createAccntSplitDirToVar(){
		try{
			
			Map<Id,Id> approvalToPartnerOwnerMap = new Map<Id,Id>();
		
			for(Approval__c appObj : approvalNewStaticMap.values()){
				System.debug('###### appObj.create '+appObj.CreatedById);
				if(appObj.RecordTypeId != null && rtMapByName.get(appObj.recordtypeId).getName() == 'Channel Cross Sell'){
					String relatedUsrField = '';
					if(appObj.Type__c == 'Direct to VAR'){
						relatedUsrField = 'Partner_Owner__c';
					}else if(appObj.Type__c == 'VAR to Direct'){
						relatedUsrField = 'Direct_Sales_Rep__c';
					}
					if(relatedUsrField != '' && eligibleToCreateAccountSplits(appObj,relatedUsrField)){
						String oppotyMarket = '';
						// logic used for related opportunity
						if(appObj.Opportunity__c != NULL){
							if(opportunityStaticMap != NULL && opportunityStaticMap.containsKey(appObj.Opportunity__c) && opportunityStaticMap.get(appObj.Opportunity__c) != NULL){
								Opportunity oppty = opportunityStaticMap.get(appObj.Opportunity__c);
								// skip creating AccountSplit for this approval if employee Range AND Forecasted Users on opportunity are not populated.
								if(oppty.Effective_No_of_Employees_Range__c == NULL || oppty.Forecasted_Users__c == NULL)
									continue;
								// adding to approvalToPartnerOwnerMap Map.
								approvalToPartnerOwnerMap.put(appObj.id,appObj.Partner_Owner__c);
								oppotyMarket = findMarketTypeOfOppty(oppty.Effective_No_of_Employees_Range__c,Integer.valueOf(oppty.Forecasted_Users__c));
								// Updating the Opportunity Team
								OpportunityTeamMember optyTeamMembrObj = new OpportunityTeamMember();
								optyTeamMembrObj = (OpportunityTeamMember)updateRelatedTeams(oppotyMarket,oppty.Id,appObj.OwnerId,appObj.Type__c,appObj.Direct_Sales_Rep__c);
								if(optyTeamMembrObj != NULL){
									optyTeamMembrToInsertList.add(optyTeamMembrObj);	
								}
							}
						}
						// logic used related to Account
						if(appObj.Account__c != NULL){
							String rcAccountStatus = ''; 
							Account acc = new Account();
							if(accountStaticMap != NULL && accountStaticMap.containsKey(appObj.Account__c) && accountStaticMap.get(appObj.Account__c) != NULL){
								acc = accountStaticMap.get(appObj.Account__c);
								if(acc.RC_Account_Status__c != NULL)
							    	rcAccountStatus = acc.RC_Account_Status__c;
							}	
							// Updating the Account Team
							AccountTeamMember accntTeamMembrObj = new AccountTeamMember();
							accntTeamMembrObj = (AccountTeamMember)updateRelatedTeams(oppotyMarket,appObj.Account__c,appObj.OwnerId,appObj.Type__c,appObj.Direct_Sales_Rep__c); 
							if(accntTeamMembrObj != NULL){
								accntTeamMembrToInsertList.add(accntTeamMembrObj);	
							}
							// Creating Account_Split__c Record based on Approval fields
							Account_Split__c acSplit =  returnNewAccountSplit(rcAccountStatus,appObj.Id,oppotyMarket,appObj.Type__c,appObj.Account__c,appObj.OwnerId,appObj.Direct_Sales_Rep__c);
							accntSpltToInsertList.add(acSplit);
							approvalToAcSplitMap.put(appObj.Id,acSplit);
							System.debug('#$#$##@#@#@#@# accntSpltToInsertList '+ accntSpltToInsertList);
							appObj.Status__c = 'Completed';  
		                    appObj.Completed_Date__c = System.today();                     
						}
					}
				}
			}// end of For loop
			if(approvalToPartnerOwnerMap.size() > 0 )
				updateRelatedParentObjects(approvalToPartnerOwnerMap);
		}catch(Exception e){
			System.debug('########## Exception occurred in Method createAccntSplitDirToVar : '+ e.getMessage() +'Line == '+ e.getLineNumber());
		}
			
	}
	
	/***************************************************************************************************	
	*	@Method			:	isChangedObjectsfield
	*   @CreatedDate	:	4th May,2015
	*   @Params			:	String 
	*   @Description 	:	Generic method to Assess if any field of given object is changed or not.
	*   @returnType		:   Boolean
	*   @createdBy		:   Rajesh 
	***************************************************************************************************/
	private static Boolean isChangedObjectsfield(Sobject obj, String fieldName, Map<id,Sobject> objectOldMap){
		//System.debug('=====  ===== '+obj.get(fieldName));
		if(objectOldMap != NULL && objectOldMap.containsKey(obj.Id) && objectOldMap.get(obj.Id) != NULL
					              && objectOldMap.get(obj.Id).get(fieldName) != obj.get(fieldName)){
			System.debug('############# 111111111 Truee');
			return true;					
		}
		System.debug('############# 111111111 flaseeee');
		return false;	
	}
	
	/***************************************************************************************************	
	*	@Method			:	updateRelatedParentObjects
	*   @CreatedDate	:	4th May,2015
	*   @Params			:	Map<Id,Id> (Key = approval Id, Value = Approval.PartnerOwner Id) 
	*   @Description 	:	updates Opportunity Owner
	*   @returnType		:   void
	***************************************************************************************************/
	private static void updateRelatedParentObjects(Map<Id,Id> approvalToPartnerOwnerMap){
		Schema.DescribeSObjectResult resultOpp = Opportunity.SObjectType.getDescribe();
        Map<String,Schema.RecordTypeInfo> rtMapByNameOpp = resultOpp.getRecordTypeInfosByName();
		Map<Id,User> userMap = new Map<Id,User>([SELECT Id,ContactId,Contact.Account.Current_Owner__c,Contact.Account.Inside_Sales_Rep__c,
														Contact.Account.Partner_ID__c,Contact.Account.Ultimate_Partner_ID__c,
														Contact.Account.Ultimate_Parent_Partner_ID__c, Contact.Account.Ultimate_Partner_Name__c 
														FROM User WHERE Id IN : approvalToPartnerOwnerMap.values()]);
		for(Approval__c apprObj : approvalNewStaticMap.values()){
			system.debug('======= 11111' );
			if(opportunityStaticMap != NULL && opportunityStaticMap.containsKey(apprObj.Opportunity__c) && opportunityStaticMap.get(apprObj.Opportunity__c) != NULL){
				Opportunity oppty = opportunityStaticMap.get(apprObj.Opportunity__c);
				Account opptysAccount = new Account();
				if(accountStaticMap != NULL && accountStaticMap.containsKey(oppty.AccountId) && accountStaticMap.get(oppty.AccountId) != NULL){
					opptysAccount = accountStaticMap.get(oppty.AccountId);
				}
				 
				oppty.RecordTypeId = rtMapByNameOpp.get('VAR Opportunity').getRecordTypeId();
				if(userMap != NULL && userMap.containsKey(approvalToPartnerOwnerMap.get(apprObj.Id)) && userMap.get(approvalToPartnerOwnerMap.get(apprObj.Id)) != NULL){
					system.debug('************ == '+apprObj.Id);
					User tempUser = userMap.get(approvalToPartnerOwnerMap.get(apprObj.Id));
					system.debug('************ == 111 '+apprObj.Id);
					if(tempUser.ContactId != NULL && tempUser.Contact.Account != NULL){
						system.debug('************ == apprObj.Partner_Owner__c ==  '+apprObj.Partner_Owner__c);
						
						Account partnerAccount = tempUser.Contact.Account;
						// update Opportunity's fields.
						
						oppty.Partner_Owner__c = (apprObj.Partner_Owner__c != NULL ? apprObj.Partner_Owner__c : oppty.Partner_Owner__c);
						oppty.Partner_ID__c = (partnerAccount.Partner_ID__c != NULL && partnerAccount.Partner_ID__c != '' ? partnerAccount.Partner_ID__c : oppty.Partner_ID__c);
						if(apprObj.Type__c == 'Direct to VAR'){
							oppty.OwnerId = (partnerAccount.Current_Owner__c != NULL ? partnerAccount.Current_Owner__c : oppty.OwnerId);
							oppty.Partner_Lead_Source__c = 'RingCentral';
							oppty.Inside_Sales_Rep__c = (partnerAccount.Inside_Sales_Rep__c != NULL ? partnerAccount.Inside_Sales_Rep__c :oppty.Inside_Sales_Rep__c);
						}
						if(partnerAccount.Ultimate_Parent_Partner_ID__c != NULL && partnerAccount.Ultimate_Parent_Partner_ID__c != ''){
							oppty.Ultimate_Parent_Account_Partner_ID__c = partnerAccount.Ultimate_Parent_Partner_ID__c;
						}
						// update Opportunity's Account (Customer Account) fields.
						opptysAccount.Inside_Sales_Rep__c = (partnerAccount.Inside_Sales_Rep__c != NULL ? partnerAccount.Inside_Sales_Rep__c : opptysAccount.Inside_Sales_Rep__c);
						opptysAccount.Current_Owner__c = (partnerAccount.Current_Owner__c != NULL ? partnerAccount.Current_Owner__c : opptysAccount.Current_Owner__c);
						opptysAccount.Partner_ID__c = (partnerAccount.Partner_ID__c != '' && partnerAccount.Partner_ID__c != NULL ? partnerAccount.Partner_ID__c : opptysAccount.Partner_ID__c);
						if(partnerAccount.Ultimate_Partner_ID__c != '' && partnerAccount.Ultimate_Partner_ID__c != NULL){
							opptysAccount.Ultimate_Partner_ID__c = partnerAccount.Ultimate_Partner_ID__c;
						}
						if(partnerAccount.Ultimate_Partner_Name__c != '' && partnerAccount.Ultimate_Partner_Name__c != NULL){
							opptysAccount.Ultimate_Partner_Name__c = partnerAccount.Ultimate_Partner_Name__c;
						}
						
						// Populating approvalToAcSplitMap
						System.debug('&&&&&&&&&&&&&&&&&&&& partnerAccount.Partner_ID__c ' + partnerAccount.Partner_ID__c);
						if(approvalToAcSplitMap != NULL && approvalToAcSplitMap.containsKey(apprObj.Id) && approvalToAcSplitMap.get(apprObj.Id)!= NULL){
							approvalToAcSplitMap.get(apprObj.Id).PartnerId__c = partnerAccount.Partner_ID__c ;
						}
					}
				}
				opptyToUpdateList.add(oppty);
				customeraAcountTOUpdateList.add(opptysAccount);
			}
		}
		System.debug('&&&&&&&&&&&& approvalToAcSplitMap ' + approvalToAcSplitMap);
	}
	
	/***************************************************************************************************	
	*	@Method			:	findMarketTypeOfOppty
	*   @CreatedDate	:	4th May,2015
	*   @Params			:	String, Integer 
	*   @Description 	:	Return if oppty is Upmarket or Downmarket
	*   @returnType		:   String
	***************************************************************************************************/
	private static String findMarketTypeOfOppty(String employeeRange,Integer forecastedUsers){
		if(employeeRange != NULL){
			if(employeeRange.contains('50-249') || employeeRange.contains('250-999') || employeeRange.contains('1000+') ){
				return 'Upmarket';
			}else if(employeeRange.contains('10-49') || employeeRange.contains('2-9') || employeeRange.contains('Just me') ){
				if(forecastedUsers < 50 ){
					return 'Downmarket';	
				}else{
					return 'Upmarket';
				}
			}else{
				return '';
			}
		}else{
				return '';
		}
	}
	/****************************************************************************************************	
	*	@Method			:	insertAccountSplits
	*   @CreatedDate	:	4th May,2015
	*   @Params			:	String, double 
	*   @Description 	:	updateRelatedAccountTeam
	*   @returnType		:   sObject
	***************************************************************************************************/
	private static Sobject updateRelatedTeams(String oppotyMarket,Id objId,Id appOwnerId,String approvalType,Id dsrId){
		String teamMemberRoleStrng = '';
		Id teamMemberUser = (approvalType == 'Direct to VAR' ? appOwnerId : (approvalType == 'VAR to Direct' ? dsrId : NULL));
		
		if(oppotyMarket == 'Downmarket'){
			if(approvalType == 'Direct to VAR'){
				teamMemberRoleStrng = 'Shared Downmarket Deal - Direct to VAR';
			}else if(approvalType == 'VAR to Direct'){
				teamMemberRoleStrng = 'Overlay Downmarket Deal - VAR to Direct';
			}
		}else if(oppotyMarket == 'Upmarket'){
			if(approvalType == 'Direct to VAR'){
				teamMemberRoleStrng = 'Shared Upmarket Deal - Direct to VAR';
			}else if(approvalType == 'VAR to Direct'){
				teamMemberRoleStrng = 'Overlay Upmarket Deal - VAR to Direct';
			}
		}
		if(String.valueOf(objId).startsWith('006')){
			OpportunityTeamMember otmObj = new OpportunityTeamMember(UserId = teamMemberUser,OpportunityId = objId,TeamMemberRole = teamMemberRoleStrng);
			return otmObj;
		}else if(String.valueOf(objId).startsWith('001')){
			AccountTeamMember atmObj = new AccountTeamMember(UserId = teamMemberUser,AccountId = objId,TeamMemberRole = teamMemberRoleStrng);
			return atmObj;
		}else{
			return null;
		}
	}
	
	
	/****************************************************************************************************	
	*	@Method			:	doDMLOpertnInAfterTgr
	*   @Params			:	void 
	*   @Description 	:	updateRelatedAccountTeam
	*   @returnType		:   void
	***************************************************************************************************/
	public static void doDMLOpertnInAfterTgr(){
		try{
			// insert list
			List<Sobject> sobjectToInsertList = new List<Sobject>();
			// update list
			List<Sobject> sobjectToUpdateList = new List<Sobject>();
		    // populating values in insert list
		    sobjectToInsertList.addAll((List<Sobject>)accntSpltToInsertList);
		    sobjectToInsertList.addAll((List<Sobject>)optyTeamMembrToInsertList);
		    sobjectToInsertList.addAll((List<Sobject>)accntTeamMembrToInsertList);
		    
		    // populating values in update list
		    //sobjectToUpdateList.addAll((List<Sobject>)customeraAcountTOUpdateList);
		   // sobjectToUpdateList.addAll((List<Sobject>)opptyToUpdateList);
		    TriggerHandler.BY_PASS_CONTACT_ON_UPDATE = true;
		    TriggerHandler.BY_PASS_CONTACT_ON_INSERT = true;
			if(sobjectToInsertList.size() > 0){
				system.debug('#$#$##$#$#$$ '+ sobjectToInsertList);
				insert sobjectToInsertList;
				//insert optyTeamMembrToInsertList;
				//insert accntTeamMembrToInsertList;
			}
			if(customeraAcountTOUpdateList.size() > 0){
				//TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE();
				//TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
				System.debug('##########'+opptyToUpdateList[0].ownerId);
				update customeraAcountTOUpdateList;
				TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
			}
			if(opptyToUpdateList.size() > 0){
				TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
				TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE();
				update opptyToUpdateList;
				// resetting all lists;
				accntSpltToInsertList = new List<Account_Split__c>();
				optyTeamMembrToInsertList = new List<OpportunityTeamMember>();
				accntTeamMembrToInsertList = new List<AccountTeamMember>();
				opptyToUpdateList = new List<Opportunity>();
				customeraAcountTOUpdateList = new List<Account>();
				sobjectToUpdateList = new List<Sobject>();
				sobjectToInsertList = new List<Sobject>();
				TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
				TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE = false;	
			}
		}catch(Exception e){
			System.debug('########## Exception occurred in Method doDMLOpertnInAfterTgr : '+ e.getMessage());
		}
	}
	/****************************************************************************************************	
	*	@Method			:	eligibleToCreateAccountSplitRecords
	*   @Params			:	 
	*   @Description 	:	
	*   @returnType		:   Boolean
	***************************************************************************************************/
	private static Boolean eligibleToCreateAccountSplits(Approval__c appObj,String relatedUsrField){
		if(String.valueOf(appObj.Status__c).containsIgnoreCase('approved')){
			if((isChangedObjectsfield(appObj,'Status__c',(Map<Id,Sobject>)oldApprovalStaticMap)  || 
           		isChangedObjectsfield(appObj,relatedUsrField,(Map<Id,Sobject>)oldApprovalStaticMap)) 
           		&&  (appObj.get(relatedUsrField) != NULL) 
	   		){
	   			System.debug('#################1111111111 true');
	   			return true;
	   		}else{
	   			System.debug('#################22222222222222 false');
	   			return false;
	   		}	
		}else{
			System.debug('#################333333 false');
			return false;
		}
	}
	/****************************************************************************************************	
	*	@Method			:	returnNewAccountSplit
	*   @Params			:	 
	*   @Description 	:	
	*   @returnType		:   Account_Split__c
	***************************************************************************************************/
	private static Account_Split__c returnNewAccountSplit(String rcAccountStatus,Id apprID,String oppotyMarket,String appObjType,Id appObjAccount,Id appObjOwnerId,Id dsrId){
		String marketSegment = '';
		String partnerID = '';
		Id salesAgent;
		Boolean beginDateUpdateOnStatusChange = (rcAccountStatus.equalsIgnoreCase('Paid') ? true : false);
		if(appObjType == 'Direct to VAR'){
			marketSegment = 'Direct-to-VAR - ' + oppotyMarket;
			salesAgent = appObjOwnerId;
		}else if(appObjType == 'VAR to Direct'){
			marketSegment = 'VAR-to-Direct - ' + oppotyMarket;
			salesAgent = dsrId;
		}
		
		Account_Split__c accSplitObj = new Account_Split__c(Account__c = appObjAccount,Sales_Agent__c = salesAgent,Role__c = 'DSR Shared Agent',
							PartnerId__c = partnerID,Agent_Credit_Split__c = 'Overlay',beginDateUpdateOnStatusChange__c = beginDateUpdateOnStatusChange,
							Agent_Credit_Sub_Type__c = 'Overlay Shared',Market_Segment__c = marketSegment,
							Commission__c = ((oppotyMarket == 'Upmarket' && appObjType == 'VAR to Direct') ? 100 : 80),Begin_Date__c = System.today());
		return accSplitObj;
	}
	/****************************************************************************************************	
	*	@Method			:	chnageOpportunityRecordType
	*   @Params			:	Approval__c Trigger.new List 
	*   @Description 	:	
	*   @returnType		:   void
	***************************************************************************************************/
	public static void chnageOpportunityRecordType(List<Approval__c> approvalNewList,String triggerEvent){
		Schema.DescribeSObjectResult resultOpp = Opportunity.SObjectType.getDescribe();
        Map<String,Schema.RecordTypeInfo> rtMapByNameOpp = resultOpp.getRecordTypeInfosByName();
        system.debug('&*&*&*&*&*&*&* ');
		for(Approval__c appObj : approvalNewList){
			system.debug('&*&*&*&*&*&*&* 1111 '+ approvalNewStaticMap.values());
			if(appObj.Type__c == 'Direct to VAR'){
				if(appObj.RecordTypeId != null && rtMapByName.get(appObj.recordtypeId).getName() == 'Channel Cross Sell'){
					if(appObj.Opportunity__c != NULL){
						if(opportunityStaticMap != NULL && opportunityStaticMap.containsKey(appObj.Opportunity__c) && opportunityStaticMap.get(appObj.Opportunity__c) != NULL){
							Opportunity oppty = opportunityStaticMap.get(appObj.Opportunity__c);
							if(triggerEvent == 'isUpdate'){
								if(isChangedObjectsfield(appObj,'Status__c',(Map<Id,Sobject>)oldApprovalStaticMap) 
										&& (appObj.Status__c == 'Returned' || appObj.Status__c == 'Rejected')){
									oppty.RecordTypeId = rtMapByNameOpp.get('Sales Opportunity').getRecordTypeId();
								}
							}else{
								oppty.RecordTypeId = rtMapByNameOpp.get('VAR Opportunity').getRecordTypeId();
							}
							opptyToUpdateList.add(oppty);
						}
					}
				}
			} 
		}
		if(opptyToUpdateList.size() > 0){
			system.debug('&*&*&*&*&*&*&* 2222222222');
			TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
			TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE();
			update opptyToUpdateList;
			TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
			TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE = false;
		}
	}
	/****************************************************************************************************	
	*	@Method			:	varToDirectAutoSubmitApproval
	*   @Params			:	Approval__c Trigger.new List 
	*   @Description 	:	
	*   @returnType		:   void
	***************************************************************************************************/
	public static void varToDirectAutoSubmitApproval(List<Approval__c> approvalNewList){
		Set<Id> apprvalIdSet = new Set<Id>();
		for(Approval__c appr:approvalNewList){
    		if('Channel Cross Sell'.equalsIgnoreCase(rtMapByName.get(appr.recordtypeId).getName()) && 'VAR to Direct'.equalsIgnoreCase(appr.Type__c) 
	        																		&& 'Auto'.equalsIgnoreCase(appr.Module__c)){
	        	//TriggerHandler.BY_PASS_Approver_Trigger = true; 	
	        	if(appr.Territory_DSR__c == false){																	
		        	Approval.ProcessSubmitRequest app = new Approval.ProcessSubmitRequest();
					app.setObjectId(appr.Id);
					app.setComments('VAR to Direct Approval Process.');
					Approval.ProcessResult apprvalProcessResult = Approval.process(app);
					System.debug('Successfully submitted for approval: '+apprvalProcessResult.isSuccess());
	        	}else{
					apprvalIdSet.add(appr.Id);
	        	}
	        }
    	}
    	approveVARToDirectAutoApprls(apprvalIdSet);
	}
	/****************************************************************************************************	
	*	@Method			:	approveVarToDirectAutoApprls [FUTURE METHOD]
	*   @Params			:	Set<Id> : ids of Approval 
	*   @Description 	:	Method is called when lead is converted and approval records eligible for -
	*					:	auto approval are passed to get approved automatically from this method 
	*   @returnType		:   void
	***************************************************************************************************/
	@future
	public static void approveVarToDirectAutoApprls(Set<Id> apprvalIdSet){ 
		List<Approval__c> appList = [SELECT Id,Type__c,Territory_DSR__c FROM Approval__c WHERE ID IN : apprvalIdSet];
		
		for(Approval__c app : appList){
			if(app.Territory_DSR__c == true){
				app.Status__c = 'Approved';
			}
		}
		if(appList.size() > 0)
			update appList;
	}

}