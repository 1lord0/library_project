import 'dart:math';

import 'db_service.dart';

class SeedService {
  final DbService _db = DbService();
  final Random _random = Random();

  Future<void> seedInitialData() async {
    final usersEmpty = await _db.isTableEmpty('users');
    final booksEmpty = await _db.isTableEmpty('books');
    final salesEmpty = await _db.isTableEmpty('sales');

    if (usersEmpty && booksEmpty && salesEmpty) {
      await _insertDemoData();
      return;
    }

    if (usersEmpty || booksEmpty || salesEmpty) {
      await resetToDemoData();
    }
  }

  Future<void> resetToDemoData() async {
    await _db.clearAllTables();
    await _insertDemoData();
  }

  Future<void> breakSystem() async {
    await _insertJunkBooks();
    await _insertJunkUsers();
    await _insertJunkSales();
  }

  Future<void> _insertDemoData() async {
    final userIds = await _insertDemoUsers();
    final bookIds = await _insertDemoBooks();
    await _insertDemoSales(userIds: userIds, bookIds: bookIds);
  }

  Future<List<int>> _insertDemoUsers() async {
    final ids = <int>[];
    for (final user in _demoUsers) {
      ids.add(await _db.insert('users', user));
    }
    return ids;
  }

  Future<List<int>> _insertDemoBooks() async {
    final ids = <int>[];
    for (final book in _demoBooks) {
      ids.add(await _db.insert('books', book));
    }
    return ids;
  }

  Future<void> _insertDemoSales({
    required List<int> userIds,
    required List<int> bookIds,
  }) async {
    final buyerIds = userIds.skip(1).toList();
    final saleRandom = Random(20260427);
    final now = DateTime.now();
    final monthlySaleCounts = [5, 6, 7, 8, 9, 10];
    final weightedBookIndexes = [
      11,
      11,
      11,
      8,
      8,
      8,
      0,
      0,
      5,
      5,
      16,
      16,
      13,
      4,
      2,
      7,
      9,
      17,
      1,
      12,
    ];

    for (
      int monthIndex = 0;
      monthIndex < monthlySaleCounts.length;
      monthIndex++
    ) {
      final monthOffset = monthlySaleCounts.length - monthIndex - 1;
      final saleCount = monthlySaleCounts[monthIndex];

      for (int i = 0; i < saleCount; i++) {
        final bookIndex =
            weightedBookIndexes[saleRandom.nextInt(weightedBookIndexes.length)];
        final quantityBias = bookIndex == 11 || bookIndex == 8 || bookIndex == 5
            ? 2
            : 1;
        final quantity = quantityBias + saleRandom.nextInt(2);
        final price = (_demoBooks[bookIndex]['price'] as num).toDouble();

        await _db.insert('sales', {
          'user_id': buyerIds[saleRandom.nextInt(buyerIds.length)],
          'book_id': bookIds[bookIndex],
          'quantity': quantity,
          'total_price': price * quantity,
          'sale_date': _randomDateInMonth(
            now,
            monthOffset,
            saleRandom,
          ).toIso8601String(),
        });
      }
    }
  }

  DateTime _randomDateInMonth(DateTime now, int monthOffset, Random random) {
    final monthBase = DateTime(now.year, now.month - monthOffset, 1, 11);
    final day = 1 + random.nextInt(25);
    final hour = 10 + random.nextInt(9);
    final minute = random.nextInt(60);
    return DateTime(monthBase.year, monthBase.month, day, hour, minute);
  }

  Future<void> _insertJunkBooks() async {
    for (final book in _junkBooks) {
      await _db.insert('books', book);
    }
  }

  Future<void> _insertJunkUsers() async {
    for (final user in _junkUsers) {
      await _db.insert('users', user);
    }
  }

  Future<void> _insertJunkSales() async {
    final users = await _db.query('users');
    final books = await _db.query('books');

    if (users.isEmpty || books.isEmpty) return;

    final userIds = users.map((user) => user['id'] as int).toList();
    final bookEntries = books
        .map(
          (book) => {
            'id': book['id'] as int,
            'price': (book['price'] as num).toDouble(),
          },
        )
        .toList();

    final now = DateTime.now();

    for (int i = 0; i < 40; i++) {
      final daysAgo = _random.nextInt(30);
      final date = now.subtract(Duration(days: daysAgo));
      final bookEntry = bookEntries[_random.nextInt(bookEntries.length)];
      final quantity = _random.nextInt(10) + 1;

      await _db.insert('sales', {
        'user_id': userIds[_random.nextInt(userIds.length)],
        'book_id': bookEntry['id'],
        'quantity': quantity,
        'total_price': (bookEntry['price'] as double) * quantity,
        'sale_date': date.toIso8601String(),
      });
    }
  }

  static const List<Map<String, dynamic>> _demoUsers = [
    {
      'name': 'Admin Kullanici',
      'email': 'admin@kutuphane.com',
      'password': 'admin123',
      'role': 'admin',
    },
    {
      'name': 'Ahmet Yilmaz',
      'email': 'user@kutuphane.com',
      'password': 'user123',
      'role': 'user',
    },
    {
      'name': 'Elif Demir',
      'email': 'elif@kutuphane.com',
      'password': 'elif123',
      'role': 'user',
    },
    {
      'name': 'Zeynep Kaya',
      'email': 'zeynep@kutuphane.com',
      'password': 'zeynep123',
      'role': 'user',
    },
    {
      'name': 'Mert Arslan',
      'email': 'mert@kutuphane.com',
      'password': 'mert123',
      'role': 'user',
    },
  ];

  static const List<Map<String, dynamic>> _demoBooks = [
    {
      'title': 'Suc ve Ceza',
      'author': 'Fyodor Dostoyevski',
      'category': 'Roman',
      'price': 45.0,
      'stock': 12,
      'description': 'Rus edebiyatinin en bilinen klasiklerinden biri.',
      'image_url': 'https://covers.openlibrary.org/b/isbn/9780140449136-L.jpg',
    },
    {
      'title': 'Simyaci',
      'author': 'Paulo Coelho',
      'category': 'Roman',
      'price': 35.0,
      'stock': 20,
      'description': 'Kisisel efsanesinin pesine dusen bir cobanin yolculugu.',
      'image_url': 'https://covers.openlibrary.org/b/isbn/9780062315007-L.jpg',
    },
    {
      'title': 'Ince Memed',
      'author': 'Yasar Kemal',
      'category': 'Roman',
      'price': 40.0,
      'stock': 8,
      'description':
          'Anadolu gercekligini guclu bir dille anlatan klasik roman.',
      'image_url': 'https://covers.openlibrary.org/b/isbn/9780099530343-L.jpg',
    },
    {
      'title': 'Tutunamayanlar',
      'author': 'Oguz Atay',
      'category': 'Roman',
      'price': 55.0,
      'stock': 6,
      'description': 'Modern Turk edebiyatinin onemli eserlerinden biri.',
      'image_url': 'https://covers.openlibrary.org/b/isbn/9789750502545-L.jpg',
    },
    {
      'title': 'Kurk Mantolu Madonna',
      'author': 'Sabahattin Ali',
      'category': 'Roman',
      'price': 30.0,
      'stock': 15,
      'description': 'Aski ve yalnizligi merkeze alan guclu bir klasik.',
      'image_url': 'https://covers.openlibrary.org/b/isbn/9786051850580-L.jpg',
    },
    {
      'title': '1984',
      'author': 'George Orwell',
      'category': 'Bilim Kurgu',
      'price': 38.0,
      'stock': 10,
      'description': 'Totaliter duzeni anlatan zamansiz bir distopya.',
      'image_url': 'https://covers.openlibrary.org/b/isbn/9780451524935-L.jpg',
    },
    {
      'title': 'Cesur Yeni Dunya',
      'author': 'Aldous Huxley',
      'category': 'Bilim Kurgu',
      'price': 42.0,
      'stock': 7,
      'description':
          'Teknoloji ile bicimlenen bir toplum uzerine klasik roman.',
      'image_url': 'https://covers.openlibrary.org/b/isbn/9780060850524-L.jpg',
    },
    {
      'title': 'Dune',
      'author': 'Frank Herbert',
      'category': 'Bilim Kurgu',
      'price': 50.0,
      'stock': 5,
      'description':
          'Siyaset, ekoloji ve guc savaslarini birlestiren epik kurgu.',
      'image_url': 'https://covers.openlibrary.org/b/isbn/9780441172719-L.jpg',
    },
    {
      'title': 'Sapiens',
      'author': 'Yuval Noah Harari',
      'category': 'Tarih',
      'price': 60.0,
      'stock': 14,
      'description':
          'Insanlik tarihine genis bir cerceveden bakan populer eser.',
      'image_url': 'https://covers.openlibrary.org/b/isbn/9780062316097-L.jpg',
    },
    {
      'title': 'Nutuk',
      'author': 'Mustafa Kemal Ataturk',
      'category': 'Tarih',
      'price': 25.0,
      'stock': 30,
      'description': 'Cumhuriyetin kurulus surecini belgeleyen temel eser.',
      'image_url': 'https://covers.openlibrary.org/b/isbn/9789944888349-L.jpg',
    },
    {
      'title': 'Osmanli Imparatorlugu',
      'author': 'Halil Inalcik',
      'category': 'Tarih',
      'price': 68.0,
      'stock': 5,
      'description': 'Osmanli tarihine giris icin guvenilir bir kaynak.',
      'image_url': 'https://covers.openlibrary.org/b/isbn/9786051416526-L.jpg',
    },
    {
      'title': 'Atomik Aliskanliklar',
      'author': 'James Clear',
      'category': 'Kisisel Gelisim',
      'price': 48.0,
      'stock': 18,
      'description':
          'Kucuk aliskanliklarin buyuk sonuclara donusmesini anlatir.',
      'image_url': 'https://covers.openlibrary.org/b/isbn/9780735211292-L.jpg',
    },
    {
      'title': 'Ikigai',
      'author': 'Hector Garcia',
      'category': 'Kisisel Gelisim',
      'price': 36.0,
      'stock': 22,
      'description': 'Uzun ve anlamli yasama dair Japon yaklasimini ozetler.',
      'image_url': 'https://covers.openlibrary.org/b/isbn/9780143130727-L.jpg',
    },
    {
      'title': 'Sofinin Dunyasi',
      'author': 'Jostein Gaarder',
      'category': 'Felsefe',
      'price': 44.0,
      'stock': 9,
      'description': 'Felsefe tarihini roman akisi icinde sunan populer eser.',
      'image_url': 'https://covers.openlibrary.org/b/isbn/9780374530716-L.jpg',
    },
    {
      'title': 'Yabanci',
      'author': 'Albert Camus',
      'category': 'Felsefe',
      'price': 28.0,
      'stock': 11,
      'description': 'Varoluscu duyguyu kisa ama etkili bir dille verir.',
      'image_url': 'https://covers.openlibrary.org/b/isbn/9780679720201-L.jpg',
    },
    {
      'title': 'Seyir Defteri',
      'author': 'Turgut Uyar',
      'category': 'Siir',
      'price': 32.0,
      'stock': 6,
      'description': 'Ikinci Yeni siirinin onemli kitaplarindan biridir.',
      'image_url': 'https://covers.openlibrary.org/b/isbn/9789750719387-L.jpg',
    },
    {
      'title': 'Kozmos',
      'author': 'Carl Sagan',
      'category': 'Bilim',
      'price': 55.0,
      'stock': 8,
      'description': 'Evrene dair meraki artiran populer bilim klasigi.',
      'image_url': 'https://covers.openlibrary.org/b/isbn/9780345539434-L.jpg',
    },
    {
      'title': 'Kisa Zamanin Tarihi',
      'author': 'Stephen Hawking',
      'category': 'Bilim',
      'price': 46.0,
      'stock': 10,
      'description': 'Evrenin temel sorularina sade bir dille yaklasir.',
      'image_url': 'https://covers.openlibrary.org/b/isbn/9780553380163-L.jpg',
    },
  ];

  static const List<Map<String, dynamic>> _junkBooks = [
    {
      'title': 'asdfghjkl',
      'author': 'Test Test',
      'category': 'Belirsiz',
      'price': 99999.99,
      'stock': 0,
      'description': 'Ne oldugu belli olmayan test kaydi.',
    },
    {
      'title': 'Bos Kitap 1',
      'author': '',
      'category': 'Yok',
      'price': 0.01,
      'stock': 9999,
      'description': '',
    },
    {
      'title': 'AAAAAAA',
      'author': 'BBBBBBB',
      'category': 'CCCCCC',
      'price': 1234567.0,
      'stock': -5,
      'description': 'Negatif stoklu sacma kayit.',
    },
    {
      'title': 'Free Book',
      'author': 'Nobody',
      'category': 'Free',
      'price': 0.0,
      'stock': 1,
      'description': 'Bedava ama anlamsiz.',
    },
    {
      'title': 'Emoji Curcunasi',
      'author': 'Garip Hesap',
      'category': 'Emoji',
      'price': 666.66,
      'stock': 13,
      'description': 'Sadece gosteris icin eklenmis bir kayit.',
    },
    {
      'title': 'Kitap Kitap Kitap Kitap Kitap Kitap',
      'author': 'Yazar Yazar Yazar',
      'category': 'Tekrar',
      'price': 11.11,
      'stock': 111,
      'description': 'Ayni kelimelerin tekrarindan olusan veri.',
    },
    {
      'title': 'NULL',
      'author': 'undefined',
      'category': 'NaN',
      'price': -50.0,
      'stock': 0,
      'description': 'Programci sakasi gibi duran kayit.',
    },
    {
      'title': 'Cok Pahali Kitap',
      'author': 'Zengin Yazar',
      'category': 'Luks',
      'price': 50000.0,
      'stock': 1,
      'description': 'Altin kapli oldugu iddia ediliyor.',
    },
    {
      'title': 'x',
      'author': 'y',
      'category': 'z',
      'price': 0.001,
      'stock': 5,
      'description': 'Asiri minimal veri.',
    },
    {
      'title': 'Drop Table Books',
      'author': 'Hacker',
      'category': 'SQL',
      'price': 42.0,
      'stock': 1,
      'description': 'Sadece dikkat dagitmak icin eklenmis ad.',
    },
    {
      'title': 'Stoksuz Kitap 1',
      'author': 'Stok Yok',
      'category': 'Bos',
      'price': 25.0,
      'stock': 0,
      'description': 'Hic stok yok.',
    },
    {
      'title': 'Stoksuz Kitap 2',
      'author': 'Stok Yok',
      'category': 'Bos',
      'price': 30.0,
      'stock': 0,
      'description': 'Bu da tamamen tukenmis.',
    },
    {
      'title': '1',
      'author': '2',
      'category': '3',
      'price': 4.0,
      'stock': 5,
      'description': 'Sayi dolu test kaydi.',
    },
    {
      'title': 'Lorem Ipsum Dolor Sit Amet',
      'author': 'Cicero',
      'category': 'Latince',
      'price': 999.0,
      'stock': 3,
      'description': 'Placeholder metinden olusan urun.',
    },
    {
      'title': 'Test Kitabi Final v2 KOPYA (1)',
      'author': 'Ogrenci',
      'category': 'Test',
      'price': 15.0,
      'stock': 50,
      'description': 'Kopya dosya gibi duran sacma kayit.',
    },
    {
      'title': 'Bitmemis Roman',
      'author': 'Tembel Yazar',
      'category': 'Roman',
      'price': 88.0,
      'stock': 2,
      'description': 'Devami hic gelmeyecek gibi gorunuyor.',
    },
    {
      'title': '...',
      'author': '...',
      'category': '...',
      'price': 0.0,
      'stock': 0,
      'description': 'Tam anlamiyla eksik veri.',
    },
    {
      'title': 'Galaksi Rehberi 99',
      'author': 'Uzayli',
      'category': 'Bilim Kurgu',
      'price': 424242.0,
      'stock': 42,
      'description': 'Gercekten gereksiz pahali bir kitap.',
    },
    {
      'title': 'Kopek Kitabi',
      'author': 'Hav Hav',
      'category': 'Hayvan',
      'price': 19.99,
      'stock': 7,
      'description': 'Tamamen rastgele secilmis bir urun.',
    },
    {
      'title': 'CAPS LOCK KITAP',
      'author': 'BUYUK HARF YAZAR',
      'category': 'KATEGORI',
      'price': 55.55,
      'stock': 55,
      'description': 'Her seyi buyuk harfle yazilmis kayit.',
    },
    {
      'title': 'Gelecekten Gelen Kitap',
      'author': 'Zaman Yolcusu',
      'category': 'Bilim Kurgu',
      'price': 2077.0,
      'stock': 1,
      'description': 'Fiyat mantigi tamamen kopmus bir kayit.',
    },
    {
      'title': 'Bosluk Koleksiyonu',
      'author': 'Adsiz',
      'category': 'Bosluk',
      'price': 10.0,
      'stock': 10,
      'description': 'Gorunuse gore gereksiz bir urun.',
    },
    {
      'title': 'Fotokopi Kitap',
      'author': 'Korsan',
      'category': 'Korsan',
      'price': 3.0,
      'stock': 500,
      'description': 'Kacak baski gibi duran supheli veri.',
    },
    {
      'title': 'Muzik Kitabi Remix',
      'author': 'DJ Yazar',
      'category': 'Muzik',
      'price': 77.77,
      'stock': 7,
      'description': 'Sisteme sadece gosteri icin atilmis.',
    },
    {
      'title': 'Sonsuz Stoklu Kitap',
      'author': 'Sihirbaz',
      'category': 'Fantastik',
      'price': 33.0,
      'stock': 999999,
      'description': 'Bitmesi imkansiz gibi duran stok.',
    },
    {
      'title': 'Bir Kurusluk Kitap',
      'author': 'Fakir Yazar',
      'category': 'Ekonomi',
      'price': 0.01,
      'stock': 1,
      'description': 'Asiri ucuz sacma veri.',
    },
    {
      'title': 'Yarim Kalmis',
      'author': 'Yarim Ya',
      'category': 'Roman',
      'price': 22.5,
      'stock': 3,
      'description': 'Devami belirsiz bir urun.',
    },
    {
      'title': 'Robot Yazdi Bu Kitabi',
      'author': 'ChatGPT',
      'category': 'Yapay Zeka',
      'price': 101.0,
      'stock': 404,
      'description': 'Sunumda dikkat cekmek icin eklenmis veri.',
    },
    {
      'title': 'Kayip Sayfa',
      'author': 'Gizemli',
      'category': 'Gizem',
      'price': 13.13,
      'stock': 13,
      'description': 'Nedense 13 etrafinda dolasan bir kitap.',
    },
    {
      'title': 'Uyku Kitabi',
      'author': 'Uykucu',
      'category': 'Saglik',
      'price': 29.9,
      'stock': 8,
      'description': 'Okurken uyutmasi beklenen sacma urun.',
    },
  ];

  static const List<Map<String, dynamic>> _junkUsers = [
    {
      'name': 'Test1',
      'email': 'test1@test.com',
      'password': '123',
      'role': 'user',
    },
    {
      'name': 'Test2',
      'email': 'test2@test.com',
      'password': '123',
      'role': 'user',
    },
    {
      'name': 'ASDF',
      'email': 'asdf@asdf.com',
      'password': 'asdf',
      'role': 'user',
    },
    {
      'name': 'Fake Admin',
      'email': 'fake@admin.com',
      'password': 'hack',
      'role': 'user',
    },
    {
      'name': 'Ghost User',
      'email': 'ghost@yok.com',
      'password': 'boo',
      'role': 'user',
    },
    {
      'name': 'Bos Kullanici',
      'email': 'bos@bos.com',
      'password': '000',
      'role': 'user',
    },
    {'name': 'x', 'email': 'x@x.com', 'password': 'x', 'role': 'user'},
    {
      'name': 'Drop Table Users',
      'email': 'hacker@sql.com',
      'password': 'inject',
      'role': 'user',
    },
    {
      'name': 'Uzun Isimli Kullanici Denemesi',
      'email': 'uzun@isim.com',
      'password': 'uzun123',
      'role': 'user',
    },
    {
      'name': 'Space User',
      'email': 'space@space.com',
      'password': 'space',
      'role': 'user',
    },
  ];
}
