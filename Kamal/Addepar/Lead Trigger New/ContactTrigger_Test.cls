/**
* @author Grazitti Interactive
* @date Nov 2019
* @description Test class for ContactTrigger
*/
@isTest
public class ContactTrigger_Test{
    @TestSetup 
    static void setupEnvironment () {

        //Configure Trigger settings.
        Map<String,Boolean> settingMap = new Map<String,Boolean>();
        settingMap.put('Account',false);
        settingMap.put('Contact',false);
        settingMap.put('Training_Participant__c',false);
      
        TestUtility.createTriggerSwitchesfromMap(settingMap);
        System.debug('Trigger settings set.');
        
        // Configure PB Settings
        Process_Builder_Switch__c pbswitch = new Process_Builder_Switch__c();
        
        pbswitch.Account_Process__c=false;
        pbswitch.Contact_Process__c=false;
       
        Insert pbswitch;

        // Insert Validation Setting
        try{
            insert new Validation_Global_Switch__c(Enable_Validation__c=false);
        } catch (Exception e) {
            System.debug('Custom Setting already applied');
        }
        
    }
    @IsTest
    private static void afterInsert_TEST() {
        
        // Prep 
        ContactTriggerHandler handler = new ContactTriggerHandler();
        Map<Integer,Account> accounts = TestUtility.createAccounts(1, true);
        Map<Integer,Contact> triggerNew = TestUtility.createContacts(1, null, true);
        
        handler.instantiate();
        handler.triggerNew = triggerNew.values();
        
        // Execute
        handler.afterInsert(); 
        
        //Assert
        System.assert(handler.triggerNew.size() > 0,'List of Contacts is not populated.');  
        System.assert(!handler.accountIdSet.contains(accounts.get(1).Id),'Account ID not in accountIdSet');    

    }
    @IsTest
    private static void afterUpdate_TEST() {

        // Prep 
        
        ContactTriggerHandler handler = new ContactTriggerHandler();
        Map<Integer,Account> accounts = TestUtility.createAccounts(1, true);
        Map<Integer,Contact> triggerNew = TestUtility.createContacts(1, null, true);
        handler.instantiate();
        handler.triggerNew = triggerNew.values();
        
         // Execute
        handler.afterUpdate(); 
        
        //Assert
        System.assert(handler.triggerNew.size() > 0,'List of Contacts is not populated.');  
        System.assert(!handler.accountIdSet.contains(accounts.get(1).Id),'Account ID not in accountIdSet');  

    }
    @IsTest
    private static void afterDelete_TEST() {

        // Prep 
        
        ContactTriggerHandler handler = new ContactTriggerHandler();
        Map<Integer,Account> accounts = TestUtility.createAccounts(1, true);
        Map<Integer,Contact> triggerOld = TestUtility.createContacts(1,null, true);
        
        handler.instantiate();
        for(Contact c: triggerOld.values()){
            handler.oldContactMap.put(c.Id,c);    
        }
         // Execute
        handler.afterDelete(); 
        
        //Assert
        System.assert(handler.oldContactMap.size() > 0,'List of Contacts is not populated.');  
        System.assert(!handler.accountIdSet.contains(accounts.get(1).Id),'Account ID not in accountIdSet');  

    }

    @IsTest
    private static void beforeUpdate_TEST() {

         // Prep 
        ContactTriggerHandler handler = new ContactTriggerHandler ();
        Map<Integer,Account> accounts = TestUtility.createAccounts(1, true);
        Map<Integer,Contact> triggerOld = TestUtility.createContacts(1,accounts.get(1).Id, true);
        Map<Integer,Contact> triggerNew = new Map<Integer,Contact>();
         
        //// Populate handler
        handler.instantiate();
        
        for(Contact c: triggerOld.values()){
        
            c.Demo_Scheduled__c = true;
            c.Demo_Completed__c = true;
            handler.oldContactMap.put(c.Id,c);
        }
        
        //Clone old into new.
        for(Integer i : triggerOld.keySet()){
            triggerNew.put(i,triggerOld.get(i).clone(true,true,true,true));
        }
        

        for(Contact c : triggerNew.values()){
            c.Demo_Scheduled__c = false;
            c.Demo_Completed__c = false;
            handler.triggerNew = triggerNew.values();
        }
         // Execute
        handler.beforeUpdate(); 
        List<Contact> conList=[Select id,IsDemoScheduledUpdateByTrigger__c ,IsDemoCompletedUpdateByTrigger__c from Contact where id =: triggerNew.get(1).id ];
        System.assert(!conList[0].IsDemoCompletedUpdateByTrigger__c,'Demo Completed is true');  
        System.assert(!conList[0].IsDemoScheduledUpdateByTrigger__c,'Demo Scheduled is true');

    }
    
    @IsTest
    private static void collectionGeneratorAfterDelete_TEST() {

         // Prep 
        ContactTriggerHandler handler = new ContactTriggerHandler ();
        Map<Integer,Account> accounts = TestUtility.createAccounts(1, true);
        Map<Integer,Contact> triggerOld = TestUtility.createContacts(1,accounts.get(1).Id, true);
        Map<Integer,Contact> triggerNew = new Map<Integer,Contact>();
         
        //// Populate handler
        handler.instantiate();
        for(Contact c: triggerOld.values()){
        
            c.Edit_Online_Data__c = true;
            c.Edit_Online_Tax_Lots__c = true;
            handler.oldContactMap.put(c.Id,c);
            
        }
        handler.accountIdSet.add(accounts.get(1).Id);
        
         // Execute
        handler.collectionGeneratorAfterDelete(); 
        
         // Assert
        System.assert(handler.antiOnlineDataRollups.contains(accounts.get(1).Id),'Account ID not in accountIdSet');
        System.assert(handler.accIdSet.contains(accounts.get(1).Id),'Account ID not in accountIdSet');  

    }
    
    @IsTest
    private static void collectionGeneratorAfterInsert_Test(){
        ContactTriggerHandler handler = new ContactTriggerHandler();
        Map<Integer,Account> accounts = TestUtility.createAccounts(1, true);
        Map<Integer,Contact> triggerNew = TestUtility.createContacts(1, accounts.get(1).Id, true);

        for(Contact c : triggerNew.values()){
           
            c.Demo_Scheduled__c = true;
            c.Demo_Completed__c = true;
            c.Firm_Admin__c = true;
            c.No_Longer_with_Firm__c = false;
            c.Average_Support_CSAT__c = 4;
            c.Edit_Online_Data__c = true;
            c.Edit_Online_Tax_Lots__c = true;    
        }
        handler.instantiate();
        handler.triggerNew = triggerNew.values();
        handler.accountIdSet.add(accounts.get(1).Id);
        handler.collectionGeneratorAfterInsert();
        
        //Assert
        System.assert(handler.triggerNew.size() > 0,'List of Contacts is not populated.');  
        System.assert(handler.accountIdSet.contains(accounts.get(1).Id),'Account ID not in accountIdSet');
        System.assert(handler.accountIdsForFirm.contains(accounts.get(1).Id),'Account ID not in accountIdsForFirm'); 
        System.assert(handler.accIdSet.contains(accounts.get(1).Id),'Account ID not in accountIdSet');  
 
    }
    
    @IsTest
    private static void collectionGeneratorAfterUpdate_Test(){
    
        // Prep 
        ContactTriggerHandler handler = new ContactTriggerHandler ();
        Map<Integer,Account> accounts = TestUtility.createAccounts(1, true);
        Map<Integer,Contact> triggerOld = TestUtility.createContacts(1,accounts.get(1).Id, true);
        Map<Integer,Contact> triggerNew = new Map<Integer,Contact>();
         
        //// Populate handler
        handler.instantiate();
        
        for(Contact c: triggerOld.values()){
            c.Firm_Admin__c = true;
            c.No_Longer_with_Firm__c = false;
            c.Average_Support_CSAT__c = 4;
            c.Edit_Online_Data__c = true;
            c.Edit_Online_Tax_Lots__c = true;
            handler.oldContactMap.put(c.Id,c);
        }
        
        //Clone old into new.
        for(Integer i : triggerOld.keySet()){
            triggerNew.put(i,triggerOld.get(i).clone(true,true,true,true));
        }
        

        for(Contact c : triggerNew.values()){
            c.Firm_Admin__c = true;
            c.No_Longer_with_Firm__c = true;
            c.Average_Support_CSAT__c = 400;
            c.Edit_Online_Data__c = false;
            c.Edit_Online_Tax_Lots__c = false;
            handler.triggerNew = triggerNew.values();
            
        }

        handler.accountIdSet.add(accounts.get(1).Id);
        
      
        // Execute
         handler.collectionGeneratorAfterUpdate();

         // Assert
         System.assert(handler.accountIdSet.contains(accounts.get(1).Id),'Account ID not in accountIdSet');
         System.assert(handler.accIdSet.contains(accounts.get(1).Id),'Account ID not in accIdSet');
         System.assert(handler.noLongerinFirmConIds.contains(accounts.get(1).Id),'Account ID not in noLongerinFirmConIds');  
                                                                                                                
    }
    
    @IsTest
    private static void performAccoutUpdateOperations_Test(){
        ContactTriggerHandler handler = new ContactTriggerHandler();
        Map<Integer,Account> accounts = TestUtility.createAccounts(1, true);
        Map<Integer,Contact> triggerNew = TestUtility.createContacts(1, accounts.get(1).Id, true);
        
        Map<integer,Training__c> trainingmap = TestUtility.createTrainings(1, datetime.now().addDays(2), false);
        Training__c trainObj= trainingmap.get(1);
        trainObj.Location__c='US';
        trainObj.Training_Start_Date_Time__c = datetime.now().addDays(2);
        insert trainObj;
        Map<integer,Training_Participant__c> trainingParticipant= TestUtility.createTrainingParticipants(1, trainObj.Id, 'Attended', triggerNew.get(1).Id, accounts.get(1).Id, true);
        
        for(Contact c : triggerNew.values()){
            c.Firm_Admin__c = true;
        }
        update triggerNew.values();
        handler.accountIdsForFirm.add(accounts.get(1).Id);
        handler.noLongerinFirmConIds.add(accounts.get(1).Id);
        handler.performAccoutUpdateOperations();
        // Assert
        System.assert(handler.accountIdsForFirm.contains(accounts.get(1).Id),'Account ID not in accountIdSet');
        //System.assert(handler.accountsToUpdateMap.containsKey(accounts.get(1).Id),'Account ID not in Map');
    
    }
    @IsTest
    private static void deRollupMethod_Test(){
        ContactTriggerHandler handler = new ContactTriggerHandler();
        Map<Integer,Account> accounts = TestUtility.createAccounts(1, true);
        Map<Integer,Contact> triggerNew = TestUtility.createContacts(1, accounts.get(1).Id, true);   
        
         //// Populate handler
        handler.instantiate(); 
        
        for(Contact c : triggerNew.values()){
            c.accountid = accounts.get(1).Id;
            c.Edit_Online_Data__c = true;
            c.Edit_Online_Tax_Lots__c = true;    
        }
        update triggerNew.values();
        handler.instantiate();
        handler.antiOnlineDataRollups.add(accounts.get(1).Id);
        handler.deRollupMethod();
        //System.assert(handler.accToUpdate.contains(accounts.get(1).Id),'Account ID not in accToUpdate');
    }
    
    @IsTest
    private static void contactAccountUpdate_Test(){
        ContactTriggerHandler handler = new ContactTriggerHandler();
        Map<Integer,Account> accounts = TestUtility.createAccounts(1, true);
        Account acc = accounts.get(1);
        acc.HasActiveContacts__c = true;
        update acc; 
        handler.instantiate();
        handler.accIdSet.add(acc.id);
        handler.contactAccountUpdate();
        //System.assert(handler.accountToUpdate.contains(accounts.get(1).Id),'Account ID not in accountToUpdate');
    }
  
}
