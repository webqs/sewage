import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SendReportScreen extends StatefulWidget {
  const SendReportScreen({super.key});

  @override
  State<SendReportScreen> createState() => _SendReportScreenState();
}

class _SendReportScreenState extends State<SendReportScreen> {
  final supabase = Supabase.instance.client;
  final TextEditingController _controller = TextEditingController();

  bool sending = false;
  bool loadingDevices = true;

  String? selectedDevice;
  List<String> devices = [];

  @override
  void initState() {
    super.initState();
    fetchAssignedDevices();
  }

  /// 🔹 Fetch device_name from alerts where assigned_worker_id == current user
  Future<void> fetchAssignedDevices() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await supabase
          .from('alerts')
          .select('device_name')
          .eq('assigned_worker_id', user.id)
          .not('device_name', 'is', null)
          .order('device_name');

      devices = response
          .map<String>((e) => e['device_name'] as String)
          .toSet()
          .toList();
    } catch (e) {
      debugPrint('Error fetching devices: $e');
    }

    if (mounted) {
      setState(() => loadingDevices = false);
    }
  }

  Future<void> submitReport() async {
    if (selectedDevice == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select a device")));
      return;
    }

    if (_controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please write something in the report")),
      );
      return;
    }

    setState(() => sending = true);

    try {
      await supabase.from('report').insert({
        'reports': _controller.text.trim(),
        'device_name': selectedDevice,
      });

      _controller.clear();
      setState(() => selectedDevice = null);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Report sent successfully")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to send report: $e")));
    }

    if (mounted) setState(() => sending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Send Daily Report",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            /// 🔹 Device Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(.1), blurRadius: 6),
                ],
              ),
              child: loadingDevices
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedDevice,
                        hint: const Text("Select Assigned Device"),
                        isExpanded: true,
                        items: devices.map((device) {
                          return DropdownMenuItem(
                            value: device,
                            child: Text(device),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => selectedDevice = value);
                        },
                      ),
                    ),
            ),

            if (!loadingDevices && devices.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  "No devices assigned to you",
                  style: TextStyle(color: Colors.red),
                ),
              ),

            const SizedBox(height: 16),

            /// 🔹 Report Input
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(.1), blurRadius: 6),
                ],
              ),
              child: TextField(
                controller: _controller,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText:
                      "Describe your work progress, issues, observations...",
                  contentPadding: EdgeInsets.all(14),
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// 🔹 Send Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: sending ? null : submitReport,
                icon: sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(sending ? "Sending..." : "Send Report"),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
