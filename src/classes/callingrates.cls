public class callingrates {
	public List<SelectOption> lstCountry {get;set;}
	public List<SelectOption> lstDomesticCode {get;set;}
	public List<String> lstCountryName{get;set;}
	public List<String> lstDomesticName{get;set;}
	public Map<String,List<RatesWrapp>> mapInternationalRates {get;set;}
	public Map<String,List<RatesWrapp>> mapDomesticRates {get;set;}
	public Map<String,Set<String>> mapCountry {get;set;}
	public String strSingleWord {get;set;}
	public String strSelectedCountry {get;set;}
	public String strDomesticName {get;set;}
	public List<RatesWrapp> domesticRates {get;set;}
	public List<String> filterKey{get;set;}
	
	public static String domestic_CountryName = 'united kingdom';
	public Set<String> domesticSet;
	Blob csvBlob;
	List<List<String>> lstContentRow;

	public callingrates(){
		try{
			lstCountry = new List<SelectOption>();
			lstDomesticCode = new List<SelectOption>();
			filterKey = new List<String>();
			lstCountryName = new List<String>();
			lstDomesticName = new List<String>();
			domesticRates = new List<RatesWrapp>();
			mapInternationalRates = new Map<String,List<RatesWrapp>>();
			mapDomesticRates = new Map<String,List<RatesWrapp>>();
			mapCountry = new Map<String,Set<String>>();
			List<Document> lstDoc = [SELECT body, bodyLength, ContentType, Url FROM Document WHERE Name ='BT_Calling_Rates'];
			system.debug('#### lstDoc - '+lstDoc);
			if(lstDoc != null && lstDoc.size() > 0){
				csvBlob = lstDoc[0].body;
				lstContentRow = parseCSV(csvBlob.toString(), true);
				processCSVData(lstContentRow);
			}
		}catch(Exception ex){
			system.debug('Exception == ' + ex.getMessage() + ex.getStackTraceString());
		}
	}
	
	private void processCSVData(List<List<String>> lstRows){
		try{
			if(lstRows != null && lstRows.size() > 0){
				domesticSet = new Set<String>();
				for(List<String> obj : lstRows){
					List<RatesWrapp> lstRWI = new List<RatesWrapp>();
					List<RatesWrapp> lstRWD = new List<RatesWrapp>();
					Set<String> nameList = new Set<String>();
					String countryCode = String.isNotBlank(obj.get(0)) ? obj.get(0).replace('"','') : '';
					String countryName = String.isNotBlank(obj.get(1)) ? obj.get(1).replace('"','') : '';
					String domesticCode = String.isNotBlank(obj.get(2)) ? obj.get(2).replace('"','') : '';
					String domesticName = String.isNotBlank(obj.get(3)) ? obj.get(3).replace('"','') : '';
					String internationalType = String.isNotBlank(obj.get(4)) ? obj.get(4).replace('"','') : '';
					String domesticType = String.isNotBlank(obj.get(5)) ? obj.get(5).replace('"','') : '';
					String areaList = String.isNotBlank(obj.get(6)) ? obj.get(6).replace('"','') : '';
					String rates = String.isNotBlank(obj.get(7)) != null ? obj.get(7).replace('"','') : '';
					RatesWrapp rwObj = new RatesWrapp(countryCode, countryName, domesticCode, domesticName, internationalType, domesticType, areaList, rates);
					String countryName_lowercase = countryName.toLowerCase();
					
					String firstLetter = countryName.Substring(0,1).trim().toUpperCase();
					if(mapCountry != null && mapCountry.containsKey(firstLetter)){
						nameList = mapCountry.get(firstLetter);
						nameList.add(countryName_lowercase);
						mapCountry.put(firstLetter,nameList);
					}else{
						nameList.add(countryName_lowercase);
						mapCountry.put(firstLetter,nameList);
					}
					if(mapInternationalRates != null && mapInternationalRates.containsKey(countryName_lowercase)){
						lstRWI = mapInternationalRates.get(countryName_lowercase);
						lstRWI.add(rwObj);
						mapInternationalRates.put(countryName_lowercase,lstRWI);
					}else{
						lstRWI.add(rwObj);
						mapInternationalRates.put(countryName_lowercase,lstRWI);
					}
					String domesticType_lower = String.isNotBlank(domesticType) ? domesticType.trim().toLowerCase() : '';
					if(String.isNotBlank(countryName_lowercase) && domestic_CountryName.equalsIgnoreCase(countryName_lowercase) && String.isNotBlank(domesticType_lower)){
						domesticSet.add(domesticType);
						if(mapDomesticRates != null && mapDomesticRates.containsKey(domesticType_lower)){
							lstRWD = mapDomesticRates.get(domesticType_lower);
							lstRWD.add(rwObj);
							mapDomesticRates.put(domesticType_lower,lstRWD);
						}else{
							lstRWD.add(rwObj);
							mapDomesticRates.put(domesticType_lower,lstRWD);
						}
					}
				}
				
				if(mapCountry != null){
					filterKey.addAll(mapCountry.keySet());
					filterKey.sort();
				}
				
				lstDomesticCode.add(new SelectOption('','Select Type'));
				lstDomesticCode.add(new SelectOption('a_','All'));
				List<String> lstDomestic = new List<String>();
				lstDomestic.addAll(domesticSet);
				lstDomestic.sort();
				for(String code : lstDomestic){
					if(String.isNotBlank(code)){
						lstDomesticCode.add(new SelectOption(code.toLowerCase().trim(),code.trim()));
					}
				}
				
				lstCountry.add(new SelectOption('','Select Country'));
				lstCountry.add(new SelectOption('a_','All'));
				if(mapInternationalRates != null){
					Set<String> countryNameSet = mapInternationalRates.keySet();
					for(String nameStr : countryNameSet){
						if(mapInternationalRates != null && mapInternationalRates.containsKey(nameStr)){
							lstCountry.add(new SelectOption(nameStr, mapInternationalRates.get(nameStr).get(0).countryName));
						}
					}
					lstCountry.sort();
				}
			}
		}catch(Exception ex){
			system.debug('Exception == ' + ex.getMessage() + ex.getStackTraceString());
		}
	}
	
	public PageReference getAllInternationRates(){
		strDomesticName = '';
		try{
			lstCountryName.clear();
			lstDomesticName.clear();
			strSingleWord = 'a_'.equalsIgnoreCase(strSelectedCountry) && String.isBlank(strSingleWord) ? 'A' : strSingleWord;
			Set<String> setCountryName = mapCountry.get(strSingleWord);
			lstCountryName.addAll(setCountryName);
			lstCountryName.sort();
		}catch(Exception ex){
			system.debug('Exception == ' + ex.getMessage() + ex.getStackTraceString());
		}
		return null;
	}
	
	public PageReference getAlphaWiseRates(){
		try{
			lstCountryName.clear();
			lstDomesticName.clear();
			strDomesticName = '';
			Set<String> lNames = mapCountry.get(strSingleWord);
			lstCountryName.addAll(lNames);
			lstCountryName.sort();
		}catch(Exception ex){
			system.debug('Exception == ' + ex.getMessage() + ex.getStackTraceString());
		}
		return null;
	}
	
	public PageReference getCountryWiseRates(){
		try{
			lstCountryName.clear();
			lstDomesticName.clear();
			strDomesticName = '';
			if('a_'.equalsIgnoreCase(strSelectedCountry)){
				strSingleWord = '';
				getAllInternationRates();
			}else{
				List<RatesWrapp> lstRW = mapInternationalRates.get(strSelectedCountry);
				if(lstRW != null && lstRW.size() > 0){
					Set<String> setCName = new Set<String>();
					for(RatesWrapp rwObj : lstRW){
						setCName.add(rwObj.countryName.toLowerCase().trim());
					}
					lstCountryName.addAll(setCName);
					lstCountryName.sort();
				}
			}
		}catch(Exception ex){
			system.debug('Exception == ' + ex.getMessage() + ex.getStackTraceString());
		}
		return null;
	}
	
	public PageReference getAllDomesticRates(){
		try{
			lstCountryName.clear();
			lstDomesticName.clear();
			strSelectedCountry = '';
			strSingleWord = '';
			if(String.isNotBlank(strDomesticName) && 'a_'.equalsIgnoreCase(strDomesticName)){
				for(String str : domesticSet){
					lstDomesticName.add(str.toLowerCase().trim());
				}
				lstDomesticName.sort();
			}
		}catch(Exception ex){
			system.debug('Exception == ' + ex.getMessage() + ex.getStackTraceString());
		}
		return null;
	}
	
	public PageReference getDomesticRates(){ 
		lstCountryName.clear();
		lstDomesticName.clear();
		strSelectedCountry = '';
		strSingleWord = '';
		try{
			if(String.isNotBlank(strDomesticName) && 'a_'.equalsIgnoreCase(strDomesticName)){
				getAllDomesticRates();
			}else{
				if(String.isNotBlank(strDomesticName)){
					lstDomesticName.add(strDomesticName);
				}
			}
		}catch(Exception ex){
			system.debug('Exception == ' + ex.getMessage() + ex.getStackTraceString());
		}
		return null;
	}
	
	public Boolean getShowInternationalResultPanel(){
		if(lstCountryName != null && lstCountryName.size() > 0){
			return true;
		}
		return false;
	}
	
	public Boolean getShowDomesticResultPanel(){
		if(lstDomesticName != null && lstDomesticName.size() > 0){
			return true;
		}
		return false;
	}
	
	private static List<List<String>> parseCSV(string contents, Boolean skipHeaders) {
		List<List<String>> allFields = new List<List<String>>();
		try{
	        contents = contents.replaceAll(',"""',',"DBLQT').replaceall('""",','DBLQT",');
	        contents = contents.replaceAll('""','DBLQT');
	        List<String> lines = new List<String>();
	        try {
	            lines = contents.split('\r');
	        } catch (System.ListException e) {
	            System.debug('Limits exceeded?' + e.getMessage());
	        }
	        Integer num = 0;
	        for(String line : lines) {
	            if (line.replaceAll(',','').trim().length() == 0) break;
	            List<String> fields = line.split(',');  
	            List<String> cleanFields = new List<String>();
	            String compositeField;
	            Boolean makeCompositeField = false;
	            for(String field : fields) {
	                if (field.startsWith('"') && field.endsWith('"')) {
	                    cleanFields.add(field.replaceAll('DBLQT','"').trim());
	                } else if (field.startsWith('"')) {
	                    makeCompositeField = true;
	                    compositeField = field.trim();
	                } else if (field.endsWith('"')) {
	                    compositeField += ',' + field;
	                    cleanFields.add(compositeField.replaceAll('DBLQT','"').trim());
	                    makeCompositeField = false;
	                } else if (makeCompositeField) {
	                    compositeField +=  ',' + field.trim();
	                } else {
	                    cleanFields.add(field.replaceAll('DBLQT','"').trim());
	                }
	            }
	            allFields.add(cleanFields);
	        }
	        if (skipHeaders && !Test.isRunningTest()) allFields.remove(0);
	    }catch(Exception ex){
			system.debug('Exception == ' + ex.getMessage() + ex.getStackTraceString());
		}
		return allFields; 
    }
    
	public class RatesWrapp{
		public String countryCode {get;set;}
		public String countryName {get;set;}
		public String domesticCode {get;set;}
		public String domesticName {get;set;}
		public String internationalType {get;set;}
		public String domesticType {get;set;}
		public String areaList {get;set;}
		public String rates {get;set;}
		
		public RatesWrapp(String countryCode, String countryName, String domesticCode, String domesticName, String internationalType, 
																			String domesticType, String areaList, String rates){
			this.countryCode = countryCode;
			this.countryName = countryName;
			this.domesticCode = domesticCode;
			this.domesticName = domesticName;
			this.internationalType = internationalType;
			this.domesticType = domesticType;
			this.areaList = areaList;
			this.rates = rates;
		}
	}
}