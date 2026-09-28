#Requires AutoHotkey v2.0
#SingleInstance Force
InstallKeybdHook
Persistent

; ---------------------------------------------------------------- AYAR
; Tus atamalari. AHK kalibi: < sol, > sag, + shift, ^ ctrl, ! alt, # win
; Ornek: "<+c" sol shift+c · "^+c" ctrl+shift+c · "!v" alt+v
TUS_KOPYALA := "<+c"    ; gizli kopyala
TUS_YAPISTIR := "<+v"   ; en son kaydi yapistir
TUS_GECMIS := "<+d"     ; gizli pano gecmisi penceresi

AZAMI := 20          ; azami kayit sayisi
OMUR_DK := 10        ; kayit basina omur, dakika
HASSAS_SN := 2       ; yuzen dugmenin ekranda kalma suresi, saniye
ONIZLEME := 46       ; pencerede gosterilen karakter sayisi

; Hassas dugmesinin gorunumu
HASSAS_SAYDAM := 235   ; 0 tamamen gorunmez, 255 tam opak
HASSAS_ZEMIN := "1E2430"   ; zemin rengi, RRGGBB
HASSAS_YAZI := "D6E4EE"    ; yazi rengi, RRGGBB
HASSAS_GEN := 56           ; genislik, piksel
HASSAS_YUK := 20           ; yukseklik, piksel

; ---------------------------------------------------------------- DURUM
pano := []
kendi := false
gecmisGui := 0
gecmisHwnd := 0
satirlar := []
secili := 1
odakGordu := false
oncekiPencere := 0
hassasGui := 0
hassasBtn := 0
hassasZaman := 0
hassasGorunur := false

; ---------------------------------------------------------------- KURULUM
hassasGui := Gui("-Caption +AlwaysOnTop +ToolWindow +E0x08000000")
hassasGui.BackColor := HASSAS_ZEMIN
hassasGui.MarginX := 0
hassasGui.MarginY := 0
hassasGui.SetFont("s8", "Segoe UI")
hassasBtn := hassasGui.Add("Text",
    "w" HASSAS_GEN " h" HASSAS_YUK " +0x200 +Center Background" HASSAS_ZEMIN " c" HASSAS_YAZI,
    "hassas")
hassasBtn.OnEvent("Click", HassasAl)

A_TrayMenu.Insert("1&", "Gizli gecmisi bosalt", GecmisBosalt)
A_TrayMenu.Insert("2&")

OnClipboardChange PanoDegisti
SetTimer Temizle, 30000

Hotkey TUS_KOPYALA, (*) => GizliKopyala()
Hotkey TUS_YAPISTIR, (*) => GizliYapistir()
Hotkey TUS_GECMIS, (*) => GecmisAc()

; ---------------------------------------------------------------- TUSLAR
; Ana tuslar AYAR bolumundeki sabitlerden Hotkey() ile kuruluyor.
; Asagidakiler pencereye baglidir, sabit kalir.
#HotIf gecmisHwnd && WinActive("ahk_id " gecmisHwnd)
Up:: Sec(-1)
Down:: Sec(1)
Enter:: Yapistir(secili)
NumpadEnter:: Yapistir(secili)
Delete:: SatirSil(secili)
Escape:: GecmisKapat()
#HotIf

; Dugme odak almadigi icin baska yere tiklamak onu kendiliginden
; kapatmaz. Zamanlayiciyla fare tusunu yoklamak kisa tiklari
; kaciriyordu; bu yuzden gecirgen (~) fare kisayollari kullaniliyor.
#HotIf hassasGorunur
~LButton:: HassasTik()
~RButton:: HassasTik()
~MButton:: HassasTik()
#HotIf

; ---------------------------------------------------------------- KOPYALA
GizliKopyala() {
    global pano, kendi, AZAMI
    TuslariBirak()
    kendi := true
    A_Clipboard := ""
    Send "^c"
    okundu := ClipWait(0.6, 0)
    metin := okundu ? A_Clipboard : ""
    A_Clipboard := ""
    SetTimer () => Serbest(), -250
    if metin = "" {
        Bildir("secili metin okunamadi")
        return
    }
    Temizle()
    Ekle(metin)
    WinGecmisiTemizle()
    Bildir("gizli panoya alindi - " pano.Length "/" AZAMI)
}

GizliYapistir() {
    global pano
    Temizle()
    if pano.Length = 0 {
        Bildir("gizli pano bos")
        return
    }
    TuslariBirak()
    Sleep 40
    SendText pano[1].metin
}

Serbest() {
    global kendi
    kendi := false
}

; Kisayolun degistirge tuslari basili kaldiginda Ctrl+C ve SendText
; bozulur; hangisi fiziksel olarak basiliysa birakilir.
TuslariBirak() {
    for tus in ["LShift", "RShift", "LCtrl", "RCtrl", "LAlt", "RAlt", "LWin", "RWin"]
        if GetKeyState(tus, "P")
            Send "{" tus " up}"
}

; ---------------------------------------------------------------- GECMIS
Ekle(metin) {
    global pano, AZAMI
    pano.InsertAt(1, {metin: metin, zaman: A_TickCount})
    while pano.Length > AZAMI
        pano.Pop()
}

Temizle() {
    global pano, OMUR_DK
    omur := OMUR_DK * 60000
    i := pano.Length
    while i >= 1 {
        if (A_TickCount - pano[i].zaman) > omur
            pano.RemoveAt(i)
        i--
    }
}

GecmisBosalt(*) {
    global pano
    pano := []
    Bildir("gizli pano bosaltildi")
}

; Pencere kendi dugmesinin isleyicisi icinde yok edilmez; kapanis
; isleyici bittikten sonraya birakilir.
TumunuTemizle(*) {
    global pano
    pano := []
    SetTimer GecmisKapat, -10
    Bildir("gizli pano bosaltildi")
}

SatirMetni(sira, k) {
    global ONIZLEME, OMUR_DK
    m := StrReplace(StrReplace(k.metin, Chr(13), " "), Chr(10), " ")
    m := StrReplace(m, Chr(9), " ")
    if StrLen(m) > ONIZLEME
        m := SubStr(m, 1, ONIZLEME) Chr(8230)
    kalan := OMUR_DK - Floor((A_TickCount - k.zaman) / 60000)
    return " " sira ".  " m "      [" kalan " dk]"
}

GecmisAc() {
    global pano, gecmisGui, gecmisHwnd, satirlar, secili, oncekiPencere, odakGordu
    Temizle()
    if gecmisHwnd
        GecmisKapat()
    if pano.Length = 0 {
        Bildir("gizli pano bos")
        return
    }
    oncekiPencere := WinExist("A")
    secili := 1
    satirlar := []

    gecmisGui := Gui("-Caption +AlwaysOnTop +ToolWindow +Border")
    gecmisGui.BackColor := 0x17181B
    gecmisGui.MarginX := 8
    gecmisGui.MarginY := 8
    ; Yerel Button denetimi beyaz zeminlidir ve koyu pencerede goz alir;
    ; dugmeler zemini boyanabilen Text denetimiyle kuruluyor.
    gecmisGui.SetFont("s9 c7E8A93", "Segoe UI")
    gecmisGui.Add("Text", "w244 y+4", "ok tuslari secer, Enter yapistirir, Esc kapatir")
    tum := gecmisGui.Add("Text", "x+6 yp-5 w134 h24 +0x200 +Center Background0x232529 c94A2AC", "Tumunu temizle")
    tum.OnEvent("Click", TumunuTemizle)
    gecmisGui.SetFont("s9 cD8D8D8", "Segoe UI")

    for i, k in pano {
        txt := gecmisGui.Add("Text", "xm w352 h22 +0x200 Background0x1B1D21", SatirMetni(i, k))
        txt.OnEvent("Click", SatirTik.Bind(i))
        dgm := gecmisGui.Add("Text", "x+4 yp w26 h22 +0x200 +Center Background0x241D1D c9C7A7A", Chr(215))
        dgm.OnEvent("Click", SatirSil.Bind(i))
        satirlar.Push(txt)
    }
    Isaretle()

    MouseGetPos &mx, &my
    gen := 410
    yuk := 46 + pano.Length * 24
    if (mx + gen > A_ScreenWidth)
        mx := A_ScreenWidth - gen - 12
    if (my + yuk > A_ScreenHeight)
        my := A_ScreenHeight - yuk - 12
    if (mx < 0)
        mx := 0
    if (my < 0)
        my := 0
    gecmisGui.Show("x" mx " y" my " AutoSize")
    gecmisHwnd := gecmisGui.Hwnd
    odakGordu := false
    SetTimer OdakKontrol, 150
}

; Pencere odagi baska bir yere gecince kapanir; ilk odagi gorene
; kadar beklenir, yoksa Show henuz etkinlesmeden kendini kapatir.
OdakKontrol() {
    global gecmisHwnd, odakGordu
    if !gecmisHwnd {
        SetTimer OdakKontrol, 0
        return
    }
    if WinActive("ahk_id " gecmisHwnd) {
        odakGordu := true
        return
    }
    if odakGordu
        GecmisKapat()
}

GecmisKapat() {
    global gecmisGui, gecmisHwnd, satirlar
    SetTimer OdakKontrol, 0
    if gecmisGui {
        gecmisGui.Destroy()
        gecmisGui := 0
        gecmisHwnd := 0
        satirlar := []
    }
}

Isaretle() {
    global satirlar, secili
    for i, t in satirlar {
        t.Opt(i = secili ? "+Background0x264D3A" : "+Background0x1B1D21")
        t.Redraw()
    }
}

Sec(yon) {
    global pano, secili
    if pano.Length = 0
        return
    secili := Mod(secili - 1 + yon + pano.Length, pano.Length) + 1
    Isaretle()
}

SatirTik(sira, *) {
    global secili
    secili := sira
    Isaretle()
    Yapistir(sira)
}

SatirSil(sira, *) {
    global pano
    if sira < 1 || sira > pano.Length
        return
    pano.RemoveAt(sira)
    GecmisKapat()
    if pano.Length
        GecmisAc()
    else
        Bildir("gizli pano bos")
}

Yapistir(sira) {
    global pano, oncekiPencere
    if sira < 1 || sira > pano.Length
        return
    metin := pano[sira].metin
    hedef := oncekiPencere
    GecmisKapat()
    if hedef && WinExist("ahk_id " hedef)
        WinActivate "ahk_id " hedef
    Sleep 90
    SendText metin
}

; ---------------------------------------------------------------- HASSAS
PanoDegisti(tip) {
    global kendi
    if kendi
        return
    if tip != 1
        return
    HassasGoster()
}

HassasGoster() {
    global hassasGui, hassasZaman, hassasGorunur, HASSAS_SN, HASSAS_SAYDAM
    MouseGetPos &mx, &my
    hassasGui.Show("x" (mx + 16) " y" (my + 20) " AutoSize NoActivate")
    ; Saydamlik pencere gorunur olduktan SONRA uygulanir; Show'dan
    ; once pencere hedef olarak bulunamiyor.
    try WinSetTransparent HASSAS_SAYDAM, "ahk_id " hassasGui.Hwnd
    hassasZaman := A_TickCount
    hassasGorunur := true
    SetTimer HassasGizle, -HASSAS_SN * 1000
}

; Ilk 250 ms, kopyalama dugmesine yapilan tikin kendisini
; yakalamamak icin gormezden gelinir. Dugmenin uzerindeki tik
; kapatmaz, Click isleyicisine gider.
HassasTik() {
    global hassasGui, hassasZaman
    if (A_TickCount - hassasZaman) < 250
        return
    MouseGetPos , , &altPencere
    if (altPencere = hassasGui.Hwnd)
        return
    HassasGizle()
}

HassasGizle() {
    global hassasGui, hassasGorunur
    hassasGorunur := false
    SetTimer HassasGizle, 0
    hassasGui.Hide()
}

HassasAl(*) {
    global kendi
    metin := A_Clipboard
    HassasGizle()
    if metin = "" {
        Bildir("pano bos")
        return
    }
    kendi := true
    A_Clipboard := ""
    SetTimer () => Serbest(), -250
    Temizle()
    Ekle(metin)
    WinGecmisiTemizle()
    Bildir("gizli panoya alindi, pano ve Win+V gecmisi bosaltildi")
}

; ---------------------------------------------------------------- WIN+V
; A_Clipboard := "" panoyu bosaltir ama Win+V gecmisinden kaydi silmez.
; Gecmisi yalnizca WinRT ClearHistory dusurur; TUM gecmisi siler.
; Pencere gizli, cagri beklemesiz.
WinGecmisiTemizle() {
    komut := 'powershell.exe -NoProfile -WindowStyle Hidden -Command '
        . '"[Windows.ApplicationModel.DataTransfer.Clipboard,Windows.ApplicationModel.DataTransfer,ContentType=WindowsRuntime]::ClearHistory()"'
    try Run komut, , "Hide"
}

; ---------------------------------------------------------------- BILDIRIM
Bildir(metin) {
    ToolTip metin
    SetTimer () => ToolTip(), -1500
}