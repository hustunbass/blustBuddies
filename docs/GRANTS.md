# Kullanıcıya coin hediye etmek

Coinler telefonda tutulur, veritabanında değil. Hediye (grant) sistemi bunu
kullanıcıya coin göndermek için aşar: sen tabloya bir satır eklersin, uygulama
oyuncu giriş yapmışken satırı alır, coini cüzdana ekler, sunucu satırı "alındı"
yapar. Aynı hediye iki kez verilmez.

## Bir kerelik kurulum
1. Supabase → **SQL Editor** → [supabase/schema.sql](../supabase/schema.sql) dosyasının
   tamamını çalıştır (tekrar çalıştırmak güvenli, `grants` tablosu eklenir).
2. Render'da son commit'i deploy et (sunucuda `/grants` uçları var).
3. Uygulamanın bu sürümü (ya da sonrası) kullanıcıda kurulu olmalı. Eski
   sürümler hediyeyi almaz.

## Hediye vermek
1. Kullanıcının kimliğini bul: Supabase → **Authentication → Users** (uuid),
   ya da **Table Editor → profiles** tablosunda `display_name`'e göre ara.
2. SQL Editor'de:

```sql
insert into grants (user_id, coins, note)
values ('KULLANICININ-UUID-SI', 5000, 'test ekibi hediyesi');
```

Birden fazla kişiye:

```sql
insert into grants (user_id, coins, note)
select id, 2000, 'test ekibi' from profiles where display_name in ('Ali', 'Veli');
```

## Ne zaman ulaşır
Oyuncu **giriş yapmışsa**: uygulamayı açtığında, arka plandan döndüğünde ya da
giriş yaptığında. Ekranda "Sana bir hediye: +5000 coin" bildirimi çıkar. Misafirler
hediye alamaz (hangi kullanıcı olduğu bilinmez).

## Durumu görmek
`select * from grants order by id desc;` → `claimed_at` doluysa alınmıştır.
Boşsa oyuncu henüz uygulamayı açıp giriş yapmamış (ya da eski sürümdedir).

## Sınırlar
- Tek seferlik hediyedir; sonrasında coin yine telefonda yaşar. Telefon
  değişince/uygulama silinince coin geri gelmez (hediye verilmişse tekrar
  verilmez; gerekiyorsa yeni satır ekle).
- Bir hediye en fazla 1.000.000 coin olabilir.
