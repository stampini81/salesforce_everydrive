trigger RentalTrigger on Rental__c (before insert, before update, after insert, after update) {
    if (Trigger.isBefore) {
        RentalTriggerHandler.validateRentals(Trigger.new);
    }

    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        RentalTriggerHandler.createFollowUpTasks(Trigger.new, Trigger.oldMap);
    }
}
