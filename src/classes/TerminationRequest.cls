/**********************************************************************************************************
date:          May 12, 2015
details:       Case 03572846 - Termination Request   
               Copy the Parents 'IT Helpdesk' values  to child 'Internal Business Services' when IT Helpdesk ticket is created.                 
***********************************************************************************************************/

public class TerminationRequest { 
    static User supportAgentUser = null;
    
    /* static { 
        supportAgentUser = [SELECT Id, Name FROM User WHERE Name = 'RC Support Agent' LIMIT 1];
    } */
    
    public static Case getAssignedChildCases(case objCaseChild, case objCaseTrigger, string strRecordType){
        system.debug('#### objCaseTrigger'+objCaseTrigger);
        objCaseChild.ParentId = objCaseTrigger.id;
        objCaseChild.Status = 'New';
        objCaseChild.Request_Type__c = '';
        objCaseChild.Type = 'Termination Request';
        objCaseChild.Parent = objCaseTrigger.Parent;
        objCaseChild.Origin = objCaseTrigger.Origin;
        objCaseChild.Employee_Department__c = objCaseTrigger.Employee_Department__c;
        objCaseChild.ownerId =objCaseTrigger.OwnerId;
        
        /*  if(supportAgentUser != null ) {
            objCaseChild.ownerId = supportAgentUser.Id;
        } */
        
        objCaseChild.RecordTypeId =OpportunityHelper.getOppRecordTypeMap(strRecordType);
        if(objCaseChild.contactId == null) {   
            try {
                getContact(objCaseChild, objCaseTrigger);
        
            } catch(exception e){}
        }
        objCaseChild.SuppliedEmail = objCaseTrigger.SuppliedEmail;
        objCaseChild.Case_Contact_Email__c = objCaseTrigger.FormSubmitterEmail__c;
        objCaseChild.New_Hire_Location__c = objCaseTrigger.New_Hire_Location__c;
        objCaseChild.Location__c = objCaseTrigger.Location__c;
        objCaseChild.Job_title__c = objCaseTrigger.Job_title__c;
        objCaseChild.Hire_Name__c = objCaseTrigger.Hire_Name__c;
        objCaseChild.New_Hire_Manager_Email__c = objCaseTrigger.New_Hire_Manager_Email__c;
        objCaseChild.Last_Date_of_Work__c = objCaseTrigger.Last_Date_of_Work__c;
        objCaseChild.Effective_Date_of_Separation__c = objCaseTrigger.Effective_Date_of_Separation__c;
        return objCaseChild;            
    } 

    private static void getContact(Case objCaseChild, Case parentCase) {
        Account accObj = [SELECT id, (SELECT Id, Phone, Name, Email FROM Contacts
                                         WHERE Email =:parentCase.FormSubmitterEmail__c ORDER BY LastModifiedDate DESC LIMIT 1) FROM Account WHERE Name =:'RC Internal' LIMIT 1];
        if(accObj != null) {
            List<Contact> contactList = accObj.Contacts;
            if(contactList != null && contactList.size() != 0) {
                objCaseChild.ContactId = contactList.get(0).Id;
            } else {
                if(!String.isBlank(parentCase.FormSubmitterEmail__c)) {
                    Contact conObj = new Contact();
                    conObj.AccountId = accObj.Id;
                    conObj.LastName = parentCase.SuppliedName;
                    conObj.Email = parentCase.FormSubmitterEmail__c;
                    conObj.Phone = parentCase.SuppliedPhone;
                    if(!String.isBlank(conObj.LastName)&&conObj.LastName!=null){
                        insert conObj;
                        objCaseChild.ContactId = conObj.id;
                    }
                }
            }
        }           
    }       

    public static void internalBusinessServices(Map<Id, Case> caseNewMap) {
        List<Case> caseList = caseNewMap.values();
        system.debug('@@@caseList@@@'+caseList);
        Schema.DescribeSObjectResult caseObjDetails = Case.SObjectType.getDescribe();
        Map<ID,Schema.RecordTypeInfo> rtMapByName = caseObjDetails.getRecordTypeInfosById(); 
        List<Case> lstCase = new List<Case>();
        List<string> stringList = new List<string>();
        for(Case cs : caseList) {
            if(rtMapByName.get(cs.RecordTypeId).getName()== 'IT Helpdesk') {
                Set<String> setString = new Set<String>(); 
                Set<string> setStrDP = new Set<String>();   
                try{                  
                    System.debug('#### case cs '+ cs);
                } catch(exception ex){ cs.addError(ex.getMessage());}                 
               if(cs.status == 'NEW' && cs.ParentId == null && cs.Request_Type__c == 'Termination Request') {
                   try{
                     //  Case objCase1 =new Case(Request_Type__c ='Helpdesk', Request_Subtype_1__c = 'Application', Request_Subtype_2__c='Account Creation');
                       Case objCase1 =new Case();
                       objCase1.Subject = cs.Subject;
                       objCase1.Description = cs.Description;
                       system.debug('#### objCase1---------->'+objCase1 );                                                                     
                       lstCase.add(getAssignedChildCases(objCase1, cs,'Internal Business Services'));
                   }catch(exception e){cs.addError(e.getMessage());}
               }
            }                
        }
        if(lstCase.size()>0){
            try{
                insert lstCase;
            }catch(Exception ex){
                caseList[0].addError('Problem in creating child Case.'+ex.getMessage());    
            }
        }                           
    } 
    
    
}