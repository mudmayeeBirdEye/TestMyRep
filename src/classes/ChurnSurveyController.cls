/**************************************************************************************************
 * Project Name..........: RingCentral                                                            *
 * File..................: ChurnSurveyController                                                  *
 * Version...............: 1.0                                                                    *
 * Created by............: Simplion Technologies                                                  *
 * Created Date..........: 23-12-2014                                                             *
 * Last Modified by......: Simplion Technologies                                                  *
 * Last Modified Date....: 23-12-2014                                                             *
 * Description...........: This class will serve the need for Churn Survey Form                   *  
 *                                                                                                *
 **************************************************************************************************/
public class ChurnSurveyController {
    /*********************** VARIABLE DECLARATION *********************/
    public boolean toShowPanel {get;set;}
    public Survey__c surveyObj {get;set;}
    public string OtherCancellationReason {get;set;}
    //public string Comment {get;set;}                            
   // public list<string> Question2seletedOptions{get;set;}                       
    
    /* 
     * Cuntructor for initialisation of variables.
     * Check the and assign Survey if any exist, based on param Id.
     */
    public ChurnSurveyController() {
       try {
        //	Question2seletedOptions = new list<string>();
            toShowPanel = true; 
            surveyObj = new Survey__c();
            String surveyId = ApexPages.currentPage().getParameters().get('id');
            if(String.isNotBlank(surveyId)) {
                surveyObj = [SELECT Id,Comments__c, Name, SurveyType__c, Responded__c, Response_Date__c, CreatedDate,Couldn_t_get_it_working__c,
                					Cancellation_Influence__c, Other_Cancellation_Reason__c,Missing_Features__c,User_Interface__c,Voice_Quality_Issues__c,
                					Problems_with_Customer_Service__c,Business_Closed__c,NoLongerNeededForCompany__c,Cost__c,Just_Testing_Out_Service__c,
                					HappyWithService_LeftForOtherReasons__c,Other_please_specify__c, 
                                Account__r.Number_of_DL_s__c,Account__r.RC_Service_name__c FROM Survey__c 
                				WHERE id=:surveyId limit 1];
                if(surveyObj != null && surveyObj.SurveyType__c.equalsIgnoreCase('Churn Feedback Survey')) {
                        //setResponseValue();
                        if(checkSurveyAlreadyFilled()) {
                            toShowPanel = false;
                        }   
                } else {
                    toShowPanel = false;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Invalid Survey Type.'));
                }
                
            } else {
                toShowPanel = false;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Invalid Survey Id.'));
            }
            Apexpages.currentPage().getHeaders().put('X-UA-Compatible', 'IE=10'); 
        } catch(Exception ex) {
        	 system.debug('ex========>'+ex.getMessage());
            toShowPanel = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Invalid Survey.'));
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,ex.getMessage()+ex.getLineNumber()));
        }
    }
    
    /* This method is used for checking the survey status.
     * If already filled then return true otherwise return false.
     * @return boolean.
     */
    public boolean checkSurveyAlreadyFilled() {
        try {
            if(surveyObj.Responded__c == 1) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,'<b>You have already filled this survey.</b>'));
                return true;
            }
        } catch(Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Exception Occured.' + ex.getMessage()+ ' -->' +ex.getLineNumber()));
             system.debug('ex========>'+ex.getMessage());
        }
        return false;
    }
    
    
   /* This method is used for saving the survey responsed value.
    * @return pagereference
    */
	public PageReference save() {
   		try {
        	   surveyObj.Responded__c = 1;
				surveyObj.Response_Date__c = System.today();
				update surveyObj;
				toShowPanel = false;
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info,'<b>Thank you for filling out our survey.</b>'));
				return ApexPages.currentPage();
        	} catch(Exception ex) {
            	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Exception Occured.' + ex.getMessage()+ ' -->' +ex.getLineNumber()));
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,ex.getMessage()+ex.getLineNumber())); 
        }
       return null;
	}

}