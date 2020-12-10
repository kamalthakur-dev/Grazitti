public class articleCommnetReferenceUrlChangeBatch implements Database.Batchable<Article_Comment__c>,  Database.Stateful{
    QualysUtils  referenceURlchange = new QualysUtils();
    
    String JiveId ;
    public articleCommnetReferenceUrlChangeBatch(String jiveId){
        this.JiveId =JiveId ; 
    }
    
     public Iterable<Article_Comment__c> start(Database.BatchableContext bc) { // To get Articles
        List<Article_Comment__c> ArticleComment = new List<Article_Comment__c>();
        if(String.isNotBlank(JiveId)){
            ArticleComment = [SELECT Id, Name, Content__c, Knowledge_Article__c, Parent_Comment__c, Path__c, Like_Count__c, like_url__c, Parent_Jive_Id__c, Article_Number__c, Jive_Id__c FROM Article_Comment__c where Jive_Id__c =: jiveId];
        }else{
            ArticleComment = [SELECT Id, Name, Content__c, Knowledge_Article__c, Parent_Comment__c, Path__c, Like_Count__c, like_url__c, Parent_Jive_Id__c, Article_Number__c, Jive_Id__c FROM Article_Comment__c];
        }
        return (ArticleComment);
    }
    public void execute(Database.BatchableContext bc, list<Article_Comment__c> scope){ 
        map<string,string> Content2Jiveid = new map<string,string>();
        map<string,string> Jiveid2articleContent = new map<string,string>();
        List<string> content = new List<string>();
        list<id> ids = new list<id>();
        for(Article_Comment__c Comment:scope){
            if(Comment.Content__c != null && Comment.Content__c.contains('/DOC-4029')){
                Comment.Content__c= Comment.Content__c.replace('/DOC-4029','/DOC-6356');
            }
            ids.add(Comment.id);
            Content2Jiveid.put(Comment.Content__c,Comment.Jive_Id__c);
        }
        system.debug('content===>'+Content2Jiveid);
        Jiveid2articleContent = referenceURlchange.referenceUrlBody(Content2Jiveid);
        for(Article_Comment__c comment:scope){ 
            for(string str:Jiveid2articleContent.keyset()){
                if(comment.Jive_Id__c == str){
                    comment.Content__c=Jiveid2articleContent.get(str);
                }
            }
        }
        update scope;
        
    }
    public void finish(Database.BatchableContext bc){
        
    }
}