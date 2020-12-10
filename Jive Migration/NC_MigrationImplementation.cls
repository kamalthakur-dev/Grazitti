public class NC_MigrationImplementation {
 
    Jive_Administrator__c setting = Jive_Administrator__c.getValues('Url');       
    Map<String,Contact> gContactMap=new Map<String,Contact>();
    String communityUrl, NetworkScopeId, userProfileId, profileName , accountid, duplicateNiCkNameJiveId, duplicateNickNameSuffixValue;
    
    Map<String,String> name2TimeZoneValueMap=new Map<String, String>();
    
    List<User> employeeList = new List<User>();
    List<User> commUsers = new List<User>();
    Map<string, User> mapEmail2User = new Map<string, User>();
    Boolean isSandbox = false;
    List<string> noEmpProfiles = new List<string>();
    
    
    public NC_MigrationImplementation(){ 
        communityUrl = setting.CommunityUrl__c;    //'https://discussions.qualys.com/api/core/v3/';        
        NetworkScopeId = setting.NetworkId__c;  
        userProfileId = setting.UserProfileId__c;   
        profileName = setting.UserProfileName__c;    
        accountid = setting.Accountid__c;
        isSandbox = setting.isSandbox__c;
        duplicateNiCkNameJiveId = setting.Duplicate_NickName_Jive_Ids__c;
        duplicateNickNameSuffixValue = setting.Duplicate_NickName_suffix_Value__c;
        noEmpProfiles = setting.Non_Employee_Profile__c.split(',');
        name2TimeZoneValueMap = getTimeZoneMapping();
    }
    
    public Map<String, String> getTimeZoneMapping(){
        List<TimeZone_Mapping__mdt>timeZoneMappingList =[SELECT Label,TimeZone_Value__c from TimeZone_Mapping__mdt];
        Map<String,String> name2TimeZoneValueMap=new Map<String, String>();
        if(!timeZoneMappingList.isEmpty()){
            for(TimeZone_Mapping__mdt mdt:timeZoneMappingList){
                name2TimeZoneValueMap.put(mdt.Label.toLowerCase(), mdt.TimeZone_Value__c);
            }
        }
        return name2TimeZoneValueMap;
    }
    
    public void getEMployeeOrCspUser(List<string> emailSet){
        List<string> eList = new List<string>();
        if(isSandbox ){
            for(string s : emailSet){
                s= s+'.invalid';
                eList.add(s);
            }
        }
        else{
            eList = emailSet;
        }
        system.debug('eList ----------'+eList );
        employeeList = [select id, Email, usertype, contactId, contact.Merge_With_CSP_User__c from User where email != null and email in : eList and isactive = true];
        for(user u : employeeList){ 
            String email = u.Email;
            if(email.containsIgnoreCase('invalid')){
                email = email.substring(0, email.length()-8);
            }                      
            //mapEmail2User.put(email, u);
            if(u.usertype == 'Standard'){                  
                mapEmail2User.put(email, u);
            }
            else if(u.usertype != 'Standard' && !mapEmail2User.containsKey(email)){
                mapEmail2User.put(email, u);
            }
        }         
    }
    
    public userWrapper getSelfData( Map<string,String> selfUrlMap, List<string> emailSet){
        List<string> privateProfwithDupNname = new List<string>();
        if(string.isNotBlank(setting.Jive_User_Ids__c)){
            if(setting.Jive_User_Ids__c.contains(',')){
                privateProfwithDupNname = setting.Jive_User_Ids__c.split(',');
            }else{
                privateProfwithDupNname.add(setting.Jive_User_Ids__c);
            }
        }
        List<Account> accountToBeInserted = new List<Account>();
        List<Contact> contactToBeCreatedList=new List<Contact>();
        List<Error_Log__c>errorLogList = new List<Error_Log__c>();
        Map<string, string> jiveId2ImageUrlMap = new Map<string, string>();
        Map<String, String> jiveId2followingUrlMap = new Map<String,String>();
        Map<String, Integer> jiveId2PointsMap = new Map<String, Integer>();
        profilePrivacy obj = new profilePrivacy();
        
        userWrapper usrWrap = new userWrapper();
        List<User> usrList=new List<User>();
        List<user> users2Insert = new List<user>();
        List<selfJson> selFJsonList = new List<selfJson>();
        List<user> updateExistingUsers = new List<user>();
 
        getEMployeeOrCspUser(emailSet);
        
        for(string s:selfUrlMap.KeySet()){
            HttpRequest req= new HttpRequest();
            Http http = new Http();
            req.setMethod('GET');
            req.setEndpoint(selfUrlMap.get(s));    
            req.setHeader('Authorization', 'Basic Z2F1cmF2YjpTRkRDTWlncmF0aW9u');
            HttpResponse res = http.send(req);
            
            if(res.getStatusCode() == 200){            
                String jsonstr =  res.getBody().replace('\n','');                
                selfJson wrapperinstance=(selfJson ) selfJson.parse(jsonstr);
                selFJsonList.add(wrapperinstance);
            }
            else{
                if(res.getBody().contains('error')){
                    UserErrorWrapper errWrapper  = (UserErrorWrapper ) UserErrorWrapper.parse(res.getBody());
                    Error_Log__c log = new Error_Log__c();
                    log.Type__c = 'User';
                    log.Name = 'USER- API ERROR';
                    log.Error_Description__c = errWrapper.error.code + '-' +errWrapper.error.message;
                    errorLogList.add(log); 
                }
            }
            
        }
        
        //Before going to next block , we need to determine the Name is Public or not 
        system.debug('selFJsonList-----------'+selFJsonList);
        for(selfJson s : selFJsonList){
            system.debug('s-----------'+s);
            if(s != null && s.resources != null ){
                if(s.resources.profilePrivacy != null  &&  s.resources.profilePrivacy.ref != null ){
                     obj = getUserProfileVisibility(s.resources.profilePrivacy.ref);
                     for(profilePrivacy.list_Z u :  obj.list_Z){
                        if(u.id == '@name'){
                            if(u.visibility.toLowerCase() == 'public'){
                                s.isProfilePublic =  true;
                            }else{
                                s.isProfilePublic = false;
                            } 
                        }
                        else if(u.id == '1'){
                            if(u.visibility.toLowerCase() == 'public'){
                                s.isCompanyPublic =  true;
                            }else{
                                s.isCompanyPublic =  false;
                            }          
                        }else if(u.id == '2'){
                            s.titlePrivacy = u.visibility;
                        }else if(u.id == '3'){
                             s.phonePrivacy = u.visibility;   
                        }
                    }  
                }
                jiveId2ImageUrlMap.put(s.id , s.resources.avatar.ref);
                jiveId2followingUrlMap.put(s.id , s.resources.following.ref);
                jiveId2PointsMap.put(s.id , s.jive.level.points);
            }
        }
        //upto here 
        
        for(selfJson s : selFJsonList){ 
            System.debug('s.emails[0].value -------------'+s.emails[0].value );
            System.debug('mapEmail2User-------------'+mapEmail2User);
           if(s != null && s.emails != null && s.emails[0] != null && s.emails[0].value != null && (!mapEmail2User.containsKey(s.emails[0].value) || (mapEmail2User.containsKey(s.emails[0].value) && mapEmail2User.get(s.emails[0].value).contactId != null && !mapEmail2User.get(s.emails[0].value).contact.Merge_With_CSP_User__c)) ){               
                Contact c=new Contact();
                c.AccountId = accountId ; 
                c.email=s.emails[0].value;
                c.firstName=s.name.givenName;
                c.LastName=s.name.familyName;                    
                contactToBeCreatedList.add(c);             
                        
                User usrObj = createUser(s,privateProfwithDupNname);
                usrList.add(usrObj);                   
           }
           // Else if handles the scenarion , if the user found but its an employee, so Image will not be replaced.
           else if(s != null && s.emails != null && s.emails[0] != null && s.emails[0].value != null && mapEmail2User.containsKey(s.emails[0].value)){
               user u = new user();
               u.id = mapEmail2User.get(s.emails[0].value).id;
               u.jive_Id__c = s.id;
               u.JiveUserName__c = s.mentionName;
               if(jiveId2ImageUrlMap.containsKey(s.id)){
                   jiveId2ImageUrlMap.remove(s.id); // Now profile picture for the existing users
               }
               
               if(s.isProfilePublic){
                   u.CommunityNickname = s.displayName;
                }
                else{
                    u.CommunityNickname = s.mentionName;
                }     
                if(!privateProfwithDupNname.isEmpty() && privateProfwithDupNname.contains(s.id)){
                    u.CommunityNickname = u.CommunityNickname.deleteWhitespace();
                }  
               
               if(mapEmail2User.get(s.emails[0].value).contactId != null){
                    if(s.titlePrivacy != null){
                        if(s.titlePrivacy.toLowerCase() == 'public'){
                            u.UserPreferencesShowTitleToGuestUsers = true;
                        }else if(s.titlePrivacy.toLowerCase() != 'registered'){
                            u.UserPreferencesShowTitleToExternalUsers = false;
                        }
                    }
                    
                     if(s.phonePrivacy != null){
                        if(s.phonePrivacy.toLowerCase() == 'public'){
                            u.UserPreferencesShowWorkPhoneToGuestUsers = true;
                        }else if(s.phonePrivacy.toLowerCase() == 'registered'){
                            u.UserPreferencesShowWorkPhoneToExternalUsers = true;
                        }
                    }
                    
               }
               if(s != null && s.Jive !=null && s.Jive.profile != null && s.Jive.profile.size() > 0){ 
                   for(Integer j=0;j<s.Jive.profile.size();j++){
                       if(s.Jive.profile.get(j).jive_label != null && s.Jive.profile.get(j).jive_label.toLowerCase() == 'company'){
                           if(mapEmail2User.get(s.emails[0].value).contactId == null){
                                 if(s.isCompanyPublic){
                                    u.CompanyName = s.Jive.profile.get(j).value;
                                    u.Company_Name__c = s.Jive.profile.get(j).value;
                                }
                           }
                       break;
                       }
                   }
               }
               //u.communitynickname = ''; // to be finalised with Qualys Team
               //u.Community_Join_Date__c = ''; // to be finalised
               updateExistingUsers.add(u);
           }
        }
         
         if(!contactToBeCreatedList.isEmpty()){            
            Database.SaveResult[] recordList = Database.insert(contactToBeCreatedList, false);
            
            for(integer i=0; i<contactToBeCreatedList.size() ;i++){
                if(!recordList[i].isSuccess()){
                    for (Database.Error e : recordList[i].getErrors()){                                                     
                        Error_Log__c log = new Error_Log__c();
                        log.Type__c = 'User';
                        log.Name = 'ContactInsert';
                        log.Jive_Id__c = contactToBeCreatedList[i].email;
                        log.Error_Description__c = e.getMessage();
                        errorLogList.add(log); 
                    }
                }
            }
            
            for(Contact c:contactToBeCreatedList){
                if(c.email != null){
                    gContactMap.put(c.email , c);
                 }
             }
            if(!errorLogList.isEmpty()){
                insert errorLogList;
            }  
         }         
         
         if(!usrList.isEmpty()){
             for(User u : usrList){
                 string email = u.email;
                 if(isSandbox){
                     email = email.substring(0, email.length()-8);
                 }
                 if(gContactMap.containsKey(email)){
                    u.contactid = gContactMap.get(email).Id;
                    users2Insert.add(u);                
                 }
             }             
        }
        
         usrWrap.users2Insert = users2Insert;
         usrWrap.users2Update= updateExistingUsers;
         usrWrap.jiveId2ImageUrlMap = jiveId2ImageUrlMap;
         usrWrap.jiveId2followingUrlMap = jiveId2followingUrlMap;
         usrWrap.jiveId2PointsMap = jiveId2PointsMap;
         return usrWrap;
    }
    
    public profilePrivacy getUserProfileVisibility(string profilePrivacyUrl){
        
        HttpRequest req= new HttpRequest();
        Http http = new Http();
        req.setMethod('GET');
        req.setHeader('Authorization', 'Basic Z2F1cmF2YjpTRkRDTWlncmF0aW9u');
        req.setEndpoint(profilePrivacyUrl);
        HttpResponse res = http.send(req);  
        String temp =  res.getBody();
        profilePrivacy wrapperinstance = profilePrivacy.parse(temp); 
        return wrapperinstance;        
     }
     
     
     public User createUser(selfJson wi, List<string> privateProfwithDupNname){
       
        User usrObj = new User();
        usrObj.Jive_Id__c=wi.id;
        string mentName = '';
        if(wi.mentionName.startsWith('@'))
        {
            mentName = wi.mentionName.substring(1,wi.mentionName.length());
        }
        else if(wi.mentionName.contains('@')){
            mentName = wi.mentionName.split('@')[0];
        }       
        else
        {
            mentName = wi.mentionName;
        }
        
        usrObj.Username=mentName+'@community.qualys.com'; // setting username on independent accounts

        if(isSandbox){
            usrObj.Email = wi.emails[0].value+'.invalid' ; 
        }
        else{
            usrObj.Email = wi.emails[0].value;
        }
        usrObj.firstName = wi.name.givenName;
        usrObj.LastName = wi.name.familyName;   
        if(wi.isProfilePublic){
            usrObj.CommunityNickname = wi.displayName;
            if(wi.id == '4588'){
                usrObj.CommunityNickname = wi.mentionName;
            }
        }
        else{
            usrObj.CommunityNickname = wi.mentionName;
        }  
        if(wi != null && String.isNotBlank(wi.mentionName)){
            usrObj.JiveUserName__c = wi.mentionName;
        }
        if(!privateProfwithDupNname.isEmpty()&& privateProfwithDupNname.contains(wi.id)){
            usrObj.CommunityNickname = usrObj.CommunityNickname.deleteWhitespace();
         }       
         
        
        if(wi.id != null &&  duplicateNiCkNameJiveId != null && duplicateNiCkNameJiveId.equals(wi.id) && usrObj.CommunityNickname != null){
             if(usrObj.CommunityNickname.contains(' ')){
                 List<String> splitString = usrObj.CommunityNickname.split(' ');
                 if(!splitString.isEmpty()){
                     if(splitString.size() > 0){
                         usrObj.CommunityNickname = splitString[0]+duplicateNickNameSuffixValue+splitString[0];
                     }else{
                         usrObj.CommunityNickname = splitString[0];
                     }
                 }
             }else{
                 usrObj.CommunityNickname += usrObj.CommunityNickname+'.';
             }
        }
        
        if(wi.Jive !=null && wi.Jive.profile != null && wi.Jive.profile.size() > 0){           
            for(Integer j=0;j<wi.Jive.profile.size();j++){
                if(wi.Jive.profile.get(j).jive_label != null){
                    if(wi.Jive.profile.get(j).jive_label != null && wi.Jive.profile.get(j).jive_label.toLowerCase() == 'occupation'){
                        string str = wi.Jive.profile.get(j).value;
                        if(str.length() > 80){
                            usrObj.title = str.substring(0,79);
                        }
                        else{
                            usrObj.title = str;
                        }
                    }  
                    else if(wi.Jive.profile.get(j).jive_label.toLowerCase() == 'company'){
                        if(wi.isCompanyPublic){
                            usrObj.CompanyName = wi.Jive.profile.get(j).value;
                            usrObj.Company_Name__c = wi.Jive.profile.get(j).value;
                        }
                        /*else{
                            usrObj.Company_Name__c = wi.Jive.profile.get(j).value;
                        }*/
                        
                    }else if(wi.Jive.profile.get(j).jive_label.toLowerCase() == 'biography' && wi.Jive.profile.get(j).value != null &&  wi.Jive.profile.get(j).value != ''){
                        if(usrObj.AboutMe != null && usrObj.AboutMe != ''){
                            usrObj.AboutMe = wi.Jive.profile.get(j).value + usrObj.AboutMe;
                        }else{
                            usrObj.AboutMe = wi.Jive.profile.get(j).value;
                        }
                    }else if(wi.Jive.profile.get(j).jive_label.toLowerCase() == 'expertise' && wi.Jive.profile.get(j).value != null &&  wi.Jive.profile.get(j).value != ''){
                        usrObj.AboutMe += '\nExpertise: ' + wi.Jive.profile.get(j).value;
                    }
                }  
            }
        }
        Integer maxSize = 1000;
        if(usrObj.AboutMe != null && usrObj.AboutMe.length() > maxSize ){
            usrObj.AboutMe= usrObj.AboutMe.substring(0, maxSize);
        }
        if(wi.titlePrivacy != null){
            if(wi.titlePrivacy.toLowerCase() == 'public'){
                usrObj.UserPreferencesShowTitleToGuestUsers = true;
            }else if(wi.titlePrivacy.toLowerCase() != 'registered'){
                usrObj.UserPreferencesShowTitleToExternalUsers = false;
            }
        }
        
        if(wi.phonePrivacy != null){
            if(wi.phonePrivacy.toLowerCase() == 'public'){
                usrObj.UserPreferencesShowWorkPhoneToGuestUsers = true;
            }else if(wi.phonePrivacy.toLowerCase() == 'registered'){
                usrObj.UserPreferencesShowWorkPhoneToExternalUsers = true;
            }
        }
        
        if(wi.phoneNumbers != null && wi.phoneNumbers[0].value != null){
            usrObj.Phone = wi.phoneNumbers[0].value;
        }
                
        if(wi.name.formatted!=null){
            if(wi.name.formatted.length()>8){
                usrObj.Alias = wi.name.formatted.substring(0,7);
            }else{
                usrObj.Alias = wi.name.formatted;
            }
        }                 
        
        usrObj.LocaleSidKey ='en_US';
        usrObj.LanguageLocaleKey = 'en_US'; 
        
        if(wi.Jive.timeZone != null){      
            if(!name2TimeZoneValueMap.isEmpty() && name2TimeZoneValueMap.containsKey(wi.Jive.timeZone.toLowerCase()) && name2TimeZoneValueMap.get(wi.Jive.timeZone.toLowerCase()) != null){
                usrObj.TimeZoneSidKey = name2TimeZoneValueMap.get(wi.Jive.timeZone.toLowerCase());  
            }else{
                TimeZone tz = TimeZone.getTimeZone(wi.Jive.timeZone);
                IF(tz != null){
                    usrObj.TimeZoneSidKey = tz.getID();
                }
            }
        }
        
        //usrObj.TimeZoneSidKey = 'GMT';      
        usrObj.EmailEncodingKey = 'ISO-8859-1';
        usrObj.ProfileId = userProfileId;
        //usrObj.Community_Join_Date__c   = Date.valueOf(wi.published); 
        usrObj.Community_Join_Date__c   = QualysUtils.formatDateValue(wi.published); 
        usrObj.UserPreferencesShowProfilePicToGuestUsers = true;
        return usrObj;
    }
    
    public userInsertWrapper insertRecords(List<user> recordToBeInserted ){
        userInsertWrapper usrWrapper = new userInsertWrapper();
        usrWrapper.errLogList = null;
        usrWrapper.adminSettingsUpdate = null;
        List<Error_Log__c> errorLogList = new List<Error_Log__c>();
        String dupNameUserIds = '';
        if(Test.isRunningTest()){dupNameUserIds = '2324343';}
        Database.upsertResult[] recordList = Database.upsert(recordToBeInserted , false);        
        
        for(integer i=0; i<recordToBeInserted.size() ;i++){
            if(!recordList[i].isSuccess()){
                for (Database.Error e : recordList[i].getErrors()){                                                     
                    Error_Log__c log = new Error_Log__c();
                    log.Type__c = 'User';
                    log.Name = 'UserInsert';
                    log.Jive_Id__c = recordToBeInserted[i].jive_id__c;
                    log.Error_Description__c = e.getMessage();
                    errorLogList.add(log); 
                    if(e.getMessage() != null && (e.getMessage().containsIgnoreCase('Duplicate Nickname'))){
                        if(String.isNotBlank(dupNameUserIds)){
                            dupNameUserIds += ','+recordToBeInserted[i].jive_id__c;
                        }else{
                            dupNameUserIds = recordToBeInserted[i].jive_id__c;
                        }
                    }
                }
            }
            
        }
        if(String.isNotBlank(dupNameUserIds)){
            Jive_Administrator__c adminSetting = Jive_Administrator__c.getInstance('Url');
            if(adminSetting != null){
                adminSetting.Jive_User_Ids__c = dupNameUserIds;
                usrWrapper.adminSettingsUpdate= adminSetting;
            }
        }
        if(!errorLogList.isEmpty()){
            usrWrapper.errLogList = errorLogList;    
        }
        return usrWrapper; 
    }
    
    public class userInsertWrapper{
        public List<Error_Log__c> errLogList{get;set;}
        public Jive_Administrator__c adminSettingsUpdate{get;set;}
    }
    public List<ContentVersion> fetchUserImage( Map<String,String> imgUrlMap){ 
        List<ContentVersion> cntVersionList = new List<ContentVersion>();
 
        for(String s:imgUrlMap.keySet()){
            HttpRequest req1= new HttpRequest();
            Http http1 = new Http();
            req1.setMethod('GET');
            req1.setEndpoint(imgUrlMap.get(s));
            HttpResponse res1 = http1.send(req1);
            Blob bodyBlob = res1.getBodyAsBlob();    
                      
            ContentVersion cv=new ContentVersion();
            cv.Title='avatar-'+s;           
            cv.SharingOption = 'A';
            cv.ContentLocation = 'S';
            cv.PathOnClient ='/' + cv.Title+'.png';
            String temp = EncodingUtil.base64Encode(bodyBlob);
            cv.VersionData = EncodingUtil.base64Decode(temp);
            cv.NetworkId = NetworkScopeId;
            cntVersionList.add(cv); 
        }
        if(!Test.isrunningTest()){
            insert cntVersionList;
        }
        return cntVersionList;
    }
    
    public void getFollowingUsers(Map<String,String> jiveId2followingUrlMap) {
        String jsonstr = null;
        Map<String,Set<String>> jiveId2SetOfJiveId = new  Map<String,Set<String>>();
        
        for(String s : jiveId2followingUrlMap.keySet()) {
            string followerlinks = jiveId2followingUrlMap.get(s);
            system.debug('followerlinks ------------'+followerlinks );
            List<UserList.items> jiveUsers = new List<UserList.items>();
            while(followerlinks != null) {
                HttpRequest req= new HttpRequest();
                Http http = new Http();
                req.setMethod('GET');
                req.setEndpoint(followerlinks);      
                HttpResponse res = http.send(req);
                String temp =  res.getBody();
                jsonstr = temp.replace('list','items');
                
                if(jsonstr != null && jsonstr != '') {
                    UserList wrapperinstance=(UserList) System.JSON.deserialize(jsonstr,UserList.class);
                    if(wrapperinstance.items != null && wrapperinstance.items.size()>0){
                        jiveUsers.addAll(wrapperinstance.items);
                    }                    
 
                    if(wrapperinstance.links != null && wrapperinstance.links.next != null) {                   
                        followerlinks = wrapperinstance.links.next;
                    }
                    else {
                        followerlinks = null;
                    }                   
 
                }                                
            }   
            if(jiveUsers != null && jiveUsers.size() > 0){               
 
                for(Integer j=0;j<jiveUsers.size();j++){
                    if(jiveId2SetOfJiveId.containsKey(s)){
                        Set<String> usersId = jiveId2SetOfJiveId.get(s);
                        usersId.add(jiveUsers.get(j).id);
                        jiveId2SetOfJiveId.put(s,usersId);                       
                    } 
                    else {
                        jiveId2SetOfJiveId.put(s, new Set<String> { jiveUsers.get(j).id });
                    }  
                } 
            }
        }
                                                        
        List<User> user2Update = new List<User>();
        List<User> userList = [Select id,Jive_Id__c from User where Jive_Id__c in :jiveId2SetOfJiveId.keySet() and isActive = true];
        for(User u:userList ){
            if(u.Jive_Id__c != null && jiveId2SetOfJiveId.containsKey(u.Jive_Id__c)){
                String str = '';
                for(string s : jiveId2SetOfJiveId.get(u.Jive_Id__c)){
                    if(str == ''){
                        str = s; 
                    }
                    else{
                        str = str + '-'+ s;
                    }
                }
                if(str != null){
                    user us = new user(id = u.id, FollowerUserJiveIds__c = str);
                    user2Update.add(us);
                }
            }           
        }
        update user2Update;
    }
    
    public Map<string,Id> getUserId(){
         Map<string,Id>jiveIdMapToUserId=new Map<string,Id>();
         for(User u: [Select id , jive_id__c , Profile.name from user where Profile.name =: profileName]){
                 jiveIdMapToUserId.put(u.jive_id__c,u.id);
         }         
         return jiveIdMapToUserId;
     }
     
     public List<User_Emails__c> getJiveUserEmails(string uEmail){
         List<User_Emails__c> userEmailList = new List<User_Emails__c>();
         if(uEmail != null && uEmail != ''){
             userEmailList = [select id, Email__c from User_Emails__c where Email__c =: uEmail and To_Process__c = True and isProcessed__c = False];    
         } 
         else{
             userEmailList = [select id, Email__c from User_Emails__c where To_Process__c = True and isProcessed__c = False];
         }
         return userEmailList;     
     }
    
}