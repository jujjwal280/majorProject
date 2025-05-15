import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationScreen extends StatelessWidget {
  final List<Map<String, String>> notifications = [
    {
      "message": "Updates are available! Update your app to access more functionality.",
      "url": "https://drive.google.com/drive/folders/1GJ07mHcpegXa4DPTPsu2kH72vDwaBnyA?usp=sharing",
    },
    {
      "message": "Check out us on our website!",
      "url": "https://example.com/features",
    },
  ];

  NotificationScreen({super.key});

  void _launchURL(BuildContext context, String url) async {
    if (await canLaunchUrl(url as Uri)) {
      launchUrl;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Could not open the link. Please try again."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.notification_important_rounded,
                      color: Color(0xFFF27F0C),
                      size: 30,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        notification["message"] ?? "",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () => _launchURL(context, notification["url"] ?? ""),
                    icon: const Icon(Icons.download_rounded, color: Colors.redAccent),
                    label: const Text(
                      ' Open  ',
                      style: TextStyle(fontSize: 14, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        backgroundColor: const Color(0xFF053F5C),
                        minimumSize: const Size(100, 40)
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}