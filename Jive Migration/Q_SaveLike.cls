global class Q_SaveLike implements Database.Batchable<string>,Database.AllowsCallouts,Database.Stateful{
    //NC_MigrationImplementation migrationImplObj=new NC_MigrationImplementation();
    migr migrationImplObj=new migr();
    Boolean isFeedComment= false;
    Map<string,sObject> likeUrl2sObj = new Map<string,sObject>();
    
    
    public Q_SaveLike (Map<string,sObject> likeUrl2sObj, boolean isFeedComment){
        this.likeUrl2sObj = likeUrl2sObj; 
        this.isFeedComment = isFeedComment;
    }
    
    global Iterable<string> start(Database.BatchableContext BC) {    
        return new List<string> (likeUrl2sObj.keySet());  
    }
    
    global void execute(Database.BatchableContext BC, List<string> likeUrls) {
        List<FeedLike> feedLikes2insert = new List<FeedLike>();
        Map<string, sObject> likeUrl2FC = new Map<string, sObject>();
        for(string s : likeUrls){
            likeUrl2FC.put(s, likeUrl2sObj.get(s));
        }
        
        feedLikes2insert = (migrationImplObj.saveLike(likeUrl2FC, isFeedComment));
        System.debug('feedLikes2insert +++++++ ' + feedLikes2insert.size() + 'fhdfiuifhi++ '+ feedLikes2insert);     
        if(feedLikes2insert != null && feedLikes2insert.size()> 0){
            migrationImplObj.insertrecords(feedLikes2insert);  
        }
                       
    }
        
    global void finish(Database.BatchableContext BC) {
            
    }

}