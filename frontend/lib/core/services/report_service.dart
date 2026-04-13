import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportService {
  static const _darkBase = PdfColor.fromInt(0xFF1A1A2E);
  static const _cyan = PdfColor.fromInt(0xFF00C2CB);
  static const _lightBg = PdfColor.fromInt(0xFFF4F7FB);
  static const _textLight = PdfColor.fromInt(0xFF8A9BB0);
  static const _green = PdfColor.fromInt(0xFF2ECC71);
  static const _orange = PdfColor.fromInt(0xFFE67E22);
  static const _red = PdfColor.fromInt(0xFFE74C3C);
  static const _purple = PdfColor.fromInt(0xFF9B59B6);
  static const _border = PdfColor.fromInt(0xFFE8ECF2);
  static const _greenBg = PdfColor.fromInt(0xFFD5F5E3);
  static const _orangeBg = PdfColor.fromInt(0xFFFDEBD0);
  static const _redBg = PdfColor.fromInt(0xFFFADEDA);
  static const _cyanBg = PdfColor.fromInt(0xFFD0F4F5);
  static const _purpleBg = PdfColor.fromInt(0xFFEBD5F5);

  static PdfColor _statusColor(String status) {
    if (status.contains('Optimal')) return _green;
    if (status.contains('Warning') || status == 'Initial Cracking') return _orange;
    return _red;
  }

  static PdfColor _statusBgColor(String status) {
    if (status.contains('Optimal')) return _greenBg;
    if (status.contains('Warning') || status == 'Initial Cracking') return _orangeBg;
    return _redBg;
  }

  static pw.Widget _divider() => pw.Container(
        height: 1,
        color: _border,
        margin: const pw.EdgeInsets.symmetric(vertical: 8),
      );

  static pw.Widget _statusBadge(String status) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: pw.BoxDecoration(
          color: _statusBgColor(status),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(20)),
          border: pw.Border.all(color: _statusColor(status), width: 0.8),
        ),
        child: pw.Text(
          status,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: _statusColor(status),
          ),
        ),
      );

  static pw.Widget _kpiRow(
    String label,
    String value, {
    String? note,
    PdfColor noteColor = _textLight,
  }) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 5),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label,
                style: const pw.TextStyle(fontSize: 10, color: _textLight)),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(value,
                    style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: _darkBase)),
                if (note != null)
                  pw.Text(note,
                      style: pw.TextStyle(
                          fontSize: 8,
                          color: noteColor,
                          fontStyle: pw.FontStyle.italic)),
              ],
            ),
          ],
        ),
      );

  static pw.Widget _progressBar(
          double value, PdfColor color, PdfColor bgColor) =>
      pw.Stack(
        children: [
          pw.Container(
            height: 6,
            decoration: pw.BoxDecoration(
              color: bgColor,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
            ),
          ),
          pw.Container(
            height: 6,
            width: 200 * value.clamp(0.0, 1.0),
            decoration: pw.BoxDecoration(
              color: color,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
            ),
          ),
        ],
      );

  static pw.Widget _trendRow(
          String label, double ratio, PdfColor color, PdfColor bgColor) =>
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(label,
                    style: const pw.TextStyle(fontSize: 9, color: _textLight)),
                pw.Text(
                    '${(ratio.clamp(0.0, 1.0) * 100).toStringAsFixed(0)}%',
                    style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: color)),
              ],
            ),
            pw.SizedBox(height: 3),
            _progressBar(ratio, color, bgColor),
          ],
        ),
      );

  static List<pw.Widget> _recommendations(
    String tempStatus,
    String pressureStatus,
    double ethyleneYield,
    double co2Emissions,
  ) {
    final recs = <String>[];
    if (tempStatus == 'No Cracking') {
      recs.add(
          'Increase reactor temperature to at least 820C to initiate cracking reactions.');
    } else if (tempStatus == 'Over-Cracking') {
      recs.add(
          'Reduce temperature below 900C to prevent secondary reactions that reduce ethylene yield.');
    } else if (tempStatus == 'Optimal') {
      recs.add(
          'Temperature is within the optimal range (820-880C). Maintain current settings.');
    }
    if (pressureStatus == 'Suppressed') {
      recs.add(
          'Lower operating pressure to below 1.5 bar for maximum ethylene yield.');
    } else if (pressureStatus == 'Warning') {
      recs.add(
          'Consider reducing pressure to improve cracking efficiency and reduce by-products.');
    } else if (pressureStatus == 'Optimal') {
      recs.add('Pressure is optimal. No changes required.');
    }
    if (ethyleneYield < 25) {
      recs.add(
          'Ethylene yield is below 25%. Review feed composition and operating conditions.');
    }
    if (co2Emissions > 430) {
      recs.add(
          'CO2 emissions are elevated. Consider optimising fuel duty or feed preheating.');
    }
    if (recs.isEmpty) {
      recs.add(
          'All operating parameters are within optimal ranges. Continue monitoring.');
    }

    return recs.asMap().entries.map((e) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: 18,
              height: 18,
              margin: const pw.EdgeInsets.only(right: 10, top: 1),
              decoration: const pw.BoxDecoration(
                color: _greenBg,
                shape: pw.BoxShape.circle,
              ),
              child: pw.Center(
                child: pw.Text('${e.key + 1}',
                    style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: _green)),
              ),
            ),
            pw.Expanded(
              child: pw.Text(e.value,
                  style: const pw.TextStyle(fontSize: 9, color: _darkBase)),
            ),
          ],
        ),
      );
    }).toList();
  }

  static String _monthName(int m) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[m - 1];
  }

  static Future<void> generateAndShare({
    required String scenarioTitle,
    required String feedType,
    required String temperature,
    required String pressure,
    required String overallStatus,
    required String tempStatus,
    required String tempMessage,
    required String pressureStatus,
    required String pressureMessage,
    required double ethyleneYield,
    required double co2Emissions,
    required double fuelDuty,
    required double h2Recovery,
    required String userName,
    required String userEmail,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateStr =
        '${_monthName(now.month)} ${now.day}, ${now.year}  ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (ctx) => pw.Column(
          children: [
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const pw.BoxDecoration(
                color: _darkBase,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(10)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('CrackerIQ',
                          style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white)),
                      pw.Text('Simulation Report',
                          style: const pw.TextStyle(
                              fontSize: 10, color: PdfColors.grey300)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(dateStr,
                          style: const pw.TextStyle(
                              fontSize: 9, color: PdfColors.grey300)),
                      pw.Text(
                          'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                          style: const pw.TextStyle(
                              fontSize: 9, color: PdfColors.grey300)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
          ],
        ),
        footer: (_) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 8),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                  'Generated by CrackerIQ - Mixed Feed Steam Cracker App',
                  style:
                      const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
              pw.Text('CONFIDENTIAL',
                  style: pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey,
                      fontStyle: pw.FontStyle.italic)),
            ],
          ),
        ),
        build: (_) => [
          // Scenario header card
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: const pw.BoxDecoration(
              color: _lightBg,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(10)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(scenarioTitle,
                            style: pw.TextStyle(
                                fontSize: 13,
                                fontWeight: pw.FontWeight.bold,
                                color: _darkBase)),
                        pw.SizedBox(height: 4),
                        pw.Text('Feed Type: $feedType',
                            style: const pw.TextStyle(
                                fontSize: 9, color: PdfColors.grey600)),
                      ],
                    ),
                    _statusBadge(overallStatus),
                  ],
                ),
                _divider(),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('PREPARED FOR',
                              style: const pw.TextStyle(
                                  fontSize: 8, color: PdfColors.grey)),
                          pw.SizedBox(height: 2),
                          pw.Text(
                              userName.isNotEmpty ? userName : 'Engineer',
                              style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                  color: _darkBase)),
                          pw.Text(userEmail,
                              style: const pw.TextStyle(
                                  fontSize: 8, color: PdfColors.grey600)),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text('DATE GENERATED',
                              style: const pw.TextStyle(
                                  fontSize: 8, color: PdfColors.grey)),
                          pw.SizedBox(height: 2),
                          pw.Text(dateStr,
                              style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold,
                                  color: _darkBase)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 16),
          pw.Text('Operating Conditions',
              style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: _darkBase)),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(14),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    border: pw.Border.all(
                        color: _statusColor(tempStatus), width: 1),
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(10)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('OUTLET TEMPERATURE',
                          style: const pw.TextStyle(
                              fontSize: 8, color: PdfColors.grey)),
                      pw.SizedBox(height: 4),
                      pw.Text('$temperature C',
                          style: pw.TextStyle(
                              fontSize: 22,
                              fontWeight: pw.FontWeight.bold,
                              color: _darkBase)),
                      pw.SizedBox(height: 6),
                      _statusBadge(tempStatus),
                      pw.SizedBox(height: 6),
                      pw.Text(tempMessage,
                          style: pw.TextStyle(
                              fontSize: 8,
                              color: _statusColor(tempStatus),
                              fontStyle: pw.FontStyle.italic)),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(14),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    border: pw.Border.all(
                        color: _statusColor(pressureStatus), width: 1),
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(10)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('OUTLET PRESSURE',
                          style: const pw.TextStyle(
                              fontSize: 8, color: PdfColors.grey)),
                      pw.SizedBox(height: 4),
                      pw.Text('$pressure bar',
                          style: pw.TextStyle(
                              fontSize: 22,
                              fontWeight: pw.FontWeight.bold,
                              color: _darkBase)),
                      pw.SizedBox(height: 6),
                      _statusBadge(pressureStatus),
                      pw.SizedBox(height: 6),
                      pw.Text(pressureMessage,
                          style: pw.TextStyle(
                              fontSize: 8,
                              color: _statusColor(pressureStatus),
                              fontStyle: pw.FontStyle.italic)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 16),
          pw.Text('Key Performance Indicators',
              style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: _darkBase)),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
              border: pw.Border.all(color: _border),
            ),
            child: pw.Column(
              children: [
                _kpiRow('Ethylene Yield',
                    '${ethyleneYield.toStringAsFixed(1)}%',
                    note: ethyleneYield >= 30 ? 'Above target' : 'Below target',
                    noteColor: ethyleneYield >= 30 ? _green : _orange),
                _divider(),
                _kpiRow('CO2 Emissions',
                    '${co2Emissions.toStringAsFixed(0)} kg/h',
                    note: co2Emissions < 400 ? 'Within limits' : 'Elevated',
                    noteColor: co2Emissions < 400 ? _green : _orange),
                _divider(),
                _kpiRow('Fuel Duty', '${fuelDuty.toStringAsFixed(1)} GJ/h'),
                _divider(),
                _kpiRow('H2 Recovery', '${h2Recovery.toStringAsFixed(1)}%',
                    note: h2Recovery >= 75 ? 'Good recovery' : 'Low recovery',
                    noteColor: h2Recovery >= 75 ? _green : _orange),
              ],
            ),
          ),

          pw.SizedBox(height: 16),
          pw.Text('Trend Analysis',
              style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: _darkBase)),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
              border: pw.Border.all(color: _border),
            ),
            child: pw.Column(
              children: [
                _trendRow('Ethylene Yield', ethyleneYield / 40, _cyan, _cyanBg),
                _trendRow('H2 Recovery', h2Recovery / 100, _green, _greenBg),
                _trendRow('CO2 Efficiency', 1 - (co2Emissions / 600),
                    _orange, _orangeBg),
                _trendRow('Fuel Efficiency', 1 - (fuelDuty / 20),
                    _purple, _purpleBg),
              ],
            ),
          ),

          pw.SizedBox(height: 16),
          pw.Text('Recommendations',
              style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: _darkBase)),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: const pw.BoxDecoration(
              color: _lightBg,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(10)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: _recommendations(
                  tempStatus, pressureStatus, ethyleneYield, co2Emissions),
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name: 'CrackerIQ_${scenarioTitle.replaceAll(' ', '_')}_Report.pdf',
    );
  }
}
