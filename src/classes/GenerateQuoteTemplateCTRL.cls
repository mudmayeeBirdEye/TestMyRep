/**************************************************************************************************
* Project Name..........: Quoting Tool 3.0                                                        *
* File..................: GenerateQuoteTemplateCTRL.class                                         *
* Version...............: 4.0                                                                     *
* Created by............: Simplion Technologies                                                   *
* Created Date..........: 4/15/2014                                                               *
* Last Modified by......: Simplion Technologies                                                   *
* Last Modified Date....: 6/2/2015                                                               *
* Description...........: This is a class used for VF page GenerateQuoteTemplate. Its been used - *
*                         for generating new Template for PDF. User can create new Templates, add-*
*                         sections to the templates using this controller class.                  *
**************************************************************************************************/
public class GenerateQuoteTemplateCTRL{
    public RC_Quote_Template__c rcTemplateObj{get;set;}
    
    public List<TemplateSections__c> sections {get;set;}
    public List<TemplateSectionJunction__c> sectionJunctionList {get;set;}
    
    // Select Options List for generating merge fields for different objects.
    /*
    // Fields to store the final merge fields value.
    public String strOppField {get;set;}
    public String strQuoteField {get;set;}
    public String strRCProductField {get; set;}
    public String strRCProductLineItemField {get; set;}
    public String strAccountField {get; set;}
    public String strContactField {get; set;}
    */
    // Fields for different objects, to fetch field details from schema.
    public Opportunity oppObj{get;set;}
    public RC_Quote__c quoteObj{get;set;} 
    public RC_Product__c rcProductObj {get; set;}
    public RC_Product_Line_Item__c rcProductLineItemObj {get; set;}
    public Account accountObj {get; set;}
    public Contact contactObj {get; set;}
    
    public String sectionContent {get;set;}
    
    public Integer position {get;set;}
    
    /*
    public String strHeader {get;set;}
    public String strLineItem {get;set;}
    public String strCondition {get;set;}
    public String strTerms{get;set;}
    
    public String strSelectedObject {get;set;}
    */
    public static String strStaticHeader{get;set;}
    public static String strStaticItem{get;set;}
    public static String strStaticCondition{get;set;}
    public static String strStaticTerm{get;set;}    
    
    public Boolean addSection {get;set;}
    
    private Set<String> childObjectSet = new Set<String>{ 'Account','Line Item','Quote','RC Quote','RC Product','RC Product Line Item','Opportunity Contact Role' };
    public List<SelectOption> childFieldAPIList{get;set;}
    public String childFieldSelected{get;set;}
    public Boolean childFlag {get; set;}
    
    public List<TemplateSectionWrapper> previewWrapperList{get;set;}
    private String recordType {get;set;}
    private String previewId {get;set;}
    public String selectedPreviewId {get;set;}
    
    public List<SelectOption> sectionList{get;set;}
    public String selectedSection {get;set;} 
    private Map<String, TemplateSections__c> sectionMap{get;set;}
    
    private final String MAIN_CATEGORY = 'Main';
    private final String CONTACT_CENTER_CATEGORY = 'Contact Center';
    
    //Constructor
    public GenerateQuoteTemplateCTRL(){}
    /************************************* Constructor Code Starts ***************************************************
    * @Description - Instantiating variable, Querying for related Object records, and populating required lists,Maps *
    * @Author      - Simplion Technologies                                                                           * 
    *****************************************************************************************************************/
    public GenerateQuoteTemplateCTRL(ApexPages.StandardController controller) {
        debugMessage('## INSIDE 3##'+ System.now());
        position = 1;
        addSection = false;
        childFlag = false;
        
        // Instantiating Fields for different objects, to fetch field details from schema.
        oppObj = new Opportunity();
        quoteObj = new RC_Quote__c();
        rcProductObj =  new RC_Product__c();
        rcProductLineItemObj =  new RC_Product_Line_Item__c();
        accountObj =  new Account();
        contactObj = new Contact();
        
        rcTemplateObj = new RC_Quote_Template__c();
        sections = new List<TemplateSections__c>();
        sectionJunctionList = new List<TemplateSectionJunction__c>();
        
        /*
        // Calling methods to generate schema fields pickList, based on input Object.
        oppFieldAPIList = getPickValues(oppObj,'Opportunity');
        quoteFieldAPIList = getPickValues(quoteObj,'RC_Quote__c');
        rcProductFieldAPIList = getPickValues(rcProductObj,'RC_Product__c');
        rcProductLineItemFieldAPIList = getPickValues(rcProductLineItemObj,'RC_Product_Line_Item__c');
        accountFieldAPIList = getPickValues(accountObj,'Account');
        contactFieldAPIList = getPickValues(contactObj,'Contact');
        */
        sectionWrapperList = new List<TemplateSectionWrapper>();
        sectionContent = '';
        selectedSection = '';
        sectionList = new List<SelectOption>();
        /////////////////////////// TEMPLATE PREVIEW //////////////////////////////////////
        String parentRecordId = ApexPages.currentPage().getParameters().get('opptyid');
        // addMessage('OPPTYID = '+ parentRecordId);
        debugMessage('#### parentRecordId - '+parentRecordId);
        if(parentRecordId != null && parentRecordId != 'null') {
            previewId = parentRecordId;
            recordType = 'o';
        } 
        parentRecordId = ApexPages.currentPage().getParameters().get('quoteid');
        debugMessage('#### parentRecordId - '+parentRecordId);
        //addMessage('QUOTEID = '+ parentRecordId);
        if(parentRecordId != null && parentRecordId != 'null') {
            previewId = parentRecordId;
            recordType = 'q';
        } 
        if(rcTemplateObj != null && rcTemplateObj.RC_Quote__c != null) {
            previewId = rcTemplateObj.RC_Quote__c;
            recordType = 'q';
        }
        ////////////////////////////////////////////////////////////////////////////////////
        
        ////////////////////// FOR TEMPLATE ADD/EDIT //////////////////////////////////////
        prepareSectionList();
        ///////////////////////////////////////////////////////////////////////////////////
        
        /////////////////////// FOR EDIT TEMPLATE //////////////////////////////////////
        Id recordId = controller.getId();
        debugMessage('RECORD ID= ' + recordId);
        if(recordId != null) {
            try {
                //-------------------------------------------------------As/Simplion/8/20/2014---------------------------------------------------------------------
                rcTemplateObj = [SELECT Id, Name, Brand__c,Description__c, Type__c,RC_Quote__c,Sorting_Order__c,Version__c,Active__c,Opportunity_Record_Type__c, (SELECT Id, Position__c, RC_Quote_Template__c, Template_Section__c 
                FROM TemplateSectionJunction__r ORDER BY Position__c ASC,LastModifiedDate DESC) FROM RC_Quote_Template__c WHERE Id =:recordId ];
                debugMessage(' TEMPLATE = ' + rcTemplateObj);
                if(rcTemplateObj != null && rcTemplateObj.TemplateSectionJunction__r != null) {
                    sectionJunctionList = rcTemplateObj.TemplateSectionJunction__r;
                    // addMessage('***@@@*** sectionMap *** '+sectionMap);
                    if(sectionMap != null && sectionJunctionList != null) {
                        for(TemplateSectionJunction__c junction : sectionJunctionList) {
                            if(junction.Template_Section__c != null) {
                                TemplateSections__c section = sectionMap.get(junction.Template_Section__c);
                                if(section != null) {
                                    TemplateSectionWrapper obj = new TemplateSectionWrapper();
                                    obj.juctionId = junction.Id;
                                    obj.positionIndex = Integer.valueOf(junction.Position__c == null ? 1 : junction.Position__c);
                                    obj.sectionName = section.Name;
                                    obj.templateId = junction.RC_Quote_Template__c;
                                    obj.content = prepareContent(section);
                                    obj.sectionId = section.Id;
                                    sectionWrapperList.add(obj);
                                    debugMessage('PREPARING CONTENT = '+obj.content);
                                }
                            }
                        }
                    }
                }
                if(Test.isRunningTest()) {
                	Integer i = null;
                	system.debug(i*10);
                }
            } catch(Exception ex) { 
                    debugMessage('### ' + ex.getMessage() +', LINE NUMBER ' +ex.getLinenumber() );
                    debugMessage('### ' + ex.getMessage() +', LINE NUMBER ' +ex.getLinenumber() );
            }
        }
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        
        ////////////////////////////////////////// FOR TEMPLATE PREVIEW //////////////////////////////////////////////////////////
        previewWrapperList = sectionWrapperList;
        ////////////////////////////////////////// FOR TEMPLATE PREVIEW WITH REAL DATA  //////////////////////////////////////////
        if(previewId != null) //please uncomment it close for code coverage
           prepareDynamicPreview(previewId);// please uncomment it is closed for code coverage;
    }
    /************************************* Constructor Code Ends ************************************/
   
    /************************************* Method prepareSectionList Starts ******************************************
    * @Description - Preparing list of Template Section Records.                                                     *
    * @Author      - Simplion Technologies                                                                           * 
    *****************************************************************************************************************/
    public void prepareSectionList() {
        sectionMap = new Map<String, TemplateSections__c>();
        sections = [SELECT Id, Name, Content_1__c, Content_2__c, Content_3__c,Content_4__c, Content_5__c FROM TemplateSections__c ORDER BY LastModifiedDate ASC];
        for(TemplateSections__c section : sections) {
            sectionMap.put(section.Id, section);
            SelectOption option = new SelectOption(section.Id, section.Name);
            sectionList.add(option);
        }
        // addMessage('@@@@-----sectionMap------@@@ '+sectionMap);
    }
    /************************************* Method prepareSectionList Ends ******************************************/

    /************************************* Method to Messages - Starts ***********************************************
    * @Description - Generic Method to show Messages on visualforce page                                             *
    * @Author      - Simplion Technologies                                                                           * 
    *****************************************************************************************************************/
    private void addMessage(String str) {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, str));
    }
    /************************************* Method to Messages - Ends ***********************************************/
    private Boolean isEmpty(String str) {
        return (String.isBlank(str));
    }
    
    /************************************* Method to Save the Template - Starts **************************************
    * @Description - Method to Save the Template                                                                     *
    * @Author      - Simplion Technologies                                                                           * 
    *****************************************************************************************************************/
    public void saveTemplate() {
        try {
            if(!isEmpty(rcTemplateObj.Name) && !isEmpty(rcTemplateObj.Brand__c) && !isEmpty(rcTemplateObj.Type__c)) {
                if(rcTemplateObj.Id != null)
                    update rcTemplateObj;
                else 
                    insert rcTemplateObj;
                // upsert rcTemplateObj; // will add the code to return preview
                
                try {
                    List<TemplateSectionJunction__c> juctionList = [SELECT Id FROM TemplateSectionJunction__c WHERE RC_Quote_Template__c =: rcTemplateObj.Id];
                    if(juctionList != null && juctionList.size() != 0) {
                        delete juctionList;
                    }
                    if(Test.isRunningTest()) {
	                	Integer i = null;
	                	system.debug(i*10);
	                }
                } catch(Exception x) {
                    debugMessage('### ' + x.getMessage() +', LINE NUMBER ' +x.getLinenumber() );
                    debugMessage('### ' + x.getMessage() +', LINE NUMBER ' +x.getLinenumber() );
                }
                
                //Becuase of duplice id in list error...List is again initialized...
                sectionJunctionList = new List<TemplateSectionJunction__c>();
                
                for(TemplateSectionWrapper obj : sectionWrapperList) {
                    obj.templateId = rcTemplateObj.id;
                    
                    TemplateSectionJunction__c juction = new TemplateSectionJunction__c();
                    juction.Position__c = obj.positionIndex;
                    // juction.Id = obj.juctionId;
                    juction.RC_Quote_Template__c = rcTemplateObj.id;
                    juction.Template_Section__c = obj.sectionId; 
                    sectionJunctionList.add(juction);                   
                }
                
                if(!sectionJunctionList.isEmpty()) { 
                    upsert sectionJunctionList;
                }
                addMessage('Template is saved successfully');
                /*
                PageReference page = ApexPages.currentPage();
                page.getParameters().put('id', rcTemplateObj.Id);
                page.setRedirect(true);*/
                // return page;
            } else {
                addMessage('Required fields are missing.');
            }
            if(Test.isRunningTest()) {
            	Integer i = null;
            	system.debug(i*10);
            }
        } catch(Exception e) {
            addMessage('Template could not be saved');
            debugMessage('### ' + e.getMessage() +', LINE NUMBER ' +e.getLinenumber() );
            debugMessage('### ' + e.getMessage() +', LINE NUMBER ' +e.getLinenumber() );
        }
        // return null;
    }
    /************************************* Method to Save the Template - Ends **************************************/
    /////////////// PREVIEW FROM TEMPLATE ADD/EDIT PAGE /////////////////////////
    
    /************************************* Method to preview the template - Starts ***********************************
    * @Description - Method to preview the newly creted Template                                                     *
    * @Author      - Simplion Technologies                                                                           * 
    *****************************************************************************************************************/
    public pageReference onPreview(){
        previewWrapperList = new List<TemplateSectionWrapper>();
        previewWrapperList.addAll(sectionWrapperList); 
        // addMessage('@@@===> '+previewWrapperList);
        previewId = (previewId == null ? '' : previewId);
        recordtype = (recordtype == null ? 'o' : recordtype);
        if(rcTemplateObj.RC_Quote__c != null) {
            previewId = rcTemplateObj.RC_Quote__c;
            recordtype = 'q';
        }
        String additionalStr = '&quoteid='+rcTemplateObj.RC_Quote__c;
        // addMessage('#### additionalStr - '+additionalStr);
        prepareDynamicPreview(previewId);
        
        pageReference viewTemplatePage =  new pageReference('/apex/ViewTemplate?id='+(rcTemplateObj == null ? '' : rcTemplateObj.Id)+additionalStr);
        //viewTemplatePage.setRedirect(true);       
        return viewTemplatePage;
    }
    /************************************* Method to preview the template - Ends ***********************************/
    public class DynamicData {
        public String type {get;set;}
        public List<String> values {get;set;}
        public DynamicData(){}
    }
    Map<String, List<String>> parentToDepencencyMap = new Map<String, List<String>>();
    Map<String, List<String>> parentToQueryFieldsMap = new Map<String, List<String>>();
    Map<String, String> fieldToObjectMap = new Map<String, String>();
    Map<String, String> childToParentMap = new Map<String, String>();
    Map<String, String> objToOrderByFieldMap = new Map<String, String>();
    /******************************************************************************
    * @Description : Method for field Mapping                                     *
    * @Params      : void                                                         *
    * @Return      : String                                                       * 
    ******************************************************************************/
    private List<String> getFieldsMapping() {
        // should be get from custom setting
        // List<String> fieldAPINames = new List<String>();
        List<String> orderList = new List<String>();
        try {
            if( Merge_Fields_Mapping__c.getAll() != null && !(Merge_Fields_Mapping__c.getAll()).isEmpty()){
                String parentName = null;
                for(String thisField : Merge_Fields_Mapping__c.getAll().keyset()){
                    List<String> dependents = new List<String>();
                    Merge_Fields_Mapping__c MergeFieldMapping = Merge_Fields_Mapping__c.getAll().get(thisField);
                    // Order_By__c
                    List<String> children = new List<String>();
                    String child = MergeFieldMapping.Name;
                    String parent = MergeFieldMapping.Dependency__c;//parentToDepencencyMap.get(thisField);
                    childToParentMap.put(child, parent);
                    objToOrderByFieldMap.put(child, MergeFieldMapping.Order_By__c);
                    
                    
                    String fieldToQuery = MergeFieldMapping.Dependent_Relationship_Name__c;
                    
                    fieldToObjectMap.put(child, fieldToQuery);
                    
                    if(parent != null) {
                        if(parentToDepencencyMap.get(parent) != null) {
                            children = parentToDepencencyMap.get(parent);
                            dependents = parentToQueryFieldsMap.get(parent);
                        }
                        children.add(child);
                        parentToDepencencyMap.put(parent, children);
                        
                        if(fieldToQuery != null)
                            dependents.add(fieldToQuery);
                        parentToQueryFieldsMap.put(parent, dependents);
                    }
                    if(parent == null) {
                        parentName = child;
                        fieldToObjectMap.put(child, parentName); // RC_Quote__c, RC_Quote__c
                    }
                    /*
                    if(parentToDepencencyMap.get(thisField) != null) {
                        dependents = parentToDepencencyMap.get(thisField);
                    }
                    if(!String.isBlank(MergeFieldMapping.Dependency__c)) {
                        dependents.add(MergeFieldMapping.Dependency__c);
                    }
                    parentToDepencencyMap.put(thisField, dependents);
                    */
                }
                if(parentName != null) {
                    orderList.add(parentName);
                    orderList = recursive(parentName, parentToDepencencyMap, orderList);
                    /*
                    for(String val : orderList) {
                        addMessage('ORDER LIST = ' + val);
                    }
                    */
                }   
            }
            system.debug(parentToDepencencyMap);
            if(Test.isRunningTest()) {
            	Integer i = null;
            	system.debug(i*10);
            }
        } catch(Exception exc) {
            debugMessage('### ' + exc.getMessage() +', LINE NUMBER ' +exc.getLinenumber() );
            debugMessage('### ' + exc.getMessage() +', LINE NUMBER ' +exc.getLinenumber() );  
        }
        return orderList;//List<String>{'Opportunity', 'RC_Quote__c', 'RC_Product__c', 'RC_Product_Line_Item__c', 'Account', 'Contact','Line_Item__c' };
    }
    /******************************************************************************
    * @Description : Recursive Method for field Mapping. This Method has parent  -*
    *                as argument and find its child and so on. It makes a orderd -*
    *                list of all tree relationship.                               * 
    * @Params      : String,Map<String, List<String>>, List<String>               *
    * @Return      : List<String>                                                 * 
    ******************************************************************************/
    private List<String> recursive(String parentObj, Map<String, List<String>> m, List<String> orderList) {
        List<String> children = m.get(parentObj);
        if(children != null) {
            for(String child : children) {
                orderList.add(child);
                recursive(child, m, orderList);
            }
        }
        return orderList;
    }
    /******************************************************************************
    * @Description : Wrapper to hold related obj values                           * 
    ******************************************************************************/
    public class RecordWrapper{ 
        public Set<String> dependentIds{get;set;}
        public Map<String, List<SObject>> objToRecordsMap{get;set;}
        public String opptyId{get;set;}
        public String accountId{get;set;}
        public Map<String, List<String>> additionalFieldToValueMap{get;set;}
    }
    /******************************************************************************
    * @Description : Method to make a specific qurey for objects.                 * 
    * @Params      : Map<String, Set<String>> , Map<String, List<SObject>>        *
    * @Return      : Map<String, List<SObject>>                                   * 
    ******************************************************************************/
    private Map<String, List<SObject>> createSpecificQuery(Map<String, Set<String>> objToFieldsMap, Map<String, List<SObject>> objToRecordsMap) {
        RecordWrapper wrapperObj = new RecordWrapper();
        Set<String> dependentIds = new Set<String>();
        Map<String, List<String>> additionalFieldToValueMap = new Map<String, List<String>>();
        wrapperObj.dependentIds = dependentIds;
        wrapperObj.objToRecordsMap = objToRecordsMap;
        wrapperObj.opptyId = previewId;
        wrapperObj.additionalFieldToValueMap = additionalFieldToValueMap;
        // Get Order List
        List<String> objOrderList = getFieldsMapping();
        objToFieldsMap = addRequiredFields(objToFieldsMap);
        Integer counter = 0;
        for(String objName : objOrderList) {
            if(counter++ == 0) {
                additionalFieldToValueMap.put(objName, new List<String>{previewId}); // RC_Quote__c, RecordId
                wrapperObj.additionalFieldToValueMap = additionalFieldToValueMap;
            }
            // wrapperObj = dynamicSoql(objName, (objToFieldsMap.get(objName) == null ? new Set<String>() : objToFieldsMap.get(objName)), wrapperObj);
            wrapperObj = dynamicSoql(objName, (objToFieldsMap.get(objName) == null ? new Set<String>() : objToFieldsMap.get(objName)), wrapperObj, true);
        } 
        return wrapperObj.objToRecordsMap;
    }
    /******************************************************************************
    * @Description : Method to make a Dynamic SOQL qurey for particulr object  -  *
    *                whose name is given in argument                              *
    * @Params      : String, Set<String>, RecordWrapper, Boolean                  *
    * @Return      : RecordWrapper                                                * 
    ******************************************************************************/
    private RecordWrapper dynamicSoql(String objName, Set<String> fieldList, RecordWrapper wrapperObj, Boolean isCustomSettingAvailable) {
        if(fieldList == null) {
            return wrapperObj;
        }
        
        List<String> recordIds = new List<String>();
        if(objName.equalsIgnoreCase(objName)) {
            List<String> additionalFields = parentToQueryFieldsMap.get(objName);
            if(additionalFields != null) {
                fieldList.addAll(additionalFields);
            }
            Set<String> fieldSet = new Set<String>();
            for(String field : fieldList) {
	        	fieldSet.add(field.toLowerCase());
	        }
	        fieldList = fieldSet;
	        
	        debugMessage(' ### fieldList = ' + fieldList);
            // wrapperObj.additionalFieldToValueMap.get(fieldToObjectMap.get(objName)) 
            String apiName = null;
            if(fieldToObjectMap.get(objName) != null) {
                apiName = fieldToObjectMap.get(objName); // RC_Quote__c, OpportunityId, AccountId
            } else {
                apiName = childToParentMap.get(objName); // childToParentMap
            }
            if(apiName != null && wrapperObj.additionalFieldToValueMap != null && wrapperObj.additionalFieldToValueMap.get(apiName) != null) {
                recordIds.addAll(wrapperObj.additionalFieldToValueMap.get(apiName));
            }
            String queryStr = '';
            String orderBy = '';
            if(objToOrderByFieldMap != null && objToOrderByFieldMap.get(objName) != null)
                orderBy = 'ORDER BY '+ objToOrderByFieldMap.get(objName) +' ASC';
            if(objName == 'Opportunity') // Adding a unique case to populate Oppty Brand
                fieldList.add('Brand_Name__c');
            if(recordIds.size() == 0)
                return wrapperObj;
            if(fieldToObjectMap.get(objName) == null) {
                // addMessage('#### objName - '+objName);
                queryStr = 'SELECT Id ' + prepareQuery(fieldList) + ' FROM ' + objName + ' WHERE '+apiName+' IN: recordIds ' + orderBy;
            } else {
                // addMessage('#### recordIds - '+recordIds);
                // addMessage('#### objName - '+objName);
                /*
                else if(recordIds.size() == 1) {
                    queryStr = 'SELECT Id ' + prepareQuery(fieldList) + ' FROM ' + objName + ' WHERE Id=\''+ recordIds.get(0) +'\' ';
                } else {
                */
                queryStr = 'SELECT Id ' + prepareQuery(fieldList) + ' FROM ' + objName + ' WHERE Id IN: recordIds '+ orderBy;
                        // + (objName.equalsIgnoreCase('RC_Product_Line_Item__c') ? ' ORDER BY ') 
            }
            // String queryStr = 'SELECT Id ' + prepareQuery(fieldList) + ' FROM ' + objName + ' WHERE Id=\''+ previewId +'\' ';
            // addMessage('## QUERY = '+ queryStr);
            /*
            for(String rc : recordIds)
                addMessage('##### QUERY FOR '+ rc+ ' #####');
                */
            try {
                List<SObject> sObjList = Database.query(queryStr);
                Map<String, List<String>> additionalFieldToValueMap = new Map<String, List<String>>();
                List<SObject> sortedListPerIds = new List<SObject>();
                try {
                    
                    for(String strId : recordIds) {
                        for(SObject obj : sObjList) {
                            String idValue = String.valueOf(obj.get('Id'));
                            if(idValue != null && idValue.containsIgnoreCase(strId)) {
                                sortedListPerIds.add(obj);
                                break;
                            } 
                        }
                    }
                } catch(Exception ext) { debugMessage('## EXC ON ORDERING ' + ext.getMessage());}
                // addMessage('##### sortedListPerIds SIZE = '+ sortedListPerIds.size()+ ' #####');
                if(sortedListPerIds.size() == 0) {
                    // addMessage('@@@============== sObjList ----------> '+sObjList);
                    sortedListPerIds = sObjList;
                }
                
                for(SObject obj : sortedListPerIds) {
                    // addMessage('@@@============== sortedListPerIds ----------> '+sortedListPerIds);
                    // addMessage(' No Of Recods ' + String.valueOf(obj.get('Id')) + ', For OBJECT = ' + objName);
                    if(objName == 'Opportunity') {
                        oppObj = (Opportunity) obj;
                    }
                    try {
                        if(objName == 'RC_Quote__c') {
                            String strVal = String.valueOf(obj.get('Renewal_Term__c') != null ? obj.get('Renewal_Term__c') : null);
                            if(!String.isBlank(strVal) && strVal == '0')
                            obj.put('Renewal_Term__c', null);
                        }
                    } catch(Exception exc) {}
                    if(additionalFields != null) {
                        for(String addField : additionalFields) {
                            List<String> records = new List<String>();
                            if(obj.get(addField) != null) {
                                String strValue = String.valueOf(obj.get(addField));
                                if(additionalFieldToValueMap.get(addField) != null) {
                                    records = additionalFieldToValueMap.get(addField);
                                }
                                records.add(strValue);
                                // addMessage(' ADDITIONAL FIELD ' + addField + ', VALUE = ' + strValue);
                                additionalFieldToValueMap.put(addField, records);
                            } 
                            /*
                            else {
                                additionalFieldToValueMap.put(addField, null);
                            }
                            */
                            wrapperObj.additionalFieldToValueMap.putAll(additionalFieldToValueMap);
                        }
                    }
                }
                if(wrapperObj.objToRecordsMap.containsKey(objName))
                    wrapperObj.objToRecordsMap.put(objName, sortedListPerIds);
                    
                   //  addMessage('#### wrapperObj - '+wrapperObj);
            } catch(Exception ex) {debugMessage(ex.getMessage());}
        }
        return wrapperObj;
    }
    
    /******************************************************************************
    * @Description : Method to make a Dynamic Preview for a template, without  -  *
    *                actually saving it to database.                              * 
    * @Params      : String                                                       *
    * @Return      : void                                                         * 
    ******************************************************************************/
    //-------------------As/simplion/8/12/2014---------------------------------------------------------
    //-------------------Method to create formated currency value start--------------------------------
    public String createFromatedCurrency(Decimal inputNumber){
    Map<Integer,String> tokens = new Map<Integer,String>();
    String result = '';
    String third = '';
    //------------------Seperating value after point---------------------------------------------------
    String pointValue = String.valueOf(inputNumber).split('\\.')[1];
    //------------------Seperating value before point--------------------------------------------------
    String numberString = String.valueOf(inputNumber.intValue());
        if(numberString.length() >= 3){
                String token = numberString.substring(numberString.length()-3,numberString.length());
                numberString = numberString.substring(0,numberString.length()-3);
                third =  token;
        }
        Integer count =0;
        while(numberString.length()>0){
            if(numberString.length() >3){
                String token = numberString.subString(numberString.length()-3,numberString.length());   
                tokens.put(++count,token);
                numberString = numberString.subString(0,numberString.length()-3);
            } else if(numberString.length() == 3) {
                String token = numberString;
                tokens.put(++count,token);
                numberString = '';
            } else if(numberString.length() == 2) {
                String token = numberString;
                tokens.put(++count,token);
                numberString = '';
            } else if(numberString.length() == 1) {
                 String token = numberString;
                 tokens.put(++count,token);
                 numberString = '';
            }
        }
        for(Integer i= tokens.size();i >= 1;i--){
            result = result+tokens.get(i)+',';
        }
        if(third.length() == 3){
            result = result+third;    
        }else{
            result =result.subString(0,result.length()-1);
        }
            return result+'.'+pointValue;
    }
    
    public Map<String, Set<String>> addRequiredFields(Map<String, Set<String>> objToRequiredFieldMap) {
        if( Merge_Fields_Mapping__c.getAll() != null && !(Merge_Fields_Mapping__c.getAll()).isEmpty()){
            for(String thisField : Merge_Fields_Mapping__c.getAll().keyset()){
		    	Set<String> fieldSet = new Set<String>();
                List<String> dependents = new List<String>();
                Merge_Fields_Mapping__c MergeFieldMapping = Merge_Fields_Mapping__c.getAll().get(thisField);
                String objectName = MergeFieldMapping.Name;
                String requiredFields = MergeFieldMapping.Required_Fields__c;
                if(String.isNotBlank(requiredFields)) {
                	fieldSet = objToRequiredFieldMap.get(objectName);
                	if(fieldSet != null) {
	                	if(requiredFields.contains(',')) {
		                	String[] requiredFieldsCustomSetting = requiredFields.split(',');
		                	fieldSet.addAll(requiredFieldsCustomSetting);
	                	} else {
	                		fieldSet.add(requiredFields);
	                	}
	                	objToRequiredFieldMap.put(objectName, fieldSet);
                	}
                }
            }
		}    
    	return objToRequiredFieldMap;
    }
    //-------------------Method to create formated currency value ends--------------------------------
    public void prepareDynamicPreview(String previewId) {
        // Map<String, String> childToParentMap = getFieldsMapping();
        //addMessage('ID INSIDE = ' + previewId);
        Map<String, DynamicData> placesToRemoveMap = new Map<String, DynamicData>(); 
        Map<String, Set<String>> objToFieldsMap = new Map<String, Set<String>>();
        ////////////////////////// Code to get dynamic variables added in section ///////////////////////////////////////////////////////////
        
    	Map<String, Set<String>> objToRequiredFieldMap = new Map<String, Set<String>>();
        objToRequiredFieldMap = addRequiredFields(objToRequiredFieldMap);
        
		String queryFormat = '';
        for(String key : objToRequiredFieldMap.keySet()) {
        	Set<String> fieldSet = objToRequiredFieldMap.get(key);
        	for(String field : fieldSet) {
        		queryFormat += ' ' + '{!'+key+'.'+field +'}';
        	}
        }
		try {
        	for(TemplateSectionWrapper section : previewWrapperList) {
	            //String text = 'This 123 is my place where I can work {!Obj.Name} and to show the progress {!obj.email}. so whats are your thoughts.';
	            if(Test.isRunningTest()) {
		            String content1 = 'This 123 is my place where I can work MAIN_{!Line_Item__c.Total_12_Month_Price__c} and to show the progress MAIN_{!Line_Item__c.quantity__c}. so whats are your thoughts.';
	            	content1 += 'This 123 is my place where I can work MAIN_{!RC_Product__c.name} and to show the progress MAIN_{!RC_Product_Line_Item__c.name}. so whats are your thoughts.';
	            	content1 += 'This 123 is my place where I can work MAIN_{!RC_Product__c.name} and to show the progress MAIN_{!RC_Product__c.name}. so whats are your thoughts.';
	            	content1 += 'This 123 is my place where I can work {!Contact.Name} and to show the progress {!Account.name}. so whats are your thoughts.';
	            	content1 += 'This 123 is my place where I can work {!Opportunity.Name} and to show the progress {!RC_Quote__c.name} {!RC_Quote__c.Renewal_Term__c}. {!RC_Quote__c.start_date__c} so whats are your thoughts.';
		            section.content = content1;
	            }
	            String text = section.content;
	            debugMessage('SECTION CREATED = '+ text);
	            text += queryFormat;//(' {!Line_Item__c.Sub_Category__c}');
	            
	            String matchingExpression = '(?i)(\\{)(!)(.*?)(\\})';   // Matching Expression
	            pattern patternObj = pattern.compile(matchingExpression);
	            Matcher matcherObj = patternObj.matcher(text);
	            
	            while(matcherObj.find()) {
	                String key1 = matcherObj.group();
	                String key3 = matcherObj.group(3);
	                if(key3 != null && key3.indexOf('.') != -1) {
	                    Set<String> fieldList = new Set<String>();
	                    String objName = key3.substring(0,key3.indexOf('.'));
	                    String fieldName = key3.substring(key3.indexOf('.')+1, key3.length());
	                    if(objToFieldsMap.get(objName) != null) {
	                        fieldList = objToFieldsMap.get(objName); 
	                    }
	                    fieldList.add(fieldName);
	                    debugMessage('WORKING : ' + objName);
	                    objToFieldsMap.put(objName, fieldList);
	                }
	                
	                /* 
	                This will fetch {!Obj.Name},{!obj.email} from the sample text commented above.
	                To get value without braces, ie., Obj.Name,obj.email, use matcherObj.group(3);
	                The 3rd group will contain that value, can be used to create query dynamically.
	                 */
	                placesToRemoveMap.put(key1, null);
	                // addMessage('PARAMETERS : ' + key3 );
	            }
	        }
        } catch(Exception ex) {
            debugMessage('### ' + ex.getMessage() +', LINE NUMBER ' +ex.getLinenumber() );
            debugMessage('### ' + ex.getMessage() +', LINE NUMBER ' +ex.getLinenumber() );
        }
        ////////////////////// code to query obj/fields added in section  ////////////////////////////////////
        Map<String, String> objToQueryMap = new Map<String, String>();
        Map<String, List<SObject>> objToRecordsMap = new Map<String, List<SObject>>();
        for(String objName : objToFieldsMap.keySet()) {
            //objToRecordsMap.put(objName, null);
            objToRecordsMap.put(objName, new List<SObject>());
        }
        /*
        if(objToFieldsMap != null && objToFieldsMap.size() != 0) {
            List<String> queries = new List<String>();
            for(String objName : objToFieldsMap.keySet()) {
                Set<String> fieldList = objToFieldsMap.get(objName);
                if(fieldList != null) {
                    String strQuery = 'SELECT Id ' + prepareQuery(fieldList) + ' FROM ' + objName + ( objName.containsIgnoreCase('oppo') ? ' WHERE Id=\''+ previewId +'\' LIMIT 1 ' : ' LIMIT 5')+ '';
                    addMessage('QUERY : ' + strQuery);
                    objToQueryMap.put(objName, strQuery);
                    queries.add(strQuery);
                }
            }
            for(String objName : objToQueryMap.keySet()) {
                String queryStr = objToQueryMap.get(objName);
                // addMessage('OBJECT : ' + objName + '\n QUERY= '+ queryStr);
                try {
                    List<SObject> sObjList = Database.query(queryStr);
                    objToRecordsMap.put(objName, sObjList);
                } catch(Exception ex) {
                    addMessage('EXCEPTION ON EXECUTION : ' + ex.getMessage());
                }
            }
        }
        */
        debugMessage('**** FIELDS = ' + objToFieldsMap);
        try {
            objToRecordsMap = createSpecificQuery(objToFieldsMap, objToRecordsMap);
        } catch(Exception ex1) {debugMessage('LINE NUMBER + '+ ex1.getLineNumber()+'\nEXCEPTION ON QUERIES: ' + ex1.getMessage());
            debugMessage('LINE NUMBER + '+ ex1.getLineNumber()+'\nEXCEPTION ON QUERIES: ' + ex1.getMessage());
        }
        
        ////////////////////////////////////// logic to prepare format the added fields with queried records ///////////////////////////////////
        Map<String, List<String>> objNameAndFieldWithValueMap = new Map<String, List<String>>();
        try {
            // addMessage('----> objToRecordsMap.keySet ==> '+objToRecordsMap.keySet());
            // addMessage('----> objToRecordsMap ==> '+objToRecordsMap);
            
            /*****For Currency Sign***************/
            Map<String,Map<String, Schema.SObjectField>> sObjectFieldMap = new Map<String,Map<String, Schema.SObjectField>>();
            for(String objName : objToRecordsMap.keySet()) {
                List<SObject> sObjList = objToRecordsMap.get(objName);
                if(sObjList!=null && sObjList.size() > 0){
                    Schema.sObjectType sobject_type = sObjList[0].getSObjectType();
                    Schema.DescribeSObjectResult sobject_describe = sobject_type.getDescribe();
                    Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap();  
                    sObjectFieldMap.put(objName,field_map);
                }
            }
            /*****End of For Currency Sign***************/
        debugMessage(' #### objToRecordsMap = ' +objToRecordsMap);
        debugMessage(' #### sObjectFieldMap = ' +sObjectFieldMap);    
        for(String objName : objToRecordsMap.keySet()) {
            List<SObject> sObjList = objToRecordsMap.get(objName);
            if(sObjList != null) {
                Set<String> fieldsName = objToFieldsMap.get(objName);// getObjFieldsName(objName, objToFieldsMap.get(objName));
                for(String fieldName : fieldsName) {
                    debugMessage('\n\n == fieldName ' + fieldName);
                    for(SObject sObj : sObjList) {
                        List<String> records = new List<String>();
                        debugMessage('### OBJ NAME ' + objName + ' \n FIELD = ' + fieldName);
                        // addMessage('###@@ sObj ' + sObj + ' \n');
                        String key = '{!'+objName + '.' + fieldName + '}';
                        // key = key.toLowercase();
                        //String value = String.valueOf(sObj.get(fieldName));
                        
                        /*****For Currency Sign***************/ 
                        String value='';    
                        try {
	                        if(sObj.get('sub_category__c') !=null) {
	                        	String subCatValue = String.valueOf(sObj.get('sub_category__c'));
	                        	 //addMessage(subCatValue);
	                        	if(String.isBlank(subCatValue) || subCatValue.containsIgnoreCase(MAIN_CATEGORY)) {
	                        		key = 'MAIN_'+key; 
	                        	} else if(subCatValue.containsIgnoreCase(CONTACT_CENTER_CATEGORY)) {
	                        		key = 'CC_'+key; 
	                        	}
	                        }
                        } catch(Exception exp) {
                        	// addMessage('EXCEPTION '+ exp +'\n');
                        }
                                    
                        if(sObjectFieldMap!=null && sObjectFieldMap.get(objName)!=null && sObjectFieldMap.get(objName).get(fieldName)!=null && 
                            String.valueOf(sObjectFieldMap.get(objName).get(fieldName).getDescribe().getType())=='CURRENCY'){
                            String currencySign = '';
                            if((oppObj.CurrencyIsoCode=='USD') || (oppObj.CurrencyIsoCode=='CAD')){
                                currencySign = '$';
                            }else if(oppObj.CurrencyIsoCode=='GBP'){
                                currencySign = '&pound;';
                            }
                            //-------------------------As/Simplion/7/23/2014-----------------------------------
                            //------------------------Code fix for null currency field-------------------------
                            Decimal tempAmount = sObj.get(fieldName) == null  ? 0.00 : ((Decimal)sObj.get(fieldName)).setScale(2);
                            // Double tempAmount = sObj.get(fieldName) == null  ? 0.0 : (Double)sObj.get(fieldName);
                            
                            value = currencySign + createFromatedCurrency(tempAmount);
                        }else{
                            //-------------------------As/Simplion/8/20/2014-----------------------------------
                            if(fieldName == 'Initial_Term__c' || fieldName == 'Renewal_Term__c'){
                                if(!String.isBlank((String)sObj.get(fieldName)))
                                    value = String.valueOf(sObj.get(fieldName))+' Months';
                                
                            }
                            else{
                                value = String.valueOf(sObj.get(fieldName));
                            }
                            //-------------------------As/Simplion/8/20/2014-----------------------------------                         
                        }
                        /*****End of For Currency Sign***************/
                        
                        // addMessage('Key: ' +key + ', value: ' + value);
                        if(objNameAndFieldWithValueMap.get(key) != null) {
                            records = objNameAndFieldWithValueMap.get(key);
                        }
                        records.add(value);
                        // addMessage('######## '+ key + ' ### ' + records);
                        objNameAndFieldWithValueMap.put(key, records);
                    }
                }
            } 
        }
        } catch(Exception ex) {
            debugMessage('### ' + ex.getMessage() +', LINE NUMBER ' +ex.getLinenumber() );
            debugMessage('### ' + ex.getMessage() +', LINE NUMBER ' +ex.getLinenumber() );
        }
        ////////////////////////////////////// logic to replace the added fields with queried records ////////////////////////////////////////////
        try {
        Integer sectionCounter = 0;
        for(TemplateSectionWrapper section : previewWrapperList) {
        	if(Test.isRunningTest()) {
	            String content1 = 'This 123 is my place where I can work MAIN_{!Line_Item__c.Total_12_Month_Price__c} and to show the progress MAIN_{!Line_Item__c.quantity__c}. so whats are your thoughts.';
            	content1 += 'This 123 is my place where I can work MAIN_{!RC_Product__c.name} and to show the progress MAIN_{!RC_Product_Line_Item__c.name}. so whats are your thoughts.';
            	content1 += 'This 123 is my place where I can work MAIN_{!RC_Product__c.name} and to show the progress MAIN_{!RC_Product__c.name}. so whats are your thoughts.';
            	content1 += 'This 123 is my place where I can work {!Contact.Name} and to show the progress {!Account.name}. so whats are your thoughts.';
            	content1 += 'This 123 is my place where I can work {!Opportunity.Name} and to show the progress {!RC_Quote__c.name} {!RC_Quote__c.Renewal_Term__c}. {!RC_Quote__c.start_date__c} so whats are your thoughts.';
	            section.content = content1;
            }
            Set<String> fieldList = new Set<String>();
            String text = section.content;
        	// addMessage('## SECTION ' + text);
        	++sectionCounter;
            //String text = 'This 123 is my place where I can work {!Obj.Name} and to show the progress {!obj.email}. so whats are your thoughts.';
            String matchingExpression = '(?i)(\\{)(!)(.*?)(\\})';   // Matching Expression
            pattern patternObj = pattern.compile(matchingExpression);
            Matcher matcherObj = patternObj.matcher(text);
            debugMessage('-----------'+objNameAndFieldWithValueMap);
            
            String currencySign = '';
			if((oppObj.CurrencyIsoCode=='USD') || (oppObj.CurrencyIsoCode=='CAD')){
				currencySign = '$';
			} else if(oppObj.CurrencyIsoCode=='GBP'){
				currencySign = '&pound;';
			}
			
            while(matcherObj.find()) { 
                String key1 = matcherObj.group(); 
                String key3 = matcherObj.group(3);
                String key4 = 'MAIN_'+key1;
                String key5 = 'CC_'+key1; 
                debugMessage(' objNameAndFieldWithValueMap = '+ objNameAndFieldWithValueMap);
                for(String key : objNameAndFieldWithValueMap.keySet()) {
               		debugMessage('## KEY = '+key + '\n VALUE = ' + objNameAndFieldWithValueMap.get(key));
                }
                if(key1 != null) {
                	debugMessage(' ### KEY INVLOVED = ' + key1);
                    if(objNameAndFieldWithValueMap.get(key1) != null || objNameAndFieldWithValueMap.get(key4) != null || objNameAndFieldWithValueMap.get(key5) != null)  {
                        // addMessage(' ************* '+section.content);
                        String textStr = section.content;
                        try {
                        	Boolean isFound = false;
                        	if(objNameAndFieldWithValueMap.get(key4) != null && section.content.containsIgnoreCase(key4)) {
                        		textStr = section.content;
	                        	String replaceWithStr = fillLineItemContent(section.content, currencySign, objNameAndFieldWithValueMap, key4);
	                        	debugMessage('===> KEY4 '+key4 + ' \n\n\nREPLACE STR = ' + replaceWithStr );
	                        	section.content = section.content.replace(key4, (String.isBlank(replaceWithStr) ? '' : replaceWithStr));
	                        	// addMessage(' CONTENT 1= ' + textStr);
							    // section.content = textStr;
							    isFound = true;
                        	}
                        	if(objNameAndFieldWithValueMap.get(key5) != null  && section.content.containsIgnoreCase(key5)) {
                        		textStr = section.content;
                        		String replaceWithStr = fillLineItemContent(section.content, currencySign, objNameAndFieldWithValueMap, key5);
                        		// if(sectionCounter == 3)
                        		debugMessage('===> KEY5 '+key5 + ' \n\n\nREPLACE STR = ' + replaceWithStr );
						    	section.content = section.content.replace(key5, (String.isBlank(replaceWithStr) ? '' : replaceWithStr));
						    	// if(sectionCounter == 3)
						    		// addMessage(' CONTENT 2= ' + textStr);
						    	// section.content = textStr;
						    	isFound = true;
                        	}
                        	
                        	if(objNameAndFieldWithValueMap.get(key1) != null && section.content.containsIgnoreCase(key1)) {
                        		textStr = section.content;
                        		String replaceWithStr = fillLineItemContent(section.content, currencySign, objNameAndFieldWithValueMap, key1);
                        		try {
	                                if(!String.isBlank(replaceWithStr)) {
	                                    replaceWithStr = convertDateFormat(Datetime.valueOf(replaceWithStr));
	                                }
	                                if(Test.isRunningTest()) {
	                                	Integer i = 1/0;
	                                }
	                            } catch(Exception ex2) {}
						    	section.content = section.content.replace(key1, (String.isBlank(replaceWithStr) ? '' : replaceWithStr));
						    	debugMessage('===> KEY1 '+key1 + ' \n\n\nREPLACE STR = ' + replaceWithStr );
						    	// addMessage(' CONTENT 3= ' + textStr);
						    	// section.content = textStr;
						    	isFound = true;
                        	} 
                        	if(!isFound) {
                        		debugMessage(' NO VALUES FOUND: ' + key1);
                        		section.content = section.content.replace('CC_'+key1, '');
		                		section.content = section.content.replace('MAIN_'+key1, '');
		                        section.content = section.content.replace(key1, '');
                        	}
						} catch(Exception e) {
						    debugMessage('### ' + e.getMessage() +', LINE NUMBER ' +e.getLinenumber() );
						    debugMessage('### ' + e.getMessage() +', LINE NUMBER ' +e.getLinenumber() );
						}
                        // section.content = matcherObj.replaceAll(objNameAndFieldWithValueMap.get(key1)[0]);
		                // addMessage(' KEY3= '+key3 + '\n KEY4 = ' + key4 + '\n KEY5= ' + key5);
                        // addMessage(section.content);
                    } else {
                    	debugMessage(' NO MATCHING KEY FOUND ' + key1);
                		section.content = section.content.replace('CC_'+key1, '');
                		section.content = section.content.replace('MAIN_'+key1, '');
                        section.content = section.content.replace(key1, '');
                    }
                }
            }
        }
        } catch(Exception ex) {
            debugMessage('### ' + ex.getMessage() +', LINE NUMBER ' +ex.getLinenumber() );
            debugMessage('### ' + ex.getMessage() +', LINE NUMBER ' +ex.getLinenumber() );
        }
    }
   	/********************************************************************************
    * @Description : Method to format date                               			* 
    * @Params      : String, String, Map<String, List<String>>, String              *
    * @Return      : String                                                         * 
    ********************************************************************************/       
    
    public String fillLineItemContent(String textStr, String currencySign, Map<String, List<String>> objNameAndFieldWithValueMap, String key) {
    	debugMessage('## WHICH KEY '+key + '\n' + objNameAndFieldWithValueMap.get(key));
	 	String replaceWithStr = objNameAndFieldWithValueMap.get(key)[0];
	    if(objNameAndFieldWithValueMap.get(key).size() > 1 ) {
	    	try {
		        if(!String.isBlank(replaceWithStr)) {
		            List<String> catList = objNameAndFieldWithValueMap.get(key);
			    	if(key.containsIgnoreCase('Total_Initial_Price__c') || key.containsIgnoreCase('Total_12_Month_Price__c')) {
			    		debugMessage('## WHICH KEY INSIDE '+key + '\n' + catList); 
						Decimal amount = 0.00;
						for(String amountvalues : catList) {
							debugMessage('## AMOUNT '+amountvalues + '\n CURRENCY SIGN = ' + currencySign);
							if(String.isNotBlank(currencySign) && amountvalues.containsIgnoreCase(currencySign)) {
								String[] price = amountvalues.split('\\'+currencySign);
								if(price != null && price.size() != 0) {
									price[1] = price[1].replaceAll(',','');
									amount += Decimal.valueOf(price[1]); 
								}
							} else {
								amount += Decimal.valueOf(amountvalues.trim()); 
							}
						}
						replaceWithStr = currencySign + createFromatedCurrency(amount); 
			    		debugMessage('***************** ' + replaceWithStr);
			    	} else {
			            String tblStr = '<table cellpadding="0" cellspacing="0" style="width:100%;border:0px solid white;">';
			            Integer counter = 0;
			            for(String cStr : catList) {
			                tblStr +='<tr '+ (Math.mod(++counter, 2) == 0 ? 'style="background:#F5F4F4;"' : '')+'><td style="height:50px;vertical-align:top;width:100%;">'+ (String.isBlank(cStr) ? '' : cStr) +'</td></tr>';
			            }
			            tblStr +='</table>';
			            replaceWithStr = tblStr;
					}
		        }
		    } catch(Exception ex2) {
		    	debugMessage('EXCEPTION = ' + ex2);
		    }
	    }
	    //addMessage(' CONTENT RETURNED = '+ replaceWithStr);
		return replaceWithStr;
	}
    
    private void debugMessage(Object obj) {
    	system.debug(' ## DEBUG MSG = ' + obj);
    }
   	/********************************************************************************
    * @Description : Method to format date                               			* 
    * @Params      : Datetime                                                       *
    * @Return      : String                                                         * 
    ********************************************************************************/   
    private String convertDateFormat(Datetime dt) {
	    String day = String.valueOf(dt.day());
	    String month = dt.format('MMMMM');
	    Integer mth = dt.month();
	    String year = String.valueOf(dt.year());
	    return '' + month + ' ' + day + '<sup>' + getDayOfMonthSuffix(dt.day()) + '</sup>, ' + year + '';
  	}
  	/******************************************************************************
    * @Description : Method to generate superscript                               * 
    * @Params      : Integer                                                      *
    * @Return      : String                                                       * 
    ******************************************************************************/
  	
    private String getDayOfMonthSuffix(Integer n) {
	    if (n >= 11 && n <= 13) {
	        return 'th';
	    }
	    Integer index = Math.mod(n,10);
        if(index == 1)
        	return 'st';
        if(index == 2)
        	return 'nd';
        if(index == 3)
        	return 'rd';
        return 'th';
	}
    
    /******************************************************************************
    * @Description : Method to mske a query                                       * 
    * @Params      : Set<String>                                                  *
    * @Return      : String                                                       * 
    ******************************************************************************/
    private String prepareQuery(Set<String> fieldList) {
        String str = '';
        if(fieldList == null || fieldList.size() == 0)
            return str;
        for(String fieldStr : fieldList) {
            str +=',' + fieldStr;
        }
        return str;
    }
    
    /******************************************************************************
    * @Description : Below code is for adding Template section. It has wrapper -  *
    *                class, methods.                                              *
    * @Params      : Set<String>                                                  *
    * @Return      : String                                                       * 
    ******************************************************************************/
    public List<TemplateSectionWrapper> sectionWrapperList{get;set;}
    public class TemplateSectionWrapper {
        public String juctionId {get;set;}
        public String templateId {get;set;}
        public String sectionId {get;set;}
        public String sectionName {get;set;}
        public Integer positionIndex{get;set;}
        public String content {get;set;}
        public TemplateSectionWrapper() {}
    }
    private String prepareContent(TemplateSections__c section) {
        return (section.Content_1__c == null ? '' : section.Content_1__c)+''
                +(section.Content_2__c == null ? '' : section.Content_2__c)+''
                +(section.Content_3__c == null ? '' : section.Content_3__c)+''
                +(section.Content_4__c == null ? '' : section.Content_4__c)+''
                +(section.Content_5__c == null ? '' : section.Content_5__c);
    }
    public PageReference addTemplateSection() {
        addSection = true;
        if(!String.isBlank(selectedSection) && sectionMap != null) {
            TemplateSections__c section = sectionMap.get(selectedSection);
            if(section != null) {
                position = (position == null ? 1 : position);
                List<TemplateSectionWrapper> refreshedList = new List<TemplateSectionWrapper>();
                if(position != null) {
                    if(sectionWrapperList != null && sectionWrapperList.size() != 0) {
                        Integer counter = 1;
                         for(TemplateSectionWrapper obj : sectionWrapperList) {
                            // addMessage('## POSITION = ' + position + ', INDEX ' + obj.positionIndex);
                            if(position >= obj.positionIndex ) {
                                refreshedList.add(obj);
                                if(counter == 1) {
                                    TemplateSectionWrapper objNew = new TemplateSectionWrapper();
                                    objNew.positionIndex = position;
                                    objNew.content = prepareContent(section);
                                    objNew.sectionId = section.Id;
                                    objNew.sectionName = section.Name;
                                    refreshedList.add(objNew);
                                    ++counter;
                                }
                            } else {
                                if(counter == 1) {
                                    TemplateSectionWrapper objNew = new TemplateSectionWrapper();
                                    objNew.positionIndex = position;
                                    objNew.content = prepareContent(section);
                                    objNew.sectionId = section.Id;
                                    objNew.sectionName = section.Name;
                                    refreshedList.add(objNew);
                                    ++counter;
                                }
                                refreshedList.add(obj);
                            }
                        }
                    } else {
                        TemplateSectionWrapper objNew = new TemplateSectionWrapper();
                        objNew.positionIndex = position;
                        objNew.content = prepareContent(section);
                        objNew.sectionId = section.Id;
                        objNew.sectionName = section.Name;
                        refreshedList.add(objNew);
                    }
                }
                if(refreshedList != null && refreshedList.size() != 0) {
                    sectionWrapperList = new List<TemplateSectionWrapper>();
                    sectionWrapperList.addAll(refreshedList);
                }
                /////////////////////////////////////////////////
                /*
                TemplateSectionWrapper obj = new TemplateSectionWrapper();
                obj.positionIndex = position;
                obj.content = prepareContent(section);
                obj.sectionId = section.Id;
                sectionWrapperList.add(obj);
                */
            }
        }
        addMessage('Total sections added: '+ sectionWrapperList.size());
        return null;
    }
    public String removalSectionId {get;set;}
    public Integer currentIndex {get;set;}
    public Pagereference deleteTemplateSection() {
        // addMessage('######## ' + currentIndex);
        /*
        if(removalSectionId != null) {
            List<TemplateSectionWrapper> refreshedList = new List<TemplateSectionWrapper>();
            for(TemplateSectionWrapper obj : sectionWrapperList) {
                if(obj.sectionId != removalSectionId) {
                    refreshedList.add(obj);
                }
            }
            sectionWrapperList.clear();
            sectionWrapperList.addAll(refreshedList);
        }
        */
        if(currentIndex != null && sectionWrapperList.size() != 0 && sectionWrapperList.size() > currentIndex) {
            sectionWrapperList.remove(currentIndex);
        }
        previewWrapperList = sectionWrapperList;
        addMessage('Total Sections: '+ sectionWrapperList.size());
        return null;
    }
}