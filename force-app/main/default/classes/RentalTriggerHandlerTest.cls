@IsTest
private class RentalTriggerHandlerTest {
    private static User createActiveUserWithEmail() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            Alias = 'tuser',
            Email = 'tuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            ProfileId = p.Id,
            Username = 'tuser+' + String.valueOf(DateTime.now().getTime()) + '@example.com'
        );
        insert u;
        return u;
    }

    private static String pickRentalStatus(Set<String> preferredLower) {
        Schema.DescribeFieldResult d = Rental__c.Status__c.getDescribe();
        if (d != null && d.getType() == Schema.DisplayType.Picklist) {
            for (Schema.PicklistEntry entry : d.getPicklistValues()) {
                if (entry == null) continue;
                String v = entry.getValue();
                if (String.isBlank(v)) continue;
                if (preferredLower.contains(v.toLowerCase())) {
                    return v;
                }
            }
        }
        // Fallback (only if field is not a restricted picklist)
        for (String c : preferredLower) {
            return c;
        }
        return null;
    }

    private static String pickNonConcludedStatus(Set<String> concludedLower) {
        Schema.DescribeFieldResult d = Rental__c.Status__c.getDescribe();
        if (d != null && d.getType() == Schema.DisplayType.Picklist) {
            for (Schema.PicklistEntry entry : d.getPicklistValues()) {
                if (entry == null) continue;
                String v = entry.getValue();
                if (String.isBlank(v)) continue;
                if (!concludedLower.contains(v.toLowerCase())) {
                    return v;
                }
            }
            return null;
        }
        return 'Planejada';
    }

    @IsTest
    static void afterInsert_concluded_createsTask() {
        User rep = createActiveUserWithEmail();
        Account acc = new Account(Name = 'Acc', Sales_Rep__c = rep.Id);
        insert acc;

        Set<String> concludedLower = new Set<String>{ 'concluída', 'completed', 'complete' };
        String concluded = pickRentalStatus(concludedLower);
        System.assertNotEquals(null, concluded, 'Need a concluded Status__c value in this org.');

        Rental__c r = new Rental__c(
            Account__c = acc.Id,
            Start_Date__c = Date.today().addDays(-2),
            End_Date__c = Date.today().addDays(-1),
            Status__c = concluded,
            Value__c = 100
        );

        Test.startTest();
        insert r;
        Test.stopTest();

        List<Task> tasks = [
            SELECT Id, OwnerId, WhatId, Subject
            FROM Task
            WHERE WhatId = :acc.Id AND OwnerId = :rep.Id
        ];
        System.assertEquals(1, tasks.size(), 'Should create a follow-up Task when rental is concluded.');
        System.assertEquals('Cliente concluiu locação, realizar follow-up.', tasks[0].Subject);
    }

    @IsTest
    static void afterUpdate_toConcluded_createsTask() {
        User rep = createActiveUserWithEmail();
        Account acc = new Account(Name = 'Acc2', Sales_Rep__c = rep.Id);
        insert acc;

        Set<String> concludedLower = new Set<String>{ 'concluída', 'completed', 'complete' };
        String nonConcluded = pickNonConcludedStatus(concludedLower);
        String concluded = pickRentalStatus(concludedLower);
        System.assertNotEquals(null, nonConcluded, 'Need a non-concluded Status__c value in this org.');
        System.assertNotEquals(null, concluded, 'Need a concluded Status__c value in this org.');

        Rental__c r = new Rental__c(
            Account__c = acc.Id,
            Start_Date__c = Date.today().addDays(-2),
            End_Date__c = Date.today().addDays(-1),
            Status__c = nonConcluded,
            Value__c = 100
        );
        insert r;

        Test.startTest();
        r.Status__c = concluded;
        update r;
        Test.stopTest();

        List<Task> tasks = [
            SELECT Id
            FROM Task
            WHERE WhatId = :acc.Id AND OwnerId = :rep.Id
        ];
        System.assertEquals(1, tasks.size(), 'Should create a follow-up Task when rental status changes to concluded.');
    }

    @IsTest
    static void beforeInsert_invalidValue_fails() {
        Account acc = new Account(Name = 'Acc3');
        insert acc;

        String anyStatus = pickNonConcludedStatus(new Set<String>{ 'concluída', 'completed', 'complete' });
        System.assertNotEquals(null, anyStatus, 'Need a Status__c value in this org.');

        Rental__c r = new Rental__c(
            Account__c = acc.Id,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today(),
            Status__c = anyStatus,
            Value__c = 0
        );

        Test.startTest();
        try {
            insert r;
            System.assert(false, 'Expected DML to fail due to invalid Value__c');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Valor deve ser maior que zero.'), 'Should enforce positive value');
        }
        Test.stopTest();
    }

    @IsTest
    static void beforeInsert_endDateBeforeStart_fails() {
        Account acc = new Account(Name = 'Acc4');
        insert acc;

        String anyStatus = pickNonConcludedStatus(new Set<String>{ 'concluída', 'completed', 'complete' });
        System.assertNotEquals(null, anyStatus, 'Need a Status__c value in this org.');

        Rental__c r = new Rental__c(
            Account__c = acc.Id,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addDays(-1),
            Status__c = anyStatus,
            Value__c = 10
        );

        Test.startTest();
        try {
            insert r;
            System.assert(false, 'Expected DML to fail due to End_Date__c < Start_Date__c');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Data de Fim deve ser maior ou igual à Data de Início.'), 'Should enforce end date >= start date');
        }
        Test.stopTest();
    }

    @IsTest
    static void beforeInsert_concludedWithoutEndDate_fails() {
        Account acc = new Account(Name = 'Acc5');
        insert acc;

        Set<String> concludedLower = new Set<String>{ 'concluída', 'completed', 'complete' };
        String concluded = pickRentalStatus(concludedLower);
        System.assertNotEquals(null, concluded, 'Need a concluded Status__c value in this org.');

        Rental__c r = new Rental__c(
            Account__c = acc.Id,
            Start_Date__c = Date.today().addDays(-2),
            End_Date__c = null,
            Status__c = concluded,
            Value__c = 10
        );

        Test.startTest();
        try {
            insert r;
            System.assert(false, 'Expected DML to fail due to concluded status without End_Date__c');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Não é permitido Status Concluída sem Data de Fim.'), 'Should require end date when concluded');
        }
        Test.stopTest();
    }
}
