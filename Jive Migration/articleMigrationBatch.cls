public class articleMigrationBatch implements Database.Batchable<SObject>,  Database.Stateful, Database.AllowsCallouts {
    ArticleMigration Articles = new ArticleMigration();
    Map<String,String> topicMap=new Map<String,String>();
    Jive_Administrator__c jiveAdministratorCUstomSetting = Jive_Administrator__c.getValues('Url');
    List<ArticleMigrationWrapper> ArticleWrapperList = new List<ArticleMigrationWrapper>();
    Map<String,Knowledge__kav> ArticleFrCommentMap = new Map<String,Knowledge__kav>();
    Map<String,Knowledge__kav> Article2LikesMap = new Map<String,Knowledge__kav>();
    Map<string,Knowledge__kav> attachmentUrl2Fi = new Map<string,Knowledge__kav> ();
    Map<Knowledge__kav,string> article2jiveid = new Map<Knowledge__kav,string> ();
    string NetworkScopeId = jiveAdministratorCUstomSetting.NetworkId__c;
    Map<string, ArticleMigrationWrapper> KavTitle2WrapperRec = new Map<string, ArticleMigrationWrapper>();
    Integer startIndex,count,TotalItems;
    String placeName, articleJiveId;
    
    Map<string, string> mapArticleId2FollowersUrl  = new Map<string, string>();
    public articleMigrationBatch(Integer startIndex,Integer count,Integer TotalItems, String articleJiveId, String placeName) { 
        this.startIndex=startIndex;
        this.count=count;
        this.TotalItems=TotalItems;
        this.placeName=placeName;
        this.articleJiveId=articleJiveId;
    }
    
    public Iterable<SObject> start(Database.BatchableContext bc) { // To get Articles
        List<Knowledge__kav> ArticleList = new List<Knowledge__kav>();
        ArticleWrapperList = Articles.ApiCallouts(startIndex, count, TotalItems, articleJiveId, placeName);
        for(ArticleMigrationWrapper Obj : ArticleWrapperList){
            ArticleList.add(Obj.kArticle);
            KavTitle2WrapperRec.put(Obj.kArticle.Title,Obj);
            article2jiveid.put(Obj.kArticle,Obj.jiveId);
        }
        for(Topic t:[select id,Name, NetworkId from Topic where NetworkId =:NetworkScopeId ]){
            //system.debug('Network Topic ' + t.NetworkId);
            topicMap.put(t.name.toLowerCase().deleteWhitespace(),t.id); 
        }
        return (ArticleList);
    }
    
    public void execute(Database.BatchableContext bc, list<Knowledge__kav> scope){ 
        ArticleMigration.ArticleTagWrapper artWrapper = new ArticleMigration.ArticleTagWrapper(); 
        List<TopicAssignment> tAssignmentList = new List<TopicAssignment>();
        Map<String, Map<String,String>> newTopics2Assignment =  new Map<String, Map<String,String>>();
        Map<String,String> newTopics2AssignmentMap;
        set<Knowledge__kav> ArticleList = new set<Knowledge__kav>();
        List<Knowledge__kav> KnowledgeArticle = new List<Knowledge__kav>();
        Set<TopicAssignment> topicAssignmentSet = new Set<TopicAssignment>();
        artWrapper = Articles.ArticleImagesApi(article2jiveid); 
        system.debug('artWrapper===>'+artWrapper);
        ArticleList = artWrapper.KnowledgeArticle;
        if(!artWrapper.newTopics2Assign.isEmpty()){
            newTopics2Assignment = artWrapper.newTopics2Assign;
        }
        KnowledgeArticle.addAll(ArticleList);
        if(KnowledgeArticle != null && KnowledgeArticle.size() >0){
           Articles.insertArticles(KnowledgeArticle);
        }
        system.debug('Articles===>'+Articles);
        system.debug('newTopics2Assignment ===>'+newTopics2Assignment);
        
        //Articles.ContentDocumentLink();
        
        /*list<id> ids = new list<id>();
        for(Knowledge__kav knowledgeID: ArticleList){
            ids.add(knowledgeID.id);
        }
        list<Knowledge__kav> KnowledgeArticle =[SELECT Id,KnowledgeArticleId FROM knowledge__kav WHERE Id IN: ids];
        for(Knowledge__kav kav : KnowledgeArticle){
            KbManagement.PublishingService.publishArticle(kav.KnowledgeArticleId, true);
        }*/
        
        
        for(Knowledge__kav kav : ArticleList){
            if(kav.id != null || Test.isRunningTest()){
                system.debug('KavTitle2WrapperRec====>'+KavTitle2WrapperRec);
                ArticleMigrationWrapper KavwObj = KavTitle2WrapperRec.get(kav.Title); 
                //system.debug('KawObj===>'+KawObj.commentUrl);
                if(KavwObj.commentUrl != null){
                    ArticleFrCommentMap.put(KavwObj.commentUrl, kav);  
                }
                //system.debug('ArticleFrCommentMap====>'+ArticleFrCommentMap);
                if(KavwObj.likeUrl != null){
                    system.debug('KavwObj.likeUrl===>'+KavwObj.likeUrl);
                    Article2LikesMap.put(KavwObj.likeUrl, kav); 
                }
                if(KavwObj.helpfullUrl != null){
                    Article2LikesMap.put(KavwObj.helpfullUrl, kav); 
                }
                
                // Below 3 lines to create the Article Followers in salesforce - addition by gaurav on 12 apr 2020.
                if(KavwObj.followersUrl != null && KavwObj.followersUrl != ''){
                    mapArticleId2FollowersUrl.put(kav.id, KavwObj.followersUrl); 
                }
                // -  upto here 
                
                if(KavwObj.attachmentList != null && KavwObj.attachmentList.size() >0){
                    for(articleJSON.fileStr s: KavwObj.attachmentList){
                        if(s != null && s.name != null && s.url != null){
                            attachmentUrl2Fi.put(s.name+'-#-'+s.url,kav);  
                        }
                    }
                }
                list<string> assignmentName = new list<string>();
                system.debug('assignmentName ===>'+assignmentName );
                //system.debug('Article2AttachmentMap===>'+Article2AttachmentMap);
                system.debug('newTopics2Assignment===>'+newTopics2Assignment);
                if(newTopics2Assignment.containsKey(kav.Title)){
                    newTopics2AssignmentMap =  new Map<String,String>();
                    newTopics2AssignmentMap.putAll(newTopics2Assignment.get(kav.Title));
                    system.debug('newTopics2AssignmentMap===>'+newTopics2AssignmentMap);
                    for(String tagName :newTopics2AssignmentMap.keySet()){ 
                        if(!assignmentName.contains(tagName.toLowerCase().deleteWhitespace())){
                            TopicAssignment tAssignmnt=new TopicAssignment();
                            system.debug('tagName.toLowerCase().deleteWhitespace()===>'+tagName.toLowerCase().deleteWhitespace());
                            assignmentName.add(tagName.toLowerCase().deleteWhitespace());
                            tAssignmnt.TopicId=newTopics2AssignmentMap.get(tagName.toLowerCase().deleteWhitespace()); 
                            system.debug('TopicId===>'+tAssignmnt.TopicId);
                            tAssignmnt.EntityId=kav.id;
                            tAssignmnt.NetworkId = NetworkScopeId;
                            topicAssignmentSet.add(tAssignmnt);  
                        }
                    }
                }
               
                for(Integer l=0;l<KavwObj.tags.size();l++){
                    system.debug('KavwObj.tags[l]====>'+KavwObj.tags[l]);
                    
                    
                    if(!assignmentName.contains(KavwObj.tags[l].toLowerCase().deleteWhitespace())){
                        TopicAssignment tAssignmnt=new TopicAssignment();
                         assignmentName.add(KavwObj.tags[l].toLowerCase().deleteWhitespace());
                         tAssignmnt.TopicId=topicMap.get(KavwObj.tags[l].toLowerCase().deleteWhitespace()); 
                         system.debug('topic id'+tAssignmnt.TopicId);
                         system.debug('Checking'+KavwObj.tags[l].toLowerCase().deleteWhitespace());
                         tAssignmnt.EntityId=kav.id;
                         tAssignmnt.NetworkId = NetworkScopeId;
                         topicAssignmentSet.add(tAssignmnt);  
                        } 
                } 
                  
                system.debug('tAssignmentList====>'+topicAssignmentSet.size());
            }
        } 
        if(topicAssignmentSet != null && topicAssignmentSet.size() > 0){
            tAssignmentList.addAll(topicAssignmentSet);
            system.debug('tAssignmentListcccccccccccc==>'+tAssignmentList);
            Articles.insertRecords(tAssignmentList);  
            ArticleList.clear(); 
            
        } 
        
        //Articles.ContentDocumentLink();
    }    
    public void finish(Database.BatchableContext bc){
        articleAttachmentBatch attachmentObj = new articleAttachmentBatch(attachmentUrl2Fi);
        database.executeBatch(attachmentObj , 50);
        
        ArticleSaveLike likeObj = new ArticleSaveLike (Article2LikesMap);
        database.executeBatch(likeObj , 50);
          
        ArticleCommentMigration commentObj = new ArticleCommentMigration(ArticleFrCommentMap);
        database.executeBatch(commentObj , 50);
        
        if(mapArticleId2FollowersUrl.keySet().size() > 0 ){
            Q_MigrateArticleFollowers migratearticlefollowers = new Q_MigrateArticleFollowers(mapArticleId2FollowersUrl);
            database.executeBatch(migratearticlefollowers , 25);
        }
    }   
}