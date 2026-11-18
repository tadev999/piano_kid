import 'package:flutter/painting.dart';

enum ItemKind { hat, skin, room, petAcc }

class ShopItem {
  final String id, name, emoji;
  final ItemKind kind;
  final int price;
  final bool rewardOnly;
  const ShopItem(this.id, this.name, this.emoji, this.kind, this.price, {this.rewardOnly = false});
}

const items = <ShopItem>[
  ShopItem('hat-bow', 'Nơ xinh', '🎀', ItemKind.hat, 40),
  ShopItem('hat-cap', 'Mũ lưỡi trai', '🧢', ItemKind.hat, 40),
  ShopItem('hat-flower', 'Hoa cài tóc', '🌸', ItemKind.hat, 50),
  ShopItem('hat-glasses', 'Kính ngầu', '🕶️', ItemKind.hat, 60),
  ShopItem('hat-tophat', 'Mũ nhạc trưởng', '🎩', ItemKind.hat, 90),
  ShopItem('hat-crown', 'Vương miện', '👑', ItemKind.hat, 150),
  ShopItem('hat-grad', 'Mũ tốt nghiệp', '🎓', ItemKind.hat, 200),
  ShopItem('hat-santa', 'Mũ Ông Già Noel', '🎅', ItemKind.hat, 0, rewardOnly: true),
  ShopItem('hat-dragon', 'Rồng Vàng (quà mời bạn)', '🐉', ItemKind.hat, 0, rewardOnly: true),
  ShopItem('skin-classic', 'Cổ điển', '🎹', ItemKind.skin, 0),
  ShopItem('skin-candy', 'Kẹo ngọt', '🍭', ItemKind.skin, 80),
  ShopItem('skin-ocean', 'Đại dương', '🐳', ItemKind.skin, 80),
  ShopItem('skin-rainbow', 'Cầu vồng', '🌈', ItemKind.skin, 120),
  ShopItem('skin-galaxy', 'Dải ngân hà', '🌌', ItemKind.skin, 180),
  ShopItem('skin-gold', 'Đàn vàng', '🏆', ItemKind.skin, 0, rewardOnly: true),
  ShopItem('room-plant', 'Chậu cây', '🪴', ItemKind.room, 30),
  ShopItem('room-balloon', 'Bóng bay', '🎈', ItemKind.room, 30),
  ShopItem('room-teddy', 'Gấu bông', '🧸', ItemKind.room, 40),
  ShopItem('room-art', 'Bức tranh', '🖼️', ItemKind.room, 50),
  ShopItem('room-lamp', 'Đèn ngôi sao', '🌟', ItemKind.room, 60),
  ShopItem('room-drum', 'Cái trống', '🥁', ItemKind.room, 70),
  ShopItem('room-violin', 'Đàn violin', '🎻', ItemKind.room, 90),
  ShopItem('room-trophy', 'Cúp vàng', '🏆', ItemKind.room, 120),
  ShopItem('room-tree', 'Cây thông Noel', '🎄', ItemKind.room, 0, rewardOnly: true),
  ShopItem('room-lantern', 'Đèn lồng', '🏮', ItemKind.room, 0, rewardOnly: true),
  ShopItem('room-kite', 'Diều giấy', '🪁', ItemKind.room, 0, rewardOnly: true),
  ShopItem('pet-scarf', 'Khăn quàng', '🧣', ItemKind.petAcc, 40),
  ShopItem('pet-hat', 'Mũ rộng vành', '👒', ItemKind.petAcc, 50),
  ShopItem('pet-wand', 'Đũa phép', '🪄', ItemKind.petAcc, 70),
  ShopItem('pet-note', 'Nốt nhạc', '🎵', ItemKind.petAcc, 30),
];

ShopItem? itemById(String? id) => id == null ? null : items.where((i) => i.id == id).firstOrNull;

class KeySkin {
  final List<Color> white, black;
  final Color glow;
  const KeySkin(this.white, this.black, this.glow);
}

const skinStyles = <String, KeySkin>{
  'skin-classic': KeySkin([Color(0xffffffff), Color(0xfff1f3f5)], [Color(0xff495057), Color(0xff212529)], Color(0xffffd43b)),
  'skin-candy': KeySkin([Color(0xffffffff), Color(0xffffe3ec)], [Color(0xfff06595), Color(0xffa61e4d)], Color(0xfff783ac)),
  'skin-ocean': KeySkin([Color(0xffffffff), Color(0xffe3fafc)], [Color(0xff1c7ed6), Color(0xff0b3d91)], Color(0xff66d9e8)),
  'skin-rainbow': KeySkin([Color(0xffffffff), Color(0xfffff9db)], [Color(0xff845ef7), Color(0xff5f3dc4)], Color(0xffff922b)),
  'skin-galaxy': KeySkin([Color(0xfff8f0fc), Color(0xffe5dbff)], [Color(0xff3b0764), Color(0xff0b0423)], Color(0xffb197fc)),
  'skin-gold': KeySkin([Color(0xffffffff), Color(0xfffff3bf)], [Color(0xffe67700), Color(0xff7a3d00)], Color(0xfffcc419)),
};

class MusicCard {
  final String id, name, emoji, rarity, fact;
  const MusicCard(this.id, this.name, this.emoji, this.rarity, this.fact);
}

const cards = <MusicCard>[
  MusicCard('piano', 'Đàn piano', '🎹', 'common', 'Đàn piano có 88 phím: 52 phím trắng và 36 phím đen.'),
  MusicCard('dan-bau', 'Đàn bầu', '🪕', 'common', 'Đàn bầu của Việt Nam chỉ có một dây, nghệ sĩ uốn cần đàn để tạo ra nhiều cao độ.'),
  MusicCard('dan-tranh', 'Đàn tranh', '🎐', 'common', 'Đàn tranh thường có 16 dây, tiếng đàn trong trẻo như nước chảy.'),
  MusicCard('sao-truc', 'Sáo trúc', '🎋', 'common', 'Sáo trúc được làm từ ống trúc, thổi hơi vào để tạo ra tiếng nhạc.'),
  MusicCard('dan-nguyet', 'Đàn nguyệt', '🌕', 'common', 'Đàn nguyệt có hộp đàn tròn như mặt trăng, còn được gọi là đàn kìm.'),
  MusicCard('trung', "Đàn t'rưng", '🎍', 'common', "Đàn t'rưng làm từ những ống tre, là nhạc cụ của đồng bào Tây Nguyên."),
  MusicCard('dan-da', 'Đàn đá', '🪨', 'common', 'Đàn đá làm từ những thanh đá, là một trong những nhạc cụ cổ xưa nhất của Việt Nam.'),
  MusicCard('trong-dong', 'Trống đồng', '🥁', 'rare', 'Trống đồng Đông Sơn đã có từ hơn 2000 năm trước.'),
  MusicCard('violin', 'Violin', '🎻', 'common', 'Đàn violin có 4 dây và được chơi bằng cây vĩ.'),
  MusicCard('guitar', 'Guitar', '🎸', 'common', 'Đàn guitar phổ biến có 6 dây.'),
  MusicCard('flute', 'Sáo flute', '🪈', 'common', 'Sáo flute hiện đại làm bằng kim loại nhưng vẫn thuộc nhóm kèn gỗ.'),
  MusicCard('trumpet', 'Kèn trumpet', '🎺', 'common', 'Kèn trumpet có 3 phím bấm.'),
  MusicCard('harp', 'Đàn hạc', '🧚', 'rare', 'Đàn hạc dùng trong dàn nhạc giao hưởng có khoảng 47 dây.'),
  MusicCard('mozart', 'Mozart', '👦', 'rare', 'Mozart bắt đầu sáng tác nhạc từ khi mới khoảng 5 tuổi.'),
  MusicCard('beethoven', 'Beethoven', '🎶', 'rare', 'Beethoven vẫn sáng tác những bản nhạc tuyệt vời khi đôi tai gần như không còn nghe được.'),
  MusicCard('bach', 'J. S. Bach', '⛪', 'rare', 'Bach sinh ra trong một gia đình có rất nhiều nhạc sĩ.'),
  MusicCard('chopin', 'Chopin', '🌙', 'rare', 'Chopin được gọi là "nhà thơ của cây đàn piano".'),
  MusicCard('vivaldi', 'Vivaldi', '🍂', 'rare', 'Vivaldi viết bản nhạc Bốn Mùa: Xuân, Hạ, Thu, Đông.'),
  MusicCard('tchaikovsky', 'Tchaikovsky', '🩰', 'rare', 'Tchaikovsky viết nhạc cho vở ballet Kẹp Hạt Dẻ.'),
  MusicCard('debussy', 'Debussy', '🌌', 'rare', 'Debussy viết bản Clair de Lune (Ánh trăng) rất nổi tiếng.'),
  MusicCard('grand-piano', 'Grand piano', '🏛️', 'epic', 'Đàn grand piano có dây đàn nằm ngang, dùng trong các buổi hòa nhạc lớn.'),
  MusicCard('golden-key', 'Chìa khóa vàng', '🗝️', 'epic', 'Chỉ những nghệ sĩ vượt qua thử thách trùm mới có chìa khóa này!'),
];

MusicCard? cardById(String? id) => cards.where((c) => c.id == id).firstOrNull;

class Badge {
  final String id, name, emoji, desc;
  const Badge(this.id, this.name, this.emoji, this.desc);
}

const badges = <Badge>[
  Badge('first-note', 'Nốt nhạc đầu tiên', '🎵', 'Hoàn thành bài học đầu tiên'),
  Badge('first-song', 'Bài hát đầu tiên', '🎤', 'Chơi trọn một bài hát'),
  Badge('three-stars', 'Ba sao rực rỡ', '🌟', 'Đạt 3 sao một bài hát'),
  Badge('songs-10', 'Mười bài hát', '📚', 'Hoàn thành 10 bản nhạc khác nhau'),
  Badge('region-1', 'Vượt Làng Phím Trắng', '🏡', 'Thắng Rồng Ngủ Gật'),
  Badge('region-2', 'Vượt Rừng Nhịp Điệu', '🌳', 'Thắng Khỉ Đánh Trống'),
  Badge('region-3', 'Vượt Biển Tay Trái', '🌊', 'Thắng Bạch Tuộc Tám Tay'),
  Badge('region-4', 'Chinh phục Núi Hai Tay', '⛰️', 'Thắng Người Tuyết Khổng Lồ'),
  Badge('region-5', 'Chủ nhân Lâu Đài', '🏰', 'Thắng Bà Chúa Tuyết'),
  Badge('region-6', 'Nghệ sĩ Bầu Trời', '🌈', 'Hoàn thành Đêm Nhạc Hội'),
  Badge('week-goal', 'Tuần chăm chỉ', '📅', 'Luyện tập 4 ngày trong một tuần'),
  Badge('days-7', '7 ngày luyện đàn', '🔥', 'Tổng cộng 7 ngày luyện tập'),
  Badge('days-30', '30 ngày luyện đàn', '💎', 'Tổng cộng 30 ngày luyện tập'),
  Badge('composer', 'Nhà soạn nhạc nhí', '✍️', 'Lưu giai điệu tự sáng tác'),
  Badge('ear-master', 'Đôi tai vàng', '👂', 'Đoán đúng hết trong trò Đoán tiếng'),
  Badge('rhythm-master', 'Bậc thầy nhịp điệu', '🥁', 'Đạt 90% trò Nhảy theo nhịp'),
  Badge('collector', 'Nhà sưu tầm', '🃏', 'Sưu tầm 10 thẻ nhạc cụ'),
  Badge('decorator', 'Phòng tập xinh', '🛋️', 'Mua món đồ đầu tiên'),
  Badge('pet-adult', 'Bạn thân trưởng thành', '💞', 'Thú cưng lớn hết cỡ'),
  Badge('stage', 'Ngôi sao sân khấu', '🎭', 'Biểu diễn cho gia đình xem'),
  Badge('event', 'Nhà vô địch sự kiện', '🏅', 'Hoàn thành một thử thách theo mùa'),
];

Badge? badgeById(String id) => badges.where((b) => b.id == id).firstOrNull;

const pets = <String, ({String name, List<String> stages})>{
  'cat': (name: 'Mèo Mi', stages: ['🥚', '🐱', '🐈', '🐯']),
  'dragon': (name: 'Rồng Rê', stages: ['🥚', '🦎', '🐲', '🐉']),
  'bunny': (name: 'Thỏ Đô', stages: ['🥚', '🐰', '🐇', '🦄']),
  'owl': (name: 'Cú Sol', stages: ['🥚', '🐣', '🐥', '🦉']),
};

const petStageXp = [0, 30, 150, 500];
const petStageNames = ['Quả trứng', 'Em bé', 'Thiếu niên', 'Trưởng thành'];

int petStage(int xp) {
  var s = 0;
  for (var i = 0; i < petStageXp.length; i++) {
    if (xp >= petStageXp[i]) s = i;
  }
  return s;
}

String petEmoji(String pet, int xp) => (pets[pet] ?? pets['cat']!).stages[petStage(xp)];

const animals = ['🐱', '🐶', '🐰', '🦊', '🐼', '🐨', '🐯', '🦄', '🐸', '🐵', '🐧', '🦁'];
const avatarColors = ['#ffc9c9', '#ffd8a8', '#ffec99', '#c3fae8', '#a5d8ff', '#d0bfff', '#fcc2d7', '#b2f2bb'];

class SeasonEvent {
  final String id, name, emoji, from, to, rewardItem, desc;
  final int goal;
  const SeasonEvent(this.id, this.name, this.emoji, this.from, this.to, this.goal, this.rewardItem, this.desc);
}

const seasonEvents = <SeasonEvent>[
  SeasonEvent('tet', 'Tết rộn ràng', '🧧', '01-10', '02-28', 12, 'room-lantern', 'Chơi 12 bài để rước đèn lồng đón Tết!'),
  SeasonEvent('thieu-nhi', 'Quốc tế Thiếu nhi', '🎈', '05-25', '06-10', 10, 'room-kite', 'Mừng 1/6: chơi 10 bài nhận diều giấy!'),
  SeasonEvent('he', 'Thử thách mùa hè', '☀️', '06-11', '08-31', 30, 'skin-gold', 'Cả mùa hè luyện 30 bài để nhận Đàn Vàng!'),
  SeasonEvent('trung-thu', 'Trung thu phá cỗ', '🥮', '09-01', '09-30', 10, 'room-lantern', 'Chơi 10 bài để rước đèn Trung thu!'),
  SeasonEvent('xmas', 'Giáng sinh an lành', '🎄', '12-01', '12-31', 10, 'hat-santa', 'Chơi 10 bài để nhận mũ Ông Già Noel!'),
];

const monthlyEvent = SeasonEvent('month', 'Thử thách tháng này', '🗓️', '', '', 15, '', 'Hoàn thành 15 bài học hoặc bài hát trong tháng!');

Color hexColor(String hex) => Color(int.parse('ff${hex.replaceFirst('#', '')}', radix: 16));
