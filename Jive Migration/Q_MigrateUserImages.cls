global class Q_MigrateUserImages implements Database.Batchable<string>,Database.AllowsCallouts,Database.Stateful{
    
    Jive_Administrator__c setting = Jive_Administrator__c.getValues('Url');
    NC_MigrationImplementation migrationImplObj=new NC_MigrationImplementation();   
    Map<String,string> mapJiveID2ImageUrl=new  Map<String,string>();
    List<ContentVersion> filesList = new List<contentversion>();
    List<User> userstoAssignProfilePic = new List<User>();
    string NetworkScopeId;
    
    public Q_MigrateUserImages(){
        NetworkScopeId = setting.NetworkId__c; 
    }
    
    public Q_MigrateUserImages(Map<String,string> mapJiveID2ImageUrl){
        this.mapJiveID2ImageUrl=mapJiveID2ImageUrl; 
    }
    
    global Iterable<String> start(Database.BatchableContext BC) { 
        List<String> idList = new List<String>();
        idList.addAll(mapJiveID2ImageUrl.keySet());
        return idList;
    }
            
    global void execute(Database.BatchableContext BC,  List<string> jiveIds) {
    
        List<ContentVersion> cvList = new List<ContentVersion>();
        List<String> cntVersionIds=new List<String>();
        Map<string, string> cntDocIdMap=new Map<string, string>();
        
        Map<String,string> JiveID2ImageUrl = new  Map<String,string>();
        for(string s: jiveIds){
            JiveID2ImageUrl.put(s, mapJiveID2ImageUrl.get(s));
        }
        userstoAssignProfilePic = [select id, jive_id__c from user where jive_id__c in :jiveIds ];  
                       
        cvList = migrationImplObj.fetchUserImage(JiveID2ImageUrl);
        
        for(contentversion cv:cvList){
            cntVersionIds.add(cv.id);
        }   
        filesList = [select Id, ContentUrl, ContentDocumentId, Title FROM ContentVersion where id IN:cntVersionIds];
    
        Map<String, ID> mapJiveId2FileId = new Map<String, ID>();
        for(ContentVersion cv : filesList){
            if(cv.title != null){
                List<string> titleSplit = cv.title.split('-');
                mapJiveId2FileId.put(titleSplit[1], cv.ContentDocumentId);
                cntDocIdMap.put(cv.Id, cv.ContentDocumentId);
            }
        }
        
        QualysUtils qUtil = new QualysUtils();
        qUtil.ShareFilesWithLibraries(cntVersionIds, cntDocIdMap);
        
        for(User u : userstoAssignProfilePic){

            if(u.jive_id__c != null && mapJiveId2FileId != null && mapJiveId2FileId.containsKey(u.jive_id__c)){
             if(!Test.isRunningTest()){  
                       ConnectApi.UserProfiles.setPhoto(NetworkScopeId, u.Id, mapJiveId2FileId.get(u.jive_id__c), null);
               }               
            }
        }                       
    }
     
    global void finish(Database.BatchableContext BC) {
            
    }
}