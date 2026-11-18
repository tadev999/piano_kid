import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../audio/playback.dart';
import '../audio/synth.dart';
import '../data/api.dart';
import '../logic/missions.dart';
import '../logic/progress.dart';
import '../models.dart';

const refKey = 'pq-ref';

String _makeCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final r = math.Random.secure();
  return List.generate(6, (_) => chars[r.nextInt(chars.length)]).join();
}

class AppState extends ChangeNotifier {
  bool ready = false;
  AuthUser? user;
  ParentDoc? parent;
  List<ChildProfile> kids = [];
  String? _activeId;
  int _extraMin = 0;
  int inviteBonus = 0;
  late SharedPreferences _prefs;
  final _timers = <String, Timer>{};
  final _pending = <String, ChildProfile>{};
  StreamSubscription<AuthUser?>? _authSub;

  ChildProfile? get child => kids.where((k) => k.id == _activeId).firstOrNull;
  ParentSettings get settings => parent?.settings ?? ParentSettings();

  bool get timeUp {
    final c = child;
    return c != null && settings.dailyLimitMin > 0 && todaySeconds(c) >= (settings.dailyLimitMin + _extraMin) * 60;
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _authSub = api.authChanges().listen(_onAuth);
  }

  void rememberReferral(String code) => _prefs.setString(refKey, code.toUpperCase());

  Future<void> _onAuth(AuthUser? u) async {
    user = u;
    if (u == null) {
      parent = null;
      kids = [];
      _activeId = null;
      ready = true;
      notifyListeners();
      return;
    }
    try {
      var p = await api.getParent(u.uid);
      if (p == null) {
        p = ParentDoc(uid: u.uid, email: u.email, createdAt: DateTime.now().millisecondsSinceEpoch, inviteCode: _makeCode(), settings: ParentSettings());
        final ref = _prefs.getString(refKey);
        if (ref != null && ref != p.inviteCode && await api.joinInvite(ref, u.uid).catchError((_) => false)) p.referredBy = ref;
        await api.saveParent(p);
        await api.registerInvite(p.inviteCode, u.uid);
        await _prefs.remove(refKey);
      }
      parent = p;
      _applySettings();
      var list = (await api.listChildren(u.uid)).map(ensureDaily).toList();
      final joins = await api.countInviteJoins(p.inviteCode).catchError((_) => 0);
      var bonus = 0;
      list = list.map((c) {
        final (next, granted) = grantInviteRewards(c, joins);
        if (granted > 0) {
          bonus = math.max(bonus, granted);
          api.saveChild(u.uid, next);
        }
        return next;
      }).toList();
      inviteBonus = bonus;
      kids = list;
      final saved = _prefs.getString('pq-active-${u.uid}');
      _activeId = kids.any((k) => k.id == saved) ? saved : null;
    } catch (e) {
      debugPrint('load failed: $e');
    } finally {
      ready = true;
      notifyListeners();
    }
  }

  void _applySettings() {
    synth.sfxOn = settings.sfx;
    speech.enabled = settings.voice;
  }

  void _flush(String id) {
    final c = _pending.remove(id);
    final u = user;
    if (c == null || u == null) return;
    api.saveChild(u.uid, c).catchError((e) => debugPrint('save child failed: $e'));
  }

  void flushAll() => _pending.keys.toList().forEach(_flush);

  void updateKid(String id, ChildProfile Function(ChildProfile) fn) {
    final i = kids.indexWhere((k) => k.id == id);
    if (i < 0) return;
    final next = fn(kids[i]);
    if (identical(next, kids[i])) return;
    kids = [...kids]..[i] = next;
    _pending[id] = next;
    _timers[id]?.cancel();
    _timers[id] = Timer(const Duration(milliseconds: 600), () => _flush(id));
    notifyListeners();
  }

  void updateChild(ChildProfile Function(ChildProfile) fn) {
    final id = _activeId;
    if (id != null) updateKid(id, fn);
  }

  void selectChild(String? id) {
    final u = user;
    if (u != null) {
      id == null ? _prefs.remove('pq-active-${u.uid}') : _prefs.setString('pq-active-${u.uid}', id);
    }
    _activeId = id;
    _extraMin = 0;
    if (id != null) {
      final i = kids.indexWhere((k) => k.id == id);
      if (i >= 0) kids = [...kids]..[i] = ensureDaily(kids[i]);
    }
    notifyListeners();
  }

  Future<ChildProfile> createChild({required String nickname, required int birthYear}) async {
    final u = user!;
    var c = newChild(newId(), nickname, birthYear, const AvatarConfig('🐱', '#ffc9c9'), 'cat', 'Mèo Mi');
    if (parent?.referredBy != null) c.inventory.add('hat-dragon');
    c = ensureDaily(c);
    await api.saveChild(u.uid, c);
    kids = [...kids, c];
    notifyListeners();
    return c;
  }

  Future<void> removeChild(String id) async {
    final u = user;
    if (u == null) return;
    await api.deleteChild(u.uid, id);
    kids = kids.where((k) => k.id != id).toList();
    if (_activeId == id) selectChild(null);
    notifyListeners();
  }

  Future<void> updateSettings(void Function(ParentSettings s) fn) async {
    final p = parent;
    if (p == null) return;
    fn(p.settings);
    _applySettings();
    notifyListeners();
    await api.saveParent(p);
  }

  Outcome record(Activity act) {
    final cur = child, u = user;
    if (cur == null || u == null) return Outcome();
    final (next, outcome) = applyActivity(cur, act);
    updateKid(cur.id, (_) => next);
    api.addSession(u.uid, cur.id, SessionLog(
      id: newId(), type: act.kind, ref: act.ref, title: act.title, at: DateTime.now().millisecondsSinceEpoch,
      sec: act.sec.round(), stars: act.stars, noteAcc: act.noteAcc, rhythmAcc: act.rhythmAcc,
    )).catchError((_) {});
    return outcome;
  }

  void extendTime(int min) {
    _extraMin += min;
    notifyListeners();
  }

  void clearInviteBonus() {
    inviteBonus = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    flushAll();
    _authSub?.cancel();
    super.dispose();
  }
}
