/*
Description : It's a generic class to validate Phone number format based on country from which it belongs.
Used : It is called from Account and Reseller request trgiger as well as from Lead "Smart Search" functionality.
*/

public class ValidationUtility {
    
    //Generic Method for Phone Number formating on Country and digit basis.
    public static String validatePhoneNumber(String phoneStr, String countryStr){
        String newPhoneFormat='';
        if(!String.isBlank(countryStr) && !String.isBlank(phoneStr)){
            if(('Great Britain'.equalsIgnoreCase(countryStr) || 'United Kingdom'.equalsIgnoreCase(countryStr) || 
                'GB'.equalsIgnoreCase(countryStr) || 'UK'.equalsIgnoreCase(countryStr))){
                String initialPhoneNum = ValidationUtility.checkPhoneContainsAlphabets(phoneStr);
                if(initialPhoneNum==''){
                    initialPhoneNum = phoneStr;  
                }  
                String strPhoneValue = ValidationUtility.extractIntegerFromPhone(initialPhoneNum);
                if(strPhoneValue!=''){  
                    if(strPhoneValue.trim().startsWith('0')){
                        newPhoneFormat = '+44' + strPhoneValue.trim().substring(1);
                    } else if(strPhoneValue.trim().startsWith('44')){                       
                        newPhoneFormat = '+44' + strPhoneValue.trim().substring(2);
                    } else {
                        newPhoneFormat = '+44' + strPhoneValue;
                    }
                }           
            } else {
                if('United States'.equalsIgnoreCase(countryStr) || 'USA'.equalsIgnoreCase(countryStr) ||
                   'U.S.A.'.equalsIgnoreCase(countryStr) || 'United States of America'.equalsIgnoreCase(countryStr) ||
                   'U.S.'.equalsIgnoreCase(countryStr) || 'US'.equalsIgnoreCase(countryStr) ||
                   'United States Minor Outlying Islands'.equalsIgnoreCase(countryStr) ||
                   'Canada'.equalsIgnoreCase(countryStr) || 'CA'.equalsIgnoreCase(countryStr)){
                    newPhoneFormat = ValidationUtility.commonUSandCAPhoneFormat(phoneStr);
                }
            }   
        }else if(String.isBlank(countryStr) && !String.isBlank(phoneStr)){          
            newPhoneFormat = ValidationUtility.commonUSandCAPhoneFormat(phoneStr);
        }   
        
        if(!String.isBlank(newPhoneFormat)){
            return newPhoneFormat;
        }else{
            return phoneStr;
        }
    }
    
    //Commom Phone Format for US/CA or if no Country available.
    public static string commonUSandCAPhoneFormat(string phoneStr){
        String newPhoneFormat = '';
        String initialPhoneNum = ValidationUtility.checkPhoneContainsAlphabets(phoneStr);
        if(initialPhoneNum==''){
            initialPhoneNum = phoneStr;  
        }  
        if(initialPhoneNum!=''){            
            if(ValidationUtility.regexCheckForUsPhone(initialPhoneNum)==true){                
                newPhoneFormat = initialPhoneNum;                
            }else{                
                String strPhoneValue = ValidationUtility.extractIntegerFromPhone(initialPhoneNum);
                newPhoneFormat = strPhoneValue; 
                if(strPhoneValue.trim().startsWith('0')){
                    strPhoneValue = strPhoneValue.trim().substring(1);
                }
                if(strPhoneValue.trim().length()==10){     
                    newPhoneFormat = '(' + strPhoneValue.trim().substring(0,3) + ') ' + strPhoneValue.trim().substring(3,6) + '-' + strPhoneValue.trim().substring(6);
                }else if(strPhoneValue.trim().length()==11 && strPhoneValue.trim().startsWith('1')) {
                    newPhoneFormat = '(' + strPhoneValue.trim().substring(1,4) + ') ' + strPhoneValue.trim().substring(4,7) + '-' + strPhoneValue.trim().substring(7);
                }
            }
        }
        return newPhoneFormat;
    }   
    
    //Check if Phone Number conatins any alphabet like (408-429-0847 ext 543). Returns Initial Number before extension(Text). 
    public static string checkPhoneContainsAlphabets(String strPhone){
        String initialPhoneNum = '';
        String alphaRegex = '[a-zA-Z]';
        Pattern MyPattern = Pattern.compile(alphaRegex);
        Matcher MyMatcher = MyPattern.matcher(strPhone);        
        if(MyMatcher.find()){
            initialPhoneNum = strPhone.substring(0,(MyMatcher.end()-1));
        }
        return initialPhoneNum;
    }
    
    //Fetch only integer value from Phone Number by removing any special character and return it.
    public static String extractIntegerFromPhone(String phoneStr){
        String numberRegEx = '\\d+\\.?\\d*|-\\d+\\.?\\d*|\\.?\\d+|-\\.?\\d+';
        Pattern MyPattern = Pattern.compile(numberRegEx);       
        Matcher MyMatcher = MyPattern.matcher(phoneStr);        
        String strExtracted = '';
        String replaceRegex = '[-+.^:,_/%&*()\\s+]';
        while (MyMatcher.find()) {  
            strExtracted+=MyMatcher.group().replaceAll(replaceRegex,'').trim(); 
        }
        return strExtracted;
    }
    
    //Regex check for US phone Format (XXX) XXX-XXXX.
    public static boolean regexCheckForUsPhone(String strPhone){ 
        String regExPhone = '^((\\(\\d{3}\\) )|(\\d{3}-))?\\d{3}-\\d{4}$';
        Pattern MyPattern = Pattern.compile(regExPhone);
        Matcher MyMatcher = MyPattern.matcher(strPhone);
        return MyMatcher.find();
    }
}