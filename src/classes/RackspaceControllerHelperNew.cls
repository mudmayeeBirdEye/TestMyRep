public class RackspaceControllerHelperNew{
    
     private static String User_Agent='Rackspace Management Interface';
     private static String strResponse='{"distributionlists":[{"displayName":"TestUnmanagedDLUN","name":"testunmanageddlUN"},{"displayName":"UnmanagedDLUN","name":"unmanageddlUN"}],"offset":0,"size":250,"total":2}';
     private static String strResponse2='{"displayName":"UnmanagedDLUN","emailAddressList":[{"address":"unmanageddl@test.ringcentral.com","replyTo":true},{"address":"wilson@test.ringcentral.com","replyTo":false},{"address":"test23@test.ringcentral.com","replyTo":false},{"address":"wilsontest2@test.ringcentral.com","replyTo":false}],"isHidden":false,"memberList":["kanishktest@test.ringcentral.com"],"name":"unmanageddl"}';
     private Static String strContactResponse='{"contacts":[{"displayName":"Anuj Shukla","externalEmail":"anhuj.shukla@gmail.com","name":"anuj"}],"offset":0,"size":250,"total":7}';
 /*public static String Login(String strAccountNumberNew,String strDomain,String strSignature){
   
    String url=getDistributionListEndPointURL(strAccountNumberNew,strDomain);
    Http http = new Http();
    HttpRequest req = new HttpRequest();
    req.setEndpoint(url);
    req.setMethod('GET');
    req.setHeader('User-Agent',User_Agent);
    req.setHeader('X-Api-Signature',strSignature);
    req.setHeader('Accept', 'application/json');
    HTTPResponse res = http.send(req);
    String response= res.getBody();
    
      if (res.getStatusCode() >= 400) {
              Map<String,Object> objJson = (Map<String, Object>)JSON.deserializeUntyped(response);
              if(objJson.get('unauthorizedFault')!=null){
                 Map<String, Object> mapMessage= (Map<String, Object>)objJson.get('unauthorizedFault');
                    throw new RackspaceException (''+mapMessage.get('message'));
                }
            throw new RackspaceException ('Received '+res.getStatusCode()+' from '+url+'\n'+response);
        }
   return response;
 }
 */
 
 public static String getAllDistributionList(String strAccountNumberNew,String strDomain,String strSignature){
   
    String url=getDistributionListEndPointURL(strAccountNumberNew,strDomain);
    Http http = new Http();
    HttpRequest req = new HttpRequest();
    req.setEndpoint(url);
    req.setMethod('GET');
    req.setHeader('User-Agent',User_Agent);
    req.setHeader('X-Api-Signature',strSignature);
    req.setHeader('Accept', 'application/json');
    HTTPResponse res =new HTTPResponse();
    String response='';
    if(!Test.isRunningTest()){
      res = http.send(req);
      response= res.getBody();
   }else{
     response=strResponse;
   }
      if (res.getStatusCode() >= 400) {
              Map<String,Object> objJson = (Map<String, Object>)JSON.deserializeUntyped(response);
              if(objJson.get('unauthorizedFault')!=null){
                 Map<String, Object> mapMessage= (Map<String, Object>)objJson.get('unauthorizedFault');
                    throw new RackspaceException (''+mapMessage.get('message'));
                }
            throw new RackspaceException ('Received '+res.getStatusCode()+' from '+url+'\n'+response);
        }
   return response;
    
 }
 
 
  public static String getDistributionListDetail(String strDLName,String strAccountNo,String strDomainName,String strSignature){
    
    String url=getDistributionListDetailEndPointURL(strDLName,strAccountNo,strDomainName);
    Http http = new Http();
    HttpRequest req = new HttpRequest();
    req.setEndpoint(url);
    req.setMethod('GET');
    req.setHeader('User-Agent',User_Agent);
    req.setHeader('X-Api-Signature',strSignature);
    req.setHeader('Accept', 'application/json');
    
    HTTPResponse res =new HTTPResponse();
    String response='';
    if(!Test.isRunningTest()){
      res = http.send(req);
      response= res.getBody();
   }else{
     response=strResponse2;
   }
     
     if (res.getStatusCode() >= 400) {
            throw new RackspaceException ('Received '+res.getStatusCode()+' from '+url+'\n'+response);
        }
   return response;
    
 }
 public static String getContactList(String strName,String strAccountNo,String strDomainName,String strSignature){
    
    String url=getDistributionListConatctEndPointURL(strName,strAccountNo,strDomainName);
    Http http = new Http();
    HttpRequest req = new HttpRequest();
    req.setEndpoint(url);
    req.setMethod('GET');
    req.setHeader('User-Agent',User_Agent);
    req.setHeader('X-Api-Signature',strSignature);
    req.setHeader('Accept', 'application/json');
    
    HTTPResponse res =new HTTPResponse();
    String response='';
    if(!Test.isRunningTest()){
      res = http.send(req);
      response= res.getBody();
   }else{
     response=strContactResponse;
   }
  
     if (res.getStatusCode() >= 400) {
            throw new RackspaceException ('Received '+res.getStatusCode()+' from '+url+'\n'+response);
        }
   return response;
    
 }
 
 /* public static String addMemberToDLList(String strDLName,String strEmail,String strAccountNo,String strDomainName,String strSignature){
    
    String url=getAddMemberToDLListEndPointURL(strDLName,strEmail,strAccountNo,strDomainName);
    Http http = new Http();
    HttpRequest req = new HttpRequest();
    //request.ContentLenght = 0;
    req.setEndpoint(url);
    req.setMethod('POST');
    req.setHeader('User-Agent',User_Agent);
    req.setHeader('X-Api-Signature',strSignature);
    //req.setHeader('Accept', 'text/xml');
     req.setHeader('Accept', 'application/json');
     req.setHeader('Content-Type', 'text/xml');
      req.setHeader('content-length', '0');
  
   HTTPResponse res =new HTTPResponse();
    String response='';
    if(!Test.isRunningTest()){
      res = http.send(req);
      response= res.getBody();
   }else{
     response=strResponse;
   }
      ApexPages.addMessage(new ApexPages.Message(ApexPages.SEVERITY.ERROR,response));
     if (res.getStatusCode() >= 400) {
              Map<String,Object> objJson = (Map<String, Object>)JSON.deserializeUntyped(response);
              if(objJson.get('badRequestFault')!=null){
                 Map<String, Object> mapMessage= (Map<String, Object>)objJson.get('badRequestFault');
                    throw new RackspaceException (''+mapMessage.get('message'));
                }
            throw new RackspaceException ('Received '+res.getStatusCode()+' from '+url+'\n'+response);
        }
   return response;
    
 }*/
 public static String addMemberToDLList2(String strDLName,String strName,String strAccountNo,String strDomainName,String strSignature){
    
    String url=getAddMemberToDLListEndPointURL2(strDLName,strName,strAccountNo,strDomainName);
    Http http = new Http();
    HttpRequest req = new HttpRequest();
    //request.ContentLenght = 0;
    req.setEndpoint(url);
    req.setMethod('POST');
    req.setHeader('User-Agent',User_Agent);
    req.setHeader('X-Api-Signature',strSignature);
    //req.setHeader('Accept', 'text/xml');
     req.setHeader('Accept', 'application/json');
     req.setHeader('Content-Type', 'text/xml');
      req.setHeader('content-length', '0');
   HTTPResponse res =new HTTPResponse();
    String response='';
    if(!Test.isRunningTest()){
      res = http.send(req);
      response= res.getBody();
   }else{
     response=strResponse;
   }
    
     if (res.getStatusCode() >= 400) {
              Map<String,Object> objJson = (Map<String, Object>)JSON.deserializeUntyped(response);
              if(objJson.get('badRequestFault')!=null){
                 Map<String, Object> mapMessage= (Map<String, Object>)objJson.get('badRequestFault');
                    throw new RackspaceException (''+mapMessage.get('message'));
                }else if(objJson.get('itemNotFoundFault')!=null){
                     Map<String, Object> mapMessage= (Map<String, Object>)objJson.get('itemNotFoundFault');
                    throw new RackspaceException (''+mapMessage.get('message'));
                }else if(objJson.get('validationFault')!=null){
                     Map<String, Object> mapMessage= (Map<String, Object>)objJson.get('validationFault');
                    throw new RackspaceException (''+mapMessage.get('message'));
                }
            throw new RackspaceException ('Received '+res.getStatusCode()+' from '+url+'\n'+response);
        }
   return response;
    
 }
 
 
 
 public static String removeFromDLEmailAddressList(String strDLName,String strEmail,String strAccountNo,String strDomainName,String strSignature){
    
    String url=getRemoveMemberToDLListEndPointURL(strDLName,strEmail,strAccountNo,strDomainName);
    Http http = new Http();
    HttpRequest req = new HttpRequest();
    //request.ContentLenght = 0;
    req.setEndpoint(url);
    req.setMethod('DELETE');
    req.setHeader('User-Agent',User_Agent);
    req.setHeader('X-Api-Signature',strSignature);
    //req.setHeader('Accept', 'text/xml');
     req.setHeader('Content-Type', 'text/xml');
      req.setHeader('content-length', '0');
  
    HTTPResponse res =new HTTPResponse();
    String response='';
    if(!Test.isRunningTest()){
      res = http.send(req);
      response= res.getBody();
   }else{
     response=strResponse;
   }
    
     if (res.getStatusCode() >= 400) {
            throw new RackspaceException ('Received '+res.getStatusCode()+' from '+url+'\n'+response);
        }
   return response;
    
 }
 /* public static String getAddMemberToDLListEndPointURL2(String strDLName,String strName,String strAccountNo,String strDomainName){
   return ('https://api.emailsrvr.com/v0/customers/'+strAccountNo+'/domains/'+strDomainName+'/ex/distributionlists/'+strDLName+'/members/'+strName+'');
 }*/
 
 public static String getAddMemberToDLListEndPointURL2(String strDLName,String strName,String strAccountNo,String strDomainName){
   return ('https://api.emailsrvr.com/v0/customers/'+strAccountNo+'/domains/'+strDomainName+'/ex/distributionlists/'+strDLName+'/members/'+strName+'');
 }
 public static String getDistributionListConatctEndPointURL(String strName,String strAccountNo,String strDomainName){
       if(strName!=null && strName!=''){
          return ('https://api.emailsrvr.com/v0/customers/'+strAccountNo+'/domains/'+strDomainName+'/ex/contacts?size=1000&contains='+strName);
        }
   return ('https://api.emailsrvr.com/v0/customers/'+strAccountNo+'/domains/'+strDomainName+'/ex/contacts?size=1000');
 }
 public static String getDistributionListEndPointURL(String strAccountNumberNew,String strDomain){
   //return ('https://api.emailsrvr.com/v0/customers/'+strAccountNumberNew+'/domains/'+strDomain+'/ex/distributionlists?size=1000&contains=Unmanaged');
   return ('https://api.emailsrvr.com/v0/customers/'+strAccountNumberNew+'/domains/'+strDomain+'/ex/distributionlists?size=1000&contains=UN');
 }
 
 public static String getDistributionListDetailEndPointURL(String strDLName,String strAccountNo,String strDomainName){
   return ('https://api.emailsrvr.com/v0/customers/'+strAccountNo+'/domains/'+strDomainName+'/ex/distributionlists/'+strDLName);
 }
 /*public static String getAddMemberToDLListEndPointURL(String strDLName,String strEmail,String strAccountNo,String strDomainName){
   return ('https://api.emailsrvr.com/v0/customers/'+strAccountNo+'/domains/'+strDomainName+'/ex/distributionlists/'+strDLName+'/emailaddresses/'+strEmail+'');
 }*/
 public static String getRemoveMemberToDLListEndPointURL(String strDLName,String strEmail,String strAccountNo,String strDomainName){
  // return ('https://api.emailsrvr.com/v0/customers/'+strAccountNo+'/domains/'+strDomainName+'/ex/distributionlists/'+strDLName+'/emailaddresses/'+strEmail+'');
 
 return ('https://api.emailsrvr.com/v0/customers/'+strAccountNo+'/domains/'+strDomainName+'/ex/distributionlists/'+strDLName+'/members/'+strEmail+'');
 }


}