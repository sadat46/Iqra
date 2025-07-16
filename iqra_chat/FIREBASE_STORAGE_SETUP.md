# Firebase Storage Setup Guide

## Setting Up Firebase Storage Rules

### 1. Deploy Storage Rules

1. **Go to Firebase Console**
   - Navigate to your Firebase project
   - Go to Storage section
   - Click on "Rules" tab

2. **Copy and Paste Rules**
   - Replace the existing rules with the content from `firebase_storage_rules.rules`
   - Click "Publish" to deploy the rules

### 2. Rules Explanation

The storage rules implement the following security measures:

#### **Chat Images (`/chat_images/{chatId}/{imageName}`)**
- ✅ **Read Access**: Any authenticated user can view images
- ✅ **Write Access**: Only chat participants can upload images
- ✅ **File Size Limit**: Maximum 10MB per image
- ✅ **File Type Restriction**: Only image files (JPEG, PNG, GIF)
- ✅ **Chat Validation**: Verifies user is a participant in the chat

#### **Profile Pictures (`/profile_pictures/{userId}/{imageName}`)**
- ✅ **Read Access**: Any authenticated user can view profile pictures
- ✅ **Write Access**: Users can only upload to their own folder
- ✅ **File Size Limit**: Maximum 5MB for profile pictures
- ✅ **File Type Restriction**: Only image files

#### **Security Features**
- 🔒 **Authentication Required**: All operations require user authentication
- 🛡️ **Path Validation**: Checks Firestore database for chat participation
- 📏 **Size Limits**: Prevents abuse with large file uploads
- 🎯 **Type Restrictions**: Only allows image file types
- 🚫 **Deny All**: Blocks access to all other paths

### 3. Testing the Rules

After deploying the rules, test the following scenarios:

1. **Valid Upload**: User uploads image to their chat ✅
2. **Invalid Upload**: User tries to upload to someone else's chat ❌
3. **Large File**: User tries to upload >10MB file ❌
4. **Wrong File Type**: User tries to upload non-image file ❌
5. **Unauthenticated**: Anonymous user tries to upload ❌

### 4. Monitoring Usage

Monitor your Firebase Storage usage in the Firebase Console:
- **Storage Tab**: View total storage used
- **Usage Tab**: Monitor bandwidth and operations
- **Rules Tab**: View rule evaluation logs

### 5. Cost Optimization

The implemented rules help control costs by:
- Limiting file sizes (10MB max for chat images)
- Restricting file types (images only)
- Preventing unauthorized uploads
- Enabling automatic image compression in the app

### 6. Troubleshooting

If you encounter issues:

1. **Check Authentication**: Ensure user is properly authenticated
2. **Verify Chat Participation**: Confirm user is in the chat participants list
3. **File Size**: Ensure image is under 10MB
4. **File Type**: Ensure file is an image (JPEG, PNG, GIF)
5. **Rules Deployment**: Verify rules are published successfully

### 7. Customization

You can modify the rules based on your needs:

- **Change Size Limits**: Modify the `10 * 1024 * 1024` value
- **Add File Types**: Update the `image/.*` regex
- **Add User Roles**: Implement role-based access control
- **Add Rate Limiting**: Implement upload frequency limits 