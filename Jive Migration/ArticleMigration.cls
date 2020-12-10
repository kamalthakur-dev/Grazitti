public class ArticleMigration { 

    Map<String,Id>jiveIdToUserIdMap = new Map<String,Id>();
    //List<Topic> topicList = new List<Topic>();
    Map<String,List<String>>tags2topicMap=new Map<String,List<String>>();
    Jive_Administrator__c jiveAdministratorCUstomSetting = Jive_Administrator__c.getValues('Url');
    string documentUrl = jiveAdministratorCUstomSetting.DocumentUrl__c  ;
    //string communityUrl = jiveAdministratorCUstomSetting.CommunityUrl__c; // Commented as per request by Keith to migrate the docs with the Proxy Api
    
    string communityUrl = jiveAdministratorCUstomSetting.JiveProxyCommunityUrl__c;
    string communityUrlForAttachments = jiveAdministratorCUstomSetting.CommunityUrl__c;
    string NetworkScopeId = jiveAdministratorCUstomSetting.NetworkId__c;
    string articleRecTypeId = jiveAdministratorCUstomSetting.Article_Record_Type_Id__c; 
    string libraryName = jiveAdministratorCUstomSetting.Discussion_Community_Library__c;
    string UserProfileName = jiveAdministratorCUstomSetting.UserProfileName__c;
    string non_QualysDocIds = jiveAdministratorCUstomSetting.Non_Qualys_Document_Ids__c;
    string spaceUrl = jiveAdministratorCUstomSetting.spaceUrl__c;
    Map<String,String> ArticleImageUrlMap=new Map<String,String>(); 
    string placeId = '';
    Set<Error_Log__c> ErrorLogsSet;
    Set<Error_Log__c> ErrorLogsCommentsSet;
    Map<String, Id> nickNameToIdMap = new Map<String, Id>();
    Map<String,String> UserAnchorUrlMap = new Map<String,String>();
    Map<Article_Comment__c,String> ArticleComment2JiveId = new Map<Article_Comment__c,String>();
    Map<Knowledge__kav,string> Article2Jiveid = new Map<Knowledge__kav,string>();
    Map<String,string> ArticleTitle2Jiveid = new Map<String,string>();
    final String placeholder = 'This will be fixed manually after migration';
    List<string> nonQualysDocList= new List<string>();
     
    public Map<String,String> getTopicMap(){
        List<Topic> topicList = new List<Topic>();
        topicList=[select id,Name from Topic where NetworkId =:NetworkScopeId];
        Map<String,String> TopicMap=new Map<String,String>();
        for(Topic t:topicList){
            TopicMap.put(t.name.toLowerCase().deleteWhitespace(),t.id); 
            //system.debug('TopicMap====>'+t.name);
            //system.debug('TopicMap====>'+t.name.toLowerCase().deleteWhitespace());
        }
        
        return TopicMap;
    }
    public ArticleMigration(){
        jiveIdToUserIdMap = getSFDCUserId();
        //NetworkScopeId = '0DB560000008XhOGAU';
        //topicList=[select id,Name from Topic where NetworkId =:NetworkScopeId];
        tags2topicMap = getTopicMappingWithTags();
        
        if(string.isNotBlank(non_QualysDocIds)){
            if(non_QualysDocIds.contains(',')){
                nonQualysDocList = non_QualysDocIds.split(',');
            }else{
                nonQualysDocList.add(non_QualysDocIds);
            }
        }
    }
    
    public Map<String,List<String>> getTopicMappingWithTags(){
        
        List<Topics_Mapping__mdt>topicMappingList =[SELECT Label,topic_name__c from Topics_Mapping__mdt];
        //Map<String,String>tag2topicMap=new Map<String,String>();
        Map<String,List<String>> tag2topicMap=new Map<String,List<String>>();
        if(!topicMappingList.isEmpty()){
            for(Topics_Mapping__mdt mdt:topicMappingList){
                if(mdt.topic_name__c.contains(',')){
                    List<String> topiclist= mdt.topic_name__c.split(',');
                    tag2topicMap.put(mdt.label.toLowerCase().deleteWhitespace(),topiclist);      
                }
                else{
                      tag2topicMap.put(mdt.label.toLowerCase().deleteWhitespace(),new List<String> { mdt.topic_name__c });
                }
              
            }
        }
        return tag2topicMap;
    
    }
        
    public List<Article_Comment__c> getArticleData( Map<String, Knowledge__kav> commentUrl2ArticleMap){
        ErrorLogsCommentsSet =  new Set<Error_Log__c>();
        List<Article_Comment__c> articleCommentList = new List<Article_Comment__c>();
        Http http = new Http();
        HttpRequest req= new HttpRequest();
        req.setMethod('GET');
        req.settimeout(120000);
        for(String s:commentUrl2ArticleMap.Keyset()){
            String jsonstr=null;
            if(s!=null){ 
                req.setEndpoint(s+'?startindex=0&count=100');
                req.setHeader('Authorization', 'Basic Z2F1cmF2YjpTRkRDTWlncmF0aW9u'); 
                HttpResponse res = new HttpResponse();
                
                if(!Test.isRunningTest()){  
                        
                   res = http.send(req);
                        //system.debug('111111111>res' + res);
                        
                    }else{
                        res.setBody('{"itemsPerPage":25,"list":[{"id":"9259","resources":{"abuseReports":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/comments/9259/abuseReports"},"outcomeTypes":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/comments/9259/outcomeTypes"},"comments":{"allowed":["GET","POST","PUT"],"ref":"https://discussions.qualys.com/api/core/v3/comments/9259/comments"},"outcomes":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/comments/9259/outcomes"},"self":{"allowed":["GET","DELETE","PUT"],"ref":"https://discussions.qualys.com/api/core/v3/comments/9259"},"html":{"allowed":["GET"],"ref":"https://discussions.qualys.com/docs/DOC-7087?commentID=9259#comment-9259"},"extprops":{"allowed":["GET","POST","DELETE"],"ref":"https://discussions.qualys.com/api/core/v3/comments/9259/extprops"},"helpful":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/comments/9259/helpful"},"unhelpful":{"allowed":["POST"],"ref":"https://discussions.qualys.com/api/core/v3/comments/9259/unhelpful"},"likes":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/comments/9259/likes"}},"followed":false,"likeCount":2,"published":"2020-02-25T23:40:55.305+0000","updated":"2020-02-25T23:40:55.305+0000","iconCss":"jive-icon-document-comment","parentContent":{"id":"7087","html":"https://discussions.qualys.com/docs/DOC-7087","contentID":"74191","name":"FIM: Linux Agent Support","type":"document","typeCode":102,"uri":"https://discussions.qualys.com/api/core/v3/contents/74191","iconCss":"jive-icon-document"},"parentPlace":{"id":"2016","html":"https://discussions.qualys.com/community/tam","placeID":"19944","name":"Qualys TAMs","type":"space","typeCode":14,"uri":"https://discussions.qualys.com/api/core/v3/places/19944","iconCss":"jive-icon-space"},"author":{"id":"5782","resources":{"followingIn":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/5782/followingIn"},"images":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/5782/images"},"activity":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/5782/activities"},"social":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/5782/@social"},"roles":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/5782/roles"},"streams":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/5782/streams"},"recognition":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/5782/@recognition"},"trendingContent":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/5782/@trendingContent"},"profilePrivacy":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/5782/profilePrivacy"},"trendingPlaces":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/5782/@trendingPlaces"},"avatar":{"allowed":["GET","DELETE","PUT"],"ref":"https://discussions.qualys.com/api/core/v3/people/5782/avatar?a=1029"},"followers":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/5782/@followers"},"pages":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/5782/pages"},"following":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/5782/@following"},"members":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/members/people/5782"},"self":{"allowed":["GET","DELETE","PUT"],"ref":"https://discussions.qualys.com/api/core/v3/people/5782"},"html":{"allowed":["GET"],"ref":"https://discussions.qualys.com/people/djprakash"},"securityGroups":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/5782/securityGroups"},"extprops":{"allowed":["GET","POST","DELETE"],"ref":"https://discussions.qualys.com/api/core/v3/people/5782/extprops"}},"followerCount":32,"followed":false,"published":"2011-11-14T19:36:28.106+0000","tags":["threat_intelligence","policy compliance","vulnerabiliy management"],"updated":"2020-02-25T23:35:12.202+0000","displayName":"Deb J","mentionName":"djprakash","emails":[{"jive_label":"Email","primary":true,"type":"work","value":"debj@qualys.com","jive_displayOrder":1,"jive_summaryDisplayOrder":0,"jive_showSummaryLabel":true}],"followingCount":23,"jive":{"enabled":true,"external":false,"externalIdentities":[],"federated":false,"lastProfileUpdate":"2012-09-28T10:38:28.519+0000","lastAuthenticated":"2020-02-25T23:35:12.202+0000","level":{"description":"Level 5","imageURI":"https://rewards.imgix.net/prod_phx/11fbffd0-71ed-4b9b-95c0-4052c96abccd/level5?updated=4bc19e0d-4c6f-4990-9fa0-b6cb9fbb8ab0","name":"Level 5","points":4321},"locale":"en_IN","externalContributor":false,"profile":[{"jive_label":"Occupation","value":"Could tell you, but will have to kill you then....","jive_displayOrder":1,"jive_summaryDisplayOrder":2,"jive_showSummaryLabel":true},{"jive_label":"Join Date","value":"5/5/2009","jive_displayOrder":2,"jive_showSummaryLabel":false},{"jive_label":"Company","value":"Qualys Inc","jive_displayOrder":5,"jive_summaryDisplayOrder":3,"jive_showSummaryLabel":true},{"jive_label":"URL","value":"http://www.qualys.com","jive_displayOrder":5,"jive_showSummaryLabel":false},{"jive_label":"Expertise","value":"","jive_displayOrder":6,"jive_showSummaryLabel":false},{"jive_label":"Biography","value":"","jive_displayOrder":6,"jive_showSummaryLabel":false},{"jive_label":"LinkedIn","value":"http://in.linkedin.com/in/debzz","jive_displayOrder":10,"jive_showSummaryLabel":false}],"sendable":true,"timeZone":"Asia/Calcutta","username":"djprakash","visible":true,"roleBadge":{"groupBadgeUri":"/resources/statics/rolebadges/roleBadge-4-1005-1500841877697.png?a=1500841877739","groupBadgeRoleName":"Employee","type":"roleBadge"},"status":"registered"},"name":{"familyName":"J","formatted":"Deb J","givenName":"Deb"},"phoneNumbers":[{"jive_label":"Phone Number","primary":true,"type":"work","value":"+91-9341063573","jive_displayOrder":4,"jive_summaryDisplayOrder":1,"jive_showSummaryLabel":true}],"photos":[{"value":"https://discussions.qualys.com/api/core/v3/people/5782/images/1/data?a=3444","jive_showSummaryLabel":false},{"value":"https://discussions.qualys.com/api/core/v3/people/5782/images/2/data?a=5475","jive_showSummaryLabel":false},{"value":"https://discussions.qualys.com/api/core/v3/people/5782/images/3/data?a=6042","jive_showSummaryLabel":false}],"status":"just joined the community","thumbnailId":"1029","thumbnailUrl":"https://discussions.qualys.com/api/core/v3/people/5782/avatar?a=1029","initialLogin":"2011-11-14T19:36:28.106+0000","type":"person","typeCode":3},"content":{"text":"<body><!-- [DocumentBodyStart:e394af36-c0d2-4e97-83b8-bec4cacf4409] --><div class=\\"jive-rendered-content\\"><p>Great article<img alt=\\"\\" class=\\"image-3 jive-emoji jive-image\\" height=\\"434\\" src=\\"https://discussions.qualys.com/servlet/JiveServlet/downloadImage/102-7079-2-26694/600-434/12344.png\\"></p></div><!-- [DocumentBodyEnd:e394af36-c0d2-4e97-83b8-bec4cacf4409] --></body>","editable":false,"type":"text/html"},"parent":"https://discussions.qualys.com/api/core/v3/contents/74191","replyCount":0,"status":"published","subject":"FIM: Linux Agent Support","viewCount":40,"abuseCount":0,"typeCode":105,"type":"comment","helpfulCount":1,"unhelpfulCount":0,"outcomeTypeNames":["helpful"],"outcomeCounts":{"helpful":1},"rootType":"document","rootIconCss":"jive-icon-document","rootURI":"https://discussions.qualys.com/api/core/v3/contents/74191","rootAuthor":{"id":"44796","resources":{"followingIn":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/44796/followingIn"},"images":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/44796/images"},"activity":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/44796/activities"},"social":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/44796/@social"},"roles":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/44796/roles"},"streams":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/44796/streams"},"recognition":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/44796/@recognition"},"trendingContent":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/44796/@trendingContent"},"profilePrivacy":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/44796/profilePrivacy"},"trendingPlaces":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/44796/@trendingPlaces"},"avatar":{"allowed":["GET","DELETE","PUT"],"ref":"https://discussions.qualys.com/api/core/v3/people/44796/avatar?a=1024"},"followers":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/44796/@followers"},"pages":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/44796/pages"},"following":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/44796/@following"},"members":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/members/people/44796"},"self":{"allowed":["GET","DELETE","PUT"],"ref":"https://discussions.qualys.com/api/core/v3/people/44796"},"html":{"allowed":["GET"],"ref":"https://discussions.qualys.com/people/kakumbhar"},"securityGroups":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/44796/securityGroups"},"extprops":{"allowed":["GET","POST","DELETE"],"ref":"https://discussions.qualys.com/api/core/v3/people/44796/extprops"}},"followerCount":0,"followed":false,"published":"2019-11-06T09:53:30.575+0000","updated":"2020-03-02T09:54:33.226+0000","displayName":"Kaustubh Kumbhar","mentionName":"kakumbhar","emails":[{"jive_label":"Email","primary":true,"type":"work","value":"kakumbhar@qualys.com","jive_displayOrder":1,"jive_summaryDisplayOrder":0,"jive_showSummaryLabel":true}],"followingCount":0,"jive":{"enabled":true,"external":false,"externalIdentities":[],"federated":false,"lastProfileUpdate":"2019-11-06T09:53:31.365+0000","lastAuthenticated":"2020-03-02T09:54:33.226+0000","level":{"description":"Level 2","imageURI":"https://rewards.imgix.net/prod_phx/11fbffd0-71ed-4b9b-95c0-4052c96abccd/level2?updated=b32d26ee-446a-40fe-bc33-1f763509a8d8","name":"Level 2","points":125},"locale":"en_US","externalContributor":false,"profile":[{"jive_label":"Occupation","value":"Service","jive_displayOrder":1,"jive_summaryDisplayOrder":2,"jive_showSummaryLabel":true},{"jive_label":"Company","value":"Qualys","jive_displayOrder":5,"jive_summaryDisplayOrder":3,"jive_showSummaryLabel":true},{"jive_label":"Biography","value":"Product Manager @Qualys","jive_displayOrder":6,"jive_showSummaryLabel":false}],"sendable":true,"timeZone":"Asia/Kolkata","username":"kakumbhar","visible":true,"roleBadge":{"groupBadgeUri":"/resources/statics/rolebadges/roleBadge-4-1005-1500841877697.png?a=1500841877739","groupBadgeRoleName":"Employee","type":"roleBadge"},"status":"registered"},"name":{"familyName":"Kumbhar","formatted":"Kaustubh Kumbhar","givenName":"Kaustubh"},"photos":[{"value":"https://discussions.qualys.com/api/core/v3/people/44796/images/1/data?a=6236","jive_showSummaryLabel":false}],"thumbnailId":"1024","thumbnailUrl":"https://discussions.qualys.com/api/core/v3/people/44796/avatar?a=1024","initialLogin":"2019-11-06T09:53:30.530+0000","type":"person","typeCode":3},"publishedCalendarDate":"Tuesday, February 25, 2020","publishedTime":"3:40 PM","currentUserMentionedInObject":false,"canMarkHelpful":true,"canMarkUnHelpful":true,"unHelpfulEnabled":true,"hasVotedHelpful":false,"hasVotedUnHelpful":false,"parentID":-1,"pageNumber":1,"commentRating":5}],"startIndex":0}');
                }
                                    
                String temp =  res.getBody().replace('\n','');
                //System.debug('Response'+temp);
                jsonstr = temp.replace('"list"','"lists"');
            }
            
            CommentJson commentWrapper = (CommentJson)CommentJson.parse(jsonstr); 
            //System.debug('CommentWrapper'+commentWrapper) ;
            //System.debug('wrapper size'+commentWrapper.lists.size()) ;  
            for(Integer j=0;j<commentWrapper.lists.size();j++){
                //if(!Test.isRunningTest()){  
                if(commentUrl2ArticleMap.get(s).id!=null || Test.isRunningTest()) { 
                    
                    Article_Comment__c articleComment = new Article_Comment__c(); 
                    //system.debug('commentUrl2Art===>'+commentUrl2ArticleMap.get(s).KnowledgeArticleId);
                    //articleComment.Knowledge_Article__c =commentUrl2ArticleMap.get(s).id;
                    articleComment.Knowledge_Article__c =commentUrl2ArticleMap.get(s).Id;
                    articleComment.Jive_Id__c = commentWrapper.lists.get(j).id;
                    articleComment.CreatedDate = QualysUtils.formatDateValue(commentWrapper.lists.get(j).published); 
                    
                    if(commentWrapper.lists.get(j).parentContent!=null && commentWrapper.lists.get(j).parentContent.id != null){
                        articleComment.Parent_Jive_Id__c= commentWrapper.lists.get(j).parentContent.id;
                    }
                    
                    if(commentWrapper.lists.get(j).content!=null){
                        
                        if(commentWrapper.lists.get(j).content.text.length() <= 10000){                    
                           articleComment.Content__c = commentWrapper.lists.get(j).content.text;            
                        }
                        else{
                            
                            articleComment.Content__c = placeholder;
                            Error_Log__c log = new Error_Log__c();
                            log.Type__c = 'Article';
                            log.Name = 'Article Comments Insertion Error';
                            log.Jive_Id__c = Article2Jiveid.get(commentUrl2ArticleMap.get(s));
                            log.Object__c = 'Knowledge__kav';
                            log.Error_Description__c = 'Body of ArticleComment is greater then 10,000 character.';
                            ErrorLogsCommentsSet.add(log);
                        }
                    }
                    if(commentWrapper.lists.get(j).likeCount != null && commentWrapper.lists.get(j).likeCount >0){
                      if(commentWrapper.lists.get(j).resources.likes != null && commentWrapper.lists.get(j).resources.likes.ref != null){
                        articleComment.like_url__c =  commentWrapper.lists.get(j).resources.likes.ref;
                      }
                    }
                     // Changes done for Helpful Data starts
                    if(commentWrapper.lists.get(j).helpfulCount != null && commentWrapper.lists.get(j).helpfulCount >0){
                      if(commentWrapper.lists.get(j).resources.helpful != null && commentWrapper.lists.get(j).resources.helpful.ref != null){
                         articleComment.Helpful_Url__c=  commentWrapper.lists.get(j).resources.helpful.ref;
                      }
                    }
                    // Changes done for Helpful Data ends
                    if(commentWrapper.lists.get(j).author != null && commentWrapper.lists.get(j).author.id !=null && jiveIdToUserIdMap.size() > 0 && jiveIdToUserIdMap.containsKey(commentWrapper.lists.get(j).author.id)){
                        articleComment.CreatedById  = jiveIdToUserIdMap.get(commentWrapper.lists.get(j).author.id);
                    }
                    ArticleComment2JiveId.put(articleComment,Article2Jiveid.get(commentUrl2ArticleMap.get(s)));
                    articleCommentList.add(articleComment); 
                }
                
            }
            
        }
        //system.debug('ArticleComment2JiveId===>'+ArticleComment2JiveId);
        return articleCommentList;
    }
    public void setArticleCommentInLevels(Map<String, Article_Comment__c> ACJiveId2ArticleComment){
        //system.debug('setArticleCommentInLevels'+ACJiveId2ArticleComment.size());
        List<Article_Comment__c> updateArticleList = new List<Article_Comment__c>();
        for(Article_Comment__c a : ACJiveId2ArticleComment.values()){
            if(a.Parent_Jive_Id__c!= null && ACJiveId2ArticleComment.containsKey(a.Parent_Jive_Id__c)){
                //system.debug('Id'+a.id); 
                a.Parent_Comment__c = ACJiveId2ArticleComment.get(a.Parent_Jive_Id__c).id;
                //system.debug('articleComment.Parent_Comment__c'+a.Parent_Comment__c);
                updateArticleList.add(a);  
            } 
        } 
        //system.debug('gggggg'+updateArticleList.size());
        //update  updateArticleList;  
        Database.update(updateArticleList,true);
        //System.debug('Updated list'+updateArticleList); 
        
    }
    public List<Article_Comment_Likes__c> saveArticleCommentLike(Map<String, Article_Comment__c> commentLikeUrl2ArticleComment){
        List<Article_Comment_Likes__c>articleCommentLikeList = new List<Article_Comment_Likes__c>();
        Set<Article_Comment_Likes__c>articleCommentLikeSet = new Set<Article_Comment_Likes__c>();
        String jsonstr = null;
        Http http = new Http();
        HttpRequest req= new HttpRequest();
        req.setMethod('GET');
        req.settimeout(120000);
        if(!commentLikeUrl2ArticleComment.isEmpty()){
            for(String s:commentLikeUrl2ArticleComment.Keyset()){
                if(s != null){
                req.setEndpoint(s); 
                req.setHeader('Authorization', 'Basic Z2F1cmF2YjpTRkRDTWlncmF0aW9u'); 
                HttpResponse res = new HttpResponse();
                
                if(!Test.isRunningTest()){  
                        
                   res = http.send(req);
                        //system.debug('111111111>res' + res);
                        
                    }else{
                        res.setBody('{"itemsPerPage":25,"list":[{"id":"11844","resources":{"followingIn":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/11844/followingIn"},"images":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/11844/images"},"activity":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/11844/activities"},"social":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/11844/@social"},"roles":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/11844/roles"},"streams":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/11844/streams"},"recognition":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/11844/@recognition"},"trendingContent":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/11844/@trendingContent"},"profilePrivacy":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/11844/profilePrivacy"},"trendingPlaces":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/11844/@trendingPlaces"},"avatar":{"allowed":["GET","DELETE","PUT"],"ref":"https://discussions.qualys.com/api/core/v3/people/11844/avatar?a=2188"},"followers":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/11844/@followers"},"pages":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/11844/pages"},"following":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/11844/@following"},"members":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/members/people/11844"},"self":{"allowed":["GET","DELETE","PUT"],"ref":"https://discussions.qualys.com/api/core/v3/people/11844"},"html":{"allowed":["GET"],"ref":"https://discussions.qualys.com/people/BryanU"},"securityGroups":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/11844/securityGroups"},"extprops":{"allowed":["GET","POST","DELETE"],"ref":"https://discussions.qualys.com/api/core/v3/people/11844/extprops"}},"displayName":"Bryan Umbeck","emails":[{"jive_label":"Email","primary":true,"type":"work","value":"bryan.umbeck@imaginexconsulting.com","jive_displayOrder":1,"jive_summaryDisplayOrder":0,"jive_showSummaryLabel":true}],"jive":{"enabled":true,"level":{"description":"Level 3","imageURI":"https://rewards.imgix.net/prod_phx/11fbffd0-71ed-4b9b-95c0-4052c96abccd/level3?updated=d054f22e-e20d-4f63-8838-5ef9257ce93a","name":"Level 3","points":291},"externalContributor":false,"username":"BryanU","visible":true},"name":{"familyName":"Umbeck","formatted":"Bryan Umbeck","givenName":"Bryan"},"type":"person","typeCode":3},{"id":"33396","resources":{"followingIn":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/33396/followingIn"},"images":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/33396/images"},"activity":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/33396/activities"},"social":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/33396/@social"},"roles":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/33396/roles"},"streams":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/33396/streams"},"recognition":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/33396/@recognition"},"trendingContent":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/33396/@trendingContent"},"profilePrivacy":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/33396/profilePrivacy"},"trendingPlaces":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/33396/@trendingPlaces"},"avatar":{"allowed":["GET","DELETE","PUT"],"ref":"https://discussions.qualys.com/api/core/v3/people/33396/avatar?a=3233"},"followers":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/33396/@followers"},"pages":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/33396/pages"},"following":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/33396/@following"},"members":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/members/people/33396"},"self":{"allowed":["GET","DELETE","PUT"],"ref":"https://discussions.qualys.com/api/core/v3/people/33396"},"html":{"allowed":["GET"],"ref":"https://discussions.qualys.com/people/dbisses"},"securityGroups":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/33396/securityGroups"},"extprops":{"allowed":["GET","POST","DELETE"],"ref":"https://discussions.qualys.com/api/core/v3/people/33396/extprops"}},"displayName":"Black Beard","emails":[{"jive_label":"Email","primary":true,"type":"work","value":"denish.bissessur@uk.dstsystems.com","jive_displayOrder":1,"jive_summaryDisplayOrder":0,"jive_showSummaryLabel":true}],"jive":{"enabled":true,"level":{"description":"Level 2","imageURI":"https://rewards.imgix.net/prod_phx/11fbffd0-71ed-4b9b-95c0-4052c96abccd/level2?updated=b32d26ee-446a-40fe-bc33-1f763509a8d8","name":"Level 2","points":57},"externalContributor":false,"username":"dbisses","visible":true},"name":{"familyName":"Beard","formatted":"Black Beard","givenName":"Black"},"type":"person","typeCode":3},{"id":"37238","resources":{"followingIn":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/37238/followingIn"},"images":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/37238/images"},"activity":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/37238/activities"},"social":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/37238/@social"},"roles":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/37238/roles"},"streams":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/37238/streams"},"recognition":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/37238/@recognition"},"trendingContent":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/37238/@trendingContent"},"profilePrivacy":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/37238/profilePrivacy"},"trendingPlaces":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/37238/@trendingPlaces"},"avatar":{"allowed":["GET","DELETE","PUT"],"ref":"https://discussions.qualys.com/api/core/v3/people/37238/avatar?a=3368"},"followers":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/37238/@followers"},"pages":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/37238/pages"},"following":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/37238/@following"},"members":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/members/people/37238"},"self":{"allowed":["GET","DELETE","PUT"],"ref":"https://discussions.qualys.com/api/core/v3/people/37238"},"html":{"allowed":["GET"],"ref":"https://discussions.qualys.com/people/jacpsu"},"securityGroups":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/37238/securityGroups"},"extprops":{"allowed":["GET","POST","DELETE"],"ref":"https://discussions.qualys.com/api/core/v3/people/37238/extprops"}},"displayName":"Jayson Coulter","emails":[{"jive_label":"Email","primary":true,"type":"work","value":"jaacoulter@selectmedical.com","jive_displayOrder":1,"jive_summaryDisplayOrder":0,"jive_showSummaryLabel":true}],"jive":{"enabled":true,"level":{"description":"Level 3","imageURI":"https://rewards.imgix.net/prod_phx/11fbffd0-71ed-4b9b-95c0-4052c96abccd/level3?updated=d054f22e-e20d-4f63-8838-5ef9257ce93a","name":"Level 3","points":535},"externalContributor":false,"username":"jacpsu","visible":true},"name":{"familyName":"Coulter","formatted":"Jayson Coulter","givenName":"Jayson"},"type":"person","typeCode":3}],"startIndex":0}');
                }
                                    
                String temp =  res.getBody().replace('\n','');
                jsonstr = temp.replace('list','items');
                //system.debug('jsonstr'+jsonstr );
                
                if(jsonstr != null){
                    UserList wrapperinstance = (UserList) System.JSON.deserialize(jsonstr, UserList.class);
                    //system.debug('responses===>'+wrapperinstance );
                    if(wrapperinstance.items != null && wrapperinstance.items.size() > 0){
                        for(Integer j=0;j<wrapperinstance.items.size();j++){
                            Article_Comment_Likes__c acLikes =  new Article_Comment_Likes__c(); 
                            acLikes.Article_Comment__c =  commentLikeUrl2ArticleComment.get(s).id;
                            //System.debug('kkkk'+jiveIdToUserIdMap.containsKey(wrapperinstance.items.get(j).id));
                            //system.debug('Size'+wrapperinstance.items.get(j).id);
                            if(wrapperinstance.items.get(j).id != null && jiveIdToUserIdMap.containsKey(wrapperinstance.items.get(j).id) ){
                                //System.debug('IN IFFFFFFFFFFFFFFFF');
                                acLikes.Liked_By__c = jiveIdToUserIdMap.get(wrapperinstance.items.get(j).id);
                                acLikes.Liked__c =  true;
                            }  
                            articleCommentLikeSet.add(acLikes);
                            //articleCommentLikeList.add(acLikes); 
                        }
                        
                    }
                    
                }  
               } 
            }
            
            if(articleCommentLikeSet != null && articleCommentLikeSet.size() > 0){
                articleCommentLikeList.addAll(articleCommentLikeSet); 
            }
            
        }
        return articleCommentLikeList;
    }
    
    
    public Map<String,Id> getSFDCUserId(){
        Map<String,Id>jiveIdMapToUserId=new Map<String,Id>();
        for(User u: [Select id , jive_id__c , Profile.name,CommunityNickname, JiveUserName__c  from user where jive_id__c != null]){
            jiveIdMapToUserId.put(u.jive_id__c,u.id);
            nickNameToIdMap.put(u.JiveUserName__c , u.Id);
        }
        return jiveIdMapToUserId;
    }  
    
    public List<ArticleMigrationWrapper> ApiCallouts(Integer startIndex, Integer count, Integer totalItems,  string articleJiveId, String placeName){   // 0 10 100
        ErrorLogsSet =  new Set<Error_Log__c>();
        string endpoint  = '';
        if(String.isNotBlank(placeName)){
            placeId = Qualys_Spaces__c.getValues(placeName).SpaceId__c;
            endpoint = communityUrl+spaceUrl+placeId+'/'+documentUrl;
        }else if(String.isNotBlank(articleJiveId)){
            endpoint = communityUrl + 'contents?filter=entityDescriptor(102,'+articleJiveId+')'; 
        }else{
            endpoint = communityUrl+documentUrl;
        }
        Map<String,String> topicMap=getTopicMap();
        //System.debug('topicMap@@@@@@@@'+topicMap);
        Map<String,Topic> tMap=new Map<String,Topic>();      
        Integer loops = (totalItems/count);   //10
        
        List<articleJSON.cls_list> artilcleList = new List<articleJSON.cls_list>();
        List<ArticleMigrationWrapper> artMigWrapList = new List<ArticleMigrationWrapper>();
        //System.debug('loops @@@@@@@'+loops );
        for(Integer i=0; i<loops ; i++){
            //endpoint = 'https://discussions.qualys.com/api/core/v3/contents?filter=entityDescriptor(102,6895)';
                
            if(endpoint.contains('type(document)')){
                if(i==0){
                  endpoint += 'startIndex='+startIndex+'&count='+count;   //startIndex = 0, count = 10
               }
            }
            //System.debug('lendpoint @@@@@@'+endpoint );
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.SetEndPoint(endpoint);
            request.settimeout(120000);
            request.setHeader('Authorization', 'Basic Z2F1cmF2YjpTRkRDTWlncmF0aW9u'); 
            request.setMethod('GET');
            HttpResponse response = http.send(request); 
            //System.debug('Response'+response.getBody());
            String jsonReplace =  response.getBody().replace('"list"', '"items"');
            articleJSON wrapper = (articleJSON)articleJSON.parse(jsonReplace);
            //System.debug('wrapper '+wrapper );
            if(wrapper != null ){
                if(wrapper.links != null && wrapper.links.next != null){    
                    endpoint = wrapper.links.next;                                     //Next EndPoint
                }
                if(wrapper.items != NULL && wrapper.items.size() > 0){
                    artilcleList.addAll(wrapper.items);                                //Article Details
                }
            }
        }
        
        //insert Article
        //System.debug('artilcleList  @@@@@@'+artilcleList.size());
        if(artilcleList != null && artilcleList.size() > 0){
            
            for(articleJSON.cls_list art: artilcleList){
                if(!nonQualysDocList.isEmpty() && !nonQualysDocList.contains(art.id)){
                      
                    ArticleMigrationWrapper artMigWrap ;
                    List<string> tags = new List<string>();
                    string commentUrl;
                    string articleLikesUrl;
                    string articleHelpfulUrl;
                    string followersUrl = '';
                    string articleAttachmentsUrl;
                    List<articleJSON.fileStr> articleAttachment;
                    Knowledge__kav kA =new Knowledge__kav();
                    
                    string str = art.subject;
                    str = str.replaceAll('[^a-zA-Z0-9\\s+]', '');
                    str = str.replaceAll('[|,|.|\\,||"||:|~|!|@|#|$|%|^|&|*|_|+|=|<|>|?|\\(|\\)|\\{|\\}|\\;|\\\'"]', '');
                    str = str.trim();
                    str = str.replace(' ', '-');
                    kA.Title = art.subject.unescapeHtml4();
                    kA.Language = 'en_US';
                    kA.UrlName = str;
                    //system.debug('Date.valueOf(art.published)==>'+DateTime.valueOf((art.published).format('yyyy-MM-dd HH:mm:ss')));
                    if(art.published != null){
                       kA.Created_Date__c  = QualysUtils.formatDateValue(art.published);
                    }
                    if(art.updated != null){
                        kA.LastModified_Date__c = QualysUtils.formatDateValue(art.updated);
                    }
                    //system.debug('kA.CreatedDate==>'+kA.CreatedDate);
                    //kA.ArticleCreatedDate  = Date.valueOf(art.published);
                    if(art.author != null && art.author.id !=null && jiveIdToUserIdMap.size() > 0 && jiveIdToUserIdMap.containsKey(art.author.id)){
                        kA.CreatedById  = jiveIdToUserIdMap.get(art.author.id);
                    }
                    if(art.updater != null && art.updater.id !=null && jiveIdToUserIdMap.size() > 0 && jiveIdToUserIdMap.containsKey(art.updater.id)){
                        kA.LastModifiedBy__c = jiveIdToUserIdMap.get(art.updater.id);
                    }else if(art.author != null && art.author.id !=null && jiveIdToUserIdMap.size() > 0 && jiveIdToUserIdMap.containsKey(art.author.id)){
                        kA.LastModifiedBy__c = jiveIdToUserIdMap.get(art.author.id);
                    }else{
                        kA.LastModifiedBy__c = kA.CreatedById;
                    }
                    if(art.id != null){                    
                        kA.JiveId__c= art.id;              
                    }
                    //system.debug('Date.valueOf(art.updated)===>'+Date.valueOf(art.updated));
                    //kA.LastPublishedDate  = Date.valueOf(art.updated);
                    kA.RecordTypeId = articleRecTypeId ; // Needs to be replaced with the recordtye name
                    if(art.content.text.length() <= 201142){                    
                        kA.Description__c = art.content.text;              
                    }
                    else{
                       
                        kA.Description__c = placeholder;
                        Error_Log__c log = new Error_Log__c();
                        log.Type__c = 'Article';
                        log.Name = 'Article Insertion Error';
                        log.Jive_Id__c = art.id;
                        log.Object__c = 'Knowledge__kav';
                        log.Error_Description__c = 'Body of Article is greater then 2,01,142 character';
                        ErrorLogsSet.add(log);
                    }
                    /*if(art.tags!=null){  
                    //system.debug('Tags Not Null===>');
                        for(Integer n=0;n<art.tags.size();n++){
                          //system.debug('Tags ===>'+art.tags[n].toLowerCase().deleteWhitespace());
                            if(!topicMap.containsKey(art.tags[n].toLowerCase().deleteWhitespace())){
                                //system.debug('TAGSSSSSSSS'+art.tags[n].toLowerCase().deleteWhitespace());
                                Topic tObj=new Topic();
                                tObj.name = art.tags[n];
                                tObj.NetworkId=NetworkScopeId; 
                                tMap.put(tObj.name,tObj);                            
                            } 
                        }                 
                    }*/
                    
                    set<string> tagSet = new set<string>();
                       if(art.tags!=null){
        
                                
                         // tags logic to include the custom mapping
                          List<string> tagList = new List<string>();
                          tagList = art.tags; 
                          for(String s : tagList){
                              string s_lower = s.toLowerCase().deleteWhitespace();
                              if(tags2topicMap.containsKey(s_lower)) {
                                  for(String topic:tags2topicMap.get(s_lower)){
                                        if(!tagSet.contains(topic.toLowerCase().deleteWhitespace())){
                                            tags.add(topic);
                                            tagSet.add(topic.toLowerCase().deleteWhitespace());
                                        }
                                        system.debug('tagSet---------'+tagSet);
                                    }  
                                }
                                else if(!tagSet.contains((s_lower))){
                                     tagSet.add(s_lower);
                                     tags.add(s);
                             }
                          }
                     }
                    /*if(art.tags != null){
                        tags = art.tags;
                    }*/
                    if(art.parentPlace != null && art.parentPlace.name != null ){
                        //tags.add(art.parentPlace.name);
                        string tg = art.parentPlace.name;
                        string tg_lower = tg.toLowerCase().deleteWhitespace();
                        if(!tags.contains(tg) && !tags.contains(tg_lower) ){
                            if(tags2topicMap.containsKey(tg_lower)){
                                for(String topic:tags2topicMap.get(tg_lower)){
                                    if(!tagSet.contains(topic.toLowerCase().deleteWhitespace())){
                                        tags.add(topic);
                                        tagSet.add(topic.toLowerCase().deleteWhitespace());
                                    }
                                }
                            }
                            else{
                                tags.add(tg);
                                tagSet.add(tg_lower);
                                
                            }
                        } 
                    }
                    if(tags!=null){  
                    //system.debug('Tags Not Null===>');
                        for(Integer n=0;n<tags.size();n++){
                          //system.debug('Tags ===>'+tags[n].toLowerCase().deleteWhitespace());
                            if(!topicMap.containsKey(tags[n].toLowerCase().deleteWhitespace())){
                                //system.debug('TAGSSSSSSSS'+tags[n].toLowerCase().deleteWhitespace());
                                Topic tObj=new Topic();
                                tObj.name = tags[n];
                                tObj.NetworkId=NetworkScopeId; 
                                tMap.put(tObj.name,tObj);                            
                            } 
                        }                 
                    }
                    if(art.resources != null && art.resources.comments!= null ){
                        commentUrl = art.resources.comments.ref;
                        //system.debug('commentUrl====>'+commentUrl);
                    }
                    if(art.likeCount != null && art.likeCount >0){
                      if(art.resources != null && art.resources.likes != null ){
                        articleLikesUrl = art.resources.likes.ref;
                      }
                    }
                    // Changes done for Helpful Data starts
                    if(art.helpfulCount != null && art.helpfulCount >0){
                      if(art.resources != null && art.resources.helpful != null){
                        articleHelpfulUrl = art.resources.helpful.ref;
                      }
                    }
                    
                    if(art.followerCount != null && art.followerCount > 0){     
                    system.debug('Resources'+art.resources.followers.ref);              
                        followersUrl = art.resources.followers.ref;                                      
                    }
                    // Changes done for Helpful Data ends
                    if(art.attachments != null && art.attachments.size() > 0){                   
                        articleAttachment = art.attachments;                                      
                    }
                    
                    //system.debug('art.id'+art.id);
                    artMigWrap = new ArticleMigrationWrapper(art.id, kA,tags,commentUrl,articleLikesUrl, articleHelpfulUrl, articleAttachment, followersUrl);
                    artMigWrapList.add(artMigWrap);
                    
                }
            }
        }
        //System.debug('artMigWrap-------------'+artMigWrapList.size());
        if(!tMap.isEmpty()){
            insertRecords(tMap.values());
        }
        return artMigWrapList;
    }
    
    public ArticleTagWrapper  ArticleImagesApi(Map<Knowledge__kav,string> ArticlesJiveid){
        Map<String,String> topicMap=getTopicMap();
        List<ArticleTagWrapper> articleWrap = new List<ArticleTagWrapper>();
        ArticleTagWrapper artticleWrap = new ArticleTagWrapper();
        QualysUtils qu = new QualysUtils();
        Map<String,String> imgToDownloadMap=new Map<String,String>();
        Map<String,String> imgNameToHrefMap=new Map<String,String>();
        Map<String,String> topicUrl2TopicName=new Map<String,String>(); 
        List<ContentVersion> cntVersionList = new List<ContentVersion>();
        Set<string> tags = new Set<string>();
        Map<String,Topic> tMap=new Map<String,Topic>();  
        Map<String,String> divOldVal2NewVal=new Map<String,String>();
        Map<String,String> topicName2Id = new Map<String,String>(); 
        Map<String, Map<String,String>> topic2AssignmentMap = new Map<String, Map<String,String>>(); 
        Map<string,string> MapcontentidDocid = new Map<string,string>();    
        for( Knowledge__kav kav : ArticlesJiveid.keySet()){
            //system.debug('ArticlesJiveid===>'+ArticlesJiveid);
            //system.debug('ArticlesJiveidvalue===>'+ArticlesJiveid.values());
            //system.debug('kav===>'+kav);
            //system.debug('ArticlesJiveid.get(fi)===>'+ArticlesJiveid.get(kav));
            ArticleTitle2Jiveid.put(kav.title,ArticlesJiveid.get(kav));
            //system.debug('kav.Name----------------'+kav.Id);
            Matcher imgMatcher = Pattern.compile( '<img(.+?)>' ).matcher( kav.Description__c );
            Matcher imgAnchorMatcher = Pattern.compile( '<a(.+?)>' ).matcher( kav.Description__c );
            Matcher tagsAncerTagMacher = Pattern.compile( '<a(.+?)/a>' ).matcher( kav.Description__c ); 
            Matcher divMatcher= Pattern.compile( '<div(.+?)>' ).matcher( kav.Description__c );
            //System.debug('imgMatcher ---------------');
            while ( divMatcher.find() ) {
                 String divTag = divMatcher.group();  
                 system.debug('divTag ----------'+divTag );
                  String newVal= divMatcher.group();  
                  if(divTag.contains('alert=')){
                      string classVal = divTag.substringBetween( ' class="', '"');
                      string alertVal =divTag.substringBetween( ' alert="', '"');
                      system.debug('classVal ----------'+classVal );
                      string updatedclassVal = classVal+' alert_'+alertVal;
                      newVal= newVal.replace(classVal,updatedclassVal);
                      divOldVal2NewVal.put(divTag ,newVal);
                      system.debug('newVal ----------'+newVal);
                      
                  }  
            }
            while ( imgMatcher.find() ) {
                String imageTag = imgMatcher.group();                   
                String imageURL = imageTag.substringBetween( ' src="', '"' );
                if(imageURL.contains(System.Label.Jive_Community_Image_Anchor_URL)){
                    String imageName = imageURL.subString(imageURL.lastIndexOf('/')+1);
                    String textStripImageName = 'downloadImage';
                    //System.debug('imageName ---------------'+imageName );
                    String newImageName ='';
                    if(imageURL.contains(textStripImageName)){
                        String[] imageArr = imageURL.split(textStripImageName)[1].split('/'); 
                        //System.debug('imageArr ---------------'+imageArr ); 
                        //String jiveUniqueId = imageArr[2];
                        String jiveUniqueId = '';
                        if(imageArr[1] != null){
                            if(imageArr[1].contains('-')){
                                jiveUniqueId = imageArr[1].split('-')[2];
                                if(imageArr[1].split('-').size() > 3){
                                    jiveUniqueId += imageArr[1].split('-')[3];
                                }
                            }else{
                                jiveUniqueId = imageArr[1];
                            }
                        }
                        if(String.isNotBlank(jiveUniqueId)){
                            newImageName =  jiveUniqueId+'_'+imageName;
                        }  else{
                            newImageName = imageName;
                        }
                    }
                       
                    else{
                        newImageName = imageName;
                    }
                    imgToDownloadMap.put(newImageName, imageURL);     // Created a map of ImageName and ImageUrl
                    
                }
                }
               
            
            while ( imgAnchorMatcher.find() ) {                   
                String imgAncerTag = imgAnchorMatcher.group(); 
                String textStripImageName = 'showImage';
                String anchorURL = imgAncerTag.substringBetween( ' href="', '"' );
                if(anchorURL != null && (anchorURL.contains(System.Label.Jive_Community_Image_Anchor_URL) || anchorURL.contains('/servlet/JiveServlet'))){
                    String imageName = anchorURL.subString(anchorURL.lastIndexOf('/')+1); 
                    String newImageName ='';
                    if(anchorURL.contains(textStripImageName)){
                        String[] imageArr = anchorURL.split(textStripImageName)[1].split('/'); 
                        //System.debug('imageArr ---------------'+imageArr ); 
                        //String jiveUniqueId = imageArr[2];
                        String jiveUniqueId = '';
                        if(imageArr[1] != null){
                            if(imageArr[1].contains('-')){
                                jiveUniqueId = imageArr[1].split('-')[2];
                                if(imageArr[1].split('-').size() > 3){
                                    jiveUniqueId += imageArr[1].split('-')[3];
                                }
                            }else{
                                jiveUniqueId = imageArr[1];
                            }
                        }
                        if(String.isNotBlank(jiveUniqueId)){
                            newImageName =  jiveUniqueId+'_'+imageName;
                        }  else{
                            newImageName = imageName;
                        }
                    }
                    if(newImageName != null && newImageName != '{}'){               
                        imgNameToHrefMap.put(newImageName,anchorURL ); 
                    }
                 }
                 
                 if(anchorURL != null && anchorURL.startsWith(System.Label.Jive_Community_User_Anchor_URL)) {                
                    String comuunityNkName = anchorURL.subString(anchorURL.lastIndexOf('/')+1);               
                    Id UserId = nickNameToIdMap.get(comuunityNkName);
                    String newUserURL = System.Label.Discussion_Community_Url + UserId;               
                    UserAnchorUrlMap.put(anchorURL,newUserURL);
                }              
            }
            //system.debug('!imgNameToHrefMap---------'+imgNameToHrefMap);
            while ( tagsAncerTagMacher.find() ) { 
                String tagLink = tagsAncerTagMacher.group();                
                String tagUrl = tagLink.substringBetween( ' href="', '"' );
                //system.debug('tagUrl ===>'+tagUrl );
                //system.debug('(tagUrl.contains)===>'+tagUrl.contains('?tags='));
                if(tagUrl != null && (tagUrl.startsWith(System.Label.jive_Community_Topic_Anchor_URL) || tagUrl.contains('?tags='))){
                    String tagName = tagLink.substringBetween('>', '</a>'); 
                    //system.debug('tagName=========>'+tagName);
                    tags.add(tagName); 
                    
                    topicUrl2TopicName.put(tagUrl,tagName.toLowerCase().deleteWhitespace()); 
                }
             }
            //system.debug('topicUrl2TopicName----------'+topicUrl2TopicName);
            if(UserAnchorUrlMap != null && UserAnchorUrlMap.size() > 0) {
                //comment mentioned userurl replace
                for(String ss : UserAnchorUrlMap.keySet()) {
                   kav.Description__c = kav.Description__c.replace(ss, UserAnchorUrlMap.get(ss));
                }
            }
            system.debug('divOldVal2NewVal ----------'+divOldVal2NewVal );
            if(divOldVal2NewVal != null && divOldVal2NewVal.size() > 0){
                for(String ss : divOldVal2NewVal.keySet()) {
                   kav.Description__c = kav.Description__c.replace(ss, divOldVal2NewVal.get(ss));
                }
            }
        }
        
         if(tags!=null){                    
             system.debug('topicMap=========='+topicMap);
            for(String tgs : tags){
                System.debug('tgs.toLowerCase().deleteWhitespace()=========='+tgs.toLowerCase().deleteWhitespace());
                system.debug(topicMap.containsKey(tgs.toLowerCase().deleteWhitespace()));
                system.debug(topicMap.containsKey(tgs));
                if(topicMap != null && !topicMap.containsKey(tgs.toLowerCase().deleteWhitespace())){
                    Topic tObj=new Topic();
                    tObj.name=tgs;
                    tObj.NetworkId=NetworkScopeId; 
                    tMap.put(tObj.name,tObj);                            
                }
            }
        }  
        system.debug('tMap=========>'+tMap);    
        //system.debug('imgToDownloadMap==>'+imgToDownloadMap.size());            
        Http http = new Http();
        HttpRequest req= new HttpRequest();
        req.setMethod('GET');  
        req.settimeout(120000);
        for(String imgName:imgToDownloadMap.Keyset()){
            //system.debug('imgToDownloadMap.get(imgName)===>'+imgToDownloadMap.get(imgName));
            req.setEndpoint(imgToDownloadMap.get(imgName));
            req.setHeader('Authorization', 'Basic Z2F1cmF2YjpTRkRDTWlncmF0aW9u');  
            HttpResponse res = new HttpResponse();                // response for image
            
            if(!Test.isRunningTest()){  
                        
                res = http.send(req);
            
            }else{
                Blob bodyBlob = Blob.ValueOf('463286');
                res.setBodyAsBlob(bodyBlob);       
            }
            
            Blob b =  res.getBodyAsBlob();
            ContentVersion cv=new ContentVersion();
            cv.Title = imgName;
            cv.SharingOption = 'A';
            cv.ContentLocation = 'S';
            cv.PathOnClient ='/' + imgName;
            String temp = EncodingUtil.base64Encode(b);
            cv.VersionData = EncodingUtil.base64Decode(temp);
            if(!Test.isrunningTest()){
                cv.NetworkId = NetworkScopeId;
            }
            cntVersionList.add(cv);
        }
        system.debug('cntVersionList===>'+cntVersionList);
        Insert cntVersionList;         // Inserted images to ContentVersion(Files)
        System.debug('tMap=========='+tMap);
        
        if(!tMap.isEmpty()){
            insert tMap.values();
         
            
            for(Topic tt : tMap.values()){
                topicName2Id.put(tt.Name.toLowerCase().deleteWhitespace(), tt.Id);
            }
        }
        for(String tgname : topicMap.keySet()){
            if(!topicName2Id.containsKey(tgname)){
                topicName2Id.put(tgname, topicMap.get(tgname));
            }
        
        }
        
        
        
        System.debug('topicName2Id=========='+topicName2Id);
        List<String> cntVersionIds=new List<String>();
        Map<String,String> cntDocIdMap=new Map<String,String>(); // map of files Title and ContentDocumentId
        if(cntVersionList != null && cntVersionList.size() >0){
            for(contentversion cv:cntVersionList){
                cntVersionIds.add(cv.id);
            }  
            
        }
        
        List<ContentDistribution> cv2cd = new List<ContentDistribution>();
        
        List<ContentVersion> cvListWithDocIds = [select Id, ContentUrl, ContentDocumentId, Title FROM ContentVersion where id IN:cntVersionIds];
        if(cvListWithDocIds != null && cvListWithDocIds.size() >0){
        
             
            for(contentversion cv:cvListWithDocIds){
                MapcontentidDocid.put(cv.Id, cv.ContentDocumentId);
                ContentDistribution cd = new ContentDistribution();
                cd.name = cv.title;
                cd.ContentVersionId = cv.Id;
                cd.PreferencesAllowOriginalDownload = true;
                cd.PreferencesAllowPDFDownload = true;
                cd.PreferencesAllowViewInBrowser = true;
                cd.PreferencesNotifyOnVisit = false;
                cv2cd.add(cd); 
            }
            
        }
        //System.debug('cv2cd------------'+cv2cd);
        insert cv2cd;
        qu.ShareFilesWithLibraries(cntVersionIds, MapcontentidDocid); 
        List<String> cntDistributionIds=new List<String>();
        if(cv2cd != null && cv2cd.size() >0){
            for(ContentDistribution cv : cv2cd){
                cntDistributionIds.add(cv.id);
            }
        }
        //System.debug('cntDistributionIds------------'+cntDistributionIds);
        list<ContentDistribution> contentdList = [Select id,Name, contentVersionid,  ContentDownloadUrl from ContentDistribution where id IN:cntDistributionIds];
        if(contentdList != null && contentdList.size() >0){
            for(ContentDistribution cv : contentdList ){
                cntDocIdMap.put(cv.Name,cv.ContentDownloadUrl);
            }
        }
        //System.debug('cntDocIdMap------------'+cntDocIdMap);
       
        For(Knowledge__kav fi:ArticlesJiveid.keySet()){
            //system.debug('size>>>'+cntDocIdMap.keyset().size());
            //Matcher imgAnchorMatcher = Pattern.compile( '<a(.+?)>' ).matcher( fi.Description__c );
            for(String s:cntDocIdMap.keyset()){
                //system.debug('value>>>'+s);
                //system.debug('imgToDownloadMap.get(s)>>>'+imgToDownloadMap.get(s));
                //system.debug('cntDocIdMap.get(s)>>>'+cntDocIdMap.get(s));
                //system.debug('fi.Description__c===>'+fi.Description__c);
                String oldImageURL = imgToDownloadMap.get(s);
                String newImageURL = cntDocIdMap.get(s);
                //system.debug('!anchorURLName ---------'+s);
                //system.debug('!anchorURLName ----ssss--'+imgNameToHrefMap.containsKey(s));
                fi.Description__c = fi.Description__c.replace(oldImageURL,newImageURL); 
                if(s != null && imgNameToHrefMap.containsKey(s)){
                    fi.Description__c = fi.Description__c.replace(imgNameToHrefMap.get(s),newImageURL);  
                }
                
                //system.debug('Description__c===>'+fi.Description__c);
     
            } 
            
            
           
            if(!topicName2Id.isEmpty() && !topicUrl2TopicName.isEmpty()){
                for(String tpURL: topicUrl2TopicName.keyset()){
                    if(topicName2Id.containsKey(topicUrl2TopicName.get(tpURL)) != null){
                        
                        String topicURl = System.Label.Discussion_Community_Url +topicName2Id.get(topicUrl2TopicName.get(tpURL))+'?tabset-cbf69=2';
                        //System.debug('topicURl -------------'+topicURl );
                        //system.debug('topicUrl2TopicName.get(tpURL)-0--------------'+topicUrl2TopicName.get(tpURL));
                        //system.debug('topicUrl2TopicName--------------'+topicUrl2TopicName);
                        //System.debug('tpURL-------------'+tpURL);
                        fi.Description__c = fi.Description__c.replace(tpURL, topicURl );
                        //System.debug('fi.Description__c-------'+fi.Description__c);
                        
                    }
                }
            }
            map<String, String> tpMap = new Map<String, String>();
            for(string tgs : tags){
                if(!topicName2Id.isEmpty()  && topicName2Id.containsKey(tgs.toLowerCase().deleteWhitespace()) ){
                    string topicId = topicName2Id.get(tgs.toLowerCase().deleteWhitespace());
                    if(fi.Description__c.contains(topicId)){
                        system.debug('tpMap===>'+tpMap);
                        tpMap.put(tgs.toLowerCase().deleteWhitespace(), topicName2Id.get(tgs.toLowerCase().deleteWhitespace()));
                        topic2AssignmentMap.put(fi.title, tpMap);
                    }
                    
                }
            }
             
        }
       
        system.debug('topic2AssignmentMap===>'+topic2AssignmentMap);
        artticleWrap.KnowledgeArticle= ArticlesJiveid.keySet();
        artticleWrap.newTopics2Assign = topic2AssignmentMap;
        Article2Jiveid.putall(ArticlesJiveid);
        //system.debug('Articles===>'+ArticlesJiveid.values());
        //system.debug('ArticleTitle2Jiveid==dddd=>'+ArticleTitle2Jiveid);
        //system.debug('Article2Jiveid=>'+Article2Jiveid);
        return artticleWrap;
        
    }
    
    public void insertRecords(List<SObject> recordToBeInserted ){
        //System.debug('Passed list'+recordToBeInserted);
        Database.SaveResult[] recordList = Database.insert(recordToBeInserted, false);
        for (Database.SaveResult record : recordList ) {
            if (!record.isSuccess()) {
                // Operation failed, so get all errors                
                for(Database.Error err : record.getErrors()) {
                    //System.debug('The following error has occurred while saving Record.'+record);                    
                    //System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    //System.debug('Fields that affected this error: ' + err.getFields());
                }
            }
            
        }
    }
    
    public void insertArticles(List<knowledge__kav> recordToBeInserted ){
        //System.debug('Passed list'+recordToBeInserted);
        List<Url_mapping__c> urlMappingList = new List<Url_mapping__c>();
        List<Error_Log__c> ErrorLogsList =  new List<Error_Log__c>();
        List<string> articleVersionIds=  new List<string>();
        Map<String, KnowledgeArticleVersion> articleDetailMap;
        Database.SaveResult[] recordList = Database.insert(recordToBeInserted, false);
        for(integer k=0; k<recordToBeInserted.size(); k++){
            if(recordList[k].isSuccess()){
                articleVersionIds.add(recordList[k].getId());
            }
        }
        if(!articleVersionIds.isEmpty()){
        articleDetailMap =new Map<String, KnowledgeArticleVersion>([SELECT Id, KnowledgeArticleId, Title,VersionNumber, ArticleNumber FROM KnowledgeArticleVersion
                                    where Id IN :articleVersionIds]);
        }
        for(integer k=0; k<recordToBeInserted.size(); k++){
             if(!recordList[k].isSuccess()){
                //system.debug('Article2Jiveid.get(recordToBeInserted[k])=====>'+Article2Jiveid.get(recordToBeInserted[k]));
                 Error_Log__c Errorlog = new Error_Log__c();
                 Errorlog.Error_Description__c = recordList[k].getErrors()[0].getMessage();
                 Errorlog.Jive_Id__c = Article2Jiveid.get(recordToBeInserted[k]);
                 Errorlog.Object__c = 'Knowledge__kav';
                 Errorlog.Type__c  = 'Article';
                 Errorlog.Name = 'ArticleInsert';
                 ErrorLogsSet.add(Errorlog);
            }
            if(recordList[k].isSuccess()){
               //system.debug('Article2Jiveid==>'+Article2Jiveid);
               //system.debug('recordToBeInserted==>'+recordToBeInserted);
               //system.debug('ArticleTitle2Jiveid.get(recordToBeInserted[k])---=====>'+ArticleTitle2Jiveid.get(recordToBeInserted[k].title));
               Url_mapping__c u = new Url_mapping__c();
               u.Jive_Id__c = ArticleTitle2Jiveid.get(recordToBeInserted[k].title);
               u.Title__c = recordToBeInserted[k].title;
               u.Salesforce_Id__c = articleDetailMap.get(recordList[k].getId()).KnowledgeArticleId;
               u.Type__c = 'Article';
               urlMappingList.add(u);   
            }   
        }
        if(!Test.isRunningTest()){
           if(ErrorLogsSet != null && ErrorLogsSet.size()>0){
              ErrorLogsList.addAll(ErrorLogsSet);
              insert ErrorLogsList ;
          }
        }
        if(urlMappingList != null && !urlMappingList.isEmpty()){
                insert urlMappingList;
            }
    }
    
    public void insertArticleComments(List<Article_Comment__c> recordToBeInserted ){
        //System.debug('Passed list'+recordToBeInserted);
        List<Error_Log__c> ErrorLogsCommentsList =  new List<Error_Log__c>();
        Database.SaveResult[] recordList = Database.insert(recordToBeInserted, false);
        for(integer k=0; k<recordToBeInserted.size(); k++){
             if(!recordList[k].isSuccess()){
                 //system.debug('Article2Jiveid.get(recordToBeInserted[k])=====>'+ArticleComment2JiveId.get(recordToBeInserted[k]));
                 Error_Log__c Errorlog = new Error_Log__c();
                 Errorlog.Error_Description__c = recordList[k].getErrors()[0].getMessage();
                 Errorlog.Jive_Id__c = ArticleComment2JiveId.get(recordToBeInserted[k]);
                 Errorlog.Object__c = 'Article_Comment__c';
                 Errorlog.Type__c  = 'Article';
                 Errorlog.Name = 'ArticleCommentInsert';
                 ErrorLogsCommentsSet.add(Errorlog);
            }   
        }
        if(ErrorLogsCommentsSet != null && ErrorLogsCommentsSet.size()>0){
              ErrorLogsCommentsList.addAll(ErrorLogsCommentsSet);
              insert ErrorLogsCommentsList;
           }
    }
    
    public List<vote> saveLike(Map<string , Sobject> ArticleLikeUrl2Vote){
        //System.debug('In save Like method');
        //System.debug('ArticleLikeUrl2Vote '+ArticleLikeUrl2Vote );
        List<vote>finalvoteLikeList = new List<vote>();
        Set<vote>finalvoteLikeSet = new Set<vote>();
        //Map<String,Id>mapOfJiveIdToUserId = getSFDCUserId();
        //System.debug('UArticleLikeUrl2Vote====================>'+ArticleLikeUrl2Vote);
        String jsonstr = null;
        Http http = new Http();
        HttpRequest req= new HttpRequest();
        req.setMethod('GET');
        req.settimeout(120000);
        if(!ArticleLikeUrl2Vote.isEmpty()){
            for(String ArticleLikeUrl:ArticleLikeUrl2Vote.keySet()){
                //System.debug('URL======================>'+ArticleLikeUrl);
                req.setEndpoint(ArticleLikeUrl);  
                req.setHeader('Authorization', 'Basic Z2F1cmF2YjpTRkRDTWlncmF0aW9u');  
                HttpResponse res = new HttpResponse();
                if(!Test.isRunningTest()){  
                        
                   res = http.send(req);
                        //system.debug('111111111>res' + res);
                        
                    }else{
                        res.setBody('{"itemsPerPage":25,"list":[{"id":"11844","resources":{"followingIn":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/11844/followingIn"},"images":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/11844/images"},"activity":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/11844/activities"},"social":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/11844/@social"},"roles":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/11844/roles"},"streams":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/11844/streams"},"recognition":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/11844/@recognition"},"trendingContent":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/11844/@trendingContent"},"profilePrivacy":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/11844/profilePrivacy"},"trendingPlaces":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/11844/@trendingPlaces"},"avatar":{"allowed":["GET","DELETE","PUT"],"ref":"https://discussions.qualys.com/api/core/v3/people/11844/avatar?a=2188"},"followers":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/11844/@followers"},"pages":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/11844/pages"},"following":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/11844/@following"},"members":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/members/people/11844"},"self":{"allowed":["GET","DELETE","PUT"],"ref":"https://discussions.qualys.com/api/core/v3/people/11844"},"html":{"allowed":["GET"],"ref":"https://discussions.qualys.com/people/BryanU"},"securityGroups":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/11844/securityGroups"},"extprops":{"allowed":["GET","POST","DELETE"],"ref":"https://discussions.qualys.com/api/core/v3/people/11844/extprops"}},"displayName":"Bryan Umbeck","emails":[{"jive_label":"Email","primary":true,"type":"work","value":"bryan.umbeck@imaginexconsulting.com","jive_displayOrder":1,"jive_summaryDisplayOrder":0,"jive_showSummaryLabel":true}],"jive":{"enabled":true,"level":{"description":"Level 3","imageURI":"https://rewards.imgix.net/prod_phx/11fbffd0-71ed-4b9b-95c0-4052c96abccd/level3?updated=d054f22e-e20d-4f63-8838-5ef9257ce93a","name":"Level 3","points":291},"externalContributor":false,"username":"BryanU","visible":true},"name":{"familyName":"Umbeck","formatted":"Bryan Umbeck","givenName":"Bryan"},"type":"person","typeCode":3},{"id":"22527","resources":{"followingIn":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/22527/followingIn"},"images":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/22527/images"},"activity":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/22527/activities"},"social":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/22527/@social"},"roles":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/22527/roles"},"streams":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/22527/streams"},"recognition":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/22527/@recognition"},"trendingContent":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/22527/@trendingContent"},"profilePrivacy":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/22527/profilePrivacy"},"trendingPlaces":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/22527/@trendingPlaces"},"avatar":{"allowed":["GET","DELETE","PUT"],"ref":"https://discussions.qualys.com/api/core/v3/people/22527/avatar?a=3225"},"followers":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/22527/@followers"},"pages":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/22527/pages"},"following":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/22527/@following"},"members":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/members/people/22527"},"self":{"allowed":["GET","DELETE","PUT"],"ref":"https://discussions.qualys.com/api/core/v3/people/22527"},"html":{"allowed":["GET"],"ref":"https://discussions.qualys.com/people/fjimenez"},"securityGroups":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/22527/securityGroups"},"extprops":{"allowed":["GET","POST","DELETE"],"ref":"https://discussions.qualys.com/api/core/v3/people/22527/extprops"}},"displayName":"Felix Jimenez","emails":[{"jive_label":"Email","primary":true,"type":"work","value":"fjimenez@qualys.com","jive_displayOrder":1,"jive_summaryDisplayOrder":0,"jive_showSummaryLabel":true}],"jive":{"enabled":true,"level":{"description":"Level 5","imageURI":"https://rewards.imgix.net/prod_phx/11fbffd0-71ed-4b9b-95c0-4052c96abccd/level5?updated=4bc19e0d-4c6f-4990-9fa0-b6cb9fbb8ab0","name":"Level 5","points":2822},"externalContributor":false,"username":"fjimenez","visible":true},"name":{"familyName":"Jimenez","formatted":"Felix Jimenez","givenName":"Felix"},"type":"person","typeCode":3},{"id":"28153","resources":{"followingIn":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/28153/followingIn"},"images":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/28153/images"},"activity":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/28153/activities"},"social":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/28153/@social"},"roles":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/28153/roles"},"streams":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/28153/streams"},"recognition":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/28153/@recognition"},"trendingContent":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/28153/@trendingContent"},"profilePrivacy":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/28153/profilePrivacy"},"trendingPlaces":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/28153/@trendingPlaces"},"avatar":{"allowed":["GET","DELETE","PUT"],"ref":"https://discussions.qualys.com/api/core/v3/people/28153/avatar?a=1035"},"followers":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/28153/@followers"},"pages":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/28153/pages"},"following":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/28153/@following"},"members":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/members/people/28153"},"self":{"allowed":["GET","DELETE","PUT"],"ref":"https://discussions.qualys.com/api/core/v3/people/28153"},"html":{"allowed":["GET"],"ref":"https://discussions.qualys.com/people/wmeier"},"securityGroups":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/28153/securityGroups"},"extprops":{"allowed":["GET","POST","DELETE"],"ref":"https://discussions.qualys.com/api/core/v3/people/28153/extprops"}},"displayName":"Wesley Meier","emails":[{"jive_label":"Email","primary":true,"type":"work","value":"wmeier@qualys.com","jive_displayOrder":1,"jive_summaryDisplayOrder":0,"jive_showSummaryLabel":true}],"jive":{"enabled":true,"level":{"description":"Level 2","imageURI":"https://rewards.imgix.net/prod_phx/11fbffd0-71ed-4b9b-95c0-4052c96abccd/level2?updated=b32d26ee-446a-40fe-bc33-1f763509a8d8","name":"Level 2","points":84},"externalContributor":false,"username":"wmeier","visible":true},"name":{"familyName":"Meier","formatted":"Wesley Meier","givenName":"Wesley"},"type":"person","typeCode":3},{"id":"17231","resources":{"followingIn":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/17231/followingIn"},"images":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/17231/images"},"activity":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/17231/activities"},"social":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/17231/@social"},"roles":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/17231/roles"},"streams":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/17231/streams"},"recognition":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/17231/@recognition"},"trendingContent":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/17231/@trendingContent"},"profilePrivacy":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/17231/profilePrivacy"},"trendingPlaces":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/17231/@trendingPlaces"},"avatar":{"allowed":["GET","DELETE","PUT"],"ref":"https://discussions.qualys.com/api/core/v3/people/17231/avatar?a=3096"},"followers":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/17231/@followers"},"pages":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/17231/pages"},"following":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/17231/@following"},"members":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/members/people/17231"},"self":{"allowed":["GET","DELETE","PUT"],"ref":"https://discussions.qualys.com/api/core/v3/people/17231"},"html":{"allowed":["GET"],"ref":"https://discussions.qualys.com/people/tsalvador72"},"securityGroups":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/17231/securityGroups"},"extprops":{"allowed":["GET","POST","DELETE"],"ref":"https://discussions.qualys.com/api/core/v3/people/17231/extprops"}},"displayName":"Tim Salvador","emails":[{"jive_label":"Email","primary":true,"type":"work","value":"tim.salvador@imaginexconsulting.com","jive_displayOrder":1,"jive_summaryDisplayOrder":0,"jive_showSummaryLabel":true}],"jive":{"enabled":true,"level":{"description":"Level 1","imageURI":"https://rewards.imgix.net/prod_phx/11fbffd0-71ed-4b9b-95c0-4052c96abccd/level1?updated=2442e81d-ec4f-4104-8c3b-1fb468dc3a3a","name":"Level 1","points":38},"externalContributor":false,"username":"tsalvador72","visible":true},"name":{"familyName":"Salvador","formatted":"Tim Salvador","givenName":"Tim"},"type":"person","typeCode":3},{"id":"37264","resources":{"followingIn":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/37264/followingIn"},"images":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/37264/images"},"activity":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/37264/activities"},"social":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/37264/@social"},"roles":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/37264/roles"},"streams":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/37264/streams"},"recognition":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/37264/@recognition"},"trendingContent":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/37264/@trendingContent"},"profilePrivacy":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/37264/profilePrivacy"},"trendingPlaces":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/37264/@trendingPlaces"},"avatar":{"allowed":["GET","DELETE","PUT"],"ref":"https://discussions.qualys.com/api/core/v3/people/37264/avatar?a=3232"},"followers":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/37264/@followers"},"pages":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/37264/pages"},"following":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/37264/@following"},"members":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/members/people/37264"},"self":{"allowed":["GET","DELETE","PUT"],"ref":"https://discussions.qualys.com/api/core/v3/people/37264"},"html":{"allowed":["GET"],"ref":"https://discussions.qualys.com/people/agasu_mw"},"securityGroups":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/37264/securityGroups"},"extprops":{"allowed":["GET","POST","DELETE"],"ref":"https://discussions.qualys.com/api/core/v3/people/37264/extprops"}},"displayName":"Mornay Walters","emails":[{"jive_label":"Email","primary":true,"type":"work","value":"mwalters@anglogoldashanti.com","jive_displayOrder":1,"jive_summaryDisplayOrder":0,"jive_showSummaryLabel":true}],"jive":{"enabled":true,"level":{"description":"Level 2","imageURI":"https://rewards.imgix.net/prod_phx/11fbffd0-71ed-4b9b-95c0-4052c96abccd/level2?updated=b32d26ee-446a-40fe-bc33-1f763509a8d8","name":"Level 2","points":242},"externalContributor":false,"username":"agasu_mw","visible":true},"name":{"familyName":"Walters","formatted":"Mornay Walters","givenName":"Mornay"},"type":"person","typeCode":3},{"id":"33465","resources":{"followingIn":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/33465/followingIn"},"images":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/33465/images"},"activity":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/33465/activities"},"social":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/33465/@social"},"roles":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/33465/roles"},"streams":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/33465/streams"},"recognition":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/33465/@recognition"},"trendingContent":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/33465/@trendingContent"},"profilePrivacy":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/33465/profilePrivacy"},"trendingPlaces":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/33465/@trendingPlaces"},"avatar":{"allowed":["GET","DELETE","PUT"],"ref":"https://discussions.qualys.com/api/core/v3/people/33465/avatar?a=1023"},"followers":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/33465/@followers"},"pages":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/33465/pages"},"following":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/33465/@following"},"members":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/members/people/33465"},"self":{"allowed":["GET","DELETE","PUT"],"ref":"https://discussions.qualys.com/api/core/v3/people/33465"},"html":{"allowed":["GET"],"ref":"https://discussions.qualys.com/people/trnty_av"},"securityGroups":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/33465/securityGroups"},"extprops":{"allowed":["GET","POST","DELETE"],"ref":"https://discussions.qualys.com/api/core/v3/people/33465/extprops"}},"displayName":"Anna Barnes","emails":[{"jive_label":"Email","primary":true,"type":"work","value":"anna.vitale@trinity-health.org","jive_displayOrder":1,"jive_summaryDisplayOrder":0,"jive_showSummaryLabel":true}],"jive":{"enabled":true,"level":{"description":"Level 4","imageURI":"https://rewards.imgix.net/prod_phx/11fbffd0-71ed-4b9b-95c0-4052c96abccd/level4?updated=fc876a9d-1ab2-4c6e-8523-71a1079486b5","name":"Level 4","points":773},"externalContributor":false,"username":"trnty_av","visible":true},"name":{"familyName":"Barnes","formatted":"Anna Barnes","givenName":"Anna"},"type":"person","typeCode":3},{"id":"7720","resources":{"followingIn":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/7720/followingIn"},"images":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/7720/images"},"activity":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/7720/activities"},"social":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/7720/@social"},"roles":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/7720/roles"},"streams":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/7720/streams"},"recognition":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/7720/@recognition"},"trendingContent":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/7720/@trendingContent"},"profilePrivacy":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/7720/profilePrivacy"},"trendingPlaces":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/7720/@trendingPlaces"},"avatar":{"allowed":["GET","DELETE","PUT"],"ref":"https://discussions.qualys.com/api/core/v3/people/7720/avatar?a=3132"},"followers":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/7720/@followers"},"pages":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/7720/pages"},"following":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/7720/@following"},"members":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/members/people/7720"},"self":{"allowed":["GET","DELETE","PUT"],"ref":"https://discussions.qualys.com/api/core/v3/people/7720"},"html":{"allowed":["GET"],"ref":"https://discussions.qualys.com/people/JGregory"},"securityGroups":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/7720/securityGroups"},"extprops":{"allowed":["GET","POST","DELETE"],"ref":"https://discussions.qualys.com/api/core/v3/people/7720/extprops"}},"displayName":"Joe Gregory","emails":[{"jive_label":"Email","primary":true,"type":"work","value":"jgregory@qualys.com","jive_displayOrder":1,"jive_summaryDisplayOrder":0,"jive_showSummaryLabel":true}],"jive":{"enabled":true,"level":{"description":"Level 3","imageURI":"https://rewards.imgix.net/prod_phx/11fbffd0-71ed-4b9b-95c0-4052c96abccd/level3?updated=d054f22e-e20d-4f63-8838-5ef9257ce93a","name":"Level 3","points":657},"externalContributor":false,"username":"JGregory","visible":true},"name":{"familyName":"Gregory","formatted":"Joe Gregory","givenName":"Joe"},"type":"person","typeCode":3},{"id":"33626","resources":{"followingIn":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/33626/followingIn"},"images":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/33626/images"},"activity":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/33626/activities"},"social":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/33626/@social"},"roles":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/33626/roles"},"streams":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/33626/streams"},"recognition":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/33626/@recognition"},"trendingContent":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/33626/@trendingContent"},"profilePrivacy":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/33626/profilePrivacy"},"trendingPlaces":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/33626/@trendingPlaces"},"avatar":{"allowed":["GET","DELETE","PUT"],"ref":"https://discussions.qualys.com/api/core/v3/people/33626/avatar?a=1014"},"followers":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/33626/@followers"},"pages":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/33626/pages"},"following":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/33626/@following"},"members":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/members/people/33626"},"self":{"allowed":["GET","DELETE","PUT"],"ref":"https://discussions.qualys.com/api/core/v3/people/33626"},"html":{"allowed":["GET"],"ref":"https://discussions.qualys.com/people/ctata"},"securityGroups":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/33626/securityGroups"},"extprops":{"allowed":["GET","POST","DELETE"],"ref":"https://discussions.qualys.com/api/core/v3/people/33626/extprops"}},"displayName":"Cyrus Tata","emails":[{"jive_label":"Email","primary":true,"type":"work","value":"ctata@qualys.com","jive_displayOrder":1,"jive_summaryDisplayOrder":0,"jive_showSummaryLabel":true}],"jive":{"enabled":true,"level":{"description":"Level 2","imageURI":"https://rewards.imgix.net/prod_phx/11fbffd0-71ed-4b9b-95c0-4052c96abccd/level2?updated=b32d26ee-446a-40fe-bc33-1f763509a8d8","name":"Level 2","points":136},"externalContributor":false,"username":"ctata","visible":true},"name":{"familyName":"Tata","formatted":"Cyrus Tata","givenName":"Cyrus"},"type":"person","typeCode":3},{"id":"27242","resources":{"followingIn":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/27242/followingIn"},"images":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/27242/images"},"activity":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/27242/activities"},"social":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/27242/@social"},"roles":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/27242/roles"},"streams":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/27242/streams"},"recognition":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/27242/@recognition"},"trendingContent":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/27242/@trendingContent"},"profilePrivacy":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/27242/profilePrivacy"},"trendingPlaces":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/27242/@trendingPlaces"},"avatar":{"allowed":["GET","DELETE","PUT"],"ref":"https://discussions.qualys.com/api/core/v3/people/27242/avatar?a=3422"},"followers":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/27242/@followers"},"pages":{"allowed":["GET","POST"],"ref":"https://discussions.qualys.com/api/core/v3/people/27242/pages"},"following":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/27242/@following"},"members":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/members/people/27242"},"self":{"allowed":["GET","DELETE","PUT"],"ref":"https://discussions.qualys.com/api/core/v3/people/27242"},"html":{"allowed":["GET"],"ref":"https://discussions.qualys.com/people/kschuster"},"securityGroups":{"allowed":["GET"],"ref":"https://discussions.qualys.com/api/core/v3/people/27242/securityGroups"},"extprops":{"allowed":["GET","POST","DELETE"],"ref":"https://discussions.qualys.com/api/core/v3/people/27242/extprops"}},"displayName":"Kyle Schuster","emails":[{"jive_label":"Email","primary":true,"type":"work","value":"kschuster@qualys.com","jive_displayOrder":1,"jive_summaryDisplayOrder":0,"jive_showSummaryLabel":true}],"jive":{"enabled":true,"level":{"description":"Level 2","imageURI":"https://rewards.imgix.net/prod_phx/11fbffd0-71ed-4b9b-95c0-4052c96abccd/level2?updated=b32d26ee-446a-40fe-bc33-1f763509a8d8","name":"Level 2","points":198},"externalContributor":false,"username":"kschuster","visible":true},"name":{"familyName":"Schuster","formatted":"Kyle Schuster","givenName":"Kyle"},"type":"person","typeCode":3}],"startIndex":0}');
                }
                
                //String temp = res.getBody().replace('\n','');
                jsonstr = res.getBody().replace('list','items');
                //System.debug('response======>'+jsonstr);
                if(jsonstr != null){
                    UserList wrapperinstance = (UserList ) System.JSON.deserialize(jsonstr,UserList.class);
                    //System.debug('WrapperInstance++++++='+wrapperinstance);
                    //System.debug('WrapperInstance size>>>>>>>>>>'+wrapperinstance.items.size());
                    if(wrapperinstance.items != null && wrapperinstance.items.size() > 0){
                        //System.debug('***************************');
                        for(Integer j=0; j<wrapperinstance.items.size(); j++){
                            vote KavLike= new vote();
                            Knowledge__kav kav;
                            //System.debug('***************************'+ArticleLikeUrl2Vote);
                            //system.debug('title===>'+ ArticleLikeUrl2Vote.get(ArticleLikeUrl).id);
                            //system.debug('titleArticleLikeUrl===>'+ ArticleLikeUrl2Vote.get(ArticleLikeUrl));
                            if(!Test.isRunningTest()){
                            kav= [SELECT Id, KnowledgeArticleId, Language, Title, UrlName FROM Knowledge__kav where id =:  ArticleLikeUrl2Vote.get(ArticleLikeUrl).id];
                            KavLike.ParentId = kav.KnowledgeArticleId;
                            KavLike.Type = 'UP';
                            if(wrapperinstance.items.get(j).id != null && jiveIdToUserIdMap.containsKey(wrapperinstance.items.get(j).id) ){
                                KavLike.CreatedById = jiveIdToUserIdMap.get(wrapperinstance.items.get(j).id);
                            } 
                            //system.debug('KavLike===>'+KavLike);
                            finalvoteLikeSet.add(KavLike);
                            }
                            else{
                                 KavLike.ParentId='kA2560000008U6lCAE';
                                 KavLike.Type = 'UP';
                                 KavLike.CreatedById ='00556000004CHbnAAG';
                                 finalvoteLikeList.add(KavLike);
                            }
                            //finalvoteLikeList.add(KavLike);
                            
                        }  
                    } 
                }                  
            } 
            if(finalvoteLikeSet != null && finalvoteLikeSet.size() > 0){
                finalvoteLikeList.addAll(finalvoteLikeSet);
            }
     
        }
        return finalvoteLikeList;
    }
    public List<Article_Comment__c> saveImageForArticleComment(List<Article_Comment__c> articleCommentList){           
        Map<String,String> imgToDownloadMap=new Map<String,String>(); 
        Map<String,String> imgNameToHrefMap=new Map<String,String>(); 
        QualysUtils qu = new QualysUtils();
        List<ContentVersion> cntVersionList = new List<ContentVersion>();
        Map<string,string> MapcontentidDocid = new Map<string,string>();
        for(Article_Comment__c ac : articleCommentList){
        //system.debug('articleCommentList===>'+ac);
            Matcher imgMatcher = Pattern.compile( '<img(.+?)>' ).matcher( ac.Content__c );
            Matcher imgAnchorMatcher = Pattern.compile( '<a(.+?)>' ).matcher( ac.Content__c );  
            Matcher tagsAncerTagMacher = Pattern.compile( '<a(.+?)/a>' ).matcher( ac.Content__c); 
            while ( imgMatcher.find() ) {
                String imageTag = imgMatcher.group();                   
                String imageURL = imageTag.substringBetween( ' src="', '"' );
                if(imageURL.contains(System.Label.Jive_Community_Image_Anchor_URL)){
                    String imageName = imageURL.subString(imageURL.lastIndexOf('/')+1);
                    String textStripImageName = 'downloadImage';
                    String newImageName ='';
                    if(imageURL.contains(textStripImageName)){
                        String[] imageArr = imageURL.split(textStripImageName)[1].split('/');  
                        String jiveUniqueId = '';
                        if(imageArr[1] != null){
                            if(imageArr[1].contains('-')){
                                jiveUniqueId = imageArr[1].split('-')[2];
                                if(imageArr[1].split('-').size() > 3){
                                    jiveUniqueId += imageArr[1].split('-')[3];
                                }
                            }else{
                                jiveUniqueId = imageArr[1];
                            }
                        }
                        if(String.isNotBlank(jiveUniqueId)){
                            newImageName =  jiveUniqueId+'_'+imageName;
                        }  else{
                            newImageName = imageName;
                        }
                        
                    }
                    else{
                        newImageName = imageName;
                    }
                    imgToDownloadMap.put(newImageName, imageURL);     // Created a map of ImageName and ImageUrl
                    //system.debug('imgToDownloadMap==>'+imgToDownloadMap);
                }
            }
            while ( imgAnchorMatcher.find() ) {                   
                String imgAncerTag = imgAnchorMatcher.group(); 
                //system.debug('111111111>fc.imgAncerTag ' +imgAncerTag);   
                String anchorURL = imgAncerTag.substringBetween( ' href="', '"' );
                if(anchorURL != null && anchorURL.startsWith(System.Label.Jive_Community_User_Anchor_URL)) {
                    //system.debug('UserURL@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ ' + anchorURL);
                    String comuunityNkName = anchorURL.subString(anchorURL.lastIndexOf('/')+1);
                    //system.debug('comuunityNkName @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ ' + comuunityNkName );
                    Id UserId = nickNameToIdMap.get(comuunityNkName);
                    String newUserURL = System.Label.Discussion_Community_Url + UserId;
                    //String newUserURL = '/discussions/s/profile/' + UserId;
                    //system.debug('newUserURL @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ ' + newUserURL );
                    UserAnchorUrlMap.put(anchorURL,newUserURL);
                } 
                
                if(anchorURL != null && (anchorURL.contains(System.Label.Jive_Community_Image_Anchor_URL) || anchorURL.contains('/servlet/JiveServlet'))){
                    String imageName = anchorURL.subString(anchorURL.lastIndexOf('/')+1);
                     String textStripImageName = 'showImage';
                     String newImageName ='';
                     if(anchorURL.contains(textStripImageName)){
                        String[] imageArr = anchorURL.split(textStripImageName)[1].split('/'); 
                      
                        
                        //System.debug('imageArr ---------------'+imageArr ); 
                        //String jiveUniqueId = imageArr[2];
                        String jiveUniqueId = '';
                        if(imageArr[1] != null){
                            if(imageArr[1].contains('-')){
                                jiveUniqueId = imageArr[1].split('-')[2];
                                if(imageArr[1].split('-').size() > 3){
                                    jiveUniqueId += imageArr[1].split('-')[3];
                                }
                            }else{
                                jiveUniqueId = imageArr[1];
                            }
                        }
                        if(String.isNotBlank(jiveUniqueId)){
                            newImageName =  jiveUniqueId+'_'+imageName;
                        }  else{
                            newImageName = imageName;
                        }
                    }
                    if(newImageName != null && newImageName != '{}'){
                        imgNameToHrefMap.put(newImageName ,anchorURL );
                    } 
                }
                
                       
                
                
                /*if(anchorURL.contains('?tags=')){
                    //system.debug('anchorURL===.'+anchorURL);
                    String tagName = anchorURL.substringAfterLast('?tags=');
                    if(String.isNotBlank(tagName)){
                        ac.Content__c = ac.Content__c.remove(tagName);
                    }
                    
                }*/
            }
            String tagToLink = '';
             //System.debug('tagsAncerTagMacher'+tagsAncerTagMacher);            
            while ( tagsAncerTagMacher.find() ) {                   
                String tagLink = tagsAncerTagMacher.group();    
                String tagName = tagLink.substringBetween('>', '</a>'); 
                String tagUrl = tagLink.substringBetween( ' href="', '"' );
                if(tagUrl != null && (tagUrl.startsWith(System.Label.jive_Community_Topic_Anchor_URL) || tagUrl.contains('?tags='))){ 
                    ac.Content__c=ac.Content__c.remove(tagLink);                   
                    ac.Content__c = ac.Content__c.remove(tagName);
                    
                }
            }  
        
            if(UserAnchorUrlMap != null && UserAnchorUrlMap.size() > 0) {
                //comment mentioned userurl replace
                for(String ss : UserAnchorUrlMap.keySet()) {
                   ac.Content__c = ac.Content__c.replace(ss, UserAnchorUrlMap.get(ss));
                }
            }
        }
        Http http = new Http();
        HttpRequest req= new HttpRequest();
        req.setMethod('GET');  
        for(String imgName:imgToDownloadMap.Keyset()){
            //system.debug('imgToDownloadMap.get(imgName)===>'+imgToDownloadMap.get(imgName));
            req.setEndpoint(imgToDownloadMap.get(imgName));
            req.setHeader('Authorization', 'Basic Z2F1cmF2YjpTRkRDTWlncmF0aW9u');  
            req.settimeout(120000);
            HttpResponse res = new HttpResponse();       
            if(!Test.isRunningTest()){  
            
                res = http.send(req);
            
            }else{
                Blob bodyBlob = Blob.ValueOf('463286');
                res.setBodyAsBlob(bodyBlob);       
             }
            Blob b =  res.getBodyAsBlob();
            ContentVersion cv=new ContentVersion();
            cv.Title = imgName;
            cv.SharingOption = 'A';
            cv.ContentLocation = 'S';
            cv.PathOnClient ='/' + imgName;
            String temp = EncodingUtil.base64Encode(b);
            cv.VersionData = EncodingUtil.base64Decode(temp);
            if(!Test.isrunningTest()){
                cv.NetworkId = NetworkScopeId;
            }
            cntVersionList.add(cv);
        }
        //system.debug('cntVersionList===>'+cntVersionList);
        Insert cntVersionList;         // Inserted images to ContentVersion(Files)
        
        List<String> cntVersionIds=new List<String>();
        Map<String,String> cntDocIdMap=new Map<String,String>(); // map of files Title and ContentDocumentId
        for(contentversion cv:cntVersionList){
            cntVersionIds.add(cv.id);
        }   
        List<ContentDistribution> cv2cd = new List<ContentDistribution>();
        List<ContentVersion> cvListWithDocIds = [select Id, ContentUrl, ContentDocumentId, Title FROM ContentVersion where id IN:cntVersionIds];
        if(cvListWithDocIds != null && cvListWithDocIds.size() >0){
            for(contentversion cv:cvListWithDocIds){
                MapcontentidDocid.put(cv.Id, cv.ContentDocumentId);
                ContentDistribution cd = new ContentDistribution();
                cd.name = cv.title;
                cd.ContentVersionId = cv.Id;
                cd.PreferencesAllowOriginalDownload = true;
                cd.PreferencesAllowPDFDownload = true;
                cd.PreferencesAllowViewInBrowser = true;
                cd.PreferencesNotifyOnVisit = false;
                cv2cd.add(cd); 
            }
        }
        insert cv2cd;
        qu.ShareFilesWithLibraries(cntVersionIds, MapcontentidDocid);
        
        List<String> cntDistributionIds=new List<String>();
        for(ContentDistribution cv : cv2cd){
            cntDistributionIds.add(cv.id);
        }
        
        list<ContentDistribution> contentdList = [Select id,Name, contentVersionid,  ContentDownloadUrl from ContentDistribution where id IN:cntDistributionIds];
        if(contentdList != null && contentdList.size() >0){
            for(ContentDistribution cv : contentdList ){
                cntDocIdMap.put(cv.Name,cv.ContentDownloadUrl);
            }
        }
        
        For(Article_Comment__c aComment : articleCommentList){           
            for(String s:cntDocIdMap.keyset()){
                aComment.Content__c = aComment.Content__c.replace(imgToDownloadMap.get(s),cntDocIdMap.get(s));                 
                if(s != null && imgNameToHrefMap.containsKey(s) && imgNameToHrefMap.get(s) !=null){
                    aComment.Content__c = aComment.Content__c.replace(imgNameToHrefMap.get(s),cntDocIdMap.get(s));
                }
            }             
        }       
        return articleCommentList;        
    }
       
    public List<ContentDocumentLink> saveAttachmentsForArticle(Map<String, Knowledge__kav> attachmentUrl2ArticleMap){
        List<ContentVersion> cntVersionList = new List<ContentVersion>();
        Map<Id,ContentVersion> mapCvId2FiId =new Map<Id,ContentVersion>();
        Map<Id, List<ContentVersion>> articleIdToContentVersion = new Map<Id, List<ContentVersion>>();
        Map<id,id> MapcontentidDocid = new Map<id,id>();
        String jsonstr = null;
        Http http = new Http();
        HttpRequest req= new HttpRequest();
        req.setMethod('GET');
        req.settimeout(120000);
        if(!attachmentUrl2ArticleMap.isEmpty()){
            for(String attachmentUrl : attachmentUrl2ArticleMap.keySet()){
                 string endpoint = '';
                List<string> s = attachmentUrl.split('-#-');
                List<string> url = s[1].split('/v3/');
                if(url != null && url.size() > 0){
                    endpoint = communityUrlForAttachments +url[1];
                }
                req.setEndpoint(endpoint);   
                req.setHeader('Authorization', 'Basic Z2F1cmF2YjpTRkRDTWlncmF0aW9u'); 
                HttpResponse res = new HttpResponse();
                if(!Test.isRunningTest()){                         
                    res = http.send(req);                        
                }else{
                    res.setBody('{"list":[{"id":"28617","resources":{"self":{"allowed":["GET","DELETE"],"ref":"https://discussions.qualys.com/api/core/v3/attachments/28617"}},"contentType":"application/pdf","name":"Qualys FIM in Audit-Compatible Mode.pdf","size":530413,"url":"https://discussions.qualys.com/api/core/v3/attachments/28617/data","status":"published","doUpload":false,"type":"attachment","typeCode":13}]}');
                }
                Blob b =  res.getBodyAsBlob();
                ContentVersion cv=new ContentVersion();
                cv.Title=s[0];
                cv.PathOnClient ='/' + s[0];
                cv.SharingOption = 'A';
                cv.ContentLocation = 'S';
                if(!Test.isRunningTest()){ 
                   cv.NetworkId = NetworkScopeId;
                }
                //cv.LastModifiedDate = attachmentUrl2ArticleMap.get(attachmentUrl).CreatedDate;
                //cv.FirstPublishLocationId = attachmentUrl2ArticleMap.get(attachmentUrl).CreatedById;
                
                String temp = EncodingUtil.base64Encode(b);
                cv.VersionData = EncodingUtil.base64Decode(temp);
                cntVersionList.add(cv);
                
                if(articleIdToContentVersion.containsKey(attachmentUrl2ArticleMap.get(attachmentUrl).id)) {
                    List<ContentVersion> cvList = articleIdToContentVersion.get(attachmentUrl2ArticleMap.get(attachmentUrl).id);
                    cvList.add(cv);
                    articleIdToContentVersion.put(attachmentUrl2ArticleMap.get(attachmentUrl).id, cvList);
                } else {
                    articleIdToContentVersion.put(attachmentUrl2ArticleMap.get(attachmentUrl).id, new List<ContentVersion> {cv });
                }                      
            }
        }
        insert cntVersionList;
        list<id> cvListid = new list<id>();
        if(cntVersionList != null && cntVersionList.size() >0){
            for(ContentVersion contentV : cntVersionList){
                cvListid.add(contentV.id);
            }
        }
        
        list<ContentVersion> contentidDOcid=[SELECT Id,ContentDocumentId FROM ContentVersion WHERE Id IN:cvListid];
        if(contentidDOcid != null && contentidDOcid.size() >0){
            for(ContentVersion cvid:contentidDOcid){
                MapcontentidDocid.put(cvid.id,cvid.ContentDocumentId);
            }
        }
        //system.debug('MapcontentidDocid==>'+MapcontentidDocid);
        //system.debug('articleIdToContentVersion==>'+articleIdToContentVersion);
        list<ContentDocumentLink> ContentDocLink= New list<ContentDocumentLink>();
        if(!articleIdToContentVersion.isEmpty()){
            for(Id fId: articleIdToContentVersion.keySet()){
                for( ContentVersion cv:articleIdToContentVersion.get(fId)){
                    ContentDocumentLink cdl = New ContentDocumentLink();
                    cdl.LinkedEntityId = fId;
                    cdl.ContentDocumentId = MapcontentidDocid.get(cv.Id);
                    cdl.Visibility = 'AllUsers';
                    cdl.shareType = 'V';
                    ContentDocLink.add(cdl); 
                }
            }
        }
        return ContentDocLink;
    }
    public class ArticleTagWrapper{
      public set<knowledge__kav> KnowledgeArticle{get;set;}
      public Map<String,Map<String,String>> newTopics2Assign{get;set;}
    }
}