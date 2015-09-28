/*************************************************
OpportunityMethods class
This Class is used by Account.trigger.
sendActivePipeLimitEmail sends an email notification to Opportunity owners who have crossed their activepipe limit

UPDATE:

By:       eugenebasianomutya
Date:     5/14/2015
Details:    Case # 03532574 - Update Account if Opp Stage name is set to Closed Won
        Create Edition, Sales Segment and Sales Edition picklist fields in Account and Opp
        When Opp Stage Name is update to Closed Won, push the values of the created fields to Account. 
Update Made:  1. Create fields in Account and Opp object
        2. Update the Apex code to utilize the existing Account update instead of creating a new set of Account update (Avoiding SOQL limit)
/************************************************/

public class OpportunityMethods {
  public static boolean OpportunityUpdate_FirstRun = true;
  public static Map<string,Decimal> leadBrandTierAmountMap = OpportunityMethods.getAmountByBrandAndTier();
  /*
  sendActivePipeLimitEmail accepts an Opportunity and two Integers
  activePipeCount is the number of ActivePipe Opps the Opportunity owner has.
  activePipeLimit is the limit of ActivePipe Opps the Opportunity owner is supposed to have. 
  */
  public void sendActivePipeLimitEmail(Opportunity o, Integer activePipeCount, Integer activePipeLimit){
    system.debug('THIS IS acivepipecount / limit: ' + activePipeCount + ', ' + activePipeLimit);
    // send out warning email 
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    // set recepient    
    mail.setTargetObjectId(UserInfo.getUserId());
    mail.setSaveAsActivity(false);
    String[] ccAddresses = new String[] {o.Owner_Manager_Email__c};
    //mail.setCcAddresses(ccAddresses);
    
    mail.setSubject('RingCentral SalesForce: You have crossed your ActivePipe Opportunity Limit');                        
              
    mail.setPlainTextBody('Your current total of ActivePipe Opportunties is ' + activePipeCount + '. Your ActivePipe limit is ' + activePipeLimit + ' Opportunities.\n\n\n' +
    'Please cleanup your ActivePipe Opportunities. \n\n\n' +
    'Thanks, \n' + 
    'Business Services Team' );           

   try{
    Messaging.sendEmail(new Messaging.Singleemailmessage[] {mail}); 
        }catch(Exception e){} 
  }
  
  
  // Case # 03532574 - Update Account if Opp is Closed Won - START
  // Comment this OLD code - START
  /*
  public void updateParentAccount(Map<Id,opportunity> newOppMap, Map<Id,opportunity> oldOppMap){
      Set<Id> setOppOwnerIds=new Set<Id>();
      Map<Id, User> userMap = new Map<Id, User>();
      List<Account>  accountList = new List<Account> ();
      for(Opportunity  opp:newOppMap.values()){
      if(oldOppmap==null || (newOppMap.get(opp.Id).OwnerId != oldOppMap.get(opp.Id).OwnerId)) {
          setOppOwnerIds.add(opp.OwnerId);  
          // System.debug('***setOppOwnerOnUpdation***'+setOppOwnerIds);
        }
    }
    userMap = getOwnerList(setOppOwnerIds);
    for(Opportunity opp : newOppMap.values()){
      if(oldOppmap==null || (newOppMap.get(opp.Id).OwnerId != oldOppMap.get(opp.Id).OwnerId)) {
        Account objAcc = New Account(Id=opp.Accountid);
        objAcc.Most_Recent_Opportunity_Owner__c = opp.OwnerId;
        objAcc.Most_Recent_Opportunity_Owner_Email__c = userMap.get(opp.OwnerId).Email;
        objAcc.Most_Recent_Opportunity_Owner_FirstName__c = userMap.get(opp.OwnerId).FirstName;
                objAcc.Most_Recent_Opportunity_Owner_LastName__c = userMap.get(opp.OwnerId).LastName;
                objAcc.Most_Recent_Opportunity_Owner_Phone__c = userMap.get(opp.OwnerId).Phone;
        accountList.add(objAcc);
          }
      }   
      System.debug('***accountList***'+accountList); 
        if(accountList !=null && accountList.size()>0) {
          try{
              TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
              update accountList;
              //TriggerHandler.RESET_VARIABLES();
              TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
          } catch(Exception e){}
      }
  }
  */
  // Comment this OLD code - END
  /***************Code for updating the Parent Account*********************/   
  public void updateParentAccount(Map<Id,opportunity> newOppMap, Map<Id,opportunity> oldOppMap){
    
    Set<Id> setOppOwnerIds=new Set<Id>();
      map<Id, User> userMap = new map<Id, User>();
        map <Id, Account> mapAccount = new map <Id, Account>();
        
        
        for(Opportunity  opp:newOppMap.values()){
          if(oldOppmap==null || (newOppMap.get(opp.Id).OwnerId != oldOppMap.get(opp.Id).OwnerId)) {
        setOppOwnerIds.add(opp.OwnerId);  
        // System.debug('***setOppOwnerOnUpdation***'+setOppOwnerIds);
        }
      }
      
    userMap = getOwnerList(setOppOwnerIds);
    
    for(Opportunity opp : newOppMap.values()){
      
      //Check if Opp is Closed Won      
      if(opp.StageName == '8. Closed Won' || opp.StageName == '7. Closed Won'){
        Account objAcc = New Account(Id=opp.Accountid);
        if(oldOppmap==null){           
          objAcc.Edition__c = newOppMap.get(opp.Id).Edition__c;
          objAcc.Sales_Segment__c = newOppMap.get(opp.Id).Sales_Segment__c;
          objAcc.Sales_Region__c = newOppMap.get(opp.Id).Sales_Region__c;
        }else{
          if (opp.StageName != oldOppMap.get(opp.id).StageName){
              objAcc.Edition__c = newOppMap.get(opp.Id).Edition__c;
              objAcc.Sales_Segment__c = newOppMap.get(opp.Id).Sales_Segment__c;
              objAcc.Sales_Region__c = newOppMap.get(opp.Id).Sales_Region__c;
          }
        }
        mapAccount.put(objAcc.Id, objAcc);
      }
      
      if(oldOppmap==null || (newOppMap.get(opp.Id).OwnerId != oldOppMap.get(opp.Id).OwnerId)) {
          
          Account objAcc = New Account();
          
          if(mapAccount.Containskey(opp.Accountid)){            
            objAcc = mapAccount.get(opp.Accountid);
          }else{
            objAcc = New Account(Id=opp.Accountid);
          }
          
          objAcc.Most_Recent_Opportunity_Owner__c = opp.OwnerId;
          objAcc.Most_Recent_Opportunity_Owner_Email__c = userMap.get(opp.OwnerId).Email;
          objAcc.Most_Recent_Opportunity_Owner_FirstName__c = userMap.get(opp.OwnerId).FirstName;
                objAcc.Most_Recent_Opportunity_Owner_LastName__c = userMap.get(opp.OwnerId).LastName;
                objAcc.Most_Recent_Opportunity_Owner_Phone__c = userMap.get(opp.OwnerId).Phone;
                
                mapAccount.put(objAcc.Id, objAcc);
        }
        
    }   
    System.debug('***accountList***'+mapAccount.values()); 
      if(mapAccount !=null && mapAccount.size()>0) {
        try{
          TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
          update mapAccount.values();
          //TriggerHandler.RESET_VARIABLES();
          TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
        } catch(Exception e){}
    }
  }
  // Case # 03532574 - Update Account if Opp is Closed Won - END
  
  
  
  public void updateAccountMostRecentContact(Map<Id,opportunity> newOppMap, Map<Id,opportunity> oldOppMap) {
    try {
      List<Account>  accountList = new List<Account>();
      map<id,id> mapOpportunityToContact = new map<id,id>();
          for(OpportunityContactRole objOppContactRole: [SELECT Id, IsPrimary, ContactId, OpportunityId FROM OpportunityContactRole where OpportunityId 
                                  IN: newOppMap.keyset() and IsPrimary = true order by lastmodifieddate asc]) {
          mapOpportunityToContact.put(objOppContactRole.OpportunityId,objOppContactRole.ContactId);                     
      }
      set<Id> accountIdSet = new set<Id>();
      for(Opportunity oppObj : newOppMap.values()) {
        accountIdSet.add(oppObj.AccountId);
      }
      map<Id,Account> mapAccountMap = new map<Id,Account>([select Most_Recent_Opportunity_Contact__c from Account where Id IN : accountIdSet]);
      
      for(Opportunity opp : newOppMap.values()){
        if(!String.isBlank(opp.AccountId)) {
          Account objAcc1 = New Account(Id = opp.AccountId);
          if(mapAccountMap != null && mapAccountMap.get(opp.AccountId) != null && mapOpportunityToContact != null 
            && mapOpportunityToContact.get(opp.id) != null && 
              mapAccountMap.get(opp.AccountId).Most_Recent_Opportunity_Contact__c !=  mapOpportunityToContact.get(opp.id)) {
            objAcc1.Most_Recent_Opportunity_Contact__c = mapOpportunityToContact.get(opp.id);
            accountList.add(objAcc1);
          }
        }
      } 
      System.debug('***accountList***'+accountList); 
        if(accountList != null && accountList.size()>0) {
          try{
            TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
            update accountList;
            TriggerHandler.RESET_VARIABLES();
          } catch(Exception e){}
      }
    } catch(Exception ex) {}
  } 
    
  private Map<Id, User> getOwnerList(Set<Id> setOppOwnerIds) {
      return new Map<Id, User>([SELECT Id, Name, Email, FirstName, LastName, Phone FROM User WHERE Id IN:setOppOwnerIds]);
    }
    
    public static Map<string,Decimal> getAmountByLeadSource() {
      map<string,Decimal> rtnLeadSourceAmountMap = new map<string,Decimal>(); 
      try {
      List<Document> docList = [Select body, bodyLength, ContentType, Url from Document where Name = 'OpportunityLeadSourceMapping'];
      if(docList != null && docList.size()>0) {
        if(docList[0].Body != null) {
          List<List<String>> parsedCSV =  parseCSV(docList[0].Body.toString(),true);
          if(parsedCSV != null) {
            for(List<String> listObj : parsedCSV) {
              if(!string.isBlank(listObj[0]) &&  !string.isBlank(listObj[3])) {
                system.Debug('>>listObj[3]>>>'+ listObj[3]);
                string formatAmount = listObj[3].replace('$','').replace('"','').replace(',','').trim();
                system.Debug('>>formatAmount>>>'+ formatAmount);
                rtnLeadSourceAmountMap.put(listObj[0],Decimal.valueOf(formatAmount)); 
              }
                    } 
          }
        }   
      }
      return rtnLeadSourceAmountMap;
      } catch(Exception ex) {
        system.Debug('>>ex>>>'+ ex.getMessage());
      }
      return null;
    }
    /********************************************************************************************************************************************
    * @Description : This method is used to parse the CSV file Product_Forecast_Amounts. The file contains the Price depeding on the RC Tier and*
    *                RC Brand.                                                          *
    * @Author    : Simplion Tecnologies. 25th April,2014.                                                                                     *             
    * @Params      : void                                                                               *
    * @Return      : pageReference                                                                                    * 
    ********************************************************************************************************************************************/
    public static Map<string,Decimal> getAmountByBrandAndTier() {
      map<string,Decimal> rtnLeadSourceAmountMap = new map<string,Decimal>(); 
      try {
      List<Document> docList = [Select body, bodyLength, ContentType, Url from Document where Name = 'Product_Forecast_Amounts'];
      if(docList != null && docList.size()>0) {
        if(docList[0].Body != null) {
          List<List<String>> parsedCSV =  parseCSV(docList[0].Body.toString(),true);
          if(parsedCSV != null) {
            for(List<String> listObj : parsedCSV) {
              if(!string.isBlank(listObj[0]) &&  !string.isBlank(listObj[1])) {
                system.Debug('>>listObj[1]>>>'+ listObj[1]);
                string formatAmount = listObj[1].replace('$','').replace('"','').replace(',','').trim();
                system.Debug('>>formatAmount>>>'+ formatAmount);
                rtnLeadSourceAmountMap.put(listObj[0],Decimal.valueOf(formatAmount)); 
              }
                    } 
          }
        }   
      }
      return rtnLeadSourceAmountMap;
      } catch(Exception ex) {
        system.Debug('>>ex>>>'+ ex.getMessage());
      }
      return null;
    }
    /********************************************************************************************************************************************
    * @Description : This method is used to parse the CSV file Product_Forecast_Amounts.                            *
    * @Author    : Simplion Tecnologies. 25th April,2014.                                                                                     *             
    * @Params      : String contents, Boolean skipHeaders                                               *
    * @Return      : List<List<String>>                                                                               * 
    ********************************************************************************************************************************************/
    private static List<List<String>> parseCSV(string contents, Boolean skipHeaders) {
      List<List<String>> allFields = new List<List<String>>();
        contents = contents.replaceAll(',"""',',"DBLQT').replaceall('""",','DBLQT",');
        contents = contents.replaceAll('""','DBLQT');
        List<String> lines = new List<String>();
        try {
            lines = contents.split('\n');
        } catch (System.ListException e) {
            System.debug('Limits exceeded?' + e.getMessage());
        }
        Integer num = 0;
        for(String line : lines) {
            if (line.replaceAll(',','').trim().length() == 0) break;
            List<String> fields = line.split(',');  
            List<String> cleanFields = new List<String>();
            String compositeField;
            Boolean makeCompositeField = false;
            for(String field : fields) {
                if (field.startsWith('"') && field.endsWith('"')) {
                    cleanFields.add(field.replaceAll('DBLQT','"'));
                } else if (field.startsWith('"')) {
                    makeCompositeField = true;
                    compositeField = field;
                } else if (field.endsWith('"')) {
                    compositeField += ',' + field;
                    cleanFields.add(compositeField.replaceAll('DBLQT','"'));
                    makeCompositeField = false;
                } else if (makeCompositeField) {
                    compositeField +=  ',' + field;
                } else {
                    cleanFields.add(field.replaceAll('DBLQT','"'));
                }
            }
            allFields.add(cleanFields);
        }
        if (skipHeaders) allFields.remove(0);
        return allFields; 
    }
    /********************************************************************************************************************************************
    * @Description : This method is being called from Opportunity trigger to calculate amount based on CSV(Either amount based on LeadSource OR)*
    *        : -Based on Forecasted Users,Tier and Brand)                                         *
    * @Author    : Simplion Tecnologies. 21th November,2014.                                                                                  *             
    * @Params      : List<Opportunity>                                                                      *
    * @Return      : Void                                                                                         * 
    ********************************************************************************************************************************************/
    public static void calculateAmountBasedOnCSV(List<Opportunity> oppList){
      Schema.DescribeSObjectResult recordtypemapresult = Opportunity.SObjectType.getDescribe();
        Map<ID,Schema.RecordTypeInfo> rtMapByName = recordtypemapresult.getRecordTypeInfosById();
        Map<string,Decimal> leadSourceAmountMapping = OpportunityMethods.getAmountByLeadSource();
        
      for(Opportunity NewOppObj : oppList){
        
            if(NewOppObj.RecordTypeId != null && (rtMapByName.get(NewOppObj.RecordTypeId).getName() == 'Sales Opportunity' 
                || rtMapByName.get(NewOppObj.RecordTypeId).getName() == 'VAR Opportunity'
                || rtMapByName.get(NewOppObj.RecordTypeId).getName() == 'Sales Opportunity zQuote')) {
                if(NewOppObj.Forecasted_Users__c == 0){
                    NewOppObj.Forecasted_Users__c = 1 ; // Asked from Tucker.
                }   
                if(NewOppObj.Brand_Name__c != NULL && NewOppObj.Tier_Name__c != NULL && NewOppObj.Forecasted_Users__c!= NULL){
                    opportunityMethods.amountBasedOnForecastedCSV(NewOppObj);
                } else if(NewOppObj.LeadSource != null && leadSourceAmountMapping != null && leadSourceAmountMapping.containskey(NewOppObj.LeadSource)) {
                    NewOppObj.X12_Month_Booking__c = leadSourceAmountMapping.get(NewOppObj.LeadSource);
                    if(NewOppObj.X12_Month_Booking__c != NULL){
                        if(NewOppObj.Probability != NULL){
                            NewOppObj.Amount = NewOppObj.X12_Month_Booking__c;
                        }
                        NewOppObj.Total_MRR__c = (NewOppObj.X12_Month_Booking__c)/12;
                    }   
                }   
            } else {
                NewOppObj.Amount = 0;
            }   
        
      }
    }
    /********************************************************************************************************************************************
    * @Description : Method to calculate amount based on CSV based on Forecasted Users,Tier and Brand                     *                                         *
    * @Author    : Simplion Tecnologies. 21th November,2014.                                                                                  *             
    * @Params      : Opportunity                                                                        *
    * @Return      : Void                                                                                         * 
    ********************************************************************************************************************************************/
    public static void amountBasedOnForecastedCSV(Opportunity NewOppObj){
      String brandTier = NewOppObj.Brand_Name__c+'-'+NewOppObj.Tier_Name__c;
        if(NewOppObj.Brand_Name__c != NULL && NewOppObj.Tier_Name__c != NULL && NewOppObj.Forecasted_Users__c!= NULL){
          if(leadBrandTierAmountMap != null && leadBrandTierAmountMap.containskey(brandTier) && leadBrandTierAmountMap.get(brandTier)!=NULL){
              NewOppObj.Total_MRR__c = NewOppObj.Forecasted_Users__c*leadBrandTierAmountMap.get(brandTier);
              if(NewOppObj.Total_MRR__c != NULL)
                  NewOppObj.X12_Month_Booking__c = 12*(NewOppObj.Total_MRR__c);
                  NewOppObj.Amount = NewOppObj.X12_Month_Booking__c;
          }
        }
    }
    /********************************************************************************************************************************************
    * @Description : Method to calculate amount WHEN NO LINE ITEMS ARE ATTACHED TO OPPORTUNITY based on CSV (Either amount based on LeadSource -*
    *        : - OR based on Forecasted Users,Tier and Brand)                                       *                                         *
    * @Author    : Simplion Tecnologies. 21th November,2014.                                                                                  *             
    * @Params      : List<Opportunity>                                                                      *
    * @Return      : Void                                                                                         * 
    ********************************************************************************************************************************************/
    public static void calculateAmountForZeroLineItems(List<Opportunity> OpptyList){
      List<Opportunity> oppWithZeroLineItemList = new List<Opportunity>();
      Map<Id,List<Line_Item__c>> opptyToLineItemMap = new Map<Id,List<Line_Item__c>>();
        //List<Opportunity> OpptyListTemp = [SELECT Id, (SELECT Id From Line_Items__r) From Opportunity WHERE Id IN : OpptyList];
        List<RC_Quote__c> rcQuoteList = new List<RC_Quote__c>();
        rcQuoteList = [SELECT id,Opportunity__c, (SELECT Id FROM Line_Items__r) FROM RC_Quote__c WHERE IsPrimary__c = true AND Opportunity__c IN : OpptyList];
        if(rcQuoteList.size() > 0 ){
          for(RC_Quote__c quot : rcQuoteList){
          List<Line_Item__c> lineItemTempList = quot.getSObjects('Line_Items__r');
                opptyToLineItemMap.put(quot.opportunity__c, lineItemTempList);
        }
        }
        
      for(Opportunity opp : OpptyList){
        if(opptyToLineItemMap != NULL && opptyToLineItemMap.containsKey(opp.Id) 
          && (opptyToLineItemMap.get(opp.Id)== NULL || (opptyToLineItemMap.get(opp.Id)!= NULL && opptyToLineItemMap.get(opp.Id).size()==0))){
          //OpportunityMethods.amountBasedOnForecastedCSV(opp);
          oppWithZeroLineItemList.add(opp);
        }else if(opptyToLineItemMap != NULL && opptyToLineItemMap.containsKey(opp.Id) == false){
          oppWithZeroLineItemList.add(opp);
        }
      }
      if(oppWithZeroLineItemList.size()>0){
        calculateAmountBasedOnCSV(oppWithZeroLineItemList);
      }
    }
}