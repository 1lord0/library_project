# Kutuphane Yonetim Sistemi

Flutter + SQLite ile gelistirilmis, tam lokal calisan kutuphane ve mini kitap satis yonetim uygulamasi.

## Proje Kapsami

- Admin ve kullanici rolleri
- SQLite tabanli lokal veritabani
- Demo seed verisi ve tek tusla reset sistemi
- Kitap listeleme, detay, arama ve kategori filtreleme
- Sepet ve satin alma akisi
- Admin kitap CRUD ekrani
- Dashboard istatistikleri, son satislar ve aylik ozet
- Sunum icin "Sistemi Boz" ve "Demo Verilerine Sifirla" paneli

## Gereksinimler

- Flutter SDK 3.11 veya uzeri
- Dart SDK 3.11 veya uzeri
- Android Studio veya VS Code
- Android emulator, fiziksel cihaz veya Windows desktop

## Kurulum ve Calistirma

```bash
cd library_project
flutter pub get
flutter run
```

Belirli hedefler icin:

```bash
flutter run -d android
flutter run -d windows
```

Windows desktop acik degilse:

```bash
flutter config --enable-windows-desktop
flutter run -d windows
```

## Demo Hesaplari

| Rol | E-posta | Sifre |
|---|---|---|
| Admin | `admin@kutuphane.com` | `admin123` |
| Kullanici | `user@kutuphane.com` | `user123` |

Login ekranindaki demo hesap kartlarina tiklayarak alanlari otomatik doldurabilirsiniz.

## Demo Reset Kullanimi

1. Admin hesabi ile giris yapin.
2. Dashboard ekranindan `Demo Kontrol Paneli` ekranina gidin.
3. `Sistemi Boz` ile test verileri ekleyin.
4. Dashboard ve kitap listesindeki degisimi gosterin.
5. `Demo Verilerine Sifirla` ile sistemi temiz demo haline geri getirin.

## Sunum Icin Onerilen Senaryo

1. Uygulamayi acin.
2. Admin ile giris yapin.
3. Dashboard kartlarini ve son satislari gosterin.
4. Kitap Yonetimi ekraninda bir kitabi duzenleyin veya sacma fiyat girin.
5. Demo Kontrol Paneli ekraninda `Sistemi Boz` butonuna basin.
6. Tekrar dashboard'a donup verilerin bozuldugunu gosterin.
7. `Demo Verilerine Sifirla` ile tum sistemi temiz demo haline getirin.
8. Isterseniz reset oncesi eklenen sahte kullanicilarin artik sisteme giremedigini de gosterebilirsiniz.

## Proje Yapisi

```text
lib/
  constants/   Tema, renkler ve sabit metinler
  models/      Book, User, Sale, CartItem modelleri
  screens/     Login, dashboard, kitap, sepet ve reset ekranlari
  services/    DB, auth, seed, cart, book ve sale servisleri
  widgets/     Ortak kartlar ve UI durum bilesenleri
  main.dart    Uygulama giris noktasi
```

## Mimari Tasarim

Detayli dokuman: [ARCHITECTURE.md](ARCHITECTURE.md)

### Katmanli Yapi

```
Presentation (Screens, Widgets)
        |
  Service Layer (AuthService, BookService, CartService, SaleService, SeedService)
        |
  Data Layer (DbService - SQLite Singleton)
```

- Ekranlar dogrudan veritabanina erismez; tum islemler servis katmanindan gecer.
- DbService degisirse (ornegin REST API'ye gecis) servis ve UI katmani etkilenmez.

### Mikroservis Perspektifi

Sistem buyuk olcege tasindigi senaryoda su servislere ayrilir:

```
          +-------------+
          | API Gateway  |
          +------+------+
                 |
   +------+------+------+------+
   |      |      |      |      |
 Auth   Book   Order  Report  Notification
Service Service Service Service Service
```

- **API Gateway**: Tek giris noktasi; routing, JWT dogrulama, rate limiting.
- **Senkron iletisim**: Kullanici istekleri HTTP/REST ile servis-servis arasinda iletilir.
- **Asenkron iletisim**: Checkout sonrasi stok guncelleme, bildirim gonderme gibi islemler event bus (RabbitMQ/Kafka) uzerinden yapilir; servisler birbirini beklemez.

### Olceklenebilirlik

- Her mikroservis bagimsiz yatay olceklenir (Load Balancer arkasinda N instance).
- Mevcut SQLite, uretimde PostgreSQL + read replica ile degistirilir.
- Stateless servis tasarimi container (Docker/K8s) ortamina uygundur.

## Test ve Kontrol

Asagidaki komutlarla temel kalite kontrolu yapabilirsiniz:

```bash
flutter analyze
flutter test
```

Android emulator ve Windows desktop hedeflerinde manuel kontrol onerilir:

- Login akisi
- Admin dashboard
- Kitap CRUD
- Sepet ve satin alma
- Demo reset paneli

## Teslim Notu

Teslim etmeden once su klasorleri zip dosyasina dahil etmemeniz daha temiz olur:

- `.dart_tool/`
- `build/`

Gerekli dosyalar:

- `lib/`
- `android/`
- `ios/`
- `windows/`
- `pubspec.yaml`
- `pubspec.lock`
- `README.md`
