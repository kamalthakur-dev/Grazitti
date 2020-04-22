trigger ContactTrigger on Contact (before update, after update, after insert, after delete) {
    
    // Only fire if there is either no setting, or there is a custom setting that enables the trigger.
    String type = 'Contact';
    if(TriggerUtilities.IsEnabled(type) == false){ return; }
    
    // START -- Moving to Trigger Framework 
    new ContactTriggerHandler().run();
    // End   -- Moving to Trigger Framework 
}