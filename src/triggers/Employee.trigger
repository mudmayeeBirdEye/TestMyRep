trigger Employee on Employee__c (before insert,before update)
{
    if(trigger.isInsert) {
         Employee__c[] accs = Trigger.new;
         Set<String> userIds = new Set<String>();
         for(Employee__c emp:accs) {
            if(emp.User__c != null ) {
                userIds.add(emp.User__c);
            }
         }
         Map<Id,User> userMap = null;
         if(userIds.size() != 0) {
            userMap = new Map<Id, User>([select id,Department,Division,Team__c from User where id IN:userIds ]);
         }
         List<User> preparedUserList = new List<User>();
         for(Employee__c emp:accs) { 
             if(emp.User__c != null ) {
                 User user= userMap.get(emp.User__c);
                 if(user != null) {
                     user.Department=emp.Department__c;
                     user.Division=emp.Division__c;   
                     user.Team__c =emp.Team__c; 
                     user.EmployeeNumber =  emp.Name;
                     user.Employee_Location__c = emp.Location__c;  
                     user.Upmarket_Territory__c = emp.Territory__c;
                     preparedUserList.add(user);
                 }
            }
        }
        if(preparedUserList.size() != 0)
            update preparedUserList;
    } 
    if(trigger.isUpdate){
      Employee__c[] accs = Trigger.new;
         Set<String> userIds = new Set<String>();
         for(Employee__c emp:accs) {
            if(emp.User__c != null ) {
                userIds.add(emp.User__c);
            }
         }
         Map<Id,User> userMap = null;
         if(userIds.size() != 0) {
            userMap = new Map<Id, User>([select id,Department,Division,Team__c from User where id IN:userIds ]);
         }
         List<User> preparedUserList = new List<User>();
         for(Employee__c emp:accs) { 
             if(emp.User__c != null ) {
                 User user= userMap.get(emp.User__c);
                 if(user != null) {
                     user.Department=emp.Department__c;
                     user.Division=emp.Division__c;   
                     user.Team__c =emp.Team__c;  
                     user.EmployeeNumber =  emp.Name;
                     user.Employee_Location__c = emp.Location__c; 
                     user.Upmarket_Territory__c = emp.Territory__c;
                     preparedUserList.add(user);
                 }
            }
        }
        if(preparedUserList.size() != 0)
            update preparedUserList;
    } 
 }