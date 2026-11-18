import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

/// Builds Lottie (bodymovin) animations in code so the app ships without binary assets.
typedef J = Map<String, dynamic>;

const _fps = 60;
final _r = math.Random();
double _rnd(double a, double b) => a + _r.nextDouble() * (b - a);

J _stat(Object k) => {'a': 0, 'k': k};
J _anim(List<(num, Object)> frames) => {
      'a': 1,
      'k': [
        for (var i = 0; i < frames.length; i++)
          {
            't': frames[i].$1,
            's': frames[i].$2 is List ? frames[i].$2 : [frames[i].$2],
            if (i < frames.length - 1) ...{'i': {'x': [0.25], 'y': [1]}, 'o': {'x': [0.4], 'y': [0]}},
          },
      ],
    };

List<double> _hex(int c) => [((c >> 16) & 255) / 255, ((c >> 8) & 255) / 255, (c & 255) / 255, 1];

J _group(J shape, int color) => {
      'ty': 'gr',
      'it': [
        shape,
        {'ty': 'fl', 'c': _stat(_hex(color)), 'o': _stat(100), 'r': 1},
        {'ty': 'tr', 'p': _stat([0, 0]), 'a': _stat([0, 0]), 's': _stat([100, 100]), 'r': _stat(0), 'o': _stat(100)},
      ],
    };

J _star(double outer) => {'ty': 'sr', 'sy': 1, 'd': 1, 'pt': _stat(5), 'p': _stat([0, 0]), 'r': _stat(0), 'ir': _stat(outer * 0.45), 'is': _stat(0), 'or': _stat(outer), 'os': _stat(0)};
J _circle(double s) => {'ty': 'el', 'd': 1, 'p': _stat([0, 0]), 's': _stat([s, s])};
J _rect(double w, double h) => {'ty': 'rc', 'd': 1, 'p': _stat([0, 0]), 's': _stat([w, h]), 'r': _stat(2)};
J _heart(double size) {
  final s = size / 2;
  return {
    'ty': 'sh',
    'd': 1,
    'ks': _stat({
      'c': true,
      'v': [[0, s * 0.9], [-s, -s * 0.1], [-s * 0.5, -s * 0.8], [0, -s * 0.35], [s * 0.5, -s * 0.8], [s, -s * 0.1]],
      'i': [[s * 0.2, -s * 0.3], [0, s * 0.4], [-s * 0.3, 0], [0, -s * 0.2], [-s * 0.15, 0], [0, -s * 0.4]],
      'o': [[-s * 0.2, -s * 0.3], [0, -s * 0.4], [s * 0.15, 0], [0, -s * 0.2], [s * 0.3, 0], [0, s * 0.4]],
    }),
  };
}

J _layer(int ind, {required J shape, required int color, required List<(num, List<num>)> pos, List<(num, num)>? scale, List<(num, num)>? rot, List<(num, num)>? opacity, num start = 0, required num end}) => {
      'ddd': 0, 'ind': ind, 'ty': 4, 'nm': 'l$ind', 'sr': 1, 'ao': 0, 'ip': start, 'op': end, 'st': 0, 'bm': 0,
      'ks': {
        'o': opacity != null ? _anim(opacity.map((e) => (e.$1, e.$2 as Object)).toList()) : _stat(100),
        'r': rot != null ? _anim(rot.map((e) => (e.$1, e.$2 as Object)).toList()) : _stat(0),
        'p': _anim(pos.map((e) => (e.$1, <num>[...e.$2, 0] as Object)).toList()),
        'a': _stat([0, 0, 0]),
        's': scale != null ? _anim(scale.map((e) => (e.$1, <num>[e.$2, e.$2, 100] as Object)).toList()) : _stat([100, 100, 100]),
      },
      'shapes': [_group(shape, color)],
    };

Uint8List _comp(num w, num h, num frames, List<J> layers) =>
    Uint8List.fromList(utf8.encode(jsonEncode({'v': '5.7.4', 'fr': _fps, 'ip': 0, 'op': frames, 'w': w, 'h': h, 'nm': 'fx', 'ddd': 0, 'assets': [], 'layers': layers})));

const _palette = [0xffff6b6b, 0xffffd43b, 0xff51cf66, 0xff4dabf7, 0xff9775fa, 0xfff783ac, 0xffffa94d];

Uint8List confettiJson([int count = 46]) {
  const w = 800, h = 600, f = 150;
  return _comp(w, h, f, [
    for (var i = 0; i < count; i++)
      () {
        final x = _rnd(40, w - 40);
        final delay = _rnd(0, 30).floor();
        final shape = i % 3 == 0 ? _circle(_rnd(10, 16)) : i % 3 == 1 ? _rect(_rnd(8, 12), _rnd(16, 24)) : _star(_rnd(8, 12));
        return _layer(i + 1, shape: shape, color: _palette[i % _palette.length], end: f, pos: [(delay, [x, -30]), (f, [x + _rnd(-120, 120), h + 40])], rot: [(delay, 0), (f, _rnd(-720, 720))]);
      }(),
  ]);
}

Uint8List starBurstJson() {
  const s = 400, c = s / 2, f = 90;
  return _comp(s, s, f, [
    for (var i = 0; i < 12; i++)
      () {
        final a = i / 12 * math.pi * 2, r = _rnd(130, 180);
        return _layer(i + 1, shape: _star(_rnd(10, 18)), color: _palette[i % _palette.length], end: f,
            pos: [(0, [c, c]), (45, [c + math.cos(a) * r, c + math.sin(a) * r])], scale: [(0, 30), (20, 120), (f, 0)], opacity: [(0, 100), (60, 100), (f, 0)], rot: [(0, 0), (f, 180)]);
      }(),
    _layer(20, shape: _star(80), color: 0xffffd43b, end: f, pos: [(0, [c, c]), (f, [c, c])], scale: [(0, 0), (18, 130), (30, 100), (f, 100)], rot: [(0, -40), (30, 0), (f, 0)]),
  ]);
}

Uint8List heartsJson() {
  const w = 300, h = 300, f = 120;
  return _comp(w, h, f, [
    for (var i = 0; i < 6; i++)
      () {
        final x = 60.0 + i * 36, d = i * 12;
        return _layer(i + 1, shape: _heart(_rnd(22, 34)), color: i.isOdd ? 0xffff6b6b : 0xfff783ac, end: f, start: d,
            pos: [(d, [x, h - 20]), (d + 80, [x + _rnd(-30, 30), 30])], opacity: [(d, 0), (d + 10, 100), (d + 70, 100), (d + 80, 0)], scale: [(d, 40), (d + 20, 100), (d + 80, 120)]);
      }(),
  ]);
}

Uint8List sparklesJson() {
  const w = 300, h = 300, f = 120;
  return _comp(w, h, f, [
    for (var i = 0; i < 8; i++)
      () {
        final x = _rnd(30, w - 30), y = _rnd(30, h - 30), d = 1 + (i * 15) % (f - 45);
        return _layer(i + 1, shape: _star(_rnd(8, 14)), color: i.isOdd ? 0xffffd43b : 0xffffffff, end: f, pos: [(0, [x, y]), (f, [x, y])], scale: [(0, 0), (d, 0), (d + 20, 110), (d + 40, 0), (f, 0)], rot: [(0, 0), (f, 90)]);
      }(),
  ]);
}

Uint8List coinJson() {
  const s = 200, c = s / 2, f = 60;
  final pos = <(num, List<num>)>[(0, [c, c + 40]), (25, [c, c - 20]), (f, [c, c - 40])];
  final scale = <(num, num)>[(0, 0), (15, 120), (25, 100), (f, 80)];
  final op = <(num, num)>[(0, 100), (45, 100), (f, 0)];
  return _comp(s, s, f, [
    _layer(1, shape: _circle(70), color: 0xfffcc419, end: f, pos: pos, scale: scale, opacity: op),
    _layer(2, shape: _star(22), color: 0xfffff3bf, end: f, pos: pos, scale: scale, opacity: op),
  ]);
}
