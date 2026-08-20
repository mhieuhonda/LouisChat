# LouisChat

Chào mừng bạn đến với **LouisChat** — một repository hỗn hợp đầy đủ mọi thứ.

## Repository này là gì?

Đây là một repository hỗn hợp (mixed repo) chứa nhiều dự án và nội dung khác nhau do
**Hieu Louis** xây dựng. Mỗi thư mục là một dự án riêng biệt, độc lập với nhau.

## Cấu trúc thư mục

```
LouisChat/
├── story/      # Bộ truyện tu tiên 1000 chương
└── chatbot/    # ChatBot 70K - chatbot tiếng Việt trả lời 70.000 câu hỏi
```

### story/

Bộ truyện tu tiên dài 1000 chương bằng tiếng Việt, thể loại tu tiên kịch tính
và hài hước. Nhân vật chính là **Hieu Louis**. Mỗi chương là một file `.txt` riêng:

```
story/
├── chap_0001.txt
├── chap_0002.txt
├── ...
└── chap_1000.txt
```

Mỗi chương có khoảng 1000 từ.

### chatbot/

ChatBot 70K là một con chatbot tiếng Việt viết bằng Python thuần, không cần
thư viện bên ngoài. Nó sở hữu kho tri thức với **70.000 câu hỏi và câu trả lời**
về đủ mọi chủ đề: toán học, khoa học, lịch sử, văn hóa, ẩm thực, công nghệ...

#### Cách chạy

```bash
cd chatbot

# Chạy chế độ trò chuyện tương tác
python3 chatbot.py

# Xem số câu hỏi trong kho tri thức
python3 chatbot.py --count

# Hỏi một câu cụ thể
python3 chatbot.py --ask "toán học là gì"

# Chạy demo vài câu mẫu
python3 chatbot.py --demo

# Xem hướng dẫn
python3 chatbot.py --help
```

#### Ví dụ

```bash
$ python3 chatbot.py --ask "hố đen là gì"
Bạn: hố đen là gì
Bot: Một điều đáng ngạc nhiên về hố đen là nó hiện diện ở khắp mọi nơi,
     ngay cả những nơi bạn không ngờ tới.
```

## Tác giả

- **Hieu Louis**
- Repository: https://github.com/mhieuhonda/LouisChat

## Giấy phép

Repository phục vụ mục đích học tập và giải trí.
