import 'package:flutter/material.dart';
import '../models/email.dart';
import '../widgets/app_header.dart';

class SecureMailboxScreen extends StatefulWidget {
  const SecureMailboxScreen({Key? key}) : super(key: key);

  @override
  State<SecureMailboxScreen> createState() => _SecureMailboxScreenState();
}

class _SecureMailboxScreenState extends State<SecureMailboxScreen> {
  List<Email> _emails = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDemoEmails();
  }

  void _loadDemoEmails() {
    // Demo emails with attachments
    _emails = [
      Email(
        id: '1',
        subject: 'Welcome to IdentityConnect',
        content: 'Welcome to IdentityConnect! Your secure digital identity platform is now ready to use. You can now verify your identity with trusted partners and access secure services.\n\nYour account has been successfully created and your identity documents have been verified. You can now use your digital identity for secure transactions and verifications.\n\nIf you have any questions, please don\'t hesitate to contact our support team.',
        sender: 'support@identityconnect.io',
        businessName: 'IdentityConnect',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: true,
        attachments: [
          EmailAttachment(
            id: 'att1',
            name: 'Welcome_Guide.pdf',
            type: 'application/pdf',
            size: 245760, // 240 KB
            base64Data: 'JVBERi0xLjQKJcOkw7zDtsO4DQoxIDAgb2JqDQo8PA0KL1R5cGUgL0NhdGFsb2cNCi9QYWdlcyAyIDAgUg0KPj4NCmVuZG9iag0KMiAwIG9iag0KPDwNCi9UeXBlIC9QYWdlcw0KL0NvdW50IDENCi9LaWRzIFsgMyAwIFIgXSANCj4+DQplbmRvYmoNCjMgMCBvYmoNCjw8DQovVHlwZSAvUGFnZQ0KL1BhcmVudCAyIDAgUg0KL1Jlc291cmNlcyA8PA0KL0ZvbnQgPDwNCi9GMSA0IDAgUg0KPj4NCi9FeHRHU3RhdGUgPDwNCi9BdXRoIDw8DQovQXV0aFR5cGUgL0F1dGhVc2VyDQo+Pg0KPj4NCi9Db250ZW50cyA1IDAgUg0KL01lZGlhQm94IFsgMCAwIDU5NSA4NDIgXQ0KPj4NCmVuZG9iag0KNCAwIG9iag0KPDwNCi9UeXBlIC9Gb250DQovU3VidHlwZSAvVHlwZTENCi9CYXNlRm9udCAvSGVsdmV0aWNhLUJvbGQNCi9FbmNvZGluZyAvV2luQW5zaUVuY29kaW5nDQo+Pg0KZW5kb2JqDQo1IDAgb2JqDQo8PA0KL0xlbmd0aCAxNDQNCj4+DQpzdHJlYW0NCkJUCjcwIDUwIFRECi9GMSAxMiBUZgooSGVsbG8gV29ybGQpIFRqCkVUCmVuZHN0cmVhbQplbmRvYmoNCnhyZWYNCjAgNg0KMDAwMDAwMDAwMCA2NTUzNSBmDQowMDAwMDAwMDEwIDAwMDAwIG4NCjAwMDAwMDAwNzkgMDAwMDAgbg0KMDAwMDAwMDE3MyAwMDAwMCBuDQowMDAwMDAwMzAxIDAwMDAwIG4NCjAwMDAwMDAzODAgMDAwMDAgbg0KdHJhaWxlcg0KPDwNCi9TaXplIDYNCi9Sb290IDEgMCBSDQo+Pg0Kc3RhcnR4cmVmDQo0OTINCiUlRU9G',
          ),
        ],
      ),
      Email(
        id: '2',
        subject: 'Identity Verification Complete',
        content: 'Your identity verification has been completed successfully! Your documents have been processed and verified by our secure system.\n\nVerification Details:\n- Document Type: Passport\n- Verification Status: Approved\n- Verification Date: ${DateTime.now().subtract(const Duration(days: 1)).toString().split(' ')[0]}\n\nYour digital identity is now active and ready for use with our partner services. You can now securely share your verified identity with trusted organizations.',
        sender: 'verification@identityconnect.io',
        businessName: 'IdentityConnect Verification',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        isRead: false,
        attachments: [
          EmailAttachment(
            id: 'att2',
            name: 'Verification_Certificate.pdf',
            type: 'application/pdf',
            size: 512000, // 500 KB
            base64Data: 'JVBERi0xLjQKJcOkw7zDtsO4DQoxIDAgb2JqDQo8PA0KL1R5cGUgL0NhdGFsb2cNCi9QYWdlcyAyIDAgUg0KPj4NCmVuZG9iag0KMiAwIG9iag0KPDwNCi9UeXBlIC9QYWdlcw0KL0NvdW50IDENCi9LaWRzIFsgMyAwIFIgXSANCj4+DQplbmRvYmoNCjMgMCBvYmoNCjw8DQovVHlwZSAvUGFnZQ0KL1BhcmVudCAyIDAgUg0KL1Jlc291cmNlcyA8PA0KL0ZvbnQgPDwNCi9GMSA0IDAgUg0KPj4NCi9FeHRHU3RhdGUgPDwNCi9BdXRoIDw8DQovQXV0aFR5cGUgL0F1dGhVc2VyDQo+Pg0KPj4NCi9Db250ZW50cyA1IDAgUg0KL01lZGlhQm94IFsgMCAwIDU5NSA4NDIgXQ0KPj4NCmVuZG9iag0KNCAwIG9iag0KPDwNCi9UeXBlIC9Gb250DQovU3VidHlwZSAvVHlwZTENCi9CYXNlRm9udCAvSGVsdmV0aWNhLUJvbGQNCi9FbmNvZGluZyAvV2luQW5zaUVuY29kaW5nDQo+Pg0KZW5kb2JqDQo1IDAgb2JqDQo8PA0KL0xlbmd0aCAxNDQNCj4+DQpzdHJlYW0NCkJUCjcwIDUwIFRECi9GMSAxMiBUZgooSGVsbG8gV29ybGQpIFRqCkVUCmVuZHN0cmVhbQplbmRvYmoNCnhyZWYNCjAgNg0KMDAwMDAwMDAwMCA2NTUzNSBmDQowMDAwMDAwMDEwIDAwMDAwIG4NCjAwMDAwMDAwNzkgMDAwMDAgbg0KMDAwMDAwMDE3MyAwMDAwMCBuDQowMDAwMDAwMzAxIDAwMDAwIG4NCjAwMDAwMDAzODAgMDAwMDAgbg0KdHJhaWxlcg0KPDwNCi9TaXplIDYNCi9Sb290IDEgMCBSDQo+Pg0Kc3RhcnR4cmVmDQo0OTINCiUlRU9G',
          ),
        ],
      ),
      Email(
        id: '3',
        subject: 'New Partner Service Available',
        content: 'Great news! A new partner service is now available for your verified identity.\n\nService: Secure Banking Verification\nPartner: TrustBank\n\nYou can now use your verified identity to securely access banking services with TrustBank. This service allows for instant account verification and secure transactions.\n\nTo use this service, simply share your verified identity when prompted during the banking process. Your identity will be verified instantly without sharing any personal documents.',
        sender: 'partners@identityconnect.io',
        businessName: 'IdentityConnect Partners',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        isRead: true,
      ),
      Email(
        id: '4',
        subject: 'Security Update - Enhanced Protection',
        content: 'We\'ve implemented enhanced security measures to protect your digital identity.\n\nNew Security Features:\n- Multi-factor authentication\n- Biometric verification\n- Advanced encryption\n- Real-time fraud detection\n\nThese updates ensure your identity remains secure and protected from unauthorized access. No action is required from your side - these security enhancements are automatically applied to your account.',
        sender: 'security@identityconnect.io',
        businessName: 'IdentityConnect Security',
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        isRead: true,
        attachments: [
          EmailAttachment(
            id: 'att4',
            name: 'Security_Update_Details.pdf',
            type: 'application/pdf',
            size: 102400, // 100 KB
            base64Data: 'JVBERi0xLjQKJcOkw7zDtsO4DQoxIDAgb2JqDQo8PA0KL1R5cGUgL0NhdGFsb2cNCi9QYWdlcyAyIDAgUg0KPj4NCmVuZG9iag0KMiAwIG9iag0KPDwNCi9UeXBlIC9QYWdlcw0KL0NvdW50IDENCi9LaWRzIFsgMyAwIFIgXSANCj4+DQplbmRvYmoNCjMgMCBvYmoNCjw8DQovVHlwZSAvUGFnZQ0KL1BhcmVudCAyIDAgUg0KL1Jlc291cmNlcyA8PA0KL0ZvbnQgPDwNCi9GMSA0IDAgUg0KPj4NCi9FeHRHU3RhdGUgPDwNCi9BdXRoIDw8DQovQXV0aFR5cGUgL0F1dGhVc2VyDQo+Pg0KPj4NCi9Db250ZW50cyA1IDAgUg0KL01lZGlhQm94IFsgMCAwIDU5NSA4NDIgXQ0KPj4NCmVuZG9iag0KNCAwIG9iag0KPDwNCi9UeXBlIC9Gb250DQovU3VidHlwZSAvVHlwZTENCi9CYXNlRm9udCAvSGVsdmV0aWNhLUJvbGQNCi9FbmNvZGluZyAvV2luQW5zaUVuY29kaW5nDQo+Pg0KZW5kb2JqDQo1IDAgb2JqDQo8PA0KL0xlbmd0aCAxNDQNCj4+DQpzdHJlYW0NCkJUCjcwIDUwIFRECi9GMSAxMiBUZgooSGVsbG8gV29ybGQpIFRqCkVUCmVuZHN0cmVhbQplbmRvYmoNCnhyZWYNCjAgNg0KMDAwMDAwMDAwMCA2NTUzNSBmDQowMDAwMDAwMDEwIDAwMDAwIG4NCjAwMDAwMDAwNzkgMDAwMDAgbg0KMDAwMDAwMDE3MyAwMDAwMCBuDQowMDAwMDAwMzAxIDAwMDAwIG4NCjAwMDAwMDAzODAgMDAwMDAgbg0KdHJhaWxlcg0KPDwNCi9TaXplIDYNCi9Sb290IDEgMCBSDQo+Pg0Kc3RhcnR4cmVmDQo0OTINCiUlRU9G',
          ),
        ],
      ),
      Email(
        id: '5',
        subject: 'Monthly Activity Report',
        content: 'Here\'s your monthly activity report for your digital identity usage.\n\nActivity Summary:\n- Identity verifications: 3\n- Partner service accesses: 2\n- Security checks passed: 100%\n- No suspicious activity detected\n\nYour digital identity continues to be used securely and efficiently. All verifications and transactions have been completed successfully.',
        sender: 'reports@identityconnect.io',
        businessName: 'IdentityConnect Reports',
        timestamp: DateTime.now().subtract(const Duration(days: 5)),
        isRead: true,
      ),
    ];

    setState(() {
      _isLoading = false;
    });
  }

  void _deleteEmail(String emailId) {
    setState(() {
      _emails.removeWhere((email) => email.id == emailId);
    });
  }

  void _markAsRead(String emailId) {
    setState(() {
      final emailIndex = _emails.indexWhere((email) => email.id == emailId);
      if (emailIndex != -1) {
        _emails[emailIndex] = _emails[emailIndex].copyWith(isRead: true);
      }
    });
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'Secure Mailbox'),
      drawer: const AppDrawer(),
      backgroundColor: const Color(0xFFF8F9FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _emails.isEmpty
              ? _buildEmptyState()
              : _buildEmailList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mail_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No emails yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your secure emails will appear here',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _emails.length,
      itemBuilder: (context, index) {
        final email = _emails[index];
        return _buildEmailItem(email);
      },
    );
  }

  Widget _buildEmailItem(Email email) {
    return Dismissible(
      key: Key(email.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _deleteEmail(email.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Email deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                setState(() {
                  _emails.add(email);
                });
              },
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 1,
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(
            backgroundColor: email.isRead ? Colors.grey[300] : Colors.blue,
            child: Text(
              email.businessName[0].toUpperCase(),
              style: TextStyle(
                color: email.isRead ? Colors.grey[600] : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  email.subject,
                  style: TextStyle(
                    fontWeight: email.isRead ? FontWeight.normal : FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (email.attachments.isNotEmpty)
                const Icon(
                  Icons.attach_file,
                  size: 16,
                  color: Colors.grey,
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                email.businessName,
                style: TextStyle(
                  color: email.isRead ? Colors.grey[600] : Colors.black87,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                email.shortContent,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                _formatTimestamp(email.timestamp),
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          onTap: () {
            _markAsRead(email.id);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EmailDetailScreen(email: email),
              ),
            );
          },
        ),
      ),
    );
  }
}

class EmailDetailScreen extends StatelessWidget {
  final Email email;

  const EmailDetailScreen({Key? key, required this.email}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              Navigator.pop(context);
              // Note: In a real app, you'd want to pass a callback to delete the email
            },
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subject
            Text(
              email.subject,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Sender info
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(
                    email.businessName[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        email.businessName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        email.sender,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatTimestamp(email.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Content
            Text(
              email.content,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
              ),
            ),
            
            // Attachments
            if (email.attachments.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Attachments',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...email.attachments.map((attachment) => _buildAttachmentItem(attachment)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentItem(EmailAttachment attachment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.attach_file, color: Colors.blue),
        title: Text(attachment.name),
        subtitle: Text('${attachment.type} • ${attachment.fileSize}'),
        trailing: IconButton(
          icon: const Icon(Icons.download),
          onPressed: () {
            // In a real app, you'd implement file download
            print('Downloading ${attachment.name}');
          },
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
} 