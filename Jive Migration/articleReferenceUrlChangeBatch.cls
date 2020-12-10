public class articleReferenceUrlChangeBatch implements Database.Batchable<knowledge__kav>,  Database.Stateful{
    QualysUtils referenceURlchange = new QualysUtils();
    Jive_Administrator__c jiveAdministratorCUstomSetting = Jive_Administrator__c.getValues('Url');
    string RecordType= jiveAdministratorCUstomSetting.Article_Record_Type_Id__c;
    String JiveId ;
    public articleReferenceUrlChangeBatch(String jiveId){
        this.JiveId =JiveId ; 
    }
    
     public Iterable<knowledge__kav> start(Database.BatchableContext bc) { // To get Articles
        List<knowledge__kav> knowledgeArticle = new List<knowledge__kav>();
        if(!Test.isRunningTest()){
            if(String.isNotBlank(JiveId)){
                knowledgeArticle = [select id,KnowledgeArticleId,title,Description__c,JiveId__c,publishStatus from knowledge__kav where publishStatus='Draft' AND RecordTypeId=:RecordType AND JiveId__c =: jiveId];
            }else{
                knowledgeArticle = [select id,KnowledgeArticleId,title,Description__c,JiveId__c,publishStatus from knowledge__kav where publishStatus='Draft' AND RecordTypeId=:RecordType];
            }
        }else{
            knowledgeArticle = [select id,KnowledgeArticleId,title,Description__c,JiveId__c,publishStatus from knowledge__kav where publishStatus='Draft'];
        }
        return (knowledgeArticle);
    }
    public void execute(Database.BatchableContext bc, list<Knowledge__kav> scope){ 
        map<string,string> Jiveid2Content = new map<string,string>();
        map<string,string> Jiveid2articleContent = new map<string,string>();
        List<string> content = new List<string>();
        list<id> ids = new list<id>();
        for(Knowledge__kav kav:scope){
             if(kav.Description__c != null && kav.Description__c.contains('/DOC-4029')){
                kav.Description__c= kav.Description__c.replace('/DOC-4029','/DOC-6356');
            }
            ids.add(kav.id);
            Jiveid2Content.put(kav.Description__c,kav.JiveId__c);
        }
        system.debug('content===>'+Jiveid2Content);
        Jiveid2articleContent = referenceURlchange.referenceUrlBody(Jiveid2Content);
        for(Knowledge__kav kav:scope){ 
            kav.IsVisibleInPkb = true;
            for(string str:Jiveid2articleContent.keyset()){
                if(kav.JiveId__c == str){
                    kav.Description__c=Jiveid2articleContent.get(str);
                }
            }
        }
        update scope;
        list<Knowledge__kav> KArticles =[SELECT Id,KnowledgeArticleId FROM knowledge__kav WHERE Id IN: ids];
        for(Knowledge__kav kav : KArticles){
            if(!Test.isRunningTest()){
                KbManagement.PublishingService.publishArticle(kav.KnowledgeArticleId, true);
            }
        }
    }
    public void finish(Database.BatchableContext bc){
        
    }
}