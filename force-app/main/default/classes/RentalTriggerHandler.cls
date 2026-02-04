public with sharing class RentalTriggerHandler {
    private static final Set<String> STATUS_CONCLUDED = new Set<String>{ 'Concluída', 'Completed', 'Complete' };

    public static void validateRentals(List<Rental__c> rentals) {
        for (Rental__c rental : rentals) {
            if (rental.Value__c == null || rental.Value__c <= 0) {
                rental.Value__c.addError('Valor deve ser maior que zero.');
            }

            if (rental.Start_Date__c != null && rental.End_Date__c != null &&
                rental.End_Date__c < rental.Start_Date__c) {
                rental.End_Date__c.addError('Data de Fim deve ser maior ou igual à Data de Início.');
            }

            if (STATUS_CONCLUDED.contains(rental.Status__c) && rental.End_Date__c == null) {
                rental.End_Date__c.addError('Não é permitido Status Concluída sem Data de Fim.');
            }
        }
    }

    public static void createFollowUpTasks(List<Rental__c> newRentals, Map<Id, Rental__c> oldMap) {
        // External/portal/guest users may not be allowed to create Tasks.
        // Avoid breaking the rental transaction for those contexts.
        if (UserInfo.getUserType() != 'Standard') {
            return;
        }

        Set<Id> accountIds = new Set<Id>();
        List<Rental__c> concludedRentals = new List<Rental__c>();

        for (Rental__c rental : newRentals) {
            Rental__c oldRental = oldMap != null ? oldMap.get(rental.Id) : null;
            Boolean isConcludedNow = STATUS_CONCLUDED.contains(rental.Status__c);
            Boolean wasConcludedBefore = oldRental != null && STATUS_CONCLUDED.contains(oldRental.Status__c);

            if (isConcludedNow && !wasConcludedBefore) {
                if (rental.Account__c != null) {
                    concludedRentals.add(rental);
                    accountIds.add(rental.Account__c);
                }
            }
        }

        if (concludedRentals.isEmpty()) {
            return;
        }

        Map<Id, Account> accountMap = new Map<Id, Account>([
            SELECT Id, Sales_Rep__c
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
                SELECT Id, IsActive, UserType
                FROM User
                WHERE Id IN :salesRepIds
                    AND IsActive = true
            ]);
        }

        List<Task> tasks = new List<Task>();
        for (Rental__c rental : concludedRentals) {
            Account acc = accountMap.get(rental.Account__c);
            if (acc == null || acc.Sales_Rep__c == null) {
                continue;
            }

            User rep = salesRepMap.get(acc.Sales_Rep__c);
            // Avoid assigning or inserting Tasks for non-internal user types (portal/guest/etc.),
            // which can throw OP_WITH_INVALID_USER_TYPE_EXCEPTION.
            if (rep == null || rep.UserType != 'Standard') {
                continue;
            }

            if (salesRepMap.containsKey(acc.Sales_Rep__c)) {
                tasks.add(new Task(
                    OwnerId = acc.Sales_Rep__c,
                    WhatId = rental.Account__c,
                    Subject = 'Cliente concluiu locação, realizar follow-up.'
                ));
            }
        }

        if (!tasks.isEmpty()) {
            // Insert with partial success to prevent the trigger from failing the entire DML.
            // Some org/user contexts can still throw (e.g., invalid user type / permissions),
            // so keep this as a best-effort operation.
            try {
                Database.insert(tasks, false);
            } catch (DmlException e) {
                System.debug('Task insert skipped: ' + e.getMessage());
            }
        }
    }
}
