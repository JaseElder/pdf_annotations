import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_annotations/src/utilities/errors.dart';

void main() {
  group('TaskResult', () {
    test('Success holds payload data correctly', () {
      const success = Success<String>('Operation succeeded');
      expect(success.data, 'Operation succeeded');
      expect(success, isA<TaskResult<String>>());
    });

    test('Failure encapsulates error message, exception, and stackTrace', () {
      final exception = Exception('Disk error');
      final stackTrace = StackTrace.current;
      final failure = Failure<int>(
        'Failed to save file',
        error: exception,
        stackTrace: stackTrace,
      );

      expect(failure.message, 'Failed to save file');
      expect(failure.error, exception);
      expect(failure.stackTrace, stackTrace);
      expect(failure, isA<TaskResult<int>>());
    });
  });
}
