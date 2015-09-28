trigger QoSProbeInventory_Before  on QoS_Probe_Inventory__c (Before insert, Before update)  {
    
    if((Trigger.isInsert)||(Trigger.isUpdate)){
        try{
            Set<String> setQoSProbeInventory_UpcomingInventory = new Set<String>();
            Set<String> setDuplicateName = new Set<String>();
            Map<String,QoS_Probe_Inventory__c> MapIdAndQoSProbeInventory = new Map<String,QoS_Probe_Inventory__c>();
            
            for(QoS_Probe_Inventory__c QoSProbeInventoryObject:Trigger.new){
                setQoSProbeInventory_UpcomingInventory.add(QoSProbeInventoryObject.Name);       
                MapIdAndQoSProbeInventory.put(QoSProbeInventoryObject.Name,QoSProbeInventoryObject);
            }
            
            for(QoS_Probe_Inventory__c QoSProbeInventoryObject:[SELECT Id,Name,Probe_Name__c FROM QoS_Probe_Inventory__c WHERE Name IN: setQoSProbeInventory_UpcomingInventory  ]){
                setDuplicateName.add(QoSProbeInventoryObject.Name);
            } 
            
            if(Trigger.isInsert){
                for(String strName :setDuplicateName){
                    MapIdAndQoSProbeInventory.get(strName).Name.addError('QoS Probe Serial Number  already exists.');
                    MapIdAndQoSProbeInventory.get(strName).addError('Duplicate QoS Probe Inventory  is found.');
                }
            }
            
            if(Trigger.isUpdate){
            system.debug('Code is in ----------');
                for(QoS_Probe_Inventory__c QoSProbeInventoryObject:trigger.new){
                    QoS_Probe_Inventory__c QoSProbeInventoryObjectOld = trigger.oldMap.get(QoSProbeInventoryObject.id);
                    system.debug('QoSProbeInventoryObjectOld.name  '+QoSProbeInventoryObjectOld.name);
                     system.debug('QoSProbeInventoryObject.name  '+QoSProbeInventoryObject.name);
                    if(QoSProbeInventoryObjectOld.name != QoSProbeInventoryObject.name ){
                        system.debug('Code is in 1 ----------');
                        if(setDuplicateName.contains(QoSProbeInventoryObject.name)){
                        system.debug('Code is in 2 ----------');
                            MapIdAndQoSProbeInventory.get(QoSProbeInventoryObject.name).Name.addError('QoS Probe Serial Number  already exists.');
                            MapIdAndQoSProbeInventory.get(QoSProbeInventoryObject.name).addError('Duplicate QoS Probe Inventory  is found.');
                        }
                    }
                }
               
            }
            
        }catch(Exception ex){
            system.debug('#### Error on line - '+ex.getLineNumber()); 
            system.debug('#### Error message - '+ex.getMessage());
        }
    }
    if(Trigger.isUpdate){
        try{
            //List<QoS_Probe_Inventory__c> listQoSProbeInventory = new List<QoS_Probe_Inventory__c> ();
            for(QoS_Probe_Inventory__c objProbeInventory:trigger.new){
                 QoS_Probe_Inventory__c QoSProbeInventoryObjectOld = trigger.oldMap.get(objProbeInventory.id);
                 if(QoSProbeInventoryObjectOld.Status__c != 'Available' && objProbeInventory.Status__c == 'Available'){
                    system.debug('IF STATUS CHANGE TO AVAILABLE QoS PROBE INVENTORY');
                    objProbeInventory.Assigned_Case__c = null;
                    objProbeInventory.Customer_Contact_Name__c = null;
                    objProbeInventory.Estimated_Return_Date__c = null;
                    objProbeInventory.Shipping_Address__c = null;
                 
                 }
                // listQoSProbeInventory.add(objProbeInventory);
            }               
         }catch(Exception ex){
            system.debug('#### Error on line - '+ex.getLineNumber()); 
            system.debug('#### Error message - '+ex.getMessage());
         }  
    }
 }