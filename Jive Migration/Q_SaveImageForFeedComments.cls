global class Q_SaveImageForFeedComments implements Database.Batchable<sObject>,Database.AllowsCallouts,Database.Stateful{
    //NC_MigrationImplementation migrationImplObj=new NC_MigrationImplementation();
    migr migrationImplObj=new migr();
    
    List<CustomFeedComment__c> feedCommentList = new List<CustomFeedComment__c>();
    List<CustomFeedComment__c> feedCommentList2insert = new List<CustomFeedComment__c>();
    Map<string , FeedComment>  FcLikeUrl2FeedComment = new Map<string , FeedComment>();
    
    public Q_SaveImageForFeedComments (List<CustomFeedComment__c> feedCommentList){
        this.feedCommentList = feedCommentList; 
    }
    
    global Iterable<sObject> start(Database.BatchableContext BC) {  
        List<CustomFeedComment__c> fcList2Pass = new List<CustomFeedComment__c>();
        fcList2Pass=(migrationImplObj.saveAttachmentsForFC(feedCommentList));
        return fcList2Pass;
    }
    
    global void execute(Database.BatchableContext BC,  List<CustomFeedComment__c> customFeedComments) {
        feedCommentList2insert.addAll(migrationImplObj.saveImageForFeedComment(customFeedComments));                      
    }
    
    
    global void finish(Database.BatchableContext BC) {
        NC_feedCommentWrapper fcW = new NC_feedCommentWrapper();
        
    
        insertCustomFeedComment(feedCommentList2insert);
        fcW = migrationImplObj.setFeedCommentInLevels(feedCommentList2insert);
        //migrationImplObj.setBestAnswer(fcW.fiBestCommentMap); // marking best answer on the Feeditems
        system.debug('feedCommentLikeUrl2FC'+fcW.feedCommentLikeUrl2FC);
        
        Q_SaveLike savelike = new Q_SaveLike(fcW.feedCommentLikeUrl2FC, true); // this batch save likes on FeedComments
        Database.executeBatch(savelike , 100);
        
        Q_SetBestAnswer bestAns = new Q_SetBestAnswer(fcW.fiBestCommentMap); // this batch set best answer on feeditem
        Database.executeBatch(bestAns , 150);
    }
    
    
    public void insertCustomFeedComment(List<CustomFeedComment__c> recordToBeInserted ){
        Set<Id> feedItemIds = new Set<Id>();
        List<Url_Mapping__c> updateMapping = new List<Url_Mapping__c>();
        List<Error_Log__c>errorLogList = new List<Error_Log__c>();
        for(integer i=0; i<recordToBeInserted.size() ;i++){
            feedItemIds.add(recordToBeInserted[i].FeedItemId__c);
        }
        Database.SaveResult[] recordList = Database.insert(recordToBeInserted, false);
        System.debug('recordList '+recordList);
        System.debug('recordList size '+recordList.size());
        for(integer i=0; i<recordToBeInserted.size() ;i++){
            System.debug('In for loop');
            
            System.debug('recordList'+recordList[i].getId());
            System.debug('Is Success'+recordList[i].isSuccess());
            if(!recordList[i].isSuccess()){
                System.debug('In if');
                for (Database.Error e : recordList[i].getErrors()){  
                    System.debug('ooooo');                                                     
                    Error_Log__c log = new Error_Log__c();
                    log.Type__c = 'Discussion';
                    log.Name = 'CustomFeedCommentInsert';
                    log.Jive_Id__c = recordToBeInserted[i].FeedItem_JiveID__c;
                    log.Error_Description__c = e.getMessage();
                    //log.Object__c = 'FeedItem';
                    errorLogList.add(log); 
                    System.debug('errorLogList!!!!!!!!!!'+errorLogList);
                }
            }
        }
        if(!errorLogList.isEmpty()){
            insert errorLogList;
        
        }
        
        if(!feedItemIds.isEmpty()){
        
            List<Url_Mapping__c> feedItemLists = [select id,Salesforce_Id__c,isCommentInserted__c from url_mapping__c where Salesforce_Id__c IN :feedItemIds];
            for(url_mapping__c u :feedItemLists ){
                if(!u.isCommentInserted__c){
                    u.isCommentInserted__c = true;
                    updateMapping.add(u);
                }
            }
            if(updateMapping != null && updateMapping.size() > 0){
                update updateMapping;
            }
        }
        
    }
    
}