global class NC_getUsers implements  Database.Batchable<User_Emails__c>,Database.AllowsCallouts,Database.Stateful {
    NC_MigrationImplementation fetchObj = new NC_MigrationImplementation();
    Jive_Administrator__c setting = Jive_Administrator__c.getValues('Url');       
    String communityUrl = setting.CommunityUrl__c; 
    String commNetworkId = setting.NetworkId__c;
    
    userWrapper uWrap = new userWrapper();
    List<User> usrList = new List<User>();
    List<User_Emails__c> userEmailList = new List<User_Emails__c>();
    set<string> newUsrJiveIds = new set<string>();
    
    Map<string,Id> jiveId2UserIDMap = new Map<string,Id>();
    Map<string, string> jiveId2ImageUrlMap = new Map<string, string>();
    Map<String, String> jiveId2followingUrlMap = new Map<String,String>();
    Map<String, Integer> jiveId2PointsMap = new Map<String, Integer>();
    String emailOrJiveId = '';
    
    public NC_getUsers(String emailOrJiveId){ 
       jiveId2UserIDMap = fetchObj.getUserId();
       this.emailOrJiveId = emailOrJiveId;
    }
    
    global Iterable<User_Emails__c> start(Database.BatchableContext BC) {
        
        userEmailList = fetchObj.getJiveUserEmails(emailOrJiveId);                        
        return userEmailList;
    }
    
    global void execute(Database.BatchableContext BC, List<User_Emails__c> emailList) {
        Map<string,String> selfUrlMap=new Map<string,String>();
        String selfUrl;
        List<string> emailSet = new List<string>();
        if(emailOrJiveId == null || emailOrJiveId == ''){
            selfUrl = communityUrl + 'people/email/'; //'https://discussions.qualys.com/api/core/v3/' + 'people/email/';   
                    
            for(User_Emails__c e : emailList){             
                selfUrlMap.put(e.email__c,selfUrl+e.email__c); 
                emailSet.add(e.email__c);           
            }
        } else{
            //if(Pattern.matches('[a-zA-Z0-9._-]+@[a-zA-Z]+.[a-zA-Z]{2,4}', emailOrJiveId)){
                selfUrl = communityUrl + 'people/email/';
                selfUrlMap.put(emailOrJiveId, selfUrl + emailOrJiveId);  
                emailSet.add(emailOrJiveId);
            //}
        } 
        
        system.debug('111111111111' + emailSet + emailSet.size());  
        system.debug('111111111111' + selfUrlMap + selfUrlMap.size());              
        uWrap = fetchObj.getSelfData(selfUrlMap, emailSet); 
        
      if(uWrap != null){
            if(uWrap.users2Insert != null && uWrap.users2Insert.size() > 0){
                usrList.addAll(uWrap.users2Insert);
                for(User a : uWrap.users2Insert){
                    if(a.jive_id__c != null){
                        newUsrJiveIds.add(a.jive_id__c);
                    }
                }
            }     
            if(uWrap.users2Update != null && uWrap.users2Update.size() > 0){
                usrList.addAll(uWrap.users2Update);
            } 
            if(uWrap.jiveId2ImageUrlMap != null && uWrap.jiveId2ImageUrlMap.keySet().size() > 0){
                jiveId2ImageUrlMap.putAll(uWrap.jiveId2ImageUrlMap);
            }     
            if(uWrap.jiveId2followingUrlMap != null && uWrap.jiveId2followingUrlMap.keySet().size() > 0){
                jiveId2followingUrlMap.putAll(uWrap.jiveId2followingUrlMap);
            }   
            if(uWrap.jiveId2PointsMap != null && uWrap.jiveId2PointsMap.keySet().size() > 0){
                jiveId2PointsMap.putAll(uWrap.jiveId2PointsMap);
            }   
        }                               
    }
    
    
    global void finish(Database.BatchableContext BC) {
        NC_MigrationImplementation.userInsertWrapper usrWrapper = new NC_MigrationImplementation.userInsertWrapper();
        List<Error_Log__c> userErrorLog = new List<Error_Log__c>();
        List<Jive_Administrator__c> adminSetting = new List<Jive_Administrator__c>();
        if(usrList != null && usrList.size() > 0){
              usrWrapper = fetchObj.insertRecords(usrList);
              if(usrWrapper != null){
                  if(usrWrapper.errLogList != null && usrWrapper.errLogList.size() > 0){
                      userErrorLog = usrWrapper.errLogList;
                  }  
                  if(usrWrapper.adminSettingsUpdate != null){
                      adminSetting.add(usrWrapper.adminSettingsUpdate);
                  }         
                  
              }
              system.debug('usrList Size () ' + usrList.size());                 
        }
       
        Map<Id,Integer>userId2ptsMap = new Map<Id,Integer>();
        Map<string, string> jiveId2ImageUrlMapFiltered = new Map<string, string>();
        Map<String, String> jiveId2followingUrlMapFiltered = new Map<String,String>();
        
        if(!usrList.isEmpty()){
            for(User u : usrList){
                if(u.Id != null || Test.isRunningTest()){
                    if(u.jive_id__c != null && jiveId2PointsMap != null && jiveId2PointsMap.keySet().size () > 0 && jiveId2PointsMap.containskey(u.jive_id__c)){
                        userId2ptsMap.put(u.id, jiveId2PointsMap.get(u.jive_id__c));    
                    }
                    if(newUsrJiveIds != null && newUsrJiveIds.contains(u.jive_id__c)){
                        jiveId2ImageUrlMapFiltered.put(u.jive_id__c, jiveId2ImageUrlMap.get(u.jive_id__c));
                    }
                    jiveId2followingUrlMapFiltered.put(u.jive_id__c,jiveId2followingUrlMap.get(u.jive_id__c));
                }
            }
        }
       List<NetworkMember> nMemeberList = [SELECT MemberId, NetworkId,ReputationPoints FROM NetworkMember WHERE MemberId in :userId2ptsMap.keySet() and NetworkId =: commNetworkId];
       List<NetworkMember> nMember2Update =  new List<NetworkMember>();
       for(NetworkMember nMember:nMemeberList ){
            nMember.ReputationPoints = userId2ptsMap.get(nMember.MemberId);
            nMember.PreferencesDisableAllFeedsEmail = true;
            nMember.PreferencesDisableEndorsementEmail = true;
            nMember.PreferencesDisableFollowersEmail= true;
            nMember.PreferencesDisableProfilePostEmail= true;
            nMember.PreferencesDisableItemFlaggedEmail = true;
            nMember.PreferencesDisablePendingReviewEmail =  true;
            nMember2Update.add(nMember);                 
       }
       update nMember2Update;
       

        if(userErrorLog != null && userErrorLog.size() > 0 && !userErrorLog.isEmpty()){
            NC_UserErrorLogInsert ErrorLog = new NC_UserErrorLogInsert(userErrorLog);
            database.executeBatch(ErrorLog, 50);                
        }
        
        if(adminSetting != null && adminSetting.size() > 0 && !adminSetting.isEmpty()){
            NC_AdminSettingUpdate adminSettings= new NC_AdminSettingUpdate(adminSetting);
            database.executeBatch(adminSettings, 50);                
        }
                   
        Q_MigrateUserImages bat = new Q_MigrateUserImages(jiveId2ImageUrlMapFiltered);
        database.executeBatch(bat,50);
        
        Q_MigrateUserfollowing  follo = new Q_MigrateUserfollowing(jiveId2followingUrlMapFiltered);
        database.executeBatch(follo, 50); 
    }  
}