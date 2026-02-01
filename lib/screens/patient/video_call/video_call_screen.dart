import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/video_call_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

class VideoCallScreen extends ConsumerStatefulWidget {
  final String callId;
  final String doctorId;
  final String doctorName;
  final CallType callType;
  final bool isIncoming;

  const VideoCallScreen({
    super.key,
    required this.callId,
    required this.doctorId,
    required this.doctorName,
    required this.callType,
    this.isIncoming = false,
  });

  @override
  ConsumerState<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends ConsumerState<VideoCallScreen> {
  // Agora App ID - Replace with your own
  static const String appId = "YOUR_AGORA_APP_ID";
  
  final _patientId = FirebaseAuth.instance.currentUser?.uid ?? '';
  RtcEngine? _engine;
  bool _isJoined = false;
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isSpeakerOn = true;
  bool _isFrontCamera = true;
  int? _remoteUid;
  DateTime? _callStartTime;
  String _callDuration = '00:00';
  bool _isConnecting = true;

  @override
  void initState() {
    super.initState();
    _initAgora();
    _updateCallStatus();
  }

  Future<void> _initAgora() async {
    // Request permissions
    await [Permission.camera, Permission.microphone].request();

    // Create engine
    _engine = createAgoraRtcEngine();
    await _engine!.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    _engine!.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        setState(() {
          _isJoined = true;
          _isConnecting = false;
          _callStartTime = DateTime.now();
        });
        _startTimer();
      },
      onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
        setState(() => _remoteUid = remoteUid);
      },
      onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
        setState(() => _remoteUid = null);
        _endCall();
      },
      onError: (ErrorCodeType err, String msg) {
        debugPrint('Agora Error: $err - $msg');
      },
    ));

    if (widget.callType == CallType.video) {
      await _engine!.enableVideo();
      await _engine!.startPreview();
    }

    // Join channel
    await _engine!.joinChannel(
      token: '', // Use token for production
      channelId: widget.callId,
      uid: _patientId.hashCode,
      options: ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );
  }

  void _updateCallStatus() async {
    await FirebaseFirestore.instance
        .collection('video_calls')
        .doc(widget.callId)
        .update({
      'status': CallStatus.ongoing.name,
      'actualStartTime': FieldValue.serverTimestamp(),
    });
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      
      final duration = DateTime.now().difference(_callStartTime!);
      setState(() {
        _callDuration = _formatDuration(duration);
      });
      return _isJoined;
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (duration.inHours > 0) {
      final hours = duration.inHours.toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Remote video (full screen)
            if (widget.callType == CallType.video)
              _remoteUid != null
                  ? AgoraVideoView(
                      controller: VideoViewController.remote(
                        rtcEngine: _engine!,
                        canvas: VideoCanvas(uid: _remoteUid),
                        connection: RtcConnection(channelId: widget.callId),
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                            child: const Icon(
                              Icons.person,
                              size: 60,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Dr. ${widget.doctorName}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isConnecting ? 'Connecting...' : 'Waiting for doctor to join...',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                        ],
                      ),
                    )
            else
              // Audio call view
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primaryColor,
                          width: 3,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 70,
                        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                        child: const Icon(
                          Icons.person,
                          size: 70,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Dr. ${widget.doctorName}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isConnecting 
                          ? 'Connecting...' 
                          : _remoteUid == null 
                              ? 'Calling...'
                              : _callDuration,
                      style: TextStyle(
                        color: _remoteUid != null ? Colors.green : Colors.grey[400],
                        fontSize: 18,
                      ),
                    ),
                    if (_remoteUid != null) ...[
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.phone_in_talk, color: Colors.green),
                            SizedBox(width: 8),
                            Text(
                              'Connected',
                              style: TextStyle(color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            // Local video (small preview)
            if (widget.callType == CallType.video && _isVideoEnabled)
              Positioned(
                top: 20,
                right: 20,
                child: GestureDetector(
                  onTap: _switchCamera,
                  child: Container(
                    width: 120,
                    height: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: AgoraVideoView(
                        controller: VideoViewController(
                          rtcEngine: _engine!,
                          canvas: const VideoCanvas(uid: 0),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Call duration
            if (_isJoined && widget.callType == CallType.video)
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _callDuration,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),

            // Controls
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  // Secondary controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildControlButton(
                        icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                        label: 'Speaker',
                        onPressed: _toggleSpeaker,
                        isActive: _isSpeakerOn,
                      ),
                      const SizedBox(width: 20),
                      if (widget.callType == CallType.video)
                        _buildControlButton(
                          icon: Icons.cameraswitch,
                          label: 'Flip',
                          onPressed: _switchCamera,
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Main controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildMainControlButton(
                        icon: _isMuted ? Icons.mic_off : Icons.mic,
                        color: _isMuted ? Colors.red : Colors.white,
                        backgroundColor: _isMuted ? Colors.white : Colors.grey[800]!,
                        onPressed: _toggleMute,
                      ),
                      const SizedBox(width: 20),
                      _buildMainControlButton(
                        icon: Icons.call_end,
                        color: Colors.white,
                        backgroundColor: Colors.red,
                        onPressed: _endCall,
                        size: 70,
                      ),
                      const SizedBox(width: 20),
                      if (widget.callType == CallType.video)
                        _buildMainControlButton(
                          icon: _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                          color: _isVideoEnabled ? Colors.white : Colors.red,
                          backgroundColor: _isVideoEnabled ? Colors.grey[800]! : Colors.white,
                          onPressed: _toggleVideo,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.grey[800],
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              icon,
              color: isActive ? Colors.black : Colors.white,
            ),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.grey[400], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildMainControlButton({
    required IconData icon,
    required Color color,
    required Color backgroundColor,
    required VoidCallback onPressed,
    double size = 56,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: size * 0.5),
      ),
    );
  }

  void _toggleMute() async {
    setState(() => _isMuted = !_isMuted);
    await _engine?.muteLocalAudioStream(_isMuted);
  }

  void _toggleVideo() async {
    setState(() => _isVideoEnabled = !_isVideoEnabled);
    await _engine?.muteLocalVideoStream(!_isVideoEnabled);
  }

  void _toggleSpeaker() async {
    setState(() => _isSpeakerOn = !_isSpeakerOn);
    await _engine?.setEnableSpeakerphone(_isSpeakerOn);
  }

  void _switchCamera() async {
    setState(() => _isFrontCamera = !_isFrontCamera);
    await _engine?.switchCamera();
  }

  void _endCall() async {
    // Update call status in Firestore
    final duration = _callStartTime != null
        ? DateTime.now().difference(_callStartTime!).inSeconds
        : 0;

    await FirebaseFirestore.instance
        .collection('video_calls')
        .doc(widget.callId)
        .update({
      'status': CallStatus.completed.name,
      'endTime': FieldValue.serverTimestamp(),
      'duration': duration,
    });

    await _engine?.leaveChannel();
    
    if (mounted) {
      Navigator.pop(context);
    }
  }
}

// Simple screen to initiate calls
class InitiateCallScreen extends ConsumerStatefulWidget {
  final String doctorId;
  final String doctorName;
  final String? appointmentId;

  const InitiateCallScreen({
    super.key,
    required this.doctorId,
    required this.doctorName,
    this.appointmentId,
  });

  @override
  ConsumerState<InitiateCallScreen> createState() => _InitiateCallScreenState();
}

class _InitiateCallScreenState extends ConsumerState<InitiateCallScreen> {
  final _patientId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Start Consultation'),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              child: const Icon(
                Icons.person,
                size: 60,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Dr. ${widget.doctorName}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose consultation type',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCallTypeButton(
                  icon: Icons.videocam,
                  label: 'Video Call',
                  color: AppTheme.primaryColor,
                  onTap: () => _startCall(CallType.video),
                ),
                const SizedBox(width: 32),
                _buildCallTypeButton(
                  icon: Icons.phone,
                  label: 'Voice Call',
                  color: Colors.green,
                  onTap: () => _startCall(CallType.audio),
                ),
              ],
            ),
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Make sure you have a stable internet connection for the best experience.',
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallTypeButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _startCall(CallType callType) async {
    try {
      // Get patient name
      final userDoc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(_patientId)
          .get();
      final patientName = userDoc.data()?['name'] ?? 'Patient';

      // Create call document
      final callDoc = await FirebaseFirestore.instance
          .collection('video_calls')
          .add({
        'patientId': _patientId,
        'patientName': patientName,
        'doctorId': widget.doctorId,
        'doctorName': widget.doctorName,
        'callType': callType.name,
        'status': CallStatus.pending.name,
        'appointmentId': widget.appointmentId,
        'scheduledTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VideoCallScreen(
              callId: callDoc.id,
              doctorId: widget.doctorId,
              doctorName: widget.doctorName,
              callType: callType,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting call: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
