# Kế hoạch xây dựng app tự học piano cho bé 6–10 tuổi

Tên tạm: **Piano Quest – Hành Trình Phím Đàn**

---

## 1. Tầm nhìn và nguyên tắc sản phẩm

**Tầm nhìn:** Bé từ chưa biết phím nào có thể tự học, tự luyện và tự hào biểu diễn những bài hát Việt Nam và quốc tế, với lộ trình rõ ràng từ cơ bản đến nâng cao.

**5 nguyên tắc thiết kế:**

1. **Bé tự dùng được, không cần biết đọc:** mọi hướng dẫn đều có giọng nói, hình ảnh và hoạt cảnh.
2. **Mỗi buổi học thật ngắn, luôn có cảm giác thắng:** 10–15 phút, kết thúc bằng một thành tựu.
3. **Chơi đàn thật là trung tâm:** gamification phục vụ việc luyện tập, không thay thế nó.
4. **Tiến bộ phải nghe được, nhìn được:** bản thu “trước – sau”, phiên bản khó dần của cùng một bài.
5. **An toàn cho trẻ là mặc định:** không chat, không mạng xã hội công khai, phụ huynh kiểm soát mọi chia sẻ.

---

## 2. Người dùng

| Nhóm | Đặc điểm | Thiết kế cần có |
|---|---|---|
| Bé 6–7 tuổi | Chưa đọc trôi chảy, tập trung 5–10 phút, thích nhân vật và màu sắc | Giọng nói dẫn dắt, nút to, nốt nhạc có màu, buổi học ngắn |
| Bé 8–10 tuổi | Đọc được, thích thử thách, thích khoe và sưu tầm | Nhiệm vụ khó hơn, huy hiệu hiếm, sáng tác, biểu diễn |
| Phụ huynh | Người tải app, trả tiền, quyết định chia sẻ | Báo cáo ngắn gọn, thiết lập thời gian học, quản lý riêng tư |

---

## 3. Trải nghiệm dễ dùng cho bé

### 3.1 Lần đầu mở app (dưới 3 phút)

1. Nhân vật dẫn đường chào bé, ví dụ chú chim **Đô Rê**.
2. Bé chọn và trang trí nhân vật của mình.
3. Hỏi bé dùng đàn gì: đàn thật, đàn điện tử cắm cáp hay bàn phím trên màn hình.
4. Kiểm tra micro hoặc kết nối MIDI bằng một trò chơi “bấm phím bất kỳ để đánh thức con rồng”.
5. Bài kiểm tra xếp lớp dưới dạng trò chơi: bé chưa biết gì sẽ bắt đầu từ đầu; bé đã biết chơi có thể nhảy cóc.
6. Bé chơi được 3 nốt đầu tiên và nhận huy hiệu đầu tiên ngay trong buổi này.

### 3.2 Quy tắc giao diện

- Tối đa **3 lựa chọn** trên mỗi màn hình của bé.
- Nút bấm tối thiểu 64 pt, ưu tiên máy tính bảng xoay ngang.
- Không có chữ nào bắt buộc phải đọc; mọi chữ đều có nút nghe.
- Sai thì không có âm thanh tiêu cực; nhân vật nói “Thử lại nhé!” và gợi ý phím đúng.
- Ba lần sai liên tiếp sẽ tự giảm tốc độ hoặc tách đoạn nhỏ hơn.
- Khu vực phụ huynh khóa bằng câu đố dành cho người lớn.

### 3.3 Cấu trúc một buổi học

| Bước | Thời lượng | Nội dung |
|---|---|---|
| Khởi động | 1–2 phút | Trò chơi tai nghe hoặc vỗ nhịp |
| Học kỹ năng mới | 2–3 phút | Nhân vật làm mẫu, bé làm theo |
| Luyện tập | 3–5 phút | Trò chơi dùng kỹ năng vừa học |
| Chơi bài hát | 3–5 phút | Đoạn nhạc áp dụng kỹ năng |
| Tổng kết | 30 giây | Sao, phần thưởng, gợi ý buổi sau |

---

## 4. Hệ thống gamification

### 4.1 Bản đồ thế giới âm nhạc

| Vùng đất | Cấp độ | Kỹ năng | Trùm cuối |
|---|---|---|---|
| 1. Làng Phím Trắng | Tân binh | Tư thế, số ngón, phím trắng, Đô–Rê–Mi | Chơi *Một con vịt* đoạn đầu |
| 2. Rừng Nhịp Điệu | Tập sự | Nốt đen, nốt trắng, nhịp 4/4, năm ngón tay phải | Chơi *Twinkle Twinkle* đúng nhịp |
| 3. Biển Tay Trái | Khám phá | Tay trái, khóa Fa, chơi luân phiên hai tay | Chơi *Ode to Joy* có tay trái |
| 4. Núi Hai Tay | Phối hợp | Hai tay cùng lúc, hợp âm C–F–G | Chơi *Jingle Bells* hai tay |
| 5. Lâu Đài Sắc Thái | Nghệ sĩ | Mạnh–nhẹ, legato–staccato, pedal, phím đen | Biểu diễn trọn bài có sắc thái |
| 6. Nhạc Viện Bầu Trời | Bậc thầy | Gam, arpeggio, đọc bản nhạc, tác phẩm cổ điển | Recital nhiều bài |

Mỗi vùng có 8–12 bài học, một bài kiểm tra kỹ năng và một sân khấu biểu diễn cuối vùng.

### 4.2 Các cơ chế thưởng

| Cơ chế | Mục đích | Lưu ý |
|---|---|---|
| **3 sao mỗi bài:** đúng nốt, đúng nhịp, có sắc thái | Khuyến khích chơi lại bài cũ | Một sao đã đủ để đi tiếp |
| **Nốt nhạc vàng** | Tiền trong game để mua trang phục, nhạc cụ, phòng tập | Không bán bằng tiền thật cho bé |
| **Thẻ sưu tầm** | Sưu tầm nhạc cụ, nhà soạn nhạc, nhạc cụ dân tộc Việt Nam | Dạy thêm kiến thức âm nhạc |
| **Tuần luyện tập** | Thay cho streak hằng ngày | Đủ 4/7 ngày là hoàn thành, không phạt khi nghỉ |
| **Nhiệm vụ hằng ngày** | 3 nhiệm vụ nhỏ, khoảng 10 phút | Tự điều chỉnh theo điểm yếu của bé |
| **Thú cưng âm nhạc** | Lớn lên khi bé luyện tập | Không buồn hay chết khi bé nghỉ |
| **Phòng tập của bé** | Trang trí bằng phần thưởng | Tạo cảm giác sở hữu |
| **Trùm cuối** | Kiểm tra kỹ năng cuối vùng | Có thể thử lại không giới hạn |

### 4.3 Các trò chơi luyện kỹ năng

- **Bắt nốt rơi:** nốt rơi xuống, bé bấm đúng phím trước khi chạm đất.
- **Đoán tiếng:** nghe một nốt hoặc giai điệu ngắn, chọn hoặc chơi lại.
- **Nhảy theo nhịp:** nhân vật nhảy qua chướng ngại theo nhịp bé chơi.
- **Thám tử bản nhạc:** tìm nốt sai trong một đoạn nhạc.
- **Xưởng sáng tác:** ghép nốt và tiết tấu thành giai điệu riêng, đặt tên và lưu lại.
- **Song tấu cùng nhân vật:** bé chơi giai điệu, app chơi phần đệm như một ban nhạc.

### 4.4 Thể hiện sự tiến bộ

- **Bài hát nhiều cấp:** cùng một bài có các bản Dễ, Vừa, Khó, Biểu diễn.
- **Album “Trước – Sau”:** tự lưu bản thu lần đầu và lần đạt 3 sao để so sánh.
- **Cây kỹ năng:** hiển thị kỹ năng đã vững, đang luyện và sắp học.
- **Sổ tay nghệ sĩ:** tổng kết hằng tháng gồm số bài đã chơi, kỹ năng mới và bản thu hay nhất.

---

## 5. Nội dung bài hát

### 5.1 Chiến lược bản quyền

| Nhóm | Ví dụ | Ghi chú |
|---|---|---|
| Dân ca, đồng dao Việt Nam | *Bắc kim thang*, *Lý cây bông*, *Trống cơm*, *Cò lả* | Ưu tiên cho MVP, cần kiểm tra bản ký âm hoặc bản phối được dùng |
| Nhạc thiếu nhi quốc tế phổ biến | *Twinkle Twinkle*, *Mary Had a Little Lamb*, *Frère Jacques*, *London Bridge* | Ưu tiên cho MVP, tự soạn bản phối |
| Nhạc cổ điển thuộc phạm vi công cộng | *Ode to Joy*, *Minuet in G*, *Für Elise*, *Canon in D*, *Clair de Lune* | Tác phẩm gốc có thể dùng; bản phối do nhóm tự làm |
| Nhạc thiếu nhi Việt Nam có tác giả | *Một con vịt*, *Cả nhà thương nhau*, *Em yêu trường em*, *Cho con* | Cần xin phép tác giả hoặc tổ chức quản lý quyền tác giả trước khi phát hành |
| Nhạc pop, nhạc phim | *River Flows in You*, nhạc hoạt hình | Chỉ thêm sau khi có hợp đồng cấp phép |

### 5.2 Số lượng nội dung theo giai đoạn

- **MVP:** 2 vùng đất, khoảng 20 bài học, 15 bài hát, mỗi bài 2 cấp độ.
- **Phiên bản 1.0:** 4 vùng đất, khoảng 60 bài học, 40 bài hát.
- **Năm đầu:** 6 vùng đất, hơn 150 bài học, hơn 100 bài hát; thêm bài mới hằng tháng.

---

## 6. Chiến lược viral

Trẻ em không tự chia sẻ trên mạng. Viral cần đi qua **phụ huynh**, với nội dung khiến phụ huynh **tự hào và muốn khoe**.

### 6.1 Những khoảnh khắc đáng chia sẻ

| Tính năng | Cách hoạt động | Vì sao lan truyền |
|---|---|---|
| **Video biểu diễn tự động** | Sau khi đạt 3 sao, app tạo video dọc 15–30 giây có bàn phím hiệu ứng, tên bài và nhân vật | Phụ huynh đăng Facebook, Zalo, TikTok |
| **Video “Trước – Sau”** | Ghép bản thu đầu tiên và bản thu mới nhất của cùng một bài | Thể hiện rõ sự tiến bộ, rất dễ gây ấn tượng |
| **Chứng nhận cuối vùng** | Giấy chứng nhận đẹp, có thể in hoặc chia sẻ | Phụ huynh thích lưu và đăng |
| **Tổng kết tháng / năm** | Thẻ tổng kết kiểu “Wrapped”: số bài, kỹ năng mới, bài yêu thích | Có nhịp chia sẻ định kỳ |
| **Thiệp nhạc tặng người thân** | Bé chơi *Happy Birthday* hoặc bài chúc Tết, app tạo thiệp nhạc gửi ông bà, bố mẹ | Lan truyền trong gia đình, theo mùa lễ |
| **Sân khấu gia đình** | Bé biểu diễn qua link riêng tư cho người thân xem và gửi tim | Người nhận thấy app và tải về cho con mình |

**Mặc định an toàn:** video chỉ quay bàn phím và bàn tay hoặc dùng avatar; không lộ mặt, tên thật, trường học. Chỉ phụ huynh có quyền xuất video hoặc chia sẻ.

### 6.2 Cơ chế giới thiệu

- **Mời bạn cùng học:** phụ huynh gửi link; cả hai bé nhận một nhân vật hoặc trang phục hiếm.
- **Thử thách song tấu:** hai bé ở hai nhà cùng hoàn thành một bài song tấu theo lượt; không có chat.
- **Thử thách theo mùa:** Tết, Trung thu, Giáng sinh, ngày 1/6; hoàn thành nhận phần thưởng giới hạn.
- **Ưu đãi giới thiệu:** cả người mời và người được mời nhận thêm thời gian Premium miễn phí.

### 6.3 Kênh tăng trưởng

| Kênh | Hoạt động |
|---|---|
| Nhóm phụ huynh trên Facebook và Zalo | Chia sẻ video tiến bộ thật, mẹo giúp con luyện đàn |
| TikTok, Reels | Chuỗi “Con gái tôi tự học piano ngày 1 → ngày 100” |
| Trường mầm non, tiểu học, trung tâm năng khiếu | Thử thách mùa hè, biểu diễn cuối khóa |
| Cửa hàng đàn điện tử | Mã dùng thử Premium đi kèm khi mua đàn |
| Người có ảnh hưởng là phụ huynh | Hợp tác dài hạn, không quảng cáo nhắm trực tiếp tới trẻ |
| Tối ưu trên cửa hàng ứng dụng | Từ khóa “học piano cho bé”, “piano trẻ em”; video giới thiệu hấp dẫn |

### 6.4 Câu chuyện thương hiệu

Bắt đầu bằng chính hành trình của bạn: **“Tôi làm app này để con gái tôi tự học piano.”** Ghi lại hành trình của con từ ngày đầu tiên, có sự đồng ý của gia đình và bảo vệ thông tin cá nhân. Đây là nội dung chân thực và dễ lan truyền nhất.

---

## 7. Tài khoản, quyền riêng tư và an toàn

- **Tài khoản phụ huynh:** đăng nhập Apple, Google hoặc email.
- **Hồ sơ của bé:** tên hiển thị hoặc biệt danh, năm sinh, avatar; không cần email.
- **Nhiều hồ sơ:** một tài khoản có tối đa 4 bé.
- **Dữ liệu tối thiểu:** không thu thập vị trí, danh bạ, ảnh khuôn mặt; dữ liệu âm thanh mặc định xử lý trên máy.
- **Bản thu:** chỉ lưu khi phụ huynh bật; có thể xóa từng bản hoặc toàn bộ.
- **Không quảng cáo** cho trẻ, không chat, không bảng xếp hạng công khai.
- **Mua hàng:** chỉ trong khu vực phụ huynh có khóa.
- **Tuân thủ pháp lý:** Nghị định 13/2023/NĐ-CP về bảo vệ dữ liệu cá nhân, chính sách dành cho trẻ em của App Store và Google Play; nếu phát hành quốc tế, cần tuân thủ thêm COPPA và GDPR-K.
- **Kiểm soát thời gian:** phụ huynh đặt giới hạn mỗi ngày; app nhắc bé nghỉ sau khoảng 20 phút.

---

## 8. Kiến trúc công nghệ đề xuất

| Thành phần | Lựa chọn | Lý do |
|---|---|---|
| App di động | **Flutter** hoặc React Native | Một mã nguồn cho iPad, máy tính bảng Android và điện thoại |
| Âm thanh | Thư viện âm thanh độ trễ thấp và bộ mẫu âm piano chất lượng | Phản hồi tức thì khi bấm phím |
| Nhận diện nốt qua micro | Phân tích cao độ trên thiết bị, chẳng hạn thuật toán YIN; về sau dùng mô hình ML nhẹ để nhận diện nhiều nốt cùng lúc | Hoạt động ngoại tuyến, bảo vệ riêng tư |
| Kết nối đàn điện tử | MIDI qua USB và Bluetooth | Đo nốt, nhịp và lực bấm chính xác |
| Hiển thị bản nhạc | Dữ liệu **MusicXML** và trình hiển thị bản nhạc | Cùng một dữ liệu cho cả bản nhạc và chế độ nốt rơi |
| Backend | **Supabase** hoặc Firebase | Đăng nhập, cơ sở dữ liệu, lưu trữ, đồng bộ nhanh |
| Nội dung | CMS nội bộ để thêm bài học, bài hát, cấp độ | Cập nhật nội dung mà không cần phát hành lại app |
| Phân tích | Công cụ phân tích không định danh, phù hợp với trẻ em | Đo giữ chân người dùng và tỷ lệ hoàn thành |
| Video chia sẻ | Tạo video trên thiết bị | Không cần tải bản thu thô lên máy chủ |

### Mô hình dữ liệu chính

- `ParentAccount`: tài khoản, gói đăng ký, cài đặt riêng tư.
- `ChildProfile`: biệt danh, năm sinh, avatar, cấp độ hiện tại.
- `Skill`: kỹ năng và các kỹ năng cần học trước.
- `Lesson`: bài học, các bước, kỹ năng liên quan.
- `Song` và `Arrangement`: bài hát và các bản phối theo cấp độ.
- `PracticeSession`: thời gian, độ chính xác nốt, độ chính xác nhịp, số sao.
- `Recording`: bản thu do phụ huynh cho phép lưu.
- `Reward` và `Inventory`: phần thưởng và vật phẩm của bé.

### Thuật toán điều chỉnh độ khó

- Độ chính xác **trên 90%** trong hai lần liên tiếp: gợi ý cấp khó hơn.
- Độ chính xác **dưới 60%**: giảm tốc độ, tách đoạn ngắn hơn hoặc cho tập riêng từng tay.
- Lặp lại các kỹ năng yếu sau 1, 3 và 7 ngày.

---

## 9. Lộ trình phát triển

### Giai đoạn 0: Xác thực ý tưởng (2–3 tuần)

- Phỏng vấn 10–15 phụ huynh có con 6–10 tuổi.
- Làm prototype giấy hoặc Figma; quan sát con bạn và 3–5 bé khác sử dụng.
- Thử nghiệm nhận diện nốt qua micro với đàn piano cơ và đàn điện tử thật.
- **Kết quả cần đạt:** bé tự dùng prototype mà không cần người lớn giải thích.

### Giai đoạn 1: MVP (8–10 tuần)

- Onboarding, nhân vật, tài khoản phụ huynh và hồ sơ bé.
- Vùng 1 và Vùng 2 với khoảng 20 bài học.
- 15 bài hát dân ca, thiếu nhi quốc tế và cổ điển, mỗi bài 2 cấp.
- Bàn phím trên màn hình, micro, MIDI qua USB.
- 3 trò chơi luyện kỹ năng, hệ thống sao, nốt nhạc vàng và nhiệm vụ hằng ngày.
- Báo cáo tuần cho phụ huynh.
- **Video biểu diễn tự động** và chia sẻ qua phụ huynh.
- **Thử nghiệm kín:** 30–50 gia đình trong 4 tuần.

### Giai đoạn 2: Ra mắt công khai (6–8 tuần)

- Thêm Vùng 3 và Vùng 4, tổng cộng khoảng 40 bài hát.
- Video “Trước – Sau”, chứng nhận cuối vùng, thiệp nhạc.
- Chương trình mời bạn và thử thách theo mùa.
- MIDI qua Bluetooth, thú cưng âm nhạc, phòng tập của bé.
- Ra mắt App Store và Google Play tại Việt Nam.

### Giai đoạn 3: Mở rộng (liên tục)

- Vùng 5 và Vùng 6: pedal, sắc thái, tác phẩm cổ điển.
- Xưởng sáng tác nâng cao, song tấu giữa hai bé.
- Tổng kết năm, cấp phép thêm bài hát Việt Nam.
- Hỗ trợ tiếng Anh và phát hành ở thị trường khác.

---

## 10. Mô hình kiếm tiền

- **Miễn phí:** Vùng 1, một số bài hát và các trò chơi cơ bản.
- **Premium theo tháng hoặc năm:** mở toàn bộ vùng đất, thư viện bài hát và tính năng chia sẻ nâng cao.
- **Gói gia đình:** tối đa 4 bé.
- **Dùng thử 7 ngày** trước khi trả phí.
- **Hợp tác:** gói Premium đi kèm khi mua đàn điện tử.
- Không có quảng cáo, không bán vật phẩm bằng tiền thật trực tiếp cho bé.

---

## 11. Chỉ số cần theo dõi

| Nhóm | Chỉ số | Mục tiêu ban đầu |
|---|---|---|
| Kích hoạt | Bé hoàn thành bài học đầu tiên | Trên 80% |
| Giữ chân | Người dùng quay lại sau 1 / 7 / 30 ngày | Trên 50% / 30% / 15% |
| Học tập | Số buổi luyện mỗi tuần | Từ 3 buổi trở lên |
| Học tập | Tỷ lệ hoàn thành vùng 1 | Trên 50% |
| Viral | Tỷ lệ phụ huynh chia sẻ video | Trên 15% |
| Viral | Hệ số K: số người mới từ mỗi người dùng | Trên 0,3, hướng tới 0,5 |
| Kinh doanh | Tỷ lệ chuyển từ dùng thử sang trả phí | Trên 20% |
| Chất lượng | Độ chính xác nhận diện nốt qua micro | Trên 95% với nốt đơn |

---

## 12. Rủi ro và cách xử lý

| Rủi ro | Cách xử lý |
|---|---|
| Nhận diện nốt qua micro kém trong phòng ồn hoặc với hợp âm | Bắt đầu với nốt đơn, ưu tiên MIDI, có hướng dẫn hiệu chỉnh micro |
| Bé chán sau 2 tuần | Thêm nội dung theo mùa, thú cưng, sáng tác, bài hát bé yêu cầu |
| Vi phạm bản quyền bài hát | MVP dùng dân ca, nhạc thuộc phạm vi công cộng; xin phép trước khi dùng bài có tác giả |
| Bé tập sai tư thế khi không có giáo viên | Video tư thế ngắn, nhắc định kỳ, bài kiểm tra tư thế bằng hình ảnh minh họa |
| Rủi ro về quyền riêng tư của trẻ | Xử lý dữ liệu trên máy, phụ huynh kiểm soát chia sẻ, video không lộ mặt |
| Gamification lấn át việc học | Phần thưởng chỉ đến từ thời gian luyện tập và kỹ năng thật |

---

## 13. Việc nên làm ngay trong tuần này

1. Chọn tên app và thiết kế nhân vật dẫn đường.
2. Viết chi tiết 10 bài học đầu tiên của Vùng 1.
3. Chọn 15 bài hát cho MVP, ưu tiên dân ca và nhạc thuộc phạm vi công cộng.
4. Vẽ wireframe 6 màn hình: onboarding, bản đồ, bài học, chơi bài hát, kết quả, khu vực phụ huynh.
5. Làm prototype kỹ thuật: bàn phím trên màn hình và nhận diện một nốt qua micro.
6. Cho con gái bạn thử prototype, ghi lại chỗ bé bối rối và chỗ bé thích nhất.
