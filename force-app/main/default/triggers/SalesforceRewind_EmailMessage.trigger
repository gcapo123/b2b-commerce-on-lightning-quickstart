trigger SalesforceRewind_EmailMessage on EmailMessage (after insert, after update, after delete) {
    if(System.isBatch()) return;
    SalesforceRewindTriggerHandler.publishNotifications(Trigger.oldMap, Trigger.new, Trigger.isInsert, Trigger.isUpdate, Trigger.isDelete);
}