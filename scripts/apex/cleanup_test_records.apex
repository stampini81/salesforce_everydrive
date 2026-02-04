System.debug('=== Cleanup test records start ===');

List<Account> accs = [
    SELECT Id
    FROM Account
    WHERE Name LIKE 'Debug Acc %'
       OR Name LIKE 'Test Gold Notif %'
       OR Name LIKE 'Test Notif Target %'
       OR Name LIKE 'Manual Tier %'
];

if (!accs.isEmpty()) {
    delete accs;
    System.debug(LoggingLevel.INFO, 'Deleted Accounts: ' + accs.size());
} else {
    System.debug(LoggingLevel.INFO, 'No test Accounts found.');
}

List<Rental__c> rentals = [
    SELECT Id
    FROM Rental__c
    WHERE Account__c = null
      AND CreatedDate = TODAY
];
if (!rentals.isEmpty()) {
    delete rentals;
    System.debug(LoggingLevel.INFO, 'Deleted Rentals: ' + rentals.size());
} else {
    System.debug(LoggingLevel.INFO, 'No standalone Rentals found.');
}

System.debug('=== Cleanup test records end ===');
