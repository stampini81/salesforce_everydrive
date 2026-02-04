public with sharing class EveryDriveCustomerTierController {
    @AuraEnabled
    public static String getTierImageUrl(Id accountId) {
        Account acc = [
            SELECT Name, Customer_Tier__c
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];

        String tier = acc.Customer_Tier__c;
        if (String.isBlank(tier)) {
            return null;
        }

        String normalizedTier = normalizeTier(tier);
        if (normalizedTier == null) {
            return null;
        }

        String fileName = 'bronze.png';
        if (normalizedTier == 'silver') fileName = 'silver.png';
        if (normalizedTier == 'gold') fileName = 'gold.png';

        return '/resource/medals/' + fileName;
    }

    private static String normalizeTier(String tier) {
        if (String.isBlank(tier)) {
            return null;
        }
        String normalized = tier.trim().toLowerCase();
        if (normalized == 'bronze') return 'bronze';
        if (normalized == 'prata' || normalized == 'silver') return 'silver';
        if (normalized == 'ouro' || normalized == 'gold') return 'gold';
        return null;
    }

    @AuraEnabled
    public static String getAccountName(Id accountId) {
        return [SELECT Name FROM Account WHERE Id = :accountId].Name;
    }

    @AuraEnabled
    public static String getCustomerTier(Id accountId) {
        return [SELECT Customer_Tier__c FROM Account WHERE Id = :accountId].Customer_Tier__c;
    }
}
