global class Q_SaveFIAttachment implements Database.Batchable<string>,Database.AllowsCallouts,Database.Stateful{
    migr migrationImplObj=new migr();
    Map<String, FeedItem> attachmentUrl2FIMap = new Map<String, FeedItem>();
    public Q_SaveFIAttachment (Map<String, FeedItem> attachmentUrl2FIMap){
        this.attachmentUrl2FIMap = attachmentUrl2FIMap ; 
    }
    
    global Iterable<string> start(Database.BatchableContext BC) {  
        System.debug('attachmentUrlKeySet'+attachmentUrl2FIMap.keySet());  
        return new List<string> (attachmentUrl2FIMap.keySet());  
        
    }
    
    global void execute(Database.BatchableContext BC, List<string> attachmentUrl) {
        System.debug('attachmentUrl'+attachmentUrl);
        List<FeedAttachment> feedAttachmentList2Insert = new List<FeedAttachment>();
        Map<String, FeedItem> attachmentUrl2FI = new Map<String, FeedItem>();
        for(string s : attachmentUrl){
            attachmentUrl2FI.put(s, attachmentUrl2FIMap.get(s));
        }
        
        feedAttachmentList2Insert.addAll(migrationImplObj.saveAttachmentsForFI(attachmentUrl2FI));
        System.debug('FeedAttachmentList'+feedAttachmentList2Insert);
        migrationImplObj.insertrecords(feedAttachmentList2Insert);
                   
    }
        
    global void finish(Database.BatchableContext BC) {
            
    }

}