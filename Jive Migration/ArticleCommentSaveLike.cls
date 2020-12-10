global class ArticleCommentSaveLike implements Database.Batchable<string>,Database.AllowsCallouts,Database.Stateful{
    ArticleMigration articleObj = new ArticleMigration();
    Map<string,Article_Comment__c> LikeUrl2ArticleComment = new Map<string,Article_Comment__c>();
    
    
    public ArticleCommentSaveLike (Map<string, Article_Comment__c> LikeUrl2ArticleComment ){
        this.LikeUrl2ArticleComment = LikeUrl2ArticleComment ; 
    }
    
    global Iterable<string> start(Database.BatchableContext BC) {    
        return new List<string> (LikeUrl2ArticleComment.keySet());  
    }
    
    global void execute(Database.BatchableContext BC, List<string> commentLikeUrls) {
        List<Article_Comment_Likes__c> articleCommentLike2insert = new List<Article_Comment_Likes__c>();
        List<Article_Comment_Likes__c> finalArticleCommentLike2insert = new List<Article_Comment_Likes__c>();
        Set<Article_Comment_Likes__c> temp = new set<Article_Comment_Likes__c>();
        Map<string, Article_Comment__c> likeUrl2AC = new Map<string, Article_Comment__c>();
        for(string s : commentLikeUrls){
            likeUrl2AC.put(s, LikeUrl2ArticleComment.get(s));
        }
        
         articleCommentLike2insert.addAll(articleObj.saveArticleCommentLike(LikeUrl2ArticleComment));
          temp.addAll(articleCommentLike2insert);
          finalArticleCommentLike2insert.addAll(temp);
        if( finalArticleCommentLike2insert!= null &&  finalArticleCommentLike2insert.size()> 0){
            articleObj.insertrecords(finalArticleCommentLike2insert);  
            finalArticleCommentLike2insert.clear();
        }
                       
    }
        
    global void finish(Database.BatchableContext BC) {
            
    }

}