@IsTest
private class EveryDriveCustomerTierControllerTest {
    private static String pickTierValue(Set<String> candidates) {
        // Supports both EN/PT values and restricted picklists.
        Schema.DescribeFieldResult d = Account.Customer_Tier__c.getDescribe();
        if (d != null && d.getType() == Schema.DisplayType.Picklist) {
            for (Schema.PicklistEntry entry : d.getPicklistValues()) {
                if (entry == null) continue;
                String v = entry.getValue();
                if (String.isBlank(v)) continue;
                if (candidates.contains(v.toLowerCase())) {
                    return v;
                }
            }
            return null;
        }

        // If it's not a picklist (e.g., Text), just pick the first candidate.
        for (String c : candidates) {
            return c;
        }
        return null;
    }

    @IsTest
    static void getTierImageUrl_returnsBronzeSilverGold() {
        String bronzeTier = pickTierValue(new Set<String>{ 'bronze' });
        String silverTier = pickTierValue(new Set<String>{ 'silver', 'prata' });
        String goldTier = pickTierValue(new Set<String>{ 'gold', 'ouro' });

        System.assertNotEquals(null, bronzeTier, 'Customer_Tier__c must have a Bronze value');
        System.assertNotEquals(null, silverTier, 'Customer_Tier__c must have a Silver/Prata value');
        System.assertNotEquals(null, goldTier, 'Customer_Tier__c must have a Gold/Ouro value');

        Account bronzeAcc = new Account(Name = 'Bronze Acc', Customer_Tier__c = bronzeTier);
        Account silverAcc = new Account(Name = 'Silver Acc', Customer_Tier__c = silverTier);
        Account goldAcc = new Account(Name = 'Gold Acc', Customer_Tier__c = goldTier);
        insert new List<Account>{ bronzeAcc, silverAcc, goldAcc };

        Test.startTest();
        String bronzeUrl = EveryDriveCustomerTierController.getTierImageUrl(bronzeAcc.Id);
        String silverUrl = EveryDriveCustomerTierController.getTierImageUrl(silverAcc.Id);
        String goldUrl = EveryDriveCustomerTierController.getTierImageUrl(goldAcc.Id);
        Test.stopTest();

        System.assertEquals('/resource/medals/bronze.png', bronzeUrl, 'Bronze tier should map to bronze.png');
        System.assertEquals('/resource/medals/silver.png', silverUrl, 'Silver tier should map to silver.png');
        System.assertEquals('/resource/medals/gold.png', goldUrl, 'Gold tier should map to gold.png');
    }

    @IsTest
    static void getTierImageUrl_returnsNullWhenBlankTier() {
        Account acc = new Account(Name = 'No Tier Acc');
        insert acc;

        Test.startTest();
        String url = EveryDriveCustomerTierController.getTierImageUrl(acc.Id);
        Test.stopTest();

        System.assertEquals(null, url, 'Blank tier should return null');
    }

    @IsTest
    static void getAccountName_and_getCustomerTier_work() {
        String silverTier = pickTierValue(new Set<String>{ 'silver', 'prata' });
        System.assertNotEquals(null, silverTier, 'Customer_Tier__c must have a Silver/Prata value');

        Account acc = new Account(Name = 'Sample Acc', Customer_Tier__c = silverTier);
        insert acc;

        Test.startTest();
        String name = EveryDriveCustomerTierController.getAccountName(acc.Id);
        String tier = EveryDriveCustomerTierController.getCustomerTier(acc.Id);
        Test.stopTest();

        System.assertEquals('Sample Acc', name);
        System.assertEquals(silverTier, tier);
    }
}
