trigger AccountTrigger on Account (after update) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        AccountCustomerTierNotifier.handleAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}
