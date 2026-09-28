# Gizli Pano

Windows için ikinci, gizli bir pano. Şifre ve token gibi değerler Windows panosuna ve Win+V geçmişine **düşmeden** kopyalanır, yapıştırılırken pano hiç kullanılmaz.

AutoHotkey v2 · tek dosya · kurulum gerektirmez · disk yazımı yok

English: [README.md](README.md)

---

## Hangi sorunu çözüyor

Sanal makine kullanırken (VMware, Hyper-V, RDP) konak ile misafir arasındaki pano paylaşımı iş hızı için açık tutulur. Bedeli şudur: konakta kopyaladığın **her şey** misafir makineye geçer. Kurumsal bir misafir sistemde bu, kişisel şifrelerinin denetlenen bir ortama akması demektir.

İkinci sorun Windows'un kendisidir. `Win+V` geçmişi kopyalanan değerleri tutar ve panoyu boşaltmak bu kayıtları **silmez**. Panoyu temizlediğini sanarken değer geçmişte durmaya devam eder.

Gizli Pano bu iki yolu da kapatır: hassas değer kendi belleğinde yaşar, Windows panosunda ölçülebilir biçimde çok kısa kalır, Win+V geçmişi ise her yakalamada düşürülür.

---

## Ne yapar

Kopyalama anında sınıflandırma yapılır. İçerik filtresi yoktur — metnin şifre olup olmadığı anlaşılamaz, bu yüzden kararı kullanıcının tuş seçimi verir.

| Kısayol | İşlev |
|---|---|
| `Sol Shift + C` | Seçili metni gizli panoya al, Windows panosunu boşalt |
| `Sol Shift + V` | En son gizli kaydı imlecin olduğu yere yaz |
| `Sol Shift + D` | Gizli pano geçmişi penceresini aç |

Normal `Ctrl+C` / `Ctrl+V` / `Win+V` davranışı **değişmez**. Sıradan metin eskisi gibi kopyalanır ve sanal makineye senkron olur.

Bunlara ek olarak, normal bir kopyalama yaptığında imlecin yanında küçük bir **hassas** düğmesi iki saniye görünür. Web sitesindeki "kopyala" düğmesiyle panoya düşen bir şifreyi sonradan gizli panoya almak için bu düğmeye basmak yeterlidir; değer gizli geçmişe girer, normal pano boşaltılır.

---

## Nasıl çalışır

**Kopyalamada geri yazma yok.** Betik arka planda `Ctrl+C` gönderir, değeri okur ve panoyu derhal boşaltır. Eski pano içeriğini geri yazmaya çalışmaz — geri yazma, değerin panoda kalma süresini uzatır.

**Koruma, panoda geçirilen süredir.** Değer panoda yaklaşık 50 ms kalır. Ölçüm şunu gösterdi: VMware Tools panoyu sürekli değil belirli anlarda aktarıyor ve bu pencereyi kaçırıyor.

**Yapıştırmada pano hiç kullanılmaz.** `Sol Shift + V` değeri `SendText` ile karakter karakter yazar. Shift'li, AltGr'li, Türkçe harfler ve `€` dahil test edildi, karakter düşmesi görülmedi.

**Win+V geçmişi ayrıca düşürülür.** Her gizli yakalamadan sonra WinRT `Clipboard.ClearHistory()` çağrılır.

**Geçmiş yalnız bellektedir.** 20 kayıt, kayıt başına 10 dakika ömür. Diske yazım, log, şifreleme dosyası yok — betik kapanınca hiçbir iz kalmaz.

---



https://github.com/user-attachments/assets/d73c31fc-e88f-415a-83c4-b48a1ae6fe1e


---
**Shift + C , Shift + V , Shift + D**



https://github.com/user-attachments/assets/7711618a-77e3-4e7d-998a-f31490f51370



---

## Gereksinimler

Windows 10 veya 11 ve [AutoHotkey v2](https://www.autohotkey.com/v2/). v1 sözdizimi uyumlu değildir, betik v2 ile çalıştırılmalıdır.

---

## Kurulum

1. AutoHotkey v2'yi kur.
2. `gizli_pano.ahk` dosyasını istediğin klasöre koy.
3. Çift tıkla. Tepsi simgesi belirdiğinde çalışıyordur.
4. Her açılışta çalışsın istersen kısayolunu `shell:startup` klasörüne koy.

Yönetici olarak çalıştırmak gerekmez ve önerilmez.

---

## Ayarlar

Dosyanın başındaki AYAR bölümü tüm ayarları tutar. Değiştirdikten sonra tepsi simgesine sağ tıklayıp **Reload Script** demek yeterlidir.

| Sabit | Varsayılan | Ne yapar |
|---|---|---|
| `TUS_KOPYALA` | `"<+c"` | Gizli kopyalama kısayolu |
| `TUS_YAPISTIR` | `"<+v"` | Son kaydı yapıştırma kısayolu |
| `TUS_GECMIS` | `"<+d"` | Geçmiş penceresi kısayolu |
| `AZAMI` | `20` | Azami kayıt sayısı |
| `OMUR_DK` | `10` | Kayıt ömrü, dakika |
| `HASSAS_SN` | `2` | Yüzen düğmenin ekranda kalma süresi |
| `ONIZLEME` | `46` | Pencerede gösterilen karakter sayısı |
| `HASSAS_SAYDAM` | `235` | Düğme saydamlığı (0 görünmez, 255 mat) |
| `HASSAS_ZEMIN` | `"1E2430"` | Düğme zemin rengi, RRGGBB |
| `HASSAS_YAZI` | `"D6E4EE"` | Düğme yazı rengi, RRGGBB |
| `HASSAS_GEN` / `HASSAS_YUK` | `56` / `20` | Düğme boyutu, piksel |

Kısayol yazımında `<` sol, `>` sağ tuşu belirtir; `+` shift, `^` ctrl, `!` alt, `#` win anlamına gelir. `"^+c"` ctrl+shift+c, `"!v"` alt+v, `"F9"` ise F9 demektir.

---

## Geçmiş penceresi

`Sol Shift + D` ile açılır ve imlecin yanında belirir; en yeni kayıt üsttedir. Ok tuşları seçimi kaydırır, `Enter` seçili kaydı önceki pencereye yazar, `Delete` veya satır sonundaki `×` tek kaydı siler. Başlıktaki **Tumunu temizle** düğmesi geçmişin tamamını düşürür.

Pencere `Esc` ile, başka bir yere tıklandığında ve odak kaybında kapanır. Her satırda kaydın kalan ömrü dakika olarak yazar.

---

## Bilinen sınırlar

**Sanal makine odaktayken kısayollar çalışmaz.** VMware misafir odaktayken klavyeyi ham olarak yakalar; konak kısayolları tetiklenmez. Bu tüm sanal sistemlerde beklenen davranıştır ve bilinçli olarak kabul edilmiştir — gizli değerler zaten misafire gitmeyeceği için gizli panonun misafirde çalışmasına gerek yoktur. VMware'in ham klavye sürücüsünü kapatmak sorunu çözer ama `Win` ve `Alt+Tab` tuşlarını konağa kaçırır.

**`ClearHistory` seçici değildir.** Çağrıldığında Win+V geçmişinin tamamı silinir, yalnız o kayıt değil. Geçmişi yoğun kullanıyorsan bu bir bedeldir. Geçmişi tümden kapatmak istersen `HKCU\Software\Microsoft\Clipboard\EnableClipboardHistory` değerini `0` yapabilirsin.

**Kısayoldaki harf o değiştirgeyle yazılamaz.** Varsayılan kurulumda sol shift ile büyük `C`, `V`, `D` yazılamaz; bu harfler için sağ shift kullanılır. Rahatsız ediyorsa kısayolları değiştir.

**Bellek şifrelenmiyor.** Kayıtlar süreç belleğinde düz metindir. Betiğin savunduğu şey pano ve Win+V sızıntısıdır, bellek dökümü yapabilen bir saldırgan değil.

**`ExcludeClipboardContentFromMonitorProcessing` bayrağına güvenilmez.** Ölçüldü: bayraklı yazım Win+V geçmişine düşmüyor, ancak VMware Tools bayrağı yok sayıyor ve değer misafirde `Ctrl+V` ile yapışıyor. Betik bu yüzden bayrağa değil, panoda geçirilen süreye dayanır.

---

## Ölçüm notları

Aşağıdaki davranışlar varsayım değil, konak-misafir kurulumunda test edilerek bulundu.

`A_Clipboard := ""` panoyu boşaltır ama Win+V geçmişinden kaydı silmez; geçmişte görünen değer güncel pano içeriği değildir.

Panoya yazıp 50 ms sonra boşaltma denemesinde misafirde eski değer duruyordu — ne yeni değer ne de boşaltma senkron oldu. Aktarım sürekli değil, belirli anlarda yapılıyor.

`SendText` ile ve pano ile yazılan aynı karakter dizisi birebir eşleşti; özel karakterlerde düşme olmadı.

---

## Lisans

MIT. Dilediğin gibi kullan, değiştir, dağıt.
