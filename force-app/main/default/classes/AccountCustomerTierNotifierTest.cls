@IsTest
private class AccountCustomerTierNotifierTest {
    private static User createActiveUserWithEmail() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            Alias = 'arepr',
            Email = 'arepr@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Rep',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            ProfileId = p.Id,
            Username = 'arepr+' + String.valueOf(DateTime.now().getTime()) + '@example.com'
        );
        insert u;
        return u;
    }

    private static String pickTierValue(Set<String> candidatesLower) {
        Schema.DescribeFieldResult d = Account.Customer_Tier__c.getDescribe();
        if (d != null && d.getType() == Schema.DisplayType.Picklist) {
            for (Schema.PicklistEntry entry : d.getPicklistValues()) {
                if (entry == null) continue;
                String v = entry.getValue();
                if (String.isBlank(v)) continue;
                if (candidatesLower.contains(v.toLowerCase())) {
                    return v;
                }
            }
            return null;
        }

        for (String c : candidatesLower) {
            return c;
        }
        return null;
    }

    @IsTest
    static void updateToGold_sendsEmailWhenRepValid() {
        User rep = createActiveUserWithEmail();

        String gold = pickTierValue(new Set<String>{ 'gold' });
        String nonGold = pickTierValue(new Set<String>{ 'bronze', 'silver', 'prata', 'ouro' });
        System.assertNotEquals(null, gold, 'Customer_Tier__c must contain Gold value for this notifier logic.');

        Account acc = new Account(
            Name = 'Acc',
            Sales_Rep__c = rep.Id,
            Customer_Tier__c = nonGold
        );
        insert acc;

        Test.startTest();
        Integer beforeInv = Limits.getEmailInvocations();
        acc.Customer_Tier__c = gold;
        update acc;
        Integer afterInv = Limits.getEmailInvocations();
        Test.stopTest();

        System.assertEquals(beforeInv + 1, afterInv, 'Should send exactly one email when tier changes to Gold.');
    }

    @IsTest
    static void updateAlreadyGold_doesNotSendAgain() {
        User rep = createActiveUserWithEmail();
        String gold = pickTierValue(new Set<String>{ 'gold' });
        System.assertNotEquals(null, gold, 'Customer_Tier__c must contain Gold value for this notifier logic.');

        Account acc = new Account(Name = 'Acc2', Sales_Rep__c = rep.Id, Customer_Tier__c = gold);
        insert acc;

        Test.startTest();
        Integer beforeInv = Limits.getEmailInvocations();
        acc.Name = 'Acc2 Updated';
        update acc;
        Integer afterInv = Limits.getEmailInvocations();
        Test.stopTest();

        System.assertEquals(beforeInv, afterInv, 'Should not send email if it was already Gold.');
    }

    @IsTest
    static void updateToGold_withoutSalesRep_doesNotSend() {
        String gold = pickTierValue(new Set<String>{ 'gold' });
        String nonGold = pickTierValue(new Set<String>{ 'bronze', 'silver', 'prata', 'ouro' });
        System.assertNotEquals(null, gold, 'Customer_Tier__c must contain Gold value for this notifier logic.');

        Account acc = new Account(Name = 'Acc3', Customer_Tier__c = nonGold);
        insert acc;

        Test.startTest();
        Integer beforeInv = Limits.getEmailInvocations();
        acc.Customer_Tier__c = gold;
        update acc;
        Integer afterInv = Limits.getEmailInvocations();
        Test.stopTest();

        System.assertEquals(beforeInv, afterInv, 'Should not send email if Sales_Rep__c is null.');
    }
}
