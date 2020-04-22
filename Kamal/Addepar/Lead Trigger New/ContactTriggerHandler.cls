/**
 * @File Name          : ContactTriggerHandler.cls
 * @Description        : 
 * @Author             : Grazitti Interactive
 * @Group              : Grazitti Interactive
 * @Last Modified By   : Will Craig
 * @Last Modified On   : 4/21/2020, 10:41:25 PM
 * @Modification Log   : Refactor to non-static
**/

public class ContactTriggerHandler extends TriggerHandler {

    @TestVisible
    private List<Contact> triggerNew;

    @TestVisible
    private Map<Id, Contact> newContactMap;

    @TestVisible
    private List<Contact> triggerOld;

    @TestVisible
    private Map<Id, Contact> oldContactMap;
    
    @TestVisible
    private Set<Id> accountIdsForFirm ;
    
    @TestVisible
    private Set<Id> accountIdsForCSATRollUp ;
    
    @TestVisible
    private Set<Id> onlineDataRollups ; //Rollups collection for Edit Online Data Rollups
    
    @TestVisible
    private Set<Id> onlineTaxRollups ;  //Rollups collection for Tax Rollups
    
    @TestVisible
    private Set<Id> noLongerinFirmConIds ;
    
    @TestVisible
    private Set<Id> antiOnlineDataRollups ;
    
    @TestVisible
    private Set<Id> accIdSet ;
    
    @TestVisible
    private Set<Id> accountIdSet ;

    @TestVisible
    private core_NotificationService notifier ;
    
    public ContactTriggerHandler() {

        this.triggerNew = (List<Contact>) Trigger.new;
        this.oldContactMap = (Map<Id,Contact>) Trigger.oldMap;
        this.triggerOld = (List<Contact>) Trigger.old;
        this.newContactMap = (Map<Id,Contact>) Trigger.newMap;
        this.accountIdsForFirm = new Set<Id>();
        this.accountIdsForCSATRollUp = new Set<Id>();
        this.noLongerinFirmConIds = new Set<Id>();
        this.onlineDataRollups = new Set<Id>();
        this.onlineTaxRollups = new Set<Id>();
        this.antiOnlineDataRollups = new Set<Id>();           
        this.accountIdSet = new Set<Id>();
        this.notifier = new core_NotificationService();
        
    }
    
    public override void beforeUpdate(){
    
        this.UpdateDemoFlag();
        
        // Publish error logs cached in the notifier.
        this.notifier.flush();
        
    }
    
    public override void afterInsert(){
     
        this.buildAcctIdSet(this.triggerNew);
        
        this.collectionGeneratorAfterInsert();
        
        // call this method to update Firm Admin(contact lookup) On Account update Firm Admin(contact lookup) On Account 
        this.performAccoutUpdateOperations();
        
        this.contactAccountUpdate();

        // Publish error logs cached in the notifier.
        this.notifier.flush();

    }
    
    public override void afterUpdate(){

        this.buildAcctIdSet(this.triggerNew);
        
        this.collectionGeneratorAfterUpdate();
        
        this.deRollupMethod();

        // call this method to update Firm Admin(contact lookup) On Account
        this.performAccoutUpdateOperations();    
        
        this.contactAccountUpdate();
        
        // Publish error logs cached in the notifier.
        this.notifier.flush();

    } 
    
     public override void afterDelete(){
        
        this.buildAcctIdSet(this.oldContactMap.values());
        
        this.collectionGeneratorAfterDelete();
        
        this.deRollupMethod();
        
        this.contactAccountUpdate();
        
        // Publish error logs cached in the notifier.
        this.notifier.flush();  
        
    }

    @TestVisible
    private void buildAcctIdSet(List<Contact> records){

        for (Contact c: records ){ 
            this.accountIdSet.add(c.AccountId);    
        }
        this.accountIdSet.remove(null);
        

    }

    @TestVisible
    private void UpdateDemoFlag(){

        for (Contact c: this.triggerNew){  
        
            Contact old = this.oldContactMap.get(c.Id);
            // identify the demo activities if they are created from trigger or not & prefill fields
            if(old.Demo_Scheduled__c && !c.Demo_Scheduled__c) c.IsDemoScheduledUpdateByTrigger__c = false;
            if(old.Demo_Completed__c && !c.Demo_Completed__c) c.IsDemoCompletedUpdateByTrigger__c = false;
            
        }

    }
    
    
     @TestVisible
     private void performAccoutUpdateOperations(){
            
        // Return if all collections are empty.
        if(        this.accountIdsForFirm.isEmpty() 
                && this.accountIdsForCSATRollUp.isEmpty() 
                && this.noLongerinFirmConIds.isEmpty() 
                && this.onlineDataRollups.isEmpty() 
                && this.onlineTaxRollups.isEmpty()){
            return;
        }

        Map<Id, Account> accountsToUpdateMap = new Map<Id, Account>();
        // being used to populate firm Admin (contact Lookup field)
        
        // Will Craig NOTE: Move this block, building accountsToQuery, to a method.
        Set<Id> accountsToQuery = new Set<Id>();
        accountsToQuery.addAll(this.accountIdsForFirm);
        accountsToQuery.addAll(this.noLongerinFirmConIds);
        //Added by grazitti - Adding the Accounts to Query for two more rollups - Edit Online Data and Edit Online Tax lots
        accountsToQuery.addAll(this.onlineDataRollups);
        accountsToQuery.addAll(this.onlineTaxRollups);
        list<Training_Participant__c > listTrin=[select id from Training_Participant__c  limit 1];
        
        System.debug('Query'+listTrin);
        if(!accountsToQuery.isEmpty()){                
            // Will Craig NOTE: SOQL in a method.
            for(Account each : [SELECT Id,Account_Edit_Online_Data__c,Account_Edit_Online_Tax_Lots__c,Date_First_Trained__c,
                                                TrainedEmployee__c,Firm_Admin__c,(SELECT Id,Date_of_Training__c FROM Training_Participants__r 
                                                        WHERE Training_Status__c = 'Attended' AND Contact__r.No_Longer_with_Firm__c = false 
                                                        ORDER BY Date_of_Training__c ASC LIMIT 1),
                                                        (SELECT Id, Firm_Admin__c FROM Contacts WHERE Firm_Admin__c = true ORDER BY 
                                                        CreatedDate DESC LIMIT 1) FROM Account WHERE Id IN: accountsToQuery]){
                System.debug('each&&&&&&&&&'+each);
                
                // Will Craig NOTE: Replace isAnyFieldUpdated with a Map<String,boolean>() above the for loop.
                Boolean isAnyFieldUpdated = false;

                // Will Craig NOTE: As far as I can tell, this is the only summary we shouldn't replace with DLRS, as it is populating
                // a lookup with the first contact trained contact that is still with the firm, which is a process.
                if(this.accountIdsForFirm.contains(each.Id) && !each.Contacts.isEmpty() && each.Firm_Admin__c != each.Contacts[0].Id){
                    each.Firm_Admin__c = each.Contacts[0].Id;
                    isAnyFieldUpdated = true;
                }

                // Will Craig NOTE: This if block should be a method.
                // ##DLRS
                if(this.noLongerinFirmConIds!= null && this.noLongerinFirmConIds.contains(each.Id)){
                    if(!each.Training_Participants__r.isEmpty()){
                        if(each.Date_First_Trained__c != each.Training_Participants__r[0].Date_of_Training__c){
                            each.Date_First_Trained__c = each.Training_Participants__r[0].Date_of_Training__c;
                            isAnyFieldUpdated = true;
                        }
                        if(!each.TrainedEmployee__c){
                            each.TrainedEmployee__c = true;
                            isAnyFieldUpdated = true;
                        }
                    }else if(each.Training_Participants__r.isEmpty()){
                        if(each.Date_First_Trained__c != null){
                            each.Date_First_Trained__c = null;
                            isAnyFieldUpdated = true;
                        }
                        if(each.TrainedEmployee__c){
                            each.TrainedEmployee__c = false;
                            isAnyFieldUpdated = true;
                        }
                    }                        
                }
                // Will Craig NOTE: This if block should be a method.
                //Added by Grazitti - Start - Setting Edit fields to true
                // ##DLRS
                if(!this.onlineDataRollups.isEmpty() && this.onlineDataRollups.contains(each.Id)
                                && each.Account_Edit_Online_Data__c != true){
                                System.debug('In if');
                    each.Account_Edit_Online_Data__c = true;
                    isAnyFieldUpdated = true;
                }
                // Will Craig NOTE: This if block should be a method.
                // ##DLRS
                if(!this.onlineTaxRollups.isEmpty() && this.onlineTaxRollups.contains(each.Id)
                                && each.Account_Edit_Online_Tax_Lots__c != true){
                    each.Account_Edit_Online_Tax_Lots__c = true;
                    isAnyFieldUpdated = true;
                }
                //Added by Grazitti - End
                if(isAnyFieldUpdated) accountsToUpdateMap.put(each.Id, each);
            }
        }
        
        // Will Craig NOTE: This if block should be a method
        // being used to populate Average_Support_CSAT__c field on Account
        // ##DLRS
        if(!this.accountIdsForCSATRollUp.isEmpty()){
            
            for(AggregateResult a : [SELECT AVG(Average_Support_CSAT__c) asExp, AccountId accId FROM Contact WHERE AccountId IN: accountIdsForCSATRollUp GROUP BY AccountId]){
                Account acc = new Account(Id=(Id)a.get('accId'));
                if(accountsToUpdateMap.containsKey(acc.Id)) acc = accountsToUpdateMap.get(acc.Id);
                acc.Average_Support_CSAT__c=(Decimal)a.get('asExp');
                accountsToUpdateMap.put(acc.Id, acc);
                System.debug('AggregateResult '+acc.Average_Support_CSAT__c);
            }
        }
        System.debug('accountsToUpdateMap'+accountsToUpdateMap);
        this.UpdateRecords(accountsToUpdateMap.values());
        System.debug('accountsToUpdateMap3333'+accountsToUpdateMap);
    } 
     
     @TestVisible
     private void deRollupMethod(){
        
        if(this.antiOnlineDataRollups.isEmpty()){return;}
        
        // ##DLRS
        Map<Id, Contact> deRollDataAccounts = new Map<Id, Contact>();
        Map<Id, Contact> deRollTaxAccounts = new Map<Id, Contact>();
        List<Account> accToUpdate = new List<Account>();
        List<Contact>listc=[Select id, AccountId,Edit_Online_Tax_Lots__c, Edit_Online_Data__c from Contact WHERE AccountId in: this.antiOnlineDataRollups];
        System.debug('listc'+listc);
        //Checking if Accounts contains atleast one true rollup field
        for(Contact c : [Select id, AccountId,Edit_Online_Tax_Lots__c, Edit_Online_Data__c from Contact WHERE AccountId in: this.antiOnlineDataRollups]){
            if(c.Edit_Online_Data__c){
                deRollDataAccounts.put(c.AccountId, c);
            }
            if(c.Edit_Online_Tax_Lots__c){
                deRollTaxAccounts.put(c.AccountId, c);
            }
        }
        
        //unchecking the Fields on Account in case no true rollups found
        for(Id accId : this.antiOnlineDataRollups){
            Account actoUpdate = new Account(Id = accId);
            Boolean isUpdated = false;
            if((deRollDataAccounts != NULL && !deRollDataAccounts.containsKey(accId)) || (deRollDataAccounts == NULL)){
                actoUpdate.Account_Edit_Online_Data__c = false;
                isUpdated = true;
            }
            if((deRollTaxAccounts != null && !deRollTaxAccounts.containsKey(accId)) || (deRollTaxAccounts == NULL)){
                actoUpdate.Account_Edit_Online_Tax_Lots__c = false;
                isUpdated = true;
            }
            if(isUpdated) accToUpdate.add(actoUpdate);
        }

        this.UpdateRecords(accToUpdate);
        
    }  
    
    @TestVisible
    private void  contactAccountUpdate(){
        
        if(this.accIdSet.isEmpty()){return;}
        
        // ##DLRS
        List<account> accountToUpdate = new List<account>();  
        Set<Id> accIdtoTrue = new Set<Id>();
        for(contact con : [select name,AccountId from contact where AccountId =: this.accIdSet AND No_Longer_with_Firm__c = false]){
            accIdtoTrue.add(con.AccountId);
        }
        for(Account accDetails : [SELECT id, name, HasActiveContacts__c FROM Account WHERE Id =: this.accIdSet ]){
            if(accIdtoTrue.size() > 0 && accIdtoTrue.contains(accDetails.id) ){
                if(accDetails.HasActiveContacts__c == false){
                    accDetails.HasActiveContacts__c = true;
                    accountToUpdate.add(accDetails);
                }
            }else if(accDetails.HasActiveContacts__c == true){ 
                accDetails.HasActiveContacts__c = false;
                accountToUpdate.add(accDetails);
            }
        }
        
        // Pass updates into update method.
        this.UpdateRecords(accountToUpdate);

    }
    
    @TestVisible
    private void collectionGeneratorAfterInsert(){
        
        // Only process if accountIdSet is not empty.
        if(this.accountIdSet.isEmpty()){return;}
        
        for (Contact c: this.triggerNew){
        
            if(c.AccountId != null && accountIdSet.contains(c.AccountId)){
            
                // Detect changes in fields key to Roll-ups on account.
                if(c.Firm_Admin__c)                   { this.accountIdsForFirm.add(c.AccountId); }
                if(c.Average_Support_CSAT__c != null) { this.accountIdsForCSATRollUp.add(c.AccountId); }
                if(c.Edit_Online_Data__c)             { this.onlineDataRollups.add(c.AccountId); }
                if(c.Edit_Online_Tax_Lots__c)         { this.onlineTaxRollups.add(c.AccountId); }
            
            } 
            
            // Only process contacts marked as being present at forms.
            if(c.No_Longer_with_Firm__c == false){
                this.accIdSet.add(c.AccountId);
            }
        }
        
    }

    @TestVisible
    private void collectionGeneratorAfterUpdate(){
    
        // Only process if accountIdSet is not empty.
        if(this.accountIdSet.isEmpty()){return;}
        
        for (Contact c: this.triggerNew ){
            
            Contact old = this.oldContactMap.get(c.Id);
            
            // Detect changes to Contact fields that are relevant to account roll-ups.
            if(accountIdSet.contains(c.AccountId)){
                if(old.Firm_Admin__c != c.Firm_Admin__c)                      { this.accountIdsForFirm.add(c.AccountId); }
                if(old.Average_Support_CSAT__c != c.Average_Support_CSAT__c)  { this.accountIdsForCSATRollUp.add(c.AccountId); }
                if(!old.No_Longer_with_Firm__c && c.No_Longer_with_Firm__c)   { this.noLongerinFirmConIds.add(c.AccountId); }
                if(!old.Edit_Online_Data__c && c.Edit_Online_Data__c)         { this.onlineDataRollups.add(c.AccountId); }
                if(old.Edit_Online_Data__c && !c.Edit_Online_Data__c)         { this.antiOnlineDataRollups.add(c.AccountId); }
                if(!old.Edit_Online_Tax_Lots__c && c.Edit_Online_Tax_Lots__c) { this.onlineTaxRollups.add(c.AccountId); }
                if(old.Edit_Online_Tax_Lots__c && !c.Edit_Online_Tax_Lots__c) { this.antiOnlineDataRollups.add(c.AccountId); }
            }
            
            // Detect changes to No longer with firm and accountid
            if((this.oldContactMap.get(c.id).No_Longer_with_Firm__c != c.No_Longer_with_Firm__c) || (this.oldContactMap.get(c.id).AccountId != c.AccountId)){
                    this.accIdSet.add(c.AccountId);
                    this.accIdSet.add(this.oldContactMap.get(c.id).AccountId);
            }
        }       
    } 
    
    
    @TestVisible
    private void collectionGeneratorAfterDelete(){
        
        // Only process if accountIdSet is not empty.
        if(this.accountIdSet.isEmpty()){return;}
        
        for(Contact c :  this.oldContactMap.values()){
            if(String.isNotBlank(c.AccountId)&& accountIdSet.contains(c.AccountId) && (c.Edit_Online_Data__c || c.Edit_Online_Tax_Lots__c)){
                this.antiOnlineDataRollups.add(c.AccountId);
            }
            if(c.No_Longer_with_Firm__c == false){
                this.accIdSet.add(c.AccountId);
            }
        }     
    }

    @TestVisible
    private void UpdateRecords(List<SObject> records){

        if(records.isEmpty()){return;}
        
        List<Database.SaveResult> srs = Database.update(records,false);
        System.debug(srs);
        for(Database.SaveResult sr : srs ){
            if(!sr.isSuccess()){
                this.notifier.queue('OpportunityTriggerHandler.InsertRecords', 
                core_NotificationItem.CategoryType.CORE, 
                core_NotificationItem.SeverityType.CRITICAL, 
                JSON.serialize(sr.getErrors()), 
                JSON.serialize(sr.errors));
            }
        }
    }

    public void instantiate() {

        if(this.triggerNew == null){this.triggerNew = new List<Contact>();}
        if(this.newContactMap == null){this.oldContactMap = new Map<Id,Contact>();}
        if(this.triggerOld == null){this.triggerNew = new List<Contact>();}
        if(this.oldContactMap == null){this.oldContactMap = new Map<Id,Contact>();}
        if(this.accIdSet == null){this.accIdSet = new Set<Id>();}
        if(this.accountIdsForFirm == null){this.accountIdsForFirm = new Set<Id>();}
        if(this.accountIdsForCSATRollUp == null){this.accountIdsForCSATRollUp = new Set<Id>();}
        if(this.noLongerinFirmConIds == null){this.noLongerinFirmConIds = new Set<Id>();}
        if(this.onlineDataRollups == null){this.onlineDataRollups = new Set<Id>();}
        if(this.onlineTaxRollups == null){this.onlineTaxRollups = new Set<Id>();}
        if(this.antiOnlineDataRollups == null){this.antiOnlineDataRollups = new Set<Id>();}
        if(this.accountIdSet == null){this.accountIdSet = new Set<Id>();}

    }
    
}