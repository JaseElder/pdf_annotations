package com.loucheindustries.pdf_annotations

import android.content.Context
import android.content.res.AssetManager
import android.graphics.Paint
import android.graphics.PointF
import android.graphics.Typeface
import android.text.TextPaint
import android.util.SizeF
import com.tom_roush.pdfbox.cos.COSArray
import com.tom_roush.pdfbox.cos.COSFloat
import com.tom_roush.pdfbox.cos.COSName
import com.tom_roush.pdfbox.pdmodel.PDDocument
import com.tom_roush.pdfbox.pdmodel.PDResources
import com.tom_roush.pdfbox.pdmodel.common.PDRectangle
import com.tom_roush.pdfbox.pdmodel.font.PDFont
import com.tom_roush.pdfbox.pdmodel.font.PDTrueTypeFont
import com.tom_roush.pdfbox.pdmodel.font.encoding.Encoding
import com.tom_roush.pdfbox.pdmodel.graphics.color.PDColor
import com.tom_roush.pdfbox.pdmodel.graphics.color.PDDeviceRGB
import com.tom_roush.pdfbox.pdmodel.interactive.annotation.PDAnnotation
import com.tom_roush.pdfbox.pdmodel.interactive.annotation.PDAnnotationMarkup
import com.tom_roush.pdfbox.pdmodel.interactive.annotation.PDBorderStyleDictionary
import com.tom_roush.pdfbox.pdmodel.interactive.form.PDAcroForm
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.plugins.FlutterPlugin
import java.io.File
import java.util.Locale
import java.util.Objects
import kotlin.math.max
import kotlin.math.min


/** PdfAnnotationsPlugin */
class PdfAnnotationsPlugin: FlutterPlugin {

  private lateinit var context: Context

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    context = flutterPluginBinding.applicationContext
    val api = PdfAnnotationsImplementation(context)
    PdfAnnotations.setUp(flutterPluginBinding.binaryMessenger, api)
  }


  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {

  }
}

private class PdfAnnotationsImplementation(context: Context) : PdfAnnotations {
  private lateinit var fullPath: String
  private var assetManager: AssetManager = context.assets


  private class AnnotationMeasurements(
    private val assetManager: AssetManager,
    private val text: String,
    private val fontName: String,
    private val fontSize: Float
  ) {
    private lateinit var textPaint: TextPaint
    private lateinit var fm: Paint.FontMetrics

    fun create(): AnnotationMeasurements {
      val assetPath = FlutterInjector.instance().flutterLoader().getLookupKeyForAsset(
        "fonts/$fontName.ttf"
      )
      val typeface = Typeface.createFromAsset(
        assetManager, assetPath
      )
      textPaint = TextPaint()
      textPaint.textSize = fontSize
      textPaint.setTypeface(typeface)
      fm = textPaint.fontMetrics
      return this
    }

    val annotationWidth: Float
      get() = textPaint.measureText(this.text) + ANNOTATION_PADDING

    val fontHeight: Float
      get() = textPaint.fontSpacing

    val annotationHeight: Float
      get() {
        var addForFont = 0f
        if (fontName == "STIXTwoText-SemiBold") {
          addForFont = -1f
        }
        return fm.bottom - fm.top + addForFont
      }
  }

  override fun registerFonts(fontList: List<String>): Boolean {
    return true
  }

  override fun addAnnotations(annotationData: AnnotationData): Boolean {
    val fileName: String = annotationData.fileName
    val drawingPaths: List<Map<String, Any>?> = annotationData.drawingPaths
    val textAnnotations: List<Map<String, Any>?> = annotationData.textAnnotations
    val pdfPageWidth: Float = annotationData.pdfPageWidth.toFloat()
    val pdfPageHeight: Float = annotationData.pdfPageHeight.toFloat()

    return try {
      addAnnotationsToPdfBox(
        fileName,
        drawingPaths,
        textAnnotations,
        pdfPageWidth,
        pdfPageHeight
      )
    } catch (e: Exception) {
      throw FlutterError("FAIL", "Failed to add annotations", e.message)
    }
  }

  private fun addAnnotationsToPdfBox(pdfFilePath: String, drawingPaths: List<Map<String, Any>?>,
                                     textAnnotations: List<Map<String, Any>?>,
                                     flutterPdfPageWidth: Float, flutterPdfPageHeight: Float): Boolean {
    val document: PDDocument = openPdf(pdfFilePath)
    val noOfPages = document.numberOfPages
    val fontCodeMap: MutableMap<String?, String?> = HashMap()
    for (pageNo in 0 until noOfPages) {
      val page = document.getPage(pageNo)
      val pageAnnotations = page.annotations
      val pageMediaBox = page.mediaBox
      val pdfBoxPageWidth = pageMediaBox.width
      val pdfBoxPageHeight = pageMediaBox.height
      val scalingX = pdfBoxPageWidth / flutterPdfPageWidth
      val scalingY = pdfBoxPageHeight / flutterPdfPageHeight
      val pageHeightOffset = (noOfPages - pageNo - 1) * flutterPdfPageHeight
      addDrawingAnnotations(
        pageAnnotations,
        drawingPaths,
        scalingX,
        scalingY,
        pageHeightOffset,
        pdfBoxPageHeight
      )
      addTextAnnotations(
        pageAnnotations,
        textAnnotations,
        scalingX,
        scalingY,
        pageHeightOffset,
        pdfBoxPageHeight,
        document,
        fontCodeMap
      )

      for (ann in pageAnnotations) {
        ann.constructAppearances(document)
      }
    }

    closePdf(document)
    return true
  }

  private fun openPdf(name: String): PDDocument {
    fullPath = name
    return PDDocument.load(File(fullPath))
  }

  private fun closePdf(pdf: PDDocument) {
    pdf.save(fullPath)
    pdf.close()
  }

  @Suppress("UNCHECKED_CAST")
  private fun addDrawingAnnotations(
    pageAnnotations: MutableList<PDAnnotation>,
    drawingPaths: List<Map<String, Any>?>,
    scalingX: Float,
    scalingY: Float,
    pageHeightOffset: Float,
    pdfBoxPageHeight: Float
  ) {
    for (drawnPath in drawingPaths) {
      val path: List<List<Double>> =
        drawnPath!!.getOrDefault(
          "path",
          getDefaultPath()
        ) as List<List<Double>>
      val pathAsPoints =
        convertListToPointListInPageSpace(path, pageHeightOffset, scalingX, scalingY)
      val colour: List<Double> = drawnPath.getOrDefault(
        "colour",
        DEFAULT_COLOR
      ) as List<Double>
      val width = (Objects.requireNonNull(
        drawnPath.getOrDefault(
          "width",
          0.0
        )
      ) as Double).toFloat() * scalingX

      val pdFreehand: PDAnnotationMarkup? =
        addDrawingAnnotation(pathAsPoints, colour, width, pdfBoxPageHeight)
      if (pdFreehand != null) {
        pageAnnotations.add(pdFreehand)
      }
    }
  }

  @Suppress("UNCHECKED_CAST")
  private fun addTextAnnotations(
    pageAnnotations: MutableList<PDAnnotation>, textAnnotations: List<Map<String, Any>?>,
    scalingX: Float, scalingY: Float, pageHeightOffset: Float, pdfBoxPageHeight: Float,
    document: PDDocument, fontCodeMap: MutableMap<String?, String?>
  ) {
    for (textAnnotation in textAnnotations) {
      val textString = textAnnotation?.get("text_string") as String
      val fontName = textAnnotation["font_name"] as String
      val fontSize = textAnnotation.getOrDefault(
          "font_size",
          DEFAULT_FONT_SIZE
        ) as Double
      val scaledFontSize = fontSize.toFloat() * scalingX
      val measurements: AnnotationMeasurements =
        assetManager.let {
          AnnotationMeasurements(
            it,
            textString,
            fontName,
            scaledFontSize
          ).create()
        }
      val annotationWidth: Float = measurements.annotationWidth
      val annotationHeight: Float = measurements.annotationHeight
      val coord = Objects.requireNonNull(
        textAnnotation.getOrDefault(
          "coordinate",
          mutableListOf(0.0, 0.0)
        )
      ) as List<Double>
      val coordAsScaledPoint: PointF = convertCoordToPointInPageSpace(
          coord,
          pageHeightOffset,
          scalingX,
          scalingY,
          annotationHeight
        )
      if (coordAsScaledPoint.y >= -annotationHeight && coordAsScaledPoint.y <= pdfBoxPageHeight + annotationHeight) {
        val colourList = textAnnotation.getOrDefault(
          "colour",
          DEFAULT_COLOR
        ) as List<Double>
        val annotationSize = SizeF(annotationWidth, annotationHeight)
        var fontCode = fontCodeMap[fontName]
        if (fontCode == null) {
          fontCode = getFontCode(document, fontName)
          fontCodeMap[fontName] = fontCode
        }
        addTextAnnotation(
          pageAnnotations,
          textString,
          coordAsScaledPoint,
          fontCode,
          scaledFontSize,
          colourList,
          annotationSize
        )
      }
    }
  }

  private fun addTextAnnotation(
    pageAnnotations: MutableList<PDAnnotation>,
    theText: String,
    scaledPoint: PointF,
    fontCode: String,
    scaledFontSize: Float,
    colourList: List<Double>,
    annotationSize: SizeF
  ) {
    val textAnnotation = createTextAnnotation(theText, fontCode, scaledFontSize, colourList)
    val rect =
      PDRectangle(scaledPoint.x, scaledPoint.y, annotationSize.width, annotationSize.height)
    textAnnotation.rectangle = rect
    pageAnnotations.add(textAnnotation)
  }

  private fun createTextAnnotation(
    theText: String,
    fontCode: String,
    fontSize: Float,
    colourList: List<Double>
  ): PDAnnotationMarkup {
    val colourComponents = floatArrayOf(
      colourList[1].toFloat() / 255f,
      colourList[2].toFloat() / 255f,
      colourList[3].toFloat() / 255f
    )
    val textAnnotation = PDAnnotationMarkup()
    textAnnotation.cosObject.setName(COSName.SUBTYPE, PDAnnotationMarkup.SUB_TYPE_FREETEXT)
    val appearance = String.format(
      Locale.ENGLISH, "/%s %f Tf %f %f %f rg", fontCode, fontSize,
      colourComponents[0],
      colourComponents[1],
      colourComponents[2]
    )
    textAnnotation.defaultAppearance = appearance
    val thickness = PDBorderStyleDictionary()
    thickness.width = 0f
    textAnnotation.borderStyle = thickness
    textAnnotation.contents = theText

    return textAnnotation
  }

  private fun getFontCode(document: PDDocument, fontName: String): String {
    var acroForm = document.documentCatalog.acroForm
    if (acroForm == null) {
      acroForm = PDAcroForm(document)
      document.documentCatalog.acroForm = acroForm
    }
    var resources = acroForm.defaultResources
    if (resources == null) {
      resources = PDResources()
      acroForm.defaultResources = resources
    }
    var fontCode = ""
    for (cosFontName in resources.fontNames) {
      val pdFont = resources.getFont(cosFontName)
      if (fontName == pdFont.name) {
        fontCode = cosFontName.name
        break
      }
    }

    if (fontCode.isEmpty()) {
      fontCode = addFontToResources(document, fontName, resources)
    }
    return fontCode
  }

  private fun addFontToResources(document: PDDocument, fontName: String, res: PDResources): String {
    val assetPath =
      FlutterInjector.instance().flutterLoader().getLookupKeyForAsset("fonts/$fontName.ttf")
    val font: PDFont = PDTrueTypeFont.load(
      document,
      assetManager.open(assetPath),
      Encoding.getInstance(COSName.WIN_ANSI_ENCODING)
    )
    return res.add(font).name
  }

  private fun convertCoordToPointInPageSpace(
    coordinate: List<Double>, pageHeightOffset: Float,
    scalingX: Float, scalingY: Float, annotationHeight: Float
  ): PointF {
    val x = coordinate[0].toFloat() * scalingX
    val y = (coordinate[1].toFloat() - pageHeightOffset) * scalingY - annotationHeight
    return PointF(x, y)
  }

  private fun convertListToPointListInPageSpace(
    list: List<List<Double>>,
    pageHeightOffset: Float, scalingX: Float, scalingY: Float
  ): ArrayList<PointF> {
    val points = ArrayList<PointF>()
    for (pointList in list) {
      if (pointList.size == 2) {
        val x = pointList[0].toFloat() * scalingX
        val y = (pointList[1].toFloat() - pageHeightOffset) * scalingY
        points.add(PointF(x, y))
      }
    }
    return points
  }

  private fun getDefaultPath(): List<List<Double>> {
    val path = ArrayList<ArrayList<Double>>()
    path.add(arrayListOf(0.0, 0.0))
    return path
  }

  private fun addDrawingAnnotation(
    coordinates: List<PointF>, colourList: List<Double>,
    width: Float, pdfPageHeight: Float
  ): PDAnnotationMarkup? {
    val freehand = createDrawingAnnotation(colourList, width)
    val coordsAreValidForThisPage = setDrawingRectangle(coordinates, width, pdfPageHeight, freehand)
    if (coordsAreValidForThisPage) {
      val pathAdded = addDrawingPath(coordinates, width, pdfPageHeight, freehand)
      if (pathAdded) {
        return freehand
      }
    }
    return null
  }

  private fun createDrawingAnnotation(colourList: List<Double>, width: Float): PDAnnotationMarkup {
    val colourComponents = floatArrayOf(
      colourList[1].toFloat() / 255f,
      colourList[2].toFloat() / 255f,
      colourList[3].toFloat() / 255f
    )
    val color = PDColor(colourComponents, PDDeviceRGB.INSTANCE)

    val thickness = PDBorderStyleDictionary()
    thickness.width = width

    val freehand = PDAnnotationMarkup()
    freehand.cosObject.setName(COSName.SUBTYPE, PDAnnotationMarkup.SUB_TYPE_INK)
    freehand.color = color
    freehand.borderStyle = thickness
    freehand.constantOpacity = colourList[0].toFloat() / 255f

    return freehand
  }

  private fun setDrawingRectangle(
    coordinates: List<PointF>,
    width: Float,
    pdfPageHeight: Float,
    freehand: PDAnnotationMarkup
  ): Boolean {
    var minX = INITIAL_MIN_VALUE
    var minY = INITIAL_MIN_VALUE
    var maxX = INITIAL_MAX_VALUE
    var maxY = INITIAL_MAX_VALUE

    for (coordinate in coordinates) {
      val x = coordinate.x
      val y = coordinate.y

      if (y >= -width && y <= (pdfPageHeight + width)) {
        minX = min(minX.toDouble(), x.toDouble()).toFloat()
        minY = min(minY.toDouble(), y.toDouble()).toFloat()
        maxX = max(maxX.toDouble(), x.toDouble()).toFloat()
        maxY = max(maxY.toDouble(), y.toDouble()).toFloat()
      }
    }

    if (minX == INITIAL_MIN_VALUE && minY == INITIAL_MIN_VALUE) {
      return false
    }
    val points = PDRectangle(minX, minY, (maxX - minX), (maxY - minY))
    freehand.rectangle = points
    return true
  }

  private fun addDrawingPath(
    coordinates: List<PointF>,
    width: Float,
    pdfPageHeight: Float,
    freehand: PDAnnotationMarkup
  ): Boolean {
    val verticesArray = COSArray()

    for (coordinate in coordinates) {
      val xCoord = coordinate.x
      val yCoord = coordinate.y
      if (yCoord >= -width && yCoord <= (pdfPageHeight + width)) {
        verticesArray.add(COSFloat(xCoord))
        verticesArray.add(COSFloat(yCoord))
      }
    }

    if (verticesArray.size() == 0) {
      return false
    }
    val verticesArrayArray = COSArray()
    verticesArrayArray.add(verticesArray)
    freehand.cosObject.setItem(COSName.INKLIST, verticesArrayArray)
    return true
  }

  override fun undoAnnotation(fileName: String, pageNo: Long): Boolean {
    val document = openPdf(fileName)
    val page = document.getPage(Math.toIntExact(pageNo))
    var removed: PDAnnotation? = null
    val annotations = page.annotations
    val annotationsLength = annotations.size
    if (annotationsLength > 0) {
      removed = annotations.removeAt(annotationsLength - 1)
      for (ann in annotations) {
        ann.constructAppearances(document)
      }
    }
    closePdf(document)
    return (removed != null)
  }

  companion object {
    private const val ANNOTATION_PADDING: Int = 6
    private val DEFAULT_COLOR: List<Double> = mutableListOf(1.0, 0.0, 0.0, 0.0)
    private const val DEFAULT_FONT_SIZE: Double = 12.0
    const val INITIAL_MIN_VALUE = Float.MAX_VALUE
    const val INITIAL_MAX_VALUE = Float.MIN_VALUE
    const val TAG = "PdfAnnotationsPlugin"
  }
}