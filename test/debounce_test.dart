import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Debounce Logic Tests', () {
    test('isSaving flag prevents double execution', () async {
      bool isSaving = false;
      int executionCount = 0;

      Future<void> saveOperation() async {
        // Debounce check
        if (isSaving) {
          return;
        }

        isSaving = true;
        try {
          executionCount++;
          // Simulate async operation
          await Future.delayed(const Duration(milliseconds: 50));
        } finally {
          isSaving = false;
        }
      }

      // Simulate rapid double-click
      final futures = <Future>[];
      futures.add(saveOperation());
      futures.add(saveOperation()); // Should be ignored
      futures.add(saveOperation()); // Should be ignored

      await Future.wait(futures);

      // Only first call should execute
      expect(executionCount, 1);
    });

    test('isSaving flag resets after operation completes', () async {
      bool isSaving = false;
      int executionCount = 0;

      Future<void> saveOperation() async {
        if (isSaving) {
          return;
        }

        isSaving = true;
        try {
          executionCount++;
          await Future.delayed(const Duration(milliseconds: 10));
        } finally {
          isSaving = false;
        }
      }

      // First call
      await saveOperation();
      expect(executionCount, 1);
      expect(isSaving, false); // Should be reset

      // Second call after first completes
      await saveOperation();
      expect(executionCount, 2); // Should execute
      expect(isSaving, false); // Should be reset again
    });

    test('isSaving flag resets even when operation throws error', () async {
      bool isSaving = false;
      int executionCount = 0;

      Future<void> saveOperation({bool shouldFail = false}) async {
        if (isSaving) {
          return;
        }

        isSaving = true;
        try {
          executionCount++;
          if (shouldFail) {
            throw Exception('Test error');
          }
          await Future.delayed(const Duration(milliseconds: 10));
        } finally {
          isSaving = false;
        }
      }

      // First call that throws error
      try {
        await saveOperation(shouldFail: true);
      } catch (e) {
        // Expected error
      }

      expect(executionCount, 1);
      expect(isSaving, false); // Should be reset even after error

      // Second call should work
      await saveOperation(shouldFail: false);
      expect(executionCount, 2);
      expect(isSaving, false);
    });

    test('Concurrent calls are properly debounced', () async {
      bool isSaving = false;
      int executionCount = 0;

      Future<void> saveOperation() async {
        if (isSaving) {
          return;
        }

        isSaving = true;
        try {
          executionCount++;
          await Future.delayed(const Duration(milliseconds: 100));
        } finally {
          isSaving = false;
        }
      }

      // Fire 5 concurrent calls
      await Future.wait([
        saveOperation(),
        saveOperation(),
        saveOperation(),
        saveOperation(),
        saveOperation(),
      ]);

      // Only one should execute
      expect(executionCount, 1);
      expect(isSaving, false);
    });

    test('Sequential calls after completion all execute', () async {
      bool isSaving = false;
      int executionCount = 0;

      Future<void> saveOperation() async {
        if (isSaving) {
          return;
        }

        isSaving = true;
        try {
          executionCount++;
          await Future.delayed(const Duration(milliseconds: 10));
        } finally {
          isSaving = false;
        }
      }

      // Execute calls sequentially (await each one)
      await saveOperation();
      await saveOperation();
      await saveOperation();

      // All should execute
      expect(executionCount, 3);
      expect(isSaving, false);
    });
  });
}

