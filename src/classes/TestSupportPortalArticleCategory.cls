/**************************************************************************************************
* Project Name..........: BT Support Portal                                                       *
* File..................: TestSupportPortalArticleCategory.class                                  *
* Version...............: 1.0                                                                     *
* Created by............: Simplion Technologies                                                   *
* Created Date..........: 01/28/2015                                                              *
* Last Modified by......: Simplion Technologies                                                   *
* Last Modified Date....: 01/28/2015                                                              *
* Description...........: This is a test class for Support Portal Article Category class.         *
**************************************************************************************************/
@isTest
private class TestSupportPortalArticleCategory {
	
	
	/******************************************************************************
	* @Description : Method to setup test records.                                *
	* @Params      : void                                                         *
	* @Return      : void                                                         * 
	******************************************************************************/
	static void recordSetup(){
		// Insert RC Knowledge Article here!
	}
	/******************************************************************************
	* @Description : Method to test the schedulable class.                        *
	* @Params      : void                                                         *
	* @Return      : void                                                         * 
	******************************************************************************/
    static testMethod void testExecuteMethod() {
    	Test.StartTest();
			SupportPortalArticleCategory spac = new SupportPortalArticleCategory();
			String scheduleTime = '0 0 4 * * ?'; 
			system.schedule('Test Medallia Fetch Survey', scheduleTime, spac); 
		Test.stopTest();
    }
    
}