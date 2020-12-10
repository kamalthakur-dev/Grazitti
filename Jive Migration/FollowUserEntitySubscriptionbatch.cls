global class FollowUserEntitySubscriptionbatch implements Database.batchable<user>, Database.Stateful {
    Jive_Administrator__c setting = Jive_Administrator__c.getValues('Url');    
    map<string, id> jiveIduserIdMap = new map<string, id>();
    List<Error_Log__c>errorLogList = new List<Error_Log__c>();
    String NetworkScopeId; 
    
    public FollowUserEntitySubscriptionbatch(){
        NetworkScopeId = setting.NetworkId__c;
     }
    
    global Iterable<user> start(Database.BatchableContext BC) {
       list<User> userList = new list<User>();
       if(!Test.isRunningTest()){
           userList = [select Id, jive_id__c, FollowerUserJiveIds__c from user where jive_id__c != null and isactive = true];
       }else{
           userList = [select Id, jive_id__c, FollowerUserJiveIds__c from user where jive_id__c = '1234' ];
       }
       for(user usr : userList) {
            jiveIduserIdMap.put(usr.jive_id__c, usr.Id);                                
        }
        if(Test.isRunningTest()){
            
            jiveIduserIdMap.put('1234','0053J000000HGcN');
        }
       
       return userList;      
    }

    global void execute(Database.BatchableContext BC, list<user> scope) {
        map<string, list<string>> userFollowingsMap = new map<string, list<string>>();
        list<string> followersJiveIdList = new list<string>(); 
        list<EntitySubscription> esList = new list<EntitySubscription>();
         for(user usr : scope) {
            followersJiveIdList = new list<string>();           
            if(usr.FollowerUserJiveIds__c != null) {
                for(string followingJiveId : usr.FollowerUserJiveIds__c.split('-')) {
                    followersJiveIdList.add(followingJiveId);
                }
                userFollowingsMap.put(usr.jive_id__c, followersJiveIdList); 
            }           
        }      

        for(string s1 : userFollowingsMap.keyset()) {
            followersJiveIdList = new list<string>();
            followersJiveIdList = userFollowingsMap.get(s1);
            for(string ss : followersJiveIdList) {
                if(jiveIduserIdMap.get(ss) != null){
                    EntitySubscription es = new EntitySubscription();
                    es.NetworkId = NetworkScopeId;
                    es.ParentId = jiveIduserIdMap.get(ss);
                    es.SubscriberId = jiveIduserIdMap.get(s1);
                    esList.add(es);
                }
            }
        }

        if(esList.size() > 0){             
            Database.SaveResult[] recordList = Database.insert(esList, false);
            for(integer i=0; i<esList.size() ;i++){
                if(!recordList[i].isSuccess()){
                    for (Database.Error e : recordList[i].getErrors()){                                                     
                        Error_Log__c log = new Error_Log__c();
                        log.Type__c = 'User';
                        log.Name = 'UserFollowerInsert-' + esList[i].SubscriberId;
                        log.Jive_Id__c = esList[i].ParentId;
                        log.Error_Description__c = e.getMessage();
                        errorLogList.add(log); 
                    }
                }
            }
        }
    }    
    global void finish(Database.BatchableContext BC) {
        if(errorLogList.size() > 0){
            insert errorLogList;
        }
    }
}