import 'dart:convert';

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
  BoolColumn get isMonthly => boolean().withDefault(const Constant(false))();

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

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  @JsonKey('iconCode')
  IntColumn get iconCode => integer()();
  @JsonKey('colorValue')
  IntColumn get colorValue => integer()();
  @JsonKey('userId')
  TextColumn get userId => text()();
  @JsonKey('parentId')
  TextColumn get parentId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class MonthlyPayments extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get amount => real()();
  TextColumn get type => text()();
  IntColumn get dayOfMonth => integer()();
  TextColumn get accountId => text()();
  TextColumn get categoryId => text().nullable()();
  DateTimeColumn get lastApplied => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class PaymentMethodsConverter extends TypeConverter<List<Map<String, dynamic>>, String> {
  const PaymentMethodsConverter();

  @override
  List<Map<String, dynamic>> fromSql(String fromDb) {
    final List<dynamic> decoded = jsonDecode(fromDb) as List<dynamic>;
    return decoded.map((e) => e as Map<String, dynamic>).toList();
  }

  @override
  String toSql(List<Map<String, dynamic>> value) {
    return jsonEncode(value);
  }
}

class Users extends Table {
  TextColumn get id => text()();
  TextColumn get displayName => text()();
  TextColumn get email => text()();
  TextColumn get photoUrl => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get fcmToken => text().nullable()();
  BoolColumn get hasCompletedSetup => boolean().withDefault(const Constant(false))();

  TextColumn get paymentMethods => text().map(const PaymentMethodsConverter()).nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Transactions, BankAccounts, Categories, MonthlyPayments, Users])
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