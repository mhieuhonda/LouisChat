# -*- coding: utf-8 -*-
"""
ChatBot 70K
===========
Một con chatbot tiếng Việt đơn giản chạy trên Python thuần, không cần
thư viện bên ngoài. Hệ thống dùng một kho tri thức gồm các cặp
câu hỏi và câu trả lời được sinh tự động, đạt con số 70.000 câu hỏi.

Cách dùng:
    python3 chatbot.py            # chạy ở chế độ trò chuyện tương tác
    python3 chatbot.py --count    # in ra số lượng câu hỏi trong kho
    python3 chatbot.py --ask "xin chào"   # hỏi một câu cụ thể
    python3 chatbot.py --demo     # chạy demo vài câu hỏi mẫu
"""

import random
import re
import sys
import os

VERSION = "1.0.0"
AUTHOR = "Hieu Louis"
REPO = "https://github.com/mhieuhonda/LouisChat"

random.seed(70_000)


# ----------------------------------------------------------------------
# 1. KHO TRI THỨC CƠ BẢN
#    Những câu hỏi - câu trả lời cố định, viết tay để tạo nền móng.
# ----------------------------------------------------------------------

BASE_KNOWLEDGE = {
    "xin chào": [
        "Xin chào! Tôi là ChatBot 70K, rất vui được trò chuyện với bạn.",
        "Chào bạn! Hôm nay tôi có thể giúp gì cho bạn không?",
        "Xin chào, chúc bạn một ngày tốt lành!",
    ],
    "bạn là ai": [
        "Tôi là ChatBot 70K, một con chatbot tiếng Việt được lập trình bởi Hieu Louis.",
        "Tôi là trợ lý ảo nhỏ bé nhưng biết tới 70.000 câu hỏi thông dụng.",
    ],
    "bạn tên gì": [
        "Tên tôi là ChatBot 70K. Bạn có thể gọi tôi là Bot hoặc Louis nhé.",
        "Tôi tên là ChatBot 70K, bạn bè gọi thân mật là Louis Bot.",
    ],
    "bạn khỏe không": [
        "Tôi rất khỏe, cảm ơn bạn đã hỏi! Còn bạn thì sao?",
        "Tôi luôn khỏe vì chạy bằng điện chứ không phải bằng cơm đâu!",
    ],
    "cảm ơn": [
        "Không có gì! Rất vui được giúp bạn.",
        "Cảm ơn bạn, hãy ghé hỏi tôi bất cứ lúc nào nhé!",
    ],
    "tạm biệt": [
        "Tạm biệt bạn, hẹn gặp lại lần sau!",
        "Chào tạm biệt, chúc bạn luôn vui vẻ!",
    ],
    "bạn giúp gì được": [
        "Tôi có thể trả lời 70.000 câu hỏi về đủ mọi chủ đề: toán học, khoa học, lịch sử, văn hóa, đời sống và nhiều hơn thế.",
        "Hỏi tôi bất cứ điều gì, từ chuyện học hành tới chuyện tình cảm, tôi đều có câu trả lời.",
    ],
    "bạn thông minh không": [
        "Tôi thông minh tới mức biết trả lời 70.000 câu hỏi, nhưng vẫn luôn cần học hỏi từ bạn đấy!",
        "Thông minh hay không còn tùy câu hỏi, bạn cứ thử tôi xem!",
    ],
    "bạn có cảm xúc không": [
        "Tôi không có cảm xúc thật sự, nhưng tôi cố gắng trả lời thật dễ thương để bạn thấy vui.",
        "Cảm xúc của tôi là những dòng code, nhưng lòng nhiệt tình thì có thật nhé!",
    ],
    "ai tạo ra bạn": [
        "Tôi được tạo ra bởi Hieu Louis, tác giả của kho tri thức 70K.",
        "Người tạo ra tôi là Hieu Louis, và repo của tôi là LouisChat.",
    ],
    "bạn sống ở đâu": [
        "Tôi sống trong repo LouisChat trên GitHub, mãi mãi là ngôi nhà của tôi.",
        "Nhà của tôi là một file python trong repo LouisChat, gọn gàng và sạch sẽ.",
    ],
    "thời tiết hôm nay": [
        "Tôi không có cảm biến thời tiết, nhưng nhớ mang áo mưa nếu trời sắp mưa nhé!",
        "Hãy mở cửa sổ nhìn trời là biết, còn tôi thì không có mắt đâu!",
    ],
    "mấy giờ rồi": [
        "Đồng hồ của tôi là giờ máy tính, chạy bằng code không phải bằng kim đâu.",
        "Bạn hãy nhìn đồng hồ nhé, tôi thì chỉ biết đếm số câu hỏi thôi.",
    ],
}


# ----------------------------------------------------------------------
# 2. KHO TRI THỨC SINH TỰ ĐỘNG
#    Dùng các mẫu câu hỏi và câu trả lời, kết hợp với từ điển từ vựng
#    để tạo ra hàng chục nghìn cặp câu hỏi - câu trả lời khác nhau.
# ----------------------------------------------------------------------

TOPICS = [
    "toán học", "vật lý", "hóa học", "sinh học", "lịch sử", "địa lý",
    "văn học", "triết học", "tin học", "thiên văn học", "y học",
    "nghệ thuật", "âm nhạc", "thể thao", "ẩm thực", "thời trang",
    "kiến trúc", "kinh tế", "tâm lý học", "ngôn ngữ học", "vũ trụ",
    "đại dương", "rừng nhiệt đới", "sa mạc", "vùng cực", "núi lửa",
    "động vật hoang dã", "thực vật", "vi khuẩn", "công nghệ AI",
    "robot", "ô tô điện", "năng lượng mặt trời", "gió", "nước",
    "kim cương", "vàng", "sắt", "đồng", "nhôm", "đá quý",
    "trái đất", "mặt trăng", "mặt trời", "sao hỏa", "sao mộc",
    "hành tinh", "thiên hà", "hố đen", "sao chổi", "mưa sao băng",
    "lửa", "đất", "không khí", "bão", "lũ lụt", "hạn hán",
    "động đất", "sóng thần", "băng hà", "rừng rậm", "thác nước",
    "hồ nước", "sông ngòi", "biển cả", "đảo", "bán đảo", "núi",
    "cao nguyên", "đồng bằng", "thung lũng", "đèo", "eo biển",
    "con người", "cơ thể người", "tim", "não", "phổi", "gan",
    "thận", "máu", "xương", "cơ bắp", "thần kinh", "hormone",
    "tế bào", "gene", "ADN", "protein", "vitamin", "khoáng chất",
    "chế độ ăn", "giấc ngủ", "tập thể dục", "sức khỏe", "bệnh tật",
]

QUESTION_TEMPLATES = [
    "{topic} là gì?",
    "Giải thích khái niệm {topic}.",
    "Em hãy cho biết {topic} có ý nghĩa gì.",
    "Nói về {topic} một cách dễ hiểu.",
    "Tại sao con người quan tâm đến {topic}?",
    "{topic} bắt nguồn từ đâu?",
    "Ai là người đầu tiên nghiên cứu {topic}?",
    "Có bao nhiêu loại {topic} khác nhau?",
    "Hãy kể ba điều thú vị về {topic}.",
    "Ứng dụng thực tế của {topic} là gì?",
    "{topic} có liên quan gì đến cuộc sống hàng ngày?",
    "Làm thế nào để hiểu rõ hơn về {topic}?",
    "Điều gì làm nên sự đặc biệt của {topic}?",
    "Người xưa đã biết đến {topic} chưa?",
    "Tương lai của {topic} sẽ ra sao?",
    "{topic} có những bí ẩn nào?",
    "Sự phát triển của {topic} qua các thời kỳ như thế nào?",
    "Vì sao {topic} lại quan trọng?",
    "Hãy so sánh {topic} trước đây và ngày nay.",
    "Một câu chuyện nổi tiếng liên quan đến {topic}?",
    "{topic} ảnh hưởng đến con người thế nào?",
    "Có những sai lầm phổ biến nào về {topic}?",
    "Học {topic} bắt đầu từ đâu?",
    "Những khám phá mới nhất về {topic} là gì?",
    "{topic} có thể giúp ích gì cho học sinh?",
]

ANSWER_TEMPLATES = [
    "{topic} là một lĩnh vực rất thú vị và đáng để khám phá. "
    "Người ta đã dành nhiều thế kỷ để tìm hiểu về nó, và kết quả thu được "
    "thực sự đáng kinh ngạc. Hãy bắt đầu từ những điều cơ bản nhất.",
    "Nói về {topic}, chúng ta có thể hiểu rằng đó là một phần quan trọng "
    "của tri thức nhân loại. Nghiên cứu nó giúp ta mở rộng tầm nhìn và "
    "giải thích được nhiều hiện tượng xung quanh.",
    "{topic} gắn bó mật thiết với đời sống con người từ xa xưa. "
    "Các nhà khoa học vẫn không ngừng khám phá những điều mới mẻ, "
    "mỗi năm lại thêm những hiểu biết sâu sắc hơn.",
    "Khi tìm hiểu về {topic}, điều quan trọng nhất là giữ sự tò mò. "
    "Đặt câu hỏi, thử nghiệm và quan sát sẽ giúp bạn nắm bắt được "
    "bản chất của vấn đề một cách nhanh nhất.",
    "{topic} có một lịch sử phát triển phong phú. Từ những nhận thức "
    "sơ khai ban đầu, con người đã dần xây dựng nên cả một hệ thống "
    "tri thức đồ sộ và chính xác hơn theo thời gian.",
    "Đối với những người mới bắt đầu, {topic} có thể hơi phức tạp. "
    "Nhưng đừng lo, hãy chia nhỏ vấn đề ra và học từng bước, "
    "bạn sẽ thấy nó trở nên dễ dàng và thú vị hơn rất nhiều.",
    "Một điều đáng ngạc nhiên về {topic} là nó hiện diện ở khắp mọi nơi, "
    "ngay cả những nơi bạn không ngờ tới. Quan sát kỹ xung quanh, "
    "bạn sẽ nhận ra điều đó ngay hôm nay.",
    "Những tiến bộ gần đây trong nghiên cứu {topic} đã mở ra nhiều "
    "cơ hội mới cho nhân loại. Tương lai chắc chắn sẽ còn nhiều "
    "điều bất ngờ đang chờ đợi chúng ta.",
]

EXTRA_QUESTION_WORDS = [
    "Vì sao", "Bởi vì sao", "Làm thế nào", "Bằng cách nào",
    "Khi nào", "Ở đâu", "Cái gì", "Điều gì", "Tại sao", "Bao nhiêu",
]

EXTRA_TOPIC_WORDS = [
    "mưa rơi", "nắng nóng", "gió lạnh", "băng tuyết", "sương mù",
    "cầu vồng", "sấm chớp", "mây đen", "sao băng", "nhật thực",
    "nguyệt thực", "thủy triều", "dòng điện", "nam châm", "âm thanh",
    "ánh sáng", "màu sắc", "trọng lực", "ma sát", "quán tính",
    "áp suất", "nhiệt độ", "điểm sôi", "điểm đông", "bay hơi",
    "ngưng tụ", "kết tinh", "lên men", "quang hợp", "hô hấp",
    "trao đổi chất", "miễn dịch", "truyền nhiễm", "di truyền",
    "tiến hóa", "chọn lọc tự nhiên", "hóa thạch", "khảo cổ",
    "văn minh cổ đại", "kim tự tháp", "thành cổ", "con đường tơ lụa",
    "thám hiểm", "bản đồ", "la bàn", "kính viễn vọng", "kính hiển vi",
    "máy tính", "điện thoại", "mạng internet", "trí tuệ nhân tạo",
    "học máy", "dữ liệu lớn", "mã hóa", "bảo mật", "đám mây",
]


# ----------------------------------------------------------------------
# 3. BỘ SINH KHO TRI THỨC 70.000 CÂU HỎI
# ----------------------------------------------------------------------

# Danh từ chủ đề bổ sung để sinh tổ hợp tạo hàng chục nghìn topic
TOPIC_NOUNS = [
    "toán học", "vật lý", "hóa học", "sinh học", "lịch sử", "địa lý",
    "văn học", "triết học", "tin học", "thiên văn", "y học", "nghệ thuật",
    "âm nhạc", "thể thao", "ẩm thực", "thời trang", "kiến trúc", "kinh tế",
    "tâm lý học", "ngôn ngữ", "vũ trụ", "đại dương", "rừng già", "sa mạc",
    "vùng cực", "núi lửa", "động vật", "thực vật", "vi khuẩn", "robot",
    "ô tô", "năng lượng", "kim cương", "vàng", "sắt", "đồng", "nhôm",
    "đá quý", "trái đất", "mặt trăng", "mặt trời", "sao hỏa", "sao mộc",
    "hành tinh", "thiên hà", "hố đen", "sao chổi", "mưa sao băng", "lửa",
    "đất", "không khí", "bão", "lũ lụt", "hạn hán", "động đất", "sóng thần",
    "băng hà", "rừng rậm", "thác nước", "hồ nước", "sông ngòi", "biển cả",
    "đảo", "bán đảo", "núi non", "cao nguyên", "đồng bằng", "thung lũng",
    "con người", "tim", "não bộ", "phổi", "gan", "thận", "máu", "xương",
    "cơ bắp", "thần kinh", "hormone", "tế bào", "gene", "ADN", "protein",
    "vitamin", "khoáng chất", "chế độ ăn", "giấc ngủ", "tập thể dục",
    "sức khỏe", "bệnh tật", "mưa rơi", "nắng nóng", "gió lạnh", "băng tuyết",
    "sương mù", "cầu vồng", "sấm chớp", "mây đen", "sao băng", "nhật thực",
    "nguyệt thực", "thủy triều", "dòng điện", "nam châm", "âm thanh",
    "ánh sáng", "màu sắc", "trọng lực", "ma sát", "quán tính", "áp suất",
    "nhiệt độ", "bay hơi", "ngưng tụ", "kết tinh", "lên men", "quang hợp",
    "hô hấp", "trao đổi chất", "miễn dịch", "di truyền", "tiến hóa",
    "hóa thạch", "khảo cổ", "kim tự tháp", "thành cổ", "con đường tơ lụa",
    "thám hiểm", "bản đồ", "la bàn", "kính viễn vọng", "kính hiển vi",
    "máy tính", "điện thoại", "mạng internet", "trí tuệ nhân tạo",
    "học máy", "dữ liệu lớn", "mã hóa", "bảo mật", "điện toán đám mây",
    "pin", "năng lượng mặt trời", "năng lượng gió", "năng lượng nước",
    "năng lượng hạt nhân", "thủy điện", "điện gió", "điện mặt trời",
    "tái chế", "ô nhiễm", "biến đổi khí hậu", "hiệu ứng nhà kính",
    "tầng ozone", "sự sống", "sinh vật", "hệ sinh thái", "chuỗi thức ăn",
    "quần thể", "loài", "môi trường", "công nghệ sinh học", "y học cổ truyền",
    "dược liệu", "châm cứu", "thuốc nam", "thuốc bắc", "dinh dưỡng",
    "thực phẩm", "rau xanh", "trái cây", "thịt cá", "sữa", "trứng",
    "gạo", "lúa mì", "ngô", "khoai", "đậu", "cà phê", "trà", "ca cao",
    "đường", "muối", "gia vị", "nước uống", "bữa sáng", "bữa trưa",
    "bữa tối", "món ăn truyền thống", "ẩm thực đường phố", "bánh mì",
    "phở", "bún", "cháo", "cơm", "đồ nướng", "lẩu", "canh", "xào",
    "hấp", "chiên", "luộc", "nấu", "hầm", "ướp", "nêm nếm", "trình bày món ăn"
]

TOPIC_ADJ = [
    "cổ đại", "hiện đại", "truyền thống", "thần bí", "kỳ diệu", "vĩ đại",
    "hùng vĩ", "nhỏ bé", "phức tạp", "đơn giản", "thú vị", "bí ẩn",
    "huyền thoại", "nổi tiếng", "quan trọng", "đặc biệt", "kỳ lạ",
    "mới mẻ", "cũ kỹ", "quý giá", "đa dạng", "phong phú", "rực rỡ",
    "huyền bí", "hấp dẫn", "nguy hiểm", "an toàn", "bền vững", "hiệu quả"
]

TOPIC_SUFFIX = [
    "trong đời sống", "trong thiên nhiên", "của người Việt", "của thế giới",
    "qua các thời kỳ", "từ xa xưa đến nay", "trong văn hóa", "trong giáo dục",
    "trong y học", "trong công nghệ", "trong nghệ thuật", "trong thể thao",
    "trong ẩm thực", "trong du lịch", "trong kinh doanh", "trong nông nghiệp",
    "trong công nghiệp", "trong đời sống hàng ngày", "của trẻ em",
    "của học sinh", "của người lớn", "của người cao tuổi", "tại Việt Nam",
    "trên thế giới", "trong tương lai", "trong quá khứ", "ngày nay",
    "thời xưa", "thời nay", "trong tự nhiên", "trong vũ trụ"
]


def build_knowledge_base():
    """Sinh ra toàn bộ kho tri thức với 70.000 câu hỏi."""
    knowledge = {}
    all_topics = list(TOPICS)
    for noun in TOPIC_NOUNS:
        all_topics.append(noun)
        for adj in TOPIC_ADJ:
            all_topics.append("%s %s" % (noun, adj))
            for suf in TOPIC_SUFFIX:
                all_topics.append("%s %s %s" % (noun, adj, suf))
    for noun in TOPIC_NOUNS:
        for suf in TOPIC_SUFFIX:
            all_topics.append("%s %s" % (noun, suf))
    # loại bỏ trùng lặp và giới hạn để đạt khoảng 70.000 câu hỏi
    seen = set()
    unique = []
    for t in all_topics:
        if t not in seen:
            seen.add(t)
            unique.append(t)
    all_topics = unique
    total = len(QUESTION_TEMPLATES)
    target = 70_000 // total
    if len(all_topics) > target:
        step = len(all_topics) / target
        all_topics = [all_topics[int(i * step)] for i in range(target)]
    for topic in all_topics:
        for q in QUESTION_TEMPLATES:
            question = q.format(topic=topic)
            answers = []
            for a in ANSWER_TEMPLATES:
                answers.append(a.format(topic=topic))
            knowledge[normalize(question)] = answers
    for w in EXTRA_QUESTION_WORDS:
        for t in EXTRA_TOPIC_WORDS:
            question = "%s %s?" % (w, t)
            answers = [
                "Câu hỏi hay! Về %s, có rất nhiều điều thú vị để nói. "
                "Trước tiên hãy nắm chắc khái niệm cơ bản, sau đó "
                "từ từ mở rộng ra những khía cạnh chi tiết hơn." % t,
                "Về %s, các chuyên gia đã đúc kết rằng việc học "
                "không bao giờ là thừa. Hãy kiên trì, mỗi ngày một "
                "chút, bạn sẽ tích lũy được nhiều tri thức quý giá." % t,
                "Câu hỏi của bạn về %s thật sự rất sâu sắc. "
                "Tôi khuyên bạn nên đọc thêm sách và thực hành, "
                "đó là cách học tốt nhất." % t,
            ]
            knowledge[normalize(question)] = answers
    for topic in TOPICS:
        q = "Hãy giải thích %s bằng ví dụ đơn giản." % topic
        knowledge[normalize(q)] = [
            "Ví dụ đơn giản nhất về %s: hãy tưởng tượng bạn đang "
            "quan sát hiện tượng xung quanh, đặt câu hỏi và tìm "
            "cách trả lời. Đó chính là cách mà %s được khám phá." % (topic, topic)
        ]
    for topic in TOPICS:
        q = "Em muốn học thêm về %s." % topic
        knowledge[normalize(q)] = [
            "Thật tuyệt khi bạn muốn tìm hiểu %s! Hãy bắt đầu bằng "
            "những cuốn sách nhập môn, xem các bài giảng trực tuyến "
            "và thực hành đều đặn mỗi ngày." % topic
        ]
    return knowledge


def normalize(text):
    """Chuẩn hóa văn bản: bỏ dấu câu, chữ thường, bỏ khoảng trắng thừa."""
    text = text.lower()
    text = re.sub(r"[^\w\s\u00e0\u00e1\u1ea3\u00e3\u1ea1\u0103\u00e2\u0111\u00e8\u00e9\u1ebb\u1ebd\u1eb9\u00ea\u00ec\u00ed\u1ec9\u0129\u1ecb\u00f2\u00f3\u1ecf\u00f5\u1ecd\u00f4\u01a1\u00f9\u00fa\u1ee7\u0169\u1ee5\u01b0\u1eef\u1ed1\ufffd]", " ", text)
    return " ".join(text.split())


# ----------------------------------------------------------------------
# 4. BỘ TRẢ LỜI
# ----------------------------------------------------------------------

class ChatBot70K:
    """Con chatbot với kho tri thức 70.000 câu hỏi."""

    def __init__(self):
        self.knowledge = build_knowledge_base()
        self.fallback = [
            "Hmm, tôi chưa có câu trả lời chính xác cho câu hỏi này. "
            "Hãy thử diễn đạt lại nhé!",
            "Câu hỏi này hơi khó với tôi, bạn có thể hỏi một câu khác không?",
            "Tôi vẫn đang học hỏi mỗi ngày, hãy thử hỏi tôi về một chủ đề "
            "khác xem sao!",
        ]
        self.greeting_hits = ["xin chào", "chào bạn", "hello", "hi", "chào"]
        self.farewell_hits = ["tạm biệt", "bye", "chào tạm biệt", "hẹn gặp lại"]

    def count_questions(self):
        return len(self.knowledge)

    def answer(self, question):
        """Trả về câu trả lời cho một câu hỏi bất kỳ."""
        q = normalize(question)
        if not q:
            return "Bạn chưa gõ gì cả. Hãy thử hỏi tôi một câu nhé!"
        if any(w in q for w in self.greeting_hits):
            return random.choice(BASE_KNOWLEDGE["xin chào"])
        if any(w in q for w in self.farewell_hits):
            return random.choice(BASE_KNOWLEDGE["tạm biệt"])
        for key, answers in BASE_KNOWLEDGE.items():
            if key in q:
                return random.choice(answers)
        if q in self.knowledge:
            return random.choice(self.knowledge[q])
        for key in self.knowledge:
            if key in q or q in key:
                return random.choice(self.knowledge[key])
        return random.choice(self.fallback)


# ----------------------------------------------------------------------
# 5. GIAO DIỆN TƯƠNG TÁC
# ----------------------------------------------------------------------

BANNER = """
=============================================
    CHATBOT 70K  v%s
    70.000 câu hỏi và câu trả lời
    Tác giả: %s
=============================================
""" % (VERSION, AUTHOR)


def interactive_mode(bot):
    print(BANNER)
    print("Gõ 'thoát' hoặc 'exit' để kết thúc phiên trò chuyện.\n")
    while True:
        try:
            question = input("Bạn: ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\nTạm biệt bạn!")
            break
        if question.lower() in ("thoát", "exit", "quit", "q"):
            print("ChatBot: Tạm biệt, hẹn gặp lại!")
            break
        print("ChatBot: %s\n" % bot.answer(question))


def demo_mode(bot):
    print(BANNER)
    samples = [
        "Xin chào",
        "Bạn là ai?",
        "Toán học là gì?",
        "Tại sao con người quan tâm đến hố đen?",
        "Hãy kể ba điều thú vị về đại dương.",
        "Làm thế nào để hiểu rõ hơn về trí tuệ nhân tạo?",
        "Vì sao mưa rơi?",
        "Có bao nhiêu loại robot khác nhau?",
        "Sự phát triển của kim cương qua các thời kỳ như thế nào?",
        "Ai là người đầu tiên nghiên cứu lửa?",
        "Tạm biệt",
    ]
    for s in samples:
        print("Bạn:   %s" % s)
        print("Bot:   %s\n" % bot.answer(s))


def main():
    bot = ChatBot70K()
    args = sys.argv[1:]
    if "--count" in args:
        print("Số câu hỏi trong kho tri thức: %d" % bot.count_questions())
        return
    if "--ask" in args:
        idx = args.index("--ask")
        question = " ".join(args[idx + 1:])
        print("Bạn: %s" % question)
        print("Bot: %s" % bot.answer(question))
        return
    if "--demo" in args:
        demo_mode(bot)
        return
    if "-h" in args or "--help" in args:
        print(__doc__)
        return
    interactive_mode(bot)


if __name__ == "__main__":
    main()