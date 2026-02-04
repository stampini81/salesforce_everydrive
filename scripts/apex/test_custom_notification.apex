System.debug('=== Custom Notification test start ===');

Account acc = new Account(
    Name = 'Test Gold Notif ' + String.valueOf(DateTime.now().getTime()),
    Sales_Rep__c = UserInfo.getUserId()
);
insert acc;
System.debug(LoggingLevel.INFO, 'Inserted Account Id=' + acc.Id);

// Determine a "concluded" status value for Rental__c
Schema.DescribeFieldResult statusDescribe = Rental__c.Status__c.getDescribe();
String concludedStatus;
Set<String> concludedLower = new Set<String>{ 'concluída', 'completed', 'complete' };
if (statusDescribe != null && statusDescribe.getType() == Schema.DisplayType.Picklist) {
    for (Schema.PicklistEntry e : statusDescribe.getPicklistValues()) {
        String v = e.getValue();
        if (String.isBlank(v)) continue;
        String l = v.trim().toLowerCase();
        if (concludedLower.contains(l) && concludedStatus == null) {
            concludedStatus = v;
        }
    }
}
if (concludedStatus == null) {
    concludedStatus = 'Completed';
}
System.debug(LoggingLevel.INFO, 'Using Rental__c Status__c=' + concludedStatus);

// Insert a concluded Rental__c with high value to drive rollup/automation
Rental__c r = new Rental__c(
    Account__c = acc.Id,
    Start_Date__c = Date.today().addDays(-2),
    End_Date__c = Date.today().addDays(-1),
    Status__c = concludedStatus,
    Value__c = 20000
);
insert r;
System.debug(LoggingLevel.INFO, 'Inserted Rental__c Id=' + r.Id);

// Requery Account to see tier/total after automation
Account accAfter = [
    SELECT Id, Customer_Tier__c, Total_Amount_Spent__c
    FROM Account
    WHERE Id = :acc.Id
    LIMIT 1
];
System.debug(LoggingLevel.INFO, 'Account after Rental__c => Tier=' + accAfter.Customer_Tier__c +
    ', Total=' + accAfter.Total_Amount_Spent__c);

System.debug('=== Custom Notification test end ===');
