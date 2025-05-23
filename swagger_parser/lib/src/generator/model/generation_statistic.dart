import 'package:meta/meta.dart';

/// Contains statistics about generation
@immutable
class GenerationStatistic {
  /// Creates a [GenerationStatistic].
  const GenerationStatistic({
    required this.totalFiles,
    required this.totalLines,
    required this.totalRestClients,
    required this.totalRequests,
    required this.totalDataClasses,
    required this.timeElapsed,
    required this.totalRepoClasses,
    required this.totalUseCaseClasses,
  });

  /// Total files
  final int totalFiles;

  /// Total lines of code
  final int totalLines;

  /// Total rest clients
  final int totalRestClients;

  /// Total requests
  final int totalRequests;

  /// Total data classes
  final int totalDataClasses;

  /// Total repository classes
  final int totalRepoClasses;

  /// Total use case classes
  final int totalUseCaseClasses;

  /// Time elapsed for generation
  final Duration timeElapsed;

  /// Merge two [GenerationStatistic] into one
  GenerationStatistic merge(GenerationStatistic other) => GenerationStatistic(
        totalFiles: totalFiles + other.totalFiles,
        totalLines: totalLines + other.totalLines,
        totalRestClients: totalRestClients + other.totalRestClients,
        totalRequests: totalRequests + other.totalRequests,
        totalDataClasses: totalDataClasses + other.totalDataClasses,
        timeElapsed: timeElapsed + other.timeElapsed,
        totalRepoClasses: totalRepoClasses + other.totalRepoClasses,
        totalUseCaseClasses: totalUseCaseClasses + other.totalUseCaseClasses,
      );
}
