import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/account.dart';
import '../models/category.dart';
import '../models/transaction.dart';

class CloudSyncService {
  final FirebaseAuth? _authOverride;
  final FirebaseFirestore? _firestoreOverride;
  final GoogleSignIn _googleSignIn;

  CloudSyncService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _authOverride = auth,
        _firestoreOverride = firestore,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore => _firestoreOverride ?? FirebaseFirestore.instance;

  User? get currentUser {
    try {
      return _auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Inicio de sesión cancelado');
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  CollectionReference<Map<String, dynamic>> _accountsCol(String uid) {
    return _userDoc(uid).collection('accounts');
  }

  CollectionReference<Map<String, dynamic>> _categoriesCol(String uid) {
    return _userDoc(uid).collection('categories');
  }

  CollectionReference<Map<String, dynamic>> _transactionsCol(String uid) {
    return _userDoc(uid).collection('transactions');
  }

  Future<void> uploadAll({
    required List<Account> accounts,
    required List<Category> categories,
    required List<Transaction> transactions,
    required String? selectedMonthKey,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No hay sesión iniciada');

    final uid = user.uid;
    final batch = _firestore.batch();

    final accountsSnap = await _accountsCol(uid).get();
    for (final doc in accountsSnap.docs) {
      batch.delete(doc.reference);
    }

    final categoriesSnap = await _categoriesCol(uid).get();
    for (final doc in categoriesSnap.docs) {
      batch.delete(doc.reference);
    }

    final transactionsSnap = await _transactionsCol(uid).get();
    for (final doc in transactionsSnap.docs) {
      batch.delete(doc.reference);
    }

    batch.set(
      _userDoc(uid),
      {
        'updatedAt': FieldValue.serverTimestamp(),
        'selectedMonthKey': selectedMonthKey,
      },
      SetOptions(merge: true),
    );

    for (final a in accounts) {
      batch.set(_accountsCol(uid).doc(a.id), a.toMap());
    }
    for (final c in categories) {
      batch.set(_categoriesCol(uid).doc(c.id), c.toMap());
    }
    for (final t in transactions) {
      batch.set(_transactionsCol(uid).doc(t.id), t.toMap());
    }

    await batch.commit();
  }

  Future<({
    List<Account> accounts,
    List<Category> categories,
    List<Transaction> transactions,
    String? selectedMonthKey,
  })> downloadAll() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No hay sesión iniciada');

    final uid = user.uid;

    final userSnap = await _userDoc(uid).get();
    final selectedMonthKey = userSnap.data()?['selectedMonthKey'] as String?;

    final accountsSnap = await _accountsCol(uid).get();
    final categoriesSnap = await _categoriesCol(uid).get();
    final transactionsSnap = await _transactionsCol(uid).get();

    final accounts = accountsSnap.docs
        .map((d) => Account.fromMap(Map<String, dynamic>.from(d.data())))
        .toList();
    final categories = categoriesSnap.docs
        .map((d) => Category.fromMap(Map<String, dynamic>.from(d.data())))
        .toList();
    final transactions = transactionsSnap.docs
        .map((d) => Transaction.fromMap(Map<String, dynamic>.from(d.data())))
        .toList();

    return (
      accounts: accounts,
      categories: categories,
      transactions: transactions,
      selectedMonthKey: selectedMonthKey,
    );
  }
}
