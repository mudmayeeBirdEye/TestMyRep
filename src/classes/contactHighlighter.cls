/* #######################################################################################
Updates: 
  By: eugenebasianomutya
  Case: 03428105 - Unsubscribe message in lead/contact banner
  Date: 06192015
######################################################################################## */

public class contactHighlighter {
  public Boolean isBTApproved {get;set;}
  public Contact objContact {get;set;}
  static final String strBTBrand = 'BT';
  public list<String> tempList{get;set;}
  public Boolean bRedAccount {get;set;}

  public boolean isHasOptedOutOfEmail {get;set;}
  public String imgPath{get;set;}
  public String imgPathRed{get;set;}
  
  public contactHighlighter(ApexPages.StandardController controller){

    // Initializing variables
    ImgPath = '/resource/warning';
    ImgPathRed = '/resource/warningRed';
    tempList = new List<String>();
    tempList.add('test');

    bRedAccount = false;
    isBTApproved = false;
    isHasOptedOutOfEmail = false;

    List<Contact> lstContact= [SELECT Id, Account.RC_Brand__c, HasOptedOutOfEmail FROM Contact WHERE id= :ApexPages.currentPage().getParameters().get('id')];
    if(lstContact != null && lstContact.size() > 0){
      objContact = lstContact.get(0);
    }
    if(objContact != null){
      String rcBrand = objContact.Account.RC_Brand__c;
      if(String.isNotBlank(rcBrand) && rcBrand.trim().containsIgnoreCase(strBTBrand)){
        isBTApproved = true;
      }

      isHasOptedOutOfEmail = objContact.HasOptedOutOfEmail;
    }

  }
}