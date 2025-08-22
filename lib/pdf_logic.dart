import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'dart:typed_data';

class PDFGenerator {
  // Export schedule to PDF with table format similar to CSV
  static Future<String?> exportScheduleToPDF(List<Map<String, dynamic>> schedule, String algorithm) async {
    try {
      final pdf = pw.Document();
      
      // Create timestamp for filename
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return [
              // Header Section
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 20),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Resource Allocation Schedule',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Algorithm: $algorithm',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue700,
                          ),
                        ),
                        pw.Text(
                          'Total Requests: ${schedule.length}',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Generated on: ${DateTime.now().toString().split('.')[0]}',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Schedule Table (matching CSV format)
              if (schedule.isNotEmpty)
                pw.Table(
                  border: pw.TableBorder.all(
                    color: PdfColors.grey600,
                    width: 0.8,
                  ),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1.2), // Request_ID
                    1: const pw.FlexColumnWidth(1.5), // User_Name
                    2: const pw.FlexColumnWidth(1.3), // Resource_Type
                    3: const pw.FlexColumnWidth(0.8), // Quantity
                    4: const pw.FlexColumnWidth(1.2), // Date
                    5: const pw.FlexColumnWidth(1.0), // Start_Time
                    6: const pw.FlexColumnWidth(1.0), // End_Time
                    7: const pw.FlexColumnWidth(1.0), // Duration_Hours
                    8: const pw.FlexColumnWidth(0.8), // Arrival_Time
                    9: const pw.FlexColumnWidth(0.8), // Priority
                    10: const pw.FlexColumnWidth(0.8), // Burst_Time
                  },
                  children: [
                    // Header row (matching CSV headers exactly)
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.blue900,
                      ),
                      children: [
                        _buildTableCell('Request ID', isHeader: true),
                        _buildTableCell('User Name', isHeader: true),
                        _buildTableCell('Resource Type', isHeader: true),
                        _buildTableCell('Quantity', isHeader: true),
                        _buildTableCell('Date', isHeader: true),
                        _buildTableCell('Start Time', isHeader: true),
                        _buildTableCell('End Time', isHeader: true),
                        _buildTableCell('Duration (h)', isHeader: true),
                        _buildTableCell('Arrival', isHeader: true),
                        _buildTableCell('Priority', isHeader: true),
                        _buildTableCell('Burst Time', isHeader: true),
                      ],
                    ),
                    // Data rows (matching CSV format exactly)
                    ...schedule.asMap().entries.map((entry) {
                      int index = entry.key;
                      Map<String, dynamic> item = entry.value;
                      
                      return pw.TableRow(
                        decoration: pw.BoxDecoration(
                          color: index % 2 == 0 ? PdfColors.grey100 : PdfColors.white,
                        ),
                        children: [
                          _buildTableCell('${item['request_id'] ?? ''}'),
                          _buildTableCell('${item['user_name'] ?? ''}'),
                          _buildTableCell('${item['resource_type'] ?? ''}'),
                          _buildTableCell('${item['quantity'] ?? ''}'),
                          _buildTableCell('${item['date'] ?? ''}'),
                          _buildTableCell('${item['start_time'] ?? ''}'),
                          _buildTableCell('${item['end_time'] ?? ''}'),
                          _buildTableCell('${item['duration'] ?? ''}'),
                          _buildTableCell('${item['arrival_time'] ?? ''}'),
                          _buildTableCell('${item['priority'] ?? ''}'),
                          _buildTableCell('${item['burst_time'] ?? ''}'),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              
              // Empty state message
              if (schedule.isEmpty)
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(30),
                  child: pw.Center(
                    child: pw.Column(
                      children: [
                        pw.Text(
                          '📋',
                          style: const pw.TextStyle(fontSize: 40),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Text(
                          'No schedule data available',
                          style: pw.TextStyle(
                            fontSize: 16,
                            color: PdfColors.grey600,
                            fontStyle: pw.FontStyle.italic,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Create some resource requests to generate a schedule',
                          style: const pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Footer
              pw.SizedBox(height: 20),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(color: PdfColors.grey400, width: 1),
                  ),
                ),
                child: pw.Text(
                  'Resource Allocator App • Working Hours: 9:00 AM - 5:00 PM • Generated: ${DateTime.now().toString().split(' ')[0]}',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey500,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ];
          },
        ),
      );
      
      // Save PDF file
      String fileName = 'schedule_${algorithm.toLowerCase()}_$timestamp.pdf';
      String exportPath = '/storage/emulated/0/Download/$fileName';
      
      final Uint8List bytes = await pdf.save();
      File pdfFile = File(exportPath);
      await pdfFile.writeAsBytes(bytes);
      
      print('Schedule exported to PDF: $exportPath');
      return exportPath;
    } catch (e) {
      print('Error exporting schedule to PDF: $e');
      return null;
    }
  }

  // Helper method to build table cells
  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 9 : 8,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.white : PdfColors.black,
        ),
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.left,
        overflow: pw.TextOverflow.clip,
      ),
    );
  }
}
