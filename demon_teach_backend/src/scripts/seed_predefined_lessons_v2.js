const { db } = require('../config/firebase');
require('dotenv').config();

const LESSONS_DATA = [
  // ==================== BEGINNER ====================
  {
    id: "en_beginner_vocabulary_001",
    title: "Topic: Greetings & Introductions (EN)",
    difficulty: "beginner",
    category: "vocabulary",
    topic: "Greetings & Introductions",
    vocab: [
      { word: "Hello", translation: "Xin chào", pronunciation: "/həˈloʊ/", example: "Hello, how are you?", example_translation: "Xin chào, bạn thế nào?" },
      { word: "Good morning", translation: "Chào buổi sáng", pronunciation: "/ɡʊd ˈmɔːrnɪŋ/", example: "Good morning, teacher.", example_translation: "Chào buổi sáng, thưa cô." },
      { word: "My name is...", translation: "Tên của tôi là...", pronunciation: "/maɪ neɪm ɪz/", example: "My name is John.", example_translation: "Tên tôi là John." }
    ],
    quiz: [
      { questionText: "Translate: 'Xin chào'", options: ["Hello", "Goodbye", "Thank you", "Sorry"], correctAnswer: "Hello", explanation: "Hello có nghĩa là Xin chào." },
      { questionText: "Translate: 'Chào buổi sáng'", options: ["Good afternoon", "Good night", "Good morning", "Goodbye"], correctAnswer: "Good morning", explanation: "Good morning có nghĩa là Chào buổi sáng." }
    ],
    listeningText: "Hello, my name is Alice. Nice to meet you.",
    listeningQuestion: "What is the speaker's name?",
    listeningOptions: ["Alice", "Bob", "Charlie", "John"],
    listeningCorrect: "Alice",
    speaking: { phrase: "Nice to meet you", translation: "Rất vui được gặp bạn", pronunciation: "/naɪs tuː miːt juː/" }
  },
  {
    id: "en_beginner_vocabulary_002",
    title: "Topic: Numbers and Time (EN)",
    difficulty: "beginner",
    category: "vocabulary",
    topic: "Numbers and Time",
    vocab: [
      { word: "One hundred", translation: "Một trăm", pronunciation: "/wʌn ˈhʌndrəd/", example: "There are one hundred pages.", example_translation: "Có một trăm trang sách." },
      { word: "Half past", translation: "Rưỡi (giờ)", pronunciation: "/hæf pæst/", example: "It is half past eight.", example_translation: "Bây giờ là tám giờ rưỡi." },
      { word: "O'clock", translation: "Giờ đúng", pronunciation: "/əˈklɑːk/", example: "It is nine o'clock.", example_translation: "Bây giờ là 9 giờ đúng." }
    ],
    quiz: [
      { questionText: "Translate: 'Một trăm'", options: ["Ten", "Fifty", "One hundred", "One thousand"], correctAnswer: "One hundred", explanation: "One hundred là số 100." },
      { questionText: "Translate: '8 giờ rưỡi'", options: ["Eight o'clock", "Half past eight", "Quarter to eight", "Half past nine"], correctAnswer: "Half past eight", explanation: "Half past eight nghĩa là 8 giờ rưỡi." }
    ],
    listeningText: "The train leaves at seven o'clock sharp.",
    listeningQuestion: "What time does the train leave?",
    listeningOptions: ["Seven o'clock", "Eight o'clock", "Six o'clock", "Nine o'clock"],
    listeningCorrect: "Seven o'clock",
    speaking: { phrase: "What time is it?", translation: "Bây giờ là mấy giờ?", pronunciation: "/wʌt taɪm ɪz ɪt/" }
  },
  {
    id: "en_beginner_vocabulary_003",
    title: "Topic: Colors and Clothing (EN)",
    difficulty: "beginner",
    category: "vocabulary",
    topic: "Colors and Clothing",
    vocab: [
      { word: "Blue shirt", translation: "Áo sơ mi xanh", pronunciation: "/bluː ʃɜːrt/", example: "He is wearing a blue shirt.", example_translation: "Anh ấy đang mặc một chiếc áo sơ mi màu xanh." },
      { word: "Red shoes", translation: "Giày màu đỏ", pronunciation: "/red ʃuːz/", example: "She bought red shoes.", example_translation: "Cô ấy đã mua đôi giày màu đỏ." },
      { word: "Black pants", translation: "Quần đen", pronunciation: "/blæk pænts/", example: "I need black pants.", example_translation: "Tôi cần một chiếc quần màu đen." }
    ],
    quiz: [
      { questionText: "Translate: 'Màu đỏ'", options: ["Blue", "Red", "Black", "Yellow"], correctAnswer: "Red", explanation: "Red có nghĩa là Màu đỏ." },
      { questionText: "Translate: 'Áo sơ mi'", options: ["Shoes", "Pants", "Shirt", "Hat"], correctAnswer: "Shirt", explanation: "Shirt là Áo sơ mi." }
    ],
    listeningText: "She wears a yellow hat and blue jeans.",
    listeningQuestion: "What color is her hat?",
    listeningOptions: ["Blue", "Yellow", "Red", "Black"],
    listeningCorrect: "Yellow",
    speaking: { phrase: "I like your red jacket", translation: "Tôi thích chiếc áo khoác đỏ của bạn", pronunciation: "/aɪ laɪk jɔːr red ˈdʒækɪt/" }
  },
  {
    id: "en_beginner_vocabulary_004",
    title: "Topic: Daily Activities & Routines (EN)",
    difficulty: "beginner",
    category: "vocabulary",
    topic: "Daily Activities & Routines",
    vocab: [
      { word: "Get up", translation: "Thức dậy", pronunciation: "/ɡet ʌp/", example: "I get up at six AM.", example_translation: "Tôi thức dậy vào lúc 6 giờ sáng." },
      { word: "Have breakfast", translation: "Ăn sáng", pronunciation: "/həv ˈbrekfəst/", example: "We have breakfast together.", example_translation: "Chúng tôi ăn sáng cùng nhau." },
      { word: "Go to bed", translation: "Đi ngủ", pronunciation: "/ɡoʊ tuː bed/", example: "She goes to bed early.", example_translation: "Cô ấy đi ngủ sớm." }
    ],
    quiz: [
      { questionText: "Translate: 'Thức dậy'", options: ["Go to bed", "Get up", "Eat lunch", "Work"], correctAnswer: "Get up", explanation: "Get up có nghĩa là thức dậy." },
      { questionText: "Translate: 'Ăn sáng'", options: ["Have dinner", "Have lunch", "Have breakfast", "Drink coffee"], correctAnswer: "Have breakfast", explanation: "Have breakfast nghĩa là ăn sáng." }
    ],
    listeningText: "I usually read a book before I go to bed.",
    listeningQuestion: "What does the speaker do before bed?",
    listeningOptions: ["Have breakfast", "Read a book", "Watch TV", "Run"],
    listeningCorrect: "Read a book",
    speaking: { phrase: "I go to work by bus", translation: "Tôi đi làm bằng xe buýt", pronunciation: "/aɪ ɡoʊ tuː wɜːrk baɪ bʌs/" }
  },
  {
    id: "en_beginner_vocabulary_005",
    title: "Topic: Common Foods & Drinks (EN)",
    difficulty: "beginner",
    category: "vocabulary",
    topic: "Common Foods & Drinks",
    vocab: [
      { word: "Bread", translation: "Bánh mì", pronunciation: "/bred/", example: "I eat bread for breakfast.", example_translation: "Tôi ăn bánh mì cho bữa sáng." },
      { word: "Milk", translation: "Sữa", pronunciation: "/mɪlk/", example: "A glass of fresh milk.", example_translation: "Một ly sữa tươi." },
      { word: "Apple", translation: "Quả táo", pronunciation: "/ˈæpl/", example: "An apple is red or green.", example_translation: "Quả táo có màu đỏ hoặc xanh." }
    ],
    quiz: [
      { questionText: "Translate: 'Sữa'", options: ["Milk", "Water", "Tea", "Coffee"], correctAnswer: "Milk", explanation: "Milk có nghĩa là Sữa." },
      { questionText: "Translate: 'Bánh mì'", options: ["Rice", "Bread", "Meat", "Egg"], correctAnswer: "Bread", explanation: "Bread nghĩa là Bánh mì." }
    ],
    listeningText: "I would like to have a hot cup of tea, please.",
    listeningQuestion: "What does the speaker want to drink?",
    listeningOptions: ["Milk", "Water", "Tea", "Coffee"],
    listeningCorrect: "Tea",
    speaking: { phrase: "I drink water every day", translation: "Tôi uống nước mỗi ngày", pronunciation: "/aɪ drɪŋk ˈwɔːtər ˈevri deɪ/" }
  },

  // ==================== ELEMENTARY ====================
  {
    id: "en_elementary_vocabulary_001",
    title: "Topic: Family Members (EN)",
    difficulty: "elementary",
    category: "vocabulary",
    topic: "Family Members",
    vocab: [
      { word: "Father", translation: "Bố/Cha", pronunciation: "/ˈfɑːðər/", example: "My father is a doctor.", example_translation: "Bố tôi là bác sĩ." },
      { word: "Mother", translation: "Mẹ", pronunciation: "/ˈmʌðər/", example: "My mother is very kind.", example_translation: "Mẹ tôi rất hiền lành." },
      { word: "Sister", translation: "Chị/Em gái", pronunciation: "/ˈsɪstər/", example: "I have an elder sister.", example_translation: "Tôi có một người chị gái." }
    ],
    quiz: [
      { questionText: "Translate: 'Mẹ'", options: ["Father", "Mother", "Brother", "Sister"], correctAnswer: "Mother", explanation: "Mother nghĩa là Mẹ." },
      { questionText: "Translate: 'Chị/Em gái'", options: ["Sister", "Brother", "Uncle", "Aunt"], correctAnswer: "Sister", explanation: "Sister nghĩa là Chị/Em gái." }
    ],
    listeningText: "I live with my parents and my two younger brothers.",
    listeningQuestion: "Who does the speaker live with?",
    listeningOptions: ["Parents and brothers", "Friends", "Grandparents", "Alone"],
    listeningCorrect: "Parents and brothers",
    speaking: { phrase: "This is my family", translation: "Đây là gia đình tôi", pronunciation: "/ðɪs ɪz maɪ ˈfæməli/" }
  },
  {
    id: "en_elementary_vocabulary_002",
    title: "Topic: Weather and Seasons (EN)",
    difficulty: "elementary",
    category: "vocabulary",
    topic: "Weather and Seasons",
    vocab: [
      { word: "Sunny", translation: "Có nắng", pronunciation: "/ˈsʌni/", example: "It is a sunny day.", example_translation: "Hôm nay là một ngày nắng." },
      { word: "Winter", translation: "Mùa đông", pronunciation: "/ˈwɪntər/", example: "It snows in winter.", example_translation: "Tuyết rơi vào mùa đông." },
      { word: "Rainy", translation: "Có mưa", pronunciation: "/ˈreɪni/", example: "Don't go out in rainy weather.", example_translation: "Đừng đi ra ngoài trời mưa." }
    ],
    quiz: [
      { questionText: "Translate: 'Mùa đông'", options: ["Spring", "Summer", "Autumn", "Winter"], correctAnswer: "Winter", explanation: "Winter là mùa đông." },
      { questionText: "Translate: 'Có nắng'", options: ["Sunny", "Cloudy", "Rainy", "Windy"], correctAnswer: "Sunny", explanation: "Sunny nghĩa là có nắng." }
    ],
    listeningText: "Autumn is my favorite season because the weather is cool.",
    listeningQuestion: "Why does the speaker like autumn?",
    listeningOptions: ["It is hot", "It is snowy", "It is cool", "It is rainy"],
    listeningCorrect: "It is cool",
    speaking: { phrase: "It is very cold today", translation: "Hôm nay trời rất lạnh", pronunciation: "/ɪt ɪz ˈveri koʊld təˈdeɪ/" }
  },
  {
    id: "en_elementary_vocabulary_003",
    title: "Topic: Hobbies and Leisure (EN)",
    difficulty: "elementary",
    category: "vocabulary",
    topic: "Hobbies and Leisure",
    vocab: [
      { word: "Reading", translation: "Đọc sách", pronunciation: "/ˈriːdɪŋ/", example: "Reading books expands your mind.", example_translation: "Đọc sách mở rộng tâm trí bạn." },
      { word: "Swimming", translation: "Bơi lội", pronunciation: "/ˈswɪmɪŋ/", example: "He goes swimming every Sunday.", example_translation: "Anh ấy đi bơi mỗi Chủ Nhật." },
      { word: "Playing guitar", translation: "Chơi đàn guitar", pronunciation: "/ˈpleɪɪŋ ɡɪˈtɑːr/", example: "She is good at playing guitar.", example_translation: "Cô ấy chơi guitar rất giỏi." }
    ],
    quiz: [
      { questionText: "Translate: 'Bơi lội'", options: ["Running", "Reading", "Swimming", "Cooking"], correctAnswer: "Swimming", explanation: "Swimming nghĩa là bơi lội." },
      { questionText: "Translate: 'Chơi đàn guitar'", options: ["Playing soccer", "Playing guitar", "Singing", "Drawing"], correctAnswer: "Playing guitar", explanation: "Playing guitar là chơi đàn guitar." }
    ],
    listeningText: "I enjoy taking photographs of nature in my free time.",
    listeningQuestion: "What is the speaker's hobby?",
    listeningOptions: ["Taking photos", "Reading", "Swimming", "Singing"],
    listeningCorrect: "Taking photos",
    speaking: { phrase: "My hobby is listening to music", translation: "Sở thích của tôi là nghe nhạc", pronunciation: "/maɪ ˈhɑːbi ɪz ˈlɪsnɪŋ tuː ˈmjuːzɪk/" }
  },
  {
    id: "en_elementary_vocabulary_004",
    title: "Topic: Directions & Places (EN)",
    difficulty: "elementary",
    category: "vocabulary",
    topic: "Directions & Places",
    vocab: [
      { word: "Turn left", translation: "Rẽ trái", pronunciation: "/tɜːrn left/", example: "Turn left at the next corner.", example_translation: "Rẽ trái ở góc tiếp theo." },
      { word: "Hospital", translation: "Bệnh viện", pronunciation: "/ˈhɑːspɪtl/", example: "The hospital is near the park.", example_translation: "Bệnh viện ở gần công viên." },
      { word: "Go straight", translation: "Đi thẳng", pronunciation: "/ɡoʊ streɪt/", example: "Go straight for two blocks.", example_translation: "Đi thẳng qua hai block nhà." }
    ],
    quiz: [
      { questionText: "Translate: 'Bệnh viện'", options: ["School", "Hospital", "Market", "Library"], correctAnswer: "Hospital", explanation: "Hospital là bệnh viện." },
      { questionText: "Translate: 'Rẽ trái'", options: ["Turn right", "Turn left", "Go straight", "Stop"], correctAnswer: "Turn left", explanation: "Turn left nghĩa là rẽ trái." }
    ],
    listeningText: "Excuse me, the post office is right next to the train station.",
    listeningQuestion: "Where is the post office?",
    listeningOptions: ["Next to the train station", "Behind the school", "Far from here", "Next to the park"],
    listeningCorrect: "Next to the train station",
    speaking: { phrase: "How do I get to the supermarket?", translation: "Làm thế nào để đi tới siêu thị?", pronunciation: "/haʊ duː aɪ ɡet tuː ðə ˈsuːpərmɑːrkɪt/" }
  },
  {
    id: "en_elementary_vocabulary_005",
    title: "Topic: Body Parts & Health (EN)",
    difficulty: "elementary",
    category: "vocabulary",
    topic: "Body Parts & Health",
    vocab: [
      { word: "Headache", translation: "Cơn đau đầu", pronunciation: "/ˈhedeɪk/", example: "I have a terrible headache.", example_translation: "Tôi có một cơn đau đầu kinh khủng." },
      { word: "Doctor", translation: "Bác sĩ", pronunciation: "/ˈdɑːktər/", example: "You should see a doctor.", example_translation: "Bạn nên đi gặp bác sĩ." },
      { word: "Medicine", translation: "Thuốc", pronunciation: "/ˈmedsn/", example: "Take this medicine after meals.", example_translation: "Hãy uống thuốc này sau khi ăn." }
    ],
    quiz: [
      { questionText: "Translate: 'Bác sĩ'", options: ["Teacher", "Driver", "Doctor", "Cook"], correctAnswer: "Doctor", explanation: "Doctor nghĩa là bác sĩ." },
      { questionText: "Translate: 'Đau đầu'", options: ["Stomachache", "Headache", "Fever", "Cough"], correctAnswer: "Headache", explanation: "Headache nghĩa là đau đầu." }
    ],
    listeningText: "If you have a high fever, rest and drink lots of water.",
    listeningQuestion: "What should you do if you have a fever?",
    listeningOptions: ["Run outside", "Rest and drink water", "Go to work", "Eat candy"],
    listeningCorrect: "Rest and drink water",
    speaking: { phrase: "I feel sick today", translation: "Hôm nay tôi cảm thấy bị ốm", pronunciation: "/aɪ fiːl sɪk təˈdeɪ/" }
  },

  // ==================== INTERMEDIATE ====================
  {
    id: "en_intermediate_vocabulary_001",
    title: "Topic: Travel Arrangements (EN)",
    difficulty: "intermediate",
    category: "vocabulary",
    topic: "Travel Arrangements",
    vocab: [
      { word: "Reservation", translation: "Sự đặt trước", pronunciation: "/ˌrezərˈveɪʃn/", example: "I made a hotel reservation.", example_translation: "Tôi đã đặt trước khách sạn." },
      { word: "Departure", translation: "Giờ khởi hành", pronunciation: "/dɪˈpɑːrtʃər/", example: "Our departure is at 9 AM.", example_translation: "Giờ khởi hành của chúng tôi là 9 giờ sáng." },
      { word: "Destination", translation: "Điểm đến", pronunciation: "/ˌdestɪˈneɪʃn/", example: "Paris is our final destination.", example_translation: "Paris là điểm đến cuối cùng của chúng tôi." }
    ],
    quiz: [
      { questionText: "Translate: 'Điểm đến'", options: ["Reservation", "Departure", "Destination", "Flight"], correctAnswer: "Destination", explanation: "Destination nghĩa là Điểm đến." },
      { questionText: "Translate: 'Sự đặt trước'", options: ["Booking", "Reservation", "Ticket", "Cancel"], correctAnswer: "Reservation", explanation: "Reservation có nghĩa là Sự đặt trước." }
    ],
    listeningText: "Please confirm your flight departure time twenty-four hours in advance.",
    listeningQuestion: "When should you confirm your flight departure?",
    listeningOptions: ["24 hours in advance", "1 hour before", "At the airport", "One week before"],
    listeningCorrect: "24 hours in advance",
    speaking: { phrase: "Where is the departure gate?", translation: "Cổng khởi hành ở đâu?", pronunciation: "/wer ɪz ðə dɪˈpɑːrtʃər ɡeɪt/" }
  },
  {
    id: "en_intermediate_vocabulary_002",
    title: "Topic: Office & Workplace (EN)",
    difficulty: "intermediate",
    category: "vocabulary",
    topic: "Office & Workplace",
    vocab: [
      { word: "Colleague", translation: "Đồng nghiệp", pronunciation: "/ˈkɑːliːɡ/", example: "He is my colleague at work.", example_translation: "Anh ấy là đồng nghiệp tại chỗ làm của tôi." },
      { word: "Deadline", translation: "Hạn chót", pronunciation: "/ˈdedlaɪn/", example: "The deadline is this Friday.", example_translation: "Hạn chót là thứ sáu tuần này." },
      { word: "Meeting room", translation: "Phòng họp", pronunciation: "/ˈmiːtɪŋ ruːm/", example: "The team is in the meeting room.", example_translation: "Cả đội đang ở trong phòng họp." }
    ],
    quiz: [
      { questionText: "Translate: 'Đồng nghiệp'", options: ["Partner", "Colleague", "Manager", "Boss"], correctAnswer: "Colleague", explanation: "Colleague có nghĩa là đồng nghiệp." },
      { questionText: "Translate: 'Hạn chót'", options: ["Deadline", "Timeline", "Schedule", "Duty"], correctAnswer: "Deadline", explanation: "Deadline nghĩa là hạn chót." }
    ],
    listeningText: "We need to finish the project before the upcoming deadline.",
    listeningQuestion: "What must be finished before the deadline?",
    listeningOptions: ["The project", "The email", "The holiday plan", "The budget"],
    listeningCorrect: "The project",
    speaking: { phrase: "Let's schedule a meeting", translation: "Chúng ta hãy đặt lịch một cuộc họp", pronunciation: "/lets ˈskedʒuːl ə ˈmiːtɪŋ/" }
  },
  {
    id: "en_intermediate_vocabulary_003",
    title: "Topic: Shopping & Money (EN)",
    difficulty: "intermediate",
    category: "vocabulary",
    topic: "Shopping & Money",
    vocab: [
      { word: "Discount", translation: "Khấu trừ / Giảm giá", pronunciation: "/ˈdɪskaʊnt/", example: "Get a 20% discount on clothing.", example_translation: "Được giảm giá 20% cho quần áo." },
      { word: "Receipt", translation: "Biên lai", pronunciation: "/rɪˈsiːt/", example: "Keep your receipt for return.", example_translation: "Giữ lại biên lai của bạn để đổi trả." },
      { word: "Budget", translation: "Ngân sách", pronunciation: "/ˈbʌdʒɪt/", example: "We are on a tight budget.", example_translation: "Chúng tôi đang có một ngân sách eo hẹp." }
    ],
    quiz: [
      { questionText: "Translate: 'Biên lai'", options: ["Receipt", "Bill", "Coin", "Cash"], correctAnswer: "Receipt", explanation: "Receipt là biên lai thanh toán." },
      { questionText: "Translate: 'Giảm giá'", options: ["Tax", "Discount", "Refund", "Charge"], correctAnswer: "Discount", explanation: "Discount nghĩa là giảm giá." }
    ],
    listeningText: "Always ask for a receipt so you can track your spending.",
    listeningQuestion: "Why should you ask for a receipt?",
    listeningOptions: ["To get free food", "To track your spending", "To pay less tax", "To show friends"],
    listeningCorrect: "To track your spending",
    speaking: { phrase: "Can I pay with credit card?", translation: "Tôi có thể thanh toán bằng thẻ tín dụng không?", pronunciation: "/kæn aɪ peɪ wɪð ˈkredɪt kɑːrd/" }
  },
  {
    id: "en_intermediate_vocabulary_004",
    title: "Topic: Technology & Social Media (EN)",
    difficulty: "intermediate",
    category: "vocabulary",
    topic: "Technology & Social Media",
    vocab: [
      { word: "Download", translation: "Tải xuống", pronunciation: "/ˌdaʊnˈloʊd/", example: "Download the file from the link.", example_translation: "Tải xuống file từ đường dẫn." },
      { word: "Account", translation: "Tài khoản", pronunciation: "/əˈkaʊnt/", example: "Set up a new user account.", example_translation: "Thiết lập một tài khoản người dùng mới." },
      { word: "Internet connection", translation: "Kết nối mạng", pronunciation: "/ˈɪntərnet kəˈnekʃn/", example: "I have a slow internet connection.", example_translation: "Tôi có đường truyền internet chậm." }
    ],
    quiz: [
      { questionText: "Translate: 'Tải xuống'", options: ["Upload", "Download", "Delete", "Share"], correctAnswer: "Download", explanation: "Download nghĩa là tải xuống." },
      { questionText: "Translate: 'Tài khoản'", options: ["Profile", "Password", "Account", "Email"], correctAnswer: "Account", explanation: "Account là tài khoản." }
    ],
    listeningText: "You can download our mobile application from the app store.",
    listeningQuestion: "Where can you download the application?",
    listeningOptions: ["From the app store", "From the newspaper", "From TV", "From the radio"],
    listeningCorrect: "From the app store",
    speaking: { phrase: "What is the Wi-Fi password?", translation: "Mật khẩu Wi-Fi là gì?", pronunciation: "/wʌt ɪz ðə ˈwaɪfaɪ ˈpæswɜːrd/" }
  },
  {
    id: "en_intermediate_vocabulary_005",
    title: "Topic: Environment & Nature (EN)",
    difficulty: "intermediate",
    category: "vocabulary",
    topic: "Environment & Nature",
    vocab: [
      { word: "Pollution", translation: "Sự ô nhiễm", pronunciation: "/pəˈluːʃn/", example: "Air pollution is a global issue.", example_translation: "Ô nhiễm không khí là một vấn đề toàn cầu." },
      { word: "Recycle", translation: "Tái chế", pronunciation: "/ˌriːˈsaɪkl/", example: "We should recycle plastic bottles.", example_translation: "Chúng ta nên tái chế các chai nhựa." },
      { word: "Wildlife", translation: "Động vật hoang dã", pronunciation: "/ˈwaɪldlaɪf/", example: "Protecting wildlife is crucial.", example_translation: "Bảo vệ động vật hoang dã là điều tối quan trọng." }
    ],
    quiz: [
      { questionText: "Translate: 'Tái chế'", options: ["Waste", "Pollute", "Recycle", "Burn"], correctAnswer: "Recycle", explanation: "Recycle có nghĩa là tái chế." },
      { questionText: "Translate: 'Sự ô nhiễm'", options: ["Ecology", "Environment", "Pollution", "Climate"], correctAnswer: "Pollution", explanation: "Pollution nghĩa là sự ô nhiễm." }
    ],
    listeningText: "Water pollution harms marine life and clean drinking water.",
    listeningQuestion: "What does water pollution harm?",
    listeningOptions: ["Forests", "Marine life and drinking water", "Desert animals", "Clouds"],
    listeningCorrect: "Marine life and drinking water",
    speaking: { phrase: "We need to save energy", translation: "Chúng ta cần tiết kiệm năng lượng", pronunciation: "/wiː niːd tuː seɪv ˈenərdʒi/" }
  },

  // ==================== UPPER-INTERMEDIATE ====================
  {
    id: "en_upperIntermediate_vocabulary_001",
    title: "Topic: Career Development (EN)",
    difficulty: "upperIntermediate",
    category: "vocabulary",
    topic: "Career Development",
    vocab: [
      { word: "Promotion", translation: "Sự thăng chức", pronunciation: "/prəˈmoʊʃn/", example: "She received a well-deserved promotion.", example_translation: "Cô ấy được thăng chức rất xứng đáng." },
      { word: "Resume", translation: "Sơ yếu lý lịch", pronunciation: "/ˈrezəmeɪ/", example: "Submit your resume to HR.", example_translation: "Nộp sơ yếu lý lịch của bạn cho phòng Nhân sự." },
      { word: "Negotiation", translation: "Sự đàm phán", pronunciation: "/nɪˌɡoʊʃiˈeɪʃn/", example: "Salary negotiation is essential.", example_translation: "Đàm phán lương là việc rất quan trọng." }
    ],
    quiz: [
      { questionText: "Translate: 'Sự đàm phán'", options: ["Promotion", "Resume", "Negotiation", "Interview"], correctAnswer: "Negotiation", explanation: "Negotiation nghĩa là Đàm phán." },
      { questionText: "Translate: 'Sự thăng chức'", options: ["Resignation", "Promotion", "Training", "Recruiting"], correctAnswer: "Promotion", explanation: "Promotion nghĩa là thăng chức." }
    ],
    listeningText: "A strong resume should highlight your achievements rather than just your duties.",
    listeningQuestion: "What should a strong resume highlight?",
    listeningOptions: ["Your age", "Your achievements", "Your hobbies", "Your house address"],
    listeningCorrect: "Your achievements",
    speaking: { phrase: "I would like to negotiate my contract", translation: "Tôi muốn thương lượng hợp đồng của tôi", pronunciation: "/aɪ wʊd laɪk tuː nɪˈɡoʊʃieɪt maɪ ˈkɑːntrækt/" }
  },
  {
    id: "en_upperIntermediate_vocabulary_002",
    title: "Topic: Entrepreneurship & Startups (EN)",
    difficulty: "upperIntermediate",
    category: "vocabulary",
    topic: "Entrepreneurship & Startups",
    vocab: [
      { word: "Funding", translation: "Nguồn vốn tài trợ", pronunciation: "/ˈfʌndɪŋ/", example: "The startup secured seed funding.", example_translation: "Dự án khởi nghiệp đã có nguồn vốn tài trợ hạt giống." },
      { word: "Equity", translation: "Cổ phần sở hữu", pronunciation: "/ˈekwəti/", example: "Founders split equity equally.", example_translation: "Các nhà sáng lập chia đều cổ phần sở hữu." },
      { word: "Product launch", translation: "Sự ra mắt sản phẩm", pronunciation: "/ˈprɑːdʌkt lɔːntʃ/", example: "The product launch is next month.", example_translation: "Sự ra mắt sản phẩm diễn ra vào tháng tới." }
    ],
    quiz: [
      { questionText: "Translate: 'Cổ phần'", options: ["Funding", "Equity", "Debt", "Expense"], correctAnswer: "Equity", explanation: "Equity có nghĩa là cổ phần sở hữu." },
      { questionText: "Translate: 'Nguồn vốn'", options: ["Funding", "Refund", "Leasing", "Taxes"], correctAnswer: "Funding", explanation: "Funding nghĩa là nguồn vốn tài trợ." }
    ],
    listeningText: "Venture capitalists provide capital to startups with high growth potential.",
    listeningQuestion: "Who provides capital to high-growth startups?",
    listeningOptions: ["Venture capitalists", "The government", "Local banks", "Students"],
    listeningCorrect: "Venture capitalists",
    speaking: { phrase: "We need a marketing strategy", translation: "Chúng ta cần một chiến lược tiếp thị", pronunciation: "/wiː niːd ə ˈmɑːrkɪtɪŋ ˈstrætədʒi/" }
  },
  {
    id: "en_upperIntermediate_vocabulary_003",
    title: "Topic: Healthy Lifestyle (EN)",
    difficulty: "upperIntermediate",
    category: "vocabulary",
    topic: "Healthy Lifestyle",
    vocab: [
      { word: "Nutrition", translation: "Dinh dưỡng", pronunciation: "/nuˈtrɪʃn/", example: "Good nutrition is vital for health.", example_translation: "Dinh dưỡng tốt là thiết yếu cho sức khỏe." },
      { word: "Wellness", translation: "Sự khỏe mạnh toàn diện", pronunciation: "/ˈwelnəs/", example: "Corporate wellness programs.", example_translation: "Các chương trình khỏe mạnh toàn diện của công ty." },
      { word: "Organic food", translation: "Thực phẩm hữu cơ", pronunciation: "/ɔːrˈɡænɪk fuːd/", example: "I prefer buying organic food.", example_translation: "Tôi thích mua thực phẩm hữu cơ hơn." }
    ],
    quiz: [
      { questionText: "Translate: 'Dinh dưỡng'", options: ["Diet", "Calorie", "Nutrition", "Sugar"], correctAnswer: "Nutrition", explanation: "Nutrition nghĩa là dinh dưỡng." },
      { questionText: "Translate: 'Hữu cơ'", options: ["Organic", "Chemical", "Processed", "Frozen"], correctAnswer: "Organic", explanation: "Organic nghĩa là hữu cơ." }
    ],
    listeningText: "Regular exercise combined with balanced nutrition boosts mental well-being.",
    listeningQuestion: "What boosts mental well-being besides exercise?",
    listeningOptions: ["Balanced nutrition", "Watching TV", "Fast food", "Sleeping all day"],
    listeningCorrect: "Balanced nutrition",
    speaking: { phrase: "I exercise three times a week", translation: "Tôi tập thể dục ba lần một tuần", pronunciation: "/aɪ ˈeksərsaɪz θriː taɪmz ə wiː/" }
  },
  {
    id: "en_upperIntermediate_vocabulary_004",
    title: "Topic: Arts & Culture (EN)",
    difficulty: "upperIntermediate",
    category: "vocabulary",
    topic: "Arts & Culture",
    vocab: [
      { word: "Exhibition", translation: "Cuộc triển lãm", pronunciation: "/ˌeksɪˈbɪʃn/", example: "We visited an art exhibition.", example_translation: "Chúng tôi đã đi tham quan một triển lãm nghệ thuật." },
      { word: "Masterpiece", translation: "Kiệt tác", pronunciation: "/ˈmæstərpiːs/", example: "Mona Lisa is a masterpiece.", example_translation: "Mona Lisa là một kiệt tác nghệ thuật." },
      { word: "Heritage", translation: "Di sản", pronunciation: "/ˈherɪtɪdʒ/", example: "Preserve our cultural heritage.", example_translation: "Bảo tồn di sản văn hóa của chúng ta." }
    ],
    quiz: [
      { questionText: "Translate: 'Kiệt tác'", options: ["Drawing", "Masterpiece", "Sketch", "Portrait"], correctAnswer: "Masterpiece", explanation: "Masterpiece là kiệt tác nghệ thuật." },
      { questionText: "Translate: 'Triển lãm'", options: ["Exhibition", "Gallery", "Museum", "Theater"], correctAnswer: "Exhibition", explanation: "Exhibition nghĩa là triển lãm." }
    ],
    listeningText: "Museums protect historical artifacts to educate future generations about heritage.",
    listeningQuestion: "Why do museums protect historical artifacts?",
    listeningOptions: ["To sell them", "To educate future generations", "To decorate rooms", "For fun"],
    listeningCorrect: "To educate future generations",
    speaking: { phrase: "This painting is magnificent", translation: "Bức tranh này thật tráng lệ", pronunciation: "/ðɪs ˈpeɪntɪŋ ɪz mæɡˈnɪfɪsnt/" }
  },
  {
    id: "en_upperIntermediate_vocabulary_005",
    title: "Topic: Society & Urban Life (EN)",
    difficulty: "upperIntermediate",
    category: "vocabulary",
    topic: "Society & Urban Life",
    vocab: [
      { word: "Infrastructure", translation: "Cơ sở hạ tầng", pronunciation: "/ˈɪnfrəstrʌktʃər/", example: "The city has modern infrastructure.", example_translation: "Thành phố có cơ sở hạ tầng hiện đại." },
      { word: "Congestion", translation: "Sự tắc nghẽn (giao thông)", pronunciation: "/kənˈdʒestʃən/", example: "Traffic congestion is worsening.", example_translation: "Tắc nghẽn giao thông đang tồi tệ đi." },
      { word: "Diversity", translation: "Sự đa dạng", pronunciation: "/daɪˈvɜːrsəti/", example: "Cultural diversity in classrooms.", example_translation: "Sự đa dạng văn hóa trong lớp học." }
    ],
    quiz: [
      { questionText: "Translate: 'Cơ sở hạ tầng'", options: ["Infrastructure", "Building", "Roadway", "Bridges"], correctAnswer: "Infrastructure", explanation: "Infrastructure nghĩa là cơ sở hạ tầng." },
      { questionText: "Translate: 'Tắc nghẽn'", options: ["Accident", "Highway", "Congestion", "Crowd"], correctAnswer: "Congestion", explanation: "Congestion nghĩa là sự tắc nghẽn." }
    ],
    listeningText: "High traffic congestion in urban cities leads to increased carbon emissions.",
    listeningQuestion: "What does traffic congestion lead to?",
    listeningOptions: ["Clear skies", "Increased carbon emissions", "Cheaper tickets", "Faster travel"],
    listeningCorrect: "Increased carbon emissions",
    speaking: { phrase: "Our community is very supportive", translation: "Cộng đồng của chúng tôi rất tương trợ nhau", pronunciation: "/ˈaʊər kəˈmjuːnəti ɪz ˈveri səˈpɔːrtɪv/" }
  },

  // ==================== ADVANCED ====================
  {
    id: "en_advanced_vocabulary_001",
    title: "Topic: Academic Discourse (EN)",
    difficulty: "advanced",
    category: "vocabulary",
    topic: "Academic Discourse",
    vocab: [
      { word: "Hypothesis", translation: "Giả thuyết", pronunciation: "/haɪˈpɑːθəsɪs/", example: "The researcher formulated a hypothesis.", example_translation: "Nhà nghiên cứu đã thiết lập một giả thuyết." },
      { word: "Methodology", translation: "Phương pháp luận", pronunciation: "/ˌmeθəˈdɑːlədʒi/", example: "The paper revised the research methodology.", example_translation: "Bài báo đã chỉnh sửa phương pháp luận nghiên cứu." },
      { word: "Empirical Evidence", translation: "Bằng chứng thực nghiệm", pronunciation: "/ɪmˈpɪrɪkl ˈevɪdəns/", example: "This theory is backed by empirical evidence.", example_translation: "Lý thuyết này được hỗ trợ bởi bằng chứng thực nghiệm." }
    ],
    quiz: [
      { questionText: "Translate: 'Giả thuyết'", options: ["Hypothesis", "Methodology", "Evidence", "Analysis"], correctAnswer: "Hypothesis", explanation: "Hypothesis nghĩa là giả thuyết." },
      { questionText: "Translate: 'Phương pháp luận'", options: ["Mechanism", "Methodology", "Procedure", "Strategy"], correctAnswer: "Methodology", explanation: "Methodology nghĩa là phương pháp luận." }
    ],
    listeningText: "Without strong empirical evidence, your academic hypothesis remains unproven.",
    listeningQuestion: "What is required to prove an academic hypothesis?",
    listeningOptions: ["Empirical evidence", "A title", "A computer", "Coauthors"],
    listeningCorrect: "Empirical evidence",
    speaking: { phrase: "The research methodology is rigorous", translation: "Phương pháp luận nghiên cứu rất chặt chẽ", pronunciation: "/ðə rɪˈsɜːrtʃ ˌmeθəˈdɑːlədʒi ɪz ˈrɪɡərəs/" }
  },
  {
    id: "en_advanced_vocabulary_002",
    title: "Topic: Business Negotiation (EN)",
    difficulty: "advanced",
    category: "vocabulary",
    topic: "Business Negotiation",
    vocab: [
      { word: "Compromise", translation: "Sự thỏa hiệp", pronunciation: "/ˈkɑːmprəmaɪz/", example: "Both parties reached a compromise.", example_translation: "Cả hai bên đã đi đến một sự thỏa hiệp." },
      { word: "Consensus", translation: "Sự đồng thuận", pronunciation: "/kənˈsensəs/", example: "Building consensus is hard work.", example_translation: "Xây dựng sự đồng thuận là công việc khó khăn." },
      { word: "Leverage", translation: "Thế thế lực / Điểm đòn bẩy", pronunciation: "/ˈlevərɪdʒ/", example: "We have the leverage in this deal.", example_translation: "Chúng tôi có lợi thế đòn bẩy trong thỏa thuận này." }
    ],
    quiz: [
      { questionText: "Translate: 'Thỏa hiệp'", options: ["Conflict", "Compromise", "Clause", "Agreement"], correctAnswer: "Compromise", explanation: "Compromise là sự thỏa hiệp từ cả hai phía." },
      { questionText: "Translate: 'Đồng thuận'", options: ["Consensus", "Dispute", "Argument", "Majority"], correctAnswer: "Consensus", explanation: "Consensus nghĩa là sự đồng thuận chung." }
    ],
    listeningText: "The negotiation was successful because we used our technology patent as leverage.",
    listeningQuestion: "Why was the negotiation successful?",
    listeningOptions: ["They paid cash", "They used a patent as leverage", "They argued loudly", "They walked away"],
    listeningCorrect: "They used a patent as leverage",
    speaking: { phrase: "We need a mutually beneficial agreement", translation: "Chúng ta cần một thỏa thuận đôi bên cùng có lợi", pronunciation: "/wiː niːd ə ˈmjuːtʃuəli ˌbenɪˈfɪʃl əˈɡriːmənt/" }
  },
  {
    id: "en_advanced_vocabulary_003",
    title: "Topic: Medical Ethics & Tech (EN)",
    difficulty: "advanced",
    category: "vocabulary",
    topic: "Medical Ethics & Tech",
    vocab: [
      { word: "Autonomy", translation: "Quyền tự quyết của bệnh nhân", pronunciation: "/ɔːˈtɑːnəmi/", example: "Respect patient autonomy at all times.", example_translation: "Luôn tôn trọng quyền tự quyết của bệnh nhân." },
      { word: "Clinical trial", translation: "Thử nghiệm lâm sàng", pronunciation: "/ˈklɪnɪkl ˈtraɪəl/", example: "The vaccine passed the clinical trial.", example_translation: "Vắc-xin đã vượt qua cuộc thử nghiệm lâm sàng." },
      { word: "Gene editing", translation: "Chỉnh sửa gen", pronunciation: "/dʒiːn ˈedɪtɪŋ/", example: "Ethical debates surrounding gene editing.", example_translation: "Các cuộc tranh luận đạo đức xoay quanh chỉnh sửa gen." }
    ],
    quiz: [
      { questionText: "Translate: 'Quyền tự quyết'", options: ["Authority", "Autonomy", "Freedom", "Consent"], correctAnswer: "Autonomy", explanation: "Autonomy là quyền tự quyết." },
      { questionText: "Translate: 'Thử nghiệm lâm sàng'", options: ["Clinical trial", "Lab test", "Research phase", "Pilot study"], correctAnswer: "Clinical trial", explanation: "Clinical trial nghĩa là thử nghiệm lâm sàng." }
    ],
    listeningText: "Gene editing offers therapeutic solutions but raises profound moral questions.",
    listeningQuestion: "What does gene editing raise besides solutions?",
    listeningOptions: ["Financial gains", "Profound moral questions", "Shorter lifespan", "More diseases"],
    listeningCorrect: "Profound moral questions",
    speaking: { phrase: "Patient confidentiality is absolute", translation: "Bảo mật thông tin bệnh nhân là tuyệt đối", pronunciation: "/ˈpeɪʃnt ˌkɑːnfɪˌdenʃiˈæləti ɪz ˈæbsəluːt/" }
  },
  {
    id: "en_advanced_vocabulary_004",
    title: "Topic: Philosophy & Human Mind (EN)",
    difficulty: "advanced",
    category: "vocabulary",
    topic: "Philosophy & Human Mind",
    vocab: [
      { word: "Consciousness", pronunciation: "/ˈkɑːnʃəsnəs/", translation: "Ý thức / Nhận thức", example: "The nature of human consciousness.", example_translation: "Bản chất ý thức của con người." },
      { word: "Existentialism", pronunciation: "/ˌeɡzɪˈstenʃəlɪzəm/", translation: "Thuyết hiện sinh", example: "Sartre was a major figure in existentialism.", example_translation: "Sartre là một nhân vật lớn trong thuyết hiện sinh." },
      { word: "Perception", pronunciation: "/pərˈsepʃn/", translation: "Sự tri giác / Cảm nhận", example: "Our perception of reality is subjective.", example_translation: "Cảm nhận về thực tế của chúng ta là chủ quan." }
    ],
    quiz: [
      { questionText: "Translate: 'Ý thức'", options: ["Consciousness", "Dreaming", "Thinking", "Intelligence"], correctAnswer: "Consciousness", explanation: "Consciousness nghĩa là ý thức." },
      { questionText: "Translate: 'Thuyết hiện sinh'", options: ["Realism", "Materialism", "Existentialism", "Idealism"], correctAnswer: "Existentialism", explanation: "Existentialism nghĩa là thuyết hiện sinh." }
    ],
    listeningText: "Existentialism argues that individuals are entirely free and responsible for their actions.",
    listeningQuestion: "What does existentialism argue about individuals?",
    listeningOptions: ["They are pre-destined", "They are entirely free and responsible", "They are governed by luck", "They cannot think"],
    listeningCorrect: "They are entirely free and responsible",
    speaking: { phrase: "Reality is shaped by perception", translation: "Thực tại được định hình bởi cảm nhận", pronunciation: "/riˈæləti ɪz ʃeɪpt baɪ pərˈsepʃn/" }
  },
  {
    id: "en_advanced_vocabulary_005",
    title: "Topic: Geopolitics & Trade (EN)",
    difficulty: "advanced",
    category: "vocabulary",
    topic: "Geopolitics & Trade",
    vocab: [
      { word: "Sovereignty", translation: "Chủ quyền quốc gia", pronunciation: "/ˈsɑːvrənti/", example: "Respect the territorial sovereignty.", example_translation: "Tôn trọng chủ quyền lãnh thổ quốc gia." },
      { word: "Treaty", translation: "Hiệp ước / Thỏa thuận quốc tế", pronunciation: "/ˈtriːti/", example: "The trade treaty was signed yesterday.", example_translation: "Hiệp ước thương mại đã được ký hôm qua." },
      { word: "Tariff", translation: "Thuế quan hàng nhập khẩu", pronunciation: "/ˈtærɪf/", example: "Imposing high tariffs on imported goods.", example_translation: "Đánh thuế quan cao lên hàng hóa nhập khẩu." }
    ],
    quiz: [
      { questionText: "Translate: 'Thuế quan'", options: ["Tax", "Tariff", "Fine", "Interest"], correctAnswer: "Tariff", explanation: "Tariff là thuế quan đánh trên hàng hóa nhập khẩu." },
      { questionText: "Translate: 'Hiệp ước'", options: ["Treaty", "Contract", "Pact", "Charter"], correctAnswer: "Treaty", explanation: "Treaty nghĩa là Hiệp ước quốc tế." }
    ],
    listeningText: "The new global trade treaty aims to reduce import tariffs across borders.",
    listeningQuestion: "What does the new trade treaty aim to reduce?",
    listeningOptions: ["Sovereignty", "Import tariffs", "Border security", "Tax rates"],
    listeningCorrect: "Import tariffs",
    speaking: { phrase: "International relations are complex", translation: "Quan hệ quốc tế rất phức tạp", pronunciation: "/ˌɪntərˈnæʃnəl rɪˈleɪʃnz ɑːr kəmˈpleks/" }
  }
];

async function seedPredefinedV2() {
  console.log('🌱 Starting predefined lessons v2 seeding to Firestore...');
  if (!db) {
    console.error('❌ Firestore not initialized.');
    process.exit(1);
  }

  try {
    let successCount = 0;
    for (const raw of LESSONS_DATA) {
      console.log(`⏳ Seeding lesson: ${raw.id} ("${raw.topic}")`);

      // Construct flashcards formatted data
      const flashcards = raw.vocab.map((v, index) => ({
        id: `${raw.id}_fc_${index + 1}`,
        frontText: v.word,
        backText: v.translation,
        phonetic: v.pronunciation,
        example: v.example,
        example_translation: v.example_translation,
        audioUrl: `/api/tts?text=${encodeURIComponent(v.word)}&language=en`
      }));

      // Construct quiz formatted data
      const quizQuestions = raw.quiz.map((q, index) => ({
        id: `${raw.id}_q_${index + 1}`,
        type: "multiple-choice",
        content: {
          questionText: q.questionText,
          options: q.options,
          correctAnswer: q.correctAnswer,
          explanation: q.explanation
        }
      }));

      const quiz = {
        id: `${raw.id}_quiz`,
        title: `${raw.topic} Quiz`,
        questions: quizQuestions
      };

      // Construct listening formatted data
      const listening = {
        id: `${raw.id}_listening`,
        lessonId: raw.id,
        audioUrl: `/api/tts?text=${encodeURIComponent(raw.listeningText)}&language=en`,
        durationSeconds: 15,
        questions: [
          {
            id: `${raw.id}_lq_1`,
            questionText: raw.listeningQuestion,
            options: raw.listeningOptions,
            correctAnswer: raw.listeningCorrect,
            explanation: `Đoạn ghi âm phát âm: "${raw.listeningText}"`
          }
        ]
      };

      // Construct sections formatted data
      const sections = [
        {
          type: "vocabulary",
          items: raw.vocab.map(v => ({
            word: v.word,
            translation: v.translation,
            pronunciation: v.pronunciation,
            audioUrl: `/api/tts?text=${encodeURIComponent(v.word)}&language=en`
          }))
        },
        {
          type: "practice",
          exercises: raw.quiz.map(q => ({
            question: q.questionText,
            options: q.options,
            correctAnswer: q.correctAnswer
          }))
        },
        {
          type: "speaking",
          items: [
            {
              phrase: raw.speaking.phrase,
              translation: raw.speaking.translation,
              pronunciation: raw.speaking.pronunciation,
              audioUrl: `/api/tts?text=${encodeURIComponent(raw.speaking.phrase)}&language=en`
            }
          ]
        }
      ];

      // Form final lesson object matching Firestore structure
      const lessonDocument = {
        id: raw.id,
        title: raw.title,
        difficulty: raw.difficulty,
        category: raw.category,
        topic: raw.topic,
        targetLanguage: "en",
        durationEstimate: 10,
        content: {
          flashcards: flashcards,
          quiz: quiz,
          listening: listening,
          sections: sections
        },
        isPublished: true,
        publishedAt: new Date().toISOString(),
        createdBy: "admin_seed",
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      };

      await db.collection('lessons').doc(raw.id).set(lessonDocument);
      successCount++;
    }

    console.log(`✅ Success! Seeded ${successCount} lessons (5 lessons per level for all 5 levels) into Firestore!`);
    process.exit(0);
  } catch (error) {
    console.error('❌ Failed to seed predefined lessons:', error.message);
    process.exit(1);
  }
}

seedPredefinedV2();
