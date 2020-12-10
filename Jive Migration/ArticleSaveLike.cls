global class ArticleSaveLike implements Database.Batchable<string>,Database.AllowsCallouts,Database.Stateful{
    
    ArticleMigration migrationImplObj=new ArticleMigration();
    Map<string,sObject> likeUrl2sObj = new Map<string,sObject>();
    
    public ArticleSaveLike (Map<string,sObject> likeUrl2sObj){
        this.likeUrl2sObj = likeUrl2sObj; 
    }
    
    global Iterable<string> start(Database.BatchableContext BC) {    
        return new List<string> (likeUrl2sObj.keySet());  
    }
    
    global void execute(Database.BatchableContext BC, List<string> likeUrls) {
        List<vote> ArticleLikes2insert = new List<vote>();
        Map<string, sObject> likeUrl2AC = new Map<string, sObject>();
        for(string s : likeUrls){
            likeUrl2AC.put(s, likeUrl2sObj.get(s));
        }
        
        ArticleLikes2insert = (migrationImplObj.saveLike(likeUrl2AC));    
        if(ArticleLikes2insert != null && ArticleLikes2insert.size()> 0){
            migrationImplObj.insertrecords(ArticleLikes2insert);  
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        
    }
    
}