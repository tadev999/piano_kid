// Data models, serialised with the same field names as the React web version so both apps share Firestore data.
typedef Json = Map<String, dynamic>;

enum Hand { r, l, b }

enum PlayMode { wait, timed }

enum InputKind { screen, midi, mic }

String handCode(Hand h) => h == Hand.r ? 'R' : h == Hand.l ? 'L' : 'B';

class Step {
  final double t;
  final double d;
  List<int> notes;
  List<int> lh;
  Map<int, int> fingers;
  Step({required this.t, required this.d, required this.notes, required this.lh, Map<int, int>? fingers}) : fingers = fingers ?? {};
  Step copyWith({double? t}) => Step(t: t ?? this.t, d: d, notes: [...notes], lh: [...lh], fingers: {...fingers});
}

class Arrangement {
  final int level;
  final String label;
  final int bpm;
  final int beatsPerBar;
  final Hand hands;
  final PlayMode defaultMode;
  final List<Step> steps;
  const Arrangement({required this.level, required this.label, required this.bpm, required this.beatsPerBar, required this.hands, required this.defaultMode, required this.steps});
}

class Song {
  final String id, title, subtitle, origin, credit, emoji;
  final int color;
  final int region;
  final List<Arrangement> levels;
  const Song({required this.id, required this.title, required this.subtitle, required this.origin, required this.credit, required this.emoji, required this.color, required this.region, required this.levels});
}

enum PicKey { posture, fingers, groups, cPosition, staff, bass, chord, sharp, dynamics, rhythm }

enum GameKind { catchNotes, ear, rhythm, detective }

class GameConfig {
  final List<int>? notes;
  final int? rounds;
  final List<double>? pattern;
  final int? bpm;
  final String? songId;
  final int? duration;
  final int? melodyLen;
  const GameConfig({this.notes, this.rounds, this.pattern, this.bpm, this.songId, this.duration, this.melodyLen});
}

sealed class LessonStep {
  final String text;
  const LessonStep(this.text);
}

class TalkStep extends LessonStep {
  final PicKey? pic;
  const TalkStep(super.text, [this.pic]);
}

class DemoStep extends LessonStep {
  final List<List<int>> notes;
  const DemoStep(super.text, this.notes);
}

class FindStep extends LessonStep {
  final List<int> target;
  final int count;
  final bool anyOctave;
  final bool chord;
  const FindStep(super.text, this.target, this.count, {this.anyOctave = false, this.chord = false});
}

class EchoStep extends LessonStep {
  final List<int> notes;
  final int rounds;
  const EchoStep(super.text, this.notes, {this.rounds = 2});
}

class GameStep extends LessonStep {
  final GameKind game;
  final GameConfig config;
  const GameStep(super.text, this.game, this.config);
}

class SongStep extends LessonStep {
  final String songId;
  final int level;
  final PlayMode? mode;
  const SongStep(super.text, this.songId, this.level, [this.mode]);
}

class DynStep extends LessonStep {
  final List<String> prompts;
  const DynStep(super.text, this.prompts);
}

class Lesson {
  final String id;
  final int region;
  final String title, emoji, skill;
  final bool boss;
  final List<LessonStep> steps;
  const Lesson({required this.id, required this.region, required this.title, required this.emoji, required this.skill, this.boss = false, required this.steps});
}

class Region {
  final int id;
  final String name, rank, emoji, desc, bossName, bossEmoji;
  final int color;
  final List<int> bg;
  const Region({required this.id, required this.name, required this.rank, required this.emoji, required this.color, required this.bg, required this.desc, required this.bossName, required this.bossEmoji});
}

class AvatarConfig {
  final String animal;
  final String color;
  const AvatarConfig(this.animal, this.color);
  Json toJson() => {'animal': animal, 'color': color};
  factory AvatarConfig.fromJson(Json? j) => AvatarConfig(j?['animal'] ?? '🐱', j?['color'] ?? '#ffd8a8');
}

double _d(dynamic v) => (v as num?)?.toDouble() ?? 0;
int _i(dynamic v) => (v as num?)?.toInt() ?? 0;
List<String> _sl(dynamic v) => (v as List?)?.map((e) => '$e').toList() ?? [];

class SongProgress {
  int stars;
  double bestNote, bestRhythm;
  int plays, last, highStreak;
  String? firstRec, bestRec;
  SongProgress({this.stars = 0, this.bestNote = 0, this.bestRhythm = 0, this.plays = 0, this.last = 0, this.highStreak = 0, this.firstRec, this.bestRec});
  Json toJson() => {'stars': stars, 'bestNote': bestNote, 'bestRhythm': bestRhythm, 'plays': plays, 'last': last, 'highStreak': highStreak, if (firstRec != null) 'firstRec': firstRec, if (bestRec != null) 'bestRec': bestRec};
  factory SongProgress.fromJson(Json j) => SongProgress(
      stars: _i(j['stars']), bestNote: _d(j['bestNote']), bestRhythm: _d(j['bestRhythm']), plays: _i(j['plays']), last: _i(j['last']),
      highStreak: _i(j['highStreak']), firstRec: j['firstRec'], bestRec: j['bestRec']);
}

class DayLog {
  int sec, songs, lessons, games, stars;
  DayLog({this.sec = 0, this.songs = 0, this.lessons = 0, this.games = 0, this.stars = 0});
  Json toJson() => {'sec': sec, 'songs': songs, 'lessons': lessons, 'games': games, 'stars': stars};
  factory DayLog.fromJson(Json j) => DayLog(sec: _i(j['sec']), songs: _i(j['songs']), lessons: _i(j['lessons']), games: _i(j['games']), stars: _i(j['stars']));
}

class Mission {
  final String id, kind, text;
  final int target, reward;
  double progress;
  bool claimed;
  final String? ref;
  Mission({required this.id, required this.kind, required this.text, required this.target, required this.reward, this.progress = 0, this.claimed = false, this.ref});
  bool get done => progress >= target;
  Json toJson() => {'id': id, 'kind': kind, 'text': text, 'target': target, 'reward': reward, 'progress': progress, 'claimed': claimed, if (ref != null) 'ref': ref};
  factory Mission.fromJson(Json j) => Mission(
      id: j['id'], kind: j['kind'], text: j['text'], target: _i(j['target']), reward: _i(j['reward']), progress: _d(j['progress']), claimed: j['claimed'] == true, ref: j['ref']);
}

class DailyState {
  final String date;
  final List<Mission> missions;
  bool chestClaimed;
  DailyState({required this.date, required this.missions, this.chestClaimed = false});
  Json toJson() => {'date': date, 'missions': missions.map((m) => m.toJson()).toList(), 'chestClaimed': chestClaimed};
  factory DailyState.fromJson(Json j) =>
      DailyState(date: j['date'], missions: (j['missions'] as List).map((m) => Mission.fromJson(Map<String, dynamic>.from(m))).toList(), chestClaimed: j['chestClaimed'] == true);
}

class Equipped {
  String? hat, skin, petAcc;
  List<String> room;
  Equipped({this.hat, this.skin, this.petAcc, List<String>? room}) : room = room ?? [];
  Json toJson() => {if (hat != null) 'hat': hat, if (skin != null) 'skin': skin, if (petAcc != null) 'petAcc': petAcc, 'room': room};
  factory Equipped.fromJson(Json? j) => Equipped(hat: j?['hat'], skin: j?['skin'] ?? 'skin-classic', petAcc: j?['petAcc'], room: _sl(j?['room']));
}

class ChildProfile {
  final String id;
  String nickname;
  int birthYear;
  AvatarConfig avatar;
  String pet, petName;
  InputKind input;
  bool onboarded;
  final int createdAt;
  int coins, totalStars, petXp;
  List<String> inventory, cards, badges, weekRewards, eventClaimed;
  Equipped equipped;
  Map<String, ({int stars, int at})> lessons;
  Map<String, SongProgress> songs;
  Map<String, int> weakNotes;
  Map<String, DayLog> log;
  DailyState? daily;
  int unlockedRegion;
  Map<String, int> eventProgress;
  int claimedInvites;

  ChildProfile({
    required this.id, required this.nickname, required this.birthYear, required this.avatar, required this.pet, required this.petName,
    this.input = InputKind.screen, this.onboarded = false, int? createdAt, this.coins = 50, this.totalStars = 0, this.petXp = 0,
    List<String>? inventory, Equipped? equipped, List<String>? cards, List<String>? badges, Map<String, ({int stars, int at})>? lessons,
    Map<String, SongProgress>? songs, Map<String, int>? weakNotes, Map<String, DayLog>? log, this.daily, List<String>? weekRewards,
    this.unlockedRegion = 1, Map<String, int>? eventProgress, List<String>? eventClaimed, this.claimedInvites = 0,
  })  : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch,
        inventory = inventory ?? ['skin-classic'],
        equipped = equipped ?? Equipped(skin: 'skin-classic'),
        cards = cards ?? [],
        badges = badges ?? [],
        lessons = lessons ?? {},
        songs = songs ?? {},
        weakNotes = weakNotes ?? {},
        log = log ?? {},
        weekRewards = weekRewards ?? [],
        eventProgress = eventProgress ?? {},
        eventClaimed = eventClaimed ?? [];

  Json toJson() => {
        'id': id, 'nickname': nickname, 'birthYear': birthYear, 'avatar': avatar.toJson(), 'pet': pet, 'petName': petName, 'input': input.name,
        'onboarded': onboarded, 'createdAt': createdAt, 'coins': coins, 'totalStars': totalStars, 'petXp': petXp, 'inventory': inventory,
        'equipped': equipped.toJson(), 'cards': cards, 'badges': badges,
        'lessons': lessons.map((k, v) => MapEntry(k, {'stars': v.stars, 'at': v.at})),
        'songs': songs.map((k, v) => MapEntry(k, v.toJson())), 'weakNotes': weakNotes, 'log': log.map((k, v) => MapEntry(k, v.toJson())),
        'daily': daily?.toJson(), 'weekRewards': weekRewards, 'unlockedRegion': unlockedRegion, 'eventProgress': eventProgress,
        'eventClaimed': eventClaimed, 'claimedInvites': claimedInvites,
      };

  factory ChildProfile.fromJson(Json j) {
    Map<String, dynamic> m(dynamic v) => v == null ? {} : Map<String, dynamic>.from(v as Map);
    return ChildProfile(
      id: j['id'], nickname: j['nickname'] ?? 'Bé', birthYear: _i(j['birthYear']), avatar: AvatarConfig.fromJson(m(j['avatar'])),
      pet: j['pet'] ?? 'cat', petName: j['petName'] ?? 'Mèo Mi',
      input: InputKind.values.firstWhere((e) => e.name == j['input'], orElse: () => InputKind.screen), onboarded: j['onboarded'] == true,
      createdAt: _i(j['createdAt']), coins: _i(j['coins']), totalStars: _i(j['totalStars']), petXp: _i(j['petXp']),
      inventory: _sl(j['inventory']), equipped: Equipped.fromJson(m(j['equipped'])), cards: _sl(j['cards']), badges: _sl(j['badges']),
      lessons: m(j['lessons']).map((k, v) => MapEntry(k, (stars: _i(v['stars']), at: _i(v['at'])))),
      songs: m(j['songs']).map((k, v) => MapEntry(k, SongProgress.fromJson(m(v)))),
      weakNotes: m(j['weakNotes']).map((k, v) => MapEntry(k, _i(v))),
      log: m(j['log']).map((k, v) => MapEntry(k, DayLog.fromJson(m(v)))),
      daily: j['daily'] == null ? null : DailyState.fromJson(m(j['daily'])), weekRewards: _sl(j['weekRewards']),
      unlockedRegion: _i(j['unlockedRegion']).clamp(1, 6), eventProgress: m(j['eventProgress']).map((k, v) => MapEntry(k, _i(v))),
      eventClaimed: _sl(j['eventClaimed']), claimedInvites: _i(j['claimedInvites']),
    );
  }

  ChildProfile clone() => ChildProfile.fromJson(toJson());
}

class ParentSettings {
  int dailyLimitMin, breakReminderMin;
  bool allowRecording, allowSharing, voice, sfx;
  ParentSettings({this.dailyLimitMin = 30, this.breakReminderMin = 20, this.allowRecording = true, this.allowSharing = true, this.voice = true, this.sfx = true});
  Json toJson() => {'dailyLimitMin': dailyLimitMin, 'breakReminderMin': breakReminderMin, 'allowRecording': allowRecording, 'allowSharing': allowSharing, 'voice': voice, 'sfx': sfx};
  factory ParentSettings.fromJson(Json? j) => ParentSettings(
      dailyLimitMin: j?['dailyLimitMin'] ?? 30, breakReminderMin: j?['breakReminderMin'] ?? 20, allowRecording: j?['allowRecording'] ?? true,
      allowSharing: j?['allowSharing'] ?? true, voice: j?['voice'] ?? true, sfx: j?['sfx'] ?? true);
}

class ParentDoc {
  final String uid, email, inviteCode;
  final int createdAt;
  String? referredBy;
  ParentSettings settings;
  ParentDoc({required this.uid, required this.email, required this.createdAt, required this.inviteCode, this.referredBy, required this.settings});
  Json toJson() => {'uid': uid, 'email': email, 'createdAt': createdAt, 'inviteCode': inviteCode, if (referredBy != null) 'referredBy': referredBy, 'settings': settings.toJson()};
  factory ParentDoc.fromJson(Json j) => ParentDoc(
      uid: j['uid'], email: j['email'] ?? '', createdAt: _i(j['createdAt']), inviteCode: j['inviteCode'] ?? '', referredBy: j['referredBy'],
      settings: ParentSettings.fromJson(j['settings'] == null ? null : Map<String, dynamic>.from(j['settings'])));
}

/// Performance event; `t` is milliseconds from start.
class PerfEvent {
  final int t, m;
  final double v;
  final bool on;
  const PerfEvent(this.t, this.m, this.v, this.on);
  Json toJson() => {'t': t, 'm': m, 'v': v, 'on': on};
  factory PerfEvent.fromJson(Json j) => PerfEvent(_i(j['t']), _i(j['m']), _d(j['v']), j['on'] == true);
}

List<PerfEvent> _events(dynamic v) => (v as List?)?.map((e) => PerfEvent.fromJson(Map<String, dynamic>.from(e))).toList() ?? [];

class Recording {
  final String id, childId, songId, title;
  final int level, createdAt, stars, durationMs;
  final double noteAcc, rhythmAcc;
  final List<PerfEvent> events;
  const Recording({required this.id, required this.childId, required this.songId, required this.level, required this.title, required this.events, required this.createdAt, required this.stars, required this.noteAcc, required this.rhythmAcc, required this.durationMs});
  Json toJson() => {'id': id, 'childId': childId, 'songId': songId, 'level': level, 'title': title, 'events': events.map((e) => e.toJson()).toList(), 'createdAt': createdAt, 'stars': stars, 'noteAcc': noteAcc, 'rhythmAcc': rhythmAcc, 'durationMs': durationMs};
  factory Recording.fromJson(Json j) => Recording(
      id: j['id'], childId: j['childId'], songId: j['songId'], level: _i(j['level']), title: j['title'] ?? '', events: _events(j['events']),
      createdAt: _i(j['createdAt']), stars: _i(j['stars']), noteAcc: _d(j['noteAcc']), rhythmAcc: _d(j['rhythmAcc']), durationMs: _i(j['durationMs']));
}

class Composition {
  final String id, childId, name;
  final List<PerfEvent> events;
  final int createdAt;
  const Composition({required this.id, required this.childId, required this.name, required this.events, required this.createdAt});
  Json toJson() => {'id': id, 'childId': childId, 'name': name, 'events': events.map((e) => e.toJson()).toList(), 'createdAt': createdAt};
  factory Composition.fromJson(Json j) => Composition(id: j['id'], childId: j['childId'], name: j['name'] ?? '', events: _events(j['events']), createdAt: _i(j['createdAt']));
}

class SessionLog {
  final String id, type, ref, title;
  final int at, sec, stars;
  final double? noteAcc, rhythmAcc;
  const SessionLog({required this.id, required this.type, required this.ref, required this.title, required this.at, required this.sec, required this.stars, this.noteAcc, this.rhythmAcc});
  Json toJson() => {'id': id, 'type': type, 'ref': ref, 'title': title, 'at': at, 'sec': sec, 'stars': stars, if (noteAcc != null) 'noteAcc': noteAcc, if (rhythmAcc != null) 'rhythmAcc': rhythmAcc};
  factory SessionLog.fromJson(Json j) => SessionLog(
      id: j['id'], type: j['type'], ref: j['ref'] ?? '', title: j['title'] ?? '', at: _i(j['at']), sec: _i(j['sec']), stars: _i(j['stars']),
      noteAcc: (j['noteAcc'] as num?)?.toDouble(), rhythmAcc: (j['rhythmAcc'] as num?)?.toDouble());
}

class ShareDoc {
  final String id, ownerUid, nickname, title, kind, inviteCode;
  final String? childId;
  final AvatarConfig avatar;
  final List<PerfEvent> events;
  int hearts;
  final int createdAt;
  ShareDoc({required this.id, required this.ownerUid, this.childId, required this.nickname, required this.avatar, required this.title, required this.kind, required this.events, required this.hearts, required this.createdAt, required this.inviteCode});
  Json toJson() => {'id': id, 'ownerUid': ownerUid, if (childId != null) 'childId': childId, 'nickname': nickname, 'avatar': avatar.toJson(), 'title': title, 'kind': kind, 'events': events.map((e) => e.toJson()).toList(), 'hearts': hearts, 'createdAt': createdAt, 'inviteCode': inviteCode};
  factory ShareDoc.fromJson(Json j) => ShareDoc(
      id: j['id'], ownerUid: j['ownerUid'], childId: j['childId'], nickname: j['nickname'] ?? '', avatar: AvatarConfig.fromJson(j['avatar'] == null ? null : Map<String, dynamic>.from(j['avatar'])),
      title: j['title'] ?? '', kind: j['kind'] ?? 'performance', events: _events(j['events']), hearts: _i(j['hearts']), createdAt: _i(j['createdAt']), inviteCode: j['inviteCode'] ?? '');
}
