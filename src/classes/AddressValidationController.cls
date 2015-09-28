public class AddressValidationController{/*
    public String strOppId{get;set;}
    public List<AddressDetail> lstAddressDetail{get;set;}
    public String strAddressId{get;set;}
    public String strAddress{get;set;}
    public Boolean isJURISDICTIONFound{get;set;}
    public Boolean isAddressEmpty{get;set;}
    public String strSelectedID{get;set;}
    public Opportunity objOPP{get;set;}
    public String JCode {get;set;}
    public String titleBarMessage {get;set;}
    public boolean ZipFound {get;set;}
    public String currentCallSource{get;set;}
    
    // Constructor
    public AddressValidationController(ApexPages.StandardController controller) {
        strOppId=ApexPages.currentPage().getParameters().get('id');
        currentCallSource=ApexPages.currentPage().getParameters().get('currentCallSource');
        lstAddressDetail=new List<AddressDetail>();
    }
        
    public AddressValidationController(){
        lstAddressDetail=new List<AddressDetail>();
        strAddressId='1';
        
        lstAddressDetail.add(new AddressDetail('India','1'));
        lstAddressDetail.add(new AddressDetail('USA','2'));
    }
    
    public pagereference skip(){
      if(currentCallSource == 'ViewTax'){
          return new pagereference('/apex/ViewTaxDetails?id='+ApexPages.currentPage().getParameters().get('QuoteId')+'&skipped=true');
        }else {
          return new pagereference('/apex/zqu__QuoteOption?id='+ApexPages.currentPage().getParameters().get('id'));
        }
    }
    public pagereference ValidateAccountAddress(){
        strSelectedID='';
        isJURISDICTIONFound=true;
        if(strOppId!=''){
          objOPP=[Select JURISDICTION__c,Account.BillingCity, Account.BillingCountry, Account.BillingState, Account.BillingStreet, Account.BillingPostalCode 
                          from Opportunity where id=:strOppId];
          if(objOPP.Account.BillingPostalCode == '' || objOPP.Account.BillingPostalCode == NULL){
              ZipFound = false ;
              titleBarMessage = 'ZIP on Account Billing Address Is Blank';
              return null;
          }else{
              ZipFound = true;    
          }
          isAddressEmpty=false;
          if((objOPP.Account.BillingCity==null || objOPP.Account.BillingCity=='') && (objOPP.Account.BillingCountry==null || objOPP.Account.BillingCountry == '')&&
             (objOPP.Account.BillingState==null || objOPP.Account.BillingState== '')&& (objOPP.Account.BillingStreet==null || objOPP.Account.BillingStreet== '')&&
              (objOPP.Account.BillingPostalCode==null || objOPP.Account.BillingPostalCode == '')){
              isAddressEmpty=true;
              titleBarMessage = 'Account Address Is Blank';
              return null;
          }
          
          lstAddressDetail=getAddressDetail(objOPP);
          
          if(lstAddressDetail.size()==0){
              isJURISDICTIONFound=false;
              titleBarMessage = 'Jurisdiction ID Not Found';
              strAddress=getAddress(objOPP.Account.BillingCountry,objOPP.Account.BillingCity,objOPP.Account.BillingState,objOPP.Account.BillingStreet,objOPP.Account.BillingPostalCode);
              return null;
          }
          if(lstAddressDetail.size()>1){
              if(objOPP.Account.BillingPostalCode != NULL && objOPP.Account.BillingPostalCode != ''){
                  titleBarMessage = 'Multiple Addresses Found for ZIP : '+objOPP.Account.BillingPostalCode;
              }else {
                  titleBarMessage = 'Multiple Addresses Found';
              }
              
              return null;
          }
          updateJURISDICTIONId(objOPP,lstAddressDetail.get(0).strAddressId);
          system.debug('@@@@5454545454'+lstAddressDetail.get(0).strAddressId);
        }
        try{
          if(currentCallSource == 'ViewTax'){
            PageReference retnPage = null;
            if(ApexPages.currentPage().getParameters().get('secondCall') == 'true'){
              retnPage = updateZQuote('true');
            }else{
              retnPage = updateZQuote('false');
            }
            return retnPage;
          }else {
            return new pagereference('/apex/zqu__QuoteOption?id='+ApexPages.currentPage().getParameters().get('id'));
          }
        }catch(Exception e ){
          return null;
        }
    }
    
    public pagereference CreateQuote(){
        try{
          if(currentCallSource != 'ViewTax'){
            updateJURISDICTIONId(objOPP,strSelectedID);
          }
          if(currentCallSource == 'ViewTax'){
            PageReference retnPage = null;
            if(ApexPages.currentPage().getParameters().get('secondCall') == 'true'){
              retnPage = updateZQuote('true');
            }else{
              retnPage = updateZQuote('false');
            }
            return retnPage;
          }else {
            return new pagereference('/apex/zqu__QuoteOption?id='+ApexPages.currentPage().getParameters().get('id'));
          }
        }catch(Exception e ){
          return null;
        }
        
    }
    
    public pagereference updateZQuote(string secondCall) {
      try {
        zqu__Quote__c zquoteTemp = [select id, Account_Zip_Code__c,tax_jurisdiction__c from zqu__Quote__c where id =:ApexPages.currentPage().getParameters().get('QuoteId') limit 1 ];
        zqu__Quote__c zquote = new zqu__Quote__c(id=ApexPages.currentPage().getParameters().get('QuoteId'));
        string oldZip = zquoteTemp.Account_Zip_Code__c ;
        string oldJurisdiction = '';
        if(zquoteTemp.tax_jurisdiction__c == null || zquoteTemp.tax_jurisdiction__c == ''){
          oldJurisdiction = 'empty';
        }else{
          oldJurisdiction = zquoteTemp.tax_jurisdiction__c;
        }
        
        zquote.Run_Time_Zip__c = objOPP.Account.BillingPostalCode;
        if(lstAddressDetail.size()>0){
	    		zquote.Run_Time_Jurisdiction__c = lstAddressDetail.get(0).strAddressId;
	    	}else{
	    		zquote.Run_Time_Jurisdiction__c = '';
	    	}
        update zquote;
        if(secondCall == 'true'){
          return new pagereference('/apex/ViewTaxDetails?id='+ApexPages.currentPage().getParameters().get('QuoteId')+'&oldZip='+oldZip+'&oldJurisdiction='+oldJurisdiction+'&secondCall=true');
        }else{
          return new pagereference('/apex/ViewTaxDetails?id='+ApexPages.currentPage().getParameters().get('QuoteId')+'&oldZip='+oldZip+'&oldJurisdiction='+oldJurisdiction);
        }    
      } catch(Exception ex) {}
      return null;
    }
    
    public void updateJURISDICTIONId(Opportunity objOPP,String strJURISDICTIONId){
        try{
          objOPP.JURISDICTION__c=strJURISDICTIONId;
          objOPP.Account_Zip_Code__c=objOPP.Account.BillingPostalCode;
          upsert objOPP;
        }catch(Exception e){}    
    }
    public string matchAddress(String ZuoraAddress){
        String accAddress = objOPP.Account.BillingCity + '' + objOPP.Account.BillingStreet;
        List<String> accAddress2 = accAddress.splitByCharacterTypeCamelCase();
        if((objOPP.Account.BillingCity != '' && objOPP.Account.BillingCity != NULL && string.valueOf(ZuoraAddress).containsIgnoreCase(objOPP.Account.BillingCity)) ||
            (objOPP.Account.BillingStreet != '' && objOPP.Account.BillingStreet != NULL && string.valueOf(ZuoraAddress).containsIgnoreCase(objOPP.Account.BillingStreet))){
            return 'exactMatch';
        }else{
            for(String s : accAddress2){
                if(s != '' && s.length()>2){
                    if(ZuoraAddress.containsIgnoreCase(s)){
                        return 'partialMatch';
                    }
                }
            }
        }
        return 'noMatch';
    }
       
    public List<AddressDetail> getAddressDetail(Opportunity objOPP){
        JCode = '';
        List<AddressDetail> lstAddress=new List<AddressDetail>();
        string oppZipCode = objOPP.Account.BillingPostalCode;
        string oppCity = objOPP.Account.BillingCity+'%';
        string oppStreet = '%'+objOPP.Account.BillingStreet+'%';
        string AccountZipCode = objOPP.Account.BillingPostalCode;
        string AccountCity = objOPP.Account.BillingCity == null?'':objOPP.Account.BillingCity;
        string AccountStreet = objOPP.Account.BillingStreet == null?'':objOPP.Account.BillingStreet;
        List<Zuora_Address__c> zuoraAddressList = new List<Zuora_Address__c>();
        zuoraAddressList = [Select Id,City_Locality__c,Locality__c,Jcode__c,P_Code__c,Zip_Code__c from Zuora_Address__c where 
                                    (Zip_Code__c != null AND Zip_Code__c =:oppZipCode )];
        if(zuoraAddressList.size()>0){ 
            ZipFound = True;
            if(zuoraAddressList.size() == 1){
                JCode = zuoraAddressList[0].Jcode__c;
                updateJURISDICTIONId(objOPP,JCode);
                lstAddress.add(new AddressDetail(zuoraAddressList[0].City_Locality__c + ' - ' + zuoraAddressList[0].Zip_Code__c,zuoraAddressList[0].Jcode__c));
            }else{
                string accountAddString = getAddress(objOPP.Account.BillingCountry,objOPP.Account.BillingCity,objOPP.Account.BillingState,objOPP.Account.BillingStreet,objOPP.Account.BillingPostalCode);
                integer exactMatchLength = 0; 
                for(Zuora_Address__c zAdd : zuoraAddressList ){
                    string matchResult = '';
                    if(zAdd.City_Locality__c != NULL){
                        matchResult = matchAddress(zAdd.City_Locality__c);
                        if(matchResult == 'exactMatch'){
                            exactMatchLength = string.valueOf(zAdd.City_Locality__c).length();
                            lstAddress.add(new AddressDetail(zAdd.City_Locality__c + ' - ' + zAdd.Zip_Code__c ,zAdd.Jcode__c));
                        }else if(matchResult == 'partialMatch'){
                            if(string.valueOf(zAdd.City_Locality__c).length() > exactMatchLength){
                                exactMatchLength = string.valueOf(zAdd.City_Locality__c).length();
                                lstAddress.add(new AddressDetail(zAdd.City_Locality__c + ' - ' + zAdd.Zip_Code__c ,zAdd.Jcode__c));
                            }    
                        }
                    }
                }
                if(lstAddress.size()>0){
                    return lstAddress;
                }else{
                  integer i=0;
                    for(Zuora_Address__c zAdd : zuoraAddressList ){
                      if(i<=10){
                        i++;
                          lstAddress.add(new AddressDetail(zAdd.City_Locality__c + ' - ' + zAdd.Zip_Code__c ,zAdd.Jcode__c));  
                      }else{
                        break;
                      }
                    }
                }
            }
        }else{
            isJURISDICTIONFound=false;                      
        }
        return lstAddress;  
    }
    
    public String getAddress(String strCountry,String strCity,String strState,String strStreet,String strPostalCode){
        if(strCountry == null ){strCountry = '';}
        if(strCity == null ){strCity = '';}
        if(strState== null ){strState= '';}
        if(strStreet== null ){strStreet= '';}
        if(strPostalCode== null ){strPostalCode= '';}
        return 'Country = '+strCountry+','+'State= '+strState+','+'City= '+strCity+','+'Postal Code = '+strPostalCode;
    }
    
    public class AddressDetail{
        public String strAddressDetail{get;set;}
        public String strAddressId{get;set;}
        public Boolean isSelected{get;set;}
        
        public AddressDetail(String strAddressDetail,String strAddressId){
            this.strAddressDetail=strAddressDetail;
            this.strAddressId=strAddressId;
        }
    }*/
}