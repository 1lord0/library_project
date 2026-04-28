# Mimari Tasarim Dokumani

## 1. Genel Bakis

Kutuphane Yonetim Sistemi, Flutter (UI) + SQLite (lokal veritabani) uzerine kurulu bir kitap satis uygulamasidir. Uygulama su anda monolitik bir mobil/desktop istemci olarak calisir; ancak tasarimi ileride mikroservis mimarisine gecisi kolaylastiracak sekilde katmanli olarak ayrilmistir.

## 2. Katmanli Mimari (Layered Architecture)

```
+------------------------------------------------------+
|                  PRESENTATION LAYER                   |
|  Screens (Login, Dashboard, Cart, BookDetail, ...)    |
|  Widgets (BookCard, BookCover, AppHeroPanel, ...)     |
+------------------------------------------------------+
                         |
                         v
+------------------------------------------------------+
|                   SERVICE LAYER                       |
|  AuthService    - Kimlik dogrulama ve oturum yonetimi |
|  BookService    - Kitap CRUD ve arama islemleri       |
|  CartService    - Sepet yonetimi ve checkout          |
|  SaleService    - Satis istatistikleri ve raporlar    |
|  UserService    - Kullanici yonetimi                  |
|  SeedService    - Demo veri yukleme ve reset          |
+------------------------------------------------------+
                         |
                         v
+------------------------------------------------------+
|                    DATA LAYER                         |
|  DbService (Singleton)                                |
|  - SQLite baglantisi                                  |
|  - Tablo olusturma (users, books, sales, cart_items)  |
|  - Genel CRUD helper fonksiyonlari                    |
+------------------------------------------------------+
```

**Neden katmanli?**
- Presentation layer hicbir zaman dogrudan veritabanina erismez.
- Service layer is mantigi tasir; UI'dan ve veri kaynagindan bagimsizdir.
- Data layer degisirse (ornegin SQLite yerine REST API), yalnizca DbService degisir; service ve presentation katmanlari etkilenmez.

## 3. Mikroservis Perspektifi

Eger bu sistem buyuk olcekli bir uretim ortamina tasinsaydi, su sekilde mikroservislere ayrilabilirdi:

```
                    +-------------------+
                    |   API GATEWAY     |
                    | (Tek Giris Noktasi)|
                    +--------+----------+
                             |
         +-------------------+-------------------+
         |           |           |               |
    +----v----+ +----v----+ +----v----+   +------v------+
    |  Auth   | |  Book   | |  Order  |   |   Report    |
    | Service | | Service | | Service |   |   Service   |
    +---------+ +---------+ +---------+   +-------------+
    | Users   | | Books   | | Cart    |   | Sales Stats |
    | Login   | | Search  | | Sales   |   | Monthly     |
    | Register| | CRUD    | | Checkout|   | Top Books   |
    +---------+ +---------+ +---------+   +-------------+
         |           |           |               |
    +----v-----------v-----------v---------------v----+
    |              VERITABANI KATMANI                   |
    |  (Her servis kendi DB'sine sahip olabilir veya    |
    |   paylasimli bir DB kullanilabilir)                |
    +--------------------------------------------------+
```

### Servis Sorumluluk Haritalari

| Mikroservis     | Sorumluluk                                     | Mevcut Karsilik        |
|-----------------|------------------------------------------------|------------------------|
| Auth Service    | Login, register, token yonetimi, rol kontrolu  | AuthService + UserService |
| Book Service    | Kitap CRUD, arama, kategori filtreleme, stok    | BookService            |
| Order Service   | Sepet yonetimi, checkout, satis kaydi           | CartService + SaleService |
| Report Service  | Dashboard istatistikleri, aylik ozet, top kitaplar | SaleService (rapor kismi) |

### API Gateway Konsepti

API Gateway, tum istemci isteklerinin gectigi tek giris noktasidir:

- **Routing**: `/api/auth/*` -> Auth Service, `/api/books/*` -> Book Service, vb.
- **Authentication**: Her istekte JWT token dogrulamasi yapilir.
- **Rate Limiting**: Kotu niyetli veya asiri istekleri sinirlar.
- **Load Balancing**: Ayni servisin birden fazla instance'ina istekleri dagitir.

Mevcut uygulamada `DbService` singleton'i, tum servislerin tek bir veritabanina eristigi basit bir gateway gorevi gorur.

## 4. Senkron ve Asenkron Iletisim

### Senkron (Synchronous) Iletisim
Mevcut durumda tum islemler senkron (istek-yanit) modelindedir:
- Kullanici sepete kitap ekler -> CartService hemen DB'ye yazar -> UI guncellenir
- Admin kitap duzenler -> BookService hemen gunceller -> Liste yenilenir

Mikroservis ortaminda bu HTTP/REST veya gRPC uzerinden olur.

### Asenkron (Asynchronous) Iletisim
Buyuk olcekli sistemlerde su senaryolar asenkron olurdu:

```
Kullanici checkout yapar
        |
        v
  Order Service (satis kaydeder)
        |
        +---> [Message Queue / Event Bus]
                    |
                    +---> Book Service (stok guncelle)
                    +---> Report Service (istatistik guncelle)
                    +---> Notification Service (e-posta gonder)
```

Avantajlari:
- Servisler birbirini beklemez (loose coupling)
- Bir servis cokerse diger servisler etkilenmez
- Event-driven mimari sayesinde yeni servisler kolayca eklenebilir

Mevcut uygulamada `CartService.checkout()` metodu transaction icinde hem satis kaydeder hem stok gunceller. Bu monolitik yaklasim kucuk olcekte dogrudur ancak buyuk olcekte asenkron event'lara donusturulmelidir.

## 5. Olceklenebilirlik (Scalability)

### Yatay Olcekleme (Horizontal Scaling)
```
                   +------------------+
                   |  Load Balancer   |
                   +--------+---------+
                            |
              +-------------+-------------+
              |             |             |
        +-----v---+  +-----v---+  +-----v---+
        | App      |  | App      |  | App      |
        | Instance |  | Instance |  | Instance |
        | #1       |  | #2       |  | #3       |
        +----------+  +----------+  +----------+
```

- Her mikroservis bagimsiz olceklenir (Book Service yogun ise sadece o artirilir)
- Load balancer istekleri instance'lar arasinda dagitir
- Stateless servisler yatay olceklemeyi kolaylastirir

### Dikey Olcekleme (Vertical Scaling)
- Mevcut SQLite yaklasimi tek makinede calisir
- Uretim ortaminda PostgreSQL/MySQL gibi bir RDBMS'e gecis gerekir
- Okuma yogun senaryolarda read replica eklenebilir

## 6. Mevcut Durum ve Gelecek Plani

| Ozellik                | Mevcut Durum         | Hedef                          |
|------------------------|----------------------|--------------------------------|
| Veri Katmani           | SQLite (lokal)       | PostgreSQL + REST API          |
| Kimlik Dogrulama       | Plain text sifre     | JWT + bcrypt hash              |
| Servis Iletisimi       | Dogrudan fonksiyon   | HTTP/REST veya gRPC            |
| Asenkron Islemler      | Yok                  | RabbitMQ / Kafka event bus     |
| Olcekleme              | Tek cihaz            | Docker + Kubernetes            |
| API Gateway            | DbService singleton  | Kong / Nginx API Gateway       |
| Izleme (Monitoring)    | Yok                  | Prometheus + Grafana           |

## 7. Tasarim Kararlari

1. **Provider (State Management)**: AuthService ChangeNotifier ile dinlenir. Hafif ve Flutter ekosisteminde standart.
2. **Singleton DbService**: Tek veritabani baglantisi garanti edilir; gereksiz connection acilmasi onlenir.
3. **Transaction-Based Checkout**: Satis + stok guncelleme atomik olarak yapilir; yarim kalmis islem olmaz.
4. **SeedService Ayri Tutuldu**: Demo veri mantigi is mantigi servislerinden ayrildi; tek sorumluluk prensibi.
5. **Responsive Layout**: LayoutBuilder + ConstrainedBox ile mobil ve desktop icin tek codebase.
