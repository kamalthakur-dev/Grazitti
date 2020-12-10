public class articleAttachmentBatch implements Database.Batchable<string>,  Database.Stateful, Database.AllowsCallouts {
   ArticleMigration Articles = new ArticleMigration();
   Map<string,sObject> likeUrl2sObj = new Map<string,sObject>();
   Map<String, Knowledge__kav> attachmentUrl2FIMap = new Map<String, Knowledge__kav>();
   public articleAttachmentBatch (Map<String, Knowledge__kav> attachmentUrl2FIMap) { 
       this.attachmentUrl2FIMap = attachmentUrl2FIMap;
    }
    
    public Iterable<string> start(Database.BatchableContext bc) {
         return new List<string> (attachmentUrl2FIMap.keySet()); 
    }
 
    public void execute(Database.BatchableContext bc, list<string> scope){  
       Map<String, Knowledge__kav> attachmentUrl2FI = new Map<String, Knowledge__kav>();
       if(scope != null){
            for(string s : scope){
                attachmentUrl2FI.put(s, attachmentUrl2FIMap.get(s));
            }
        }
        list<ContentDocumentLink> cdl = Articles.saveAttachmentsForArticle(attachmentUrl2FI);
        if(cdl != null && cdl.size()>0){
            Articles.insertRecords(cdl);
        }
    }    
    public void finish(Database.BatchableContext bc){
        
 
    }   
}