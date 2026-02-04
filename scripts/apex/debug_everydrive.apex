// Execute with:
//   sf apex run --target-org everydrive --file scripts/apex/debug_everydrive.apex
// Then tail logs with:
//   sf apex tail log --target-org everydrive --color

System.debug('=== EveryDrive debug start ===');

// -----------------------------
// 1) Debug the LWC controller
// -----------------------------
Schema.DescribeFieldResult tierDescribe = Account.Customer_Tier__c.getDescribe();
String bronzeTier;
String silverTier;
String goldTier;

if (tierDescribe != null && tierDescribe.getType() == Schema.DisplayType.Picklist) {
    for (Schema.PicklistEntry e : tierDescribe.getPicklistValues()) {
        String v = e.getValue();
        if (String.isBlank(v)) continue;
        String l = v.trim().toLowerCase();
        if (l == 'bronze') bronzeTier = v;
        if (l == 'silver' || l == 'prata') silverTier = v;
        if (l == 'gold' || l == 'ouro') goldTier = v;
    }
} else {
    bronzeTier = 'Bronze';
    silverTier = 'Silver';
    goldTier = 'Gold';
}

System.debug(LoggingLevel.INFO, 'Tier picklist values found => bronze=' + bronzeTier + ', silver=' + silverTier + ', gold=' + goldTier);

Account acc = new Account(
    Name = 'Debug Acc ' + String.valueOf(DateTime.now().getTime()),
    Customer_Tier__c = silverTier
);
insert acc;

System.debug(LoggingLevel.INFO, 'Created Account Id=' + acc.Id);
System.debug(LoggingLevel.INFO, 'getAccountName=' + EveryDriveCustomerTierController.getAccountName(acc.Id));
System.debug(LoggingLevel.INFO, 'getCustomerTier=' + EveryDriveCustomerTierController.getCustomerTier(acc.Id));
System.debug(LoggingLevel.INFO, 'getTierImageUrl=' + EveryDriveCustomerTierController.getTierImageUrl(acc.Id));

// --------------------------------------
// 2) Fire AccountTrigger (after update)
//    It calls AccountCustomerTierNotifier
// --------------------------------------
// Note: it only notifies when Customer_Tier__c becomes exactly 'Gold'.
// If your org uses 'Ouro' instead, the trigger logic won't match.
// We'll attempt to set 'Gold' if available; otherwise we just log the mismatch.

Boolean goldAvailable = (goldTier != null) && (goldTier.trim().toLowerCase() == 'gold');
if (goldAvailable) {
    // Set Sales_Rep__c to current user so notifier has someone to email.
    acc.Sales_Rep__c = UserInfo.getUserId();
    acc.Customer_Tier__c = goldTier;
    update acc;
    System.debug(LoggingLevel.INFO, 'Updated Account to Gold to fire AccountTrigger.');
} else {
    System.debug(LoggingLevel.WARN, 'Gold value not available as literal "Gold" in this org; AccountCustomerTierNotifier checks for "Gold" exactly.');
}

// --------------------------------------
// 3) Fire RentalTrigger (before/after)
// --------------------------------------
// We'll:
//   a) Insert a NON-concluded Rental__c (fires before/after insert; should NOT create a follow-up task)
//   b) Update it to CONCLUDED (fires before/after update; SHOULD create a follow-up task)
// This makes it easier to see both code paths.

Schema.DescribeFieldResult statusDescribe = Rental__c.Status__c.getDescribe();
String concludedStatus;
String nonConcludedStatus;
Set<String> concludedLower = new Set<String>{ 'concluída', 'completed', 'complete' };

if (statusDescribe != null && statusDescribe.getType() == Schema.DisplayType.Picklist) {
    for (Schema.PicklistEntry e : statusDescribe.getPicklistValues()) {
        String v = e.getValue();
        if (String.isBlank(v)) continue;
        String l = v.trim().toLowerCase();
        if (concludedLower.contains(l) && concludedStatus == null) concludedStatus = v;
        if (!concludedLower.contains(l) && nonConcludedStatus == null) nonConcludedStatus = v;
    }
} else {
    concludedStatus = 'Completed';
    nonConcludedStatus = 'Planejada';
}

System.debug(LoggingLevel.INFO, 'Rental status values => concluded=' + concludedStatus + ', nonConcluded=' + nonConcludedStatus);

if (concludedStatus == null || nonConcludedStatus == null) {
    System.debug(LoggingLevel.WARN, 'Missing concluded or non-concluded Rental__c Status__c value in this org; skipping Rental trigger fire.');
} else {
    Integer tasksBefore = [SELECT COUNT() FROM Task WHERE WhatId = :acc.Id];
    System.debug(LoggingLevel.INFO, 'Tasks related to Account BEFORE rentals: ' + tasksBefore);

    Rental__c r = new Rental__c(
        Account__c = acc.Id,
        Start_Date__c = Date.today().addDays(-2),
        End_Date__c = Date.today().addDays(-1),
        Status__c = nonConcludedStatus,
        Value__c = 123
    );

    System.debug(LoggingLevel.INFO, 'Inserting NON-concluded Rental__c (expect: validation runs, no follow-up task yet).');
    insert r;
    System.debug(LoggingLevel.INFO, 'Inserted Rental__c Id=' + r.Id + ' with Status=' + r.Status__c);

    Integer tasksAfterInsert = [SELECT COUNT() FROM Task WHERE WhatId = :acc.Id];
    System.debug(LoggingLevel.INFO, 'Tasks related to Account AFTER non-concluded insert: ' + tasksAfterInsert);

    System.debug(LoggingLevel.INFO, 'Updating Rental__c to CONCLUDED (expect: follow-up task created in after update).');
    r.Status__c = concludedStatus;
    update r;

    Integer tasksAfterUpdate = [SELECT COUNT() FROM Task WHERE WhatId = :acc.Id];
    System.debug(LoggingLevel.INFO, 'Tasks related to Account AFTER concluded update: ' + tasksAfterUpdate);

    List<Task> lastTasks = [
        SELECT Id, OwnerId, Subject, CreatedDate
        FROM Task
        WHERE WhatId = :acc.Id
        ORDER BY CreatedDate DESC
        LIMIT 5
    ];
    System.debug(LoggingLevel.INFO, 'Last Tasks: ' + lastTasks);
}

System.debug('=== EveryDrive debug end ===');
