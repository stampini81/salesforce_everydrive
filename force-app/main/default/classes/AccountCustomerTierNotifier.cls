public with sharing class AccountCustomerTierNotifier {
    public static void handleAfterUpdate(List<Account> newList, Map<Id, Account> oldMap) {
        if (newList == null || newList.isEmpty()) {
            return;
        }

        Set<Id> accountIds = new Set<Id>();
        for (Account acc : newList) {
            Account oldAcc = oldMap != null ? oldMap.get(acc.Id) : null;
            if (acc.Customer_Tier__c == 'Gold' && (oldAcc == null || oldAcc.Customer_Tier__c != 'Gold')) {
                accountIds.add(acc.Id);
            }
        }

        if (accountIds.isEmpty()) {
            return;
        }

        Map<Id, Account> accountMap = new Map<Id, Account>([
            SELECT Id, Name, Sales_Rep__c, Sales_Rep__r.Email
            FROM Account
            WHERE Id IN :accountIds
        ]);

        Set<Id> salesRepIds = new Set<Id>();
        for (Account acc : accountMap.values()) {
            if (acc.Sales_Rep__c != null) {
                salesRepIds.add(acc.Sales_Rep__c);
            }
        }

        Map<Id, User> salesRepMap = new Map<Id, User>();
        if (!salesRepIds.isEmpty()) {
            salesRepMap = new Map<Id, User>([
                SELECT Id, Email, IsActive
                FROM User
                WHERE Id IN :salesRepIds
            ]);
        }

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (Account acc : accountMap.values()) {
            if (acc.Sales_Rep__c == null) {
                continue;
            }
            User rep = salesRepMap.get(acc.Sales_Rep__c);
            if (rep == null || !rep.IsActive || String.isBlank(rep.Email)) {
                continue;
            }

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setTargetObjectId(rep.Id);
            email.setSaveAsActivity(false);
            email.setSubject('EveryDrive Alert: Account ' + acc.Name + ' is now GOLD!');
            email.setHtmlBody('<p>Great news! The account <b>' + acc.Name + '</b> has just reached the <b>GOLD TIER</b>! 🚀</p>');
            emails.add(email);
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails, false);
        }
    }
}
