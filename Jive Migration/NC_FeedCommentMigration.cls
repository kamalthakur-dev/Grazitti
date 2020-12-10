global class NC_FeedCommentMigration implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful{
    //NC_MigrationImplementation migrationImplObj=new NC_MigrationImplementation();
    migr migrationImplObj=new migr();
    Map<String,FeedItem> feedItemMap =new  Map<String,FeedItem>();
    List<CustomFeedComment__c> feedCommentList = new List<CustomFeedComment__c>();
    
   public String Query = 'select id,salesforce_id__c, jive_id__c,isCommentInserted__c,Comment_Url__c from url_mapping__c'
                                               +'where Comment_Url__c != null and isCommentInserted__c = false';
    
    public NC_FeedCommentMigration (String qry){
         if(String.isNotBlank(qry)){
            query = qry ; 
        }
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) { 
        return Database.getQueryLocator(Query);
    }
    
    global void execute(Database.BatchableContext BC,  List<Url_Mapping__c> scope) {
        Map<String,string> feedCommentUrlToFIMap = new Map<String,string>(); 
        for(Url_Mapping__c u : scope){
            feedCommentUrlToFIMap.put(u.Comment_Url__c,u.salesforce_id__c);  
        }
        feedCommentList.addAll(migrationImplObj.getFeedCommentData(feedCommentUrlToFIMap)) ;         
    }
    
    
    global void finish(Database.BatchableContext BC) {
        Q_SaveImageForFeedComments f = new Q_SaveImageForFeedComments(feedCommentList);
        database.executeBatch(f , 50);
    }

}