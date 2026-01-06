import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animal_rescue_app/features/home/providers/mock_data_provider.dart';

final mockDataProvider = ChangeNotifierProvider<MockDataProvider>((ref) {
  return MockDataProvider();
});
