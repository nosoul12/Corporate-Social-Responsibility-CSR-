import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockCase {
  final String id;
  final String title;
  final String description;
  final String reporterName;
  final String location;
  final String timeAgo;
  final String severity;
  final String status;
  final String animalType;
  final String imagePath;
  final double latitude;
  final double longitude;
  final int likes;
  final int comments;
  final bool isLiked;
  final bool isBookmarked;

  MockCase({
    required this.id,
    required this.title,
    required this.description,
    required this.reporterName,
    required this.location,
    required this.timeAgo,
    required this.severity,
    this.status = 'Reported',
    required this.animalType,
    required this.imagePath,
    required this.latitude,
    required this.longitude,
    this.likes = 0,
    this.comments = 0,
    this.isLiked = false,
    this.isBookmarked = false,
  });
}

class MockAdoption {
  final String id;
  final String name;
  final String type;
  final String age;
  final String location;
  final String distance;
  final String description;

  MockAdoption({
    required this.id,
    required this.name,
    required this.type,
    required this.age,
    required this.location,
    required this.distance,
    required this.description,
  });
}

class MockDataProvider extends ChangeNotifier {
  List<MockCase> _cases = [];
  List<MockAdoption> _adoptions = [];
  Set<String> _bookmarkedCaseIds = <String>{};

  static const _bookmarksKey = 'bookmarked_case_ids';

  List<MockCase> get cases => _cases;
  List<MockAdoption> get adoptions => _adoptions;
  List<MockCase> get bookmarkedCases =>
      _cases.where((c) => _bookmarkedCaseIds.contains(c.id)).toList();

  MockDataProvider() {
    _initializeMockData();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList(_bookmarksKey) ?? <String>[];
      _bookmarkedCaseIds = ids.toSet();
      _applyBookmarksToCases();
      notifyListeners();
    } catch (_) {
      // ignore
    }
  }

  Future<void> _persistBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_bookmarksKey, _bookmarkedCaseIds.toList());
    } catch (_) {
      // ignore
    }
  }

  void _applyBookmarksToCases() {
    _cases = _cases
        .map(
          (caseItem) => MockCase(
            id: caseItem.id,
            title: caseItem.title,
            description: caseItem.description,
            reporterName: caseItem.reporterName,
            location: caseItem.location,
            timeAgo: caseItem.timeAgo,
            severity: caseItem.severity,
            status: caseItem.status,
            animalType: caseItem.animalType,
            imagePath: caseItem.imagePath,
            latitude: caseItem.latitude,
            longitude: caseItem.longitude,
            likes: caseItem.likes,
            comments: caseItem.comments,
            isLiked: caseItem.isLiked,
            isBookmarked: _bookmarkedCaseIds.contains(caseItem.id),
          ),
        )
        .toList();
  }

  void _initializeMockData() {
    _cases = [
      MockCase(
        id: '1',
        title: 'Injured Dog Found',
        description:
            'A dog was found injured near the park. It appears to have a broken leg and needs immediate medical attention. The dog is friendly but in pain.',
        reporterName: 'John Doe',
        location: 'Central Park',
        timeAgo: '2 hours ago',
        severity: 'Critical',
        status: 'Reported',
        animalType: 'Dog',
        imagePath: 'assets/images/dog_injured.jpg',
        latitude: 40.7829,
        longitude: -73.9654,
        likes: 245,
        comments: 12,
      ),
      MockCase(
        id: '2',
        title: 'Stray Cat Needs Help',
        description:
            'Found a stray cat that seems to be malnourished and looking for food. Very gentle and allows approach.',
        reporterName: 'Sarah Smith',
        location: 'Downtown Area',
        timeAgo: '5 hours ago',
        severity: 'Moderate',
        status: 'Reported',
        animalType: 'Cat',
        imagePath: 'assets/images/cat_stray.jpg',
        latitude: 40.7580,
        longitude: -73.9855,
        likes: 89,
        comments: 5,
      ),
      MockCase(
        id: '3',
        title: 'Bird with Injured Wing',
        description:
            'Small bird found with injured wing, unable to fly. Currently in a safe box with water.',
        reporterName: 'Mike Johnson',
        location: 'Riverside Park',
        timeAgo: '1 day ago',
        severity: 'Urgent',
        status: 'Reported',
        animalType: 'Bird',
        imagePath: 'assets/images/bird_injured.jpg',
        latitude: 40.8148,
        longitude: -73.9442,
        likes: 156,
        comments: 8,
      ),
      MockCase(
        id: '4',
        title: 'Abandoned Puppy Rescue',
        description:
            'Found a puppy abandoned in a box. Very young and needs immediate care and feeding.',
        reporterName: 'Emily Brown',
        location: 'Suburban Street',
        timeAgo: '3 days ago',
        severity: 'Critical',
        status: 'Reported',
        animalType: 'Dog',
        imagePath: 'assets/images/puppy_abandoned.jpg',
        latitude: 40.7489,
        longitude: -73.9680,
        likes: 423,
        comments: 23,
      ),
      MockCase(
        id: '5',
        title: 'Injured Squirrel',
        description:
            'Squirrel found with leg injury, unable to climb trees properly. Needs wildlife rehabilitation.',
        reporterName: 'David Lee',
        location: 'Forest Trail',
        timeAgo: '4 days ago',
        severity: 'Low',
        status: 'Reported',
        animalType: 'Squirrel',
        imagePath: 'assets/images/squirrel_injured.jpg',
        latitude: 40.7736,
        longitude: -73.9566,
        likes: 67,
        comments: 3,
      ),
    ];

    _adoptions = [
      MockAdoption(
        id: '1',
        name: 'Buddy',
        type: 'Dog',
        age: '2 years',
        location: 'City Shelter',
        distance: '2 km away',
        description: 'Friendly golden retriever, great with kids',
      ),
      MockAdoption(
        id: '2',
        name: 'Luna',
        type: 'Cat',
        age: '1 year',
        location: 'Pet Rescue Center',
        distance: '3 km away',
        description: 'Playful tabby cat, loves to cuddle',
      ),
      MockAdoption(
        id: '3',
        name: 'Max',
        type: 'Dog',
        age: '3 years',
        location: 'Animal Haven',
        distance: '5 km away',
        description: 'Energetic beagle, needs active family',
      ),
      MockAdoption(
        id: '4',
        name: 'Bella',
        type: 'Cat',
        age: '6 months',
        location: 'Kitty Corner',
        distance: '1 km away',
        description: 'Adorable kitten, very curious and friendly',
      ),
      MockAdoption(
        id: '5',
        name: 'Charlie',
        type: 'Dog',
        age: '4 years',
        location: 'Happy Paws Shelter',
        distance: '4 km away',
        description: 'Calm mixed breed, perfect for quiet home',
      ),
      MockAdoption(
        id: '6',
        name: 'Mittens',
        type: 'Cat',
        age: '2 years',
        location: 'Feline Friends',
        distance: '6 km away',
        description: 'Gentle Persian cat, loves to nap',
      ),
      MockAdoption(
        id: '7',
        name: 'Rocky',
        type: 'Dog',
        age: '1 year',
        location: 'Dog House Rescue',
        distance: '3 km away',
        description: 'Young terrier mix, full of energy',
      ),
      MockAdoption(
        id: '8',
        name: 'Whiskers',
        type: 'Cat',
        age: '3 years',
        location: 'Cat Café Adoption',
        distance: '2 km away',
        description: 'Social cat, loves other animals',
      ),
    ];
  }

  void toggleLike(String caseId) {
    final index = _cases.indexWhere((c) => c.id == caseId);
    if (index != -1) {
      final caseItem = _cases[index];
      _cases[index] = MockCase(
        id: caseItem.id,
        title: caseItem.title,
        description: caseItem.description,
        reporterName: caseItem.reporterName,
        location: caseItem.location,
        timeAgo: caseItem.timeAgo,
        severity: caseItem.severity,
        status: caseItem.status,
        animalType: caseItem.animalType,
        imagePath: caseItem.imagePath,
        latitude: caseItem.latitude,
        longitude: caseItem.longitude,
        likes: caseItem.isLiked ? caseItem.likes - 1 : caseItem.likes + 1,
        comments: caseItem.comments,
        isLiked: !caseItem.isLiked,
        isBookmarked: caseItem.isBookmarked,
      );
      notifyListeners();
    }
  }

  Future<bool> toggleBookmark(String caseId) async {
    final index = _cases.indexWhere((c) => c.id == caseId);
    if (index != -1) {
      final caseItem = _cases[index];
      final isNowBookmarked = !_bookmarkedCaseIds.contains(caseId);
      if (isNowBookmarked) {
        _bookmarkedCaseIds.add(caseId);
      } else {
        _bookmarkedCaseIds.remove(caseId);
      }
      _cases[index] = MockCase(
        id: caseItem.id,
        title: caseItem.title,
        description: caseItem.description,
        reporterName: caseItem.reporterName,
        location: caseItem.location,
        timeAgo: caseItem.timeAgo,
        severity: caseItem.severity,
        status: caseItem.status,
        animalType: caseItem.animalType,
        imagePath: caseItem.imagePath,
        latitude: caseItem.latitude,
        longitude: caseItem.longitude,
        likes: caseItem.likes,
        comments: caseItem.comments,
        isLiked: caseItem.isLiked,
        isBookmarked: isNowBookmarked,
      );
      await _persistBookmarks();
      notifyListeners();
      return isNowBookmarked;
    }
    return false;
  }

  void addComment(String caseId) {
    final index = _cases.indexWhere((c) => c.id == caseId);
    if (index != -1) {
      final caseItem = _cases[index];
      _cases[index] = MockCase(
        id: caseItem.id,
        title: caseItem.title,
        description: caseItem.description,
        reporterName: caseItem.reporterName,
        location: caseItem.location,
        timeAgo: caseItem.timeAgo,
        severity: caseItem.severity,
        status: caseItem.status,
        animalType: caseItem.animalType,
        imagePath: caseItem.imagePath,
        latitude: caseItem.latitude,
        longitude: caseItem.longitude,
        likes: caseItem.likes,
        comments: caseItem.comments + 1,
        isLiked: caseItem.isLiked,
        isBookmarked: caseItem.isBookmarked,
      );
      notifyListeners();
    }
  }

  void addNewCase(
      String title,
      String description,
      String severity,
      String animalType,
      String imagePath,
      double latitude,
      double longitude,
      String location) {
    final newCase = MockCase(
      id: (_cases.length + 1).toString(),
      title: title,
      description: description,
      reporterName: 'Current User',
      location: location,
      timeAgo: 'Just now',
      severity: severity,
      status: 'Reported',
      animalType: animalType,
      imagePath: imagePath,
      latitude: latitude,
      longitude: longitude,
      likes: 0,
      comments: 0,
      isBookmarked: false,
    );
    _cases.insert(0, newCase);
    notifyListeners();
  }

  void updateCaseStatus(String caseId, String newStatus) {
    final index = _cases.indexWhere((c) => c.id == caseId);
    if (index != -1) {
      final caseItem = _cases[index];
      _cases[index] = MockCase(
        id: caseItem.id,
        title: caseItem.title,
        description: caseItem.description,
        reporterName: caseItem.reporterName,
        location: caseItem.location,
        timeAgo: caseItem.timeAgo,
        severity: caseItem.severity,
        status: newStatus,
        animalType: caseItem.animalType,
        imagePath: caseItem.imagePath,
        latitude: caseItem.latitude,
        longitude: caseItem.longitude,
        likes: caseItem.likes,
        comments: caseItem.comments,
        isLiked: caseItem.isLiked,
        isBookmarked: caseItem.isBookmarked,
      );
      notifyListeners();
    }
  }
}
