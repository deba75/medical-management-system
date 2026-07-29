import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/chatbot_service.dart';
import '../../../core/services/pdf_generator_service.dart';
import '../../../models/doctor_model.dart';
import '../doctors/search_doctors_screen.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatbotService _chatbot = ChatbotService.instance;
  
  bool _isLoading = false;
  bool _isInitializing = true;
  List<DoctorModel> _availableDoctors = [];  // Store fetched doctors for booking

  @override
  void initState() {
    super.initState();
    _initializeChatbot();
  }

  Future<void> _initializeChatbot() async {
    await _chatbot.initialize();
    if (_chatbot.messages.isEmpty) {
      _chatbot.getGreeting();
    }
    if (mounted) {
      setState(() => _isInitializing = false);
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    _messageController.clear();
    setState(() => _isLoading = true);
    _scrollToBottom();

    // Check if user wants to book an appointment - fetch doctors for selection
    final lowerMessage = message.toLowerCase();
    if (lowerMessage.contains('book') || lowerMessage.contains('appointment') || 
        lowerMessage.contains('doctor') || lowerMessage.contains('find')) {
      final doctors = await _chatbot.getAllDoctors();
      if (doctors.isNotEmpty) {
        setState(() => _availableDoctors = doctors);
      }
    }

    await _chatbot.sendMessage(message);

    if (mounted) {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _selectDoctorForInChatBooking(DoctorModel doctor) {
    _chatbot.setBookingDoctor(doctor.doctorId, doctor.name, doctor.specialization);
    _chatbot.setBookingHospital(doctor.hospitals.isNotEmpty ? doctor.hospitals.first : 'City General Hospital');
    _chatbot.setBookingDate(DateTime.now());
    _chatbot.setBookingTimeSlot('10:00 AM');
    _chatbot.setAwaitingConfirmation(true);

    _messageController.text = 'Confirm booking with Dr. ${doctor.name} for 10:00 AM today';
    _sendMessage();
  }

  void _navigateToSearchDoctors() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SearchDoctorsScreen(),
      ),
    );
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text('Are you sure you want to clear the chat history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _chatbot.clearHistory();
              _chatbot.getGreeting();
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2,
        shadowColor: AppTheme.primaryColor.withOpacity(0.2),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MediBot',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'AI Health Assistant',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              onPressed: _clearChat,
              tooltip: 'Clear chat',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Disclaimer Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.amber.shade200),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.info_outline, color: Colors.amber.shade800, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'For guidance only. Please consult a doctor for medical advice.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Chat Messages
          Expanded(
            child: _isInitializing
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppTheme.primaryColor),
                        const SizedBox(height: 16),
                        Text(
                          'Initializing MediBot...',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _chatbot.messages.length + (_isLoading ? 1 : 0) + (_availableDoctors.isNotEmpty ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Show typing indicator at the end
                      if (_isLoading && index == _chatbot.messages.length + (_availableDoctors.isNotEmpty ? 1 : 0)) {
                        return _buildTypingIndicator();
                      }
                      
                      // Show doctor cards after messages
                      if (_availableDoctors.isNotEmpty && index == _chatbot.messages.length) {
                        return _buildDoctorCards();
                      }
                      
                      final message = _chatbot.messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
          ),
          
          // Quick Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickAction('🤒 I have a fever', 'I have a fever'),
                  _buildQuickAction('🤕 Headache', 'I have a headache'),
                  _buildQuickActionWithNav('📅 Book Now', _navigateToSearchDoctors),
                  _buildQuickAction('🏥 Find Doctor', 'Help me find a doctor'),
                  _buildQuickAction('🚑 Emergency', 'This is an emergency'),
                  _buildQuickAction('💊 First Aid', 'Give me first aid tips'),
                ],
              ),
            ),
          ),
          
          // Message Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Describe your symptoms...',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isLoading ? null : _sendMessage,
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            _isLoading ? Icons.hourglass_empty : Icons.send_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMessageText(String text) {
    if (text.isEmpty) return text;
    String formatted = text;
    // Replace **Heading:** or **Text** with bullet points
    formatted = formatted.replaceAllMapped(RegExp(r'\*\*([^*]+)\*\*'), (match) {
      final title = match.group(1)?.trim() ?? '';
      if (title.startsWith('•')) return title;
      return '• $title';
    });
    // Remove double bullet markers if present
    formatted = formatted.replaceAll('• •', '•');
    return formatted;
  }

  Widget _buildFormattedMessageText(String rawText, bool isUser) {
    final textColor = isUser ? Colors.white : Colors.black87;
    final text = _formatMessageText(rawText);
    final lines = text.split('\n');

    final spans = <TextSpan>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();

      bool isHeader = false;
      if (trimmed.startsWith('•') && (trimmed.endsWith(':') || trimmed.contains(': '))) {
        isHeader = true;
      }

      if (isHeader) {
        if (trimmed.contains(': ') && !trimmed.endsWith(':')) {
          final colonIndex = line.indexOf(': ');
          final headerPart = line.substring(0, colonIndex + 2);
          final restPart = line.substring(colonIndex + 2);

          spans.add(TextSpan(
            text: headerPart,
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ));
          spans.add(TextSpan(
            text: restPart,
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.normal,
              height: 1.4,
            ),
          ));
        } else {
          spans.add(TextSpan(
            text: line,
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ));
        }
      } else {
        spans.add(TextSpan(
          text: line,
          style: TextStyle(
            color: textColor,
            fontSize: 15,
            fontWeight: FontWeight.normal,
            height: 1.4,
          ),
        ));
      }

      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }

    return Text.rich(
      TextSpan(children: spans),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.smart_toy_rounded,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser ? AppTheme.primaryColor : Colors.grey.shade100,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 20),
                    ),
                  ),
                  child: _buildFormattedMessageText(message.text, isUser),
                ),
                if (message.appointment != null) ...[
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => PdfGeneratorService.showPdfPreview(context, message.appointment!),
                    icon: const Icon(Icons.picture_as_pdf, size: 16, color: Colors.white),
                    label: const Text('📄 View / Download Appointment PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
              child: Icon(
                Icons.person,
                color: AppTheme.primaryColor,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.smart_toy_rounded,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(1),
                const SizedBox(width: 4),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey.shade400.withOpacity(0.5 + (value * 0.5)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildQuickAction(String label, String message) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
        onPressed: () {
          _messageController.text = message;
          _sendMessage();
        },
        backgroundColor: Colors.grey.shade100,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildQuickActionWithNav(String label, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        onPressed: onPressed,
        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
        side: BorderSide(color: AppTheme.primaryColor, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildDoctorCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.local_hospital,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Available Doctors',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _navigateToSearchDoctors,
                    child: Text(
                      'View All',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _availableDoctors.length > 5 ? 5 : _availableDoctors.length,
                  itemBuilder: (context, index) {
                    final doctor = _availableDoctors[index];
                    return _buildDoctorCard(doctor);
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildDoctorCard(DoctorModel doctor) {
    return GestureDetector(
      onTap: () => _selectDoctorForInChatBooking(doctor),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  backgroundImage: (doctor.photoURL != null && doctor.photoURL!.isNotEmpty)
                      ? NetworkImage(doctor.photoURL!)
                      : null,
                  child: (doctor.photoURL == null || doctor.photoURL!.isEmpty)
                      ? Icon(
                          Icons.person,
                          color: AppTheme.primaryColor,
                          size: 20,
                        )
                      : null,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 12, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(
                        doctor.rating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Dr. ${doctor.name}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              doctor.specialization,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _selectDoctorForInChatBooking(doctor),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Book'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
