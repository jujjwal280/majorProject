import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Map<String, String>> _notifications = [];

  @override
  void initState() {
    super.initState();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      setState(() {
        _notifications.add({
          "title": message.notification?.title ?? "No Title",
          "body": message.notification?.body ?? "No Body",
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Notifications")),
      body: _notifications.isEmpty
          ? Center(child: Text("No Notifications Yet"))
          : ListView.builder(
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_notifications[index]["title"]!),
            subtitle: Text(_notifications[index]["body"]!),
          );
        },
      ),
    );
  }
}
