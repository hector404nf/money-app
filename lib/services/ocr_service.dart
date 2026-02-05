import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../utils/invoice_parser.dart';

// Re-export or alias for compatibility if needed, but better to use InvoiceParser directly
// for logic. However, OcrService wraps the ML Kit part.
export '../utils/invoice_parser.dart' show InvoiceParser; 

// Backward compatibility for existing code using OcrResult
// actually, let's just use InvoiceParser result or map it.
// Since we just created OcrService, we can change OcrResult to be just the class from InvoiceParser
// But wait, InvoiceParser is the class name for the logic AND the result holder? 
// Let's check my implementation of InvoiceParser...
// Yes, it has the fields amount, date, merchant.

typedef OcrResult = InvoiceParser;

class OcrService {
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<OcrResult> processImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    
    return InvoiceParser.parse(recognizedText);
  }

  Future<void> dispose() async {
    await _textRecognizer.close();
  }
}
