global class ArticleCommentMigration  implements Database.Batchable<string>,Database.AllowsCallouts,Database.Stateful{
   
    List<Article_Comment__c>articleList = new List <Article_Comment__c>();
    Map<String, Knowledge__kav> commentUrl2ArticleMap = new Map<String, Knowledge__kav>();
    ArticleMigration instance = new ArticleMigration();
    public ArticleCommentMigration (Map<String, Knowledge__kav> commentUrl2ArticleMap ){
        this.commentUrl2ArticleMap = commentUrl2ArticleMap; 
    }
    
    global Iterable<string> start(Database.BatchableContext BC) {    
        return new List<string> (commentUrl2ArticleMap.keySet());  
    }
    
    global void execute(Database.BatchableContext BC, List<string> articleCommentUrl) {
        
        Map<String, Knowledge__kav> commentUrl2Article = new Map<String, Knowledge__kav>();
        for(string s : articleCommentUrl){
            commentUrl2Article.put(s, commentUrl2ArticleMap.get(s));
        }
        articleList.addAll(instance.getArticleData(commentUrl2Article));                 
    }
        
    global void finish(Database.BatchableContext BC) {
        SaveImageForArticleComments s = new SaveImageForArticleComments(articleList);
        database.executeBatch(s , 50);      
    }

}