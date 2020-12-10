global class Q_MigrateUserfollowing implements  Database.Batchable<string>,Database.AllowsCallouts,Database.Stateful {
    NC_MigrationImplementation fetchObj = new NC_MigrationImplementation();
    
    Map<String, String> mapjiveId2followingUrl = new Map<String,String>();
    
    public Q_MigrateUserfollowing(Map<String, String> mapjiveId2followingUrl){
        this.mapjiveId2followingUrl = mapjiveId2followingUrl;
    }
    
    global Iterable<string> start(Database.BatchableContext BC) {
    
        List<string> idList = new List<string>();
        idList.addAll(mapjiveId2followingUrl.keySet());
        return idList;
   
    }
    
    global void execute(Database.BatchableContext BC, List<string> jiveIds) {
        Map<String, String> jiveId2followingUrl = new Map<String,String>();
        //List<EntitySubscription> entitySub2insert = new  List<EntitySubscription>();
        for(String id : jiveIds){
             if(mapjiveId2followingUrl != null && mapjiveId2followingUrl.keySet().contains(id)){
                jiveId2followingUrl.put(id , mapjiveId2followingUrl.get(id));
             } 
        }
        if(!jiveId2followingUrl.isEmpty()){
            fetchObj.getFollowingUsers(jiveId2followingUrl);
            //insert entitySub2insert;  
        }  
    }
    
    global void finish(Database.BatchableContext BC) {
    }
}