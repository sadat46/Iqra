import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _badgeEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    try {
      final settings = await _notificationService.getNotificationSettings();
      if (settings != null) {
        setState(() {
          _notificationsEnabled = settings['enabled'] ?? true;
          _soundEnabled = settings['sound'] ?? true;
          _vibrationEnabled = settings['vibration'] ?? true;
          _badgeEnabled = settings['badge'] ?? true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading notification settings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateNotificationSettings() async {
    try {
      await _notificationService.updateNotificationSettings(
        enabled: _notificationsEnabled,
        sound: _soundEnabled,
        vibration: _vibrationEnabled,
        badge: _badgeEnabled,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification settings updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating notification settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main notification toggle
                  Card(
                    elevation: 2,
                    child: SwitchListTile(
                      title: const Text(
                        'Enable Notifications',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: const Text(
                        'Receive push notifications for new messages',
                      ),
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _notificationsEnabled = value;
                          // If notifications are disabled, disable all other options
                          if (!value) {
                            _soundEnabled = false;
                            _vibrationEnabled = false;
                            _badgeEnabled = false;
                          }
                        });
                        _updateNotificationSettings();
                      },
                      activeColor: Colors.blue,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Notification options (only shown if notifications are enabled)
                  if (_notificationsEnabled) ...[
                    const Text(
                      'Notification Options',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Sound toggle
                    Card(
                      elevation: 1,
                      child: SwitchListTile(
                        title: const Text('Sound'),
                        subtitle: const Text('Play sound for notifications'),
                        value: _soundEnabled,
                        onChanged: (value) {
                          setState(() {
                            _soundEnabled = value;
                          });
                          _updateNotificationSettings();
                        },
                        activeColor: Colors.blue,
                        secondary: const Icon(Icons.volume_up, color: Colors.blue),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Vibration toggle
                    Card(
                      elevation: 1,
                      child: SwitchListTile(
                        title: const Text('Vibration'),
                        subtitle: const Text('Vibrate device for notifications'),
                        value: _vibrationEnabled,
                        onChanged: (value) {
                          setState(() {
                            _vibrationEnabled = value;
                          });
                          _updateNotificationSettings();
                        },
                        activeColor: Colors.blue,
                        secondary: const Icon(Icons.vibration, color: Colors.blue),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Badge toggle
                    Card(
                      elevation: 1,
                      child: SwitchListTile(
                        title: const Text('Badge'),
                        subtitle: const Text('Show notification badge on app icon'),
                        value: _badgeEnabled,
                        onChanged: (value) {
                          setState(() {
                            _badgeEnabled = value;
                          });
                          _updateNotificationSettings();
                        },
                        activeColor: Colors.blue,
                        secondary: const Icon(Icons.badge, color: Colors.blue),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Information section
                  Card(
                    elevation: 1,
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Notification Information',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '• Notifications are sent when you receive new messages\n'
                            '• You can customize how notifications appear\n'
                            '• Settings are saved to your account\n'
                            '• You can change these settings anytime',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Test notification button
                  if (_notificationsEnabled)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            await _notificationService.sendTestNotification();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Test notification sent!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error sending test notification: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.notifications),
                        label: const Text('Send Test Notification'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
} 