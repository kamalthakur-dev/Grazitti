global class Q_SetBestAnswer implements Database.Batchable<Id>,Database.AllowsCallouts,Database.Stateful{
    
    migr migrationImplObj=new migr();
    Map<Id , FeedComment> fi2BestCommentMap = new Map<ID , FeedComment>();
    public Q_SetBestAnswer (Map<Id , FeedComment> fi2BestCommentMap){
        this.fi2BestCommentMap = fi2BestCommentMap ; 
    }
    
    
    global Iterable<Id> start(Database.BatchableContext BC) {  
        return new List<Id> (fi2BestCommentMap.keySet());            
    }
    
    global void execute(Database.BatchableContext BC, List<Id> feedItemId) {
        Map<Id, FeedComment>fi2BestFeedComment = new Map<Id, FeedComment>();
        for(Id id : feedItemId){
            fi2BestFeedComment.put(id, fi2BestCommentMap.get(id));
        } 
        migrationImplObj.setBestAnswer(fi2BestFeedComment ); // marking best answer on the Feeditems  
                   
    }
        
    global void finish(Database.BatchableContext BC) {
            
    }

}