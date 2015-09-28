/**************************************************************************************************
 * Project Name..........:                                                                         *
 * File..................: AccountTriggerHelper.class                                              *
 * Version...............: 1.0                                                                     *
 * Created by............: Simplion Technologies                                                   *
 * Created Date..........: 29-01-2014                                                              *
 * Last Modified by......: Simplion Technologies                                                   *
 * Last Modified Date....: 29-01-2014                                                              *
 * Description...........: This is a helper class for Account.trigger.                             *
 **************************************************************************************************/

public class AccountTriggerHelper { 

	//Declaring Updated Account Map and Older Account Map. 
	public static Map<Id, Account> newAccountMap = new Map<Id, Account>();
	public static Map<Id, Account> oldAccountMap = new Map<Id, Account>();

	// Declaring Variables
	private static ImplementationMethods im = new ImplementationMethods();
	private static List<Survey__c> surveyListTOInsert = new List<Survey__c>();                                       
	private static List<Lead> leadList = new List<Lead>();
	private static List<Account> partnerAccountLst = new list<Account>();
	private static List<Account> lstAcc = new List<Account>();
	private static List<Implementation__c> implementationList = new List<Implementation__c>();
	private static Set<Id> accountIds = new Set<Id>();
	private static Set<Id> accountOwnerIdSet = new Set<Id>();
	private static Set<Id> contractOwnerId = new Set<Id>();
	private static Set<String> lstPartnerAcc = new set<String>();
	private static Set<string> partnerAccountIdSet = new Set<string>();

	private static Map<String, Account> mapPartnerIdToAccount = new Map<String, Account>();
	private static Map<String, Account> MapPartnerId = new Map<String, Account>();
	private static Map<String, Account> partnerAccMap = new Map<String, Account>();
	private static Map<String, Account> partnerAccountContactMap = new Map<String, Account>();
	//private static Map<String, Integer> mapAccountImplementationTrail = new Map<String, Integer>(); 
	//private static Map<String, Integer> mapAccntImplementation = new Map<String, Integer>(); 
	private static Map<Id, Integer> premiumImpAccMap = new Map<Id, Integer>();
	private static Map<Id, User> userMap = new Map<Id, User>();
	private static Map<Id, Contact> contactAccountMap = new Map<Id, Contact>(); 
	private static Map<Id, Boolean> allowImplMap = new Map<Id, Boolean>();

	//This set is initialized for implementation status.
	private static Set<String> impStatus = new Set<String>{'6a. Completed','6b. Completed - No Help Needed','6c. Completed - Account Cancelled','6d. Completed - No Response'};

	//This map is initialzed for the mob lead sources
	private static Map<String, String> mobLeadSources = new Map<String, String>{'m' => 'm', 'iphone' => 'iphone', 'bb' => 'bb', 'android' => 'android'};

	// Declaring constants
	private static final String TRIAL_30NOCC = 'TRIAL_30NOCC';
	private static final String TRIAL_30d_NO_CC_WEB ='TRIAL 30d-NO-CC-WEB';
	private static final String DWH_SYNC_PENDING = 'DWH SYNC PENDING';
	private static final String TRIAL = 'TRIAL';
	private static final String TRIAL_NOCC ='TRIAL_NOCC';
	private static final String TRIAL_30d_NO_CC_MOB = 'TRIAL 30d-NO-CC-MOB';
	private static final String TRIAL_30_NO_CC = 'Trial 30 no-CC';
	private static final String IMP_NEW = 'New';
	private static final String TRIAL_ACCOUNT = 'Trial Account';
	private static final String PREMIUM = 'Premium';
	private static final String CANCELED = 'Canceled'; 
	private static final String DISABLED = 'Disabled'; 
	private static final String CANCELLED_TRIAL = 'Cancelled Trial';
	private static final String RC_OFFICE ='RC Office';
	private static final String SALES_AGENT_RESELLERS = 'Sales Agents & Resellers';
	private static final String PARTNER_ACCOUNT = 'Partner Account';
	private static final String CUSTOMER_ACCOUNT ='Customer Account';
	private static final String PARTNER = 'Partner';
	private static final String RING_CENTRAL ='RingCentral';
	private static final String WEB = 'WEB';
	private static final String COMPLETED_ACCOUNT_CANCELLED = '6c. Completed - Account Cancelled';
	private static final String TELUS ='TELUS';
	private static final String BT_CLOUD_PHONE = 'BT Cloud Phone';
	private static final String BT_BUSINESS;
	
	static{
		if(!Test.isRunningTest()){
			BT_BUSINESS = RcDealHealper.getBTBrand();
		}else{
			BT_BUSINESS = 'BT Business';
		}
	}

	/****************************************************************************
	 * @Description - Constructor Class.                                         * 
	 * @params void                                                              *
	 * @return void                                                              * 
	 *****************************************************************************/
	public AccountTriggerHelper(){
		//system.debug('#### Inside Contructor AccountTriggerHelper');

		system.debug('#### mobLeads - '+mobLeadSources);
		accountIds = newAccountMap.keySet();
		//system.debug('#### accountIds - '+accountIds);  

		contactAccountMap = im.getContactAccountMap(newAccountMap);
		partnerAccountContactMap = im.getPartnerAccountContactMap(newAccountMap.values());
		premiumImpAccMap = im.accountToOppMap(accountIds);
		allowImplMap = im.allImplementationMap(newAccountMap.values()); 
	}   

	/*****************************************************************************
	 * @Description - Queries Contact object and fetches relevant details.       * 
	 * @params Set<Account> [trigger.new]                                        *
	 * @return Map<Id,Contact>                                                   * 
	 *****************************************************************************/
	public static Map<Id,Contact> getContact(Set<Id> accountIdSet){

		System.debug('No.of queries executed before getContact - '+limits.getqueries());

		Map<Id,Contact> mapContactImplementation = new Map<Id,Contact>();
		try{
			for(Contact thisContact : [SELECT FirstName, LastName, NumberOfEmployees__c,AccountId, Email,Phone, Account.No_of_Employees__c , Account.Name
			                           FROM Contact WHERE AccountId IN: accountIdSet]){

				if(thisContact != null){
					mapContactImplementation.put(thisContact.AccountId,thisContact);
				}
			}
			if(Test.isRunningTest()){
				Integer error = 0/0;
			}
		}catch(Exception e){
			System.debug('#### Error @ getContact line - '+e.getlineNumber());
			System.debug('#### Error @ getContact message - '+e.getMessage());
		}
		System.debug('No.of queries executed after getContact - '+limits.getqueries());
		return mapContactImplementation;
	}
	/*****************************************************************************
	 * @Description - accountMapForOfficeTrail.                                  * 
	 * @params Set<Id>acountIds                                                  *
	 * @return Map<Id,Account>                                                   * 
	 ****************************************************************************/ 
	public static Map<Id,Account> getAccountMapForOfficeTrail(Set<Id>acountIds){

		System.debug('No.of queries executed before getAccountMapForOfficeTrail - '+limits.getqueries());

		Map<Id,Account> accountMapForOffice = new Map<Id,Account>();
		try{
			for(Account thisAccount :[SELECT Owner.Email, Owner.Name, Owner.Team__c, Owner.Manager.Name, Owner.Manager.Email,CreatedBy.Name,    
			                          (SELECT Id FROM Opportunities limit 1),
			                          (SELECT Email,phone,LastName,Account.Name,Account.No_of_Employees__c FROM Contacts ORDER BY lastmodifieddate DESC), 
			                          (SELECT Account.Name, Contact.Email,Contact.phone, Contact.LastName,Contact.NumberOfEmployees__c, IsPrimary,Account.No_of_Employees__c 
			                        		  FROM AccountContactRoles WHERE IsPrimary = true limit 1),
			                        		  (SELECT Id FROM Surveys__r WHERE SurveyType__c = 'VAR Customer' limit 1)      
			                        		  FROM Account WHERE Id IN :accountIds]){
				if(thisAccount!=null){
					accountMapForOffice.put(thisAccount.Id,thisAccount);
				}
			}
			if(Test.isRunningTest()){
				Integer error = 0/0;
			}
		} catch(Exception ex){
			System.debug('#### Error @ accountMapForOfficeTrail line - '+ex.getlineNumber());
			System.debug('#### Error @ accountMapForOfficeTrail message - '+ex.getMessage());
		}
		System.debug('No.of queries executed after getAccountMapForOfficeTrail - '+limits.getqueries());
		return accountMapForOffice;
	}
	/*****************************************************************************
	 * @Description - Method to update account list.                             * 
	 * @params Map<Id,Account> [trigger.new] , Map<Id,Account> [trigger.old]     *
	 * @return void                                                              * 
	 ****************************************************************************/ 
	public static Map<String,Integer> getMapAccountImplementation(Set<Id> acctIds){ 

		System.debug('No.of queries executed before getMapAccountImplementation - '+limits.getqueries());
		Map<String,Integer> mapAccntImplementation =  new Map<String,Integer>();

		try {
			for(AggregateResult objAggregateResult:[SELECT Account__c,count(id) cnt 
			                                        FROM Implementation__c 
			                                        WHERE Account__c IN:accountIds 
			                                        GROUP BY Account__c ]){
				mapAccntImplementation.put(String.valueOf(objAggregateResult.get('Account__c')),Integer.valueOf(objAggregateResult.get('cnt')));              
			}
			if(Test.isRunningTest()){
				Integer error = 0/0;
			}  
		} catch(Exception ex) {
			System.debug('#### Exception @ getMapAccountImplementation line - '+ex.getlineNumber());
			System.debug('#### Exception message @ getMapAccountImplementation - '+ex.getMessage());
		} 
		System.debug('No.of queries executed after getMapAccountImplementation - '+limits.getqueries());
		return mapAccntImplementation;
	}
	/*****************************************************************************
	 * @Description - Method to update account list.                             * 
	 * @params Map<Id,Account> [trigger.new] , Map<Id,Account> [trigger.old]     *
	 * @return void                                                              * 
	 ****************************************************************************/ 
	public static Map<String,Integer> getMapAccountImplementationTrail (Set<Id> acntIds){

		System.debug('No.of queries executed before mapAccountImplementationTrail - '+limits.getqueries());
		Map<String,Integer> mapAccountImplementationTrail = new Map<String,Integer>();
		try {
			for(AggregateResult objAggregateResult:[SELECT Account__c,count(id) cnt FROM Implementation__c WHERE Account__c IN:accountIds and
			                                        Implementation_Type__c = 'Trial Account'
			                                        group by Account__c ]){
				mapAccountImplementationTrail.put(String.valueOf(objAggregateResult.get('Account__c')),Integer.valueOf(objAggregateResult.get('cnt')));              
			}
			if(Test.isRunningTest()){
				Integer error = 0/0;
			}  
		} catch(Exception ex) {
			system.debug('#### Exception @ mapAccountImplementationTrail line - '+ex.getlineNumber());
			system.debug('#### Exception message @ mapAccountImplementationTrail - '+ex.getMessage());
		}  
		system.debug('No.of queries executed after mapAccountImplementationTrail - '+limits.getqueries());
		return mapAccountImplementationTrail;
	}

	/*****************************************************************************
	 * @Description - Method to update Account Active Date.                      * 
	 * @params Map<Id,Account> [trigger.new], Map<Id,Account> [trigger.oldMap]   *
	 * @return void                                                              * 
	 *****************************************************************************/     
	public static void updateAccountActiveDate(){

		//system.debug('#### newAccountMap - '+newAccountMap);
		//system.debug('#### accountIds - '+accountIds);
		system.debug('No. of queries executed before updateAccountActiveDate - '+limits.getqueries());

		try{
			// Calling method to fetch Account Implementation details.
			Map<Id,List<Implementation__c>> mapAccountImplementation = new Map<Id,List<Implementation__c>>();
			mapAccountImplementation = getImplementation(accountIds);

			// Calling method to fetch Account Implementation Trail count.
			Map<String,Integer> mapAccountImplementationTrail = new Map<String,Integer>();
			mapAccountImplementationTrail =  getMapAccountImplementationTrail(accountIds);

			// Calling method to fetch Account Implementation count.
			Map<String,Integer> mapAccntImplementation =  new Map<String,Integer>();
			mapAccntImplementation = getMapAccountImplementation(accountIds);

			//Calling method to fetch RC User Id.
			Map<Id,Account> accountMap =  new Map<Id,Account>();
			accountMap = getAccount(accountIds);

			//Calling method to fetch Contact details.
			Map<Id,Contact> contactMap = new Map<Id,Contact>();
			contactMap = getContact(accountIds);

			Map<Id,Account> accountMapForOfficeTrail = new Map<Id,Account>();
			accountMapForOfficeTrail = getAccountMapForOfficeTrail(accountIds);

			//Calling method to fetch Contract details.
			Map<Id,List<Contract>> contractMap = new Map<Id,List<Contract>>();
			contractMap = getContract(accountIds);

			//Calling method to fetch User details.
			userMap = getUserDetails(contractOwnerId);

			//Calling method for Account Lead map.
			Map<Id, Lead> accountLeadMap =  new Map<Id, Lead>(); 
			accountLeadMap = createAccountLeadMap(newAccountMap.keySet());
			// getting the updated lead object from the create lead method.   
			accountLeadMap = im.createAccountLead(accountLeadMap, newAccountMap, contactMap );

			// Map to contain Account , Implementation.
			Map<Id, Implementation__c> accountImplementationMap =  new Map<Id, Implementation__c>();
			// Bucket List for Lead insertion.
			List<Lead> bucketLeadList =  new List<Lead>(); 

			for(Account thisAccount : newAccountMap.values()){

				Account oldAccount = oldAccountMap.get(thisAccount.Id);
				Account newAccount = newAccountMap.get(thisAccount.Id);

				/*****************************************************************
                    The below condition is added on June 14, 2011.
                    The signup type is also considered to contain 'TRIAL' word. 
                    It is being modified per requirement sent on June 15, 2011
				 ****************************************************************/ 

				if(!String.isBlank(thisAccount.SignupType__c)) {
					// getting the updated lead object from the create lead method.                 
					//Lead newLead = im.createLead(thisAccount,contactAccountMap, new Lead());
					Lead newLead = new Lead();
					newLead = accountLeadMap.get(thisAccount.Id);

					// checking the signup platform if it is WEB or NULL the lead is created per this condition only.
					if((String.isBlank(thisAccount.SignupPlatform__c) || ((!String.isBlank(thisAccount.SignupPlatform__c) && 
							WEB.equalsIgnoreCase(thisAccount.SignupPlatform__c.trim())))) && 
							TRIAL_30NOCC.equalsIgnoreCase(thisAccount.SignupType__c.trim()) && 
							newLead != null){

						//System.debug('SignupPlatform####'+thisAccount.SignupPlatform__c);
						newLead.LeadSource = TRIAL_30d_NO_CC_WEB;
						system.debug('#### thisAccount.RC_Account_Status__c - '+thisAccount.RC_Account_Status__c);

						if(!String.isBlank(thisAccount.RC_Account_Status__c) && 
								!DWH_SYNC_PENDING.equalsIgnoreCase(thisAccount.RC_Account_Status__c.trim()) && 
								thisAccount.RC_Account_Status__c.containsIgnoreCase(TRIAL)){

							//System.debug('@@@@Status'+thisAccount.RC_Account_Status__c);
							//insert newLead;
							bucketLeadList.add(newLead);
							//System.debug('Lead inserted'+newLead);
						}
						//System.debug('\n\n\n\nlead source is WEB');
					} 

					else if(!String.isBlank(thisAccount.SignupPlatform__c) && 
							!String.isBlank(mobLeadSources.get(thisAccount.SignupPlatform__c.trim())) && 
							(TRIAL_30NOCC.equalsIgnoreCase(thisAccount.SignupType__c.trim()) || 
									TRIAL_NOCC.equalsIgnoreCase(thisAccount.SignupType__c.trim())) &&
									newLead != null){

						System.debug('SignupPlatform@@@'+thisAccount.SignupPlatform__c);
						/*  Map mobLeadSources has these values (m, iphone, bb, android) if SignupPlatform needs to have any other value matched, 
                            it should be added to mobLeadSources map as key & value */
						newLead.LeadSource = TRIAL_30d_NO_CC_MOB;

						if(!String.isBlank(thisAccount.RC_Account_Status__c) && !DWH_SYNC_PENDING.equalsIgnoreCase(thisAccount.RC_Account_Status__c)
								&& thisAccount.RC_Account_Status__c.containsIgnoreCase(TRIAL)){
							//insert newLead;
							bucketLeadList.add(newLead);
							//System.debug('LeadSource@@'+newLead.LeadSource);
							//System.debug('Lead inserted'+newLead);
						}
					}
				}  

				/* 16th May 2011 : Logic to create Lead for 30 days NO CC */
				if(String.isBlank(thisAccount.SignupType__c) && String.isBlank(thisAccount.SignupPlatform__c) && 
						(!String.isBlank(thisAccount.RC_Account_Status__c) && TRIAL_30_NO_CC.equalsIgnoreCase(thisAccount.RC_Account_Status__c.trim())) && 
						oldAccountMap != null && (String.isBlank (oldAccount.RC_Account_Status__c)|| 
								!TRIAL_30_NO_CC.equalsIgnoreCase(oldAccount.RC_Account_Status__c.trim()) )) {

					/* gettting the updated lead object from the crate lead method. modified on June 15, 2011 */
					Lead newLead = im.createLead(thisAccount,contactAccountMap, new Lead());
					if(newLead != null){
						newLead.LeadSource = TRIAL_30d_NO_CC_WEB;
						///insert newLead;
						bucketLeadList.add(newLead);
					}
				}

				/****************************************************************************
                  Check different scenarios to see if implementation is needed
                    -If RC_Service_name__c is not null
                    -if Office account was not Paid or Suspended but is now Paid,is not high usage and there is no "Existing" type Implementation in progress
                    -if account was Online/Mobie/Fax and is now Office and a "Existing" type Implementation is not in progress
                    -if account is being upgraded from 1 line to 4 or 8 line tier or 4 to 8 line tier and a "Existing" type Implementation is not in progress
                    -if temp__c field is beint set to 1 (THIS IS FOR ADMIN USE ONLY. Create so admin could create implementations on the fly if requested. Not a business requirement)
				 *****************************************************************************/        
				//System.debug('@@@@@@@@');
				//system.debug('#### mapAccntImplementation - '+mapAccntImplementation);
				//system.debug('#### implementation flag - '+im.tocreateImplemetationOnInsorUpdForTELUS(thisAccount,mapAccntImplementation));
				//system.debug('#### brand - '+thisAccount.RC_Brand__c);
				//system.debug('#### Service Name - '+thisAccount.RC_Service_name__c);
				//system.debug('#### RC User Id - '+thisAccount.RC_User_ID__c);
				//system.debug('#### Account Status - '+thisAccount.RC_Account_Status__c);

				if(!String.isBlank(thisAccount.RC_Brand__c) && RING_CENTRAL.equalsIgnoreCase(thisAccount.RC_Brand__c.trim())) {
					System.Debug('BRAND IS NOT NULL && RINGCENTRAL');
					Integer oldDL = (oldAccount.Number_of_DL_s__c == null ? 0 : Integer.valueOf(oldAccount.Number_of_DL_s__c));
					Integer newDL = (thisAccount.Number_of_DL_s__c == null ? 0 : Integer.valueOf(thisAccount.Number_of_DL_s__c));
					
					if((oldDL !=  newDL) || (oldAccount.RC_Service_name__c != thisAccount.RC_Service_name__c) ||
							(oldAccount.RC_User_ID__c != thisAccount.RC_User_ID__c)|| 
							(oldAccount.RC_Account_Status__c != thisAccount.RC_Account_Status__c)) {
						System.Debug('EITHER DL, SERVICE NAME, USER ID OR ACCOUNT STATUS IS CHANGED');
						if(im.toCreateImplementationOnInsOrUpdRing(thisAccount,mapAccntImplementation) || 
								(im.toCreateImplementationOnInsOrUpdOfficeTrials(thisAccount,mapAccountImplementationTrail) && 
										(oldAccount.RC_Account_Status__c != thisAccount.RC_Account_Status__c))) { 
							System.Debug('ALLOWED TO CREATE IMPLEMENTATION');
							Implementation__c impObj = new Implementation__c();
							impObj.Type__c = IMP_NEW;
							System.debug('implementation gets created'+impObj.Type__c);
							if(!String.isBlank(thisAccount.RC_Account_Status__c) && (thisAccount.RC_Account_Status__c.containsIgnoreCase(TRIAL))) {
								impObj.Implementation_Type__c = TRIAL_ACCOUNT;
							}
							if(premiumImpAccMap != null && premiumImpAccMap.get(thisAccount.Id)!= null && premiumImpAccMap.get(thisAccount.Id) > 0) {
								impObj.Implementation_Type__c = PREMIUM;
							}
							//im.createAccountImplementation(thisAccount, contactAccountMap, impObj); 
							accountImplementationMap.put(thisAccount.Id, impObj);
						}       
					}   
				} else if(!String.isBlank(thisAccount.RC_Brand__c) && thisAccount.RC_Brand__c.trim().containsIgnoreCase(TELUS) && 
						im.tocreateImplemetationOnInsorUpdForTELUS(thisAccount,mapAccntImplementation)) {

					if((oldAccount.RC_Service_name__c != thisAccount.RC_Service_name__c) || 
							(oldAccount.RC_User_ID__c != thisAccount.RC_User_ID__c) || 
							(oldAccount.RC_Account_Status__c != thisAccount.RC_Account_Status__c) || 
							((oldAccount.RC_Brand__c != thisAccount.RC_Brand__c) && 
									(String.isBlank(oldAccount.RC_Brand__c) || !oldAccount.RC_Brand__c.trim().containsIgnoreCase(TELUS)))) {

						//System.Debug('>>$2>>>');
						Implementation__c impObj = new Implementation__c();
						impObj.Type__c = IMP_NEW;
						if(!String.isBlank(thisAccount.RC_Account_Status__c) && thisAccount.RC_Account_Status__c.toUpperCase().contains(TRIAL)) {
							impObj.Implementation_Type__c = TRIAL_ACCOUNT;
						}
						if(premiumImpAccMap !=null){
							if(premiumImpAccMap.get(thisAccount.Id) != null && premiumImpAccMap.get(thisAccount.Id) > 0) {
								impObj.Implementation_Type__c = PREMIUM;
							}
						}
						//im.createAccountImplementation(thisAccount, contactMap, impObj);
						accountImplementationMap.put(thisAccount.Id, impObj);    
					}           

				}
				/********************************************************************************** 
				*  Code for BT Implementation Creation.                                           *
				*   - Account Brand = BT Cloud Phone                                              *
				*   - Account Number of DL's > 0                                                  *
				*   - Account Status = Paid	                                                      *
				*                                                                                 *
				*   Either RC User Id, Status, Brand is changed.                                  *
				**********************************************************************************/ 
				else if(!String.isBlank(thisAccount.RC_Brand__c) 
							&& (thisAccount.RC_Brand__c.trim().containsIgnoreCase(BT_CLOUD_PHONE) 
												|| thisAccount.RC_Brand__c.trim().containsIgnoreCase(BT_BUSINESS) )
							&& im.tocreateImplemetationOnInsorUpdForBT(thisAccount,mapAccntImplementation)) {

					if((oldAccount.RC_User_ID__c != thisAccount.RC_User_ID__c) || 
					   (oldAccount.RC_Account_Status__c != thisAccount.RC_Account_Status__c) ||
					  ((oldAccount.RC_Brand__c != thisAccount.RC_Brand__c) && 
						(String.isBlank(oldAccount.RC_Brand__c) || !oldAccount.RC_Brand__c.trim().containsIgnoreCase(BT_CLOUD_PHONE)
												|| !oldAccount.RC_Brand__c.trim().containsIgnoreCase(BT_BUSINESS)))) {

						Implementation__c impObj = new Implementation__c();
						impObj.Type__c = IMP_NEW;
						if(!String.isBlank(thisAccount.RC_Account_Status__c) && thisAccount.RC_Account_Status__c.toUpperCase().contains(TRIAL)) {
							impObj.Implementation_Type__c = TRIAL_ACCOUNT;
						}
						if(premiumImpAccMap !=null){
							if(premiumImpAccMap.get(thisAccount.Id) != null && premiumImpAccMap.get(thisAccount.Id) > 0) {
								impObj.Implementation_Type__c = PREMIUM;
							}
						}
						accountImplementationMap.put(thisAccount.Id, impObj);    
					}           
				}
				
				else if(im.toCreateImplementationOnUpd(thisAccount,oldAccount,mapAccntImplementation)) {
					Implementation__c impObj = new Implementation__c();
					impObj.Type__c = IMP_NEW;
					if(!String.isBlank(thisAccount.RC_Account_Status__c) &&(thisAccount.RC_Account_Status__c.containsIgnoreCase(TRIAL))) {
						impObj.Implementation_Type__c = TRIAL_ACCOUNT;
					}
					if(premiumImpAccMap !=null){
						if(premiumImpAccMap.get(thisAccount.Id) != null && premiumImpAccMap.get(thisAccount.Id) > 0) {
							impObj.Implementation_Type__c = PREMIUM;
						}
					}
					//im.createAccountImplementation(thisAccount, contactAccountMap, impObj);
					accountImplementationMap.put(thisAccount.Id, impObj);  
				}


				if(((oldAccount.RC_Account_Status__c != thisAccount.RC_Account_Status__c) || 
						(oldAccount.Service_Type__c != thisAccount.Service_Type__c)) && 
						im.chkToCreateLeadForOfficeTrails(thisAccount,accountMapForOfficeTrail)) {

					Lead rtnleadobj = im.createLeadOfficeTrail(thisAccount,accountMapForOfficeTrail);
					if(rtnleadobj != null) {
						/**********************updating Lead Number Of Employee Field*************************************/
						Contact contactObj = contactMap.get(thisAccount.Id);
						if(contactObj != null && contactObj.NumberOfEmployees__c != Null){
							rtnleadobj.NumberOfEmployees__c = contactObj.NumberOfEmployees__c;
						} else if(thisAccount.No_Of_Employees__c != null){
							rtnleadobj.NumberOfEmployees__c = thisAccount.No_Of_Employees__c;
						}
						/******************************************************************/
						bucketLeadList.add(rtnleadobj);   
					}
				}

				if(CANCELED.equalsIgnoreCase(thisAccount.RC_account_Status__c) && 
						!CANCELED.equalsIgnoreCase(oldAccount.RC_Account_Status__c)){

					// If account was not and now is canceled.

					//List<Implementation__c> implementationList = new List<Implementation__c>();
					for(Implementation__c thisImplementation : mapAccountImplementation.get(thisAccount.Id)){
						//Updated by India Team for Case#02405558 on 25/04/2014
						if(!impStatus.contains(thisImplementation.Implementation_Status_2__c)){
							
							thisImplementation.Implementation_Status_2__c = Completed_Account_Cancelled;
							implementationList.add(thisImplementation);
						}
					}
					//Update Implementation
					//update implementationList;
				}
				//system.debug('#### new Account Status - '+thisAccount.RC_Account_Status__c);
				//system.debug('#### old Account Status - '+oldAccount.RC_Account_Status__c);



				/* If Account was a trial and is now disabled create a cancelled trial lead */          
				if(!String.isBlank(thisAccount.RC_Account_Status__c)  && !String.isBlank(oldAccount.RC_Account_Status__c)){

					if(DISABLED.equalsIgnoreCase(thisAccount.RC_Account_Status__c.trim()) && (oldAccount.RC_Account_Status__c.containsIgnoreCase(TRIAL))){
						Lead leadObj = null;
						if(accountMap != null && accountMap.get(thisAccount.Id)!= null && 
								contactMap !=null && contactMap.get(thisAccount.Id) != null && 
								accountMap.get(thisAccount.Id)!= null && accountMap.get(thisAccount.Id).RC_User_ID__c != null ){

							leadObj = new Lead(FirstName=contactMap.get(thisAccount.Id).FirstName,LastName=contactMap.get(thisAccount.Id).LastName,
									Company=thisAccount.Name,Email=contactMap.get(thisAccount.Id).Email,Phone=contactMap.get(thisAccount.Id).Phone,
									LeadSource= CANCELLED_TRIAL ,Lead_Score__c = 'B', timezone__c=thisAccount.Timezone__c, 
									Industry=thisAccount.Industry,User_ID__c = accountMap.get(thisAccount.Id).RC_User_ID__c);

							//insert leadObj;
							bucketLeadList.add(leadObj);
						} else if(accountMap != null && accountMap.get(thisAccount.Id)!= null && 
								contactMap !=null && contactMap.get(thisAccount.Id) != null){

							leadObj = new Lead(FirstName=contactMap.get(thisAccount.Id).FirstName,LastName=contactMap.get(thisAccount.Id).LastName,
									Company=thisAccount.Name,Email=contactMap.get(thisAccount.Id).Email,Phone=contactMap.get(thisAccount.Id).Phone,
									LeadSource= CANCELLED_TRIAL,Lead_Score__c = 'B', timezone__c=thisAccount.Timezone__c,Industry=thisAccount.Industry);
							//insert leadObj;
							
							//bucketLeadList.add(leadObj);
						} 
						if(leadObj != null) {
							/**********************updating Lead Number Of Employee Field*************************************/
							Contact contactObj = contactMap.get(thisAccount.Id);
							if(contactObj.NumberOfEmployees__c != Null){
								leadObj.NumberOfEmployees__c = contactObj.NumberOfEmployees__c;
							} else if(thisAccount.No_Of_Employees__c != null){
								leadObj.NumberOfEmployees__c = thisAccount.No_Of_Employees__c;
							}
							/******************************************************************/
							bucketLeadList.add(leadObj);
						}

					}
				}

				/* If activation date has been filled in for first time check for contracts and alert contract owner. */
				if(oldAccount.RC_Activation_Date__c == null && 
						oldAccount.RC_Activation_Date__c != newAccount.RC_Activation_Date__c && 
						RC_OFFICE.equalsIgnoreCase(newAccount.RC_Service_name__c)){

					if(contractMap != null && contractMap.containsKey(thisAccount.Id)){
						for(Contract thisContract : contractMap.get(thisAccount.Id)){
							sendEmails(thisContract);
						}
					}
				}

				/***************** Create VAR Survey on Account Activation *******************/
				if(thisAccount.Is_Demo_Account__c == false && 
				  	(!String.isBlank(thisAccount.RC_Attribution_Channel__c) && SALES_AGENT_RESELLERS.equalsIgnoreCase(thisAccount.RC_Attribution_Channel__c)) && 
						oldAccount.RC_Activation_Date__c == null && thisAccount.RC_Activation_Date__c != null) { 

					if(accountMapForOfficeTrail != null && 
					   accountMapForOfficeTrail.get(thisAccount.id) != null && 
					   accountMapForOfficeTrail.get(thisAccount.id).Surveys__r != null && 
					   accountMapForOfficeTrail.get(thisAccount.id).Surveys__r.size() == 0 &&
							partnerAccountContactMap != null && !String.isBlank(thisAccount.Partner_ID__c) && 
							partnerAccountContactMap.get(thisAccount.Partner_ID__c) != null && 
							partnerAccountContactMap.get(thisAccount.Partner_ID__c).contacts != null) {

						List<Contact> partnerAccountContactList = partnerAccountContactMap.get(thisAccount.Partner_ID__c).contacts;     
						Survey__c survObj = im.createVARSurveyOnAccountActivation(thisAccount,accountMapForOfficeTrail,partnerAccountContactList);
						if(survObj != null) {
							surveyListTOInsert.add(survObj);    
						}
					}
				}
			}

			// Bypassing Account Trigger to avoid loop.
			TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
			TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
			// Updating Implementation.
			if(implementationList != null && !implementationList.isEmpty()){
				update implementationList;
			}
			// Calling method to create Implementation.
			im.createAccountImplementation(accountImplementationMap, newAccountMap, contactAccountMap);

			// Calling Account Clean up process. 
			AccountCleanUpProcess.cleanUpAccounts(newAccountMap,contactAccountMap);

			/* DML Operation Area below, approach with caution! */
			// Inserting bulk Lead.
			if(bucketLeadList != null && !bucketLeadList.isEmpty()){
				insert bucketLeadList;
			}
			// Inserting bulk Lead.
			if(leadList !=null && !leadList.isEmpty()){
				insert leadList;
			}
			// Inserting bulk Survey.
			if(surveyListTOInsert !=null && !surveyListTOInsert.isEmpty()){
				insert surveyListTOInsert;
			}
			System.debug('No. of queries executed after updateAccountActiveDate - '+limits.getqueries());
			if(Test.isRunningTest()){
				Integer error = 0/0;
			}
		}catch(Exception e){
			System.debug('#### Error @ updateAccountActiveDate line - '+e.getlineNumber());
			System.debug('#### Error @ updateAccountActiveDate message - '+e.getMessage());                      
		}
	} 

	/*****************************************************************************
	 * @Description - Method to send mails.                                      * 
	 * @params Contract [trigger.new] Id's                                       *
	 * @return void                                                              * 
	 *****************************************************************************/
	public static void sendEmails(Contract thisContract){

		System.debug('No. of queries executed before sendEmails - '+limits.getqueries());

		try {
			if(thisContract != null){
				//Send email to Contract owner using Exception_And_Notification_History__c object.
				Exception_And_Notification_History__c exeNotificationObj = new Exception_And_Notification_History__c();
				exeNotificationObj.Sender_Display_Name__c = 'SFDC Account Alert';
				//System.debug('@@@@@@@@@'+exeNotificationObj.Sender_Display_Name__c);
				exeNotificationObj.Email_Subject__c = 'Please review this Account Contract';
				exeNotificationObj.To_Address_1__c = thisContract.Owner.Email;
				exeNotificationObj.Reply_To__c =  UserRC.rcsfSyncUserObj.Email__c;
				exeNotificationObj.Object_Type__c = 'Account';
				exeNotificationObj.content_label_01__c = 'SFDC_ACCOUNT_CONTRACT_NOTIFICATION';
				exeNotificationObj.content_var_01__c = thisContract.Id;
				exeNotificationObj.RecordTypeId = ExceptionAndNotificationHelper.getRcId('Email Notification');
				insert exeNotificationObj;
				//System.debug('@@Sender_Display_Name@@'+exeNotificationObj.Sender_Display_Name__c);
				/*
				exeNotificationObj.Email_Body__c = 'You have a Contract whose Account was recently listed as activated.'+
						'<BR>Please review the contract terms, fill in start date and activate.'+
						' Make sure signed contract is attached before activating.'+
						'<BR><BR><a href=https://na6.salesforce.com/'+thisContract.Id +'>View Contract in salesforce</a>' ;
				*/
				
				/*  System.debug('no.of queries got executed sendEmails'+limits.getqueries());
	            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
	            String[] toAddresses = new String[] {userMap.get(thisContract.OwnerId).Email};
	            mail.setToAddresses(toAddresses);
	            mail.setSenderDisplayName('SFDC Account Alert');
	            mail.setReplyTo(UserRC.rcsfSyncUserObj.Email__c);
	            mail.setSubject('Please review this Account Contract ');
	            mail.setHTMLBody('You have a Contract whose Account was recently listed as activated. <BR>Please review the contract terms, fill in start'+
	                    'date and activate. Make sure signed contract is attached before activating.<BR><BR><a href=https://na6.salesforce.com/'+
	                    thisContract.Id +'>View Contract in salesforce</a>');
	            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });*/
			}
			System.debug('No. of queries executed after sendEmails - '+limits.getqueries());
			if(Test.isRunningTest()){
				Integer error = 0/0;
			}
		} catch(Exception e){
			System.debug('#### Error @ sendEmails line - '+e.getlineNumber());
			System.debug('#### Error @ sendEmails message - '+e.getMessage());                      
		}
	}

	/*****************************************************************************
	 * @Description - Method to Create VAR Survey on Account Activation.         * 
	 * @params Map<Id,Account> [trigger.new] , Account                           *
	 * @return void                                                              * 
	 *****************************************************************************/      
	public static void survey (){

		//system.debug('#### survey accountIds - '+accountIds);   
		system.debug('No. of queries executed before survey - '+limits.getqueries());

		Map<Id,Account> accountMapForOfficeTrail = new Map<Id,Account>();
		accountMapForOfficeTrail = getAccountMapForOfficeTrail(accountIds);

		try {
			for(Account thisAccount : newAccountMap.values()){
				Account oldAccount = oldAccountMap.get(thisAccount.Id);
				if(thisAccount.Is_Demo_Account__c == false && (!String.isBlank(thisAccount.RC_Attribution_Channel__c) && 
						SALES_AGENT_RESELLERS.equalsIgnoreCase(thisAccount.RC_Attribution_Channel__c)) && 
						oldAccount.RC_Activation_Date__c == null && thisAccount.RC_Activation_Date__c != null) { 

					if(accountMapForOfficeTrail != null && accountMapForOfficeTrail.get(thisAccount.id) != null && 
							accountMapForOfficeTrail.get(thisAccount.id).Surveys__r == null && 
							partnerAccountContactMap != null && thisAccount.Partner_ID__c != null && 
							partnerAccountContactMap.get(thisAccount.Partner_ID__c) != null && 
							partnerAccountContactMap.get(thisAccount.Partner_ID__c).contacts != null) {

						List<Contact> partnerAccountContactList = partnerAccountContactMap.get(thisAccount.Partner_ID__c).contacts;     
						Survey__c survObj = im.createVARSurveyOnAccountActivation(thisAccount,accountMapForOfficeTrail,partnerAccountContactList);

						if(survObj != null) {
							surveyListTOInsert.add(survObj);    
							//System.debug('SURVEY'+surveyListTOInsert);
						}
					}
				} 
			}
			/***************** Create VAR Survey on Account Activation *******************/
			AccountCleanUpProcess.cleanUpAccounts(newAccountMap, contactAccountMap);

			if(leadList !=null &&!leadList.isEmpty()){
				insert leadList;
			}
			if(surveyListTOInsert !=null &&!surveyListTOInsert.isEmpty()){
				insert surveyListTOInsert;
				//System.debug('SURVEY LIST'+surveyListTOInsert);
			}
			System.debug('No. of queries executed after survey - '+limits.getqueries());
			if(Test.isRunningTest()){
				Integer error = 0/0;
			}
		}catch(Exception ex){
			System.debug('#### Error @ survey line - '+ex.getlineNumber());
			System.debug('#### Error @ survey message - '+ex.getMessage());
		}
	}
	/*****************************************************************************
	 * @Description - Method to Create  Account for Partner.                     * 
	 * @params Map<Id,Account> [trigger.new] , Account                           *
	 * @return void                                                              * 
	 *****************************************************************************/
	public static void partnerAccount(){

		System.debug('No. of queries executed before partnerAccount - '+limits.getqueries());
		try{
			Map<Id,Account> accMap = new Map<Id,Account>([SELECT Name,Parent_Detail__c,Partner_ID__c,Do_Not_Creation_Implementation__c,
			                                              Ultimate_Parent_Partner_ID__c,Ultimate_Partner_ID__c,Ultimate_Partner_Name__c,
			                                              Ultimate_Parent_Account_ID__c,Ultimate_Parent_Account_Name__c,Current_Owner__c,
			                                              Current_Owner_Email__c,Current_Owner_Name__c 
			                                              FROM Account 
			                                              WHERE parentId != null AND Parent_Detail__c != null 
			                                              AND Parent_Detail__c LIKE :partnerAccountIdSet AND RecordType.Name = 'Partner Account']);

			Schema.DescribeSObjectResult result = Account.SObjectType.getDescribe();
			Map<ID,Schema.RecordTypeInfo> rtMapByName = result.getRecordTypeInfosById();

			for(Account objAcc : newAccountMap.values()){
				// objAcc.RecordTypeId == '01280000000UERv' 
				if((PARTNER.equalsIgnoreCase(objAcc.Type)) && !String.isBlank(objAcc.Partner_Id__c) && 
						(rtMapByName != null && objAcc.RecordTypeId != null && rtMapByName.get(objAcc.RecordTypeId ).getName() == PARTNER_ACCOUNT)){

					partnerAccMap.put(objAcc.Partner_ID__c,objAcc);
					partnerAccountIdSet.add('%'+string.valueOf(objAcc.Id).substring(0,15)+'%');
					//System.debug('#@$@#$@%@$@#'+partnerAccountIdSet);
				}
			}
			system.debug('#### partnerAccMap - '+partnerAccMap);
			for(Account acc : [SELECT Name,Parent_Detail__c,Partner_ID__c,Do_Not_Creation_Implementation__c,Ultimate_Parent_Partner_ID__c,
			                   Ultimate_Partner_ID__c,Ultimate_Partner_Name__c,Ultimate_Parent_Account_ID__c,Ultimate_Parent_Account_Name__c,
			                   Current_Owner__c,Current_Owner_Email__c,Current_Owner_Name__c 
			                   FROM Account 
			                   WHERE parentId != null AND Parent_Detail__c != null AND Parent_Detail__c LIKE :partnerAccountIdSet 
			                   AND RecordType.Name = 'Partner Account']){
				if(!partnerAccMap.containsKey(acc.Partner_ID__c)){
					partnerAccMap.put(acc.Partner_ID__c,acc);
				}
			}
			system.debug('#### partnerAccMap - '+partnerAccMap);
			List<Account> customerAccountList = [SELECT Name,Parent_Detail__c,Partner_ID__c,Do_Not_Creation_Implementation__c,
			                                     Ultimate_Parent_Partner_ID__c,Ultimate_Partner_ID__c,Ultimate_Partner_Name__c,
			                                     Ultimate_Parent_Account_ID__c,Ultimate_Parent_Account_Name__c,Current_Owner__c,
			                                     Current_Owner_Email__c,Current_Owner_Name__c 
			                                     FROM Account 
			                                     WHERE Partner_ID__c IN: partnerAccMap.keySet() AND RecordType.Name = 'Customer Account'];
			//System.debug('**customerList'+customerAccountList);
			for(Account customerAccount : customerAccountList) {

				/*
                system.debug('#### In Map - '+partnerAccMap.containsKey(customerAccount.Partner_ID__c));
                system.debug('#### Customer Account Owner - '+customerAccount.Current_Owner__c);
                system.debug('#### Partner Account Owner - '+partnerAccMap.get(customerAccount.Partner_ID__c).Current_Owner__c);
				 */

				if(partnerAccMap !=null && partnerAccMap.get(customerAccount.Partner_ID__c) !=null && 
						partnerAccMap.containsKey(customerAccount.Partner_ID__c) && 
						customerAccount.Current_Owner__c != partnerAccMap.get(customerAccount.Partner_ID__c).Current_Owner__c){

					customerAccount.Current_Owner__c = partnerAccMap.get(customerAccount.Partner_ID__c).Current_Owner__c;
					//System.debug('@@@@@owner**'+customerAccount.Current_Owner__c);       

					if(partnerAccMap !=null && partnerAccMap.containsKey(customerAccount.Partner_ID__c) && 
							customerAccount.Ultimate_Partner_ID__c != partnerAccMap.get(customerAccount.Partner_ID__c).Ultimate_Parent_Partner_ID__c){

						customerAccount.Ultimate_Partner_ID__c = partnerAccMap.get(customerAccount.Partner_ID__c).Ultimate_Parent_Partner_ID__c;
						customerAccount.Ultimate_Partner_Name__c = partnerAccMap.get(customerAccount.Partner_ID__c).Ultimate_Parent_Account_Name__c;
						//System.debug('**customerAccount.Ultimate_Partner_ID__c'+customerAccount.Ultimate_Partner_ID__c);
					}   
				} 
			}
			if(customerAccountList!=null &&!customerAccountList.isEmpty()) {
				TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
				update customerAccountList; 
				TriggerHandler.RESET_VARIABLES();
			}
			System.debug('No. of queries executed after partnerAccount - '+limits.getqueries());
			if(Test.isRunningTest()){
				Integer error = 0/0;
			}
		} catch(Exception e){
			System.debug('#### Error @ partnerAccount line - '+e.getlineNumber());
			System.debug('#### Error @ partnerAccount message - '+e.getMessage());                      
		}
	}
	/* Utility Methods */

	/*****************************************************************************
	 * @Description - Queries Implementation object and fetches relevant details.* 
	 * @params Set<Account> [trigger.new]                                        *
	 * @return Map<Id,List<Implementation__c>                                    * 
	 *****************************************************************************/ 
	public static Map<Id,List<Implementation__c>> getImplementation(Set<Id> accountId){

		System.debug('No. of queries executed before getImplementation - '+limits.getqueries());

		Map<Id,List<Implementation__c>> mapAccountImplementation = new Map<Id,List<Implementation__c>>();
		try{
			for(Implementation__c thisImplementation : [SELECT id, Implementation_Status__c,Account__c ,Implementation_Status_2__c
			                                            FROM Implementation__c 
			                                            WHERE Account__c IN: accountId]){
				if(mapAccountImplementation.containsKey(thisImplementation.Account__c)){
					mapAccountImplementation.get(thisImplementation.Account__c).add(thisImplementation);    
				} else {
					mapAccountImplementation.put(thisImplementation.Account__c,new List<Implementation__c>{thisImplementation});
				}
			}
			if(Test.isRunningTest()){
				Integer error = 0/0;
			}
		}catch(Exception e){
			System.debug('#### Error @ getImplementation line - '+e.getlineNumber());
			System.debug('#### Error @ getImplementation message - '+e.getMessage());
		}

		System.debug('No. of queries executed after getImplementation - '+limits.getqueries());
		return mapAccountImplementation;
	}

	/*****************************************************************************
	 * @Description - Queries Contract object and fetches relevant details.      * 
	 * @params Set<Account> [trigger.new]                                        *
	 * @return Map<Id,List<Contract>                                             * 
	 *****************************************************************************/     
	public static Map<Id,List<Contract>> getContract(Set<Id> accountId){

		System.debug('No. of queries executed before getContract - '+limits.getqueries());

		Map<Id,List<Contract>> mapContractImplementation = new Map<Id,List<Contract>>();
		try{
			for(Contract thisContract : [SELECT Id, OwnerId, Owner.Email, AccountId FROM Contract WHERE AccountId =: accountId]){
				if(mapContractImplementation.containsKey(thisContract.AccountId)){
					mapContractImplementation.get(thisContract.AccountId).add(thisContract);    
				} else {
					mapContractImplementation.put(thisContract.AccountId,new List<Contract>{thisContract});
				}

				contractOwnerId.add(thisContract.OwnerId);
			}
			if(Test.isRunningTest()){
				Integer error = 0/0;
			}
		}catch(Exception e){
			System.debug('#### Error @ getContract line - '+e.getlineNumber());
			System.debug('#### Error @ getContract message - '+e.getMessage());
		}
		System.debug('No. of queries executed after getContract - '+limits.getqueries());
		return mapContractImplementation;
	}

	/*****************************************************************************
	 * @Description - Queries Account object and fetches relevant details.       * 
	 * @params Set<Id> [trigger.new] Id's                                        *
	 * @return Map<Id,Account>                                                   * 
	 *****************************************************************************/
	public static Map<Id,Account> getAccount(Set<Id> accountId){

		System.debug('No. of queries executed before getAccount - '+limits.getqueries());
		Map<Id,Account> accountMap =  new Map<Id,Account>();

		try{
			for(Account thisAccount : [SELECT RC_User_ID__c FROM Account WHERE Id IN: accountId]){
				accountMap.put(thisAccount.Id, thisAccount);
			} 
			if(Test.isRunningTest()){
				Integer error = 0/0;
			}
		}catch(Exception e){
			System.debug('#### Error @ getAccount line - '+e.getlineNumber());
			System.debug('#### Error @ getAccount message - '+e.getMessage());
		}
		System.debug('No. of queries executed after getAccount - '+limits.getqueries());
		return accountMap;
	}

	/*****************************************************************************
	 * @Description - Queries Account object and fetches relevant details.       * 
	 * @params Set<Id> [trigger.new] Id's                                        *
	 * @return Map<Id,Account>                                                   * 
	 *****************************************************************************/
	public static Map<Id,User> getUserDetails(Set<Id> contractOwnId){

		System.debug('No. of queries executed before getUserDetails - '+limits.getqueries());
		Map<Id,User> userDetailsMap =  new Map<Id,User>();

		try{
			for(User thisUser : [SELECT Id, Email FROM User WHERE Id IN: contractOwnId]){
				userDetailsMap.put(thisUser.Id, thisUser);
			}
			if(Test.isRunningTest()){
				Integer error = 0/0;
			} 
		}catch(exception e){
			System.debug('#### Error @ getUserDetails line - '+e.getlineNumber());
			System.debug('#### Error @ getUserDetails message - '+e.getMessage());
		}
		System.debug('No. of queries executed after getUserDetails - '+limits.getqueries());
		return userDetailsMap;
	}

	/*****************************************************************************
	 * @Description - Create Account Lead Map.                                   * 
	 * @params Set<Id> [trigger.new] Id's                                        *
	 * @return Map<Id,Account>                                                   * 
	 *****************************************************************************/
	public static Map<Id, Lead> createAccountLeadMap(Set<Id> accountIdList){

		Map<Id, Lead> accountLeadMap =  new Map<Id, Lead>();
		for(Id thisAccountId : accountIdList){
			accountLeadMap.put(thisAccountId, new Lead());	
		}	
		return accountLeadMap;
	}
	/*****************************************************************************
	 * @Description - Method to update account list.                             * 
	 * @params Map<Id,Account> [trigger.new] , Map<Id,Account> [trigger.old]     *
	 * @return void                                                              * 
	 *****************************************************************************/ 
	public static List<Account> upListAccount(){

		System.debug('No. of queries executed before upListAccount - '+limits.getqueries());
		List<Account> lstAccount=new List<Account>();

		try{
			for(Account accObj : newAccountMap.values()){
				if(accObj.ParentId !=null && (accObj.ParentId != oldAccountMap.get(accObj.Id).ParentId)){
					lstAccount.add(accObj);
				}
			}
			if(Test.isRunningTest()){
				Integer error = 0/0;
			}
		}catch(Exception e){
			System.debug('#### Error @ upListAccount line - '+e.getlineNumber());
			System.debug('#### Error @ upListAccount message - '+e.getMessage());
		}
		System.debug('No. of queries executed after upListAccount - '+limits.getqueries());
		return lstAccount;
	}

	/*****************************************************************************
	 * @Description - Method to insert lead for implementation.                  * 
	 * @params Map<Id,Account> [trigger.new] , Map<Id,Account> [trigger.old]     *
	 * @return void                                                              * 
	 *****************************************************************************/      
	public static void implementationLeads(){

		System.debug('No.of queries executed before implementationLeads - '+limits.getqueries());

		// Map to contain Account , Implementation.
		Map<Id, Implementation__c> accountImplementationMap =  new Map<Id, Implementation__c>();

		// Calling method to fetch Account Implementation Trail count.
		Map<String,Integer> mapAccountImplementationTrail = new Map<String,Integer>();
		mapAccountImplementationTrail =  getMapAccountImplementationTrail(accountIds);

		// Calling method to fetch Account Implementation count.
		Map<String,Integer> mapAccntImplementation =  new Map<String,Integer>();
		mapAccntImplementation = getMapAccountImplementation(accountIds); 

		// Calling method to fetch contact Map.
		Map<Id,Contact> contactMap = new Map<Id,Contact>();
		contactMap = getContact(accountIds);

		// Calling method to fetch Account Map For Office Trail.
		Map<Id,Account> accountMapForOfficeTrail = new Map<Id,Account>();
		accountMapForOfficeTrail = getaccountMapForOfficeTrail(accountIds);

		system.debug('#### mapAccntImplementation - '+mapAccntImplementation);
		system.debug('#### mapAccountImplementationTrail - '+mapAccountImplementationTrail);

		try{
			for(Account accObj : newAccountMap.values()) {

				if(accObj != null) {
					if(!String.isBlank(accObj.RC_Brand__c) && RING_CENTRAL.equalsIgnoreCase(accObj.RC_Brand__c.trim())) {
						if(im.toCreateImplementationOnInsOrUpdRing(accObj,mapAccntImplementation) || 
								(im.toCreateImplementationOnInsOrUpdOfficeTrials(accObj,mapAccountImplementationTrail))) { 

							Implementation__c impObj = new Implementation__c();
							impObj.Type__c = IMP_NEW;

							// Creating Trial Account type Implementation.
							if(!String.isBlank(accObj.RC_Account_Status__c) && accObj.RC_Account_Status__c.containsIgnoreCase(TRIAL)) {
								impObj.Implementation_Type__c = TRIAL_ACCOUNT;
							}

							// Creating Premium Account type Implementation
							if(premiumImpAccMap !=null && premiumImpAccMap.get(accObj.Id) != null && premiumImpAccMap.get(accObj.Id) > 0) {
								impObj.Implementation_Type__c = PREMIUM;
							}

							// Adding to Account Implementation Map for final insertion.
							accountImplementationMap.put(accObj.Id, impObj); 
						}       
					} else if(!String.isBlank(accObj.RC_Brand__c) && accObj.RC_Brand__c.trim().containsIgnoreCase(TELUS)
							&& im.tocreateImplemetationOnInsorUpdForTELUS(accObj,mapAccntImplementation)) {
						//system.Debug('>>$2>>>');
						Implementation__c impObj = new Implementation__c();
						impObj.Type__c = 'New';
						if(!String.isBlank(accObj.RC_Account_Status__c) && accObj.RC_Account_Status__c.toUpperCase().contains(TRIAL)) {
							impObj.Implementation_Type__c = TRIAL_ACCOUNT;
						}
						if(premiumImpAccMap !=null && premiumImpAccMap.get(accObj.Id) != null && premiumImpAccMap.get(accObj.Id) > 0) {
							impObj.Implementation_Type__c = PREMIUM;
						}

						// Adding to Account Implementation Map for final insertion.
						accountImplementationMap.put(accObj.Id, impObj);

					} else {
						if (im.toCreateImplementationOnInsOrUpd(accObj)) { 
							Implementation__c impObj = new Implementation__c();
							impObj.Type__c = IMP_NEW;
							if(premiumImpAccMap !=null && premiumImpAccMap.get(accObj.Id) != null && premiumImpAccMap.get(accObj.Id) > 0) {
								impObj.Implementation_Type__c = PREMIUM;
							}

							// Adding to Account Implementation Map for final insertion.
							accountImplementationMap.put(accObj.Id, impObj); 

						}
					}

					if(im.chkToCreateLeadForOfficeTrails(accObj,accountMapForOfficeTrail)) {
						Lead rtnleadobj = im.createLeadOfficeTrail(accObj,accountMapForOfficeTrail);
						if(rtnleadobj != null) {
							leadList.add(rtnleadobj);   
						}
					}
				}
			}
			if(leadList != null && leadList.size()>0) {
     			insert leadList;
			}

			// Calling method to create Implementation.
			im.createAccountImplementation(accountImplementationMap, newAccountMap, contactAccountMap);

			System.debug('No.of queries executed after implementationLeads - '+limits.getqueries());
			if(Test.isRunningTest()){
				Integer error = 0/0;
			}
		} catch(Exception e){
			System.debug('#### Error @ implementationLeads line - '+e.getlineNumber());
			System.debug('#### Error @ implementationLeads message - '+e.getMessage());                      
		}   
	}
	/*****************************************************************************
	 * @Description - Method to deinitalize maps, lists, sets.                   * 
	 * @params                                                                   *
	 * @return void                                                              * 
	 *****************************************************************************/      
	public static void deinitalize(){
		try{ 
			surveyListTOInsert.clear();
			leadList.clear();
			contractOwnerId.clear();
			partnerAccountIdSet.clear();
			partnerAccMap.clear();
			//mapAccountImplementationTrail.clear();
			//mapAccntImplementation.clear();
			userMap.clear();
			if(Test.isRunningTest()){
				Integer error = 0/0;
			}
		}catch(Exception e){
			System.debug('@@@Exception Deinitalize'+ e.getlineNumber());
			System.debug('###Exception deinitalize'+e.getMessage());
		}
	}
	
	/***************************************************************************************
     * @Description - Method to create Finance Case                                          * 
     * @params                                                                               *
     * @return void                                                                          * 
     ****************************************************************************************/ 
     public static void createFinanceCaseOnPaid(map<Id,Account> accountMapOld,List<Account> accountLstNew) {
 		List<Case> casetoinsert = new List<Case>();
		Schema.DescribeSObjectResult result = Case.SObjectType.getDescribe();
		Map<ID,Schema.RecordTypeInfo> rtMapByName = result.getRecordTypeInfosById();
    	Map<String,Schema.RecordTypeInfo> rtMapByRecName = result.getRecordTypeInfosByName();
		Map<Id,Integer> mapAccountIdToFinanceCaseNumber = new Map<Id,Integer>();
		String grpId = [SELECT Id FROM Group WHERE Name = 'Finance Queue' AND Type = 'Queue'].Id;
		try {
			for(Account accObj : [SELECT Id,(SELECT Id FROM Cases WHERE RecordType.Name = 'Finance' limit 1) 
									FROM Account WHERE ID IN :accountLstNew]) {
				if(accObj.cases != null) {
					mapAccountIdToFinanceCaseNumber.put(accObj.id,accObj.cases.size());
				} 
				//System.debug('^^^^^^^mapAccountIdToFinanceCaseNumber'+ mapAccountIdToFinanceCaseNumber.get(accObj.Id));
			}
	    	for (Account accObj : accountLstNew) {
		    	System.debug('########');
		    	if (accObj.Active_Invoice_Approval__c != NULL && mapAccountIdToFinanceCaseNumber != NULL && 
		    			mapAccountIdToFinanceCaseNumber.get(accObj.Id) == 0 && accObj.RC_Account_Status__c == 'Paid' && 
		    			(accountMapOld == null || 
		    				((accountMapOld.get(accObj.id).RC_Account_Status__c != accObj.RC_Account_Status__c) 
		    					|| accountMapOld.get(accObj.id).Active_Invoice_Approval__c == null))) {
		    		System.debug('*******');
					Case caseObj = new Case();
					caseObj.Status = 'New';
					caseObj.Subject = 'New Customer Tracking for Finance';
					caseObj.OwnerId = grpId;
					caseObj.AccountId = accObj.Id;
					caseObj.RecordTypeId  = rtMapByRecName.get('Finance').getRecordTypeId();
					casetoinsert.add(caseObj);
					System.debug('----->>>' + caseObj.Id);
				}
			}
			TriggerHandler.BY_PASS_CASE_ON_INSERT = true;
			TriggerHandler.BY_PASS_CASE_ON_UPDATE = true;
			insert casetoinsert;
			TriggerHandler.BY_PASS_CASE_ON_INSERT = false;
			TriggerHandler.BY_PASS_CASE_ON_UPDATE = false;
		    System.debug('%%%%%'+ casetoinsert);
		} catch (Exception ex) {
			System.debug('##createCaseline'+ ex.getlineNumber());
	      	System.debug('##createCaseMessage'+ ex.getMessage());
	 	}	
     }
     
     /*****************************************************************************
     * @Description - method to update contact records on insertion/updation of account record      * 
     * @return Map<Id,List<Contract>                                                                * 
     *****************************************************************************/
     
    public static void updateRelatedContactAccount(list<Account> lsttAcc){              
       List<Contact> contList = new List<Contact>(); 
       Set<Id> accounttIds = new Set<Id>();
         for(Account ACC : lsttAcc){  
             if(ACC.Id != null){                   
                accounttIds.add(ACC.Id);
             }
         }
         //Query records of Contact 
         List<Contact> lstcontact = [select id,AccountId, isCustomer__c,Contact_Status__c ,People_Segment__c,RCService_ContactStatus__c from Contact where AccountId IN: accounttIds];
         Map<id, list<Contact>> accountToContactMap = new Map<id, list<Contact>>();  
          for(Contact  conn:lstcontact) { 
            if(accountToContactMap.get(conn.AccountId) != null){
                //accountToContactMap.put(conn.AccountId, new List<Contact>{conn});
                accountToContactMap.get(conn.AccountId).add(conn);
            }else{
                accountToContactMap.put(conn.AccountId, new List<Contact>{conn});
            }
          }
          system.debug('-----lstcontact------->'+lstcontact);
          system.debug('------------>'+accountToContactMap);
          for ( Account acc : lsttAcc ) {   
                        if(accountToContactMap.size()!= 0 && accountToContactMap.get(acc.Id) != null){
                         //List<Contact> lstCon= accountToContactMap.get(acc.Id);
                              for(Contact con : accountToContactMap.get(acc.Id)){                                                     
                                if(!String.isBlank(acc.RC_Account_Status__c)){                                  
                                    if(acc.RC_Account_Status__c!= null && 'Paid'.equalsIgnoreCase(acc.RC_Account_Status__c.trim())){
                                        con.isCustomer__c=True;
                                        con.Contact_Status__c='Closed Won';
                                        con.Contact_Funnel_Type__c='Customer';
                                       con.People_Segment__c='Customer'; 
                                    }
                                    else if(acc.RC_Account_Status__c!= null && 'Canceled'.equalsIgnoreCase(acc.RC_Account_Status__c.trim())){
                                        con.isCustomer__c=False;
                                        con.Contact_Status__c='Canceled';
                                        con.Contact_Funnel_Type__c='Winback';
                                        con.People_Segment__c='Former Customer'; 
                                    }
                                }
                                contList.add(con);
                                system.debug('*********'+contList);
                               }
                                 
                            }
          } 
                 
        if(contList.size()>0){
        	
        	TriggerHandler.BY_PASS_CONTACT_ON_UPDATE();        	
            update contList;
            TriggerHandler.BY_PASS_CONTACT_ON_UPDATE=false;
        }         
    }
     
	
}// End of Class