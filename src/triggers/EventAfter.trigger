trigger EventAfter on Event (after insert, after update) {
     set<String> eventId = new set<String>();
        for(Event ev : trigger.new){
            system.debug('ev---------------->'+ev);
            eventId.add(ev.id);
        }
       
      
    if(!system.isFuture()){
    	eventSchedulerUtility.updateEventAssigneeOnEvent(eventId);
    }
}