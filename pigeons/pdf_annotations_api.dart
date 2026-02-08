import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/generated/pdf_annotations_api.dart',
    kotlinOut: 'android/src/main/kotlin/com/loucheindustries/pdf_annotations/PdfAnnotations.g.kt',
    kotlinOptions: KotlinOptions(package: 'com.loucheindustries.pdf_annotations'),
    swiftOut: 'ios/Classes/PdfAnnotations.g.swift',
    swiftOptions: SwiftOptions(errorClassName: 'AnnotationsError'),
    copyrightHeader: 'pigeons/copyright_header.txt',
  ),
)
class AnnotationData {
  String fileName;
  List<Map<String, Object>>? drawingPaths;
  List<Map<String, Object>>? textAnnotations;
  double pdfPageWidth;
  double pdfPageHeight;

  AnnotationData({
    required this.fileName,
    required this.drawingPaths,
    required this.textAnnotations,
    required this.pdfPageWidth,
    required this.pdfPageHeight,
  });
}

@HostApi()
abstract class PdfAnnotationsApi {
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  bool registerFonts(List<String> fontList);

  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  bool addAnnotations(AnnotationData annotationData);

  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  bool undoAnnotation(String fileName, int pageNo);
}
