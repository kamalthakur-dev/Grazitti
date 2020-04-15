/**
 * @File Name          : LeadTrigger.trigger
 * @Description        : 
 * @Last Modified By   : Will Craig
 * @Last Modified On   : 4/10/2020, 3:46:36 PM
 * @Modification Log   : Removed Qualification Profile logic.
 * @Modification Log   : Added Trigger global switch logic.
 * @Modification Log   : Moved to Trigger Framework.
**/

trigger LeadTrigger on Lead (after insert, after update, before insert, before update) {
    
    // Only fire if there is either no setting, or there is a custom setting that enables the trigger.
    String type = 'Lead';
    if(TriggerUtilities.IsEnabled(type) == false){ return; }

    // START -- Moving to Trigger Framework -- Will Craig //
    new LeadTriggerHandler().run();
    // End   -- Moving to Trigger Framework -- Will Craig //
    
}