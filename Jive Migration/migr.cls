public class migr{

    Jive_Administrator__c jiveAdministratorCUstomSetting = Jive_Administrator__c.getValues('Url');
    String NetworkScopeId, communityUrl, userProfileId, spaceUrl, communityUrlForAttachments, placesFilter , fileUrl ;
    String discussionUrl = jiveAdministratorCUstomSetting.DiscussionUrl__c; 
    String placeholder = jiveAdministratorCUstomSetting.Place_Holder_Text__c;
    List<String> qualysSpaceNameList= new List<String>();
    List<String> spacesNotToMoveIds=new List<String>();
    List<Topic> topicList = new List<Topic>();
    set<Id> notAvailableIds = new Set<Id>();
    string placeId = '';
    Map<string , FeedComment> mapLikeUrl2FeedComment = new Map<string , FeedComment>();
    Map<String,Id>jiveIdToUserIdMap = new Map<String,Id>();
    Map<String, Id> nickNameToIdMap = new Map<String, Id>();
    Map<String,String> UserCommentUrlMap=new Map<String,String>(); 
    Map<String,List<String>>tags2topicMap=new Map<String,List<String>>();
    QualysUtils qUtil = new QualysUtils();
    
    public Map<String,String> getTopicMap(List<Topic> topicList){
        Map<String,String> TopicMap=new Map<String,String>();
        for(Topic t:topicList){
            TopicMap.put(t.name.toLowerCase().deleteWhitespace(),t.id); 
        }
        return TopicMap;
    }
    public List<String> getQualysSpaceList(){
        List<Qualys_Spaces__c> qualysSpaceList = Qualys_Spaces__c.getall().values();
        List<String> qualysSpaceList2Pass = new List<String>();
        if(!qualysSpaceList.isEmpty()){
            for(Qualys_Spaces__c q:qualysSpaceList){
                qualysSpaceList2Pass.add(q.SpaceId__c);
            }
        }
        return qualysSpaceList2Pass;
    }
    
    public map<string,Url_mapping__c> getUrlMapping(){
         map<string,Url_mapping__c> Jiveid2UrlMappingRec = new map<string,Url_mapping__c>();
        List<Url_mapping__c> DiscussionUrlMap =[SELECT Salesforce_Id__c,Title__c, Jive_Id__c, Id, Name FROM Url_mapping__c];
        for(Url_mapping__c UrlMap: DiscussionUrlMap){
            Jiveid2UrlMappingRec.put(UrlMap.Jive_Id__c,UrlMap);
        }
        return Jiveid2UrlMappingRec;
    }
    
    public Map<String,List<String>> getTopicMappingWithTags(){
        List<Topics_Mapping__mdt>topicMappingList =[SELECT Label,topic_name__c from Topics_Mapping__mdt];
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
        
    public migr(){
        communityUrl = jiveAdministratorCUstomSetting.JiveProxyCommunityUrl__c;
        communityUrlForAttachments = jiveAdministratorCUstomSetting.CommunityUrl__c;
        NetworkScopeId = jiveAdministratorCUstomSetting.NetworkId__c;
        userProfileId = jiveAdministratorCUstomSetting.UserProfileId__c;
        spaceUrl = jiveAdministratorCUstomSetting.spaceUrl__c;
        fileUrl  = jiveAdministratorCUstomSetting.FileUrl__c;
        placesFilter  = jiveAdministratorCUstomSetting.List_Of_Places__c;
        topicList=[select id,Name from Topic where NetworkId =:NetworkScopeId];
        jiveIdToUserIdMap = getSFDCUserId();
        qualysSpaceNameList = getQualysSpaceList(); 
        tags2topicMap = getTopicMappingWithTags();
    }
    
    public String parseHtmlString(String str){
       
        str=str.replaceAll('class="[^\"]*"', '');
        if(str.indexOf('<div >')!=-1){
            str=str.replace(str.substring(0,str.indexOf('<div >')+6), '');
        }
        if(str.indexOf('</div><!')!=-1){
            str=str.replace(str.substring(str.indexOf('</div><!'),str.length()),'');  
        }    
        str=str.replaceAll('<span[^>]*>','');
        str=str.replaceAll('<hr[^>]*>','');
        str=str.replaceAll('<tbody[^>]*>','');
        str=str.replaceAll('</tbody>','');
        str=str.replaceAll('<p [^>]*>','<p>'); // removes colspan and any other attribute
        str=str.replaceAll('</span>','');
        str=str.replaceAll('<div[^>]*>','');
        str=str.replaceAll('</div>','');
        str=str.replaceAll('<pre[^>]*>','');
        str=str.replaceAll('</pre>','');
        str=str.replaceAll('<table[^>]*>','');
        str=str.replaceAll('</table>','');
        str=str.replaceAll('<tr[^>]*>','');
        str=str.replaceAll('</tr>','');
        str=str.replaceAll('<td[^>]*>','');
        str=str.replaceAll('</td>','');
        str=str.replaceAll('<thead[^>]*>','');
        str=str.replaceAll('</thead>','');
        str=str.replaceAll('<blockquote[^>]*>','');
        str=str.replaceAll('</blockquote>','');
        str=str.replaceAll('<code[^>]*>','<code>');
        str=str.replaceAll('style="[^\"]*"', '');
        str=str.replaceAll('class="[^\"]*"', '');
        str=str.replaceAll('height="[^\"]*"', '');
        str=str.replaceAll('width="[^\"]*"', '');
        str=str.replaceAll('size="[^\"]*"', '');
        str=str.replaceAll('bgcolor="[^\"]*"', '');
        str=str.replaceAll('tbody="[^\"]*"', '');
        str=str.replace('<h1','<b');
        str=str.replace('</h1>','</b>');
        str=str.replace('<h2','<b');// Addition by gaurav not sure correct
        str=str.replace('</h2>','</b>');// Addition by gaurav not sure correct
        str=str.replace('<h3','<b');// Addition by gaurav not sure correct
        str=str.replace('</h3>','</b>');
        str=str.replace('<h4','<b');
        str=str.replace('</h4>','</b>');
        str=str.replace('<h5','<b');// Addition by gaurav not sure correct
        str=str.replace('</h5>','</b>');// Addition by gaurav not sure correct
        str=str.replace('<h6','<b');// Addition by gaurav not sure correct
        str=str.replace('</h6>','</b>');
        str=str.replace('<em>','<b>');
        str=str.replace('<em>','<b>');
        str=str.replace('<hr/>','');
        str=str.replace('</em>','</b>');
        str=str.replace('<em >','<b>');   
        str = str.replace('<br>','\n');
        str = str.replace('<br/>','\n'); 
        str = str.replace('<strong','<b');
        str = str.replace('</strong>','</b>');
        str = str.replace('<th','<p');
        str = str.replace('</th>','</p>');
        str = str.replace('#','# ');
        
        str = migr.processIMGTag(str); //this is added because the proxy was not returning the "/" closing for img tag   
        List<string> stringParts = str.split('<code>');
        String finalString = '';
        for(String s : stringParts){
           if(String.isNotBlank(s) && s.contains('</code>')){
                List<string> parts = s.split('</code>');       
               if(parts != null && parts.size() > 0){
                   if(String.isNotBlank(parts[0])){
                       finalString = finalString + ' <code>' + migr.processCodeTag(parts[0]) + '</code> ';
                   }
                   if(parts.size() > 1 && string.isNotBlank(parts[1])){
                        finalString = finalString + parts[1];            
                   }
                   if(parts.size() > 2 && string.isNotBlank(parts[2])){
                        finalString = finalString + parts[2];            
                   }
               }
               
            }else{
                finalString = finalString + s;    
            }      
        }      
        return finalString;   
    }
    
    
    public static String processCodeTag(String x){
        x = x.replaceAll('<p [^>]*>','<p>');
        x = x.replaceAll('<b [^>]*>','<b>');
        x = x.replaceAll('<code [^>]*>','<code>');
        x = x.replaceAll('<ul [^>]*>','<ul>');
        x = x.replaceAll('<ol [^>]*>','<ol>');
        x = x.replaceAll('<li [^>]*>','<li>');
        x = x.replaceAll('<','&lt;');
        x = x.replaceAll('>','&gt;');
        x = x.replaceAll('&lt;p&gt;','<p>');
        x = x.replaceAll('&lt;/p&gt;','</p>');
        
        x = x.replaceAll('&lt;b&gt;','<b>');
        x = x.replaceAll('&lt;/b&gt;','</b>');
        
        x = x.replaceAll('&lt;code&gt;','<code>');
        x = x.replaceAll('&lt;/code&gt;','</code>');
        
        x = x.replaceAll('&lt;ul&gt;','<ul>');
        x = x.replaceAll('&lt;/ul&gt;','</ul>');
        
        x = x.replaceAll('&lt;ol&gt;','<ol>');
        x = x.replaceAll('&lt;/ol&gt;','</ol>');
        
        x = x.replaceAll('&lt;li&gt;','<li>');
        x = x.replaceAll('&lt;/li&gt;','</li>');
        
        x = x.replaceAll('<p>&nbsp;</p>','\n');
        x = x.replaceAll('&lt;p&gt;&nbsp;&lt;/p&gt;','\n');
        
        return x;
    }
    public static String processIMGTag(String x){
        String str = x;
        Map<string, string> old2newMap = new Map<string, string>();       
        
        Matcher imgMatcher = Pattern.compile( '<img(.+?)>' ).matcher(str);
        while ( imgMatcher.find() ) {
            String imageTag = imgMatcher.group();
            string st = imageTag.substring(0,imageTag.lastIndexOf('>') )+'/>';
            old2newMap.put(imageTag, st);
        }
        if(old2newMap != null && old2newMap.keyset().size() > 0){
            for(string sss : old2newMap.keySet()){
                str = str.replace(sss, old2newMap.get(sss));   
            }
        }

        return str; 
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
        
        
    public List<NC_feedItemWrapper> getAllDiscussionData(Integer startIndex,Decimal count,Decimal TotalItems,  string threadJiveId, String placeName,string contentType){
        string endpoint  = '';
        if(String.isNotBlank(placeName)){
            placeId = Qualys_Spaces__c.getValues(placeName).SpaceId__c;
            endpoint = communityUrl+spaceUrl+placeId+'/'+fileUrl;
        }else if(String.isNotBlank(threadJiveId)){
            if(threadJiveId == '11685'){
                endpoint = communityUrlForAttachments + 'contents?filter=entityDescriptor(1,'+threadJiveId+')'; 
            }else{
                if(string.isNotBlank(contentType) && (contentType.toLowerCase() == 'document' || contentType.toLowerCase() == 'file')){
                     endpoint = communityUrl  + 'contents?filter=entityDescriptor(102,'+threadJiveId+')';
                }else if(String.isBlank(contentType) || (string.isNotBlank(contentType) && contentType.toLowerCase() == 'discussion')){
                    endpoint = communityUrl + 'contents?filter=entityDescriptor(1,'+threadJiveId+')'; 
                }
            }
        }else{
            endpoint = communityUrl+discussionUrl +placesFilter+'sort=dateCreatedAsc&'; 
        }
        List<NC_feedItemWrapper> feedWrapperList = new List<NC_feedItemWrapper>();
        Decimal tempLoops = (TotalItems/count);
        Long noOfLoop = tempLoops.round(System.RoundingMode.UP);     
        Map<String,String> topicMap=getTopicMap(topicList);
        Map<String,Topic> tMap=new Map<String,Topic>();       
        List<discussionJSON.cls_list> discussionItems = new List<discussionJSON.cls_list>();
        
        HttpRequest req= new HttpRequest();
        Http http = new Http();
        req.setMethod('GET');
        req.setHeader('Authorization', 'Basic Z2F1cmF2YjpTRkRDTWlncmF0aW9u'); 
        for(Integer i=0;i<noOfLoop;i++){
        String jsonstr=null;
        //if(!Test.isRunningTest()){
            if(endpoint.contains('type(discussion)') || endpoint.contains('type(file)')){ 
                if(i==0){   
                    endPoint += 'startIndex='+startIndex+'&count='+count;              
                }
            }
            req.setEndpoint(endPoint);
            req.settimeout(120000);
            HttpResponse res = http.send(req);
            String temp =  res.getBody().replace('\n','');
            jsonstr = temp.replace('list','items');                     
            discussionJSON wrapperinstance=(discussionJSON ) discussionJSON.parse(jsonstr);
            discussionItems.addAll(wrapperinstance.items);     
            if(wrapperinstance.links != null && wrapperinstance.links.next != null){ 
                endPoint =  wrapperinstance.links.next;
            }
        //} 
        }
        
        if(discussionItems != null && discussionItems.size() > 0){                
            for(Integer j=0;j<discussionItems.size();j++){
                //if(discussionItems.get(j).id != '20105' && discussionItems.get(j).parentPlace.type == 'space' && discussionItems.get(j).parentPlace.name != null && qualysSpaceNameList.contains(discussionItems.get(j).parentPlace.placeID)){               
                    FeedItem feedItem=new FeedItem();  
                    string HelpfulUrl;
                    Map<string,string> fileUrl2Name = new Map<String,string>();
                    feedItem.NetworkScope = NetworkScopeId;
                    feedItem.title=discussionItems.get(j).subject.unescapeHtml4();                                             
                    feedItem.Type = 'QuestionPost';                                              
                    feedItem.IsRichText=true;  
                    feedItem.CreatedDate = QualysUtils.formatDateValue(discussionItems.get(j).published);                                                              
                    //feedItem.CreatedDate = Date.valueOf(discussionItems.get(j).published);
                    if(discussionItems.get(j).author != null && discussionItems.get(j).author.id != null && jiveIdToUserIdMap.size() > 0 && jiveIdToUserIdMap.containsKey(discussionItems.get(j).author.id)){  
                        feedItem.CreatedById = jiveIdToUserIdMap.get(discussionItems.get(j).author.id);     
                    }
                    else{                                    
                        feedItem.CreatedById = userinfo.getUserId();
                    } 
                    feedItem.ParentId = feedItem.CreatedById;
                    if(discussionItems.get(j).content.text.length()<10000){
                        //String temp = discussionItems.get(j).content.text.unescapeHtml4();
                        if(threadJiveId != null && threadJiveId == '11685'){
                            discussionItems.get(j).content.text= discussionItems.get(j).content.text.unescapeHtml4();
                        }
                        if(discussionItems.get(j).content.text != null && discussionItems.get(j).content.text.contains('&#160;')){
                           discussionItems.get(j).content.text = discussionItems.get(j).content.text.replace('&#160;','\n');
                        }
                        if(discussionItems.get(j).content.text != null){
                            String temp = discussionItems.get(j).content.text;
                            temp=parseHtmlString(temp);                       
                            feedItem.Body=temp;
                        } 
                    }else{
                        //String temp = discussionItems.get(j).content.text.unescapeHtml4();                       
                      if(discussionItems.get(j).content.text != null){                    
                            String temp = discussionItems.get(j).content.text;
                            
                            temp=parseHtmlString(temp); 
                            feedItem.Body=temp;
                        }
                        
                    }
                    System.debug('fdiscussionItems.get(j).content.text##########'+discussionItems.get(j).content.text.Length());   
                     System.debug('feedItem.Body##########'+feedItem.Body.Length());   
                    List<string> tags = new List<string>();
                    set<string> tagSet = new set<string>();
                    if(discussionItems.get(j).tags!=null){
                        // tags logic to include the custom mapping
                        List<string> tagList = new List<string>();
                        tagList = discussionItems.get(j).tags; 
                        for(String s : tagList){
                            string s_lower = s.toLowerCase().deleteWhitespace();
                            if(tags2topicMap.containsKey(s_lower)) {
                            
                                for(String topic:tags2topicMap.get(s_lower)){
                                    if(!tagSet.contains(topic.toLowerCase().deleteWhitespace())){
                                        tags.add(topic);
                                        tagSet.add(topic.toLowerCase().deleteWhitespace());
                                    }
                                
                                }  
                            }
                            else if(!tagSet.contains((s_lower))){
                                tagSet.add(s_lower);
                                tags.add(s);
                            }
                        }
                        //Upto here    
                    }
                    
                    if(discussionItems.get(j).parentPlace != null && discussionItems.get(j).parentPlace.name != null ){
                        string tg = discussionItems.get(j).parentPlace.name;
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
                        for(Integer n=0;n<tags.size();n++){
                            if(!topicMap.containsKey(tags[n].toLowerCase().deleteWhitespace())){
                                Topic tObj=new Topic();
                                tObj.name=tags[n];
                                tObj.NetworkId=NetworkScopeId; 
                                tMap.put(tObj.name,tObj);                            
                            } 
                        }
                    }  
                    /*------------------------Topic-----------------------*/
                    string commentUrl = '';
                    if(discussionItems.get(j).replyCount != null && discussionItems.get(j).replyCount != 0){
                        if(discussionItems.get(j).resources.comments != null && discussionItems.get(j).resources.comments.ref != null){
                            commentUrl = discussionItems.get(j).resources.comments.ref;
                        }else if(discussionItems.get(j).resources.messages != null && discussionItems.get(j).resources.messages.ref != null){
                            commentUrl = discussionItems.get(j).resources.messages.ref;
                        }
                    }
                    if(discussionItems.get(j).resources != null && discussionItems.get(j).resources.helpful != null){
                        HelpfulUrl = discussionItems.get(j).resources.helpful.ref;
                    }
                    List<discussionJSON.fileStr> attachmentList =new List<discussionJSON.fileStr>(); 
                    if(discussionItems.get(j).attachments != null){ 
                        attachmentList.addAll(discussionItems.get(j).attachments);   
                    } 
                    if(String.isNotBlank(discussionItems.get(j).binaryURL) && String.isNotBlank(discussionItems.get(j).Name)){
                        fileUrl2Name.put(discussionItems.get(j).binaryURL, discussionItems.get(j).Name);
                        
                    }  
                    NC_feedItemWrapper wObj=new NC_feedItemWrapper(discussionItems.get(j).id ,discussionItems.get(j).parentPlace.name, feedItem,tags,commentUrl ,discussionItems.get(j).resources.likes.ref,attachmentList, fileUrl2Name,HelpfulUrl);
                    feedWrapperList.add(wObj);   
                
               // } 
            }
        }   
        
        /*----------------Inserting new topics-----------*/
        if(!tMap.isEmpty()){
            insertRecords(tMap.values());
        } 
        return feedWrapperList;
    }
        
          public List<CustomFeedComment__c> getFeedCommentData( Map<String,String> feedItemMap){
            //createUserAndContactMap();
            Map<string , FeedComment> feedCommentList2= new Map<string , FeedComment>();           
            List<CustomFeedComment__c> feedCommentList= new List<CustomFeedComment__c>();
            Map<String, CustomFeedComment__c> attachmentUrl2FeedComment = new Map<String, CustomFeedComment__c>();
            Set<id> fiIds = new Set<id>();
            Http http = new Http();
            HttpRequest req= new HttpRequest();
            req.setMethod('GET');
            for(String s:feedItemMap.Keyset()){
                String jsonstr='';
                 HttpResponse res = new HttpResponse();
                 Http h = new Http();
                 req.setHeader('Authorization', 'Basic Z2F1cmF2YjpTRkRDTWlncmF0aW9u');
                if(s!=null){
                    req.setEndpoint(s+'?startindex=0&count=100');
                    req.settimeout(120000);
                    if(!Test.isRunningTest()){  
                        res = h.send(req);   
                    }else{
                        res.setBody('{"itemsPerPage":25,"list":[{"id":"16044","resources":{"outcomeTypes":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/messages/16044/outcomeTypes"},"editHTML":{"allowed":["GET"],'
                        +'"ref":"https://discussions.qualys.com/update-advanced-comment.jspa?id=16044"},"attachments":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/attachments/messages/16044"},'
                        +'"outcomes":{"allowed":["GET","POST"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/messages/16044/outcomes"},"messages":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/messages/16044/messages"},'
                        +'"self":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/messages/16044"},"html":{"allowed":["GET"],"ref":"https://discussions.qualys.com/message/16044?commentID=16044#comment-16044"},'
                        +'"extprops":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/messages/16044/extprops"},"helpful":{"allowed":["GET"],'
                        +'"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/messages/16044/helpful"},"likes":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/messages/16044/likes"}},'
                        +'"followerCount":0,"followed":false,"likeCount":1,"published":"2012-10-05T14:38:32.354+0000","tags":["reports","vulnerability_reporting"],"updated":"2012-10-05T14:38:32.354+0000","iconCss":"jive-icon-discussion","parentContent":{"id":"10661",'
                        +'"answer":"https://jive-api-proxy.herokuapp.com/api/core/v3/messages/50447","html":"https://discussions.qualys.com/thread/10661","contentID":"10546","name":"Quick way to test Authentication Record in Qualys",'
                        +'"question":false,"type":"discussion","typeCode":1,"uri":"https://jive-api-proxy.herokuapp.com/api/core/v3/contents/10546","iconCss":"jive-icon-discussion"},"parentPlace":{"id":"2005","html":"https://discussions.qualys.com/community/vulnerability-management",'
                        +'"placeID":"19890","name":"IT Security","type":"space","typeCode":14,"uri":"https://jive-api-proxy.herokuapp.com/api/core/v3/places/19890","iconCss":"jive-icon-space"},"author":{"id":"7015","resources":{"followingIn":{"allowed":["GET","POST"],'
                        +'"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015/followingIn"},"images":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015/images"},"activity":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015/activities"},'
                        +'"social":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015/@social"},"recognition":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015/@recognition"},"trendingContent":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015/@trendingContent"},'
                        +'"trendingPlaces":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015/@trendingPlaces"},"avatar":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015/avatar?a=1729"},"followers":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015/@followers"},'
                        +'"following":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015/@following"},"members":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/members/people/7015"},"self":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015"},"html":{"allowed":["GET"],'
                        +'"ref":"https://discussions.qualys.com/people/pbaxi"},"extprops":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015/extprops"}},"followerCount":23,"followed":false,"published":"2012-05-24T01:33:41.123+0000","updated":"2019-10-08T16:01:58.772+0000","displayName":"Parag Baxi","mentionName":"pbaxi","followingCount":22,'
                        +'"jive":{"enabled":true,"external":false,"federated":false,"lastProfileUpdate":"2014-08-01T02:27:47.585+0000","locale":"en_US","externalContributor":false,"sendable":true,"timeZone":"America/Los_Angeles","username":"pbaxi","visible":true,"status":"registered"},"name":{"familyName":"Baxi","formatted":"Parag Baxi","givenName":"Parag"},"photos":[{"value":'
                        +'"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015/images/1/data?a=3497","jive_showSummaryLabel":false}],"status":"I dont always encrypt my application layer, but when I do, I use TLS (&gt; 1.0).","thumbnailId":"1729","thumbnailUrl":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015/avatar?a=1729","initialLogin":"2012-05-24T01:33:41.123+0000",'
                        +'"type":"person","typeCode":3},"content":{"text":"<p>Simple way to copy and paste:</p><p>105015, 105053, 105177, 105192, 105193, 105296, 105297, 105298, 105299, 105329, 105330, 115263, 70038, 90194, 90195, 90399</p><img alt=\\"\\" class=\\"image-3 jive-emoji jive-image\\" height=\\"434\\" src=\\"https://discussions.qualys.com/servlet/JiveServlet/downloadImage/102-7079-2-26694/600-434/Screen+Shot+2020-02-28+at+4.28.09+PM.png\\">"'
                        +',"editable":false,"type":"text/html"},"parent":"https://jive-api-proxy.herokuapp.com/api/core/v3/contents/10546","replyCount":0,"status":"published","subject":"Quick way to test Authentication Record in Qualys","viewCount":15584,"visibleToExternalContributors":false,"abuseCount":0,"typeCode":2,"type":"message","helpfulCount":1,"unhelpfulCount":0,"answer":true,"attachments":[],"discussion":"https://jive-api-proxy.herokuapp.com/api/core/v3/contents/10546",'
                        +'"outcomeTypeNames":["helpful"],"outcomeCounts":{"helpful":1},"messageTarget":"replyAsComment"},{"id":"16045","resources":{"outcomeTypes":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/messages/16045/outcomeTypes"},"editHTML":{"allowed":["GET"],"ref":"https://discussions.qualys.com/update-advanced-comment.jspa?id=16045"},"attachments":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/attachments/messages/16045"},'
                        +'"outcomes":{"allowed":["GET","POST"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/messages/16045/outcomes"},"messages":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/messages/16045/messages"},"self":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/messages/16045"},"html":{"allowed":["GET"],"ref":"https://discussions.qualys.com/message/16045?commentID=16045#comment-16045"},"extprops":{"allowed":["GET"],'
                        +'"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/messages/16045/extprops"},"helpful":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/messages/16045/helpful"},"likes":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/messages/16045/likes"}},"followerCount":0,"followed":false,"likeCount":0,"published":"2012-10-05T16:10:05.174+0000","tags":[],"updated":"2012-10-05T16:10:05.174+0000","iconCss":"jive-icon-discussion",'
                        +'"parentContent":{"id":"10661","html":"https://discussions.qualys.com/thread/10661","contentID":"10546","name":"Quick way to test Authentication Record in Qualys","question":false,"type":"discussion","typeCode":1,"uri":"https://jive-api-proxy.herokuapp.com/api/core/v3/contents/10546","iconCss":"jive-icon-discussion"},"parentPlace":{"id":"2005","html":"https://discussions.qualys.com/community/vulnerability-management","placeID":"19890","name":"IT Security","type":"space",'
                        +'"typeCode":14,"uri":"https://jive-api-proxy.herokuapp.com/api/core/v3/places/19890","iconCss":"jive-icon-space"},"author":{"id":"7015","resources":{"followingIn":{"allowed":["GET","POST"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015/followingIn"},"images":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015/images"},"activity":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015/activities"},'
                        +'"social":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015/@social"},"recognition":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015/@recognition"},"trendingContent":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015/@trendingContent"},"trendingPlaces":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015/@trendingPlaces"},"avatar":{"allowed":["GET"],'
                        +'"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015/avatar?a=1729"},"followers":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015/@followers"},"following":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015/@following"},"members":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/members/people/7015"},"self":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015"},'
                        +'"html":{"allowed":["GET"],"ref":"https://discussions.qualys.com/people/pbaxi"},"extprops":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015/extprops"}},"followerCount":23,"followed":false,"published":"2012-05-24T01:33:41.123+0000","updated":"2019-10-08T16:01:58.772+0000","displayName":"Parag Baxi","mentionName":"pbaxi","followingCount":22,"jive":{"enabled":true,"external":false,"federated":false,"lastProfileUpdate":"2014-08-01T02:27:47.585+0000","locale":"en_US",'
                        +'"externalContributor":false,"sendable":true,"timeZone":"America/Los_Angeles","username":"pbaxi","visible":true,"status":"registered"},"name":{"familyName":"Baxi","formatted":"Parag Baxi","givenName":"Parag"},"photos":[{"value":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015/images/1/data?a=3497","jive_showSummaryLabel":false}],"status":"I dont always encrypt my application layer, but when I do, I use TLS (&gt; 1.0).","thumbnailId":"1729","thumbnailUrl":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015/avatar?a=1729",'
                        +'"initialLogin":"2012-05-24T01:33:41.123+0000","type":"person","typeCode":3},"content":{"text":"<p>Simpler way to copy and paste below.</p><p>&nbsp;</p><p><b>All:</b></p><p>QIDs: 105015, 105053, 105177, 105192, 105193, 105296, 105297, 105298, 105299, 105329, 105330, 115263, 70038, 90194, 90195, 90399</p><p>Ports: 22, 23, 145, 161, 162, 10161, 10162</p><p>&nbsp;</p><p><b>Windows only:</b></p><p>QIDs: 70038, 90194, 90195, 90399, 105015, 105177, 105296</p><p>Ports: 145</p><p>&nbsp;</p><p><b>Oracle only:</b></p><p>QIDs: 105193, 105330, 105299, 105329</p>'
                        +'<p>Ports: 1521</p><p><p>&nbsp;</p><b>Cisco only:</b></p><p>QIDs: 105053, 115263, 105297</p><p>Ports: 22, 23</p><p>&nbsp;</p><p><b>SNMP only:</b></p><p>QIDs: 105192, 105298</p><p>Ports: 161, 162, 10161, 10162</p><p>&nbsp;</p><p><b>Unix only:</b></p><p>QIDS: 105053, 115263, 105297 </p><p>Ports: 22, 23</p>","editable":false,"type":"text/html"},"parent":"https://jive-api-proxy.herokuapp.com/api/core/v3/contents/10546","replyCount":2,"status":"published","subject":"Quick way to test Authentication Record in Qualys","viewCount":15584,"visibleToExternalContributors":false,'
                        +'"abuseCount":0,"typeCode":2,"type":"message","helpfulCount":0,"unhelpfulCount":0,"attachments":[{"id":"19123","resources":{"self":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/attachments/19123"}},"contentType":"image/png","name":"Screenshot under SHA1 Root.png","size":15150,"url":"https://jive-api-proxy.herokuapp.com/api/core/v3/attachments/19123/data","status":"published","doUpload":false,"type":"attachment","typeCode":13}],"discussion":"https://jive-api-proxy.herokuapp.com/api/core/v3/contents/10546","messageTarget":"replyAsComment"},{"id":"16061","resources":{"outcomeTypes":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/messages/16061/outcomeTypes"},"editHTML":{"allowed":["GET"],"ref":"https://discussions.qualys.com/update-advanced-comment.jspa?id=16061"},"attachments":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/attachments/messages/16061"},'
                        +'"outcomes":{"allowed":["GET","POST"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/messages/16061/outcomes"},"messages":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/messages/16061/messages"},"self":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/messages/16061"},"html":{"allowed":["GET"],"ref":"https://discussions.qualys.com/message/16061?commentID=16061#comment-16061"},"extprops":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/messages/16061/extprops"},"helpful":{"allowed":["GET"],'
                        +'"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/messages/16061/helpful"},"likes":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/messages/16061/likes"}},"followerCount":0,"followed":false,"likeCount":0,"published":"2012-10-05T16:46:12.674+0000","tags":[],"updated":"2012-10-05T16:47:35.912+0000","iconCss":"jive-icon-discussion","parentContent":{"id":"16045","html":"https://discussions.qualys.com/message/16045?commentID=16045#comment-16045","contentID":"null","name":"Quick way to test Authentication Record in Qualys","type":"message","typeCode":2,'
                        +'"uri":"https://jive-api-proxy.herokuapp.com/api/core/v3/messages/16045","iconCss":"jive-icon-discussion"},"parentPlace":{"id":"2005","html":"https://discussions.qualys.com/community/vulnerability-management","placeID":"19890","name":"IT Security","type":"space","typeCode":14,"uri":"https://jive-api-proxy.herokuapp.com/api/core/v3/places/19890","iconCss":"jive-icon-space"},"author":{"id":"2069","resources":{"followingIn":{"allowed":["GET","POST"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/2069/followingIn"},"images":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/2069/images"},'
                        +'"activity":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/2069/activities"},"social":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/2069/@social"},"recognition":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/2069/@recognition"},"trendingContent":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/2069/@trendingContent"},"trendingPlaces":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/2069/@trendingPlaces"},"avatar":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/2069/avatar?a=1204"},'
                        +'"followers":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/2069/@followers"},"following":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/2069/@following"},"members":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/members/people/2069"},"self":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/2069"},"html":{"allowed":["GET"],"ref":"https://discussions.qualys.com/people/mclancy"},"extprops":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/2069/extprops"}},"followerCount":57,"followed":false,"published":"2010-07-23T22:01:00.164+0000",'
                        +'"updated":"2014-11-13T02:16:35.155+0000","displayName":"Matt Clancy","mentionName":"mclancy","emails":[{"jive_label":"Email","primary":true,"type":"work","value":"mclancy@noreplies.com","jive_displayOrder":1,"jive_summaryDisplayOrder":0,"jive_showSummaryLabel":true}],"followingCount":57,"jive":{"enabled":true,"external":false,"federated":false,"lastProfileUpdate":"2014-07-10T23:39:55.774+0000","level":{"description":"Level 4","imageURI":"https://rewards.imgix.net/prod_phx/11fbffd0-71ed-4b9b-95c0-4052c96abccd/level4?updated=fc876a9d-1ab2-4c6e-8523-71a1079486b5","name":"Level 4","points":1043},"locale":"en_US","externalContributor":false,"profile":[{"jive_label":"Company","value":"","jive_displayOrder":5,'
                        +'"jive_summaryDisplayOrder":3,"jive_showSummaryLabel":true},{"jive_label":"Expertise","value":"GCIH, CISSP, MCSE","jive_displayOrder":6,"jive_showSummaryLabel":false},{"jive_label":"LinkedIn","value":"http://www.linkedin.com/in/mattclancy","jive_displayOrder":10,"jive_showSummaryLabel":false}],"sendable":true,"timeZone":"America/Chicago","username":"mclancy","visible":true,"status":"registered"},"name":{"familyName":"Clancy","formatted":"Matt Clancy","givenName":"Matt"},"status":"https://community.qualys.com/blogs/matt","thumbnailId":"1204","thumbnailUrl":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/2069/avatar?a=1204","initialLogin":"2010-07-23T22:01:00.164+0000","type":"person","typeCode":3},'
                        +'"content":{"text":"<p>Parag, the docs say that for non-Domain (local) authentication TCP ports 135 and 445 are required for: Windows 2000, 2003, XP</p>","editable":false,"type":"text/html"},"parent":"https://jive-api-proxy.herokuapp.com/api/core/v3/messages/16045","replyCount":1,"status":"published","subject":"Re: Quick way to test Authentication Record in Qualys","viewCount":15584,"visibleToExternalContributors":false,"abuseCount":0,"typeCode":2,"type":"message","helpfulCount":0,"unhelpfulCount":0,"attachments":[],"discussion":"https://jive-api-proxy.herokuapp.com/api/core/v3/contents/10546","messageTarget":"replyAsComment"},{"id":"16089","resources":{"outcomeTypes":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/messages/16089/outcomeTypes"},'
                        +'"editHTML":{"allowed":["GET"],"ref":"https://discussions.qualys.com/update-advanced-comment.jspa?id=16089"},"attachments":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/attachments/messages/16089"},"outcomes":{"allowed":["GET","POST"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/messages/16089/outcomes"},"messages":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/messages/16089/messages"},"self":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/messages/16089"},"html":{"allowed":["GET"],"ref":"https://discussions.qualys.com/message/16089?commentID=16089#comment-16089"},"extprops":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/messages/16089/extprops"},'
                        +'"helpful":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/messages/16089/helpful"},"likes":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/messages/16089/likes"}},"followerCount":0,"followed":false,"likeCount":0,"published":"2012-10-10T13:01:17.553+0000","tags":[],"updated":"2013-02-26T20:49:49.528+0000","iconCss":"jive-icon-discussion","parentContent":{"id":"16061","html":"https://discussions.qualys.com/message/16061?commentID=16061#comment-16061","contentID":"null","name":"Re: Quick way to test Authentication Record in Qualys","type":"message","typeCode":2,"uri":"https://jive-api-proxy.herokuapp.com/api/core/v3/messages/16061","iconCss":"jive-icon-discussion"},"parentPlace":{"id":"2005","html":"https://discussions.qualys.com/community/vulnerability-management",'
                        +'"placeID":"19890","name":"IT Security","type":"space","typeCode":14,"uri":"https://jive-api-proxy.herokuapp.com/api/core/v3/places/19890","iconCss":"jive-icon-space"},"author":{"id":"7015","resources":{"followingIn":{"allowed":["GET","POST"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015/followingIn"},"images":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015/images"},"activity":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015/activities"},"social":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015/@social"},"recognition":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015/@recognition"},"trendingContent":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015/@trendingContent"},'
                        +'"trendingPlaces":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015/@trendingPlaces"},"avatar":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015/avatar?a=1729"},"followers":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015/@followers"},"following":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015/@following"},"members":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/members/people/7015"},"self":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015"},"html":{"allowed":["GET"],"ref":"https://discussions.qualys.com/people/pbaxi"},"extprops":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015/extprops"}},"followerCount":23,"followed":false,'
                        +'"published":"2012-05-24T01:33:41.123+0000","updated":"2019-10-08T16:01:58.772+0000","displayName":"Parag Baxi","mentionName":"pbaxi","followingCount":22,"jive":{"enabled":true,"external":false,"federated":false,"lastProfileUpdate":"2014-08-01T02:27:47.585+0000","locale":"en_US","externalContributor":false,"sendable":true,"timeZone":"America/Los_Angeles","username":"pbaxi","visible":true,"status":"registered"},"name":{"familyName":"Baxi","formatted":"Parag Baxi","givenName":"Parag"},"photos":[{"value":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015/images/1/data?a=3497","jive_showSummaryLabel":false}],"status":"I do always encrypt my application layer, but when I do, I use TLS (&gt; 1.0).","thumbnailId":"1729","thumbnailUrl":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015/avatar?a=1729","initialLogin":"2012-05-24T01:33:41.123+0000","type":"person","typeCode":3},'
                        +'"content":{"text":"<p>Thanks, Matt.</p><p>&nbsp;</p><p><b>All:</b></p><p>QIDs: 105015, 105053, 105192, 105193, 105296, 105297, 105298, 105299, 105329, 105330, 115263, 70038, 90194, 90195, 90399</p><p>Ports: 22, 23, 145, 161, 162, 10161, 10162</p><p>&nbsp;</p><p><b>Windows only:</b></p><p>QIDs: 70038, 90194, 90195, 90399, 105015, 105296</p><p>Ports: 135, 445</p><p>&nbsp;</p><p><b>Oracle only:</b></p><p>QIDs: 105193, 105330, 105299, 105329</p><p>Ports: 1521</p><p><p>&nbsp;</p><b>Cisco only:</b></p><p>QIDs: 105053, 115263, 105297</p><p>Ports: 22, 23</p><p>&nbsp;</p><p><b>SNMP only:</b></p><p>QIDs: 105192, 105298</p><p>Ports: 161, 162, 10161, 10162</p><p>&nbsp;</p><p><b>Unix only:</b></p><p>QIDS: 105053, 115263, 105297</p><p>Ports: 22, 23</p>","editable":false,"type":"text/html"},"parent":"https://jive-api-proxy.herokuapp.com/api/core/v3/messages/16061","replyCount":0,"status":"published",'
                        +'"subject":"Re: Quick way to test Authentication Record in Qualys","viewCount":15584,"visibleToExternalContributors":false,"abuseCount":0,"typeCode":2,"type":"message","helpfulCount":0,"unhelpfulCount":0,"attachments":[],"discussion":"https://jive-api-proxy.herokuapp.com/api/core/v3/contents/10546","messageTarget":"replyAsComment"},{"id":"16092","resources":{"outcomeTypes":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/messages/16092/outcomeTypes"},"editHTML":{"allowed":["GET"],"ref":"https://discussions.qualys.com/update-advanced-comment.jspa?id=16092"},"attachments":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/attachments/messages/16092"},"outcomes":{"allowed":["GET","POST"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/messages/16092/outcomes"},"messages":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/messages/16092/messages"},'
                        +'"self":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/messages/16092"},"html":{"allowed":["GET"],"ref":"https://discussions.qualys.com/message/16092?commentID=16092#comment-16092"},"extprops":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/messages/16092/extprops"},"helpful":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/messages/16092/helpful"},"likes":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/messages/16092/likes"}},"followerCount":0,"followed":false,"likeCount":0,"published":"2012-10-10T15:16:31.145+0000","tags":[],"updated":"2012-10-10T15:16:31.145+0000","iconCss":"jive-icon-discussion","parentContent":{"id":"10661","html":"https://discussions.qualys.com/thread/10661","contentID":"10546","name":"Quick way to test Authentication Record in Qualys","question":false,"type":"discussion","typeCode":1,"uri":'
                        +'"https://jive-api-proxy.herokuapp.com/api/core/v3/contents/10546","iconCss":"jive-icon-discussion"},"parentPlace":{"id":"2005","html":"https://discussions.qualys.com/community/vulnerability-management","placeID":"19890","name":"IT Security","type":"space","typeCode":14,"uri":"https://jive-api-proxy.herokuapp.com/api/core/v3/places/19890","iconCss":"jive-icon-space"},"author":{"id":"2080","resources":{"followingIn":{"allowed":["GET","POST"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/2080/followingIn"},"images":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/2080/images"},"activity":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/2080/activities"},"social":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/2080/@social"},"recognition":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/2080/@recognition"},'
                        +'"trendingContent":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/2080/@trendingContent"},"trendingPlaces":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/2080/@trendingPlaces"},"avatar":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/2080/avatar?a=1799"},"followers":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/2080/@followers"},"following":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/2080/@following"},"members":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/members/people/2080"},"self":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/2080"},"html":{"allowed":["GET"],"ref":"https://discussions.qualys.com/people/jkent"},"extprops":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/2080/extprops"}},'
                        +'"followerCount":52,"followed":false,"published":"2010-07-24T19:17:59.307+0000","updated":"2017-11-28T13:52:25.028+0000","displayName":"jkent","mentionName":"jkent","followingCount":51,"jive":{"enabled":true,"external":false,"federated":false,"lastProfileUpdate":"2017-05-26T17:59:10.995+0000","locale":"en_US","externalContributor":false,"sendable":true,"timeZone":"America/New_York","username":"jkent","visible":true,"status":"registered"},"name":{},"photos":[{"value":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/2080/images/1/data?a=2039","jive_showSummaryLabel":false}],"status":"Some people just  cut out for life on the road.","thumbnailId":"1799","thumbnailUrl":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/2080/avatar?a=1799","initialLogin":"2010-07-24T19:17:59.307+0000","type":"person","typeCode":3},"content":{"text":"<p>Would a dynamic search list with the word  be a better way to do this?&nbsp; This way if new auth types are added  they '
                        +'just automatically appear?</p><p>&nbsp;</p><p>If you are doing pure windows or pure unix, you can just grab the search lists from the library and not reinvent the wheel.</p><a href=\\"https://discussions.qualys.com/people/intr0\\">https://discussions.qualys.com/people/intr0</a>","editable":false,"type":"text/html"},"parent":"https://jive-api-proxy.herokuapp.com/api/core/v3/contents/10546","replyCount":1,"status":"published","subject":"Quick way to test Authentication Record in Qualys","viewCount":15584,"visibleToExternalContributors":false,"abuseCount":0,"typeCode":2,"type":"message","helpfulCount":0,"unhelpfulCount":0,"attachments":[],"discussion":"https://jive-api-proxy.herokuapp.com/api/core/v3/contents/10546","messageTarget":"replyAsComment"},{"id":"16098","resources":{"outcomeTypes":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/messages/16098/outcomeTypes"},"editHTML":{"allowed":["GET"],"ref":"https://discussions.qualys.com/update-advanced-comment.jspa?id=16098"},'
                        +'"attachments":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/attachments/messages/16098"},"outcomes":{"allowed":["GET","POST"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/messages/16098/outcomes"},"messages":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/messages/16098/messages"},"self":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/messages/16098"},"html":{"allowed":["GET"],"ref":"https://discussions.qualys.com/message/16098?commentID=16098#comment-16098"},"extprops":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/messages/16098/extprops"},"helpful":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/messages/16098/helpful"},"likes":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/messages/16098/likes"}},"followerCount":0,"followed":false,"likeCount":0,"published":"2012-10-11T02:01:06.480+0000","tags":[],"updated":"2012-10-11T02:01:41.901+0000",'
                        +'"iconCss":"jive-icon-discussion","parentContent":{"id":"16092","html":"https://discussions.qualys.com/message/16092?commentID=16092#comment-16092","contentID":"null","name":"Quick way to test Authentication Record in Qualys","type":"message","typeCode":2,"uri":"https://jive-api-proxy.herokuapp.com/api/core/v3/messages/16092","iconCss":"jive-icon-discussion"},"parentPlace":{"id":"2005","html":"https://discussions.qualys.com/community/vulnerability-management","placeID":"19890","name":"IT Security","type":"space","typeCode":14,"uri":"https://jive-api-proxy.herokuapp.com/api/core/v3/places/19890","iconCss":"jive-icon-space"},"author":{"id":"7015","resources":{"followingIn":{"allowed":["GET","POST"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015/followingIn"},"images":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015/images"},"activity":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015/activities"},"social":{"allowed":["GET"],'
                        +'"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015/@social"},"recognition":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015/@recognition"},"trendingContent":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015/@trendingContent"},"trendingPlaces":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015/@trendingPlaces"},"avatar":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015/avatar?a=1729"},"followers":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015/@followers"},"following":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015/@following"},"members":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/members/people/7015"},"self":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015"},"html":{"allowed":["GET"],"ref":"https://discussions.qualys.com/people/pbaxi"},'
                        +'"extprops":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015/extprops"}},"followerCount":23,"followed":false,"published":"2012-05-24T01:33:41.123+0000","updated":"2019-10-08T16:01:58.772+0000","displayName":"Parag Baxi","mentionName":"pbaxi","followingCount":22,"jive":{"enabled":true,"external":false,"federated":false,"lastProfileUpdate":"2014-08-01T02:27:47.585+0000","locale":"en_US","externalContributor":false,"sendable":true,"timeZone":"America/Los_Angeles","username":"pbaxi","visible":true,"status":"registered"},"name":{"familyName":"Baxi","formatted":"Parag Baxi","givenName":"Parag"},"photos":[{"value":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015/images/1/data?a=3497","jive_showSummaryLabel":false}],"status":"I dont always encrypt my application layer but when I do I use","thumbnailId":"1729","thumbnailUrl":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/7015/avatar?a=1729","initialLogin":"2012-05-24T01:33:41.123+0000","type":"person","typeCode":3},"content":{"text":"<p>That is '
                        +'generally a good idea but will not achieve the goal of the report we hoped to create. We built this search list to only return results (from a report template using this search list) when there are issues with authentication. This way, a scheduled report could be put in place to with only data that is actionable.<p>&nbsp;</p><p>A dynamic search list would include the \\"* Authentication Method\\" which is not a symptom of an authentication issue.</p>","editable":false,"type":"text/html"},"parent":"https://jive-api-proxy.herokuapp.com/api/core/v3/messages/16092","replyCount":0,"status":"published","subject":"Re: Quick way to test Authentication Record in Qualys","viewCount":15584,"visibleToExternalContributors":false,"abuseCount":0,"typeCode":2,"type":"message","helpfulCount":0,"unhelpfulCount":0,"attachments":[],"discussion":"https://jive-api-proxy.herokuapp.com/api/core/v3/contents/10546","messageTarget":"replyAsComment"}],"startIndex":0}');
                        //res.setBody('{"itemsPerPage" : "25","list" : [],"startIndex" : 0}');
                    }
                   
                    String temp =  res.getBody().replace('\n','');
                    jsonstr = temp.replace('list','items');
                   
                    Map<string, Integer> mapparentId2Level = new Map<string, Integer>();
                    Integer level = 0;
                    string parntId = '';
                    if(jsonstr != null && jsonstr != ''){
                        feedCommentJson wrapperinstance=(feedCommentJson ) feedCommentJson.parse(jsonstr);
                        String fIJiveId = '';
                        
                        for(Integer j=0;j<wrapperinstance.items.size();j++){
                            level =0;
                            if(feedItemMap.get(s)!=null) {                       
                                CustomFeedComment__c fc = new CustomFeedComment__c();
                                fc.FeedItemId__c = feedItemMap.get(s);
                                
                                if(j ==0 && wrapperinstance.items.get(j).parentContent != null && wrapperinstance.items.get(j).parentContent.id != null){
                                    
                                    fIJiveId = wrapperinstance.items.get(j).parentContent.id;
                                }
                                
                                fc.FeedItem_JiveID__c = fIJiveId;
                                if(wrapperinstance.items.get(j).content!=null){
                                    if(fc.FeedItem_JiveID__c == '11685'){
                                        wrapperinstance.items.get(j).content.text = wrapperinstance.items.get(j).content.text.unescapeHtml4();
                                    }
                                    fc.Content__c = parseHtmlString(wrapperinstance.items.get(j).content.text);
                                    
                                    //getSFDCUserId();
                                    Matcher userCommentAncerTagMacher = Pattern.compile( '<a(.+?)>' ).matcher( fc.Content__c );                
                                    while ( userCommentAncerTagMacher.find() ) {                   
                                        String userCommentAncerTag = userCommentAncerTagMacher.group();                    
                                        String UserURL = userCommentAncerTag.substringBetween( ' href="', '"' );
                                        if(UserURL != null && UserURL.startsWith(System.label.Jive_Community_User_Anchor_URL)) {
                                            String comuunityNkName = UserURL.subString(UserURL.lastIndexOf('/')+1);
                                            Id UserId = nickNameToIdMap.get(comuunityNkName);
                                            String newUserURL = System.Label.Discussion_Community_Base_Url + System.Label.Discussion_Community_Url+ UserId;
                                            UserCommentUrlMap.put(UserURL,newUserURL);
                                        }  
                                    }
                                    if(UserCommentUrlMap != null && UserCommentUrlMap.size() > 0) {
                                        //comment mentioned userurl replace
                                        for(String ss : UserCommentUrlMap.keySet()) {
                                            fc.Content__c = fc.Content__c.replace(ss, UserCommentUrlMap.get(ss)); 
                                        }
                                    }
                                } 
                          
                                fc.Jive_Id__c = wrapperinstance.items.get(j).id;
                                if(wrapperinstance.items.get(j).answer == true){
                                     fc.Best_Answer__c = true;
                                }
                               
                                if(wrapperinstance.items.get(j).parent.contains('contents')){
                                    fc.Type__c = 'contents';      
                                }
                                else{
                                    fc.Type__c = 'messages';
                                } 
                                
                                if(wrapperinstance.items.get(j).parentContent != null && wrapperinstance.items.get(j).parentContent.id != null){
                                    string parentid  = wrapperinstance.items.get(j).parentContent.id;
                                    if(fc.Type__c == 'contents' || mapparentId2Level.containsKey(parentid) && mapparentId2Level.get(parentid) <=8){
                                        fc.Jive_ParentId__c = parentid;
                                    }
                                    else{
                                        
                                        fc.Jive_ParentId__c = parntId;
                                    }
                                }
                                if(wrapperinstance.items.get(j).author != null && wrapperinstance.items.get(j).author.id != null && jiveIdToUserIdMap.size() > 0 && jiveIdToUserIdMap.containsKey(wrapperinstance.items.get(j).author.id)){
                                    fc.CreatedById = jiveIdToUserIdMap.get(wrapperinstance.items.get(j).author.id);
                                    
                                }else{                                    
                                    fc.CreatedById = userinfo.getUserId(); 
                                }
     
                                if(wrapperinstance.items.get(j).published != null ){
                                    fc.CreatedDate = QualysUtils.formatDateValue(wrapperinstance.items.get(j).published); 
                                    //fc.CreatedDate = Date.valueOf(wrapperinstance.items.get(j).published);
                                }
                             
                                
                                //Added to assign likeurl to custom object field like_url__c
                                if(wrapperinstance.items.get(j).resources.likes != null && wrapperinstance.items.get(j).resources.likes.ref != null ){
                                    fc.like_url__c =  wrapperinstance.items.get(j).resources.likes.ref;
                 
                                }
                                // Below code is added to assign helpful url to custom object field Helpful_Url__c 
                                if(wrapperinstance.items.get(j).helpfulCount != null && wrapperinstance.items.get(j).helpfulCount > 0 ){
                                    if(wrapperinstance.items.get(j).resources.helpful != null && wrapperinstance.items.get(j).resources.helpful.ref != null ){
                                        fc.Helpful_Url__c = wrapperinstance.items.get(j).resources.helpful.ref;
                                    }
                                
                                }
                                List<feedCommentJson.cls_attachments> attachmentLists= new List<feedCommentJson.cls_attachments>();
                                //Below code is added to assign attachmenturl to custom object field attachment_url__c
                                if(wrapperinstance.items.get(j).attachments != null && wrapperinstance.items.get(j).attachments.size()>0 && wrapperinstance.items.get(j).attachments[0].id != null ){
                                    fc.attachment_url__c = wrapperinstance.items.get(j).attachments[0].name+'-#-'+wrapperinstance.items.get(j).attachments[0].url;
                                    attachmentLists.addAll(wrapperinstance.items.get(j).attachments);
                                }
                                if(attachmentLists != null && attachmentLists.size() >0){
                                    for(feedCommentJson.cls_attachments ss: attachmentLists){
                                        if(ss != null && ss.name != null && ss.url != null){
                                            attachmentUrl2FeedComment.put(ss.name+'-#-'+ss.url,fc);  
                                        }
                                    }
                                    attachmentUrl2FeedComment.remove(fc.attachment_url__c);
                                }
                               
                                feedCommentList.add(fc);
                                if((mapparentId2Level.containsKey(fc.Jive_ParentId__c) && !mapparentId2Level.containsKey(fc.Jive_Id__c)) || fc.Type__c == 'contents' ){
                                    if(fc.Type__c == 'contents'){
                                        mapparentId2Level.put(fc.Jive_Id__c, 0);
                                    }
                                    else{
                                        Integer l = mapparentId2Level.get(fc.Jive_ParentId__c);
                                        l = l+1;
                                        if(l <= 8){
                                            mapparentId2Level.put(fc.Jive_Id__c, l);
                                            if(l==8){
                                                parntId = fc.Jive_Id__c;
                                            }
                                        }
                                    }
                                }
                            }  
                        }
                    }
                }
            }
            if(attachmentUrl2FeedComment != null && attachmentUrl2FeedComment.size() > 0){
                Integer i = 0;
                for(string au : attachmentUrl2FeedComment.keySet()){   
                    CustomFeedComment__c temp = attachmentUrl2FeedComment.get(au);
                    CustomFeedComment__c fc = new CustomFeedComment__c();
                    fc.FeedItemId__c = temp.FeedItemId__c;
                    fc.Type__c = temp.Type__c;
                    fc.Jive_ParentId__c = temp.Jive_ParentId__c;
                    fc.Jive_Id__c = i+'-'+temp.Jive_Id__c;
                    fc.CreatedById = temp.CreatedById;
                    fc.CreatedDate = temp.CreatedDate;
                    fc.attachment_Url__c = au;
                    feedCommentList.add(fc);
                    i++;
                }
            }
                return feedCommentList;
            }              
        
        public  NC_feedCommentWrapper setFeedCommentInLevels(List<CustomFeedComment__c> finalList){ 
            
            List<CustomFeedComment__c> commentsList = new List<CustomFeedComment__c>();
            Map<String,FeedComment> jiveIdTofeedComment= new Map<String,FeedComment>(); 
            Set<Id> notAvailableIds = new Set<Id>();
            Map<string , FeedComment> mapLikeUrl2FeedComment = new Map<string , FeedComment>();
            Map<String,String> mapFiId2JiveId = new Map<String, String>();
            List<Error_Log__c>errorLogList = new List<Error_Log__c>();
            List<Error_Log__c>errorLogListForlargeComment = new List<Error_Log__c>();
            Map<Id , FeedComment> mapFI2BestComment = new Map<ID , FeedComment>();
            List<String>fCJiveIdNot2Insert = new List<String>();
            NC_feedCommentWrapper fcWrapper = new NC_feedCommentWrapper();
            
            for(Integer i = 0;i<10;i++){               
                for(CustomFeedComment__c c:finalList){                    
                    if((i==0 && c.Type__c == 'contents') || (i> 0 && c.Type__c =='messages')){
                        if((i==0 && c.Type__c == 'contents') || (!notAvailableIds.contains(c.ID) && jiveIdTofeedComment.containsKey(c.Jive_ParentId__c) && jiveIdTofeedComment.get(c.Jive_ParentId__c).id != null)){
                            
                            FeedComment fc=new FeedComment();
                            fc.FeedItemId = c.FeedItemId__c;
                            if(c.content__c!=null){
                                if(c.content__c.length()<10000 ){
                                    fc.CommentBody = c.content__c;
                                }else{
                                    fc.CommentBody = placeholder;
                                    Error_Log__c log = new Error_Log__c();
                                    log.Type__c = 'Discussion';
                                    log.Name = 'LargeFeedComment';
                                    log.Jive_Id__c = c.FeedItem_JiveID__c;
                                    log.Error_Description__c = 'Body of comment is greater then 10,000 character';
                                    errorLogListForlargeComment.add(log);                          
                                }
                            }
                            if(c.RelatedRecordId__c != null){
                                fc.RelatedRecordId = c.RelatedRecordId__c;
                                fc.CommentType = 'ContentComment';   
                            }else{
                                 fc.CommentType = 'TextComment'; 
                            }
                             
                            fc.IsRichText = true; 
                             
                            if(i > 0){  
                                fc.threadParentId = jiveIdTofeedComment.get(c.Jive_ParentId__c).id;
                            }
                            fc.CreatedById = c.CreatedById;
                            
                            fc.CreatedDate  = c.CreatedDate; 
                            fc.Revision = 1;
                            
                            if(c.Best_Answer__c){
                                mapFI2BestComment.put(c.FeedItemId__c , fc);
                            } 
                            
                            // below code is added make map of helpful url corresponding to that feedcomment  
                            if(c.Helpful_Url__c != null){
                                  mapLikeUrl2FeedComment.put(c.Helpful_Url__c , fc);  
                            }
                            if(c.like_url__c != null){
                                  mapLikeUrl2FeedComment.put(c.like_url__c, fc);  
                            }   
                            
                                              
                            jiveIdTofeedComment.put(c.Jive_Id__c , fc);
                            notAvailableIds.add(c.Id);
                            mapLikeUrl2FeedComment.put(c.like_url__c, fc);   
                            mapFiId2JiveId.put(c.FeedItemId__c, c.FeedItem_JiveID__c);                       
                        }        
                    }    
                }
                                
                //List<FeedComment> fclist2 = new List<FeedComment>();
                Map<String, FeedComment> jiveid2Fc2Insert = new  Map<String, FeedComment>();
                for(String s : jiveIdTofeedComment.keySet()){                   
                    if(jiveIdTofeedComment.get(s).Id == null && !fCJiveIdNot2Insert.contains(s)){
                        //fclist2.add(jiveIdTofeedComment.get(s));
                        jiveid2Fc2Insert.put(s, jiveIdTofeedComment.get(s));
                    }
                }
                Database.SaveResult[] recordList = Database.insert(jiveid2Fc2Insert.values(), false);
                
                for(Integer k = 0; k<jiveid2Fc2Insert.keySet().size() ; k++){
                    if(!recordList[k].isSuccess()){
                                                                             
                        Error_Log__c log = new Error_Log__c();
                        log.Type__c = 'Discussion';
                        log.Name = 'FeedCommentInsert';
                        log.Jive_Id__c = mapFiId2JiveId.get(jiveid2Fc2Insert.values()[k].FeedItemId)+'-'+ new List<String>(jiveid2Fc2Insert.keySet())[k];
                        log.Error_Description__c = recordList[k].getErrors()[0].getMessage();
                        fCJiveIdNot2Insert.add( new List<String>(jiveid2Fc2Insert.keySet())[k] );
                        
                        errorLogList.add(log);                        
                    }
                }
                
                /*if(errorLogList != null && errorLogList.size() > 0 ){
                    break;
                }*/
               
            }  // exit of main for loop
            
            if(errorLogListForlargeComment != null && errorLogListForlargeComment.size() > 0 ){
                errorLogList.addAll(errorLogListForlargeComment);
            }
            if(errorLogList != null && errorLogList.size()>0){
                insert errorLogList;
            }
               
            fcWrapper.feedCommentLikeUrl2FC = mapLikeUrl2FeedComment;
            fcWrapper.fiBestCommentMap = mapFI2BestComment; 
            return fcWrapper;
        }
        
        //save Image for feeditem Comment
        public List<CustomFeedComment__c> saveImageForFeedComment(List<CustomFeedComment__c> feedCommentList){           
            Map<String,String> imgToDownloadMap=new Map<String,String>();
            Map<String,String> imgNameToHrefMap=new Map<String,String>(); 
            Map<String,String> imgNameToNewURlMap=new Map<String,String>(); 
            Map<String,String> UserUrlMap=new Map<String,String>();  
            Map<String,String> tagUrlMap=new Map<String,String>(); 
            Map<String,Integer> jiveId2Imgcount = new Map<String,Integer>();
            List<ContentVersion> cntVersionList = new List<ContentVersion>();
            List<Error_Log__c>errorLogList = new List<Error_Log__c>();
            Map<String,string> fc2ImgTag2Replace= new Map<String,String>();
            Map<string,string> replaceAncTag = new Map<string,string>();
            Map<string,string> replaceAncVal = new Map<string,string>();
            Map<string,string> escapeHrefHTML = new Map<string,string>();
            Map<string,url_Mapping__c> jiveId2UrlMappingRec= getUrlMapping();
            
            For(CustomFeedComment__c fi:feedCommentList){
                Integer imgCount=0;
                if(String.isnotBlank(fi.Content__c)){
                    String str = fi.Content__c;
                    Matcher imgMatcher = Pattern.compile( '<img(.+?)/>' ).matcher( str );
                    Matcher userAncerTagMacher = Pattern.compile( '<a(.+?)/a>' ).matcher( str ); 
                    
                    while ( userAncerTagMacher.find() ) {                   
                        String userAncerTag = userAncerTagMacher.group();                    
                        String UserURL = userAncerTag.substringBetween( ' href="', '"' );
                        if(String.isNotBlank(UserURL) && UserURL.startsWith(System.Label.Jive_Community_User_Anchor_URL)){
                        
                            String comuunityNkName = UserURL.subString(UserURL.lastIndexOf('/')+1);
                            Id UserId = nickNameToIdMap.get(comuunityNkName);
                            String newUserURL = System.Label.Discussion_Community_Base_Url + System.Label.Discussion_Community_Url + UserId;
                            UserUrlMap.put(UserURL,newUserURL);
                        }  
                        //Below code is written to replace the <a>tag containing the Img inside and replace it with just the Img tag.
                        
                        else if(userAncerTag.contains('<img')){
                        
                            String imageTag = userAncerTag.substring(userAncerTag.indexOf('<img'), userAncerTag.indexOf('/>')+2);
                            if(imageTag != null && imageTag != ''){
                                replaceAncTag.put(userAncerTag, imageTag);
                            }
                        }
                        //Below code is added to replace the Discussion url in body
                        else if(UserURL != null &&  (UserURL.contains('docs/DOC') || UserURL.contains('thread/'))){
                            string anchorValue =userAncerTag.substringBetween( '>', '</a>' );
                            system.debug('anchorValue-----------'+anchorValue );
                            if(anchorValue != null && anchorValue.contains('<u>')){
                                system.debug('anchorValue----------ss-'+anchorValue );
                                anchorValue = anchorValue.substringBetween( '<u>', '</u>' ); 
                            }else{
                                anchorValue = anchorValue;
                            }
                            system.debug('anchorValue ----------'+anchorValue );
                            String threadName = UserURL.subString(UserURL.lastIndexOf('/')+1);
                            String[] JiveId= threadName.split('-');
                            system.debug('JiveId===>'+JiveId);
                            string newUrl = '';
                            if(UserURL.contains('docs/DOC') ){   
                                if(jiveId2UrlMappingRec.containsKey(jiveId[1])){
                                    newUrl = System.Label.Discussion_Community_Base_Url + System.Label.Discussion_Community_Url+ jiveId2UrlMappingRec.get(jiveId[1]).Salesforce_Id__c;                     
                                    
                                    
                                    replaceAncTag.put('href="'+UserURL+'"', 'href="'+newUrl+'"');
                                    replaceAncVal.put(anchorValue, jiveId2UrlMappingRec.get(jiveId[1]).Title__c);
                                }
                            }
                            else{
                               if(JiveId[0] != null && JiveId[0].contains('?')){
                                    String DiscussionID = JiveId[0].substringBefore('?');
                                    
                                    if(jiveId2UrlMappingRec.containsKey(DiscussionID)){
                                        newUrl = System.Label.Discussion_Community_Base_Url + System.Label.Discussion_Community_Url+ jiveId2UrlMappingRec.get(DiscussionID).Salesforce_Id__c;                     
                                       replaceAncTag.put('href="'+UserURL+'"', 'href="'+newUrl+'"');
                                        replaceAncVal.put(anchorValue, jiveId2UrlMappingRec.get(DiscussionID).Title__c);
                                    }
                                }
                                else if(JiveId[0] != null && JiveId[0].contains('#')){
                                    String[] DiscussionID = JiveId[0].split('#');
                                    if(jiveId2UrlMappingRec.containsKey(DiscussionID[0])){
                                        newUrl = System.Label.Discussion_Community_Base_Url + System.Label.Discussion_Community_Url+ jiveId2UrlMappingRec.get(DiscussionID[0]).Salesforce_Id__c;                     
                                        replaceAncTag.put('href="'+UserURL+'"', 'href="'+newUrl+'"');
                                        replaceAncVal.put(anchorValue, jiveId2UrlMappingRec.get(DiscussionID[0]).Title__c);
                                    }
                                }
                                
                                else{
                                    system.debug('JiveId[0]===>'+JiveId[0]); 
                                    if(jiveId2UrlMappingRec.containsKey(JiveId[0])){
                                        newUrl = System.Label.Discussion_Community_Base_Url + System.Label.Discussion_Community_Url+ jiveId2UrlMappingRec.get(jiveId[0]).Salesforce_Id__c;                     
                                        replaceAncTag.put('href="'+UserURL+'"', 'href="'+newUrl+'"'); 
                                        replaceAncVal.put(anchorValue, jiveId2UrlMappingRec.get(jiveId[0]).Title__c);
                                    }
                                }                   
                            } 
                        }
                        
                        // upto here
                        if(String.isNotBlank(UserURL)){
                            escapeHrefHTML.put(UserURL, UserURL.escapeHtml4());
                        }
                        system.debug('--------------'+replaceAncVal);
                        //upto here ..
                    }
                    while ( imgMatcher.find() ) {
                        
                        String imageTag = imgMatcher.group();
                        
                        String imageURL = imageTag.substringBetween( ' src="', '"' );
                        
                        if(imageURL.length() > 10){
                            String imageName = imageURL.subString(imageURL.lastIndexOf('/')+1);
                            String textStripImageName = 'downloadImage';
                            String newImageName = '';
                            if(imageURL.contains(textStripImageName)){
                                String[] imageArr = imageURL.split(textStripImageName)[1].split('/'); 
                                String jiveUniqueId='';
                                if(!imageArr.isEmpty()){
                                    if(imageArr[1] != null){
                                        if(imageArr[1].contains('-')){
                                            list<string> temp = imageArr[1].split('-');
                                            if(temp.size()>=2){
                                                jiveUniqueId = temp[2];
                                            }
                                            else{
                                                jiveUniqueId = temp[1];
                                            } 
                                        }else{
                                            jiveUniqueId = imageArr[1];
                                        }
                                    }
                                } 
                                
                                newImageName =  imgCount+'_'+jiveUniqueId+'_'+imageName;                       
                                imgCount++; 
                            }
                            else{
                                newImageName = imgCount+'_'+imageName;
                                imgCount++; 
                            }
                            imgToDownloadMap.put(newImageName, imageURL);
                        
                        }else{
                        
                            fc2ImgTag2Replace.put(fi.id, imageTag); 
                        
                        }               
                    }
                    jiveId2Imgcount.put(fi.Jive_Id__c,imgCount);
                    
                    //To replace tags
                    
                    Matcher tagsAncerTagMacher = Pattern.compile( '<a(.+?)/a>' ).matcher( str );   
                    
                    while ( tagsAncerTagMacher.find() ) {                   
                        String tagLink = tagsAncerTagMacher.group();         
                        String tagToLink = tagLink.substringBetween('>', '</a>');         
                        String tagUrl = tagLink.substringBetween( ' href="', '"' );
                        if(tagUrl != null && tagUrl.startsWith(System.Label.jive_Community_Topic_Anchor_URL)){                    
                            tagUrlMap.put(tagLink,tagToLink);
                        }
                        if(tagUrl != null && tagUrl.startsWith('https://discussions.qualys.com/community')){
                            tagUrlMap.put(tagLink,tagToLink);
                        }
                    }  
                
                }
            }
            Http http = new Http();
            HttpRequest req= new HttpRequest();
            req.setMethod('GET');  
            for(String imgName:imgToDownloadMap.Keyset()){
                req.setEndpoint(imgToDownloadMap.get(imgName));
                req.setHeader('Authorization', 'Basic Z2F1cmF2YjpTRkRDTWlncmF0aW9u'); 
                HttpResponse res = new HttpResponse();
                req.settimeout(120000);
                //req.setEndpoint('https://raw.githubusercontent.com/paragbaxi/qualysguard_vm_scan_trend/master/images/screenshot-report-template-id.png');
                if(!Test.isRunningTest()){  
                    try{
                        res = http.send(req); 
                    }catch(System.CalloutException e) {
                    
                        Error_Log__c log = new Error_Log__c();
                        log.Type__c = 'Discussion';
                        log.Name = 'Callout error while hitting image URL';
                        log.Error_Description__c = e.getMessage();
                        errorLogList.add(log);  
                    }  
                }
                else{
                    Blob bodyBlob = Blob.ValueOf('66558');
                    res.setBodyAsBlob(bodyBlob);
                }
                //if(res.getStatusCode() == 200) {
                
                    Blob b =  res.getBodyAsBlob();
                    if(b != null){
                        string tempVal = EncodingUtil.base64Encode(b);
                        system.debug('tempVal -----------'+tempVal );
                        if(string.isNotBlank(tempVal)){
                            ContentVersion cv=new ContentVersion();
                            cv.Title=imgName;
                            cv.SharingOption = 'A';
                            cv.ContentLocation = 'S';
                            cv.PathOnClient ='/' + imgName;
                            String temp = EncodingUtil.base64Encode(b);
                            cv.VersionData = EncodingUtil.base64Decode(temp);
                            if(!Test.isRunningTest()){
                                cv.NetworkId = NetworkScopeId;
                            }
                            cntVersionList.add(cv);
                        }
                    }
                // }
                
            }
            Map<string,string> cntDocIdMap=new Map<string,string>();
            if(!cntVersionList.isEmpty()){
                Insert cntVersionList;
                
                
                List<String> cntVersionIds=new List<String>();
                
                for(contentversion cv:cntVersionList){
                    cntVersionIds.add(cv.id);
                }   
                List<ContentVersion> cvListWithDocIds=
                [select Id, ContentUrl, ContentDocumentId, Title FROM ContentVersion where id IN:cntVersionIds];
                for(contentversion cv:cvListWithDocIds){
                    cntDocIdMap.put(cv.Title,cv.ContentDocumentId);
                }  
                qUtil.ShareFilesWithLibraries(cntVersionIds, cntDocIdMap);
            }
            
            
            // Below few lines of code is written to take care of the <a> containing <img>
            For(CustomFeedComment__c fi:feedCommentList){
                for(String ancUrl : replaceAncTag.keySet()){
                    if(ancUrl != null && fi.Content__c != null && fi.Content__c.contains(ancUrl) && replaceAncTag.get(ancUrl) != null ){
                        fi.Content__c = fi.Content__c.replace(ancUrl,replaceAncTag.get(ancUrl));
                    }
                }
            }
            //Upto here 
            For(CustomFeedComment__c fi:feedCommentList){
                for(String ancVal : replaceAncVal.keySet()){
                    system.debug('ancVal @@@@@@@@@@@@'+ancVal );
                    if(ancVal != null && fi.Content__c != null && fi.Content__c.contains(ancVal) && replaceAncVal.get(ancVal) != null ){
                        system.debug('ddddddddddfi.Content__c@@@@@@@@@@@@'+fi.Content__c);
                        if(ancVal == ':'){
                            fi.Content__c = fi.Content__c.replace(ancVal,':');
                        }else{
                            fi.Content__c = fi.Content__c.replace(ancVal,replaceAncVal.get(ancVal));
                        }
                        system.debug('fi.Content__c@@@@@@@@@@@@'+fi.Content__c);
                    }
                }
            }
            For(CustomFeedComment__c fi:feedCommentList){
                if(jiveId2Imgcount.containsKey(fi.Jive_Id__c) && jiveId2Imgcount.get(fi.Jive_Id__c)>10 ){
                
                    fi.Content__c = placeholder;
                    Error_Log__c log = new Error_Log__c();
                    log.Type__c = 'Discussion';
                    log.Name = 'FeedComment-More than 10 images';
                    log.Jive_Id__c = fi.FeedItem_JiveID__c;
                    log.Error_Description__c = 'cannot include more than 10 inline images on a single feed entity';
                    errorLogList.add(log);  
                    
                }
                else{
                    if(!cntDocIdMap.isEmpty()){
                    
                        for(String s:cntDocIdMap.keyset()){
                            //fi.body=fi.body.replace(imgToDownloadMap.get(s),'/servlet/servlet.FileDownload?file='+cntDocIdMap.get(s));
                            //if(s != null && imgNameToHrefMap.containsKey(s)){
                            //System.debug('In else!!!!!!!!!!!!!!!ssss'+s);
                            //System.debug('imgNameToHrefMap.containsKey(s)In else!!!!!!!!!!!!!!!'+imgNameToHrefMap.containsKey(s));
                            //System.debug('imgNameToHrefMap.containsKey(s)In else!!!!!!!!!!!!!!!'+imgNameToNewURlMap.containsKey(s));
                            //fi.Content__c= fi.Content__c.replace(imgNameToHrefMap.get(s),imgNameToNewURlMap.get(s)); 
                            //}
                            if(fi.Content__c != null){
                                fi.Content__c = fi.Content__c.replace(imgToDownloadMap.get(s),'sfdc://'+cntDocIdMap.get(s));
                            }
                        } 
                    
                    }
                }
                
                
                if(fi.Content__c != null && !fc2ImgTag2Replace.isEmpty() && fc2ImgTag2Replace.containsKey(fi.id)){
                    fi.Content__c = fi.Content__c.replace(fc2ImgTag2Replace.get(fi.id),'') ;                   
                }
                
                for(String s:tagUrlMap.keyset()){
                    if(fi.Content__c != null){
                        fi.Content__c=fi.Content__c.replace(s,'$'+tagUrlMap.get(s));
                    }
                }
                
                // Below code replaces the @mention user urls
                if(fi.Content__c != null &&UserUrlMap != null && UserUrlMap.Keyset().size() >0 ) {
                    for(String s : UserUrlMap.keySet()){
                        fi.Content__c=  fi.Content__c.replace(s, UserUrlMap.get(s)); 
                    }
                }
                if(fi.Content__c != null && escapeHrefHTML != null  && escapeHrefHTML.keySet().size()>0){
                    for(String s : escapeHrefHTML.keySet()){
                        fi.Content__c=  fi.Content__c.replace(s, escapeHrefHTML.get(s)); 
                    }
                }
            }
            if(!errorLogList.isEmpty()){
                insert errorLogList;      
            }
            
            return feedCommentList; 
            
        } 
        // -- upto here 
        public List<FeedItem> saveImageForFeedItem(Map<String,FeedItem> feedItemList){   
            List<Topic> topicList1=[select id,Name from Topic where NetworkId =:NetworkScopeId]; 
            Map<String,String> topicMap=getTopicMap(topicList1);       
            Map<String,String> imgToDownloadMap=new Map<String,String>(); 
            Map<String,String> imgNameToHrefMap=new Map<String,String>();
            Map<String,String> imgNameToNewURlMap=new Map<String,String>();
            Map<String,String> UserUrlMap=new Map<String,String>(); 
            List<ContentVersion> cntVersionList = new List<ContentVersion>();
            Map<String,String> UserAnchorUrlMap = new Map<String,String>();
            Map<String,Integer> jiveId2FiImgcount = new Map<String,Integer>();
            List<Error_Log__c> errorLogList = new List<Error_Log__c>();
            Map<String,String> divOldVal2NewVal=new Map<String,String>();
            Map<String,string> fi2ImgTag2Replace = new Map<String,String>();
            Map<string,string> replaceAncTag = new Map<string,string>();
            Map<string,string> replaceAncVal = new Map<string,string>();
            Map<String,Topic> tMap=new Map<String,Topic>();  
            
            Map<String,String> topicName2Id = new Map<String,String>(); 
            Map<string,string> escapeHrefHTML = new Map<string,string>();
            Map<String,String> topicUrl2TopicName=new Map<String,String>(); 
            Set<string> tags = new Set<string>();
            Map<string,Url_Mapping__c> jiveId2UrlMappingRec = getUrlMapping();
            
            For(String fi:feedItemList.keySet()){
                system.debug('fi-----------'+fi);
                Integer imgCount=0;
                String str = feedItemList.get(fi).Body;                                
                Matcher userAncerTagMacher = Pattern.compile( '<a(.+?)/a>' ).matcher( str ); 
                Matcher tagsAncerTagMacher = Pattern.compile( '<a(.+?)/a>' ).matcher( str  ); 
                Matcher divMatcher= Pattern.compile( '<div(.+?)>' ).matcher( str );
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
                while ( userAncerTagMacher.find() ) {                   
                    String userAncerTag = userAncerTagMacher.group();                    
                    String UserURL = userAncerTag.substringBetween( ' href="', '"' );
                    if(String.isNotBlank(UserURL) && UserURL.startsWith(System.Label.Jive_Community_User_Anchor_URL)){
                        
                        String comuunityNkName = UserURL.subString(UserURL.lastIndexOf('/')+1);
                        Id UserId = nickNameToIdMap.get(comuunityNkName);
                        String newUserURL = System.Label.Discussion_Community_Base_Url + System.Label.Discussion_Community_Url+ UserId;
                        UserUrlMap.put(UserURL,newUserURL);
                    }  
                    
                    // Beow code to replace the Image anchor tags.
                     else if(userAncerTag.contains('<img')){
                        system.debug('userAncerTag----------'+userAncerTag);
                        String imageTag = userAncerTag.substring(userAncerTag.indexOf('<img'), userAncerTag.indexOf('/>')+2);
                        system.debug('imageTag ----------'+imageTag );
                        if(imageTag != null && imageTag != ''){
                            if(imageTag.contains('//>')){imageTag = imageTag.replace('//>','/>');}
                            replaceAncTag.put(userAncerTag, imageTag);
                        }
                    }
                    //upto here ..
                    //Below code is added to replace the Discussion url in body
                   
                        else if(UserURL != null &&  (UserURL.contains('docs/DOC') || UserURL.contains('thread'))){
                            string anchorValue= userAncerTag.substringBetween( '>', '</a>' );
                            if(anchorValue != null && anchorValue.contains('<u>')){
                                anchorValue = anchorValue.substringBetween( '<u>', '</u>' ); 
                            }else{
                                anchorValue = anchorValue;
                            }
                            String threadName = UserURL.subString(UserURL.lastIndexOf('/')+1);
                            String[] JiveId= threadName.split('-');
                            system.debug('JiveId===>'+JiveId);
                            string newUrl = '';
                            if(userAncerTag.contains('docs/DOC') ){   
                                if(jiveId2UrlMappingRec.containsKey(JiveId[1])){
                                    newUrl = System.Label.Discussion_Community_Base_Url + System.Label.Discussion_Community_Url+ jiveId2UrlMappingRec.get(jiveId[1]).Salesforce_Id__c;                     
                                    replaceAncTag.put('href="'+UserURL+'"', 'href="'+newUrl+'"');
                                    replaceAncVal.put(anchorValue, jiveId2UrlMappingRec.get(jiveId[1]).Title__c);
                                }
                            }
                            else{
                             if(JiveId[0] != null && JiveId[0].contains('?')){
                                    
                                    String DiscussionID = JiveId[0].substringBefore('?');
                                    if(jiveId2UrlMappingRec.containsKey(DiscussionID)){
                                        newUrl = System.Label.Discussion_Community_Base_Url + System.Label.Discussion_Community_Url+ jiveId2UrlMappingRec.get(DiscussionID).Salesforce_Id__c;                     
                                        replaceAncTag.put('href="'+UserURL+'"', 'href="'+newUrl+'"');
                                        replaceAncVal.put(anchorValue, jiveId2UrlMappingRec.get(DiscussionID).Title__c);
                                    }
                                }
                                else if(JiveId[0] != null && JiveId[0].contains('#')){
                                    String[] DiscussionID = JiveId[0].split('#');
                                    if(jiveId2UrlMappingRec.containsKey(DiscussionID[0])){
                                        newUrl = System.Label.Discussion_Community_Base_Url + System.Label.Discussion_Community_Url+ jiveId2UrlMappingRec.get(DiscussionID[0]).Salesforce_Id__c;                     
                                        replaceAncTag.put('href="'+UserURL+'"', 'href="'+newUrl+'"');
                                        replaceAncVal.put(anchorValue, jiveId2UrlMappingRec.get(DiscussionID[0]).Title__c);
                                    }
                                }
                                
                                else{
                                    system.debug('JiveId[0]===>'+JiveId[0]); 
                                    if(jiveId2UrlMappingRec.containsKey(JiveId[0])){
                                        newUrl = System.Label.Discussion_Community_Base_Url + System.Label.Discussion_Community_Url+ jiveId2UrlMappingRec.get(jiveId[0]).Salesforce_Id__c;                     
                                        replaceAncTag.put('href="'+UserURL+'"', 'href="'+newUrl+'"'); 
                                        replaceAncVal.put(anchorValue, jiveId2UrlMappingRec.get(jiveId[0]).Title__c);
                                    }
                                }                   
                            } 
                        }
                    // upto here 
                    
                    if(String.isNotBlank(UserURL)){
                        escapeHrefHTML.put(UserURL, UserURL.escapeHtml4());
                    }
                }
                
                //Below processing is for images
                Matcher imgMatcher = Pattern.compile( '<img(.+?)>' ).matcher( str );
                while ( imgMatcher.find() ) {                   
                    String imageTag = imgMatcher.group();
                    
                    String imageURL = imageTag.substringBetween( ' src="', '"' );
                    
                    if(imageURL.length() > 10){   
                        String imageName = imageURL.subString(imageURL.lastIndexOf('/')+1);
                        String textStripImageName = 'downloadImage';
                        String newImageName ='';
                        if(String.isNotBlank(imageURL) && imageURL.contains(textStripImageName)){
                            String[] imageArr = imageURL.split(textStripImageName)[1].split('/');
                            String jiveUniqueId = '';  
                            if(!imageArr.isEmpty()){  
                                if(imageArr[1] != null){
                                    if(imageArr[1].contains('-')){
                                        list<string> temp = imageArr[1].split('-');
                                        if(temp.size()>=2){
                                            jiveUniqueId = temp[2];
                                        }
                                        else{
                                           jiveUniqueId = temp[1];
                                        } 
                                    }else{
                                        jiveUniqueId = imageArr[1];
                                    }
                                }
                            } 
                            
                            newImageName =  imgCount+'_'+jiveUniqueId+'_'+imageName;
                            imgCount++; 
                        }
                        else{
                            newImageName = imgCount+'_'+imageName;
                            imgCount++; 
                        }
                        imgToDownloadMap.put(newImageName, imageURL ); 
                    }else{
                         
                         fi2ImgTag2Replace.put(fi, imageTag); 
                                               
                    }
                }
                
                jiveId2FiImgcount.put(fi,imgCount);  
                
                             
            }
            
             if(tags!=null){                    
             system.debug('topicMap=========='+topicMap);
            for(String tgs : tags){
                System.debug('tgs.toLowerCase().deleteWhitespace()=========='+tgs.toLowerCase().deleteWhitespace());
                system.debug(topicMap.containsKey(tgs.toLowerCase().deleteWhitespace()));
                system.debug(topicMap.containsKey(tgs));
                if(String.isNotBlank(tgs) && topicMap != null && !topicMap.containsKey(tgs.toLowerCase().deleteWhitespace())){
                    System.debug('tvvvgs.toLowerCase().deleteWhitespace()=========='+tgs.toLowerCase().deleteWhitespace());
                    Topic tObj=new Topic();
                    tObj.name=tgs;
                    tObj.NetworkId=NetworkScopeId; 
                    tMap.put(tObj.name,tObj);                            
                }
            }
        }  
        
            Http http = new Http();
            HttpRequest req= new HttpRequest();
            req.setMethod('GET'); 
           req.settimeout(120000);
            for(String imgName:imgToDownloadMap.Keyset()){
                
                req.setEndpoint(imgToDownloadMap.get(imgName));
                req.setHeader('Authorization', 'Basic Z2F1cmF2YjpTRkRDTWlncmF0aW9u');   
                HttpResponse res = new HttpResponse();
                if(!Test.isRunningTest()){
                    try{
                         res = http.send(req); 
                    }catch(System.CalloutException e) {
                        
                        Error_Log__c log = new Error_Log__c();
                        log.Type__c = 'Discussion';
                        log.Name = 'Callout error while hitting image URL';
                        log.Error_Description__c = e.getMessage();
                        errorLogList.add(log);  
                    }        
                }else{
                    Blob bodyBlob = Blob.ValueOf('66558');
                    res.setBodyAsBlob(bodyBlob);
                }
                //if(res.getStatusCode() == 200) {
                    Blob b =  res.getBodyAsBlob();
                    
                    system.debug('b------------'+b);
                    if(b != null){
                        string tempVal = EncodingUtil.base64Encode(b);
                        system.debug('tempVal -----------'+tempVal );
                        if(string.isNotBlank(tempVal)){
                            ContentVersion cv=new ContentVersion();
                            cv.Title=imgName;
                            cv.SharingOption = 'A';
                            cv.ContentLocation = 'S';
                            cv.PathOnClient ='/' + imgName;         
                            String temp = EncodingUtil.base64Encode(b);
                            cv.VersionData = EncodingUtil.base64Decode(temp);
                            if(!Test.isRunningTest()){
                                cv.NetworkId = NetworkScopeId;
                            }
                            cntVersionList.add(cv); 
                        }
                    }
                //}      
            }
            Map<string,string> cntDocIdMap=new Map<string,string>();
            if(!cntVersionList.isEmpty()){
                Insert cntVersionList;
            }
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
            List<String> cntVersionIds=new List<String>();
            
            for(contentversion cv:cntVersionList){
                cntVersionIds.add(cv.id);
            }   
            List<ContentVersion> cvListWithDocIds=
                [select Id, ContentUrl, ContentDocumentId, Title FROM ContentVersion where id IN:cntVersionIds];
            for(contentversion cv:cvListWithDocIds){
                cntDocIdMap.put(cv.Title,cv.ContentDocumentId);
            }  
            qUtil.ShareFilesWithLibraries(cntVersionIds, cntDocIdMap);
            // Below few lines of code is written to take care of the <a> containing <img>
            For(String fi:feedItemList.keySet()){
                for(String ancUrl : replaceAncTag.keySet()){
                    system.debug('replaceAncTag!!!!!!!!!!!!!'+replaceAncTag);
                    
                    system.debug('replaceAncTag!!!!!!!!!!!!!'+replaceAncTag);
                    if(ancUrl != null && feedItemList.get(fi).body.contains(ancUrl) && replaceAncTag.get(ancUrl) != null ){
                        feedItemList.get(fi).body = feedItemList.get(fi).body.replace(ancUrl,replaceAncTag.get(ancUrl));
                    }
                }
            }
            
            For(String  fi: feedItemList.keySet()){
                for(String ancVal : replaceAncVal.keySet()){
                    if(ancVal != null && feedItemList.get(fi).body != null && feedItemList.get(fi).body.contains(ancVal) && replaceAncVal.get(ancVal) != null ){
                        
                        if(ancVal == ':'){
                            feedItemList.get(fi).body = feedItemList.get(fi).body.replace(ancVal,':');
                        }else{
                            feedItemList.get(fi).body = feedItemList.get(fi).body.replace(ancVal,replaceAncVal.get(ancVal));
                        }
                        
                    }
                    
                    
                }
            }
            
            system.debug('divOldVal2NewVal ----------'+divOldVal2NewVal );
            if(divOldVal2NewVal != null && divOldVal2NewVal.size() > 0){
                For(String  fi: feedItemList.keySet()){  
                    for(String ss : divOldVal2NewVal.keySet()) {
                        if(ss != null && feedItemList.get(fi).body != null && feedItemList.get(fi).body.contains(ss) && replaceAncVal.get(ss) != null ){
                           feedItemList.get(fi).body = feedItemList.get(fi).body.replace(ss, divOldVal2NewVal.get(ss));
                       }
                    }
                }
            }   
            
            For(String fi:feedItemList.keySet()){
                if(jiveId2FiImgcount.containsKey(fi) && jiveId2FiImgcount.get(fi)>10 ){
                    feedItemList.get(fi).body = placeholder;  
                    Error_Log__c log = new Error_Log__c();
                    log.Type__c = 'Discussion';
                    log.Name = 'FeedItem-More than 10 images on feeditem';
                    log.Jive_Id__c = fi;
                    log.Error_Description__c = 'cannot include more than 10 inline images on a single feed entity';
                    errorLogList.add(log);  
                }
                else{
                     // replaces image urls.
                    for(String s:cntDocIdMap.keyset()){
                        feedItemList.get(fi).body= feedItemList.get(fi).body.replace(imgToDownloadMap.get(s),'sfdc://'+cntDocIdMap.get(s)); 
                    } 
                                     
                }
                
                if(!fi2ImgTag2Replace.isEmpty() && fi2ImgTag2Replace.containsKey(fi)){
                    
                    feedItemList.get(fi).body = feedItemList.get(fi).body.replace(fi2ImgTag2Replace.get(fi),'') ;    
                                  
                }
                if(!topicName2Id.isEmpty() && !topicUrl2TopicName.isEmpty()){
                    for(String tpURL: topicUrl2TopicName.keyset()){
                        if(topicName2Id.containsKey(topicUrl2TopicName.get(tpURL)) != null){
                            
                            String topicURl =System.Label.Discussion_Community_Base_Url+ System.Label.Discussion_Community_Url +topicName2Id.get(topicUrl2TopicName.get(tpURL));
                            //System.debug('topicURl -------------'+topicURl );
                            //system.debug('topicUrl2TopicName.get(tpURL)-0--------------'+topicUrl2TopicName.get(tpURL));
                            //system.debug('topicUrl2TopicName--------------'+topicUrl2TopicName);
                            //System.debug('tpURL-------------'+tpURL);
                            feedItemList.get(fi).body = feedItemList.get(fi).body.replace(tpURL, topicURl );
                            //System.debug('fi.Description__c-------'+fi.Description__c);
                            
                        }
                    }
                }
                // Below code replaces the @mention user urls
                if(UserUrlMap != null && UserUrlMap.Keyset().size() >0 ) {
                    for(String s : UserUrlMap.keySet()){
                        feedItemList.get(fi).body=  feedItemList.get(fi).body.replace(s, UserUrlMap.get(s)); 
                    }
                }
                if(escapeHrefHTML != null && escapeHrefHTML.Keyset().size() >0 ) {
                    for(String s : escapeHrefHTML.keySet()){
                        feedItemList.get(fi).body=  feedItemList.get(fi).body.replace(s, escapeHrefHTML.get(s)); 
                    }
                }
            }
            if(!errorLogList.isEmpty()){
                insert errorLogList;      
            }
            
            return feedItemList.values(); 
        }    
        
        // Below method written to support the like functionality in the Discussions.
        
         
         public List<FeedLike> saveLike(Map<string , Sobject> feedLikeUrl2FI , Boolean isFeedComment ){
             
             List<FeedLike>finalFeedLikeList=new List<FeedLike>();
             Set<FeedLike>finalFeedLikeSet = new Set<FeedLike>();
             //Map<String,Id>mapOfJiveIdToUserId = getSFDCUserId();
             String jsonstr = '';
             Http http = new Http();
            
             HttpRequest req= new HttpRequest();
             req.setMethod('GET');
             if(!feedLikeUrl2FI.isEmpty()){
                 for(String feedLikeUrl:feedLikeUrl2FI.keySet()){
                
                      req.setEndpoint(feedLikeUrl);  
                      req.setHeader('Authorization', 'Basic Z2F1cmF2YjpTRkRDTWlncmF0aW9u');  
                      req.settimeout(120000);
                      HttpResponse res = new HttpResponse();
                      if(!Test.isRunningTest()){  
                         res = http.send(req);
                      }else{
                          res.setBody('{"itemsPerPage":25,"list":[{"id":"45031","resources":{"followingIn":{"allowed":["POST","GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/45031/followingIn"},'
                                        +'"images":{"allowed":["POST","GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/45031/images"},"activity":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/45031/activities"},'
                                        +'"social":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/45031/@social"},"roles":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/45031/roles"},'
                                        +'"streams":{"allowed":["POST","GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/45031/streams"},"recognition":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/45031/@recognition"},'
                                        +'"trendingContent":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/45031/@trendingContent"},"profilePrivacy":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/45031/profilePrivacy"},'
                                        +'"trendingPlaces":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/45031/@trendingPlaces"},"avatar":{"allowed":["GET","DELETE","PUT"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/45031/avatar?a=1002"},'
                                        +'"followers":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/45031/@followers"},"pages":{"allowed":["POST","GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/45031/pages"},"following":{"allowed":["GET"],'
                                        +'"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/45031/@following"},"members":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/members/people/45031"},"self":{"allowed":["GET","DELETE","PUT"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/45031"},'
                                        +'"html":{"allowed":["GET"],"ref":"https://discussions.qualys.com/people/gauravb"},"securityGroups":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/45031/securityGroups"},"extprops":{"allowed":["POST","GET","DELETE"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/45031/extprops"},'
                                        +'"tasks":{"allowed":["POST","GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/45031/tasks"}},"displayName":"Gaurav Bhalla","emails":[{"jive_label":"Email","primary":true,"type":"work","value":"gauravb@grazitti.com","jive_displayOrder":1,"jive_summaryDisplayOrder":0,"jive_showSummaryLabel":true}],'
                                        +'"jive":{"enabled":true,"level":{"description":"Level 2","imageURI":"https://rewards.imgix.net/prod_phx/11fbffd0-71ed-4b9b-95c0-4052c96abccd/level2?updated=b32d26ee-446a-40fe-bc33-1f763509a8d8","name":"Level 2","points":73},"externalContributor":false,"username":"gauravb","visible":true},"name":{"familyName":"Bhalla",'
                                        +'"formatted":"Gaurav Bhalla","givenName":"Gaurav"},"type":"person","typeCode":3},{"id":"28795","resources":{"followingIn":{"allowed":["POST","GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/28795/followingIn"},"images":{"allowed":["POST","GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/28795/images"},'
                                        +'"activity":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/28795/activities"},"social":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/28795/@social"},"roles":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/28795/roles"},"streams":{"allowed":'
                                        +'["POST","GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/28795/streams"},"recognition":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/28795/@recognition"},"trendingContent":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/28795/@trendingContent"},"profilePrivacy":'
                                        +'{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/28795/profilePrivacy"},"trendingPlaces":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/28795/@trendingPlaces"},"avatar":{"allowed":["GET","DELETE","PUT"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/28795/avatar?a=1001"},'
                                        +'"followers":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/28795/@followers"},"pages":{"allowed":["POST","GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/28795/pages"},"following":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/28795/@following"},"members":{"allowed":'
                                        +'["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/members/people/28795"},"self":{"allowed":["GET","DELETE","PUT"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/28795"},"html":{"allowed":["GET"],"ref":"https://discussions.qualys.com/people/donal.scollan"},"securityGroups":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/28795/securityGroups"},'
                                        +'"extprops":{"allowed":["POST","GET","DELETE"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/people/28795/extprops"}},"displayName":"Donal Scollan","emails":[{"jive_label":"Email","primary":true,"type":"work","value":"donal.scollan@fmr.com","jive_displayOrder":1,"jive_summaryDisplayOrder":0,"jive_showSummaryLabel":true}],"jive":{"enabled":true,"level":{"description":"Level 2",'
                                        +'"imageURI":"https://rewards.imgix.net/prod_phx/11fbffd0-71ed-4b9b-95c0-4052c96abccd/level2?updated=b32d26ee-446a-40fe-bc33-1f763509a8d8","name":"Level 2","points":246},"externalContributor":false,"username":"donal.scollan","visible":true},"name":{"familyName":"Scollan","formatted":"Donal Scollan","givenName":"Donal"},"type":"person","typeCode":3}],"startIndex":0}');
                      }
                      String temp = res.getBody().replace('\n','');
                      jsonstr = temp.replace('list','items');        
                      if(jsonstr != null && jsonstr != ''){
                           UserList wrapperinstance = UserList.parse(jsonstr);
                           
                           if(wrapperinstance.items != null && wrapperinstance.items.size() > 0){
                               
                               for(Integer j=0;j<wrapperinstance.items.size();j++){
                                   FeedLike fLike= new FeedLike();
                                    if(jiveIdToUserIdMap.containsKey(wrapperinstance.items.get(j).id) ){
                                        if(isFeedComment == true){
                                             fLike.FeedEntityId = feedLikeUrl2FI.get(feedLikeUrl).id;
                                        } 
                                        else if(isFeedComment == false){
                                            fLike.FeedItemId = feedLikeUrl2FI.get(feedLikeUrl).id;
                                        }
                                       
                                       if(jiveIdToUserIdMap.containsKey(wrapperinstance.items.get(j).id) ){
                                            fLike.createdbyid= jiveIdToUserIdMap.get(wrapperinstance.items.get(j).id);
                                       }
                                       // Set to store feedlike without any duplicate value
                                       finalFeedLikeSet.add(fLike);
                                   }
                                  
                               }  
                           } 
                      }                  
                } 
            }
            finalFeedLikeList.addAll(finalFeedLikeSet);
            return finalFeedLikeList;
        }

        public void setBestAnswer(Map<Id, FeedComment> FI2BestCommentMap){
             for(ID fiId : FI2BestCommentMap.keySet()){
                if(FI2BestCommentMap.get(fiId) != null){
                    ConnectApi.QuestionAndAnswersCapabilityInput qaInput = new ConnectApi.QuestionAndAnswersCapabilityInput();
                    qaInput.bestAnswerId = FI2BestCommentMap.get(fiId).id;
                    if(!Test.isRunningTest()){
                        ConnectApi.QuestionAndAnswersCapability qa = ConnectApi.QuestionAndAnswers.updateQuestionAndAnswers(NetworkScopeId, fiId , qaInput);
                    }
                }
            }
        }
        
        
        
         public Map<String,Id> getSFDCUserId(){
             Map<String,Id>jiveIdMapToUserId=new Map<String,Id>();
             for(User u: [Select id , jive_id__c , Profile.name, CommunityNickname,JiveUserName__c from user where jive_id__c !=null]){
                 jiveIdMapToUserId.put(u.jive_id__c,u.id);
                 nickNameToIdMap.put(u.JiveUserName__c , u.Id);
             }
             return jiveIdMapToUserId;
         }   
         
        public List<FeedAttachment> saveAttachmentsForFI(Map<String, FeedItem> attachmentUrl2FIMap){
            
            List<ContentVersion> cntVersionList = new List<ContentVersion>();
            Map<Id,List<ContentVersion>> mapCvId2FiId =new Map<Id,list<ContentVersion>>();
            
            String jsonstr = null;
            Http http = new Http();
            HttpRequest req= new HttpRequest();
            req.setMethod('GET');
            if(!attachmentUrl2FIMap.isEmpty()){
                for(String attachmentUrl : attachmentUrl2FIMap.keySet()){
                    string endpoint = '';
                    List<string> s = attachmentUrl.split('-#-');
                    List<string> url = s[1].split('/v3/');
                    if(url != null && url.size() > 0){
                        endpoint = communityUrlForAttachments +url[1];
                    }
                   
                    req.setEndpoint(endpoint);   
                    req.setHeader('Authorization', 'Basic Z2F1cmF2YjpTRkRDTWlncmF0aW9u'); 
                    req.settimeout(120000);
                    HttpResponse res = new HttpResponse();
                    
                    if(!Test.isRunningTest()){
                        res = http.send(req);
                    }else{
                        res.setBody('{"id":"11129","resources":{"self":{"allowed":["GET"],"ref":"https://jive-api-proxy.herokuapp.com/api/core/v3/attachments/11129"}},"contentType":"application/vnd.ms-word","name":"Quick way to test Authentication Record in Qualys.doc","size":214528,"url":"https://jive-api-proxy.herokuapp.com/api/core/v3/attachments/11129/data","status":"published","doUpload":false,"type":"attachment","typeCode":13}');
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
                   
                    String temp = EncodingUtil.base64Encode(b);
                    cv.VersionData = EncodingUtil.base64Decode(temp);
                    cntVersionList.add(cv);
                    if(mapCvId2FiId.containsKey(attachmentUrl2FIMap.get(attachmentUrl).id)){
                        List<ContentVersion> tmpList = mapCvId2FiId.get(attachmentUrl2FIMap.get(attachmentUrl).id);
                        tmpList.add(cv);
                        
                        mapCvId2FiId.put(attachmentUrl2FIMap.get(attachmentUrl).id, tmpList);  
                    }else{
                         mapCvId2FiId.put(attachmentUrl2FIMap.get(attachmentUrl).id,new List<contentVersion>{cv});  
                    }                       
                }
            }
            //insert cntVersionList;
            Map<string,string> cntDocIdMap=new Map<string,string>();
            if(!cntVersionList.isEmpty()){
                Insert cntVersionList;
                
               
                List<String> cntVersionIds=new List<String>();
                
                for(contentversion cv:cntVersionList){
                    cntVersionIds.add(cv.id);
                }   
                List<ContentVersion> cvListWithDocIds=
                    [select Id, ContentUrl, ContentDocumentId, Title FROM ContentVersion where id IN:cntVersionIds];
                for(contentversion cv:cvListWithDocIds){
                    cntDocIdMap.put(cv.Title,cv.ContentDocumentId);
                }  
             qUtil.ShareFilesWithLibraries(cntVersionIds, cntDocIdMap);   
            }
            
            List<FeedAttachment> feedAttachmentList = new List<FeedAttachment>();
            if(!mapCvId2FiId.isEmpty()){
                for(Id fId: mapCvId2FiId.keySet()){
                    for(contentVersion cv : mapCvId2FiId.get(fId)){
                        FeedAttachment fa = new FeedAttachment();
                        fa.FeedEntityId = fId;
                        fa.RecordId=cv.id;
                        fa.type ='CONTENT';
                        feedAttachmentList.add(fa);
                    }
                }
          
            }
            return feedAttachmentList;
        }
        //below method create file for attachment & assign contentversionid in custom object field i.e. RelatedRecordId__c 
        public List<CustomFeedComment__c> saveAttachmentsForFC(List<CustomFeedComment__c> feedCommentList){
            List<Error_Log__c> errorLogList = new List<Error_Log__c>();
            List<ContentVersion> cntVersionList = new List<ContentVersion>();
            Map<String, ContentVersion> mapJiveId2cv=new Map<String, ContentVersion>();
            
            String jsonstr = null;
            Http http = new Http();
            HttpRequest req= new HttpRequest();
            HttpResponse res = new HttpResponse();
            req.setMethod('GET');
            if(!feedCommentList.isEmpty()){
                for(CustomFeedComment__c fc : feedCommentList){
                    if(fc.attachment_url__c != null){
                        
                        string endpoint = '';
                        List<string> s = fc.attachment_url__c .split('-#-');
                        List<string> url = s[1].split('/v3/');
                        if(url != null && url.size() > 0){
                            endpoint = communityUrlForAttachments +url[1];
                        }
                        req.setEndpoint(endpoint);  
                        req.setHeader('Authorization', 'Basic Z2F1cmF2YjpTRkRDTWlncmF0aW9u'); 
                        req.settimeout(120000);
                        try{
                             res = http.send(req); 
                        }catch(System.CalloutException e) {
                            
                            Error_Log__c log = new Error_Log__c();
                            log.Type__c = 'Discussion';
                            log.Name = 'Callout error while hitting image URL- '+fc.FeedItem_JiveID__c;
                            log.Error_Description__c = e.getMessage();
                            errorLogList.add(log);  
                        }  
                        //HttpResponse res = http.send(req);
                        Blob b =  res.getBodyAsBlob();
                        if(b != null){
                            string tempVal = EncodingUtil.base64Encode(b);
                            if(string.isNotBlank(tempVal)){
                                ContentVersion cv=new ContentVersion();
                                cv.Title=s[0];
                                cv.PathOnClient ='/' + s[0];
                                cv.SharingOption = 'A';
                                cv.ContentLocation = 'S';
                                if(!Test.isRunningTest()){
                                    cv.NetworkId = NetworkScopeId;
                                }
                                String temp = EncodingUtil.base64Encode(b);
                                cv.VersionData = EncodingUtil.base64Decode(temp);
                                cntVersionList.add(cv);
                                mapJiveId2cv.put(fc.Jive_Id__c, cv); 
                            }
                        }
                        
                           
                        
                    }                     
                }
            }
            //insert cntVersionList;
            Map<string,string> cntDocIdMap=new Map<string,string>();
            if(!cntVersionList.isEmpty()){
                Insert cntVersionList;
                
               
                List<String> cntVersionIds=new List<String>();
                
                for(contentversion cv:cntVersionList){
                    cntVersionIds.add(cv.id);
                }   
                List<ContentVersion> cvListWithDocIds=
                    [select Id, ContentUrl, ContentDocumentId, Title FROM ContentVersion where id IN:cntVersionIds];
                for(contentversion cv:cvListWithDocIds){
                    cntDocIdMap.put(cv.Title,cv.ContentDocumentId);
                }  
                qUtil.ShareFilesWithLibraries(cntVersionIds, cntDocIdMap);
            }
            
            
            List<CustomFeedComment__c> customFeedCommentList = new List<CustomFeedComment__c>();
            
            for(CustomFeedComment__c c:feedCommentList){
                if(mapJiveId2cv.containsKey(c.Jive_Id__c)){
                    c.RelatedRecordId__c = mapJiveId2cv.get(c.Jive_Id__c).id;     
                }
                customFeedCommentList.add(c);
            
            }
            if(!errorLogList.isEmpty()){
                insert errorLogList;      
            }
            return customFeedCommentList;
        }
       
    }