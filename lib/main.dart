import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard functionality
import 'package:http/http.dart' as http;
import 'dart:async'; // For Timer

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ZoomMeetingScreen(),
    );
  }
}

class ZoomMeetingScreen extends StatefulWidget {
  @override
  _ZoomMeetingScreenState createState() => _ZoomMeetingScreenState();
}

class _ZoomMeetingScreenState extends State<ZoomMeetingScreen> {
  String _meetingLink = '';
  bool _isLoading = false; // To track the loading state
  String accessToken = ''; // Access token will be updated automatically
  Timer? _tokenRefreshTimer;

  // Controllers to get user input
  final TextEditingController topicController = TextEditingController();
  final TextEditingController startTimeController = TextEditingController();
  final TextEditingController durationController = TextEditingController();

  bool hostVideo = true;
  bool participantVideo = true;

  @override
  void initState() {
    super.initState();
    refreshAccessToken(); // Fetch token when the app starts
  }

  // Function to refresh the access token
  Future<void> refreshAccessToken() async {
    const String clientId = 'vPeTHpMASCiuQo19LAJPoQ'; // Replace with your Client ID
    const String clientSecret = 'UuyciEXHG5PmURMkmzTNq3WApsoo3h5U'; // Replace with your Client Secret
    const String accountId = 'ywkC-LmpSqOYpYnYuX3iOw'; // Replace with your Account ID
    final String credentials = base64Encode(utf8.encode('$clientId:$clientSecret'));

    // URL for Server-to-Server OAuth
    final Uri url = Uri.parse('https://zoom.us/oauth/token?grant_type=account_credentials&account_id=$accountId');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Basic $credentials',  // Use the base64 encoded Client ID and Client Secret
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final newAccessToken = data['access_token'];
      setState(() {
        accessToken = newAccessToken;
      });
      print('New Access Token: $accessToken');
    } else {
      print('Error fetching access token: ${response.statusCode}');
      print('Response: ${response.body}');
    }
  }

  // Function to create Zoom meeting
  Future<void> createZoomMeeting() async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    final Uri url = Uri.parse('http://localhost:3000/create-meeting'); // Update with your server's address

    final Map<String, dynamic> requestBody = {
      "topic": topicController.text, // Use user-input for the meeting topic
      "type": 2, // Scheduled meeting
      "start_time": DateTime.parse(startTimeController.text).toUtc().toIso8601String(), // Use user-input for start time
      "duration": int.parse(durationController.text), // Use user-input for meeting duration
      "timezone": "UTC", // Timezone
      "settings": {
        "host_video": hostVideo, // Use user-input for host video
        "participant_video": participantVideo, // Use user-input for participant video
      }
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json', // Ensure content type is set
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() {
          _meetingLink = data['join_url']; // Get join URL from response
          _isLoading = false; // Hide loading indicator
        });
        print("Meeting link: $_meetingLink");
      } else {
        setState(() {
          _isLoading = false; // Hide loading indicator on error
        });
        print('Error creating meeting: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error: $e');
    }
  }

  // Function to copy the meeting link to clipboard
  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _meetingLink));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Meeting link copied to clipboard!')),
    );
  }

  @override
  void dispose() {
    _tokenRefreshTimer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Zoom Meeting Scheduler'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // User input for meeting topic
                TextField(
                  controller: topicController,
                  decoration: InputDecoration(labelText: 'Meeting Topic'),
                ),
                SizedBox(height: 10),
                
                // User input for start time with hint
                TextField(
                  controller: startTimeController,
                  decoration: InputDecoration(
                    labelText: 'Start Time',
                    hintText: 'YYYY-MM-DDTHH:MM:SS', // Provide a hint for start time format
                  ),
                ),
                SizedBox(height: 10),

                // User input for duration
                TextField(
                  controller: durationController,
                  decoration: InputDecoration(labelText: 'Duration (minutes)'),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 10),

                // User input for host video
                Row(
                  children: [
                    Text('Host Video:'),
                    Switch(
                      value: hostVideo,
                      onChanged: (value) {
                        setState(() {
                          hostVideo = value;
                        });
                      },
                    ),
                  ],
                ),

                // User input for participant video
                Row(
                  children: [
                    Text('Participant Video:'),
                    Switch(
                      value: participantVideo,
                      onChanged: (value) {
                        setState(() {
                          participantVideo = value;
                        });
                      },
                    ),
                  ],
                ),

                SizedBox(height: 20),

                // Show CircularProgressIndicator when loading
                if (_isLoading)
                  CircularProgressIndicator()
                else
                  ElevatedButton(
                    onPressed: createZoomMeeting,
                    child: Text('Create Meeting'),
                  ),
                SizedBox(height: 20),
                
                // Show the meeting link if available and add option to copy it
                if (_meetingLink.isNotEmpty)
                  Column(
                    children: [
                      Text(
                        'Meeting Link: $_meetingLink',
                        style: TextStyle(color: Colors.blue),
                        textAlign: TextAlign.center,
                      ),
                      ElevatedButton(
                        onPressed: _copyToClipboard,
                        child: Text('Copy Link'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
