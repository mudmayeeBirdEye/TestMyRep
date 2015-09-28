/**************************************************************************************************
 * Project Name..........: RingCentral                                                            *
 * File..................: ChurnSurveyBatch                                                       *
 * Version...............: 1.0                                                                    *
 * Created by............: Simplion Technologies                                                  *
 * Created Date..........: 23-12-2014                                                             *
 * Last Modified by......: Simplion Technologies                                                  *
 * Last Modified Date....: 23-12-2014                                                             *
 * Description...........: This batch class will serve the need for creation of Churn Survey      *  
 *                                                                                                *
 **************************************************************************************************/
global class ChurnSurveyBatch implements Database.Batchable<sObject> {
	public string strQuery{get;set;} 
	
	global ChurnSurveyBatch() {
		DateTime currentDateTime = DateTime.now().adddays(-7);
		 
		this.strQuery = 'SELECT a.Service_Type__c,RC_Account_Status__c,RC_Brand__c, Total_DLs__c, a.RC_Churn_Date__c, a.Name, a.Id,'
						+'(SELECT Id, Email, HasOptedOutOfEmail, LastModifiedDate From Contacts Order by LastModifiedDate desc),'
						+'(SELECT Id, Name, SurveyType__c FROM Surveys__r where SurveyType__c = \'Churn Feedback Survey\'), ' 
						+'(SELECT AccountId, ContactId, IsPrimary From AccountContactRoles where IsPrimary = true) From Account a '
						+' where a.RC_Account_Status__c =\'disabled\' and RC_Churn_Date__c > '
						+ currentDateTime.format('yyyy-MM-dd\'T\'00:00:00Z')
						+ ' and RC_Churn_Date__c <='
						+ currentDateTime.format('yyyy-MM-dd\'T\'23:59:59Z'); //2014-09-22T21:56:42.000+0000 
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		system.debug('strQuery-->'+strQuery);
		return Database.getQueryLocator(strQuery);
	}
	
	global void execute(Database.BatchableContext BC, List<sObject> scope) {  
		try {
				List<Survey__c> churnSurveyList = new List<Survey__c>();
				Map<String,Contact> mapAccountToContact = new Map<String, Contact>();
				for(sObject result : scope) {
					List<Contact> contactList= new List<Contact>();
					List<AccountContactRole> accountContactRoleList= new List<AccountContactRole>();
					List<Survey__c> exisitngChurnSurveyList = new List<Survey__c>();
					Account churnAccount = (Account) result;    
					accountContactRoleList = churnAccount.AccountContactRoles;
					exisitngChurnSurveyList = churnAccount.Surveys__r;
					contactList = churnAccount.Contacts;
					Survey__c churnSurvey = new Survey__c();
					Contact contactObject = null;
					String contactId = null;
					if(accountContactRoleList.size()>0){
						for(AccountContactRole acRole:accountContactRoleList){
							if(acRole.IsPrimary){
								contactId = acRole.ContactId;
								break;
							}
						}
					}
					if(contactList.size()>0){
						for(Contact contact:contactList){
							if(contactId != null && contactId.equalsIgnoreCase(contact.id)){
								contactObject = contact;
								break;
							}
						}
						if(contactObject == null){
							contactObject = contactList[0];
						}
					}
					system.debug('Before survey creation- Barnd=>'+churnAccount.RC_Brand__c);
					if(contactObject != null && exisitngChurnSurveyList.size() == 0 && hasRelatedBrand(churnAccount.RC_Brand__c)){
						contactObject.HasOptedOutOfEmail = true;
						mapAccountToContact.put(churnAccount.Id, contactObject);
						churnSurvey.Name = churnAccount.Name+ ' - Churn Survey';
				        churnSurvey.Account__c = churnAccount.Id;
				        churnSurvey.SurveyType__c = 'Churn Feedback Survey';
				        churnSurvey.Snapshot_Number_of_DLs__c = churnAccount.Total_DLs__c;
				        churnSurvey.Snapshot_Service_Name__c = churnAccount.Service_Type__c;
				        churnSurvey.Contact_Email__c = contactObject.Email;
				        churnSurvey.Delivered_Date__c = system.now();
			        	churnSurveyList.add(churnSurvey);	
					}
				}
				if(churnSurveyList.size()>0){
			        Database.upsert(churnSurveyList);
			        sendSurveyMails(churnSurveyList, mapAccountToContact);
			      }
			} catch(Exception exp) {}
	}
	
	global void finish(Database.BatchableContext info) {}
	
	/* Method check the brand name.
	 *@return boolean, if brand name is empty or dosnt contains BT, AT&T and TELUS,
	 * then retrun true otherwise return false
	 */
	private boolean hasRelatedBrand(String brandName){
		system.debug('hasRelatedBrand called');
		if(String.isBlank(brandName)){
			return true;
		} else if(!brandName.containsIgnoreCase('BT') 
					&& !brandName.containsIgnoreCase('TELUS') 
					&& !brandName.containsIgnoreCase('AT&T')){
			system.debug('hasRelatedBrand called');
			return true;
		}
		return false;
	}
	
	/* Method send Churn feedback Survey to Contact.
	 * And update the respective Contact.
	 */
	public void sendSurveyMails(List<Survey__c> churnSurveyList, Map<String,Contact> mapAccountToContact){
		List<Exception_And_Notification_History__c> excepAndNotiList = new List<Exception_And_Notification_History__c>();
		List<EmailTemplate> emailTemplateList=[SELECT id,Subject  FROM EmailTemplate where Name=:'ChurnFeedbackSurvey'];
		try{
			for(Survey__c survey : churnSurveyList){
				Exception_And_Notification_History__c enhObject = new Exception_And_Notification_History__c(); 
				Schema.DescribeSObjectResult d = Schema.SObjectType.Exception_And_Notification_History__c;
                Map<String,Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName(); 
                /* Setting the Exception And Notification History object to compose the email. */
                enhObject.content_label_01__c = 'Churn Feedback Survey';
                enhObject.Email_Subject__c = emailTemplateList[0].Subject;
                enhObject.Record_Id__c = survey.Id;
                enhObject.RecordTypeId = rtMapByName.get('Email Notification').getRecordTypeId();
                enhObject.Reply_To__c = survey.Contact_Email__c;
				excepAndNotiList.add(enhObject);
			}
			if(excepAndNotiList.size()>0){
				insert excepAndNotiList;
			}
			if(!mapAccountToContact.isEmpty()){
				TriggerHandler.BY_PASS_CONTACT_ON_UPDATE = true;
				update mapAccountToContact.values();
			}
		}catch(Exception ex){
			system.debug('Exception on sendSurveyMails---->'+ex.getMessage());
		}
	}
}