class Supplier {
  final String id;
  final String name;
  final String logoUrl;
  bool allowIdentityRequests;

  Supplier({
    required this.id,
    required this.name,
    required this.logoUrl,
    this.allowIdentityRequests = false,
  });
} 