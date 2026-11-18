import 'dart:math' as math;
import '../content/rewards.dart';
import '../models.dart';
import 'dates.dart';
import 'missions.dart';

final _rng = math.Random();

class Activity {
  final String kind; // lesson | song | game | free
  final String ref, title;
  final int stars;
  final double sec;
  final double? noteAcc, rhythmAcc;
  final bool boss, perfect, composed;
  final int? region;
  final GameKind? gameKind;
  final Map<String, int>? weak;
  const Activity({required this.kind, required this.ref, required this.title, required this.stars, required this.sec, this.noteAcc, this.rhythmAcc, this.boss = false, this.region, this.gameKind, this.perfect = false, this.composed = false, this.weak});
}

class Outcome {
  int coins = 0, starsGained = 0;
  final List<String> newBadges = [];
  String? card;
  int? petStageUp, regionUnlocked;
  final List<String> missionsCompleted = [];
  bool eventReady = false, bestImproved = false, firstTime = false;
  String? suggestion; // harder | slower
}

ChildProfile newChild(String id, String nickname, int birthYear, AvatarConfig avatar, String pet, String petName) =>
    ChildProfile(id: id, nickname: nickname, birthYear: birthYear, avatar: avatar, pet: pet, petName: petName);

void addBadge(ChildProfile child, String id, [List<String>? list]) {
  if (!child.badges.contains(id)) {
    child.badges.add(id);
    list?.add(id);
  }
}

String? dropCard(ChildProfile child, bool rare) {
  final pool = cards.where((c) => !child.cards.contains(c.id) && (rare ? c.rarity != 'common' : c.rarity == 'common')).toList();
  final from = pool.isNotEmpty ? pool : cards.where((c) => !child.cards.contains(c.id)).toList();
  if (from.isEmpty) return null;
  final c = from[_rng.nextInt(from.length)];
  child.cards.add(c.id);
  return c.id;
}

int practiceDayCount(ChildProfile c) => c.log.values.where((l) => l.sec >= 60).length;
int todaySeconds(ChildProfile c) => c.log[dayKey()]?.sec ?? 0;

(ChildProfile, Outcome) applyActivity(ChildProfile child0, Activity act) {
  final child = ensureDaily(child0.clone());
  final out = Outcome();
  final now = DateTime.now().millisecondsSinceEpoch;
  final log = child.log.putIfAbsent(dayKey(), () => DayLog());
  log.sec += act.sec.round();
  log.stars += act.stars;
  final stageBefore = petStage(child.petXp);
  act.weak?.forEach((k, v) => child.weakNotes[k] = (child.weakNotes[k] ?? 0) + v);

  switch (act.kind) {
    case 'lesson':
      log.lessons++;
      final prev = child.lessons[act.ref];
      out.firstTime = prev == null;
      out.bestImproved = act.stars > (prev?.stars ?? 0);
      out.starsGained = math.max(0, act.stars - (prev?.stars ?? 0));
      child.lessons[act.ref] = (stars: math.max(act.stars, prev?.stars ?? 0), at: now);
      out.coins = 10 + 5 * act.stars + (out.firstTime ? 15 : 0);
      addBadge(child, 'first-note', out.newBadges);
      if (out.firstTime) out.card = dropCard(child, act.boss);
      if (act.boss && act.stars >= 1 && act.region != null) {
        addBadge(child, 'region-${act.region}', out.newBadges);
        if (act.region! < 6 && child.unlockedRegion < act.region! + 1) {
          child.unlockedRegion = act.region! + 1;
          out.regionUnlocked = act.region! + 1;
        }
      }
    case 'song':
      log.songs++;
      final prev = child.songs[act.ref];
      out.firstTime = prev == null;
      final sp = prev ?? SongProgress();
      out.bestImproved = act.stars > sp.stars || (act.noteAcc ?? 0) > sp.bestNote + 0.02;
      out.starsGained = math.max(0, act.stars - sp.stars);
      sp.stars = math.max(sp.stars, act.stars);
      sp.bestNote = math.max(sp.bestNote, act.noteAcc ?? 0);
      sp.bestRhythm = math.max(sp.bestRhythm, act.rhythmAcc ?? 0);
      sp.plays++;
      sp.last = now;
      sp.highStreak = (act.noteAcc ?? 0) >= 0.9 ? sp.highStreak + 1 : 0;
      child.songs[act.ref] = sp;
      out.coins = 5 + 3 * act.stars + (out.bestImproved ? 10 : 0);
      if (sp.highStreak >= 2) {
        out.suggestion = 'harder';
      } else if ((act.noteAcc ?? 1) < 0.6) {
        out.suggestion = 'slower';
      }
      addBadge(child, 'first-song', out.newBadges);
      if (act.stars >= 3) addBadge(child, 'three-stars', out.newBadges);
      if (child.songs.length >= 10) addBadge(child, 'songs-10', out.newBadges);
    case 'game':
      log.games++;
      out.coins = 5 + 2 * act.stars;
      if (act.gameKind == GameKind.ear && act.perfect) addBadge(child, 'ear-master', out.newBadges);
      if (act.gameKind == GameKind.rhythm && (act.rhythmAcc ?? 0) >= 0.9) addBadge(child, 'rhythm-master', out.newBadges);
    default:
      out.coins = math.min(10, (act.sec / 60).ceil() * 2);
      if (act.composed) addBadge(child, 'composer', out.newBadges);
  }

  child.coins += out.coins;
  child.totalStars += out.starsGained;
  child.petXp += (act.sec / 10).round() + act.stars * 2;
  final stageAfter = petStage(child.petXp);
  if (stageAfter > stageBefore) out.petStageUp = stageAfter;
  if (stageAfter == petStageXp.length - 1) addBadge(child, 'pet-adult', out.newBadges);

  for (final m in child.daily?.missions ?? <Mission>[]) {
    if (m.done) continue;
    switch (m.kind) {
      case 'lesson' || 'song' || 'game' || 'free' when m.kind == act.kind:
        m.progress++;
      case 'stars':
        m.progress += act.stars;
      case 'minutes':
        m.progress = ((m.progress * 60 + act.sec) / 60 * 10).round() / 10;
      case 'review' when act.kind == 'song' && act.ref == m.ref:
        m.progress++;
    }
    if (m.done) out.missionsCompleted.add(m.text);
  }

  if ((act.kind == 'lesson' || act.kind == 'song') && act.stars >= 1) {
    final ev = activeEvent();
    child.eventProgress[ev.key] = (child.eventProgress[ev.key] ?? 0) + 1;
    out.eventReady = child.eventProgress[ev.key]! >= ev.event.goal && !child.eventClaimed.contains(ev.key);
  }

  final days = practiceDayCount(child);
  if (days >= 7) addBadge(child, 'days-7', out.newBadges);
  if (days >= 30) addBadge(child, 'days-30', out.newBadges);
  if (child.cards.length >= 10) addBadge(child, 'collector', out.newBadges);
  return (child, out);
}

(ChildProfile, int) claimMission(ChildProfile c0, String id) {
  final c = c0.clone();
  final m = c.daily?.missions.where((x) => x.id == id).firstOrNull;
  if (m == null || m.claimed || !m.done) return (c0, 0);
  m.claimed = true;
  c.coins += m.reward;
  return (c, m.reward);
}

bool chestReady(ChildProfile c) => c.daily != null && !c.daily!.chestClaimed && c.daily!.missions.every((m) => m.claimed);

(ChildProfile, int, String?) openChest(ChildProfile c0) {
  if (!chestReady(c0)) return (c0, 0, null);
  final c = c0.clone();
  c.daily!.chestClaimed = true;
  final coins = 30 + _rng.nextInt(4) * 10;
  c.coins += coins;
  c.petXp += 15;
  final card = _rng.nextDouble() < 0.6 ? dropCard(c, _rng.nextDouble() < 0.3) : null;
  return (c, coins, card);
}

({List<String> days, List<bool> done, int count, int goal, bool claimed, bool ready}) weekProgress(ChildProfile c) {
  final days = weekDays();
  final done = days.map((d) => (c.log[d]?.sec ?? 0) >= 60).toList();
  final count = done.where((x) => x).length;
  final claimed = c.weekRewards.contains(weekKey());
  return (days: days, done: done, count: count, goal: 4, claimed: claimed, ready: count >= 4 && !claimed);
}

(ChildProfile, int, String?) claimWeek(ChildProfile c0) {
  if (!weekProgress(c0).ready) return (c0, 0, null);
  final c = c0.clone();
  c.weekRewards.add(weekKey());
  c.coins += 100;
  addBadge(c, 'week-goal');
  return (c, 100, dropCard(c, true));
}

(ChildProfile, String?, int) claimEvent(ChildProfile c0) {
  final ev = activeEvent();
  if ((c0.eventProgress[ev.key] ?? 0) < ev.event.goal || c0.eventClaimed.contains(ev.key)) return (c0, null, 0);
  final c = c0.clone();
  c.eventClaimed.add(ev.key);
  addBadge(c, 'event');
  final item = ev.event.rewardItem;
  if (item.isNotEmpty && !c.inventory.contains(item)) {
    c.inventory.add(item);
    return (c, item, 0);
  }
  c.coins += 100;
  return (c, null, 100);
}

ChildProfile? buyItem(ChildProfile c0, String id) {
  final item = itemById(id);
  if (item == null || item.rewardOnly || c0.inventory.contains(id) || c0.coins < item.price) return null;
  final c = c0.clone();
  c.coins -= item.price;
  c.inventory.add(id);
  addBadge(c, 'decorator');
  return equipItem(c, id);
}

ChildProfile equipItem(ChildProfile c0, String id) {
  final item = itemById(id);
  if (item == null || !c0.inventory.contains(id)) return c0;
  final c = c0.clone();
  final eq = c.equipped;
  switch (item.kind) {
    case ItemKind.hat:
      eq.hat = eq.hat == id ? null : id;
    case ItemKind.skin:
      eq.skin = id;
    case ItemKind.petAcc:
      eq.petAcc = eq.petAcc == id ? null : id;
    case ItemKind.room:
      eq.room.contains(id) ? eq.room.remove(id) : eq.room.add(id);
  }
  return c;
}

(ChildProfile, int) grantInviteRewards(ChildProfile c0, int joins) {
  final granted = joins - c0.claimedInvites;
  if (granted <= 0) return (c0, 0);
  final c = c0.clone();
  c.claimedInvites = joins;
  c.coins += 100 * granted;
  if (!c.inventory.contains('hat-dragon')) c.inventory.add('hat-dragon');
  return (c, granted);
}
