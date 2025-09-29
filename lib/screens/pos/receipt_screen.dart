// lib/screens/pos/receipt_screen.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pos_app/database/database_helper.dart';
import 'package:pos_app/models/transaction_model.dart' as model;
import 'package:screenshot/screenshot.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

class ReceiptScreen extends StatefulWidget {
  final int transactionId;
  const ReceiptScreen({super.key, required this.transactionId});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  late Future<Map<String, dynamic>> _detailsFuture;

  // 1. Buat ScreenshotController
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _detailsFuture = _loadTransactionDetails();
  }

  Future<Map<String, dynamic>> _loadTransactionDetails() async {
    final transaction =
        await DatabaseHelper.instance.getTransactionById(widget.transactionId);
    final details = await DatabaseHelper.instance
        .getTransactionDetails(widget.transactionId);
    return {'transaction': transaction, 'details': details};
  }

  // 2. Buat fungsi untuk download struk
  void _downloadReceipt() async {
    // Minta izin penyimpanan
    var status = await Permission.storage.request();
    if (status.isGranted) {
      // Tangkap widget sebagai gambar (Uint8List)
      final Uint8List? image = await _screenshotController.capture();

      if (image != null) {
        // Simpan gambar ke galeri
        final result = await ImageGallerySaver.saveImage(image);
        if (result['isSuccess']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Struk berhasil disimpan di galeri!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menyimpan struk.')),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Izin penyimpanan ditolak.')),
      );
    }

    // Kembali ke halaman utama
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Struk Pembayaran'),
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!['transaction'] == null) {
            return const Center(child: Text('Gagal memuat detail transaksi.'));
          }

          final model.Transaction transaction = snapshot.data!['transaction'];
          final List<model.TransactionDetail> details =
              snapshot.data!['details'];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 3. Bungkus struk dengan Screenshot Widget
                Screenshot(
                  controller: _screenshotController,
                  child: Card(
                    elevation: 2,
                    color: Colors
                        .white, // Pastikan ada background color agar tidak transparan
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                              child: Text('--- STRUK PEMBAYARAN ---',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold))),
                          const SizedBox(height: 20),
                          Text('No. Transaksi: #${transaction.id}'),
                          Text(
                              'Tanggal: ${DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(transaction.transactionDate)}'),
                          const Divider(height: 30),
                          ...details
                              .map((item) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                            child: Text(
                                                '${item.quantity}x ${item.productName}')),
                                        Text(
                                            'Rp. ${item.priceAtTransaction * item.quantity}'),
                                      ],
                                    ),
                                  ))
                              .toList(),
                          const Divider(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('TOTAL',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              Text('Rp. ${transaction.totalAmount}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.blue)),
                            ],
                          ),
                          const SizedBox(height: 30),
                          const Center(
                              child: Text('--- Terima Kasih ---',
                                  style: TextStyle(color: Colors.grey))),
                        ],
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                // 4. Ubah tombol dan panggil fungsi download
                ElevatedButton.icon(
                  icon: const Icon(Icons.download),
                  onPressed: _downloadReceipt,
                  label: const Text('OK & Download Struk'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
