public class QualysUtils{

  Jive_Administrator__c jiveAdministratorCUstomSetting = Jive_Administrator__c.getValues('Url');
  string libraryName = jiveAdministratorCUstomSetting.Discussion_Community_Library__c;
  public map<string,string> referenceUrlBody(map<string,string> Content2Jiveid){
  map<string,string> Jiveid2Content = new map<string,string>();
  Map<string,url_Mapping__c> jiveId2UrlMappingRec= getUrlMapping();
  Map<string,string> replaceAncTag = new Map<string,string>();
  Map<string,string> replaceAncVal = new Map<string,string>();
  
  if(Content2Jiveid.keyset() != null && Content2Jiveid.keyset().size()>0){ 
    for(String Content: Content2Jiveid.keyset()){
        
        Matcher AncherTagMacher = Pattern.compile('<a(.+?)/a>').matcher( Content ); 
        while ( AncherTagMacher.find() ) { 
            String tagLink = AncherTagMacher.group();                
            String tagUrl = tagLink.substringBetween( ' href="', '"' );
            if(tagUrl != null &&  (tagUrl.contains('docs/DOC') || tagUrl.contains('thread/'))){
                String threadName = tagUrl.subString(tagUrl.lastIndexOf('/')+1);
                String[] JiveId= threadName.split('-');
                system.debug('tagLink ===>'+tagLink );
                string newUrl = '';
                string anchorValue =tagLink.substringBetween( '>', '</a>' );
                if(anchorValue != null && anchorValue.contains('<u>')){
                   anchorValue = anchorValue.substringBetween( '<u>', '</u>' ); 

                }else{
                   anchorValue = anchorValue;
                }
                if(tagUrl.contains('docs/DOC') ){ 
                    system.debug('JiveId[0]===>'+JiveId[1]);  
                    if(jiveId2UrlMappingRec.containsKey(jiveId[1])){
                        newUrl = System.Label.Discussion_Community_Url+ jiveId2UrlMappingRec.get(jiveId[1]).Salesforce_Id__c;
                        replaceAncTag.put('href="'+tagUrl+'"', 'href="'+newUrl+'"');
                        replaceAncVal.put(anchorValue, jiveId2UrlMappingRec.get(jiveId[1]).Title__c);
                    }                       
                }
                else{
                    if(JiveId[0] != null && JiveId[0].contains('?')){
                       String DiscussionID = JiveId[0].substringBefore('?');
                        if(jiveId2UrlMappingRec.containsKey(DiscussionID)){
                            newUrl = System.Label.Discussion_Community_Url+ jiveId2UrlMappingRec.get(DiscussionID).Salesforce_Id__c;                     
                            replaceAncTag.put('href="'+tagUrl+'"', 'href="'+newUrl+'"');
                            replaceAncVal.put(anchorValue, jiveId2UrlMappingRec.get(DiscussionID).Title__c);
                        }
                    }
                    else if(JiveId[0] != null && JiveId[0].contains('#')){
                       String[] DiscussionID = JiveId[0].split('#');
                       system.debug('DiscussionID ----------'+DiscussionID );
                        if(jiveId2UrlMappingRec.containsKey(DiscussionID[0])){
                            newUrl = System.Label.Discussion_Community_Url+ jiveId2UrlMappingRec.get(DiscussionID[0]).Salesforce_Id__c;                     
                            replaceAncTag.put('href="'+tagUrl+'"', 'href="'+newUrl+'"');
                            replaceAncVal.put(anchorValue, jiveId2UrlMappingRec.get(DiscussionID[0]).Title__c);
                        }
                     }
                     else{
                       system.debug('JiveId[0]===>'+JiveId[0]);  
                        if(jiveId2UrlMappingRec.containsKey(JiveId[0])){
                            newUrl = System.Label.Discussion_Community_Url+ jiveId2UrlMappingRec.get(jiveId[0]).Salesforce_Id__c;                     
                            replaceAncTag.put('href="'+tagUrl+'"', 'href="'+newUrl+'"'); 
                            replaceAncVal.put(anchorValue, jiveId2UrlMappingRec.get(jiveId[0]).Title__c);
                        }
                    }                  
                    
                } 
            }
        }
      }
    }
    system.debug('replaceAncTag----------'+replaceAncTag);
   
    
   if(Content2Jiveid.keyset() != null && Content2Jiveid.keyset().size()>0){  
    for(String content: Content2Jiveid.keyset()){   //jiveid
       
        String Jiveid = Content2Jiveid.get(content);
         for(String ancUrl : replaceAncTag.keySet()){
            if(ancUrl != null && content != null && content.contains(ancUrl) && replaceAncTag.get(ancUrl) != null ){
                content = content.replace(ancUrl,replaceAncTag.get(ancUrl));
            }
         }
                
         for(String ancVal : replaceAncVal.keySet()){
            if(ancVal != null && content != null && content.contains(ancVal) && replaceAncVal.get(ancVal) != null ){
                if(ancVal == ':'){
                    content = content.replace(ancVal,':');
                }else{
                    content = content.replace(ancVal,replaceAncVal.get(ancVal));
                }
            }
        }
        Jiveid2Content.put(Jiveid,content);
     }
    }
    return Jiveid2Content;
  }
  
  Public Void ShareFilesWithLibraries(List<string> contentVersionIds, Map<string,string> contentId2DocId){
    list<ContentDocumentLink> ContentDocLink= New list<ContentDocumentLink>();
    ContentWorkspace ws = [SELECT Id, RootContentFolderId FROM ContentWorkspace WHERE Name =: libraryName LIMIT 1];
        if(!contentVersionIds.isEmpty() && !contentId2DocId.isEmpty()){
            for(Id cId: contentVersionIds){
                ContentDocumentLink cdl = New ContentDocumentLink();
                cdl.LinkedEntityId = ws.Id;
                cdl.ContentDocumentId = contentId2DocId.get(cId);
                cdl.Visibility = 'AllUsers';
                cdl.shareType = 'I';
                ContentDocLink.add(cdl); 
            }
            insertRecords(ContentDocLink);
        }
    }
    
    public void insertRecords(List<SObject> recordToBeInserted ){
        Database.SaveResult[] recordList = Database.insert(recordToBeInserted, false);
        for (Database.SaveResult record : recordList ) {
            if (!record.isSuccess()) {
                // Operation failed, so get all errors                
                for(Database.Error err : record.getErrors()) {
                    System.debug('The following error has occurred while saving Record.'+record);                    
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Fields that affected this error: ' + err.getFields());
                }
            }
            
        }
    }
    
    public map<string,Url_mapping__c> getUrlMapping(){
         map<string,Url_mapping__c> Jiveid2UrlMappingRec = new map<string,Url_mapping__c>();
        List<Url_mapping__c> DiscussionUrlMap =[SELECT Salesforce_Id__c,Title__c, Jive_Id__c, Id, Name FROM Url_mapping__c];
        for(Url_mapping__c UrlMap: DiscussionUrlMap){
            Jiveid2UrlMappingRec.put(UrlMap.Jive_Id__c,UrlMap);
        }
        return Jiveid2UrlMappingRec;
    }
    
    
    public static Datetime formatDateValue(string dateVal){
        Date tempDate = date.ValueOf(dateVal);                                     
        string s2 = dateVal.split('T')[1];
        string s3 = s2.substring(0, 8);
        List<string> hms = s3.split(':');
        dateTime t = DateTime.newInstanceGMT(tempDate.year(), tempDate.month(), tempDate.day(), integer.valueOf(hms[0]), integer.valueOf(hms[1]), integer.valueOf(hms[2]));
        return t;
                
    }
}