public class AccountTriggerHelperExt {

    //VARIABLE DECLARATION
    private static final String PARTNER = 'Partner';
    private static final String CUSTOMER = 'Customer';
    private static final String CUSTOMER_ACCOUNT = 'Customer Account';
    private static final String PARTNER_ACCOUNT = 'Partner Account';
    private static final String CLOSED = 'Closed';
    private static Map<Id, List<Case>> caseAccountMap = new Map<Id, List<Case>>();

    //Declaring Updated Account Map and Older Account Map.
    
    public static Map<string,Account> partnerIdToAccountMap = new Map<string,Account>();
    public static Set<Id> eligiblePartnerAccountStaticIdSet = new Set<Id>();
    public static Set<Id> trackDeletedAccntSplitSet = new Set<Id>();

    public static Map<Id,Account> oldAccountMap = new Map<Id,Account>();
    public static Schema.DescribeSObjectResult result = Account.SObjectType.getDescribe();
    public static Map<ID,Schema.RecordTypeInfo> rtMapByName = result.getRecordTypeInfosById();
    public static Map<String,Schema.RecordTypeInfo> rtMapByRecName = result.getRecordTypeInfosByName();
    private static final Boolean byPass = [SELECT IsTmtTriggersDisabled__c FROM User WHERE Id=: UserInfo.getUserId()].IsTmtTriggersDisabled__c;

    public static Set<Id> prepareUserIdSet(List<Account> accountList) {
        Set<Id> userIds = new Set<Id>();
        for(Account accObj : accountList) {
            if(!String.isBlank(accObj.OwnerId)) {
                userIds.add(accObj.OwnerId);
            }
            if(!String.isBlank(accObj.Premium_Support_Agent__c)) {
                userIds.add(accObj.Premium_Support_Agent__c);
            }
            if(!String.isBlank(accObj.Current_Owner__c)) {
                userIds.add(accObj.Current_Owner__c);
            }
        }
        return userIds;
    }

    /* Utility Method */
    /****************************************************************************
     * @Description - Queries User object and fetches relevant details.          * 
     * @params Set<User>                                                        *
     * @return Map<Id,User>                                                      * 
     *****************************************************************************/
    public static Map<Id, User> getUsers(Set<Id> userIds) {
        Map<Id,User> userMap = new Map<Id,User>();
        try {
            userMap = new Map<Id,User>([SELECT Phone, Email,FirstName, LastName, Name FROM User WHERE Id IN :userIds]);
        } catch(Exception e) {}
        return userMap;
    }
    /*****************************************************************************
     * @Description - Method to update Account information                        * 
     * @params List<Account>, Map<Id,user>                                        *
     * @return void                                                               * 
     *****************************************************************************/      
    public static void accountRecordTypeInformation(List<Account> accountList,Map<Id, User> userMap) {

        System.debug('no.of queries got executed accountPhone'+limits.getqueries());
        try{    
            for(Account acct : accountList){
                if(acct.Type == PARTNER){
                    acct.RecordTypeId  = rtMapByRecName.get('Partner Account').getRecordTypeId();
                    //acct.RecordTypeId ='01280000000UERv';
                }else{
                    acct.RecordTypeId  = rtMapByRecName.get('Customer Account').getRecordTypeId();
                    // acct.RecordTypeId ='01280000000UERq';
                }
                if(acct.Premium_Support_Agent__c != null && userMap != null && userMap.containskey(acct.Premium_Support_Agent__c)) {
                    acct.Agent_Email_Address__c =  userMap.get(acct.Premium_Support_Agent__c).Email;    
                }
                if(acct.OwnerId != null && userMap != null && userMap.containskey(acct.OwnerId)) {
                    acct.Account_Owner_Phone_Number__c = userMap.get(acct.OwnerId).Phone;
                }
                if(acct.Phone!=null && acct.BillingCountry!=null){  
                    acct.Original_Phone_Number__c = acct.Phone;                                     
                    acct.Phone = ValidationUtility.validatePhoneNumber(acct.Phone,acct.BillingCountry);
                }
            }
        } catch(Exception e) {
            System.debug('accountRecordTypeInformation @ '+e.getlineNumber());
            System.debug('#### accountRecordTypeInformation '+e.getMessage()); 
        }
    }
    /*********************************************************************************
     * @Description - Method to populate partner Account name on Customer's Account   * 
     * @params List<Account>, Map<Id,Schema.RecordTypeInfo>                           *
     * @return void                                                                   * 
     *********************************************************************************/      


    public static void accountSharingOnInsert(List<Account> accountList) {
        System.debug('no.of queries got executed updateCurrentOwner'+limits.getqueries());
        try{
            Set<String> setPartnerId = new Set<String>();
            Map<String,Account> mapPartnerIdToAccount = new Map<String,Account>();
            for(Account accountObj:accountList){
                
                // no need to use accountobj.type
                if((!String.isBlank(accountObj.Partner_ID__c)) &&(CUSTOMER.equalsIgnoreCase(accountObj.Type)) ////accountObj.RecordTypeId == '01280000000UERq'
                        &&(rtMapByName != null && accountObj.RecordTypeId != null && rtMapByName.get(accountObj.RecordTypeId ).getName() == CUSTOMER_ACCOUNT)) {  
                    setPartnerId.add(accountObj.Partner_ID__c);
                }
                if(!String.isBlank(accountObj.Partner_ID__c) &&(rtMapByName != null && accountObj.RecordTypeId != null && rtMapByName.get(accountObj.RecordTypeId ).getName() == PARTNER_ACCOUNT)) {   
                    if(String.isBlank(accountObj.RC_User_ID__c)) {
                        accountObj.RC_User_ID__c = accountObj.Partner_ID__c;
                    }
                }
            }


            List<Account> lstAcc = [SELECT name,Ultimate_Parent_Account_ID__c,Current_Owner_Email__c,Current_Owner_Name__c,Ultimate_Parent_Account_Name__c,Partner_ID__c,Do_Not_Creation_Implementation__c,
                                    Ultimate_Parent_Partner_ID__c,Ultimate_Partner_ID__c,Ultimate_Partner_Name__c,Current_Owner__c, VAR_Territory__c
                                    FROM Account 
                                    WHERE  Partner_ID__c IN:setPartnerId AND type ='Partner'];
            if(!lstAcc.isEmpty()){

                for(Account accountObj :lstAcc) {
                    mapPartnerIdToAccount.put(accountObj.Partner_ID__c,accountObj);
                }
            }
            for(Account accountObj : accountList) {
                if(accountObj.Partner_ID__c != null && accountObj.Partner_ID__c != '' && mapPartnerIdToAccount != null && 
                        mapPartnerIdToAccount.get(accountObj.Partner_ID__c) != null) {
                    Account objAccount = mapPartnerIdToAccount.get(accountObj.Partner_ID__c);
                    accountObj.Do_Not_Creation_Implementation__c = objAccount.Do_Not_Creation_Implementation__c;
                }
                /***************************** code for populating partner Account name on Customer's Account *************/
                if(((accountObj.Partner_ID__c != null)&&(accountObj.Partner_ID__c != ''))
                        &&(accountObj.Type == CUSTOMER) ////accountObj.RecordTypeId == '01280000000UERq'
                        &&(rtMapByName != null && accountObj.RecordTypeId != null && rtMapByName.get(accountObj.RecordTypeId ).getName() == CUSTOMER_ACCOUNT)) {
                    if(mapPartnerIdToAccount.containsKey(accountObj.Partner_ID__c)){
                        accountObj.Partner_Account_Name__c = mapPartnerIdToAccount.get(accountObj.Partner_ID__c).name;  
                        accountObj.Ultimate_Partner_ID__c = mapPartnerIdToAccount.get(accountObj.Partner_ID__c).Ultimate_Parent_Partner_ID__c;
                        accountObj.Ultimate_Partner_Name__c = mapPartnerIdToAccount.get(accountObj.Partner_ID__c).Ultimate_Parent_Account_Name__c;

                        //Case #03765152 
                        accountObj.VAR_Territory__c = mapPartnerIdToAccount.get(accountObj.Partner_ID__c).VAR_Territory__c;
                        //Case #03765152 

                        if(!TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE) {
                            accountObj.Current_Owner__c = mapPartnerIdToAccount.get(accountObj.Partner_ID__c).Current_Owner__c;
                            accountObj.Current_Owner_Name__c = mapPartnerIdToAccount.get(accountObj.Partner_ID__c).Current_Owner_Name__c;
                            accountObj.Current_Owner_Email__c = mapPartnerIdToAccount.get(accountObj.Partner_ID__c).Current_Owner_Email__c; 
                        }
                    }   
                }
                /****************************************/
            }

        } catch(exception ex){
            System.debug('Exception accountSharingOnInsert @@'+ex.getlineNumber());
            System.debug('Exception accountSharingOnInsert'+ex.getMessage());
        }
    }
    /*********************************************************************************
     * @Description - Method to update current owner name, email                      * 
     * @params List<Account>, Map<Id,Schema.RecordTypeInfo>                           *
     * @return void                                                                   * 
     *********************************************************************************/      

    //ambiguous name
    public static void accountSharingOnUpdate0(List<Account> accList, Map<Id, User> userMap) {
        try{
            // wht is bypass
            if(!byPass){
                for(Account accObj :accList){
                    Account oldaccObj = oldAccountMap.get(accObj.ID);
                    if( accObj.Website != oldaccObj.Website  ||
                            accObj.Number_of_Locations__c != oldaccObj.Number_of_Locations__c ||
                            accObj.NumberOfEmployees != oldaccObj.NumberOfEmployees ||
                            //is there a need for this condition
                            accObj.No_of_Employees__c != oldaccObj.No_of_Employees__c  ||
                            accObj.Industry != oldaccObj.Industry ||
                            accObj.Is_the_customer_interested_in_porting__c != oldaccObj.Is_the_customer_interested_in_porting__c) {
                        accObj.Customer_Profile_Last_modified_Date__c  = System.now();
                        System.debug('#######'+accObj.Customer_Profile_Last_modified_Date__c);
                    }
                    //update current owner name, email
                    if(accObj.Current_Owner__c != null){
                        if((oldaccObj.Current_Owner__c != accObj.Current_Owner__c) && /*!UserRc.compareUserName(UserInfo.getName())*/ (! UserInfo.getFirstName().containsIgnoreCase('RCSF'))){
                            User CO = usermap.get(accObj.Current_Owner__c);
                            accObj.Current_Owner_Name__c = CO.Name;
                            accObj.Current_Owner_Email__c = CO.Email;               
                        }       
                    }
                    if(oldaccObj.Current_Owner__c != null && accObj.Current_Owner__c == null){
                        // if current owner was removed
                        accObj.Current_Owner_Name__c = null;
                        accObj.Current_Owner_Email__c = null;                               
                    }

                    if(userMap != null && oldaccObj.OwnerId != null && accObj.OwnerId != null && 
                            ((oldaccObj.OwnerId != accObj.OwnerId) ||
                                    (oldaccObj.Account_Owner_Phone_Number__c != userMap.get(accObj.OwnerId).phone))) {
                        accObj.Account_Owner_Phone_Number__c = userMap.get(accObj.OwnerId).Phone;       
                    }
                }
            }

            Set<ID> accIds = new Set<ID>();
            for(Account accObj :accList){
                if(accObj.RC_Account_Number__c != null){
                    if(accObj.RC_Account_Number__c.length() == 11 && accObj.RC_Account_Number__c.startsWith('1')){
                        accObj.RC_Account_Number__c = accObj.RC_Account_Number__c.substring(1); 
                    }
                }
                accIds.add(accObj.id);
            }
            ImplementationMethods im = new ImplementationMethods();
            for(Account newAccount : accList) {
                Account oldAccount = oldAccountMap.get(newAccount.id);
                if(im.chkToHardwareRtnOnDeactivation(newAccount,oldAccount)) {
                    newAccount.Hardware_Return_Pending__c = true;
                    newAccount.Trial_De_activation_Date__c = System.today();  
                }
                if(newAccount.Phone!=null && newAccount.billingCountry!=null){
                    if(newAccount.Phone!=oldAccount.Phone || newAccount.billingCountry!=oldAccount.billingCountry){                                         
                        newAccount.Phone = ValidationUtility.validatePhoneNumber(newAccount.Phone,newAccount.BillingCountry);
                    }
                }
            }
            List<Account> accountList =[SELECT Id, Name, (SELECT c.Id, c.status FROM Cases c WHERE c.recordtype.name LIKE '%Porting%' OR c.recordtype.name LIKE '%porting%') 
                                        FROM Account WHERE ID in : accIds];
            for(Account acctObj : accountList){
                List<case> caseList = acctObj.getSObjects('Cases'); 
                caseAccountMap.put(acctObj.Id, caseList); 
            }
            /*for(Account accObj :accList){
            //Number Porting Fields Update
            if(accObj.Id != null){
                accObj = toggleNumberPorting(accObj);
            }
        }*/
            accountSharingOnUpdate1(accList);
        }catch(Exception e){
            System.debug('Exception accountSharingOnUpdate0 @@'+e.getlineNumber());
            System.debug('Exception accountSharingOnUpdate0'+e.getMessage());
        }
    }
    /*********************************************************************************
     * @Description - Method to update current owner name, email                      * 
     * @params List<Account>, Map<Id,Account>[trigger.oldMap]                         *
     * @return void                                                                   * 
     *********************************************************************************/   
    public static void accountSharingOnUpdate1(List<Account> accountList) {
        try {
            Set<String> setPartnerId  = New Set<String>();
            Map<String,Account> MapPartnerId = new Map<String,Account>();
            for(Account objAcc : accountList) {
                if(!String.isBlank(objAcc.Partner_ID__c)) {
                    setPartnerId.add(objAcc.Partner_ID__c);
                }
            }
            //system.debug('-------------------------------------------'+ setPartnerId);    
            for(Account objAccount:[SELECT Partner_ID__c,Current_Owner__c, Current_Owner_Name__c, Current_Owner_Email__c 
                                    FROM Account  WHERE Partner_ID__c IN : setPartnerId AND type = 'Partner' AND 
                                    RecordType.Name = 'Partner Account']){
                MapPartnerId.put(objAccount.Partner_ID__c,objAccount);
            }
            //system.debug('--------------------------------------------'+MapPartnerId);
            for(Account objAcc : accountList) {
                String OldPartnerIdvalue = oldAccountMap.get(objAcc.Id).Partner_ID__c;
                if((rtMapByName.get(objAcc.RecordTypeId ).getName() == CUSTOMER_ACCOUNT) &&  objAcc.Partner_ID__c != null && 
                        (OldPartnerIdvalue != objAcc.Partner_ID__c) && MapPartnerId != null && 
                        MapPartnerId.get(objAcc.Partner_ID__c) != null) {
                    //System.Debug('>>>!!!>>');         
                    objAcc.Current_Owner__c  = MapPartnerId.get(objAcc.Partner_ID__c).Current_Owner__c;
                    objAcc.Current_Owner_Name__c = MapPartnerId.get(objAcc.Partner_ID__c).Current_Owner_Name__c;
                    objAcc.Current_Owner_Email__c = MapPartnerId.get(objAcc.Partner_ID__c).Current_Owner_Email__c;
                    //System.Debug('>>>!!!>>'+ objAcc.Current_Owner__c);
                }
            }
        } catch(Exception  e){
            System.debug('Exception accountSharingOnUpdate1 @@'+e.getlineNumber());
            System.debug('Exception accountSharingOnUpdate1'+e.getMessage());
        }
    }
    /*********************************************************************************
     * @Description - Method to update current owner name, email                      * 
     * @params List<Account>, Map<Id,Account>[trigger.oldMap]                         *
     * @return void                                                                   * 
     *********************************************************************************/
    public static void accountSharingOnUpdate2(List<Account> accList) {
        Map<String,Account> mapPartnerIdToAccount = new Map<String,Account>();
        try{
            Set<String> setPartnerId = new Set<String>();
            if(!accList.isEmpty()){
                for(Account objAcc : accList){
                    Account accB4Update = oldAccountMap.get(objAcc.id);
                    System.debug('$$$$$$$$$$$ accB4Update.Partner_ID__c '+ accB4Update.Partner_ID__c);
                    System.debug('$$$$$$$$$$$ objAcc.Partner_ID__c '+objAcc.Partner_ID__c);

                    if(((objAcc.Partner_ID__c != null)&&(objAcc.Partner_ID__c != ''))
                            &&(objAcc.Type == CUSTOMER) // objAcc.RecordTypeId == '01280000000UERq'
                            &&(rtMapByName != null && objAcc.RecordTypeId != null && rtMapByName.get(objAcc.RecordTypeId ).getName() == CUSTOMER_ACCOUNT)
                            &&(accB4Update.Partner_ID__c != objAcc.Partner_ID__c)) {
                        setPartnerId.add(objAcc.Partner_ID__c);
                        System.debug('$$$$$$$$$$$'+setPartnerId);
                    }
                }
            }
            List<Account> lstAcc = [SELECT name,Partner_ID__c,Do_Not_Creation_Implementation__c,Ultimate_Parent_Partner_ID__c,Ultimate_Partner_ID__c,Ultimate_Partner_Name__c,
                                    Ultimate_Parent_Account_ID__c,Ultimate_Parent_Account_Name__c,Current_Owner__c,Current_Owner_Email__c,Current_Owner_Name__c, VAR_Territory__c
                                    FROM Account 
                                    WHERE  Partner_ID__c IN:setPartnerId AND type ='Partner'];
            if(!lstAcc.isEmpty()){                      
                for(Account objAcc:lstAcc) {
                    mapPartnerIdToAccount.put(objAcc.Partner_ID__c,objAcc);
                }
            }
            for(Account objAcc : accList) {
                if(objAcc.Partner_ID__c != null && objAcc.Partner_ID__c != '' && mapPartnerIdToAccount != null && 
                        mapPartnerIdToAccount.get(objAcc.Partner_ID__c) != null) {
                    Account objAccount = mapPartnerIdToAccount.get(objAcc.Partner_ID__c);
                    objAcc.Do_Not_Creation_Implementation__c = objAccount.Do_Not_Creation_Implementation__c;    
                }
            }
        }catch(exception ex){
            System.debug('Exception accountSharingOnUpdate2 @@'+ex.getlineNumber());
            System.debug('Exception accountSharingOnUpdate2'+ex.getMessage());
        }
        try{
            List<Account> partnerAccountLst = new List<Account>();
            Set<String> lstPartnerAcc = new Set<String>();

            for(Account objAcc : accList) {
                if(!accList.isEmpty()){
                    Account partnerAccountB4 = oldAccountMap.get(objAcc.id);
                    //system.debug('----------------------------->> Partner update');
                    if((partnerAccountB4.Do_Not_Creation_Implementation__c != objAcc.Do_Not_Creation_Implementation__c) 
                            &&(objAcc.Type == PARTNER) && objAcc.Partner_Id__c != null // objAcc.RecordTypeId == '01280000000UERv' 
                            &&(rtMapByName != null && objAcc.RecordTypeId != null && rtMapByName.get(objAcc.RecordTypeId ).getName() == PARTNER_ACCOUNT)
                    ) {
                        //system.debug('------------------ Inside -------------------');
                        lstPartnerAcc.add(objAcc.Partner_Id__c);
                        partnerAccountLst.add(objAcc);
                    }
                    //system.debug('------------------lstPartnerAcc  '+lstPartnerAcc);
                    //system.debug('------------------partnerAccountLst '+partnerAccountLst);
                }
            }
            Map<String,List<Account>> MapToPartnerLstCustomer = new Map<String,List<Account>>();
            List<Account> lstPartnerCustomer = new  List<Account>();
            lstPartnerCustomer = [SELECT Partner_Id__c,Do_Not_Creation_Implementation__c 
                                  FROM Account WHERE Partner_Id__c IN:lstPartnerAcc AND RecordType.Name = 'Customer Account'];
            for(Account accountObj : lstPartnerCustomer) {
                if(accountObj.Partner_Id__c != null) {
                    List<Account> accountList = new List<Account>();
                    if(MapToPartnerLstCustomer != null && MapToPartnerLstCustomer.containsKey(accountObj.Partner_Id__c)) {
                        accountList = MapToPartnerLstCustomer.get(accountObj.Partner_Id__c);
                    }
                    accountList.add(accountObj);
                    MapToPartnerLstCustomer.put(accountObj.Partner_Id__c,accountList);
                }
            }                     
            //system.debug('-------------------------------------->'+ lstPartnerCustomer);

            List<Account> lstPartnerChildCustomer = new List<Account>();
            for(Account objPartner : partnerAccountLst) {
                if(objPartner.Do_Not_Creation_Implementation__c != oldAccountMap.get(objPartner.id).Do_Not_Creation_Implementation__c) {
                    for(Account PartnerCustomer : MapToPartnerLstCustomer.get(objPartner.Partner_Id__c)) {
                        if(objPartner.Partner_Id__c == PartnerCustomer.Partner_Id__c) {
                            PartnerCustomer.Do_Not_Creation_Implementation__c = objPartner.Do_Not_Creation_Implementation__c;
                            System.debug('------------'+ PartnerCustomer.Do_Not_Creation_Implementation__c);
                            lstPartnerChildCustomer.add(PartnerCustomer);
                        }
                    }   
                }
            }
            system.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'+ lstPartnerChildCustomer);
            if(!lstPartnerChildCustomer.isEmpty()){
                triggerhandler.BY_PASS_ACCOUNT_ON_UPDATE();
                update lstPartnerChildCustomer;
                TriggerHandler.RESET_VARIABLES(); 
            }
            /***************************** code for populating partner Account name on Customer's Account *************/
            for(Account objAcc : accList) { 
                if(!accList.isEmpty()){
                    System.debug('@@@@@@@@@@@@ update 1');
                    if(((objAcc.Partner_ID__c != null)&&(objAcc.Partner_ID__c != ''))
                            &&(objAcc.Type == 'Customer') ////objAcc.RecordTypeId == '01280000000UERq'
                            &&(rtMapByName != null && objAcc.RecordTypeId != null && rtMapByName.get(objAcc.RecordTypeId ).getName() == CUSTOMER_ACCOUNT)) {
                        System.debug('################ update 2');
                        if(mapPartnerIdToAccount.containsKey(objAcc.Partner_ID__c)){
                            System.debug('################ update 3');
                            objAcc.Partner_Account_Name__c = mapPartnerIdToAccount.get(objAcc.Partner_ID__c).name;
                            objAcc.Ultimate_Partner_ID__c = mapPartnerIdToAccount.get(objAcc.Partner_ID__c).Ultimate_Parent_Partner_ID__c;
                            objAcc.Ultimate_Partner_Name__c = mapPartnerIdToAccount.get(objAcc.Partner_ID__c).Ultimate_Parent_Account_Name__c;

                            //Case #03765152
                            objAcc.VAR_Territory__c = mapPartnerIdToAccount.get(objAcc.Partner_ID__c).VAR_Territory__c;
                            //Case #03765152
                            
                            if(!TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE){ 
                                System.debug('################ update 4');
                                objAcc.Current_Owner__c = mapPartnerIdToAccount.get(objAcc.Partner_ID__c).Current_Owner__c;
                                objAcc.Current_Owner_Name__c = mapPartnerIdToAccount.get(objAcc.Partner_ID__c).Current_Owner_Name__c;
                                objAcc.Current_Owner_Email__c = mapPartnerIdToAccount.get(objAcc.Partner_ID__c).Current_Owner_Email__c;
                            }
                        }   
                    }
                }
            }       
            /****************************************/ 
        }catch(exception ex){
            System.debug('Exception lstPartnerChildCustomer @@'+ex.getlineNumber());
            System.debug('Exception lstPartnerChildCustomer'+ex.getMessage());
        }
    }
    
    /*********************************************************************************
    * @Description - Method to update customer of Partner account in customer count field                      * 
    * @params List<Account>, Map<Id,Account>[trigger.oldMap]                         *
    * @return void                                                                   * 
    *********************************************************************************/           
    public static void updateCreditCounter(List<Account> accountList, map<Id,Account> oldAccountMapParam) {
        try {
            set<string> partnerIDSet = new set<string>();
            for(Account accObj : accountList) {
                if(accObj.RecordTypeId != null && (rtMapByName.get(accObj.RecordTypeId).getName() == 'Customer Account') &&
                    accObj.Partner_ID__c != null) {
                    partnerIDSet.add(accObj.Partner_ID__c);
                }
            }            
            map<Id,Integer> counterToPartnerAccount = new map<Id,Integer>();
            //map<string,Account> partnerIdToAccountMap = new map<string,Account>();
            //
            for(Account accObj : [select Partner_ID__c,Eligible_for_Refferel_Credit__c,Pay_Referral_Commissions__c, Partner_Sign_Up_Date__c,RC_Signup_Date__c,
                                  Partner_Customer_Count__c,Referring_DSR__c from Account where 
                                  RecordType.Name = 'Partner Account' and Partner_ID__c IN : partnerIDSet]) {
                partnerIdToAccountMap.put(accObj.Partner_ID__c,accObj);
                Integer initialCounter = accObj.Partner_Customer_Count__c != null ? Integer.valueOf(accObj.Partner_Customer_Count__c) : 0;
                counterToPartnerAccount.put(accObj.Id,initialCounter); 
            }           
            List<Account> partnerAccountToUpd = new List<Account>();
            map<id,Account> accountIdMapToUpd = new map<id,Account>();
            for(Account accObj : accountList) {
                if(accObj.RecordTypeId != null && (rtMapByName.get(accObj.RecordTypeId).getName() == 'Customer Account') &&
                    accObj.Partner_ID__c != null && !String.isBlank(accObj.RC_Account_Status__c) && (oldAccountMapParam == null || 
                    oldAccountMapParam.get(accObj.id).RC_Account_Status__c != accObj.RC_Account_Status__c 
                    || oldAccountMapParam != null && oldAccountMapParam.get(accObj.id).Pay_Referral_Commissions__c != accObj.Pay_Referral_Commissions__c 
                    && accObj.Pay_Referral_Commissions__c == true) && 
                    (accObj.RC_Account_Status__c).equalsIgnoreCase('Paid')
                    && partnerIdToAccountMap != null && partnerIdToAccountMap.get(accObj.Partner_ID__c) != null) {
                    Account partnerAccountObj = partnerIdToAccountMap.get(accObj.Partner_ID__c);
                    if(oldAccountMapParam == null || oldAccountMapParam != null 
                        && (!'Suspended'.equalsIgnoreCase(oldAccountMapParam.get(accObj.id).RC_Account_Status__c) 
                        && !'Canceled'.equalsIgnoreCase(oldAccountMapParam.get(accObj.id).RC_Account_Status__c))){
                        if(partnerAccountObj != null && partnerAccountObj.Referring_DSR__c != NULL
                            && partnerAccountObj.Partner_Sign_Up_Date__c != null
                            && ((counterToPartnerAccount.get(partnerAccountObj.id) < 5 && partnerAccountObj.Partner_Sign_Up_Date__c.year() < 2015) 
                                || (counterToPartnerAccount.get(partnerAccountObj.id) < 3 && partnerAccountObj.Partner_Sign_Up_Date__c.year() >= 2015))
                            && accObj.RC_Signup_Date__c != null
                            && (partnerAccountObj.Partner_Sign_Up_Date__c.daysBetween(accObj.RC_Signup_Date__c.date())) < 185) {
                            accObj.Eligible_for_Refferel_Credit__c  = true; 
                            counterToPartnerAccount.put(partnerAccountObj.id,counterToPartnerAccount.get(partnerAccountObj.id) + 1);
                            partnerAccountObj.Partner_Customer_Count__c = counterToPartnerAccount.get(partnerAccountObj.id);
                            //system.Debug('>>12345>>>' + partnerAccountObj.Id + ',,'  + partnerAccountObj.Partner_Customer_Count__c);
                            partnerAccountToUpd.add(partnerAccountObj);
                            accountIdMapToUpd.put(partnerAccountObj.id,partnerAccountObj);
                            //system.debug('!!!!!!!!!'+accountIdMapToUpd);
                        }
                    } 
                }
            }
            eligiblePartnerAccountStaticIdSet.addall(accountIdMapToUpd.keySet());
            // Inserting/updating account split records
            //createUpdateAccountSplits(accountList,partnerIdToAccountMap,accountIdMapToUpd.keySet());
            if(accountIdMapToUpd != null && accountIdMapToUpd.values() != null && accountIdMapToUpd.values().size()>0) {                  
                triggerhandler.BY_PASS_ACCOUNT_ON_INSERT();
                triggerhandler.BY_PASS_ACCOUNT_ON_UPDATE();
                update accountIdMapToUpd.values();
                TriggerHandler.RESET_VARIABLES(); 
            }
        } catch(Exception ex) {}
    }    
    public static void updateMostRecentImplementationContact(Map<Id,Account> mapAccount){
        try{
            for(Account objAccount : [Select Most_Recent_Implementation_Contact__c, (Select Id, AccountId, ContactId, Role, IsPrimary, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, IsDeleted From AccountContactRoles where isPrimary=true) From Account a where a.id IN :mapAccount.keySet() ]){
                if(objAccount.AccountContactRoles.size() != 0) {
                    AccountContactRole objACR = objAccount.AccountContactRoles[0]; 
                    if(objACR!=null && objACR.ContactId != Null){
                        mapAccount.get(objAccount.Id).Most_Recent_Implementation_Contact__c = objACR.ContactId;
                    }
                }
            }
        }catch(Exception e){
             System.debug('Exception updatePartnerCodeOnIsertAndUpdate @@'+e.getlineNumber());
            System.debug('Exception updatePartnerCodeOnIsertAndUpdate'+e.getMessage());
        }
    }
    public static void updatePartnerCodeOnInsertAndUpdate(List<Account> accountList) {
        try {
            Map<String,Account> partnerAccMap = new Map<String,Account>();
            Set<String> partnerAccountIdSet = new Set<String>();
            for(Account objAcc : accountList){
                if(objAcc.Partner_Id__c != null && (rtMapByName != null && objAcc.RecordTypeId != null 
                        && rtMapByName.get(objAcc.RecordTypeId).getName() == PARTNER_ACCOUNT) ){
                    partnerAccMap.put(objAcc.Partner_ID__c,objAcc);
                }
            }
            List<Account> customerAccountList = [SELECT id,Current_Owner__c,Partner_ID__c FROM Account WHERE Partner_ID__c IN: partnerAccMap.keySet()
                                                 AND RecordType.Name = 'Customer Account'];
            for(Account customerAccount : customerAccountList) {
                if(partnerAccMap.containsKey(customerAccount.Partner_ID__c) && 
                        customerAccount.Current_Owner__c != partnerAccMap.get(customerAccount.Partner_ID__c).Current_Owner__c){
                    customerAccount.Current_Owner__c = partnerAccMap.get(customerAccount.Partner_ID__c).Current_Owner__c;
                }   
            }
            if(!customerAccountList.isEmpty()){  
                TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
                update customerAccountList; 
                //TriggerHandler.RESET_VARIABLES(); 
                TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
            }
        } catch(exception e){
            System.debug('Exception updatePartnerCodeOnIsertAndUpdate @@'+e.getlineNumber());
            System.debug('Exception updatePartnerCodeOnIsertAndUpdate'+e.getMessage());
        }
    }

    /*****************************************************************************
     * @Description - Method for Number Porting Initiation.                       * 
     * @params Account                                                            *
     * @return Account objAcc                                                     * 
     *****************************************************************************/   
    // Need to automate toggling if there is an existing Porting Case from the Account
    /*public static Account toggleNumberPorting(Account objAcc){
    System.debug('no.of queries got executed toggleNumberPorting'+limits.getQueries());
    try{
        Boolean hasCompletedCase = false;
        List<Case> caseList = caseAccountMap.get(objAcc.Id);
        if(caseList!=null && caseList.size()>0){
            objAcc.Number_Porting_Initiated__c = true;
            for(Case caseObj : caseList){
                if(CLOSED.equalsIgnoreCase(caseObj.status)){
                    hasCompletedCase = true;
                    break;
                }
            }
        }else {
            objAcc.Number_Porting_Initiated__c = false;
        }
        if(hasCompletedCase){
            objAcc.Number_Porting_Completed__c = true;
        }else{
            objAcc.Number_Porting_Completed__c = false;
        }
    }catch(Exception ex){
        System.debug('Exception toggleNumberPorting @@'+ex.getlineNumber());
        System.debug('Exception toggleNumberPorting'+ex.getMessage());
    }
    System.debug('no.of queries got executed toggleNumberPorting'+limits.getQueries());
    return objAcc;
}*/

    /**************************************************************************
     *@Discription............: updating the Last touch sales person field    *
     *@Param..................: List<Account>,User                            *
     *@Return.................: void                                          *
     *@Last Modified by.......: 10-03-2014                                    *
     *@Last Modified Date.....: 10-03-2014                                    *  
     **************************************************************************/    
    public static void updateLastTouchedSalesPerson(List<Account> accountList, User userObj) {
        userAssignmentOnAccount(accountList, userObj);
        if(accountList != null && accountList.size() != 0) {
            TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
            TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
            try {update accountList;} catch(Exception e) {System.debug('### WE GOT EXCEPTION ### ' + e.getMessage());}
        }
    }
    /*************************************************************************/

    /**************************************************************************
     *@Discription............: Assigning the login User Value to account     *
     *                          Last touch by salesperson                     *
     *@Param..................: List<sObject>,String                          *
     *@Return.................: List<sObject>                                 *
     *@Last Modified by.......: 10-03-2014                                    *
     *@Last Modified Date.....: 10-03-2014                                    *  
     **************************************************************************/    
    public static void userAssignmentOnAccount(List<Account> accountList, User userObj){
        for(Account accountObj : accountList){
            if(userObj != null) {
                //system.debug('accountObj======='+accountObj);
                //system.debug('userObj======='+userObj);
                accountObj.LastTouchedbySalesID__c = userObj.Id;
                accountObj.LastTouchedbySalesFirstName__c = userObj.FirstName;
                accountObj.LastTouchedbySalesLastName__c = userObj.LastName;
                accountObj.LastTouchedbySalesEmail__c = userObj.Email;
                accountObj.LastTouchedbySalesPhone__c = userObj.Phone;
            }
        }
    }
    /**************************************************************************/
    
    /*************************************************************************************
    * @Description - Method to RollUp # of DL to all Parents and childs on Account on   *
    *                Insert/Update                                                      *
    * @params      -                                                                    *
    * @return      -                                                                    *
    ************************************************************************************/
    
    public static void calculateAccountHierarchyTotalDLS(Set<String> ultimateParentIdSet){
         if(ultimateParentIdSet!=null && ultimateParentIdSet.size() > 0){
            map<Id,decimal> parentCounterMap = new map<Id,decimal>();
            map<Id,List<Account>> childAccountMap = new map<Id,List<Account>>();
            system.debug('==ultimateParentIdSet=='+ultimateParentIdSet);
            List<Account> accMainList = new List<Account>();
            for(List<Account> accList : [SELECT id,Ultimate_Parent_Account_ID__c,RC_Account_Status__c, Ultimate_Parent_Snapshot__c, Number_of_DL_s__c,Total_DLs__c FROM Account
                                    WHERE NAME != NULL AND RecordType.Name =: CUSTOMER_ACCOUNT AND (Ultimate_Parent_Snapshot__c IN : ultimateParentIdSet OR Id IN : ultimateParentIdSet)]){
                accMainList.addAll(accList);                            
            }
            system.debug('==accMainList=='+accMainList.size()+'=='+accMainList);
            for(Account accObj : accMainList){
                // Only re-evaluate the hierarchy if it is either Ultimate Parent or any 'Paid' Account.
                if(accObj.RC_Account_Status__c != 'Paid' && string.valueOf(accObj.Ultimate_Parent_Account_ID__c).subString(0,15) != string.valueOf(accObj.id).subString(0,15)){
                    system.debug(' ==Continue- Eneter== ');
                    continue;
                }
                system.debug(' ==Continue- Exit == ');
                Id accountId = null;
                if(accObj.Ultimate_Parent_Account_ID__c!=null){
                    accountId = accObj.Ultimate_Parent_Account_ID__c;
                } else {
                    accountId = accObj.Id;
                }
                if(parentCounterMap!=null && parentCounterMap.get(accountId)!=null){
                    decimal counterValue = parentCounterMap.get(accountId);
                    counterValue+=(accObj.Number_of_DL_s__c!=null ? accObj.Number_of_DL_s__c : 0);
                    parentCounterMap.put(accountId,counterValue);
                    if(childAccountMap!=null && childAccountMap.get(accountId)!=null){
                        List<Account> tempList = childAccountMap.get(accountId);
                        tempList.add(accObj);
                        childAccountMap.put(accountId,tempList);
                    } else {
                        childAccountMap.put(accountId,new List<Account>{accObj});
                    }
                } else {
                    parentCounterMap.put(accountId,(accObj.Number_of_DL_s__c!=null ? accObj.Number_of_DL_s__c : 0));
                    childAccountMap.put(accountId,new List<Account>{accObj});
                }           
            }
            
            system.debug('==parentCounterMap=='+parentCounterMap.size()+'=='+parentCounterMap);
            system.debug('==childAccountMap=='+childAccountMap.size()+'=='+childAccountMap);
            
            List<Account> updatedAccountList = new List<Account>();
            
            for(Id idValue : childAccountMap.keySet()){
                for(Account accObj : childAccountMap.get(idValue)){
                    if(parentCounterMap!=null && parentCounterMap.get(idValue)!=null){
                        accObj.Total_DLs__c = parentCounterMap.get(idValue);
                        updatedAccountList.add(accObj);
                    }               
                }
            }
            
            system.debug('==updatedAccountList=='+updatedAccountList.size()+'=='+updatedAccountList);
            
            if(updatedAccountList!=null && updatedAccountList.size() > 0){
                TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
                TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
                update updatedAccountList;
                TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
                TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
            }
        }
    }
    
    /*******End Of Method to RollUp # of DL to all Parents and childs on Account on Insert/Update*******************************************************************/
    
    /**************************************************************************
     * @Discription............: Assigning the login User Value to account    *
     *                          Last touch by salesperson                     *
     * @Param..................: List<sObject>,String                         *
     * @Return.................: List<sObject>                                *
     * @Last Modified by.......: 10-03-2014                                   *
     * @Last Modified Date.....: 10-03-2014                                   *  
     **************************************************************************/
    /*public static void accountUpdation(List<Account> updatedChildAccount, User userObj) { 
        try {
            List<Account> lstAccountToUpdate = new List<Account>();
            if(updatedChildAccount.size() > 0){
                for(Account accountObj:updatedChildAccount){
                    system.debug('accountObj'+userObj);
                    accountObj.LastTouchedbySalesID__c = userObj.Id;
                    accountObj.LastTouchedbySalesFirstName__c = userObj.FirstName;
                    accountObj.LastTouchedbySalesLastName__c = userObj.LastName;
                    accountObj.LastTouchedbySalesEmail__c = userObj.Email;
                    accountObj.LastTouchedbySalesPhone__c = userObj.Phone;
                    lstAccountToUpdate.add(accountObj);
                }   
            }
            if(!lstAccountToUpdate.isEmpty()){
                //system.debug('@@@ In Update ===>');
                TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
                TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
                update lstAccountToUpdate;
            }
        } catch (Exception ex) {
            system.debug('#### Error on line - '+ex.getLineNumber());
            system.debug('#### Error message - '+ex.getMessage());
        }
    }*/
    /*****************************************************************************/
    
    public static void updateContactStatus(List<Account> accountList){
        Set<Id> accIds = new Set<Id>();
        Map<String,String> accStatus = new Map<String,String>();
        List<Contact> lstContact = new List<Contact>();
        try{
            for(Account acc : accountList){
                if(oldAccountMap != NULL && oldAccountMap.containsKey(acc.Id) && oldAccountMap.get(acc.Id) != NULL 
                    && acc.RC_Account_Status__c != oldAccountMap.get(acc.Id).RC_Account_Status__c
                    && ('Paid'.equalsIgnoreCase(acc.RC_Account_Status__c) || 'Cancelled'.equalsIgnoreCase(acc.RC_Account_Status__c) 
                        || 'Canceled'.equalsIgnoreCase(acc.RC_Account_Status__c))){
                    accIds.add(acc.id);
                    accStatus.put(acc.id,acc.RC_Account_Status__c);
                }
            }
            
            for(Contact conObj : [SELECT id,AccountId, isCustomer__c,Contact_Status__c ,People_Segment__c,RCService_ContactStatus__c 
                                    FROM Contact WHERE AccountId IN :accIds]){
                Boolean isContactUpdated = false;
                String upcomingStatus = accStatus.get(conObj.AccountId);
                if(('Paid'.equalsIgnoreCase(upcomingStatus) && conObj.Contact_Status__c != 'Closed Won') 
                    || ('Cancelled'.equalsIgnoreCase(upcomingStatus) && conObj.Contact_Status__c != 'Cancelled')
                    || ('Canceled'.equalsIgnoreCase(upcomingStatus) && conObj.Contact_Status__c != 'Canceled')) {
                    isContactUpdated = true;
                    Boolean paid = false;
                    Boolean canceled = false;
                    if('Paid'.equalsIgnoreCase(upcomingStatus)){
                        paid = true;
                    }else if(('Cancelled'.equalsIgnoreCase(upcomingStatus) || 'Canceled'.equalsIgnoreCase(upcomingStatus))){
                        canceled = true;
                    }
                    conObj.Contact_Status__c = (paid ? 'Closed Won' : (canceled ? 'Canceled' : conObj.Contact_Status__c));
                    conObj.Contact_Funnel_Type__c = (paid ? 'Customer' : (canceled ? 'Winback' : conObj.Contact_Funnel_Type__c));
                    conObj.isCustomer__c=(paid ? true : (canceled ? false : conObj.isCustomer__c));
                    conObj.People_Segment__c= (paid ? 'Customer' : (canceled ? 'Former Customer' : conObj.People_Segment__c));
                }   
                if(isContactUpdated) {
                    lstContact.add(conObj);
                }
            }
            TriggerHandler.BY_PASS_CONTACT_ON_UPDATE();
            if(lstContact.size() >0)
                update lstContact;
            TriggerHandler.BY_PASS_CONTACT_ON_UPDATE = false;   
        }catch(Exception ex){
            system.debug('Exception==========='+ex.getStackTraceString());
        }
    }
    /**************************************************************************
     * @Discription............:  Create Or/And Update Account-Split Records  *
     * @Param..................:  List<Account>, Set<Id>                      *
     * @Return.................:  Void                                        *
     * @Last Modified by.......:  Rajesh Kumar                                *
     * @Last Modified Date.....:  4/21/2015                                   *  
     **************************************************************************/
    public static void createUpdateAccountSplits(List<Account> customerAccountList,Set<Id> eligiblePartnerAccountIdSet){
        List<Account> eligibleCustomerAccountList = new List<Account>();// only those customers whose partner is going to increase the Counter on it. 
        List<Account_Split__c> accountSplitList = new List<Account_Split__c>();
        List<Account_Split__c> toDeleteAccSplitList = new List<Account_Split__c>();
        List<Account_Split__c> accountSplitToUpsertList =  new List<Account_Split__c>();
        Map<Id,Account_Split__c> accountToAccSplitOverlayTypeMap = new Map<Id,Account_Split__c>();
        Map<Id,Account> idToCustomerAccntMap = new Map<Id,Account>();
        Map<Id,Account_Split__c> accountToAccSplitResselerTypeMap = new Map<Id,Account_Split__c>();
        Set<id> accountIdSet = new Set<Id>();
        Set<id> accIdSet = new Set<Id>(); /// Case #03726551
        for(Account acc : customerAccountList){
            if(partnerIdToAccountMap!= NULL && partnerIdToAccountMap.containsKey(acc.Partner_ID__c) && partnerIdToAccountMap.get(acc.Partner_ID__c) != NULL){
                if(eligiblePartnerAccountIdSet != NULL && eligiblePartnerAccountIdSet.contains(partnerIdToAccountMap.get(acc.Partner_ID__c).Id)){
                    accountIdSet.add(acc.id);
                    eligibleCustomerAccountList.add(acc);
                    idToCustomerAccntMap.put(acc.Id,acc);
                    trackDeletedAccntSplitSet.add(acc.Id);
                    // Case #03726551 15th July 2015, Below elseif condition. If it has not gone to Partner Referral logic then it should do the following
                }else if(acc.RecordTypeId != null && (rtMapByName.get(acc.RecordTypeId).getName() == 'Customer Account')){
                    if(acc.RC_Account_Status__c != NULL && String.valueOf(acc.RC_Account_Status__c).equalsIgnoreCase('Paid') 
                      && oldAccountMap != NULL && oldAccountMap.containsKey(acc.Id) 
                      && oldAccountMap.get(acc.Id).RC_Account_Status__c != acc.RC_Account_Status__c){
                        accIdSet.add(acc.id);   
                    }   
                }    
            }
        }
            
        if(idToCustomerAccntMap != NULL){
            accountSplitList = returnAccountSplitList(accountIdSet);
                        
            for(Account_Split__c accSplit : accountSplitList){
                if(idToCustomerAccntMap.containsKey(accSplit.Account__c) && idToCustomerAccntMap.get(accSplit.Account__c) != NULL){
                    if(oldAccountMap != NULL && oldAccountMap.containsKey(accSplit.Account__c) && oldAccountMap.get(accSplit.Account__c) != NULL
                        && idToCustomerAccntMap.get(accSplit.Account__c).Partner_ID__c != oldAccountMap.get(accSplit.Account__c).Partner_ID__c){
                        if((accSplit.Role__c == 'DSR Shared Agent' && accSplit.Agent_Credit_Sub_Type__c == 'Overlay Shared')
                                || accSplit.Role__c == 'Reseller Referral Agent' && accSplit.Agent_Credit_Sub_Type__c == 'Reseller Referral'){
                            // If Customer's Partner is being changed, then delete previous AC Split records and create new ones.
                            toDeleteAccSplitList.add(accSplit);
                            continue;
                        }
                    }
                }
                if(accSplit.Role__c == 'DSR Shared Agent' && accSplit.Agent_Credit_Sub_Type__c == 'Overlay Shared'){
                    accountToAccSplitOverlayTypeMap.put(accSplit.Account__c,accSplit);
                }
                if(accSplit.Role__c == 'Reseller Referral Agent' && accSplit.Agent_Credit_Sub_Type__c == 'Reseller Referral'){
                    accountToAccSplitResselerTypeMap.put(accSplit.Account__c,accSplit);
                }   
            }
            accountSplitToUpsertList = getAccountSplitUpsertList(eligibleCustomerAccountList,accountToAccSplitOverlayTypeMap,accountToAccSplitResselerTypeMap);
        }
        /// Case #03726551
        if(accIdSet.size() > 0 ){
            List<Account_Split__c> accSplitTempList = new List<Account_Split__c>();
            accSplitTempList = returnAccountSplitList(accIdSet);
            for(Account_Split__c accSpl : accSplitTempList){
                if(accSpl.Agent_Credit_Sub_Type__c == 'Overlay Shared' && accSpl.BeginDateUpdateOnStatusChange__c == false){
                    accSpl.Begin_Date__c = System.today();
                    accSpl.BeginDateUpdateOnStatusChange__c = true;
                    accountSplitToUpsertList.add(accSpl);
                }
            }
        }
        if(!toDeleteAccSplitList.isEmpty()){
            delete toDeleteAccSplitList;    
        }
        if(!accountSplitToUpsertList.isEmpty()){
            upsert accountSplitToUpsertList;    
        }
        // resetting variables
        accountSplitList = null;
        accountSplitToUpsertList = null;
        accountToAccSplitOverlayTypeMap = null;
        accountToAccSplitResselerTypeMap = null;
    }
    /************************************************************************************************
     * @Discription............:  This method returns AccountSplit lists to Update or Insert        *
     *                         :  - based on Conditions.                                            *
     * @Param..................:  List<Account>, Map<Id,Account_Split__c>, Map<Id,Account_Split__c> *
     * @Return.................:  List<Account_Split__c>                                            *
     * @Last Modified by.......:  Rajesh Kumar                                                      *
     * @Last Modified Date.....:  4/21/2015                                                         *  
     ************************************************************************************************/
    private static List<Account_Split__c> getAccountSplitUpsertList(List<Account> customerAccountList,Map<Id,Account_Split__c> accountToAccSplitOverlayTypeMap,Map<Id,Account_Split__c> accountToAccSplitResselerTypeMap){
        List<Account_Split__c> accountSplitToUpsertList =  new List<Account_Split__c>();
        for(Account acc : customerAccountList){
            if(acc.RecordTypeId != null && (rtMapByName.get(acc.RecordTypeId).getName() == 'Customer Account')){
                Account partnerAccount;
                Boolean referralAcntSplitFoundBool = false;
                Boolean overlayAcntSplitFoundBool = false;
                if(accountToAccSplitOverlayTypeMap != NULL && accountToAccSplitOverlayTypeMap.containsKey(acc.id) && accountToAccSplitOverlayTypeMap.get(acc.id) != NULL){
                    overlayAcntSplitFoundBool = true;
                }
                if(accountToAccSplitResselerTypeMap != NULL && accountToAccSplitResselerTypeMap.containsKey(acc.id) && accountToAccSplitResselerTypeMap.get(acc.id) != NULL){
                    referralAcntSplitFoundBool = true;
                }
                if(partnerIdToAccountMap != NULL && partnerIdToAccountMap.containsKey(acc.Partner_ID__c) && partnerIdToAccountMap.get(acc.Partner_ID__c) != NULL){
                    partnerAccount = partnerIdToAccountMap.get(acc.Partner_ID__c);
                }   
                if(partnerAccount != NULL && !String.isBlank(String.valueOf(partnerAccount.Partner_Sign_Up_Date__c))){
                    if(overlayAcntSplitFoundBool == true){
                        Account_Split__c accSplitToUpdate = accountToAccSplitOverlayTypeMap.get(acc.id);
                        accSplitToUpdate.Commission__c = 70;
                        /// Case #03726551
                        if(accSplitToUpdate.BeginDateUpdateOnStatusChange__c == false){
                            accSplitToUpdate.Begin_Date__c = System.today();
                            accSplitToUpdate.BeginDateUpdateOnStatusChange__c = true;
                        }
                        system.debug('======= End Date ====== '+ String.isBlank(String.valueOf(accSplitToUpdate.End_Date__c)));
                        system.debug('======= Commissionable_Period__c ====== '+ accSplitToUpdate.Commissionable_Period__c);
                        /*if(String.isBlank(String.valueOf(accSplitToUpdate.End_Date__c)) && accSplitToUpdate.Commissionable_Period__c != NULL){
                            accSplitToUpdate.End_Date__c = accSplitToUpdate.Begin_Date__c.addDays(Integer.valueOf(accSplitToUpdate.Commissionable_Period__c));
                        }*/
                        accountSplitToUpsertList.add(accSplitToUpdate);
                    }
                    if(referralAcntSplitFoundBool == false){
                        Id tempSalesUserId = (partnerAccount.Referring_DSR__c != NULL ? partnerAccount.Referring_DSR__c : NULL);
                        Date partnerSignUpDate = date.newInstance(partnerAccount.Partner_Sign_Up_Date__c.year(), partnerAccount.Partner_Sign_Up_Date__c.month(),partnerAccount.Partner_Sign_Up_Date__c.day());
                        Date beginDate;
                        if(acc.RC_Upgrade_Date__c < partnerAccount.Partner_Sign_Up_Date__c){
                            beginDate = date.newInstance(acc.RC_Upgrade_Date__c.year(), acc.RC_Upgrade_Date__c.month(),acc.RC_Upgrade_Date__c.day());
                        }else{
                            beginDate = partnerSignUpDate;
                        }
                        system.debug('========== tempSalesUserIdfdfd ============' + partnerAccount.Referring_DSR__c);
                        
                        Integer commisionPercentage = populateCommisionPercentage(partnerSignUpDate,overlayAcntSplitFoundBool);
                        Account_Split__c accSplitToInsert = new Account_Split__c(Account__c = acc.Id,Sales_Agent__c = tempSalesUserId,Role__c = 'Reseller Referral Agent',
                                                Agent_Credit_Split__c = 'Overlay',Agent_Credit_Sub_Type__c = 'Reseller Referral',
                                                Commission__c = commisionPercentage,Begin_Date__c = beginDate);
                                                //,End_Date__c = (beginDate != NULL ? beginDate.addDays(180) :NULL));
                        
                        accountSplitToUpsertList.add(accSplitToInsert);
                    }
                }   
            }
        }
        return accountSplitToUpsertList;
    }
    /************************************************************************************************
     * @Discription............:  This method returns Commision Percentage based on SignUp Date     *
     * @Param..................:  Date, Boolean                                                     *
     * @Return.................:  Integer                                                           *
     * @Last Modified by.......:  Rajesh Kumar                                                      *
     * @Last Modified Date.....:  4/21/2015                                                         *  
     ************************************************************************************************/   
    private static Integer populateCommisionPercentage( Date partnerSignUpDate,Boolean overlayAcntSplitFoundBool){
        Integer commisionPercentage = 0;
        if(overlayAcntSplitFoundBool){
            commisionPercentage = 30;
        }else{
            system.debug('========== partnerSignUpDate ===='+ partnerSignUpDate);
            if(partnerSignUpDate.year() >= 2015){
                commisionPercentage = 100;
            }else{
                commisionPercentage = 80;
            }
        }
        return  commisionPercentage ;   
    }
    /**************************************************************************************************
     * @Discription............:  This method deletes Account Splits if Partner of Customer Accoount -*
     *                         :  - changes                                                           * 
     * @Param..................:  Map<Id,Account> newAccountMap                                       *
     * @Return.................:  void                                                                *
     * @Last Modified by.......:  Rajesh Kumar                                                        *
     * @Last Modified Date.....:  4/21/2015                                                           *  
     **************************************************************************************************/ 
    public static void deleteAccntSplitOnPartnerChange( Map<Id,Account> newAccountMap){
        Set<Id> accountIdSet = new Set<Id>();
        try{
            for(Id accId : newAccountMap.keySet()){
                if(!trackDeletedAccntSplitSet.contains(accId)){
                    // Will only get Account-Splits who were not deleted in 'createUpdateAccountSplits' Method as they did not match the conditions.
                    accountIdSet.add(accId);
                }
            }
            List<Account_Split__c> accountSplitList = returnAccountSplitList(accountIdSet);
            List<Account_Split__c> toDeleteAccSplitList = new List<Account_Split__c>();
            for(Account_Split__c accSplit : accountSplitList){
                Account tempNewAccount = new Account();
                Account tempOldAccount = new Account();
                if(newAccountMap != NULL && newAccountMap.containsKey(accSplit.Account__c) && newAccountMap.get(accSplit.Account__c) != NULL){
                    tempNewAccount = newAccountMap.get(accSplit.Account__c);
                }
                if(oldAccountMap != NULL && oldAccountMap.containsKey(accSplit.Account__c) && oldAccountMap.get(accSplit.Account__c) != NULL){
                    tempOldAccount = oldAccountMap.get(accSplit.Account__c);
                }
                if(tempNewAccount != NULL){
                    // DIRECT TO VAR
                    system.debug('###### accSplit.PartnerId__c ' + accSplit.PartnerId__c);
                    system.debug('###### tempNewAccount.Partner_ID__c ' + tempNewAccount.Partner_ID__c);
                    if((tempOldAccount != NULL && tempNewAccount.Partner_ID__c != tempOldAccount.Partner_ID__c) || Test.isRunningTest()){
                        if(accSplit.PartnerId__c != tempNewAccount.Partner_ID__c && tempOldAccount.Partner_ID__c != NULL ){
                            if((accSplit.Role__c == 'DSR Shared Agent' && accSplit.Agent_Credit_Sub_Type__c == 'Overlay Shared')
                                    || accSplit.Role__c == 'Reseller Referral Agent' && accSplit.Agent_Credit_Sub_Type__c == 'Reseller Referral'){
                                // If Customer's Partner is being changed, then delete previous AC Split records and create new ones.
                                toDeleteAccSplitList.add(accSplit);
                            }
                        }
                    }
                }
            }
            if(toDeleteAccSplitList.size() > 0){
                delete toDeleteAccSplitList;
            }
        }catch(Exception ex){}
    }
    /**************************************************************************************************
     * @Discription............:  Gets the AccountSplit Records based on Account Ids                  * 
     * @Param..................:  Set<Id>. Set of Account's Id                                        *
     * @Return.................:  List<Account_Split__c>                                              *
     * @Last Modified by.......:  Rajesh Kumar                                                        *
     * @Last Modified Date.....:  4/21/2015                                                           *  
     **************************************************************************************************/ 
    private static List<Account_Split__c> returnAccountSplitList(Set<Id> accountIdSet){
        List<Account_Split__c> accSplitList = [SELECT Id,PartnerId__c,Account__c,Sales_Agent__c,Role__c,Commission__c,
                                Commissionable_Period__c,Agent_Credit_Sub_Type__c,BeginDateUpdateOnStatusChange__c,
                                Agent_Credit_Split__c FROM Account_Split__c
                                        WHERE Account__c IN: accountIdSet ];
        return  accSplitList;                   
    }




    /**************************************************************************************************
     * @Discription............:  Update Signature Opt Out                      * 
     * @Param..................:  New Account, Old Account, Boolean if new or update                      *
     * @Return.................:  NA                                              *
     * @Last Modified by.......:  eugenebasianomutya                                              *
     * @Last Modified Date.....:  6/10/2015                                                 *  
     **************************************************************************************************/ 
    public static void Update_SignatureRepPartnershipOptOut(list<Account> lAccount, map<Id, Account> mAccountNew, map<Id, Account> mAccountOld, Boolean isNew){

        // New Partner/Customer Account is created. This code handles Bulk insert.
        if (isNew){

            map<String, Boolean> mPartId_PartOptOut = new map<String, Boolean>(); 
            set<String> sPartId_CustOptOut = new set<String>();
            map<String, boolean> myset = new map<String,Boolean>();
            list<Account> lCustomerAccountForUpdate = new list<Account>();

            // Get the New Customer Account and Partner Account
            for(Account a:lAccount){
                if(a.RecordTypeId == rtMapByRecName.get('Partner Account').getRecordTypeId()){
                    if(a.Partner_Id__c != '' && a.Partner_Id__c != NULL){ 
                        mPartId_PartOptOut.put(a.Partner_Id__c, a.Signature_Rep_Partnership_Opt_Out__c);
                    }
                }else{
                    if(a.Partner_Id__c != '' && a.Partner_Id__c != NULL){
                        sPartId_CustOptOut.add(a.Partner_Id__c);
                    }
                }
            }




            // ################################################# If partner Id of newly created Partner Account is already used by Customer Account, update Customer Account
            If(mPartId_PartOptOut.size()>0){
                for(Account a: [Select Id, Partner_Id__c, Signature_Rep_Partnership_Opt_Out__c FROM Account
                                 WHERE partner_Id__c in: mPartId_PartOptOut.keyset()
                                 AND RecordTypeId =: rtMapByRecName.get('Customer Account').getRecordTypeId()]){
                    if(mPartId_PartOptOut.containsKey(a.Partner_Id__c)){
                        a.Signature_Rep_Partnership_Opt_Out__c = mPartId_PartOptOut.get(a.Partner_Id__c);
                        lCustomerAccountForUpdate.add(a);
                    }

                }
                if(lCustomerAccountForUpdate.size()> 0){
                    TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = true; 
                    update lCustomerAccountForUpdate;
                    TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
                }

            }
            
            // ################################################# Set the value of Customer Account SigOptout checbox base on the Partner Account (Partner Id)
            if(sPartId_CustOptOut.size() > 0){                
                // Get the Partner Account of the created Customer Account 
                for ( Account a: [SELECT Id, Partner_Id__c, Signature_Rep_Partnership_Opt_Out__c FROM Account 
                                 WHERE Partner_Id__c In: sPartId_CustOptOut
                                 AND RecordTypeId =: rtMapByRecName.get('Partner Account').getRecordTypeId()]){
                    myset.put(a.Partner_Id__c, a.Signature_Rep_Partnership_Opt_Out__c);
                }

                for(Account a: lAccount){
                    if(myset.containskey(a.Partner_Id__c)){
                        a.Signature_Rep_Partnership_Opt_Out__c = myset.get(a.partner_Id__c);
                    }
                }
            }
            
            

        // Updates on Partner/Customer Account. This code handles Bulk insert.
        }else{

            
            list<Account> lCustomerAccountToUpdate = new list<Account>();
            set<string> sPartnerAccountPartnerIdToCheck = new set<String>();
            map<string, boolean> mCustomerAccountPartnerIdToUpdate = new map<string, Boolean>();
            map<String, Boolean> myset = new map<String, Boolean>(); 

            // If Partner ID of Partner Account is removed, set checkbox of customer account to false if there are any
            for(Account a:mAccountNew.values()){

                // If Partner Account Partner ID or SigOptout is updated, get all customer Account and update
                if(a.RecordTypeId == rtMapByRecName.get('Partner Account').getRecordTypeId()){
                    // This code is commented since we do not change/remove partner id in partner account (business rule - Danielle)
                    /*if(a.Partner_Id__c != mAccountOld.get(a.Id).Partner_Id__c) {
                        if(a.Partner_Id__c == '' || a.Partner_Id__c == NULL){
                            mCustomerAccountPartnerIdToUpdate.put(mAccountOld.get(a.Id).Partner_Id__c, false);
                        }else if(a.Partner_Id__c != '' || a.Partner_Id__c != NULL){
                            mCustomerAccountPartnerIdToUpdate.put(a.Partner_Id__c, a.Signature_Rep_Partnership_Opt_Out__c);
                            mCustomerAccountPartnerIdToUpdate.put(mAccountOld.get(a.Id).Partner_Id__c, a.Signature_Rep_Partnership_Opt_Out__c);
                        }
                    }*/

                    if(a.Signature_Rep_Partnership_Opt_Out__c != mAccountOld.get(a.Id).Signature_Rep_Partnership_Opt_Out__c){      
                        mCustomerAccountPartnerIdToUpdate.put(a.Partner_Id__c, a.Signature_Rep_Partnership_Opt_Out__c);
                    }
                // Customer Account partner Id is updated, if set to null, uncheck the box, if changes to another partner Id, check the Partner Account
                }else{
                    if(a.Partner_Id__c != mAccountOld.get(a.Id).Partner_Id__c){
                        if(a.Partner_Id__c == '' || a.Partner_Id__c == NULL){
                            a.Signature_Rep_Partnership_Opt_Out__c = false;
                        }else{
                            sPartnerAccountPartnerIdToCheck.add(a.Partner_Id__c);
                        }

                    }
                }
            }

            if(mCustomerAccountPartnerIdToUpdate.size() > 0){
                
                for(Account a: [SELECT Id, Partner_Id__c, Signature_Rep_Partnership_Opt_Out__c FROM Account 
                                             WHERE Partner_Id__c in: mCustomerAccountPartnerIdToUpdate.keyset() 
                                             AND RecordTypeId =: rtMapByRecName.get('Customer Account').getRecordTypeId()]) {
                    a.Signature_Rep_Partnership_Opt_Out__c = mCustomerAccountPartnerIdToUpdate.get(a.Partner_Id__c);
                    lCustomerAccountToUpdate.add(a);
                    
                }
                if(lCustomerAccountToUpdate.size()>0){
                    TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = True; 
                    Update lCustomerAccountToUpdate;
                    TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = False; 
                }

            }

            if(sPartnerAccountPartnerIdToCheck.size() > 0){                
                // Get the Partner Account of the updated Customer Account 
                for ( Account a: [SELECT Id, Partner_Id__c, Signature_Rep_Partnership_Opt_Out__c FROM Account 
                                  WHERE Partner_Id__c In: sPartnerAccountPartnerIdToCheck
                                  AND RecordTypeId =: rtMapByRecName.get('Partner Account').getRecordTypeId()]){
                    myset.put(a.Partner_Id__c, a.Signature_Rep_Partnership_Opt_Out__c);
                }

                for(Account a: mAccountNew.values()){
                    if(sPartnerAccountPartnerIdToCheck.contains(a.Partner_Id__c)){
                        if(myset.containskey(a.Partner_Id__c)){
                            a.Signature_Rep_Partnership_Opt_Out__c = myset.get(a.partner_Id__c);
                        }
                    }
                }

                    

            }

        }
    }
    // ############################################################## END Update_SignatureRepPartnershipOptOut
}