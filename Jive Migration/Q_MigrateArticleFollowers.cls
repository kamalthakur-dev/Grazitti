global class Q_MigrateArticleFollowers implements  Database.Batchable<string>,Database.AllowsCallouts,Database.Stateful {
    
    Map<String, String> mapArticleId2FollowersUrl = new Map<String,String>();
    Jive_Administrator__c setting = Jive_Administrator__c.getValues('Url');
    
    String netWorkId = setting.NetworkId__c;
    List<EntitySubscription> eSubList = new List<EntitySubscription>();
    Map<string, Id> mapJiveId2userId = new Map<string, Id>();
    Map<Id, Id> articleId2ArticleKnowledgeId = new Map<Id, Id>();
    public Q_MigrateArticleFollowers(Map<String, String> mapArticleId2FollowersUrl){
        this.mapArticleId2FollowersUrl = mapArticleId2FollowersUrl;
    }
    
    global Iterable<string> start(Database.BatchableContext BC) {
        For(User u : [select id, jive_id__c from user where jive_id__c != null]){
            mapJiveId2userId.put(u.jive_id__c, u.id);
        }
        List<string> idList = new List<string>();
        idList.addAll(mapArticleId2FollowersUrl.keySet());
        list<knowledge__kav> kav = [SELECT Id,KnowledgeArticleId FROM knowledge__kav WHERE Id IN: idList];
        for(knowledge__kav articles: kav ){
            articleId2ArticleKnowledgeId.put(articles.id, articles.KnowledgeArticleId);
        }
        if(Test.isRunningTest()){idList.add('kA23J0000008Pq8SAE');}
        return idList;
   
    }
    
    global void execute(Database.BatchableContext BC, List<string> articleIds) {
        String jsonstr = null;
        system.debug('articleIds-----------------'+articleIds);
        for(String id : articleIds){
             
            string followerlinks = mapArticleId2FollowersUrl.get(id);
            if(Test.isRunningTest()){followerlinks = 'https://discussions.qualys.com/api/core/v3/contents/74855/followers';}
            List<UserList.items> jiveUsers = new List<UserList.items>();
            while(followerlinks != null) {
                HttpRequest req= new HttpRequest();
                Http http = new Http();
                HttpResponse res = new HttpResponse(); 
                String temp = '';
                if(Test.isRunningTest()){
                    res.setBody('{"itemsPerPage":25,"list":[{"id":"23779","resources":{"followingIn":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/23779/followingIn"},"images":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/23779/images"},"activity":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/23779/activities"},"social":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/23779/@social"},"roles":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/23779/roles"},"streams":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/23779/streams"},"recognition":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/23779/@recognition"},"trendingContent":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/23779/@trendingContent"},"profilePrivacy":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/23779/profilePrivacy"},"trendingPlaces":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/23779/@trendingPlaces"},"avatar":{"allowed":["GET","DELETE","PUT"],"ref":"https://discussions.qualys.com/api/core/v3/people/23779/avatar?a=3195"},"followers":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/23779/@followers"},"pages":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/23779/pages"},"following":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/23779/@following"},"members":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/members/people/23779"},"self":{"allowed":["GET","DELETE","PUT"],"ref":"https://discussions.qualys.com/api/core/v3/people/23779"},"html":{"allowed":["GET"],"ref":"https://discussions.qualys.com/people/cpepper"},"securityGroups":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/23779/securityGroups"},"extprops":{"allowed":["GET","POST","DELETE"],"ref":"https://discussions.qualys.com/api/core/v3/people/23779/extprops"}},"displayName":"Colton Pepper","emails":[{"jive_label":"Email","primary":true,"type":"work","value":"cpepper@qualys.com","jive_displayOrder":1,"jive_summaryDisplayOrder":0,"jive_showSummaryLabel":true}],"jive":{"enabled":true,"level":{"description":"Level 4","imageURI":"https://rewards.imgix.net/prod_phx/11fbffd0-71ed-4b9b-95c0-4052c96abccd/level4?updated=fc876a9d-1ab2-4c6e-8523-71a1079486b5","name":"Level 4","points":1623},"externalContributor":false,"username":"cpepper","visible":true},"name":{"familyName":"Pepper","formatted":"Colton Pepper","givenName":"Colton"},"type":"person","typeCode":3}],"startIndex":0}');
                }else{
                    req.setMethod('GET');
                    req.setEndpoint(followerlinks);      
                    req.setHeader('Authorization', 'Basic Z2F1cmF2YjpTRkRDTWlncmF0aW9u'); 
                    res = http.send(req);
                }
                temp =  res.getBody();
                jsonstr = temp.replace('list','items');
                
                if(jsonstr != null && jsonstr != '') {
                    UserList wrapperinstance=(UserList) System.JSON.deserialize(jsonstr,UserList.class);
                    if(wrapperinstance.items != null && wrapperinstance.items.size()>0){
                        jiveUsers.addAll(wrapperinstance.items);
                    }                    
                   
                    if(wrapperinstance.links != null && wrapperinstance.links.next != null) {                   
                        followerlinks = wrapperinstance.links.next;
                    }
                    else {
                        followerlinks = null;
                    } 
                                   
 
                }                                
            }   
        
            if(jiveUsers != null && jiveUsers.size() > 0 ){
                for(UserList.items u : jiveUsers ){
                    if(mapJiveId2userId.containsKey(u.id)){
                        EntitySubscription eSub = new EntitySubscription();
                        eSub.ParentId = articleId2ArticleKnowledgeId.get(id) ;
                        eSub.SubscriberId = mapJiveId2userId.get(u.id);
                        eSub.NetworkId = netWorkId;
                        eSubList.add(eSub);
                        
                    }
                } 
            }
        }  
    }
    
    global void finish(Database.BatchableContext BC) {
        if(!Test.isRunningTest()){
            insert eSubList;
        }
    }
}