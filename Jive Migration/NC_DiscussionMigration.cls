global class NC_DiscussionMigration implements  Database.Batchable<String>,Database.AllowsCallouts,Database.Stateful{
    Jive_Administrator__c jiveAdministratorCUstomSetting = Jive_Administrator__c.getValues('Url');
    migr migrationImplObj=new migr();
    
    Map<String,String> topicMap=new Map<String,String>();
    List<NC_feedItemWrapper> fiWrapperList=new List<NC_feedItemWrapper>();
    Map<string, NC_feedItemWrapper> fiTitle2WrapperRec = new Map<string, NC_feedItemWrapper>();
    Map<String,FeedItem> feedItem2LikesMap=new Map<String,FeedItem>(); // Addition by Gaurav on 20 Jan
    Map<String[],FeedItem> feedItemTagsMap=new Map<String[],FeedItem>();
    Map<string,FeedItem> attachmentUrl2Fi = new Map<string,FeedItem> ();
    Map<String, FeedItem> jiveId2FIMap = new Map<String, FeedItem>();//
    Map<string,string> fITitle2JiveId = new Map<string,string> (); // added to insert Error logs for failed records. 
    Map<string,string> fITitle2PlaceName = new Map<string,string> (); // added to insert Error logs for failed records. 
    Map<string,string> fITitle2CommentUrl = new Map<string,string> (); // added to insert Error logs for failed records. 
    Decimal count,TotalItems;
    Integer startIndex;
    String placeName, threadJiveId, contentType;
    String NetworkScopeId = jiveAdministratorCUstomSetting.NetworkId__c;
    
    public NC_DiscussionMigration(Integer startIndex,Decimal count,Decimal TotalItems, String threadJiveId, String placeName, string contentType){
       this.startIndex=startIndex;
       this.count=count;
       this.TotalItems=TotalItems;
       this.placeName=placeName;
       this.threadJiveId=threadJiveId;
       this.contentType = contentType;
    }
                
    global Iterable<String> start(Database.BatchableContext BC) { 
        //List<FeedItem> feedList=new List<FeedItem>();    
       
        fiWrapperList = migrationImplObj.getAllDiscussionData(startIndex,count,TotalItems, threadJiveId, placeName, contentType);  
        system.debug('FI WrapperList'+fiWrapperList );
        for(NC_feedItemWrapper obj:fiWrapperList){
            //feedList.add(obj.feedItem); 
            jiveId2FIMap.put(obj.jiveId, obj.feedItem); 
            fiTitle2WrapperRec.put(obj.feedItem.title, obj);
            fITitle2JiveId.put(obj.feedItem.title , obj.jiveId);
            fITitle2PlaceName.put(obj.feedItem.title, obj.placeName); 
            fITitle2CommentUrl.put(obj.feedItem.title, obj.commentUrl);
        } 
                      
        for(Topic t:[select id,Name, NetworkId from Topic where NetworkId =:NetworkScopeId ]){
            system.debug('Network Topic ' + t.NetworkId);
            topicMap.put(t.name.toLowerCase().deleteWhitespace(),t.id); 
        }
        //System.debug('FeedList'+feedList);
        //return feedList;
        return  new List<string>(jiveId2FIMap.keySet());
    }
    
    global void execute(Database.BatchableContext BC,  List<String> feedItemJiveId) {
        List<TopicAssignment> tAssignmentList = new List<TopicAssignment>(); 
        List<FeedItem> feedListWithImages = new List<FeedItem>();
        Map<String, FeedItem> jiveId2FI = new Map<String, FeedItem>();
        for(String s:feedItemJiveId){
            jiveId2FI.put(s,jiveId2FIMap.get(s));      
        }
        feedListWithImages.addAll(migrationImplObj.saveImageForFeedItem(jiveId2FI));
        System.debug('feedItem.Body#########fff#'+feedListWithImages[0].Body.Length()); 
        //feedListWithImages = (migrationImplObj.saveImageForFeedItem(feedItemList));        
        insertFeedItem(feedListWithImages);
        
        System.debug('feedListWithImages#########rr#'+feedListWithImages);
        for(Feeditem fi:feedListWithImages) {
            if(Test.isRunningTest()){
                fi.id = '0D58A00000NTRiMSAX';
            }
            if(fi.id != null){
                
                NC_feedItemWrapper fiwObj = fiTitle2WrapperRec.get(fi.Title);   
                                                     
                
                feedItem2LikesMap.put(fiwObj.likeUrl, fi); 
                
               if(fiwObj.helpfullUrl != null){
                     feedItem2LikesMap.put(fiwObj.helpfullUrl, fi); 
                }
                
                System.debug('feedItem2LikesMap^^^^^^^'+feedItem2LikesMap);
                
                if(fiwObj.attachmentList != null && fiwObj.attachmentList.size() >0){
                    for(discussionJSON.fileStr s: fiwObj.attachmentList){
                        if(s != null && s.name != null && s.url != null){
                            attachmentUrl2Fi.put(s.name+'-#-'+s.url,fi);  
                        }
                    }
                }
                
                 if(!fiwObj.fileUrl2Name.isEmpty()){
                    for(string ss : fiwObj.fileUrl2Name.keySet()){
                        string name = fiwObj.fileUrl2Name.get(ss);
                        string url = ss;
                        attachmentUrl2Fi.put(name+'-#-'+url,fi); 
                    }
                    system.debug('KavwObj.attachmentUrl2Fi====>'+attachmentUrl2Fi);
                }
                
                System.debug('Tags##############'+fiwObj.tags);
                for(Integer l=0;l<fiwObj.tags.size();l++){
                    TopicAssignment tAssignmnt=new TopicAssignment();
                    System.debug('Tags##############'+fiwObj.tags[l].toLowerCase().deleteWhitespace().length());
                    tAssignmnt.TopicId=topicMap.get(fiwObj.tags[l].toLowerCase().deleteWhitespace()); 
                    tAssignmnt.EntityId=fi.id;
                    tAssignmnt.NetworkId = NetworkScopeId;
                    tAssignmentList.add(tAssignmnt); 
                    
                }                                        
            }
        }
        if(tAssignmentList != null && tAssignmentList.size() > 0){
            System.debug('Topic Assignment List'+tAssignmentList);
            System.debug('size of topic asssignment list'+tAssignmentList.size());
            migrationImplObj.insertRecords(tAssignmentList);     
        }
    }
    
    public void insertFeedItem(List<feedItem> recordToBeInserted ){
         List<Url_mapping__c> urlMappingList = new List<Url_mapping__c>();
         List<Error_Log__c>errorLogList = new List<Error_Log__c>();
         Database.SaveResult[] recordList = Database.insert(recordToBeInserted, false);
         System.debug('recordList '+recordList);
         for(integer i=0; i<recordToBeInserted.size() ;i++){
             System.debug('recordToBeInserted[i].title#########fff#'+recordToBeInserted[i].body.Length()); 
             System.debug('recordToBeInserted[i].title#########fff#'+recordToBeInserted[i].title.Length()); 
            if(!recordList[i].isSuccess()){
                for (Database.Error e : recordList[i].getErrors()){                                                       
                    Error_Log__c log = new Error_Log__c();
                    log.Type__c = 'Discussion';
                    log.Name = 'FeedItemInsert';
                    System.debug('gggggg'+recordToBeInserted[i].title);
                    log.Jive_Id__c = fITitle2JiveId.get(recordToBeInserted[i].title);
                    log.Error_Description__c = e.getMessage() + 'at -' + e.getFields();
                    //log.Object__c = 'FeedItem';
                    errorLogList.add(log); 
                }
            }
            if(recordList[i].isSuccess()){
                Url_mapping__c u = new Url_mapping__c();
                u.Jive_Id__c = fITitle2JiveId.get(recordToBeInserted[i].title);
                u.Salesforce_Id__c = recordList[i].getId();
                u.Type__c = 'Discussion';
                u.Title__c = recordToBeInserted[i].title;
                u.Place_Name__c = fITitle2PlaceName.get(recordToBeInserted[i].title);
                u.Comment_Url__C = fITitle2CommentUrl.get(recordToBeInserted[i].title);
                //u.isDuplicate__c = true;
                urlMappingList.add(u);
                
            }
        }
        if(errorLogList != null && !errorLogList.isEmpty()){
            insert errorLogList;
        }
        if(urlMappingList != null && !urlMappingList.isEmpty()){
            insert urlMappingList;
        }
    }
    
    
    global void finish(Database.BatchableContext BC) {
        //NC_FeedCommentMigration obj = new NC_FeedCommentMigration (feedItemFrCommentMap);
       //database.executeBatch(obj, 50);
        
        Q_SaveFIAttachment attachObj = new Q_SaveFIAttachment(attachmentUrl2Fi);
        database.executeBatch(attachObj , 50);
        
        Q_SaveLike likeObj = new Q_SaveLike (feedItem2LikesMap, false);
        database.executeBatch(likeObj , 50);
         
    }
}