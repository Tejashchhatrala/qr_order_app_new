import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/order.dart';
import '../models/cart.dart';

class LocalStorageService {
  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'qr_order.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE orders(
            id TEXT PRIMARY KEY,
            data TEXT,
            synced INTEGER,
            createdAt INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE cart(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            vendorId TEXT,
            data TEXT
          )
        ''');
      },
    );
  }

  Future<void> saveOrder(Order order) async {
    final db = await database;
    await db.insert(
      'orders',
      {
        'id': order.id,
        'data': json.encode(order.toMap()),
        'synced': 0,
        'createdAt': order.createdAt.millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveCart(Cart cart) async {
    final db = await database;
    await db.insert(
      'cart',
      {
        'vendorId': cart.vendorId,
        'data': json.encode(cart.toMap()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
