import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:insta_image_viewer/insta_image_viewer.dart';
import 'package:wms/appUI.dart';
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
  

  @override
  void initState() {
    super.initState();
    
    checkEventCompletion();
  }

  @override
  void dispose() {
    
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
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Complete Event'),
          content: const Text(
            'Are you sure you want to mark this event as completed? This action cannot be undone.',
            style: AppTheme.bodyStyle,
          ),
          actions: [
            TextButton(
              child: Text(
                'Cancel',
                style: AppTheme.bodyStyle.copyWith(color: AppTheme.textSecondary),
              ),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Complete'),
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

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              content: Row(
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.mainOrange),
                  ),
                  const SizedBox(width: 20),
                  Text("Completing event...", style: AppTheme.bodyStyle),
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

      Navigator.pop(context);

      if (response.statusCode == 200) {
        if (context.mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                title: const Text('Success'),
                content: const Text(
                  'Event has been marked as completed successfully.',
                  style: AppTheme.bodyStyle,
                ),
                actions: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.mainOrange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('OK'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        }
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: const Text('Error'),
              content: const Text(
                'Failed to complete event. Please try again.',
                style: AppTheme.bodyStyle,
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.mainOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('OK'),
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
    return Theme(
      data: Theme.of(context).copyWith(
        primaryColor: AppTheme.mainOrange,
        scaffoldBackgroundColor: AppTheme.background,
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.mainOrange,
          elevation: 0,
          centerTitle: true,
          title: Column(
            children: [
              Text(
                widget.event['event_'],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                widget.event['start_date'].toString().substring(0, 10),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
          actions: [
            if (canCompleteEvent && !isLoading)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton.icon(
                  onPressed: completeEvent,
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: const Text('Complete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: RefreshIndicator(
          color: AppTheme.mainOrange,
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
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.mainOrange),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${snapshot.error}',
                            style: AppTheme.bodyStyle,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => setState(() {}),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.mainOrange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: jsonRes.length,
                    itemBuilder: (context, index) => _buildEventCard(index),
                  );
                },
              ),
              if (kDebugMode)
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Can Complete: $canCompleteEvent',
                          style: const TextStyle(color: Colors.white),
                        ),
                        Text(
                          'Event ID: ${widget.event['appl_id']}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoSection(index),
            const SizedBox(height: 16),
            _buildTaskButton(),
            if (images_length.isNotEmpty && images_length[0] > 0)
              _buildImageCarousel(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(
          'Application Date',
          widget.event["appln_date"].toString().substring(0, 10),
          icon: Icons.date_range,
        ),
        if (widget.event["description_"]?.toString() != 'null') ...[
          const SizedBox(height: 12),
          _buildInfoRow(
            'Description',
            widget.event["description_"],
            icon: Icons.description,
          ),
        ],
        const SizedBox(height: 12),
        _buildInfoRow(
          'Event Period',
          '${widget.event["start_date"].toString().substring(0, 10)} to ${widget.event["end_date"].toString().substring(0, 10)}',
          icon: Icons.event,
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
          'Population',
          widget.event["population"].toString(),
          icon: Icons.group,
        ),
        if (widget.event["budget"] == 'custom') ...[
          const SizedBox(height: 12),
          _buildInfoRow(
            'Budget',
            'Custom: ${widget.event["cus_low_budget"]}',
            icon: Icons.attach_money,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Custom Event',
            widget.event["cus_event"] ?? "N/A",
            icon: Icons.event_note,
          ),
        ],
        const SizedBox(height: 12),
        _buildInfoRow(
          'Venue',
          '${jsonRes[index]['venues_name']}, ${jsonRes[index]['location']}',
          icon: Icons.location_on,
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {IconData? icon}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 18,
            color: AppTheme.mainOrange,
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.bodyStyle.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTheme.subheadingStyle.copyWith(
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTaskButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ManagerTasks(
              id: widget.event["appl_id"],
              event: widget.event['event_'],
            ),
          ),
        ).then((_) => _onReturnFromTasks()),
        icon: const Icon(Icons.assignment, size: 20),
        label: const Text(
          "Check Tasks",
          style: TextStyle(fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.mainOrange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildImageCarousel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 20, bottom: 12),
          child: Text(
            'Event Images',
            style: AppTheme.headingStyle,
          ),
        ),
        CarouselSlider.builder(
          options: CarouselOptions(
            height: 300,
            enlargeCenterPage: true,
            enableInfiniteScroll: false,
            viewportFraction: 0.85,
            aspectRatio: 16 / 9,
            autoPlay: false,
            enlargeStrategy: CenterPageEnlargeStrategy.height,
          ),
          itemCount: images_length[0],
          itemBuilder: (context, i, pageViewIndex) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: InstaImageViewer(
                  child: Image.network(
                    'http://153.92.5.199:5000/images/appln/${widget.event['appl_id']}/${widget.event['appl_id']}_${i + 1}.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppTheme.paleOrange,
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: AppTheme.mainOrange,
                                size: 32,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Image not available',
                                style: AppTheme.bodyStyle,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.white,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.mainOrange,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}