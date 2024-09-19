import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ShopData {
  final String shopName;
  final String deliverDate;
  final String pcs;
  final String receivedDate;
  final String rate;
  final double total;
  final String bagHandle;
  final bool isCompleted;
  final String other;
  final String size;
  final String tailorName;

  ShopData({
    required this.shopName,
    required this.deliverDate,
    required this.pcs,
    required this.receivedDate,
    required this.rate,
    required this.total,
    required this.bagHandle,
    required this.isCompleted,
    required this.other,
    required this.size,
    required this.tailorName,
  });

  factory ShopData.fromDocument(Map<String, dynamic> data) {
    return ShopData(
      shopName: data['shopName'] ?? '',
      deliverDate: data['date'] ?? '',
      pcs: data['pcs'] ?? '',
      receivedDate: data['reDate'] ?? '',
      rate: data['rate'] ?? '',
      total: (data['totalAmount'] ?? 0).toDouble(),
      bagHandle: data['Handle'] ?? '',
      isCompleted: data['isCompleted'] ?? false,
      other: data['other'] ?? '',
      size: data['size'] ?? '',
      tailorName: data['tailorName'] ?? '',

    );
  }
}

class ShopScreen extends StatefulWidget {
  @override
  _ShopScreenState createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  List<ShopData> allData = [];
  List<ShopData> filteredData = [];
  DateTimeRange? dateRange;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    fetchData();
    _searchController.addListener(() {
      filterData();
    });
  }

  Future<void> fetchData() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('JobCollection').where('isCompleted',isEqualTo: true).orderBy('reDate', descending: true).get();
      setState(() {
        allData = snapshot.docs
            .map((doc) => ShopData.fromDocument(doc.data()))
            .toList();
        filteredData = allData; // Initialize filteredData with allData
      });
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  void _selectDateRange() async {
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: dateRange,
    );
    if (pickedRange != null) {
      setState(() {
        dateRange = pickedRange;
        filterData();
      });
    }
  }

  void filterData() {
    String query = _searchController.text.toLowerCase();
    print('Search Query: $query'); // Debugging line

    filteredData = allData.where((data) {
      bool matchesDateRange = true;
      if (dateRange != null) {
        try {
          DateTime deliverDate = _parseDate(data.receivedDate);
          matchesDateRange =  (deliverDate.isAfter(dateRange!.start) || deliverDate.isAtSameMomentAs(dateRange!.start)) &&
              (deliverDate.isBefore(dateRange!.end) || deliverDate.isAtSameMomentAs(dateRange!.end));
          print("match time ...$matchesDateRange");
        } catch (e) {
          print('Error parsing date for ${data.deliverDate}: $e');
          matchesDateRange = false;
        }
      }

      bool matchesQuery = data.shopName.toLowerCase().contains(query) ||
          data.tailorName.toLowerCase().contains(query) ||
      data.deliverDate.contains(query);

      print('Data: ${data.shopName}, ${data.tailorName}, Matches: $matchesQuery'); // Debugging line
      return matchesDateRange && matchesQuery;
    }).toList();

    print('Filtered Data Length: ${filteredData.length}'); // Debugging line
    setState(() {}); // Ensure UI updates
  }

  DateTime _parseDate(String dateString) {
    // Try different date formats if necessary
    try {
      return DateTime.parse(dateString);
    } catch (_) {
      // Handle different date formats or invalid formats here
      throw FormatException('Invalid date format for $dateString');
    }
  }

  Future<void> exportToExcel(BuildContext context) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Sheet1'];

    List<String> headers = [' Received Date', 'Shop Name', 'Tailor Name', 'Size', 'Handle/Without Handle', 'Other', 'Pcs', 'Rate', 'Total'];
    for (int i = 0; i < headers.length; i++) {
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value = TextCellValue(headers[i]);
    }

    for (int i = 0; i < filteredData.length; i++) {
      ShopData item = filteredData[i];
       sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1)).value = TextCellValue(DateFormat('dd/MM/yyyy').format(DateFormat('yyyy-MM-dd').parse(item.receivedDate)));
       sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 1)).value = TextCellValue(item.shopName);
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: i + 1)).value = TextCellValue(item.tailorName);
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: i + 1)).value = TextCellValue(item.size);
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: i + 1)).value = TextCellValue(item.bagHandle);
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: i + 1)).value = TextCellValue(item.other);
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: i + 1)).value = TextCellValue(item.pcs);
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: i + 1)).value = TextCellValue(item.rate);
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: i + 1)).value = DoubleCellValue(item.total);
    }

    var status = await Permission.storage.request();
    if (status.isGranted) {
      Directory? downloadsDirectory = await getExternalStorageDirectory();
      // String filePath = '${downloadsDirectory?.path}/shop_data_export.xlsx';
      String formattedDate = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      String filePath = '/storage/emulated/0/Download/shop_data_export_$formattedDate.xlsx';

      List<int>? fileBytes = excel.save();
      if (fileBytes != null) {
        File(filePath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(fileBytes);
        print('File saved at $filePath');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Excel file saved to: $filePath')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Storage permission denied')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Shop Data'),
        backgroundColor: Colors.amber,
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_month),
            onPressed: _selectDateRange,
          ),
          IconButton(
            icon: Icon(Icons.file_download),
            onPressed: () async {
              await exportToExcel(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by shop and tailor name',
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text('Received Date')),
                    DataColumn(label: Text('Shop Name')),
                    DataColumn(label: Text('Tailor Name')),
                    DataColumn(label: Text('Size')),
                    DataColumn(label: Text('Handle/Without Handle')),
                    DataColumn(label: Text('Other')),
                    DataColumn(label: Text('Pcs')),
                    DataColumn(label: Text('Rate')),
                    DataColumn(label: Text('Total')),
                  ],
                  rows: filteredData.map((item) {
                    return DataRow(
                      cells: [
                        DataCell(Text('${DateFormat('dd/MM/yyyy').format(DateFormat('yyyy-MM-dd').parse(item.receivedDate))}')),
                        DataCell(Text(item.shopName)),
                        DataCell(Text(item.tailorName)),
                        DataCell(Text(item.size)),
                        DataCell(Align( child: Text(item.bagHandle))),
                        DataCell(Text(item.other)),
                        DataCell(Text(item.pcs)),
                        DataCell(Text(item.rate)),
                        DataCell(Text(item.total.toString())),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );

  }
}
