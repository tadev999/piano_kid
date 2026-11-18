import '../models.dart';
import '../music/notes.dart';

const regions = <Region>[
  Region(id: 1, name: 'Làng Phím Trắng', rank: 'Tân binh', emoji: '🏡', color: 0xffff922b, bg: [0xfffff4e6, 0xffffd8a8], desc: 'Làm quen cây đàn, Đô – Rê – Mi – Fa – Sol', bossName: 'Rồng Ngủ Gật', bossEmoji: '🐲'),
  Region(id: 2, name: 'Rừng Nhịp Điệu', rank: 'Tập sự', emoji: '🌳', color: 0xff40c057, bg: [0xffebfbee, 0xffb2f2bb], desc: 'Nốt đen, nốt trắng, chơi đúng nhịp', bossName: 'Khỉ Đánh Trống', bossEmoji: '🐒'),
  Region(id: 3, name: 'Biển Tay Trái', rank: 'Khám phá', emoji: '🌊', color: 0xff228be6, bg: [0xffe7f5ff, 0xffa5d8ff], desc: 'Tay trái, khóa Fa, hai tay thay phiên', bossName: 'Bạch Tuộc Tám Tay', bossEmoji: '🐙'),
  Region(id: 4, name: 'Núi Hai Tay', rank: 'Phối hợp', emoji: '⛰️', color: 0xff7950f2, bg: [0xfff3f0ff, 0xffd0bfff], desc: 'Hai tay cùng lúc, hợp âm Đô – Fa – Sol', bossName: 'Người Tuyết Khổng Lồ', bossEmoji: '☃️'),
  Region(id: 5, name: 'Lâu Đài Sắc Thái', rank: 'Nghệ sĩ', emoji: '🏰', color: 0xffe64980, bg: [0xfffff0f6, 0xfffcc2d7], desc: 'Phím đen, mạnh – nhẹ, nhạc cổ điển', bossName: 'Bà Chúa Tuyết', bossEmoji: '👸'),
  Region(id: 6, name: 'Nhạc Viện Bầu Trời', rank: 'Bậc thầy', emoji: '🌈', color: 0xfffab005, bg: [0xfffff9db, 0xffffe066], desc: 'Gam, hợp âm rải, tác phẩm biểu diễn', bossName: 'Đêm Nhạc Hội', bossEmoji: '🌟'),
];

final _c4g4 = n('C4 D4 E4 F4 G4');
final _c4c5 = n('C4 D4 E4 F4 G4 A4 B4 C5');

final List<Lesson> lessons = [
  // ---------- Region 1 ----------
  Lesson(id: 'r1-1', region: 1, title: 'Chào cây đàn', emoji: '🎹', skill: 'Tư thế & số ngón tay', steps: [
    const TalkStep('Chào bạn! Mình là Đô Rê. Hôm nay mình cùng làm quen cây đàn nhé! Ngồi thẳng lưng, hai chân đặt trên sàn, vai thả lỏng.', PicKey.posture),
    const TalkStep('Mỗi ngón tay có một con số. Ngón cái là số 1, ngón trỏ số 2, ngón giữa số 3, ngón áp út số 4, ngón út số 5.', PicKey.fingers),
    DemoStep('Nghe nhé: phía bên trái là tiếng trầm, phía bên phải là tiếng cao!', [n('C3'), n('G3'), n('C4'), n('G4'), n('C5')]),
    const FindStep('Bạn bấm phím nào cũng được, 6 lần nhé!', [], 6),
    const TalkStep('Giỏi quá! Bạn vừa chơi những nốt nhạc đầu tiên trong đời đấy!'),
  ]),
  Lesson(id: 'r1-2', region: 1, title: 'Nhà của Đô', emoji: '🏠', skill: 'Nhóm phím đen & nốt Đô', steps: [
    const TalkStep('Nhìn kỹ nhé: phím đen đứng thành nhóm 2 phím và nhóm 3 phím. Nốt Đô luôn ở ngay bên trái nhóm 2 phím đen.', PicKey.groups),
    DemoStep('Đây là các nốt Đô trên cây đàn.', [n('C3'), n('C4'), n('C5')]),
    FindStep('Tìm nốt Đô! Bấm 4 lần nhé, Đô nào cũng được.', n('C4'), 4, anyOctave: true),
    GameStep('Trò chơi Bắt nốt rơi! Bấm Đô khi bong bóng rơi xuống.', GameKind.catchNotes, GameConfig(notes: n('C4'), duration: 30)),
  ]),
  Lesson(id: 'r1-3', region: 1, title: 'Đô – Rê', emoji: '🐤', skill: 'Nốt Rê', steps: [
    const TalkStep('Nốt Rê nằm giữa hai phím đen, ngay cạnh Đô. Dùng ngón số 2 để chơi Rê nhé.'),
    FindStep('Bấm nốt Rê 3 lần.', n('D4'), 3, anyOctave: true),
    EchoStep('Nghe Đô Rê chơi trước, rồi bạn chơi lại giống hệt nhé!', n('C4 D4'), rounds: 3),
    GameStep('Bắt nốt rơi: Đô và Rê!', GameKind.catchNotes, GameConfig(notes: n('C4 D4'), duration: 40)),
  ]),
  Lesson(id: 'r1-4', region: 1, title: 'Mi vui vẻ', emoji: '😄', skill: 'Nốt Mi', steps: [
    const TalkStep('Mi nằm bên phải Rê, ngay sau nhóm 2 phím đen. Đô – Rê – Mi là ba anh em!'),
    FindStep('Bấm nốt Mi 3 lần.', n('E4'), 3, anyOctave: true),
    EchoStep('Chơi lại giai điệu nhé!', n('C4 D4 E4'), rounds: 3),
    const SongStep('Bài hát đầu tiên: Bánh Nóng! Chỉ cần Mi – Rê – Đô thôi.', 'hot-cross-buns', 1),
  ]),
  Lesson(id: 'r1-5', region: 1, title: 'Đôi tai thám tử', emoji: '👂', skill: 'Nghe Đô – Rê – Mi', steps: [
    const TalkStep('Thám tử âm nhạc phải có đôi tai thật tinh. Nghe nốt rồi tìm đúng phím nhé!'),
    GameStep('Đoán tiếng: nghe và chơi lại nốt đó.', GameKind.ear, GameConfig(notes: n('C4 D4 E4'), rounds: 6)),
    const SongStep('Bài hát Ánh Trăng – chỉ dùng Đô, Rê, Mi.', 'au-clair', 1),
  ]),
  Lesson(id: 'r1-6', region: 1, title: 'Fa và Sol', emoji: '🐸', skill: 'Nốt Fa, Sol', steps: [
    const TalkStep('Fa nằm ngay bên trái nhóm 3 phím đen. Sol là hàng xóm bên phải của Fa.', PicKey.groups),
    FindStep('Bấm nốt Fa 3 lần.', n('F4'), 3, anyOctave: true),
    FindStep('Bấm nốt Sol 3 lần.', n('G4'), 3, anyOctave: true),
    EchoStep('Đi lên cầu thang âm nhạc nào!', _c4g4),
    GameStep('Bắt nốt rơi: năm nốt!', GameKind.catchNotes, GameConfig(notes: _c4g4, duration: 45)),
  ]),
  Lesson(id: 'r1-7', region: 1, title: 'Vị trí Đô năm ngón', emoji: '🖐️', skill: 'Vị trí Đô', steps: [
    const TalkStep('Đặt 5 ngón tay phải lên Đô – Rê – Mi – Fa – Sol: ngón 1 ở Đô, ngón 5 ở Sol. Đây là vị trí Đô!', PicKey.cPosition),
    DemoStep('Nghe Đô Rê chơi lên rồi xuống nhé.', n('C4 D4 E4 F4 G4 F4 E4 D4 C4').map((m) => [m]).toList()),
    const SongStep('Chơi bài Chú Cừu Nhỏ nào!', 'mary', 1),
  ]),
  const Lesson(id: 'r1-boss', region: 1, title: 'Trùm: Rồng Ngủ Gật', emoji: '🐲', skill: 'Biểu diễn đầu tiên', boss: true, steps: [
    TalkStep('Con Rồng Ngủ Gật đang ngủ say. Hãy chơi Ngôi Sao Lấp Lánh thật hay để đánh thức nó!'),
    SongStep('Đánh thức Rồng Ngủ Gật!', 'twinkle', 1),
  ]),

  // ---------- Region 2 ----------
  const Lesson(id: 'r2-1', region: 2, title: 'Nốt đen: Ta', emoji: '🥁', skill: 'Nốt đen', steps: [
    TalkStep('Nốt đen dài 1 phách. Mình đếm: Ta – Ta – Ta – Ta. Mỗi tiếng Ta là một lần bấm.', PicKey.rhythm),
    GameStep('Nhảy theo nhịp! Bấm phím bất kỳ khi chướng ngại tới vạch.', GameKind.rhythm, GameConfig(pattern: [1, 1, 1, 1, 1, 1, 1, 1], bpm: 76)),
  ]),
  const Lesson(id: 'r2-2', region: 2, title: 'Nốt trắng: Ta-a', emoji: '🦢', skill: 'Nốt trắng', steps: [
    TalkStep('Nốt trắng dài 2 phách: Ta-a. Bấm một lần rồi giữ trong khi đếm hai.', PicKey.rhythm),
    GameStep('Nhảy theo nhịp với nốt đen và nốt trắng!', GameKind.rhythm, GameConfig(pattern: [1, 1, 2, 1, 1, 2, 2, 2], bpm: 76)),
  ]),
  const Lesson(id: 'r2-3', region: 2, title: 'Giữ nhịp đều', emoji: '⏱️', skill: 'Chơi theo nhịp', steps: [
    TalkStep('Bây giờ nốt nhạc sẽ tự rơi xuống. Khi nốt chạm vạch sáng thì bấm nhé!'),
    SongStep('Chú Cừu Nhỏ – chơi theo nhịp!', 'mary', 2, PlayMode.timed),
  ]),
  Lesson(id: 'r2-4', region: 2, title: 'La và Si', emoji: '🦜', skill: 'Nốt La, Si', steps: [
    const TalkStep('Sau Sol là La và Si. Rồi lại đến Đô cao! Bảy nốt nhạc: Đô Rê Mi Fa Sol La Si.'),
    FindStep('Bấm nốt La 3 lần.', n('A4'), 3, anyOctave: true),
    FindStep('Bấm nốt Si 3 lần.', n('B4'), 3, anyOctave: true),
    GameStep('Bắt nốt rơi: cả bảy nốt!', GameKind.catchNotes, GameConfig(notes: _c4c5, duration: 50)),
  ]),
  Lesson(id: 'r2-5', region: 2, title: 'Đô cao', emoji: '🎈', skill: 'Quãng tám', steps: [
    const TalkStep('Đô cao giống Đô thấp nhưng nghe cao hơn. Khoảng cách giữa hai nốt Đô gọi là quãng tám.'),
    DemoStep('Đô thấp – Đô cao.', [n('C4'), n('C5'), n('C4'), n('C5')]),
    EchoStep('Chơi lại nhé!', n('G4 A4 B4 C5')),
    GameStep('Đoán tiếng với nốt cao và thấp.', GameKind.ear, GameConfig(notes: n('C4 E4 G4 C5'), rounds: 6)),
  ]),
  const Lesson(id: 'r2-6', region: 2, title: 'Kìa con bướm vàng', emoji: '🦋', skill: 'Giai điệu dài', steps: [SongStep('Kìa con bướm vàng, kìa con bướm vàng...', 'frere', 2)]),
  const Lesson(id: 'r2-7', region: 2, title: 'Cầu London', emoji: '🌉', skill: 'Nốt chấm dôi', steps: [TalkStep('Nốt có dấu chấm dài hơn một chút. Nghe kỹ rồi chơi nhé!'), SongStep('Cầu London!', 'london', 2)]),
  const Lesson(id: 'r2-8', region: 2, title: 'Thám tử bản nhạc', emoji: '🕵️', skill: 'Nghe nốt sai', steps: [
    TalkStep('Ôi không! Có một nốt bị chơi sai trong bài hát. Thám tử hãy tìm ra nốt đó!'),
    GameStep('Tìm nốt sai!', GameKind.detective, GameConfig(songId: 'twinkle', melodyLen: 6, rounds: 4)),
  ]),
  const Lesson(id: 'r2-9', region: 2, title: 'Bản nhạc Niềm Vui', emoji: '🎻', skill: 'Nhạc cổ điển đầu tiên', steps: [TalkStep('Bài này do nhạc sĩ Beethoven viết gần 200 năm trước!'), SongStep('Niềm Vui – Ode to Joy', 'ode', 2)]),
  const Lesson(id: 'r2-boss', region: 2, title: 'Trùm: Khỉ Đánh Trống', emoji: '🐒', skill: 'Chơi đúng nhịp', boss: true, steps: [
    TalkStep('Khỉ Đánh Trống thách bạn chơi đúng nhịp với trống của nó!'),
    SongStep('Song đấu nhịp điệu!', 'twinkle', 2, PlayMode.timed),
  ]),

  // ---------- Region 3 ----------
  Lesson(id: 'r3-1', region: 3, title: 'Xin chào tay trái', emoji: '🤚', skill: 'Tay trái', steps: [
    const TalkStep('Tay trái cũng có số ngón: ngón cái là 1, ngón út là 5. Đặt ngón 5 tay trái lên Đô trầm nhé.', PicKey.fingers),
    FindStep('Dùng tay trái bấm Đô trầm 3 lần.', n('C3'), 3),
    const SongStep('Tay trái đi dạo!', 'lh-walk', 1),
  ]),
  Lesson(id: 'r3-2', region: 3, title: 'Khóa Fa', emoji: '🗝️', skill: 'Đọc khóa Fa', steps: [
    const TalkStep('Nốt của tay trái thường viết trên khuông nhạc có khóa Fa. Mình cùng luyện các nốt trầm nhé!', PicKey.bass),
    GameStep('Bắt nốt rơi ở vùng trầm!', GameKind.catchNotes, GameConfig(notes: n('C3 D3 E3 F3 G3'), duration: 45)),
  ]),
  const Lesson(id: 'r3-3', region: 3, title: 'Tay trái mạnh mẽ', emoji: '💪', skill: 'Tay trái linh hoạt', steps: [SongStep('Thử chơi theo nhịp nhé!', 'lh-walk', 1, PlayMode.timed)]),
  const Lesson(id: 'r3-4', region: 3, title: 'Hỏi – Đáp', emoji: '💬', skill: 'Hai tay thay phiên', steps: [TalkStep('Tay phải hỏi, tay trái đáp. Hai tay thay phiên nhau nhé!'), SongStep('Hỏi – Đáp', 'hoi-dap', 1)]),
  const Lesson(id: 'r3-5', region: 3, title: 'Bánh Nóng hai tay', emoji: '🥐', skill: 'Ghép hai tay', steps: [SongStep('Bánh Nóng với tay trái đệm!', 'hot-cross-buns', 3)]),
  const Lesson(id: 'r3-6', region: 3, title: 'Bướm vàng hai tay', emoji: '🦋', skill: 'Ghép hai tay', steps: [SongStep('Kìa con bướm vàng – hai tay!', 'frere', 3)]),
  Lesson(id: 'r3-7', region: 3, title: 'Tai siêu thính', emoji: '🦻', skill: 'Nghe nốt trầm – cao', steps: [
    GameStep('Đoán tiếng từ trầm đến cao!', GameKind.ear, GameConfig(notes: n('C3 E3 G3 C4 E4 G4'), rounds: 8)),
  ]),
  const Lesson(id: 'r3-boss', region: 3, title: 'Trùm: Bạch Tuộc Tám Tay', emoji: '🐙', skill: 'Hai tay vững vàng', boss: true, steps: [
    TalkStep('Bạch Tuộc có tám tay! Bạn chỉ có hai tay nhưng chơi hay hơn nhiều!'),
    SongStep('Niềm Vui – hai tay!', 'ode', 3),
  ]),

  // ---------- Region 4 ----------
  Lesson(id: 'r4-1', region: 4, title: 'Hợp âm Đô', emoji: '🎶', skill: 'Hợp âm Đô trưởng', steps: [
    const TalkStep('Hợp âm là nhiều nốt vang cùng lúc. Đô – Mi – Sol cùng nhau tạo thành hợp âm Đô trưởng!', PicKey.chord),
    DemoStep('Nghe hợp âm Đô.', [n('C3 E3 G3'), n('C3 E3 G3')]),
    FindStep('Bấm cùng lúc Đô – Mi – Sol, 3 lần nhé.', n('C3 E3 G3'), 3, chord: true),
  ]),
  Lesson(id: 'r4-2', region: 4, title: 'Hợp âm Fa và Sol', emoji: '🎼', skill: 'Hợp âm Fa, Sol', steps: [
    DemoStep('Hợp âm Fa: Fa – La – Đô. Hợp âm Sol: Sol – Si – Rê.', [n('F3 A3 C4'), n('G3 B3 D4')]),
    FindStep('Bấm hợp âm Fa 2 lần.', n('F3 A3 C4'), 2, chord: true),
    FindStep('Bấm hợp âm Sol 2 lần.', n('G3 B3 D4'), 2, chord: true),
  ]),
  const Lesson(id: 'r4-3', region: 4, title: 'Chú Cừu hai tay', emoji: '🐑', skill: 'Ghép hai tay', steps: [SongStep('Chú Cừu Nhỏ – hai tay', 'mary', 3)]),
  const Lesson(id: 'r4-4', region: 4, title: 'Ngôi Sao hai tay', emoji: '⭐', skill: 'Ghép hai tay', steps: [SongStep('Ngôi Sao Lấp Lánh – hai tay', 'twinkle', 3)]),
  const Lesson(id: 'r4-5', region: 4, title: 'Chúc mừng sinh nhật', emoji: '🎂', skill: 'Nhịp 3/4', steps: [TalkStep('Bài này có 3 phách mỗi ô nhịp: Một – hai – ba.'), SongStep('Chúc Mừng Sinh Nhật', 'birthday', 2)]),
  const Lesson(id: 'r4-6', region: 4, title: 'Sinh nhật hai tay', emoji: '🎁', skill: 'Nhịp 3/4 hai tay', steps: [SongStep('Chơi tặng người thân nhé!', 'birthday', 3)]),
  const Lesson(id: 'r4-7', region: 4, title: 'Chuông ngân vang', emoji: '🔔', skill: 'Nốt móc đơn', steps: [SongStep('Jingle Bells!', 'jingle', 2)]),
  const Lesson(id: 'r4-8', region: 4, title: 'Hợp âm rải', emoji: '🌊', skill: 'Hợp âm rải', steps: [TalkStep('Hợp âm rải là chơi từng nốt của hợp âm nối tiếp nhau, như sóng biển.'), SongStep('Hợp âm rải', 'arpeggio', 1)]),
  const Lesson(id: 'r4-boss', region: 4, title: 'Trùm: Người Tuyết Khổng Lồ', emoji: '☃️', skill: 'Hai tay nhanh nhẹn', boss: true, steps: [
    TalkStep('Người Tuyết chỉ tan chảy khi nghe Jingle Bells hai tay!'),
    SongStep('Chuông Ngân Vang – hai tay!', 'jingle', 3),
  ]),

  // ---------- Region 5 ----------
  Lesson(id: 'r5-1', region: 5, title: 'Phím đen: Fa thăng', emoji: '♯', skill: 'Dấu thăng', steps: [
    const TalkStep('Dấu thăng (♯) nghĩa là chơi phím đen ngay bên phải. Fa thăng là phím đen bên phải nốt Fa.', PicKey.sharp),
    FindStep('Bấm Fa thăng 3 lần.', n('F#4'), 3, anyOctave: true),
    GameStep('Bắt nốt rơi có phím đen!', GameKind.catchNotes, GameConfig(notes: n('D4 E4 F#4 G4 A4'), duration: 45)),
  ]),
  const Lesson(id: 'r5-2', region: 5, title: 'Gam Sol trưởng', emoji: '🧗', skill: 'Gam Sol trưởng', steps: [SongStep('Gam Sol trưởng có một nốt Fa thăng.', 'scale-g', 1)]),
  const Lesson(id: 'r5-3', region: 5, title: 'Mạnh và nhẹ', emoji: '🔊', skill: 'Sắc thái', steps: [
    TalkStep('Chữ f (forte) nghĩa là chơi mạnh. Chữ p (piano) nghĩa là chơi nhẹ. Trên màn hình, bấm gần mép dưới phím là mạnh, gần mép trên là nhẹ.', PicKey.dynamics),
    DynStep('Làm theo: mạnh hay nhẹ?', ['f', 'p', 'f', 'p', 'p', 'f']),
  ]),
  const Lesson(id: 'r5-4', region: 5, title: 'Minuet nhẹ nhàng', emoji: '💃', skill: 'Nốt móc đơn', steps: [SongStep('Minuet – điệu nhảy cung đình', 'minuet', 1)]),
  const Lesson(id: 'r5-5', region: 5, title: 'Minuet hai tay', emoji: '🩰', skill: 'Nhạc cổ điển hai tay', steps: [SongStep('Minuet – hai tay', 'minuet', 3)]),
  const Lesson(id: 'r5-6', region: 5, title: 'Gửi Elise', emoji: '🌹', skill: 'Tác phẩm nổi tiếng', steps: [TalkStep('Gửi Elise là một trong những bản nhạc piano nổi tiếng nhất thế giới!'), SongStep('Đoạn mở đầu Gửi Elise', 'fur-elise', 1)]),
  const Lesson(id: 'r5-7', region: 5, title: 'Elise tay phải', emoji: '🎀', skill: 'Phím đen nhanh', steps: [SongStep('Gửi Elise – tay phải', 'fur-elise', 2)]),
  const Lesson(id: 'r5-boss', region: 5, title: 'Trùm: Bà Chúa Tuyết', emoji: '👸', skill: 'Biểu diễn cổ điển', boss: true, steps: [
    TalkStep('Bà Chúa Tuyết chỉ mở cổng lâu đài khi nghe Gửi Elise hai tay!'),
    SongStep('Gửi Elise – hai tay', 'fur-elise', 3),
  ]),

  // ---------- Region 6 ----------
  const Lesson(id: 'r6-1', region: 6, title: 'Gam Đô trưởng', emoji: '🪜', skill: 'Gam & chuyển ngón', steps: [
    TalkStep('Khi chơi gam, ngón cái luồn xuống dưới để đi tiếp. Gọi là chuyển ngón.'),
    SongStep('Gam Đô trưởng – tay phải', 'scale-c', 1),
  ]),
  const Lesson(id: 'r6-2', region: 6, title: 'Gam hai tay', emoji: '🙌', skill: 'Gam hai tay', steps: [SongStep('Gam Đô trưởng – hai tay', 'scale-c', 3)]),
  const Lesson(id: 'r6-3', region: 6, title: 'Hợp âm rải hai tay', emoji: '🌊', skill: 'Hợp âm rải hai tay', steps: [SongStep('Hợp âm rải với hợp âm tay trái', 'arpeggio', 3)]),
  const Lesson(id: 'r6-4', region: 6, title: 'Canon giai điệu', emoji: '🕊️', skill: 'Nốt trắng legato', steps: [
    TalkStep('Legato là chơi nối liền, nốt này chưa tắt đã sang nốt kia.'),
    SongStep('Canon – giai điệu', 'canon', 1),
  ]),
  const Lesson(id: 'r6-5', region: 6, title: 'Canon hai tay', emoji: '🎼', skill: 'Bè trầm', steps: [SongStep('Canon – hai tay', 'canon', 3)]),
  Lesson(id: 'r6-6', region: 6, title: 'Tai nhạc sĩ', emoji: '🎧', skill: 'Nghe giai điệu', steps: [
    GameStep('Nghe 2 nốt rồi chơi lại!', GameKind.ear, GameConfig(notes: _c4c5, rounds: 8, melodyLen: 2)),
  ]),
  const Lesson(id: 'r6-7', region: 6, title: 'Minuet biểu diễn', emoji: '🎩', skill: 'Biểu diễn đúng nhịp', steps: [SongStep('Minuet – biểu diễn', 'minuet', 4, PlayMode.timed)]),
  const Lesson(id: 'r6-boss', region: 6, title: 'Trùm cuối: Đêm Nhạc Hội', emoji: '🌟', skill: 'Nghệ sĩ biểu diễn', boss: true, steps: [
    TalkStep('Đêm Nhạc Hội đã đến! Cả thế giới âm nhạc đang chờ bạn biểu diễn Canon!'),
    SongStep('Canon – biểu diễn', 'canon', 4, PlayMode.timed),
  ]),
];

Lesson? lessonById(String id) => lessons.where((l) => l.id == id).firstOrNull;
List<Lesson> lessonsOf(int region) => lessons.where((l) => l.region == region).toList();
Region regionById(int id) => regions.firstWhere((r) => r.id == id);

bool isLessonUnlocked(ChildProfile child, Lesson lesson) {
  if (lesson.region > child.unlockedRegion) return false;
  final list = lessonsOf(lesson.region);
  final i = list.indexOf(lesson);
  return i <= 0 || child.lessons.containsKey(list[i - 1].id);
}

Lesson? nextLesson(ChildProfile child) => lessons.where((l) => !child.lessons.containsKey(l.id) && isLessonUnlocked(child, l)).firstOrNull;

({int got, int max, int done, int total}) regionStars(ChildProfile child, int region) {
  final list = lessonsOf(region);
  final got = list.fold<int>(0, (s, l) => s + (child.lessons[l.id]?.stars ?? 0));
  return (got: got, max: list.length * 3, done: list.where((l) => child.lessons.containsKey(l.id)).length, total: list.length);
}
