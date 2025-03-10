import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'storage_service.dart';
import '../models/catalog_models.dart';
import '../services/local_storage_service.dart';
import 'retry_service.dart';

class SyncService {
  final StorageService _storageService = StorageService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId = FirebaseAuth.instance.currentUser!.uid;
  final LocalStorageService _storage = LocalStorageService();

  // Singleton pattern
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  Future<bool> isConnected() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Future<void> syncCatalog() async {
    if (!await isOnline()) {
      throw ConnectivityException('No internet connection');
    }

    return RetryService.retry(
      operation: () => _performCatalogSync(),
      maxAttempts: 3,
    );
  }

  Future<void> _performCatalogSync() async {
    try {
      // Get local catalog
      final localCatalog = await _storageService.getCatalog(_userId);

      // Get server catalog
      final serverDoc = await _firestore
          .collection('vendors')
          .doc(_userId)
          .collection('catalog')
          .doc('data')
          .get();

      if (!serverDoc.exists && localCatalog != null) {
        // Upload local catalog to server
        await _uploadCatalog(localCatalog);
      } else if (serverDoc.exists) {
        // Compare timestamps and sync accordingly
        final serverData = serverDoc.data()!;
        final serverTimestamp = serverData['lastUpdated'] as Timestamp;

        if (localCatalog != null) {
          // TODO: Implement proper conflict resolution
          // For now, server wins
          await _downloadCatalog(serverDoc);
        } else {
          await _downloadCatalog(serverDoc);
        }
      }
    } catch (e) {
      throw SyncException('Failed to sync catalog: $e');
    }
  }

  Future<void> _uploadCatalog(List<Category> catalog) async {
    await _firestore
        .collection('vendors')
        .doc(_userId)
        .collection('catalog')
        .doc('data')
        .set({
      'categories': catalog.map((c) => c.toMap()).toList(),
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _downloadCatalog(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final categories =
        (data['categories'] as List).map((c) => Category.fromMap(c)).toList();

    await _storageService.saveCatalog(_userId, categories);
  }

  Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Future<void> syncPendingOrders() async {
    if (!await isOnline()) return;

    final db = await _storage.database;
    final pendingOrders = await db.query(
      'orders',
      where: 'synced = ?',
      whereArgs: [0],
    );

    for (final orderData in pendingOrders) {
      await RetryService.retry(
        operation: () => _syncOrder(orderData, db),
        maxAttempts: 3,
        delay: const Duration(seconds: 2),
      );
    }
  }

  Future<void> _syncOrder(Map<String, dynamic> orderData, Database db) async {
    try {
      final order = Order.fromMap(
        json.decode(orderData['data'] as String),
        orderData['id'] as String,
      );

      await _firestore.collection('orders').doc(order.id).set(order.toMap());

      await db.update(
        'orders',
        {'synced': 1},
        where: 'id = ?',
        whereArgs: [order.id],
      );
    } catch (e) {
      print('Error syncing order ${orderData['id']}: $e');
      throw SyncException('Failed to sync order: ${orderData['id']}');
    }
  }
}

class SyncException implements Exception {
  final String message;
  SyncException(this.message);
  @override
  String toString() => message;
}

class ConnectivityException implements Exception {
  final String message;
  ConnectivityException(this.message);
  @override
  String toString() => message;
}
