import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    swiftOptions: SwiftOptions(errorClassName: 'AnnotationsError'),
  ),
)
class AnnotationData {
  String fileName;
  List<Map<String, Object>?> drawingPaths;
  List<Map<String, Object>?> textAnnotations;
  double pdfPageWidth;
  double pdfPageHeight;

  AnnotationData(
      {required this.fileName,
      required this.drawingPaths,
      required this.textAnnotations,
      required this.pdfPageWidth,
      required this.pdfPageHeight});
}

@HostApi()
abstract class PdfAnnotations {
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  bool registerFonts(List<String> fontList);

  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  bool addAnnotations(AnnotationData annotationData);

  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  bool undoAnnotation(String fileName, int pageNo);
}
