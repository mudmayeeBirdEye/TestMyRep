/**********************************************************************************************
Created By: eugenebasianomutya
Created Date: 07012015
Case: 03715619 - Customer List view
Description: A vfPage that displays the list of Customer Account of Partner Account
**********************************************************************************************/

public with sharing class PartnerCustomerSectionView{

    public list<WRPartnerCustomerInfo> lWRPartnerCustomerInfo {Get;Set;}
    public string strPId {Get;Set;}
    public string strID {Get;Set;}
    public Boolean isViewAll {Get;Set;}
    public Account acc;

    public PartnerCustomerSectionView (ApexPages.StandardController controller){
    
        try{
            isViewAll = false;
            String strViewAll=ApexPages.currentpage().getParameters().get('viewAll');
            if(strViewAll!=null && strViewAll!=''){
                isViewAll=true;
            }
               
            if(Controller.getId()!=Null){
            
                strId = Controller.getId();
                lWRPartnerCustomerInfo = new List<WRPartnerCustomerInfo>();
                
                String strPID = [SELECT Partner_ID__c 
                                 FROM Account 
                                 WHERE id=:Controller.getId()].Partner_ID__c; 
                
                if(strPID!=null && strPID!=''){
                
                    for(Account a : [SELECT Id, Name, RC_Account_Status__c, RC_Upgrade_Date__c, RC_Service_name__c, RC_Brand__c,RC_Tier__c,MRR__c, RC_User_ID__c, Is_Demo_Account__c 
                                     FROM Account 
                                     WHERE Partner_ID__c =: strPID and type='Customer']){
        
                        WRPartnerCustomerInfo myPCI = new WRPartnerCustomerInfo();
                        myPCI.AccountId = a.Id;
                        myPCI.AccountName = a.Name;
                        myPCI.UserId = a.RC_User_ID__c;
                        myPCI.RCAccountStatus = a.RC_Account_Status__c; 
                        myPCI.PaidDate = a.RC_Upgrade_Date__c;
                        myPCI.Brandname = a.RC_Brand__c; 
                        myPCI.Service = a.RC_Service_name__c; 
                        myPCI.Tier = a.RC_Tier__c;
                        myPCI.Mrr = a.MRR__c;
                        myPCI.IsDemoAccount = a.Is_Demo_Account__c;
                        lWRPartnerCustomerInfo.add(myPCI);
                    }
                }
            }               
        }catch(exception e){}
    }

    public class WRPartnerCustomerInfo{
        public id AccountId {Get;Set;}
        public string AccountName {Get;Set;}
        public string UserId {Get;Set;}
        public string RCAccountStatus {Get;Set;}
        public DateTime PaidDate {Get;Set;}
        public string Brandname {Get;Set;}
        public string Service {Get;Set;}
        public string Tier {Get;Set;}
        public decimal Mrr {Get;Set;}
        public boolean IsDemoAccount {Get;Set;}
    
    }
}