import 'package:flutter_test/flutter_test.dart';
import 'package:bonuses/providers/app_provider.dart';
import 'package:bonuses/models/user.dart';
import 'package:bonuses/models/message.dart';
import 'package:bonuses/models/company.dart';
import 'package:bonuses/services/storage_service.dart';
import 'test_helpers.dart';

void main() {
  // Initialize Flutter binding and mock shared_preferences
  setupSharedPreferencesMock();

  group('Messaging System Tests', () {
    late AppProvider appProvider;
    late User user1;
    late User user2;
    late Company testCompany;

    setUp(() async {
      // Clear storage before each test
      await StorageService.clearAllData();

      appProvider = AppProvider();

      // Create test company
      testCompany = Company(
        id: 'test_company',
        name: 'Test Company',
        address: '123 Test St',
        contactEmail: 'test@company.com',
        contactPhone: '555-0100',
        adminUserId: 'user1',
        createdAt: DateTime.now(),
      );

      // Create test users
      user1 = User(
        id: 'user1',
        name: 'Alice Smith',
        email: 'alice@test.com',
        role: UserRole.admin,
        createdAt: DateTime.now(),
        primaryCompanyId: testCompany.id,
        companyIds: [testCompany.id],
        companyRoles: {testCompany.id: 'admin'},
      );

      user2 = User(
        id: 'user2',
        name: 'Bob Jones',
        email: 'bob@test.com',
        role: UserRole.employee,
        createdAt: DateTime.now(),
        primaryCompanyId: testCompany.id,
        companyIds: [testCompany.id],
        companyRoles: {testCompany.id: 'employee'},
      );

      // Save test data
      await StorageService.addCompany(testCompany);
      await StorageService.addUser(user1);
      await StorageService.addUser(user2);

      // Set current user and initialize provider
      await StorageService.setCurrentUser(user1);
      await appProvider.initialize();
    });

    tearDown(() async {
      await StorageService.clearAllData();
    });

    group('Message Sending and Receiving', () {
      test('User can send message to another user', () async {
        // Send message from user1 to user2
        await appProvider.sendMessage(user2.id, 'Hello Bob!');

        // Get messages for user2
        final messages = await StorageService.getMessagesForUser(user2.id);

        expect(messages.length, 1);
        expect(messages[0].senderId, user1.id);
        expect(messages[0].recipientId, user2.id);
        expect(messages[0].content, 'Hello Bob!');
        expect(messages[0].isRead, false);
      });

      test('Messages are stored correctly', () async {
        // Send multiple messages
        await appProvider.sendMessage(user2.id, 'Message 1');
        await appProvider.sendMessage(user2.id, 'Message 2');
        await appProvider.sendMessage(user2.id, 'Message 3');

        // Retrieve all messages
        final allMessages = await StorageService.getMessages();

        expect(allMessages.length, 3);
        expect(allMessages[0].content, 'Message 1');
        expect(allMessages[1].content, 'Message 2');
        expect(allMessages[2].content, 'Message 3');
      });

      test('Recipient receives message', () async {
        // Send message from user1 to user2
        await appProvider.sendMessage(user2.id, 'Test message');

        // Switch to user2 and check messages
        await StorageService.setCurrentUser(user2);
        await appProvider.initialize();
        final messages = await StorageService.getMessagesForUser(user2.id);

        expect(messages.length, 1);
        expect(messages[0].content, 'Test message');
        expect(messages[0].recipientId, user2.id);
      });

      test('Messages are ordered by timestamp', () async {
        // Send messages with slight delays
        await appProvider.sendMessage(user2.id, 'First');
        await Future.delayed(Duration(milliseconds: 10));
        await appProvider.sendMessage(user2.id, 'Second');
        await Future.delayed(Duration(milliseconds: 10));
        await appProvider.sendMessage(user2.id, 'Third');

        // Get conversation
        final conversation =
            await StorageService.getConversation(user1.id, user2.id);

        expect(conversation.length, 3);
        expect(conversation[0].content, 'First');
        expect(conversation[1].content, 'Second');
        expect(conversation[2].content, 'Third');

        // Verify timestamps are in order
        expect(conversation[0].timestamp.isBefore(conversation[1].timestamp),
            true);
        expect(conversation[1].timestamp.isBefore(conversation[2].timestamp),
            true);
      });
    });

    group('Message Read Status', () {
      test('Unread messages are marked correctly', () async {
        // Send message
        await appProvider.sendMessage(user2.id, 'Unread message');

        // Check unread count for user2
        final unreadCount =
            await StorageService.getUnreadMessageCount(user2.id);

        expect(unreadCount, 1);
      });

      test('Messages are marked as read when conversation is opened', () async {
        // Send multiple messages
        await appProvider.sendMessage(user2.id, 'Message 1');
        await appProvider.sendMessage(user2.id, 'Message 2');

        // Verify unread count
        expect(await StorageService.getUnreadMessageCount(user2.id), 2);

        // Mark messages as read
        await StorageService.markMessagesAsRead(user2.id, user1.id);

        // Verify unread count is now 0
        expect(await StorageService.getUnreadMessageCount(user2.id), 0);

        // Verify messages are marked as read
        final messages = await StorageService.getMessagesForUser(user2.id);
        expect(messages.every((m) => m.isRead), true);
      });

      test('Unread count updates correctly', () async {
        // Send 3 messages
        await appProvider.sendMessage(user2.id, 'Msg 1');
        await appProvider.sendMessage(user2.id, 'Msg 2');
        await appProvider.sendMessage(user2.id, 'Msg 3');

        // Check initial unread count
        expect(await StorageService.getUnreadMessageCount(user2.id), 3);

        // Mark messages as read
        await StorageService.setCurrentUser(user2);
        await appProvider.initialize();
        await appProvider.markMessagesAsRead(user1.id);

        // Verify unread count
        expect(await appProvider.getUnreadMessageCount(), 0);

        // Send another message from user1
        await StorageService.setCurrentUser(user1);
        await appProvider.initialize();
        await appProvider.sendMessage(user2.id, 'Msg 4');

        // Verify unread count increased
        expect(await StorageService.getUnreadMessageCount(user2.id), 1);
      });

      test('Only recipient\'s messages are marked as read', () async {
        // Create third user
        final user3 = User(
          id: 'user3',
          name: 'Charlie Brown',
          email: 'charlie@test.com',
          role: UserRole.employee,
          createdAt: DateTime.now(),
          primaryCompanyId: testCompany.id,
          companyIds: [testCompany.id],
          companyRoles: {testCompany.id: 'employee'},
        );
        await StorageService.addUser(user3);

        // Send messages to user2 from both user1 and user3
        await appProvider.sendMessage(user2.id, 'From Alice');

        await StorageService.setCurrentUser(user3);
        await appProvider.initialize();
        await appProvider.sendMessage(user2.id, 'From Charlie');

        // Mark only user1's messages as read
        await StorageService.markMessagesAsRead(user2.id, user1.id);

        // Verify user1's message is read, user3's is not
        final messages = await StorageService.getMessagesForUser(user2.id);
        final aliceMessage = messages.firstWhere((m) => m.senderId == user1.id);
        final charlieMessage =
            messages.firstWhere((m) => m.senderId == user3.id);

        expect(aliceMessage.isRead, true);
        expect(charlieMessage.isRead, false);
      });
    });

    group('Conversation Management', () {
      test('Conversation partners are listed correctly', () async {
        // Create third user
        final user3 = User(
          id: 'user3',
          name: 'Charlie Brown',
          email: 'charlie@test.com',
          role: UserRole.employee,
          createdAt: DateTime.now(),
          primaryCompanyId: testCompany.id,
          companyIds: [testCompany.id],
          companyRoles: {testCompany.id: 'employee'},
        );
        await StorageService.addUser(user3);

        // Send messages to both user2 and user3
        await appProvider.sendMessage(user2.id, 'Hello Bob');
        await appProvider.sendMessage(user3.id, 'Hello Charlie');

        // Get conversation partners
        final partners = await appProvider.getConversationPartners();

        expect(partners.length, 2);
        expect(partners.any((u) => u.id == user2.id), true);
        expect(partners.any((u) => u.id == user3.id), true);
      });

      test('Conversation history loads correctly', () async {
        // Send messages back and forth
        await appProvider.sendMessage(user2.id, 'Hi Bob');

        await StorageService.setCurrentUser(user2);
        await appProvider.initialize();
        await appProvider.sendMessage(user1.id, 'Hi Alice');

        await StorageService.setCurrentUser(user1);
        await appProvider.initialize();
        await appProvider.sendMessage(user2.id, 'How are you?');

        // Get conversation
        final conversation = await appProvider.getConversation(user2.id);

        expect(conversation.length, 3);
        expect(conversation[0].content, 'Hi Bob');
        expect(conversation[1].content, 'Hi Alice');
        expect(conversation[2].content, 'How are you?');
      });

      test('Multiple conversations are isolated', () async {
        // Create third user
        final user3 = User(
          id: 'user3',
          name: 'Charlie Brown',
          email: 'charlie@test.com',
          role: UserRole.employee,
          createdAt: DateTime.now(),
          primaryCompanyId: testCompany.id,
          companyIds: [testCompany.id],
          companyRoles: {testCompany.id: 'employee'},
        );
        await StorageService.addUser(user3);

        // Send messages to different users
        await appProvider.sendMessage(user2.id, 'Message to Bob');
        await appProvider.sendMessage(user3.id, 'Message to Charlie');

        // Get conversation with user2
        final conversationWithBob = await appProvider.getConversation(user2.id);

        expect(conversationWithBob.length, 1);
        expect(conversationWithBob[0].content, 'Message to Bob');
        expect(conversationWithBob[0].recipientId, user2.id);

        // Get conversation with user3
        final conversationWithCharlie =
            await appProvider.getConversation(user3.id);

        expect(conversationWithCharlie.length, 1);
        expect(conversationWithCharlie[0].content, 'Message to Charlie');
        expect(conversationWithCharlie[0].recipientId, user3.id);
      });

      test('Bi-directional conversation retrieval works', () async {
        // Send messages from both users
        await appProvider.sendMessage(user2.id, 'Alice to Bob');

        await StorageService.setCurrentUser(user2);
        await appProvider.initialize();
        await appProvider.sendMessage(user1.id, 'Bob to Alice');

        // Get conversation from user1's perspective
        await StorageService.setCurrentUser(user1);
        await appProvider.initialize();
        final conversationFromAlice =
            await appProvider.getConversation(user2.id);

        // Get conversation from user2's perspective
        await StorageService.setCurrentUser(user2);
        await appProvider.initialize();
        final conversationFromBob = await appProvider.getConversation(user1.id);

        // Both should see the same messages
        expect(conversationFromAlice.length, 2);
        expect(conversationFromBob.length, 2);
        expect(
            conversationFromAlice[0].content, conversationFromBob[0].content);
        expect(
            conversationFromAlice[1].content, conversationFromBob[1].content);
      });
    });

    group('Company Context in Messages', () {
      test('Messages can be associated with company context', () async {
        // Send message with company context
        await appProvider.sendMessage(
          user2.id,
          'Company message',
          companyId: testCompany.id,
        );

        // Retrieve message
        final messages = await StorageService.getMessagesForUser(user2.id);

        expect(messages.length, 1);
        expect(messages[0].companyId, testCompany.id);
      });

      test('Company users are filtered correctly for messaging', () async {
        // Create user in different company
        final otherCompany = Company(
          id: 'other_company',
          name: 'Other Company',
          address: '456 Other St',
          contactEmail: 'other@company.com',
          contactPhone: '555-0200',
          adminUserId: 'user3',
          createdAt: DateTime.now(),
        );

        final user3 = User(
          id: 'user3',
          name: 'Charlie Brown',
          email: 'charlie@test.com',
          role: UserRole.employee,
          createdAt: DateTime.now(),
          primaryCompanyId: otherCompany.id,
          companyIds: [otherCompany.id],
          companyRoles: {otherCompany.id: 'employee'},
        );

        await StorageService.addCompany(otherCompany);
        await StorageService.addUser(user3);

        // Get company users for user1
        final companyUsers = await appProvider.getCompanyUsers();

        // Should only include user2, not user3
        expect(companyUsers.length, 1);
        expect(companyUsers[0].id, user2.id);
        expect(companyUsers.any((u) => u.id == user3.id), false);
      });

      test('Messages without company context are still valid', () async {
        // Send message without company context
        await appProvider.sendMessage(user2.id, 'No company context');

        // Retrieve message
        final messages = await StorageService.getMessagesForUser(user2.id);

        expect(messages.length, 1);
        expect(messages[0].companyId, null);
        expect(messages[0].content, 'No company context');
      });
    });

    group('Edge Cases and Error Handling', () {
      test('Sending empty message is allowed', () async {
        // Send empty message
        await appProvider.sendMessage(user2.id, '');

        // Verify message was sent
        final messages = await StorageService.getMessagesForUser(user2.id);

        expect(messages.length, 1);
        expect(messages[0].content, '');
      });

      test('Sending message to self is allowed', () async {
        // Send message to self
        await appProvider.sendMessage(user1.id, 'Note to self');

        // Verify message
        final messages = await StorageService.getMessagesForUser(user1.id);

        expect(messages.length, 1);
        expect(messages[0].senderId, user1.id);
        expect(messages[0].recipientId, user1.id);
      });

      test('Message copyWith preserves all fields correctly', () async {
        final originalMessage = Message(
          id: 'msg1',
          senderId: user1.id,
          recipientId: user2.id,
          content: 'Test',
          timestamp: DateTime.now(),
          isRead: false,
          companyId: testCompany.id,
        );

        // Copy with read status change
        final updatedMessage = originalMessage.copyWith(isRead: true);

        expect(updatedMessage.id, originalMessage.id);
        expect(updatedMessage.senderId, originalMessage.senderId);
        expect(updatedMessage.recipientId, originalMessage.recipientId);
        expect(updatedMessage.content, originalMessage.content);
        expect(updatedMessage.timestamp, originalMessage.timestamp);
        expect(updatedMessage.isRead, true);
        expect(updatedMessage.companyId, originalMessage.companyId);
      });

      test('Message JSON serialization works correctly', () async {
        final message = Message(
          id: 'msg1',
          senderId: user1.id,
          recipientId: user2.id,
          content: 'Test message',
          timestamp: DateTime.now(),
          isRead: true,
          companyId: testCompany.id,
        );

        // Convert to JSON and back
        final json = message.toJson();
        final deserializedMessage = Message.fromJson(json);

        expect(deserializedMessage.id, message.id);
        expect(deserializedMessage.senderId, message.senderId);
        expect(deserializedMessage.recipientId, message.recipientId);
        expect(deserializedMessage.content, message.content);
        expect(deserializedMessage.isRead, message.isRead);
        expect(deserializedMessage.companyId, message.companyId);
        expect(
          deserializedMessage.timestamp.millisecondsSinceEpoch,
          message.timestamp.millisecondsSinceEpoch,
        );
      });
    });
  });
}
