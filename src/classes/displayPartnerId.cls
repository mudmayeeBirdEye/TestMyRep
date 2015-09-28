public class displayPartnerId{
  public user currentuser{get;set;}
  public displayPartnerId(){
     currentuser=new User();
     currentuser=[Select Id, RCPartner_ID__c from User where Id=:userInfo.getUserId()];
  } 
}