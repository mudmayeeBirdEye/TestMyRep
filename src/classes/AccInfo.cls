/****************************************************************************************************************
Updated By: eugenebasianomutya
Update details: Case # 03523403 - highlight on the account when a "Customer Success Manager" is flagged on the account
                Case # 03531598 - Account Highlights for First Group Accounts                
                Case # 03650782 - Update Account Highlights
*****************************************************************************************************************/

public class AccInfo {
    //Test
    public String imgPath{get;set;}
    public String msg{get;set;}
    public String salsAgreeDate{get;set;}
    public List<String> tempList{get;set;}
    public Map<String,AccHighlighterWrapper> mapAccHighlighter;
    public String customerContactName {get;set;}
    public String RcExecutiveName {get;set;}  
    public Boolean isBTApproved {get;set;}
    static final String strBTBrand = 'BT';
   

       public Boolean warn1{get;set;}
       public Boolean warnHighlighter{get;set;}
       public Boolean warn2{get;set;}
       public Boolean warn3{get;set;} 
       public Boolean warn4{get;set;}
       public Boolean warn5{get;set;}       
       public Boolean warn6{get;set;}
       public Boolean warn7{get;set;}
       
       public Boolean isATT{get;set;}
       public Boolean isFirstGroupAcc{get;set;}
       
       public Boolean preSupportFlag{get;set;}
       public Boolean boolTrailAccountMsg {get;set;}
       public String  strPaidDate {get;set;}  
       public String strTAM {get; set;} 
       public String strTAMId {get; set;}
       
       public String strCSM {get;set;}
       public String strCSMId {get;set;}
       
       public Boolean refreshBool {get; set;}
       public Boolean bRedAccount {get;set;}
       public String strRedAccountId{get;set;}
       
       private Account acct ;
            
    public AccInfo(ApexPages.StandardController controller) {
        isBTApproved = false;
        warnHighlighter = false;
        mapAccHighlighter = new Map<String,AccHighlighterWrapper>();
        tempList = new List<String>();
        tempList.add('test');
        getDocument();
        this.acct = (Account)controller.getRecord();
        list<Account> lstAcc = [SELECT RC_User_ID__c, RC_Brand__c, name from Account WHERE Id =:acct.id limit 1];
        String accUserId;
        if(lstAcc !=null && lstAcc.size()>0){ 
            accUserId = lstAcc.get(0).RC_User_ID__c;
            String rcBrand = lstAcc.get(0).RC_Brand__c;
            if(String.isNotBlank(rcBrand) && rcBrand.trim().containsIgnoreCase(strBTBrand)){
                isBTApproved = true;
            }
            
            isATT = false;
            if(rcBrand != '' && rcBrand != null){
                if(rcBrand.toLowerCase().contains('at&t')){
                    isATT = true;
                }
            }
            
            // 03650782 - Start
            isFirstGroupAcc = false;
            string sAccName = lstAcc.get(0).Name;
            //if(lstAcc.get(0).Name == 'FIRST GROUP AMERICA'){
            if(sAccName.toLowerCase().contains('first group america')){
                isFirstGroupAcc = true;
            }
            // 03650782 - End
            
        }
        AccHighlighterWrapper currWrap = mapAccHighlighter.get(accUserId);
        if(currWrap != null){
            customerContactName = currWrap.custContactName;
            RcExecutiveName = currWrap.rcExecContactName;
            warnHighlighter = true;
        }
        boolTrailAccountMsg = false; 
        ImgPath = '/resource/warning';
        preSupportFlag = false;    
                         
        for(Quote quote_obj: [SELECT End_Date__c FROM Quote WHERE Account__c =:acct.id AND Status ='Active' LIMIT 1]){
            String dateStr = '';
            try { dateStr = '' + (quote_obj.End_Date__c == null ? '' : (''+quote_obj.End_Date__c));} catch(Exception e) {}
            //  msg = msg1 + '<b>'+ (dateStr == '' ? '' : dateStr.substring(0, dateStr.length() - 8)) +'</b>';
            salsAgreeDate = (dateStr == '' ? '' : dateStr.substring(0, dateStr.length() - 8));
            warn1 = true; 
        }
        for(Account acc: [SELECT id, Name, RC_Account_Status__c, RC_Service_name__c FROM Account WHERE Id = :acct.id]) {  
            //AND RC_Account_Status__c like :'Trial%' AND RC_Service_name__c like: '%Office%' LIMIT 1                                  
            if(!String.IsBlank(acc.RC_Account_Status__c) && !String.IsBlank(acc.RC_Service_name__c) 
                && acc.RC_Account_Status__c.containsIgnoreCase('Trial') 
                && acc.RC_Service_name__c.containsIgnoreCase('Office')) {
                warn4 = true ;  
            }
       }
       
       for(Account acc: [SELECT Account.RC_Attribution_Channel__c, Partner_Type__c , Premium_Support_Agent__c ,
                          RecordType.Name ,RC_SignUp_date__c,Partner_ID__c, MRR__c,RC_Account_Status__c,
                          (SELECT id,Status__c FROM Escalations__r where Status__c!='Resolved' and Status__c !='Yellow' order by 
                           LastModifiedDate desc limit 1) FROM Account WHERE Id =:acct.id LIMIT 1] ){    
                
            if(acc.Premium_Support_Agent__c != NULL) {
                preSupportFlag = true;
            }
                 
            try{
                if(acc.Escalations__r.size()>0){
                    bRedAccount=true;
                    strRedAccountId=acc.Escalations__r.get(0).id;
                }
            }catch(Exception e){}
                 
            if((acc.RC_Attribution_Channel__c!=null && acc.RC_Attribution_Channel__c.equalsIgnoreCase('Sales Agents & Resellers'))
                && acc.Partner_ID__c !=  null 
                && acc.RecordType.Name == 'Customer Account') {
                    warn2 = true;
            } 
            if(acc.RecordType.Name == 'Partner Account' && acc.Partner_Type__c != 'Franchisor') {
                warn2 = true;
            }
            if((acc.RC_Attribution_Channel__c!=null 
                && ( acc.RC_Attribution_Channel__c.equalsIgnoreCase('National Accounts') || acc.RC_Attribution_Channel__c.equalsIgnoreCase('Franchise & Assoc.')) )
                && (acc.RecordType.Name == 'Customer Account')
                && acc.Partner_ID__c !=  NULL) {
                    warn3 = true;
            }
            if(acc.RecordType.Name == 'Partner Account' && acc.Partner_Type__c == 'Franchisor' ){
                warn3 = true;
            }
            if(acc.MRR__c != null && acc.RC_Account_Status__c != null && acc.MRR__c == 0 && acc.RC_Account_Status__c.equalsIgnoreCase('Paid')) {
                if(acc.RC_SignUp_date__c  != null && String.valueOf(acc.RC_SignUp_date__c) != '') {
                    boolTrailAccountMsg = true;
                    Date paidDate = acc.RC_SignUp_date__c.Date() + 30;
                    strPaidDate = paidDate.format();
                } 
            }
        } 
    }
        
    public void getDocument(){
        String docName = 'Account_Highlighter';
        List<Document> doc = [SELECT body, Name, bodyLength, ContentType, Url FROM Document WHERE Name = :docName];
        if(doc != null && doc.size()>0){
            Blob b = doc[0].body;
            String content  = b.toString();
            List<List<String>> parsedCSV = new List<List<String>>();
        
            // Parse the CSV File
            parsedCSV =  parseCSV(content);
            if(parsedCSV != null && ! Test.isRunningTest()){
              parsedCSV.remove(0);
            }
            if(parsedCSV!=null){
                  for (List<String> line : parsedCSV){
                      if(line != null){
                        String accName = line.get(0);
                          String custContactName = line.get(1);
                          String rcExecContactName = line.get(2);
                          String userId = line.get(3);
                          mapAccHighlighter.put(userId,new AccHighlighterWrapper(accName,custContactName,rcExecContactName,userId));
                      }
                  }
            }
        }
    }
        
        public class AccHighlighterWrapper{
            public String accName;
            public String custContactName;
            public String rcExecContactName;
            public String userId;
      
            public AccHighlighterWrapper(String accName, String custContactName, String rcExecContactName, String userId){
                this.accName = accName;
                this.custContactName = custContactName;
                this.rcExecContactName = rcExecContactName;
                this.userId = userId;
            }
        }
        
        private List<List<String>> parseCSV(string contents) {
            List<List<String>> allFields = new List<List<String>>(); 
              try {
                    contents = contents.replaceAll(',"""',',"DBLQT').replaceall('""",','DBLQT",');
                    contents = contents.replaceAll('""','DBLQT');
                    List<String> lines = new List<String>();
                      lines = contents.split('\n'); 
                    Integer num = 0;
                    for(String line : lines) {
                        if (line.replaceAll(',','').trim().length() == 0) break;
                        List<String> fields = line.split(','); 
                        List<String> cleanFields = new List<String>();
                        String compositeField;
                        Boolean makeCompositeField = false;
                        for(String field : fields) {
                            if (field.startsWith('"') && field.endsWith('"')) {
                                cleanFields.add(field.replaceAll('DBLQT','"').trim());
                            } else if (field.startsWith('"')) {
                                makeCompositeField = true;
                                compositeField = field.trim();
                            } else if (field.endsWith('"')) {
                                compositeField += ',' + field.trim();
                                cleanFields.add(compositeField.replaceAll('DBLQT','"').trim());
                                makeCompositeField = false;
                            } else if (makeCompositeField) {
                                compositeField +=  ',' + field.trim();
                            } else {
                                cleanFields.add(field.replaceAll('DBLQT','"').trim());
                            }
                        }
                        allFields.add(cleanFields);
                    }  
              } catch(Exception ex) {}
              return allFields; 
        }
      
        /*********************************************************************************************
        *@Description............: Update the Technical Account Manager field on Account,           *
        *                          with the most recently modified Technical Account Manager-Primary*
        *Param...................: none                                                             *
        *@Return.................: pageReference                                                    *
        ********************************************************************************************/
    public PageReference PopulateATM(){  
        try{
            system.debug('### ' + acct);
            system.debug('======== TAM =========== '+ acct.Technical_Account_Manager__c + ', CONTACT= ' + acct.Most_Recent_Implementation_Contact__c);
            Id tAMOldValue = acct.Technical_Account_Manager__c;
            Id tAMNewValue = null;
            Id oldContactId = null;
            Id newContactId = null;
            Boolean isContactRoleUpdated = false;
            List<AccountContactRole> accConRoleList = new List<AccountContactRole>();
            try {
                accConRoleList = [SELECT Id, ContactId, Contact.Preferred_Language__c FROM AccountContactRole WHERE AccountId =: acct.Id AND IsPrimary=true];
            } catch(Exception ex) {}
        
            if(accConRoleList.size() > 0){
                AccountContactRole accConRoleObj = accConRoleList[0];
                if(accConRoleObj != null) {
                    // Contact con = new Contact(Id=accConRoleObj.ContactId, Preferred_Language__c=accConRoleObj.Contact.Preferred_Language__c);//[SELECT Id, Preferred_Language__c FROM Contact WHERE id =: accConRoleObj.ContactId limit 1];
                    oldContactId = acct.Most_Recent_Implementation_Contact__c;
                    newContactId = accConRoleObj.ContactId;
                    System.debug('### NEW Contact = ' + newContactId);
                    System.debug('### OLD Contact = ' + oldContactId);
                    if(acct.Most_Recent_Implementation_Contact__c != accConRoleObj.ContactId) {
                        isContactRoleUpdated = true;
                        acct.Most_Recent_Implementation_Contact__c =  accConRoleObj.ContactId;
                        acct.Preferred_Language__c = accConRoleObj.Contact.Preferred_Language__c;//con.Preferred_Language__c;
                    }
                }
            } 
                
            // 03650782 - Start
            warn7 = false;
            if(isATT && isFirstGroupAcc){
                warn7 = true;
            }
            // 03650782 - End
            
            // 03531598 - Start
            list<Contact> conList = [SELECT Id, Preferred_Language__c, Email FROM Contact 
                                     WHERE AccountId =: acct.Id ORDER BY LastModifiedDate DESC];
            if(isATT && !warn7){
                for(Contact conObj :conList) {
                    if(conObj.email.contains('@greyhound.com') || conObj.email.contains('@firstgroup.com')){
                        warn7 = true;
                    }
                }
            }
            
            
            if(accConRoleList.size() <= 0){                
                System.debug('conList--->'+conList);
                boolean isLastModied = true;

                if(conList != null && conList.size()>0){
                    if(acct.Most_Recent_Implementation_Contact__c != conList[0].Id) {
                        isContactRoleUpdated = true;
                        acct.Most_Recent_Implementation_Contact__c =  conList[0].Id;
                        acct.Preferred_Language__c = conList[0].Preferred_Language__c;
                        isLastModied = false;
                    }
                }
            }
            // 03531598 - End

            if(String.isBlank(String.valueOf(acct.Preferred_Language__c))){
                acct.Preferred_Language__c = 'en_US';
            }
           
            //Case # 03523403 - START
            list<string> sTeamRole = new list<string>();
            sTeamRole.add('Customer Success Manager (CSM)');
            sTeamRole.add('Technical Account Manager - Primary');
               
            system.debug('acct.Most_Recent_Implementation_Contact__c--->'+acct.Most_Recent_Implementation_Contact__c);
            boolean isTamUpdated = false;
            list<AccountTeamMember > latm= new list<AccountTeamMember>();
            latm = [SELECT TeamMemberRole, User.Name, UserId,LastModifiedDate FROM AccountTeamMember 
                    WHERE AccountId =: acct.Id 
                    AND TeamMemberRole IN: sTeamRole 
                    ORDER BY CreatedDate ASC];   
                             
            for(AccountTeamMember atm :latm ) {  
                if (warn5==false || warn5==null){ 
                    if(atm.TeamMemberRole != null && (atm.TeamMemberRole.containsIgnoreCase(sTeamRole[1]))){ 
                        warn5 = true;  
                        strTAM = atm.User.Name;
                        strTAMId = atm.UserId;
                        if(acct != null){
                            tAMNewValue = atm.UserId;
                        }
                    }
                }
                if (warn6==false || warn6==null){
                    if( atm.TeamMemberRole != null && (atm.TeamMemberRole.containsIgnoreCase(sTeamRole[0]))){                 
                        warn6 = true;  
                        strCSM = atm.User.Name;
                        strCSMId = atm.UserId;
                    }
                }
            }
            //Case # 03523403 - END
            if(tAMNewValue != tAMOldValue && acct.Id != null){
                acct.Technical_Account_Manager__c = tAMNewValue; 
                refreshBool = true;
                system.debug('####  New TAM = '+ acct.Technical_Account_Manager__c);
                TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
                TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();  
                isTamUpdated = true; 
                update acct;
            }  
            if(!isTamUpdated && isContactRoleUpdated) {
                refreshBool = true;
                system.debug('####  New TAM = '+ acct.Most_Recent_Implementation_Contact__c);
                TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
                TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();  
                update acct;
            }
        } catch(Exception ex) {
                system.debug('#### Exception at line = '+ex.getLineNumber()+' Message = '+ex.getMessage());
        }
        return null;
    }
}