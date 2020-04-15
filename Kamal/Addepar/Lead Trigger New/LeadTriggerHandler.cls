/**
 * @File Name          : LeadTriggerHandler.cls
 * @Description        : 
 * @Author             : Will Craig
 * @Group              : 
 * @Last Modified By   : Will Craig
 * @Last Modified On   : 4/13/2020, 10:00:15 AM
 * @Modification Log   : Complete re-build.
**/

public class LeadTriggerHandler extends TriggerHandler {
    
    @TestVisible
    private Map<Id, Lead> newLeadMap;
    @TestVisible
    private Map<Id, Lead> oldLeadMap;
    @TestVisible
    private List<Lead> triggerOld;
    @TestVisible
    private List<Lead> triggerNew;
    @TestVisible
    private Set<Id> accIdSet;
    @TestVisible
    private Set<String> leadCountries;
    @TestVisible
    private core_NotificationService notifier;

    public LeadTriggerHandler() {
        
        this.newLeadMap = (Map<Id,Lead>) Trigger.newMap;
        this.oldLeadMap = (Map<Id,Lead>) Trigger.oldMap;
        this.triggerOld = (List<Lead>) Trigger.old;
        this.triggerNew = (List<Lead>) Trigger.new;
        this.accIdSet = new Set<Id>();
        this.leadCountries = new Set<String>();
        this.OpIdToDateChange = new Map<Id,DateTime>();
        this.notifier = new core_NotificationService();

    }

    public void instantiate() {

        if(this.newLeadMap == null){this.newLeadMap = new Map<Id,Lead>();}
        if(this.oldLeadMap == null){this.oldLeadMap = new Map<Id,Lead>();}
        if(this.triggerOld == null){this.triggerOld = new List<Lead>();}
        if(this.triggerNew == null){this.triggerNew = new List<Lead>();}
        if(this.accIdSet == null){this.accIdSet = new Set<Id>();}
        if(this.leadCountries == null){this.leadCountries = new Set<String>();}
        if(this.OpIdToDateChange == null){this.OpIdToDateChange = new Map<Id,DateTime>();}
        if(this.OppListToUpdate == null){this.OppListToUpdate = new List<Opportunity>();}
        if(this.notifier == null){this.notifier = new core_NotificationService();}
        if(this.mapCountryToRM == null){this.mapCountryToRM = new Map<String, List<Region_Mapping__c>>();}
        if(this.mapRecord2RM == null){this.mapRecord2RM = new Map<Id, Region_Mapping__c>();}
        if(this.rMaps == null){this.rMaps = new List<Region_Mapping__c>();}

    }
    
    public override void beforeInsert(){

        LeadAccountBinding lab = new LeadAccountBinding( triggerNew );
        lab.setLeads();

        for(lead newLead : this.triggerNew){
        
            if(!newLead.Exclude_from_Region_Mapping__c){
                if( String.isNotBlank(newLead.CountryCode) ){
                    this.leadCountries.add(newLead.CountryCode.toLowerCase());
                }
            }
        }

        this.regionMappingHandler();
        this.notifier.flush();
        
    }

    public override void beforeUpdate(){

         // Logic in the the LeadAccountBinding Apex Class
         LeadAccountBinding lab = new LeadAccountBinding( this.oldLeadMap, this.newLeadMap );
         lab.setLeads();

         for(lead newLead : this.triggerNew){
            if(newLead.IsConverted && this.oldLeadMap.get(newLead.id).IsConverted == false && String.isNotBlank(newLead.ConvertedOpportunityId)){ 
                OpIdToDateChange.put(newLead.ConvertedOpportunityId, newLead.Lead_Score_Update_Date__c );
            }
            
            // New code added for Region mapping on May 2018 by Grazitti
            if(!newLead.Exclude_from_Region_Mapping__c){
                if(String.isNotBlank(newLead.CountryCode) 
                    && (
                        this.oldLeadMap.get(newLead.Id).CountryCode != newLead.CountryCode ||this.oldLeadMap.get(newLead.Id).StateCode != newLead.StateCode ||this.oldLeadMap.get(newLead.Id).City != newLead.City)
                    ){
                    this.leadCountries.add(newLead.CountryCode.toLowerCase());
                }
            }
        }

        this.regionMappingHandler();
        this.updateLeadSource();
        this.notifier.flush();
        
    }

    public override void afterInsert(){

        for(Lead ld : this.triggerNew){
            if(ld.Account__c != null){
                this.accIdSet.add(ld.Account__c);
            }
        }
        
        this.leadAccountUpdate();
        this.notifier.flush();

    }

    public override void afterUpdate(){

        for(Lead ld : this.triggerNew){
            if(ld.Account__c != this.oldLeadMap.get(ld.id).Account__c){
                if(ld.Account__c != null){
                    this.accIdSet.add(ld.Account__c);
                }
                /*If old map Account field is not blank*/
                if(this.oldLeadMap.get(ld.id).Account__c != null ){
                    this.accIdSet.add(this.oldLeadMap.get(ld.id).Account__c);
                }
            } 
        }
        
        this.leadAccountUpdate();
        this.notifier.flush();

    }

    public override void afterDelete(){

        for(Lead ld : this.triggerOld){
            if(ld.Account__c != null){
                this.accIdSet.add(ld.Account__c);
            }
        }
        this.leadAccountUpdate();
        this.notifier.flush();

    }
    
    @TestVisible
    private Map<id,DateTime> OpIdToDateChange;
    @TestVisible
    private List<Opportunity> OppListToUpdate;
    
    @TestVisible
    private void updateLeadSource() {
        
        // Return if empty.
        if(this.OpIdToDateChange.isEmpty()){return;}
        
        this.buildOppUpdates();
        this.updateOpps();
        
    }

    @TestVisible
    private void buildOppUpdates(){

        this.OppListToUpdate = new List<Opportunity>();
        for(Id opId : this.OpIdToDateChange.keySet()){
            if(this.OpIdToDateChange.get(opId) > Datetime.now() - Integer.ValueOf(Label.lead_score_update_time)){
                this.OppListToUpdate.add(new Opportunity(Id = opId, Opportunity_Source__c = 'Marketing'));
            }else {
                this.OppListToUpdate.add(new Opportunity(Id = opId, Opportunity_Source__c = 'Business Development'));
            }
        }
    }

    @TestVisible
    private void updateOpps(){

        if(this.OppListToUpdate.isEmpty()){return;}
        
        List<Database.SaveResult> srs = Database.update(this.OppListToUpdate);
        for(Database.SaveResult sr : srs ){
            if(!sr.isSuccess()){
                this.notifier.queue('LeadTriggerHandler.updateOpps', 
                core_NotificationItem.CategoryType.CORE, 
                core_NotificationItem.SeverityType.CRITICAL, 
                JSON.serialize(sr.getErrors()), 
                JSON.serialize(sr.errors));
            }
        }
    }
    
    @TestVisible
    private Map<String, List<Region_Mapping__c>> mapCountryToRM;
    @TestVisible
    private List<Region_Mapping__c> rMaps;
    @TestVisible
    private Map<Id, Region_Mapping__c> mapRecord2RM;

    
    @TestVisible
    private void regionMappingHandler() {

        this.getRegionRecords();
        this.buildRecordMap();
        this.updateRecordRegion();
        
    }
    @TestVisible
    private void getRegionRecords(){

        // Return if empty.
        if(this.leadCountries.isEmpty()){return;}
        
        this.mapCountryToRM = new Map<String, List<Region_Mapping__c>>();
        this.rMaps = [SELECT Id, Country__c , State__c , State_Code__c , City__c , Region__c, Sub__c FROM Region_Mapping__c 
                                         where Country__c IN : this.leadCountries];  
        
        for(Region_Mapping__c rm : this.rMaps){
            List<Region_Mapping__c> temp = new List<Region_Mapping__c>();
            if(this.mapCountryToRM.containsKey(rm.Country__c)){temp = this.mapCountryToRM.get(rm.Country__c);}
            temp.add(rm);
            this.mapCountryToRM.put(rm.Country__c , temp);
        }
    }

    @TestVisible
    private void buildRecordMap(){

        this.mapRecord2RM = new Map<Id, Region_Mapping__c>();         
        for(Lead a : this.triggerNew){
            Boolean stateMatched = false;
            Boolean cityMatched = false;
            if(a.CountryCode != null && this.mapCountryToRM != null && this.mapCountryToRM.containsKey(a.CountryCode)){
                for(Region_Mapping__c rm : this.mapCountryToRM.get(a.CountryCode)){
                    
                    Boolean isStateMatched = false;
                    Boolean isStateBlank = false;
                    Boolean iscityMatched = false;
                    Boolean isCityBlank = false;
                    System.debug(rm);
                    if(rm.state__c != null && rm.State_Code__c != null &&  a.statecode != null && a.statecode == rm.State_Code__c){                       
                        isStateMatched = true;
                    }
                    if(rm.state__c == null){
                        isStateBlank = true;
                    }
                    
                    if(rm.City__c!= null &&  a.city != null && a.city == rm.City__c){                       
                        iscityMatched = true;
                    }
                    if(rm.City__c== null){
                        isCityBlank = true;
                    }
                    
                    if(isStateMatched && iscityMatched){
                        this.mapRecord2RM.put(a.id , rm);
                        break;
                    }
                    else if(isStateMatched && isCityBlank){
                        this.mapRecord2RM.put(a.id , rm);
                        stateMatched = true;
                    }
                    else if(iscityMatched && isStateBlank && !stateMatched){
                        this.mapRecord2RM.put(a.id , rm);
                        cityMatched = true;
                    }
                    else if (isCityBlank && isStateBlank && !stateMatched && !cityMatched){
                        this.mapRecord2RM.put(a.id , rm);
                    }
                }
            }
        }
    }

    @TestVisible
    private void updateRecordRegion(){

        if(this.mapRecord2RM.keySet().size() > 0 ){
            for(Lead a : this.triggerNew){
                if(this.mapRecord2RM.containsKey(a.id)){
                    a.Region__c = this.mapRecord2RM.get(a.id).Region__c;
                    a.Sub_Region__c = this.mapRecord2RM.get(a.id).Sub__c;
                }
            }
        }
    }
/*
* @author Grazitti Interactive
* @date Nov 2019
* @description Update Account.HasLeads Field on the basis of Account field on Lead
* @param Set of AccountId 
*/
    @TestVisible
    private void  leadAccountUpdate(){
        
        // If no accounts to update, return.
        if(this.accIdSet.isEmpty()){return;}

        List<account> accountToUpdate = new List<account>();  
        Set<Id> accIdtoTrue = new Set<Id>();
        for(Lead ld : [select name,Account__c from lead where Account__c =: this.accIdSet]){
            accIdtoTrue.add(ld.Account__c);
        }
        for(Account acc : [SELECT id, name, HasLeads__c FROM Account WHERE Id =: this.accIdSet ]){
            if( accIdtoTrue.contains(acc.id) ){
                if(acc.HasLeads__c == false){
                    acc.HasLeads__c = true;
                    accountToUpdate.add(acc);
                }
            }else if(acc.HasLeads__c == true){ 
                acc.HasLeads__c = false;
                accountToUpdate.add(acc);
            }
        }
        if(accountToUpdate.size() > 0){
            update accountToUpdate;
        }
    } 
}