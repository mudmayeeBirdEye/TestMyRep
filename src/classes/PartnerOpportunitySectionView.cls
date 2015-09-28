/******************************************************************************************************************************************************
UPDATE: 

   Case: 03808003 - Parent Account on Opp List View
   Case Desc:  Please replace the column with the Partner Account Name that is on the Opp record
   Update by: eugenebasianomutya
   Update date: 08012015
   Update made: Remove Partner Account and add Partner Account Name

******************************************************************************************************************************************************/



public with Sharing class PartnerOpportunitySectionView {
    public List<WRPartnerOpportunityInfo> listWrPartnerOpportunityInfo {get;set;}
    public List<Account> childPartnerAccountList{get;set;}   
    private set<string> partnerIDSet;
    map<string,Account> mapPartnerIdToAccount;
    Account accObj;
    public String strId {get;set;}
    public List<WRPartnerOpportunityInfo> lstWrPartnerOpportunityInfo;
   public Boolean isViewAll{get;set;}
   
    public PartnerOpportunitySectionView(ApexPages.StandardController Controller) {
        try {
            isViewAll=false;
            String strViewAll=ApexPages.currentpage().getParameters().get('viewAll');
            if(strViewAll!=null && strViewAll!=''){
                isViewAll=true;
            }
            strId= Controller.getId();
            //string Controller.getId() = [select contact.AccountId from User where Id = :UserInfo.getUserId()].contact.AccountId;
            if(Controller.getId() != null) {
                listWrPartnerOpportunityInfo = new List<WRPartnerOpportunityInfo>();
                partnerIDSet = new set<string>();
                mapPartnerIdToAccount = new map<string,Account>();
                accObj = [select Name,Partner_Id__c,RecordType.Name from Account where ID = :Controller.getId() limit 1];
                //system.debug('$$$$$$$$$'+accObj); 
                //system.debug('^^^^^^^^^^'+accObj.RecordType.Name);                                 
                if(accObj != null && accObj.Partner_Id__c != null && accObj.RecordType.Name == 'Partner Account') {
                    partnerIDSet.add(accObj.Partner_Id__c);
                    mapPartnerIdToAccount.put(accObj.Partner_Id__c,accObj);
                    string strQuery = '%' + (Controller.getId().length()>15?Controller.getId().substring(0,15):Controller.getId())+ '%';
                    System.Debug('>>33>>'+strQuery);
                    List<Account> childPartnerAccountList = [SELECT id,Name,Parent_Detail__c,Number_of_DL_s__c,PartnerMrr__c,parentId,Partner_ID__c  
                                                            from Account where  RecordType.Name = 'Partner Account' and
                                                            ((parentId != null and Parent_Detail__c Like :strQuery )) order by Name ];
                    for(Account accObjchildPartner: childPartnerAccountList) {
                        if(accObjchildPartner.Partner_ID__c != null) {
                            partnerIDSet.add(accObjchildPartner.Partner_ID__c);
                            mapPartnerIdToAccount.put(accObjchildPartner.Partner_Id__c,accObjchildPartner);
                        }
                    }
                    system.Debug('>>11>>'+partnerIDSet);  
                    List<Opportunity> opportunityPartnerList = new List<Opportunity>();
                    
                    
                    // Case: 03808003 - Add Partner_Account_Name__c in the qry
                    if(!isViewAll){
                        opportunityPartnerList = [select id, Partner_ID__c,Owner.Name,Name,stageName,account.Name, Partner_Account_Name__c, LastModifiedDate, CreatedBy.Name, CloseDate, CreatedDate, Discovery_Next_Steps__c
                                                                from Opportunity where Partner_ID__c IN : partnerIDSet and 
                                                                RecordType.Name = 'VAR Opportunity' and CreatedDate >= LAST_N_DAYS:14 order  by Name ASC limit 10000];//CreatedDate >= LAST_N_DAYS:14 order
                    }else{
                        opportunityPartnerList = [select id, Partner_ID__c,Owner.Name,Name,stageName,account.Name, Partner_Account_Name__c, LastModifiedDate, CreatedBy.Name, CloseDate, CreatedDate, Discovery_Next_Steps__c from Opportunity 
                                                    where Partner_ID__c IN : partnerIDSet and RecordType.Name = 'VAR Opportunity' order by Name ASC limit 10000];
                        
                    }  
                    // Case: 03808003 - Add Partner_Account_Name__c in the qry
                    
                    
                    system.Debug('>>22>>'+opportunityPartnerList);
                    for(Opportunity partnerOppObj : opportunityPartnerList) {
                        WRPartnerOpportunityInfo wrPartnerOppInfoObj = new WRPartnerOpportunityInfo();
                        wrPartnerOppInfoObj.opportunityName =  partnerOppObj.Name;
                        wrPartnerOppInfoObj.stage =  partnerOppObj.stageName;
                        wrPartnerOppInfoObj.ownerName =  partnerOppObj.Owner.Name;
                        wrPartnerOppInfoObj.opportunityId =  partnerOppObj.id;
                        wrPartnerOppInfoObj.accountName = partnerOppObj.account.Name;
                        wrPartnerOppInfoObj.partnerAccount= partnerOppObj.account.Name;
                        
                        // Case: 03808003 - Add Partner_Account_Name__c
                        wrPartnerOppInfoObj.partnerAccountName= partnerOppObj.Partner_Account_Name__c;
                        // Case: 03808003 - Add Partner_Account_Name__c
                        
                        wrPartnerOppInfoObj.partnerId = partnerOppObj.Partner_ID__c;
                        wrPartnerOppInfoObj.createdBy =  partnerOppObj.CreatedBy.Name;
                        wrPartnerOppInfoObj.CloseDate = partnerOppObj.CloseDate;
                        wrPartnerOppInfoObj.OppNextStep = partnerOppObj.Discovery_Next_Steps__c;
                        wrPartnerOppInfoObj.createdDate = partnerOppObj.CreatedDate;
                        wrPartnerOppInfoObj.lastModifiedDate = partnerOppObj.LastModifiedDate;
                        wrPartnerOppInfoObj.createdate1 = (integer) partnerOppObj.CreatedDate.gettime();
                        wrPartnerOppInfoObj.lastModified = (integer) partnerOppObj.LastModifiedDate.gettime();
                        system.debug(wrPartnerOppInfoObj.createdDate+'>>>>123>>>'+ wrPartnerOppInfoObj.lastModifiedDate);
                        listWrPartnerOpportunityInfo.add(wrPartnerOppInfoObj);
                    }                                       
                }
            }   
        } catch(Exception ex) {}
       
    }
    
    public class WRPartnerOpportunityInfo {
        public string opportunityName {get;set;}
        public string opportunityId {get;set;}
        public string email {get;set;}
        public string phone {get;set;}
        public string companyName {get;set;}
        public string ownerName {get;set;}
        public string partnerAccount{get;set;}
        
        // Case: 03808003 - Add Partner_Account_Name__c
        public string partnerAccountName{get;set;}
        // Case: 03808003 - Add Partner_Account_Name__c
        
        public string accountName {get;set;}
        public string partnerId {get;set;}
        public string stage {get;set;}
        public string createdby {get;set;}
        public string OppNextStep {get;set;}
        public Datetime closeDate {get;set;}
        public Datetime createdDate {get;set;}
        public Datetime lastModifiedDate {get;set;}
        public Integer createdate1{get;set;}
        public Integer lastModified{get;set;}
        
        public WRPartnerOpportunityInfo() {
        }
    }
}