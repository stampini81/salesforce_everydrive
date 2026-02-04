System.debug('=== CustomNotification methods ===');
System.Type t = Type.forName('Messaging.CustomNotification');
if (t == null) {
    System.debug('CustomNotification type not found');
} else {
    System.debug(t.getMethods());
}
System.debug('=== End ===');
