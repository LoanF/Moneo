import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

part 'app_database.g.dart';

class Transactions extends Table {
  TextColumn get id => text()();
  RealColumn get amount => real()();
  TextColumn get type => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();
  BoolColumn get isChecked => boolean().withDefault(const Constant(false))();
  TextColumn get accountId => text()();
  TextColumn get categoryId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class BankAccounts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get balance => real().withDefault(const Constant(0.0))();
  
  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Transactions, BankAccounts])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}