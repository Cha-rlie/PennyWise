class DataHandlingUtil {
  static String generateFriendshipMembersKey(String userId1, String userId2) {
    List<String> sortedIds = [userId1, userId2]..sort();
    return sortedIds.join("_");
  }

}