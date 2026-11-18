import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models.dart';

class AuthUser {
  final String uid, email;
  const AuthUser(this.uid, this.email);
}

final _rnd = math.Random.secure();
String newId() => List.generate(20, (_) => 'abcdefghijklmnopqrstuvwxyz0123456789'[_rnd.nextInt(36)]).join();

abstract class Api {
  bool get demo;
  Stream<AuthUser?> authChanges();
  Future<void> signInGoogle();
  Future<void> signInEmail(String email, String password);
  Future<void> signUpEmail(String email, String password);
  Future<void> resetPassword(String email);
  Future<void> signOut();
  Future<void> deleteAccount(String uid);

  Future<ParentDoc?> getParent(String uid);
  Future<void> saveParent(ParentDoc p);
  Future<List<ChildProfile>> listChildren(String uid);
  Future<void> saveChild(String uid, ChildProfile c);
  Future<void> deleteChild(String uid, String childId);

  Future<void> addSession(String uid, String childId, SessionLog s);
  Future<List<SessionLog>> listSessions(String uid, String childId, int sinceMs);

  Future<void> saveRecording(String uid, Recording r);
  Future<List<Recording>> listRecordings(String uid, String childId);
  Future<void> deleteRecording(String uid, String childId, String id);

  Future<void> saveComposition(String uid, Composition c);
  Future<List<Composition>> listCompositions(String uid, String childId);
  Future<void> deleteComposition(String uid, String childId, String id);

  Future<String> createShare(ShareDoc s);
  Future<ShareDoc?> getShare(String id);
  Future<void> heartShare(String id);
  Future<List<ShareDoc>> listShares(String uid);
  Future<void> deleteShare(String id);

  Future<void> registerInvite(String code, String uid);
  Future<bool> joinInvite(String code, String uid);
  Future<int> countInviteJoins(String code);
}

Json _m(Object? v) => Map<String, dynamic>.from(v as Map);

// ------------------------------------------------------------------ Firebase
class FirebaseApi implements Api {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  @override
  bool get demo => false;

  CollectionReference<Json> _kids(String uid) => _db.collection('users').doc(uid).collection('children');
  CollectionReference<Json> _sub(String uid, String cid, String name) => _kids(uid).doc(cid).collection(name);

  Future<void> _deleteAll(CollectionReference<Json> col) async {
    final snap = await col.get();
    final batch = _db.batch();
    for (final d in snap.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
  }

  @override
  Stream<AuthUser?> authChanges() => _auth.authStateChanges().map((u) => u == null ? null : AuthUser(u.uid, u.email ?? ''));
  @override
  Future<void> signInGoogle() async {
    final provider = GoogleAuthProvider();
    if (kIsWeb) {
      await _auth.signInWithPopup(provider);
    } else {
      await _auth.signInWithProvider(provider);
    }
  }

  @override
  Future<void> signInEmail(String e, String p) => _auth.signInWithEmailAndPassword(email: e, password: p);
  @override
  Future<void> signUpEmail(String e, String p) => _auth.createUserWithEmailAndPassword(email: e, password: p);
  @override
  Future<void> resetPassword(String e) => _auth.sendPasswordResetEmail(email: e);
  @override
  Future<void> signOut() => _auth.signOut();
  @override
  Future<void> deleteAccount(String uid) async {
    for (final k in await listChildren(uid)) {
      await deleteChild(uid, k.id);
    }
    for (final s in await listShares(uid)) {
      await deleteShare(s.id);
    }
    await _db.collection('users').doc(uid).delete();
    await _auth.currentUser?.delete();
  }

  @override
  Future<ParentDoc?> getParent(String uid) async {
    final s = await _db.collection('users').doc(uid).get();
    return s.exists ? ParentDoc.fromJson(s.data()!) : null;
  }

  @override
  Future<void> saveParent(ParentDoc p) => _db.collection('users').doc(p.uid).set(p.toJson());
  @override
  Future<List<ChildProfile>> listChildren(String uid) async {
    final s = await _kids(uid).get();
    return s.docs.map((d) => ChildProfile.fromJson(d.data())).toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  @override
  Future<void> saveChild(String uid, ChildProfile c) => _kids(uid).doc(c.id).set(c.toJson());
  @override
  Future<void> deleteChild(String uid, String cid) async {
    for (final name in ['sessions', 'recordings', 'compositions']) {
      await _deleteAll(_sub(uid, cid, name));
    }
    await _kids(uid).doc(cid).delete();
  }

  @override
  Future<void> addSession(String uid, String cid, SessionLog s) => _sub(uid, cid, 'sessions').doc(s.id).set(s.toJson());
  @override
  Future<List<SessionLog>> listSessions(String uid, String cid, int since) async {
    final s = await _sub(uid, cid, 'sessions').where('at', isGreaterThanOrEqualTo: since).get();
    return s.docs.map((d) => SessionLog.fromJson(d.data())).toList()..sort((a, b) => b.at.compareTo(a.at));
  }

  @override
  Future<void> saveRecording(String uid, Recording r) => _sub(uid, r.childId, 'recordings').doc(r.id).set(r.toJson());
  @override
  Future<List<Recording>> listRecordings(String uid, String cid) async {
    final s = await _sub(uid, cid, 'recordings').get();
    return s.docs.map((d) => Recording.fromJson(d.data())).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<void> deleteRecording(String uid, String cid, String id) => _sub(uid, cid, 'recordings').doc(id).delete();

  @override
  Future<void> saveComposition(String uid, Composition c) => _sub(uid, c.childId, 'compositions').doc(c.id).set(c.toJson());
  @override
  Future<List<Composition>> listCompositions(String uid, String cid) async {
    final s = await _sub(uid, cid, 'compositions').get();
    return s.docs.map((d) => Composition.fromJson(d.data())).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<void> deleteComposition(String uid, String cid, String id) => _sub(uid, cid, 'compositions').doc(id).delete();

  @override
  Future<String> createShare(ShareDoc s) async {
    final id = newId();
    await _db.collection('shares').doc(id).set({...s.toJson(), 'id': id});
    return id;
  }

  @override
  Future<ShareDoc?> getShare(String id) async {
    final s = await _db.collection('shares').doc(id).get();
    return s.exists ? ShareDoc.fromJson(s.data()!) : null;
  }

  @override
  Future<void> heartShare(String id) => _db.collection('shares').doc(id).update({'hearts': FieldValue.increment(1)});
  @override
  Future<List<ShareDoc>> listShares(String uid) async {
    final s = await _db.collection('shares').where('ownerUid', isEqualTo: uid).get();
    return s.docs.map((d) => ShareDoc.fromJson(d.data())).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<void> deleteShare(String id) => _db.collection('shares').doc(id).delete();

  @override
  Future<void> registerInvite(String code, String uid) async {
    final ref = _db.collection('invites').doc(code);
    if (!(await ref.get()).exists) await ref.set({'uid': uid, 'createdAt': DateTime.now().millisecondsSinceEpoch});
  }

  @override
  Future<bool> joinInvite(String code, String uid) async {
    final s = await _db.collection('invites').doc(code).get();
    if (!s.exists || s.data()?['uid'] == uid) return false;
    await _db.collection('invites').doc(code).collection('joins').doc(uid).set({'at': DateTime.now().millisecondsSinceEpoch});
    return true;
  }

  @override
  Future<int> countInviteJoins(String code) async => (await _db.collection('invites').doc(code).collection('joins').get()).size;
}

// ------------------------------------------------------------------ Local demo
class DemoApi implements Api {
  static const _key = 'piano-quest-demo-v1';
  late SharedPreferences _prefs;
  Json _store = {};
  final _auth = StreamController<AuthUser?>.broadcast();

  @override
  bool get demo => true;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _load();
  }

  void _load() {
    try {
      final raw = _prefs.getString(_key);
      _store = raw == null ? {} : _m(jsonDecode(raw));
    } catch (_) {
      _store = {};
    }
    for (final k in ['parents', 'children', 'sessions', 'recordings', 'compositions', 'shares', 'invites']) {
      _store[k] ??= <String, dynamic>{};
    }
  }

  Future<void> _save() => _prefs.setString(_key, jsonEncode(_store));
  Json _bucket(String name) => (_store[name] ??= <String, dynamic>{}) as Json;
  Json _sub(String name, String key) => (_bucket(name)[key] ??= <String, dynamic>{}) as Json;

  AuthUser? get _user => _store['user'] == null ? null : AuthUser(_store['user']['uid'], _store['user']['email']);
  Future<void> _setUser(AuthUser? u) async {
    _store['user'] = u == null ? null : {'uid': u.uid, 'email': u.email};
    await _save();
    _auth.add(u);
  }

  String _uidFor(String email) => 'demo-${email.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}';

  @override
  Stream<AuthUser?> authChanges() async* {
    yield _user;
    yield* _auth.stream;
  }

  @override
  Future<void> signInGoogle() => _setUser(AuthUser(_uidFor('google-demo'), 'demo@piano.quest'));
  @override
  Future<void> signInEmail(String e, String p) => _setUser(AuthUser(_uidFor(e), e));
  @override
  Future<void> signUpEmail(String e, String p) => _setUser(AuthUser(_uidFor(e), e));
  @override
  Future<void> resetPassword(String e) async {}
  @override
  Future<void> signOut() => _setUser(null);
  @override
  Future<void> deleteAccount(String uid) async {
    for (final cid in _sub('children', uid).keys.toList()) {
      await deleteChild(uid, cid);
    }
    _bucket('parents').remove(uid);
    _bucket('shares').removeWhere((_, v) => v['ownerUid'] == uid);
    await _setUser(null);
  }

  @override
  Future<ParentDoc?> getParent(String uid) async => _bucket('parents')[uid] == null ? null : ParentDoc.fromJson(_m(_bucket('parents')[uid]));
  @override
  Future<void> saveParent(ParentDoc p) async {
    _bucket('parents')[p.uid] = p.toJson();
    await _save();
  }

  @override
  Future<List<ChildProfile>> listChildren(String uid) async =>
      _sub('children', uid).values.map((v) => ChildProfile.fromJson(_m(v))).toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  @override
  Future<void> saveChild(String uid, ChildProfile c) async {
    _sub('children', uid)[c.id] = jsonDecode(jsonEncode(c.toJson()));
    await _save();
  }

  @override
  Future<void> deleteChild(String uid, String cid) async {
    _sub('children', uid).remove(cid);
    for (final k in ['sessions', 'recordings', 'compositions']) {
      _bucket(k).remove(cid);
    }
    await _save();
  }

  List<Json> _list(String name, String cid) => ((_bucket(name)[cid] ??= <dynamic>[]) as List).map(_m).toList();
  Future<void> _upsert(String name, String cid, Json item) async {
    final list = _list(name, cid)..removeWhere((x) => x['id'] == item['id']);
    _bucket(name)[cid] = [...list, item];
    await _save();
  }

  Future<void> _remove(String name, String cid, String id) async {
    _bucket(name)[cid] = _list(name, cid)..removeWhere((x) => x['id'] == id);
    await _save();
  }

  @override
  Future<void> addSession(String uid, String cid, SessionLog s) => _upsert('sessions', cid, s.toJson());
  @override
  Future<List<SessionLog>> listSessions(String uid, String cid, int since) async =>
      _list('sessions', cid).map(SessionLog.fromJson).where((s) => s.at >= since).toList()..sort((a, b) => b.at.compareTo(a.at));
  @override
  Future<void> saveRecording(String uid, Recording r) => _upsert('recordings', r.childId, r.toJson());
  @override
  Future<List<Recording>> listRecordings(String uid, String cid) async =>
      _list('recordings', cid).map(Recording.fromJson).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  @override
  Future<void> deleteRecording(String uid, String cid, String id) => _remove('recordings', cid, id);
  @override
  Future<void> saveComposition(String uid, Composition c) => _upsert('compositions', c.childId, c.toJson());
  @override
  Future<List<Composition>> listCompositions(String uid, String cid) async =>
      _list('compositions', cid).map(Composition.fromJson).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  @override
  Future<void> deleteComposition(String uid, String cid, String id) => _remove('compositions', cid, id);

  @override
  Future<String> createShare(ShareDoc s) async {
    final id = newId();
    _bucket('shares')[id] = {...s.toJson(), 'id': id};
    await _save();
    return id;
  }

  @override
  Future<ShareDoc?> getShare(String id) async {
    await _prefs.reload();
    _load();
    final v = _bucket('shares')[id];
    return v == null ? null : ShareDoc.fromJson(_m(v));
  }

  @override
  Future<void> heartShare(String id) async {
    final v = _bucket('shares')[id];
    if (v != null) {
      v['hearts'] = (v['hearts'] as num) + 1;
      await _save();
    }
  }

  @override
  Future<List<ShareDoc>> listShares(String uid) async =>
      _bucket('shares').values.map((v) => ShareDoc.fromJson(_m(v))).where((s) => s.ownerUid == uid).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  @override
  Future<void> deleteShare(String id) async {
    _bucket('shares').remove(id);
    await _save();
  }

  @override
  Future<void> registerInvite(String code, String uid) async {
    _bucket('invites')[code] ??= {'uid': uid, 'joins': <String>[]};
    await _save();
  }

  @override
  Future<bool> joinInvite(String code, String uid) async {
    final inv = _bucket('invites')[code];
    if (inv == null || inv['uid'] == uid || (inv['joins'] as List).contains(uid)) return false;
    inv['joins'] = [...(inv['joins'] as List), uid];
    await _save();
    return true;
  }

  @override
  Future<int> countInviteJoins(String code) async => ((_bucket('invites')[code]?['joins'] as List?) ?? []).length;
}

late Api api;
