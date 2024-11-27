
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:insta_image_viewer/insta_image_viewer.dart';
import 'package:wms/managerTasks.dart';

class ManagerEvent extends StatefulWidget {
  final dynamic event;

  const ManagerEvent({Key? key, required this.event}) : super(key: key);

  @override
  State<ManagerEvent> createState() => _ManagerEventState();
}

class _ManagerEventState extends State<ManagerEvent> {
  List<dynamic> jsonRes = [];
  List<dynamic> images_length = [];
  bool canCompleteEvent = false;
  bool isLoading = false;
  Timer? _checkTimer;

  @override
  void initState() {
    super.initState();
    checkEventCompletion();
    // Set up periodic check
    _checkTimer = Timer.periodic(Duration(seconds: 5), (_) {
      if (mounted) {
        checkEventCompletion();
      }
    });
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }

  Future<void> checkEventCompletion() async {
    try {
      final url = 'http://153.92.5.199:5000/checkAllTasksComplete?appl_id=${widget.event['appl_id']}';
      final response = await http.get(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        log('Completion check response: ${response.body}');
        if (mounted) {
          setState(() {
            canCompleteEvent = data['canComplete'] ?? false;
          });
        }
      }
    } catch (e) {
      log('Error checking event completion: $e');
    }
  }

  Future<bool> showConfirmationDialog() async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Complete Event'),
          content: Text('Are you sure you want to mark this event as completed? This action cannot be undone.'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              child: Text('Complete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    ) ?? false;
  }

  Future<void> completeEvent() async {
    final shouldComplete = await showConfirmationDialog();
    if (!shouldComplete) return;

    try {
      setState(() {
        isLoading = true;
      });

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          // ignore: deprecated_member_use
          return WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text("Completing event..."),
                ],
              ),
            ),
          );
        },
      );

      final response = await http.post(
        Uri.parse('http://153.92.5.199:5000/completeEvent'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"appl_id": widget.event['appl_id']}),
      );

      // Close loading dialog
      Navigator.pop(context);

      if (response.statusCode == 200) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Success'),
              content: Text('Event has been marked as completed successfully.'),
              actions: [
                ElevatedButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop(); // Return to previous screen
                  },
                ),
              ],
            );
          },
        );
      } else {
        throw Exception('Failed to complete event');
      }
    } catch (e) {
      log('Error completing event: $e');
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text('Failed to complete event. Please try again.'),
              actions: [
                ElevatedButton(
                  child: Text('OK'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            );
          },
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<List<dynamic>> venue() async {
    try {
      final url = 'http://153.92.5.199:5000/venue?id=${widget.event['venue_id']}';
      final response = await http.get(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        jsonRes = data['data'];

        final imgurl = 'http://153.92.5.199:5000/managerView?appl_id=${widget.event['appl_id']}';
        final imgResponse = await http.get(
          Uri.parse(imgurl),
          headers: {"Content-Type": "application/json"},
        );

        if (imgResponse.statusCode == 200) {
          final imgData = jsonDecode(imgResponse.body);
          images_length = [imgData['data']];
          return images_length;
        }
      }
      throw Exception('Failed to load data');
    } catch (e) {
      log('Error in venue(): $e');
      rethrow;
    }
  }

  void _onReturnFromTasks() async {
    await checkEventCompletion();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Event: ${widget.event['event_']} (${widget.event['start_date'].toString().substring(0, 10)})',
        ),
        actions: [
          if (canCompleteEvent && !isLoading)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: ElevatedButton.icon(
                onPressed: completeEvent,
                icon: Icon(Icons.check_circle),
                label: Text('Complete Event'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await venue();
          await checkEventCompletion();
          setState(() {});
        },
        child: Stack(
          children: [
            FutureBuilder<List<dynamic>>(
              future: venue(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red),
                        SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: jsonRes.length,
                  itemBuilder: (context, index) => _buildEventCard(index),
                );
              },
            ),
            // Debug overlay
            if (kDebugMode)
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  padding: EdgeInsets.all(8),
                  color: Colors.black54,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Can Complete: $canCompleteEvent',
                        style: TextStyle(color: Colors.white),
                      ),
                      Text(
                        'Event ID: ${widget.event['appl_id']}',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(int index) {
    return Card(
      margin: EdgeInsets.all(8),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Application Date: ${widget.event["appln_date"].toString().substring(0, 10)}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (widget.event["description_"]?.toString() != 'null') ...[
              SizedBox(height: 15.0),
              Text('Description: ${widget.event["description_"]}'),
            ],
            SizedBox(height: 10.0),
            Text('Start Date: ${widget.event["start_date"].toString().substring(0, 10)}'),
            SizedBox(height: 10.0),
            Text('End Date: ${widget.event["end_date"].toString().substring(0, 10)}'),
            SizedBox(height: 10.0),
            Text('Population: ${widget.event["population"]}'),
            SizedBox(height: 10.0),
            if (widget.event["budget"] == 'custom') ...[
              Text('Custom Low Budget: ${widget.event["cus_low_budget"]}'),
              SizedBox(height: 10.0),
              Text('Custom Event: ${widget.event["cus_event"] ?? "N/A"}'),
              SizedBox(height: 10.0),
            ],
            Text('Venue: ${jsonRes[index]['venues_name']}, ${jsonRes[index]['location']}'),
            SizedBox(height: 16.0),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ManagerTasks(
                    id: widget.event["appl_id"],
                    event: widget.event['event_'],
                  ),
                ),
              ).then((_) => _onReturnFromTasks()),
              icon: Icon(Icons.assignment),
              label: Text("Check Tasks"),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
            if (images_length.isNotEmpty && images_length[0] > 0) ...[
              SizedBox(height: 20.0),
              CarouselSlider.builder(
                options: CarouselOptions(
                  height: 300.0,
                  enlargeCenterPage: true,
                  enableInfiniteScroll: false,
                ),
                itemCount: images_length[0],
                itemBuilder: (context, i, pageViewIndex) {
                  return InstaImageViewer(
                    child: Image.network(
                      'http://153.92.5.199:5000/images/appln/${widget.event['appl_id']}/${widget.event['appl_id']}_${i + 1}.png',
                      width: MediaQuery.of(context).size.width,
                      height: 200,
                      errorBuilder: (context, error, stackTrace) => Text('Error Loading'),
                      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                        return Padding(
                          padding: EdgeInsets.all(4.0),
                          child: child,
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
