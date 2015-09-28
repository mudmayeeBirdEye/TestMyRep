/**************************************************************************************************
 * Project Name..........: RingCentral                                                            *
 * File..................: ChurnSurveyScheduler                                                   *
 * Version...............: 1.0                                                                    *
 * Created by............: Simplion Technologies                                                  *
 * Created Date..........: 23-12-2014                                                             *
 * Last Modified by......: Simplion Technologies                                                  *
 * Last Modified Date....: 23-12-2014                                                             *
 * Description...........: This class will serve the need for calling the Churn Survey Batch      *  
 *                                                                                                *
 **************************************************************************************************/
global class ChurnSurveyScheduler implements Schedulable {
    global void execute(SchedulableContext ctx) {
        ChurnSurveyBatch churnSurveyBatch = new ChurnSurveyBatch(); 
        Database.executeBatch(churnSurveyBatch,100);
    }
}