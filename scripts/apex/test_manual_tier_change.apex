System.debug('=== Manual Tier Change test start ===');

Schema.DescribeFieldResult d = Account.Customer_Tier__c.getDescribe();
String gold;
String silver;
if (d != null && d.getType() == Schema.DisplayType.Picklist) {
    for (Schema.PicklistEntry e : d.getPicklistValues()) {
        if (e == null) continue;
        String v = e.getValue();
        if (String.isBlank(v)) continue;
        String l = v.trim().toLowerCase();
        if (l == 'gold' || l == 'ouro') gold = v;
        if (l == 'silver' || l == 'prata') silver = v;
    }
}
if (gold == null) gold = 'Gold';
if (silver == null) silver = 'Silver';

Account acc = new Account(
    Name = 'Manual Tier ' + String.valueOf(DateTime.now().getTime()),
    Sales_Rep__c = UserInfo.getUserId(),
    Customer_Tier__c = silver
);
insert acc;

acc.Customer_Tier__c = gold;
update acc;

System.debug('Updated Account to Gold Id=' + acc.Id);
System.debug('=== Manual Tier Change test end ===');
