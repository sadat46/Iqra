"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.updateFCMToken = exports.cleanupOldNotifications = exports.sendChatNotification = exports.sendNotification = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();
// Cloud Function to send FCM notifications when a notification document is created
exports.sendNotification = functions.firestore
    .document('notifications/{notificationId}')
    .onCreate(async (snap, context) => {
    try {
        const notificationData = snap.data();
        const { userId, title, body, data, status } = notificationData;
        if (status !== 'pending') {
            console.log('Notification status is not pending, skipping...');
            return;
        }
        // Get user's FCM token
        const userDoc = await db.collection('users').doc(userId).get();
        if (!userDoc.exists) {
            console.log('User document not found:', userId);
            await snap.ref.update({ status: 'failed', error: 'User not found' });
            return;
        }
        const userData = userDoc.data();
        const fcmToken = userData === null || userData === void 0 ? void 0 : userData.fcmToken;
        const notificationSettings = userData === null || userData === void 0 ? void 0 : userData.notificationSettings;
        if (!fcmToken) {
            console.log('FCM token not found for user:', userId);
            await snap.ref.update({ status: 'failed', error: 'FCM token not found' });
            return;
        }
        // Check if notifications are enabled for this user
        if (notificationSettings && notificationSettings.enabled === false) {
            console.log('Notifications disabled for user:', userId);
            await snap.ref.update({ status: 'skipped', reason: 'Notifications disabled' });
            return;
        }
        // Prepare notification payload
        const message = {
            token: fcmToken,
            notification: {
                title: title,
                body: body,
            },
            data: data || {},
            android: {
                notification: {
                    channelId: (data === null || data === void 0 ? void 0 : data.type) === 'chat' ? 'chat_channel' : 'general_channel',
                    sound: (notificationSettings === null || notificationSettings === void 0 ? void 0 : notificationSettings.sound) !== false ? 'default' : undefined,
                    priority: 'high',
                    defaultSound: true,
                    defaultVibrateTimings: (notificationSettings === null || notificationSettings === void 0 ? void 0 : notificationSettings.vibration) !== false,
                    defaultLightSettings: true,
                },
            },
            apns: {
                payload: {
                    aps: {
                        sound: (notificationSettings === null || notificationSettings === void 0 ? void 0 : notificationSettings.sound) !== false ? 'default' : undefined,
                        badge: (notificationSettings === null || notificationSettings === void 0 ? void 0 : notificationSettings.badge) !== false ? 1 : undefined,
                        alert: {
                            title: title,
                            body: body,
                        },
                    },
                },
            },
        };
        // Send the notification
        const response = await messaging.send(message);
        console.log('Successfully sent notification:', response);
        // Update notification status
        await snap.ref.update({
            status: 'sent',
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
            messageId: response,
        });
    }
    catch (error) {
        console.error('Error sending notification:', error);
        await snap.ref.update({
            status: 'failed',
            error: error instanceof Error ? error.message : 'Unknown error',
            failedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    }
});
// Cloud Function to send chat notifications when a message is created
exports.sendChatNotification = functions.firestore
    .document('messages/{messageId}')
    .onCreate(async (snap, context) => {
    try {
        const messageData = snap.data();
        const { chatId, senderId, text, type } = messageData;
        // Get chat participants
        const chatDoc = await db.collection('chats').doc(chatId).get();
        if (!chatDoc.exists) {
            console.log('Chat document not found:', chatId);
            return;
        }
        const chatData = chatDoc.data();
        const participants = (chatData === null || chatData === void 0 ? void 0 : chatData.participants) || [];
        // Get sender's user data
        const senderDoc = await db.collection('users').doc(senderId).get();
        let senderName = 'Unknown User';
        if (senderDoc.exists) {
            const senderData = senderDoc.data();
            senderName = (senderData === null || senderData === void 0 ? void 0 : senderData.displayName) || (senderData === null || senderData === void 0 ? void 0 : senderData.name) || 'Unknown User';
        }
        // Send notifications to all participants except the sender
        for (const participantId of participants) {
            if (participantId === senderId)
                continue;
            // Check if user has notifications enabled
            const userDoc = await db.collection('users').doc(participantId).get();
            if (!userDoc.exists)
                continue;
            const userData = userDoc.data();
            const notificationSettings = userData === null || userData === void 0 ? void 0 : userData.notificationSettings;
            if (notificationSettings && notificationSettings.enabled === false) {
                console.log('Notifications disabled for user:', participantId);
                continue;
            }
            // Create notification document
            const notificationTitle = senderName;
            const notificationBody = type === 'image' ? '📷 Sent you an image' : text;
            await db.collection('notifications').add({
                userId: participantId,
                title: notificationTitle,
                body: notificationBody,
                data: {
                    type: 'chat',
                    chatId: chatId,
                    senderId: senderId,
                    messageType: type,
                    messageId: snap.id,
                },
                status: 'pending',
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        }
    }
    catch (error) {
        console.error('Error sending chat notification:', error);
    }
});
// Cloud Function to clean up old notifications
exports.cleanupOldNotifications = functions.pubsub
    .schedule('every 24 hours')
    .onRun(async (context) => {
    try {
        const cutoffDate = new Date();
        cutoffDate.setDate(cutoffDate.getDate() - 7); // Keep notifications for 7 days
        const batch = db.batch();
        const oldNotifications = await db
            .collection('notifications')
            .where('createdAt', '<', cutoffDate)
            .get();
        oldNotifications.docs.forEach((doc) => {
            batch.delete(doc.ref);
        });
        await batch.commit();
        console.log(`Cleaned up ${oldNotifications.docs.length} old notifications`);
    }
    catch (error) {
        console.error('Error cleaning up old notifications:', error);
    }
});
// Cloud Function to update FCM token when user logs in
exports.updateFCMToken = functions.firestore
    .document('users/{userId}')
    .onUpdate(async (change, context) => {
    try {
        const beforeData = change.before.data();
        const afterData = change.after.data();
        const userId = context.params.userId;
        const beforeToken = beforeData === null || beforeData === void 0 ? void 0 : beforeData.fcmToken;
        const afterToken = afterData === null || afterData === void 0 ? void 0 : afterData.fcmToken;
        // If FCM token was updated
        if (beforeToken !== afterToken && afterToken) {
            console.log(`FCM token updated for user: ${userId}`);
            // You can add additional logic here, such as:
            // - Subscribing to topics
            // - Updating user's online status
            // - Sending welcome notification
        }
    }
    catch (error) {
        console.error('Error updating FCM token:', error);
    }
});
//# sourceMappingURL=index.js.map