/*************************************************
Trigger on Account object
Before Update: Update Current Owner Name and Email fields as needed.
Before Insert & Update: Format RC Account Number by removing the the 1 from the front of US numbers.        

* UPDATE:
 * By:        eugenebasianomutya
 * Date:      5/21/2015
 * Details:   Case: Case 03562230: Target Accounts in SFDC 
 * Updates:   
              Create number field "Target Accounts Owned" in User object 
              Create checkbox field "Target Account" in Account object 
              Create validation rules to require Current Owner if Target Account is true

              If field changes to True, check if CurrentOwner's Target Accounts Owned has < 20 
              If YES, increment Target Accounts Owned, ELSE, show error that CurrentOwner already 
                has 20 Target Accounts 
                

   Case: 03775648 - Hortonworks
   Case Desc:  I need to figure out what sync or automation is changing Current Owners on the accounts that Sales Ops moduled to the Signature Team
   Update by: eugenebasianomutya
   Update date: 07312015
   Update made: Comment out code that change Account's Current Owner

/************************************************/

trigger Account_Before on Account (before insert, before update,before delete) {
  // Flag to check if trigger is to be executed or not.
  if (TriggerHandler.BY_PASS_ACCOUNT_ON_BEFORE) {
    System.debug('### RETURNED FROM ACCOUNT BEFORE TRG ###');
    return;
  } else {
    System.debug('### STILL CONTINUE FROM ACCOUNT BEFORE TRG ###');
    TriggerHandler.BY_PASS_ACCOUNT_ON_BEFORE = true;
  }
  private static final String CUSTOMER_ACCOUNT = 'Customer Account';
    //---------------------------As/Simplion/9/24/2014----------------------------------------
    //---------------------------map to maintain serviceName and serviceType Mappings--------- 
    Map<String,String> serviceAndTypeMap = new Map<String,String>{
        'FAX' => 'Fax',
        'PROFESSIONAL' => 'Professional',
        'OFFICE' => 'Office'
    };  
  //---------------------------------As/Simplion/10/16/2014 ends--------------------------------------------------------------------------    
  if(!Trigger.isDelete) {
    for(Account accObj : trigger.new) {
      System.debug(' ### ULTIMATE FORMULA FIELD = ' + accObj.Ultimate_Parent_Account_ID__c);
      if(accObj.Ultimate_Parent_Account_ID__c != NULL){
        accObj.Ultimate_Parent_Snapshot__c = String.valueOf(accObj.Ultimate_Parent_Account_ID__c).substring(0,15);
      }
    }
  }
  if(TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT || TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE){
    System.debug('### RETURNED FROM ACCOUNT INSERT TRG ###');
    return;
  } else {
    System.debug('### STILL CONTINUE FROM ACCOUNT INSERT TRG ###');
  }
  
  Schema.DescribeSObjectResult result = Account.SObjectType.getDescribe();
     Map<ID,Schema.RecordTypeInfo> rtMapByName = result.getRecordTypeInfosById();
  Map<Id,User> userMap = new Map<Id,User>();
  if(!Trigger.isDelete){
    Set<Id> userIds = AccountTriggerHelperExt.prepareUserIdSet(trigger.new);
    userMap = AccountTriggerHelperExt.getUsers(userIds);
  }
  
  if(Trigger.isInsert) { 
    AccountTriggerHelperExt.accountRecordTypeInformation(trigger.new, userMap);
    AccountTriggerHelperExt.accountSharingOnInsert(trigger.new);
    /*-----For Updation  of customer count on Partner Account ------------*/
         AccountTriggerHelperExt.updateCreditCounter(trigger.new,null);         
  }
  
  if(trigger.isUpdate ){
    AccountTriggerHelperExt.oldAccountMap = trigger.oldMap;
    //AccountTriggerHelperExt.updateAccountInformation(trigger.new, userMap);
    AccountTriggerHelperExt.accountSharingOnUpdate0(trigger.new, userMap);
    AccountTriggerHelperExt.accountSharingOnUpdate2(trigger.new);
    /*-----For Updation  of customer count on Partner Account ------------*/
        AccountTriggerHelperExt.updateCreditCounter(trigger.new,trigger.oldmap);
        AccountTriggerHelperExt.updateMostRecentImplementationContact(trigger.newMap);
  }
  
  if(trigger.isInsert || trigger.isUpdate){
  
    // Case 03775648 - Remove this code      
    // AccountTriggerHelperExt.updatePartnerCodeOnInsertAndUpdate(trigger.new);
    // Case 03775648 - Remove this code
    
        //---------------------------------As/Simplion/10/16/2014 start--------------------------------------------------------------------------
        //--------------------------------Service Type mapping as per service Name for account with Account status = 'test'---------------
        String serviceName = '';
        for(Account currentAccount: trigger.new){
        if(!String.isBlank(currentAccount.RC_Service_name__c) && !String.isBlank(currentAccount.RC_Account_Status__c))
            {
                serviceName = currentAccount.RC_Service_name__c.toUpperCase();
                if(currentAccount.RC_Account_Status__c.toUpperCase().equals('TEST')){
                    
                    currentAccount.Service_Type__c = serviceName.contains('OFFICE') ? serviceAndTypeMap.get('OFFICE') 
                                                        : (serviceName.contains('PROFESSIONAL') || serviceName.startsWith('PRO'))? serviceAndTypeMap.get('PROFESSIONAL') 
                                                        : serviceName.contains('FAX') ?  serviceAndTypeMap.get('FAX') 
                                                        : currentAccount.Service_Type__c;  
                }
            }
        }    
    //---------------------------------As/Simplion/10/16/2014 ends--------------------------------------------------------------------------    
    /**Start calculation of Completion Rate and Completion Date of Graduation Phase of Graduation Score Card */
    GraduationScoreCardHelper.calculateGraduationCompletionRate(trigger.new, trigger.oldMap); 
  }
  
  /********** For Account Hierarchy Total DLS Field updation *********
   * @Description : updating the Account's Hierarchy with total num- *
   *              : -ber of DLs.                     *
   * @updatedBy   : India team                                       *
   * @updateDate  : 23/07/2014                                       *
   *******************************************************************/
  if(Trigger.isDelete){
    Set<string> ultimateParentIdSet = new Set<string>();
        for(Account accObj : Trigger.old){
          // Only re-evaluate the hierarchy if either Ultimate Parent is being deleted or any 'Paid' Account is deleted.
          if(accObj.RC_Account_Status__c == 'Paid' || string.valueOf(accObj.Ultimate_Parent_Account_ID__c).subString(0,15) == string.valueOf(accObj.id).subString(0,15)){
            if(string.valueOf(accObj.Id).subString(0,15) != string.valueOf(accObj.Ultimate_Parent_Account_ID__c).subString(0,15)){
                  ultimateParentIdSet.add(string.valueOf(accObj.Ultimate_Parent_Account_ID__c).subString(0,15));
                  ultimateParentIdSet.add(string.valueOf(accObj.Id).subString(0,15));
              }else if(string.valueOf(accObj.Id).subString(0,15) == string.valueOf(accObj.Ultimate_Parent_Account_ID__c).subString(0,15)){    
                  ultimateParentIdSet.add(string.valueOf(accObj.Id).subString(0,15));
              }  
          } 
        }
        if(ultimateParentIdSet!=null && ultimateParentIdSet.size() > 0){
            //List<Account> accList = [Select id,Ultimate_Parent_Account_ID__c,Number_of_DL_s__c,Total_DLs__c from Account 
                                   // where Ultimate_Parent_Account_ID__c in : ultimateParentIdSet OR Id in : ultimateParentIdSet];
            List<Account> accMainList = new List<Account>();
            for(List<Account> accList : [SELECT id,Ultimate_Parent_Account_ID__c, Ultimate_Parent_Snapshot__c, Number_of_DL_s__c,Total_DLs__c FROM Account
                                    WHERE NAME != NULL AND RecordType.Name =: CUSTOMER_ACCOUNT AND (Ultimate_Parent_Snapshot__c IN : ultimateParentIdSet OR Id IN : ultimateParentIdSet)]){
              accMainList.addAll(accList);                          
            }                        
        
            if(accMainList!=null && accMainList.size() > 0){
                for(Account accObj : accMainList){
                    ultimateParentIdSet.add(string.valueOf(accObj.Id).subString(0,15));
                    ultimateParentIdSet.add(string.valueOf(accObj.Ultimate_Parent_Account_ID__c).subString(0,15));
                }
            }
        }    
        TriggerHandler.RELATED_ACCOUNT_ID_SET.addAll(ultimateParentIdSet) ;
    }   
  /************End of For Account Hierarchy Total DLS Field updation**************************************/
  
  /*******************************************************************
   * @Description.: updating the Account's lastTouchbySalesAgent     *
   * @updatedBy...: India team                                       *
   * @updateDate..: 19/03/2014                                       *
   * @Case Number.: 02432238                                         *
   *******************************************************************/
  /*********************************************Case:02432238 Start's here *****************************************/
  try{
    User userObj = (userMap != null ? userMap.get(UserInfo.getUserId()) : null);// [SELECT Id, FirstName, Lastname, Name, Email, Phone, ProfileId FROM User WHERE Id =: UserInfo.getUserId()];
    Profile objpro = [SELECT Name ,Id FROM Profile WHERE Id =:UserInfo.getProfileId()];
    if(objpro.Name.toLowerCase().contains('sales') && !objpro.Name.toLowerCase().contains('engineer') ){
      AccountTriggerHelperExt.userAssignmentOnAccount(trigger.new, userObj);
    }
  }catch(Exception Ex){
    system.debug('#### Error on line - '+ex.getLineNumber());
    system.debug('#### Error message - '+ex.getMessage());
  }
  /******************************************Case:02432238 End's here*************************************************/



  /*******************************************************************
   * @Description.: Target Accounts in SFDC                          *
   * @updatedBy...: eugenebasianomutya                               *
   * @updateDate..: 5/21/2015                                      *
   * @Case Number.: 03562230                                         *
   *******************************************************************/
  // NOTE: We can move this to AccountTriggerHelper class
  if(trigger.isInsert || trigger.isUpdate){

      map<Id, Id> mUserAcc = new map<Id, Id>();
      set<Id> sUserIdToCheck = new set<Id>();
      set<Id> sUserTargetAdd = new set<Id>();
      set<Id> sUserTargetReduce = new set<Id>();
      set<Id> sAccountError = new set<Id>();

      for(Account acc: trigger.new){
        

        if (trigger.isUpdate){
          
          // TA - 0>1, CO - 0>1; TA - 0>1, CO - 1>1;
          if(trigger.oldMap.get(acc.id).Target_Account__c == False && acc.Target_Account__c == true &&  
             acc.Current_Owner__c != null){
              sUserTargetAdd.add(acc.Current_Owner__c);
              sUserIdToCheck.add(acc.Current_Owner__c);
          }

          // TA - 1>1, CO - 0>1
          if(trigger.oldMap.get(acc.id).Target_Account__c == True && acc.Target_Account__c == true && 
             trigger.oldMap.get(acc.id).Current_Owner__c == null && acc.Current_Owner__c != null){
              sUserTargetAdd.add(acc.Current_Owner__c);
              sUserIdToCheck.add(acc.Current_Owner__c);
          }        

          // TA - 1>0, CO - 1>0
          if(trigger.oldMap.get(acc.id).Target_Account__c == True && acc.Target_Account__c == False &&  
             trigger.oldMap.get(acc.id).Current_Owner__c != null && acc.Current_Owner__c == null){
              sUserTargetReduce.add(trigger.oldMap.get(acc.id).Current_Owner__c);  
              sUserIdToCheck.add(trigger.oldMap.get(acc.id).Current_Owner__c);
          }        

          // TA - 1>0, CO - 1>1
          if(trigger.oldMap.get(acc.id).Target_Account__c == True && acc.Target_Account__c == False &&  
             trigger.oldMap.get(acc.id).Current_Owner__c != null && acc.Current_Owner__c != null){
              if(trigger.oldMap.get(acc.id).Current_Owner__c !=  acc.Current_Owner__c ){
                sUserTargetReduce.add(trigger.oldMap.get(acc.id).Current_Owner__c);
                sUserIdToCheck.add(trigger.oldMap.get(acc.id).Current_Owner__c);
              }else{
                sUserTargetReduce.add(acc.Current_Owner__c);
                sUserIdToCheck.add(acc.Current_Owner__c);
              }
          }      

          // TA - 1>1, CO 1>0
          if(trigger.oldMap.get(acc.id).Target_Account__c == True && acc.Target_Account__c == True &&  
             trigger.oldMap.get(acc.id).Current_Owner__c != null && acc.Current_Owner__c == null){
              sUserTargetReduce.add(trigger.oldMap.get(acc.id).Current_Owner__c);  
              sUserIdToCheck.add(trigger.oldMap.get(acc.id).Current_Owner__c);
              // Now set the checkbox to false
              acc.Target_Account__c = false;
          }

          // TA - 1>1, CO 1>1
          if(trigger.oldMap.get(acc.id).Target_Account__c == True && acc.Target_Account__c == True &&  
             trigger.oldMap.get(acc.id).Current_Owner__c != null && acc.Current_Owner__c != null){
              
              if(trigger.oldMap.get(acc.id).Current_Owner__c !=  acc.Current_Owner__c ){
                sUserTargetAdd.add(acc.Current_Owner__c);
                sUserIdToCheck.add(acc.Current_Owner__c);
                sUserTargetReduce.add(trigger.oldMap.get(acc.id).Current_Owner__c);  
                sUserIdToCheck.add(trigger.oldMap.get(acc.id).Current_Owner__c);
              }
          }

          mUserAcc.put(acc.Current_Owner__c, acc.Id);
          mUserAcc.put(trigger.oldMap.get(acc.id).Current_Owner__c, acc.Id);

        }else{
          // TA - 0>1, CO - 0>1; TA - 0>1, CO - 1>1;
          if(acc.Target_Account__c == true &&  acc.Current_Owner__c != null){
              sUserTargetAdd.add(acc.Current_Owner__c);
              sUserIdToCheck.add(acc.Current_Owner__c);
          }

          mUserAcc.put(acc.Current_Owner__c, acc.Id);
        }

      }

      if(sUserIdToCheck != null && sUserIdToCheck.size() >0){
        map<Id, User> mAccUser = new map<Id,User>([Select Id, Target_Accounts_Owned__c from User where id in:sUserIdToCheck]);
        list<User> lUserToUpdate = new list<User>();

        for(User usr: mAccUser.values()){
          User u = new User(Id = usr.Id);  
          if(sUserTargetAdd.contains(usr.Id)){
            if(usr.Target_Accounts_Owned__c == null){
                u.Target_Accounts_Owned__c  = 1;
                lUserToUpdate.add(u);
            }else{
                
                if(usr.Target_Accounts_Owned__c >= 20){                  
                  sAccountError.add(mUserAcc.get(u.Id));
                }else{
                  u.Target_Accounts_Owned__c  = usr.Target_Accounts_Owned__c + 1;
                  lUserToUpdate.add(u);
                }
            }
          }

          if(sUserTargetReduce.contains(usr.Id)){
            if(usr.Target_Accounts_Owned__c == null || usr.Target_Accounts_Owned__c == 0){
                u.Target_Accounts_Owned__c  = null;
                lUserToUpdate.add(u);
            }else{
                u.Target_Accounts_Owned__c  = usr.Target_Accounts_Owned__c - 1;
                lUserToUpdate.add(u);
            }
          }
        }

        if(lUserToUpdate!= null || lUserToUpdate.size() >0){
          Update lUserToUpdate;
        }        
      }
      
      // Check if needed to prompt user if Current Owner already has 20 Target Accounts
      if(sAccountError != null && sAccountError.size() >0){
        for(Account acc: trigger.new){
          if (sAccountError.contains(acc.Id)){
            acc.adderror('CurrentOwner already has 20 Target Accounts');
          }
        }
      }
  }
  /******************************************Case:03562230 End's here*************************************************/



  /*******************************************************************
   * @Description.: Signature Opt-Out for Partner Accounts                        *
   * @updatedBy...: eugenebasianomutya                               *
   * @updateDate..: 6/13/2015                                      *
   * @Case Number.: 03647888                                         *
   *******************************************************************/
  if(trigger.isInsert || trigger.isUpdate){

    If(trigger.isInsert){
      AccountTriggerHelperExt.Update_SignatureRepPartnershipOptOut(trigger.new, null, null, true);      
    } else{
      AccountTriggerHelperExt.Update_SignatureRepPartnershipOptOut(null, trigger.newMap, trigger.oldMap, false);
    }   
  }
  /******************************************Case:03647888 End's here*************************************************/

}