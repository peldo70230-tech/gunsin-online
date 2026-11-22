# Gunsin Online - stari izgled UI-a
#  1) gotove slike iz stari_ui.zip (okviri, dugmad, HP/meta/skill traka)
#  2) (v8: + ciscenje bijelih odsjaja na linijama okvira) sve ostale slike u data\UI: zlatna boja se prebacuje u staru narandzasto-smedju (oblik i velicina ostaju isti)
# Upotreba:  stari_ui.ps1 primijeni   |   stari_ui.ps1 vrati
param([string]$Sta = "primijeni")
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path          # ...\Gunsin Online\_stari_ui
$ui = Join-Path (Split-Path -Parent $root) "data\UI"
$bak = Join-Path $ui "_NUI_original"
$zip = Join-Path $root "stari_ui.zip"
function Kraj($msg, $boja) { Write-Host ""; Write-Host $msg -ForegroundColor $boja; Write-Host ""; Read-Host "Pritisni Enter za izlaz"; exit }
Add-Type -TypeDefinition @"
using System;
public static class StariUi {
    // vraca broj promijenjenih piksela; -1 ako fajl nije obican 24/32-bitni BMP
    public static int Recolor(byte[] b) {
        if (b.Length < 54 || b[0] != (byte)'B' || b[1] != (byte)'M') return -1;
        int off = BitConverter.ToInt32(b, 10); int w = BitConverter.ToInt32(b, 18); int h = Math.Abs(BitConverter.ToInt32(b, 22));
        int bpp = BitConverter.ToInt16(b, 28); int comp = BitConverter.ToInt32(b, 30);
        if (comp != 0 || (bpp != 24 && bpp != 32) || w <= 0 || h <= 0) return -1;
        int step = bpp / 8; int stride = (w * step + 3) & ~3; int n = 0;
        for (int y = 0; y < h; y++) {
            int p = off + y * stride;
            for (int x = 0; x < w; x++) {
                int i = p + x * step; if (i + 2 >= b.Length) return n;
                int B = b[i], G = b[i + 1], R = b[i + 2];
                int mx = Math.Max(R, Math.Max(G, B)), mn = Math.Min(R, Math.Min(G, B));
                if (mx < 46) continue; int d = mx - mn; if (d == 0) continue;
                double s = (double)d / mx; if (s < 0.12 || s > 0.80) continue;
                double hh;
                if (mx == R) { hh = 60.0 * ((double)(G - B) / d); if (hh < 0) hh += 360; }
                else if (mx == G) hh = 60.0 * ((double)(B - R) / d + 2);
                else hh = 60.0 * ((double)(R - G) / d + 4);
                if (hh < 27 || hh > 64) continue;
                double v = mx / 255.0 * 0.94; double fv = 0.92 - 0.37 * Math.Max(0.0, Math.Min(1.0, (mx / 255.0 - 0.35) / 0.30)); double s2 = Math.Min(1.0, 0.35 + s * 0.55) * fv;
                // HSV(32 stepena, s2, v) - boje sa starog UI-a -> RGB  (sektor 0: r=v, g=t, b=pp)
                double f = 32.0 / 60.0; double pp = v * (1 - s2), t = v * (1 - s2 * (1 - f));
                b[i + 2] = (byte)(v * 255); b[i + 1] = (byte)(t * 255); b[i] = (byte)(pp * 255); n++;
            }
        }
        return n;
    }
    static void Hsv(int R, int G, int B, out double hh, out double s, out double v) {
        int mx = Math.Max(R, Math.Max(G, B)), mn = Math.Min(R, Math.Min(G, B)); int d = mx - mn;
        v = mx / 255.0; s = mx == 0 ? 0 : (double)d / mx; hh = 0;
        if (d == 0) return;
        if (mx == R) { hh = 60.0 * ((double)(G - B) / d); if (hh < 0) hh += 360; }
        else if (mx == G) hh = 60.0 * ((double)(B - R) / d + 2);
        else hh = 60.0 * ((double)(R - G) / d + 4);
    }
    // bijeli odsjaji koji leze na narandzastim linijama okvira dobijaju boju linije; vraca broj promijenjenih piksela
    public static int LineFix(byte[] b) {
        if (b.Length < 54 || b[0] != (byte)'B' || b[1] != (byte)'M') return -1;
        int off = BitConverter.ToInt32(b, 10); int w = BitConverter.ToInt32(b, 18); int h = Math.Abs(BitConverter.ToInt32(b, 22));
        int bpp = BitConverter.ToInt16(b, 28); int comp = BitConverter.ToInt32(b, 30);
        if (comp != 0 || (bpp != 24 && bpp != 32) || w <= 0 || h <= 0) return -1;
        int step = bpp / 8; int stride = (w * step + 3) & ~3;
        if ((long)off + (long)stride * h > b.Length) return -1;
        byte[] kind = new byte[w * h];          // 1 = linija (narandzasto), 2 = bijeli odsjaj
        for (int y = 0; y < h; y++) for (int x = 0; x < w; x++) {
            int i = off + y * stride + x * step; double hh, s, v; Hsv(b[i + 2], b[i + 1], b[i], out hh, out s, out v);
            if (v > 0.40 && s >= 0.22 && hh > 15 && hh < 50) kind[y * w + x] = 1;
            else if (v > 0.47 && s < 0.14) kind[y * w + x] = 2;
        }
        int[] src = new int[w * h]; for (int k = 0; k < src.Length; k++) src[k] = -1;
        for (int pass = 0; pass < 2; pass++) {
            int n1 = pass == 0 ? h : w, n2 = pass == 0 ? w : h;
            for (int a = 0; a < n1; a++) {
                int c = 0;
                while (c < n2) {
                    int q = pass == 0 ? a * w + c : c * w + a;
                    if (kind[q] == 0) { c++; continue; }
                    int e = c, no = 0;
                    while (e < n2) { int q2 = pass == 0 ? a * w + e : e * w + a; if (kind[q2] == 0) break; if (kind[q2] == 1) no++; e++; }
                    int len = e - c;
                    if (len >= 10 && no >= 2 && no * 10 >= len) {
                        for (int k = c; k < e; k++) {
                            int qk = pass == 0 ? a * w + k : k * w + a; if (kind[qk] != 2 || src[qk] >= 0) continue;
                            for (int dd = 1; dd < len; dd++) {
                                int k1 = k - dd, k2 = k + dd; int found = -1;
                                if (k1 >= c) { int t = pass == 0 ? a * w + k1 : k1 * w + a; if (kind[t] == 1) found = t; }
                                if (found < 0 && k2 < e) { int t = pass == 0 ? a * w + k2 : k2 * w + a; if (kind[t] == 1) found = t; }
                                if (found >= 0) { src[qk] = found; break; }
                            }
                        }
                    }
                    c = e;
                }
            }
        }
        int n = 0;
        for (int q = 0; q < src.Length; q++) {
            if (src[q] < 0) continue;
            int i = off + (q / w) * stride + (q % w) * step, j = off + (src[q] / w) * stride + (src[q] % w) * step;
            b[i] = b[j]; b[i + 1] = b[j + 1]; b[i + 2] = b[j + 2]; n++;
        }
        return n;
    }
    // uklanja nacrtana crvena dugmad iz podloge (prava dugmad su sad niza); vraca broj uklonjenih polja
    public static int RemoveRed(byte[] b) {
        if (b.Length < 54 || b[0] != (byte)'B' || b[1] != (byte)'M') return -1;
        int off = BitConverter.ToInt32(b, 10); int w = BitConverter.ToInt32(b, 18); int hRaw = BitConverter.ToInt32(b, 22); int h = Math.Abs(hRaw);
        int bpp = BitConverter.ToInt16(b, 28); int comp = BitConverter.ToInt32(b, 30);
        if (comp != 0 || (bpp != 24 && bpp != 32) || w <= 0 || h <= 0) return -1;
        int step = bpp / 8; int stride = (w * step + 3) & ~3;
        if ((long)off + (long)stride * h > b.Length) return -1;
        bool[] red = new bool[w * h]; int[] rowCnt = new int[h];
        for (int y = 0; y < h; y++) {                       // y = red odozgo
            int fy = hRaw > 0 ? h - 1 - y : y;
            for (int x = 0; x < w; x++) {
                int i = off + fy * stride + x * step; int B = b[i], G = b[i + 1], R = b[i + 2];
                if (R > 105 && G < 100 && B < 100 && R - G > 45) { red[y * w + x] = true; rowCnt[y]++; }
            }
        }
        int n = 0; int y0 = -1;
        for (int y = 0; y <= h; y++) {
            bool on = y < h && rowCnt[y] > 40;
            if (on && y0 < 0) y0 = y;
            if (!on && y0 >= 0) {
                int y1 = y - 1;
                if (y1 - y0 >= 8) {
                    int x0 = -1, last = -1;
                    for (int x = 0; x <= w; x++) {
                        bool c = false;
                        if (x < w) for (int yy = y0; yy <= y1; yy++) if (red[yy * w + x]) { c = true; break; }
                        if (c) { if (x0 < 0) x0 = x; last = x; }
                        if (x0 >= 0 && (x == w || (!c && x - last > 4))) {
                            if (last - x0 >= 50) {
                                int ax = Math.Max(0, x0 - 2), bx = Math.Min(w - 1, last + 2), ay = Math.Max(0, y0 - 6), by = Math.Min(h - 1, y1 + 12);
                                for (int yy = ay; yy <= by; yy++) { int fy = hRaw > 0 ? h - 1 - yy : yy;
                                    for (int xx = ax; xx <= bx; xx++) { int i = off + fy * stride + xx * step; b[i] = 0; b[i + 1] = 0; b[i + 2] = 0; } }
                                n++;
                            }
                            x0 = -1;
                        }
                    }
                }
                y0 = -1;
            }
        }
        return n;
    }
    // ikone predmeta (32-bitne, s oblikom u alfa kanalu): prozirni dio dobija kljucnu zutu boju prozora; vraca broj piksela
    public static int IconKey(byte[] b) {
        if (b.Length < 54 || b[0] != (byte)'B' || b[1] != (byte)'M') return -1;
        int off = BitConverter.ToInt32(b, 10); int w = BitConverter.ToInt32(b, 18); int h = Math.Abs(BitConverter.ToInt32(b, 22));
        int bpp = BitConverter.ToInt16(b, 28); int comp = BitConverter.ToInt32(b, 30);
        if (comp != 0 || bpp != 32 || w < 16 || w > 48 || h < 16 || h > 48) return -1;
        if ((long)off + (long)w * h * 4 > b.Length) return -1;
        int n = 0, full = 0;
        for (int k = 0; k < w * h; k++) { int a = b[off + k * 4 + 3]; if (a == 0) n++; else if (a == 255) full++; }
        if (n == 0 || full < 20) return 0;                 // nema oblika ili je slika bez pune boje - ne diraj
        for (int k = 0; k < w * h; k++) { int i = off + k * 4; if (b[i + 3] == 0) { b[i] = 0; b[i + 1] = 255; b[i + 2] = 255; } }
        return n;
    }
    // tamna tekstura podloge se izrezuje (alfa 0), linije i ostalo ostaju pune; vraca novi 32-bitni BMP ili null
    public static byte[] CutDark(byte[] b, int prag) {
        if (b.Length < 54 || b[0] != (byte)'B' || b[1] != (byte)'M') return null;
        int off = BitConverter.ToInt32(b, 10); int w = BitConverter.ToInt32(b, 18); int hRaw = BitConverter.ToInt32(b, 22); int h = Math.Abs(hRaw);
        int bpp = BitConverter.ToInt16(b, 28); int comp = BitConverter.ToInt32(b, 30);
        if (comp != 0 || (bpp != 24 && bpp != 32) || w <= 0 || h <= 0) return null;
        int step = bpp / 8; int stride = (w * step + 3) & ~3;
        if ((long)off + (long)stride * h > b.Length) return null;
        byte[] o = new byte[54 + w * h * 4];
        o[0] = (byte)'B'; o[1] = (byte)'M';
        BitConverter.GetBytes(o.Length).CopyTo(o, 2); BitConverter.GetBytes(54).CopyTo(o, 10); BitConverter.GetBytes(40).CopyTo(o, 14);
        BitConverter.GetBytes(w).CopyTo(o, 18); BitConverter.GetBytes(hRaw).CopyTo(o, 22);
        BitConverter.GetBytes((short)1).CopyTo(o, 26); BitConverter.GetBytes((short)32).CopyTo(o, 28); BitConverter.GetBytes(w * h * 4).CopyTo(o, 34);
        for (int y = 0; y < h; y++) for (int x = 0; x < w; x++) {
            int i = off + y * stride + x * step; int j = 54 + (y * w + x) * 4;
            int B = b[i], G = b[i + 1], R = b[i + 2]; int mx = Math.Max(R, Math.Max(G, B));
            if (mx < prag) { o[j] = 0; o[j + 1] = 0; o[j + 2] = 0; o[j + 3] = 0; }
            else { o[j] = (byte)B; o[j + 1] = (byte)G; o[j + 2] = (byte)R; o[j + 3] = 255; }
        }
        return o;
    }
}
"@
try {
    if (-not (Test-Path -LiteralPath $ui)) { Kraj "GRESKA: ne nalazim folder $ui" "Red" }
    if (Get-Process -Name engine -ErrorAction SilentlyContinue | Where-Object { $_.Path -and $_.Path.StartsWith((Split-Path -Parent $root), [StringComparison]::OrdinalIgnoreCase) }) { Kraj "Gunsin klijent je upaljen. Ugasi igru pa pokreni ponovo." "Yellow" }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    if ($Sta -eq "primijeni") {
        New-Item -ItemType Directory -Force -Path $bak | Out-Null
        $gotove = @{}; $n = 0
        $z = [System.IO.Compression.ZipFile]::OpenRead($zip)
        try {
            foreach ($e in $z.Entries) {
                if (-not $e.Name) { continue }
                $gotove[$e.Name.ToLower()] = $true
                $dst = Join-Path $ui $e.Name; $b = Join-Path $bak $e.Name
                if (-not (Test-Path -LiteralPath $dst)) { continue }                       # mijenjamo samo fajlove koji vec postoje
                if (-not (Test-Path -LiteralPath $b)) { Copy-Item -LiteralPath $dst -Destination $b }   # original se cuva samo prvi put
                [System.IO.Compression.ZipFileExtensions]::ExtractToFile($e, $dst, $true); $n++
            }
        } finally { $z.Dispose() }
        Write-Host "Gotove slike: $n" -ForegroundColor Cyan
        # 2) prebojavanje ostalih slika (slike s fotografijama, ikone i Gunsin dodaci se preskacu)
        $preskoci = '^(stari-|background|loading-back|launcher-bg|gunsin_|menu-type|\(e\)|\(k\)|kal-shop|ui-login-popup|ui-character-back|ui-server select-back|party union-back)|icon|_original|_prije_|_new\.|sinsu0'
        $m = 0; $isto = 0; $rub = 0
        foreach ($f in Get-ChildItem -LiteralPath $ui -File -Filter *.bmp) {
            $ime = $f.Name.ToLower()
            if ($gotove.ContainsKey($ime) -or $ime -match $preskoci) { continue }
            $b = Join-Path $bak $f.Name
            if (-not (Test-Path -LiteralPath $b)) { Copy-Item -LiteralPath $f.FullName -Destination $b }
            $bytes = [System.IO.File]::ReadAllBytes($b)                                    # uvijek krecemo od originala
            $k = [StariUi]::Recolor($bytes)
            if ($k -gt 0) { $r = [StariUi]::LineFix($bytes); if ($r -gt 0) { $rub++ } }
            if ($k -gt 0) { [System.IO.File]::WriteAllBytes($f.FullName, $bytes); $m++ } else { $isto++; Remove-Item -LiteralPath $b -Force }
        }
        Write-Host "Prebojene slike: $m (bez zlatne boje ili preskoceno: $isto), ociscenih rubova: $rub" -ForegroundColor Cyan
        # 3) prozirni prozori: podlogama s liste se izrezuje tamna tekstura
        $lista = Join-Path $root "prozirno.txt"; $pz = 0; $dug = 0
        if (Test-Path -LiteralPath $lista) {
            foreach ($ime in Get-Content -LiteralPath $lista) {
                $ime = $ime.Trim(); if (-not $ime) { continue }
                $prag = 56; $dio = $ime.Split(";"); if ($dio.Length -gt 1) { $ime = $dio[0].Trim(); $prag = [int]$dio[1] }
                $f = Join-Path $ui ($ime + ".bmp"); if (-not (Test-Path -LiteralPath $f)) { continue }
                $bajt = [System.IO.File]::ReadAllBytes($f); $crv = [StariUi]::RemoveRed($bajt); if ($crv -gt 0) { $dug += $crv }
                $nb = [StariUi]::CutDark($bajt, $prag)
                if ($nb -ne $null) { [System.IO.File]::WriteAllBytes($f, $nb); $pz++ }
            }
        }
        Write-Host "Prozirne podloge: $pz (uklonjenih nacrtanih dugmadi: $dug)" -ForegroundColor Cyan
        # 4) ikone predmeta: crna pozadina iza ikone postaje prozirna (kao na starom)
        $ht = Join-Path (Split-Path -Parent $root) "data\HyperText"; $ib = Join-Path $ht "_ikone_original"; $ik = 0
        if (Test-Path -LiteralPath $ht) {
            New-Item -ItemType Directory -Force -Path $ib | Out-Null
            foreach ($f in Get-ChildItem -LiteralPath $ht -File -Filter *.bmp) {
                if ($f.Length -gt 10000) { continue }
                $o = Join-Path $ib $f.Name
                $izvor = $f.FullName; if (Test-Path -LiteralPath $o) { $izvor = $o }      # uvijek krecemo od originala
                $bajt = [System.IO.File]::ReadAllBytes($izvor)
                $k = 0; if (Test-Path -LiteralPath $o) { Copy-Item -LiteralPath $o -Destination $f.FullName -Force }
                if ($k -gt 0) {
                    if (-not (Test-Path -LiteralPath $o)) { Copy-Item -LiteralPath $f.FullName -Destination $o }
                    [System.IO.File]::WriteAllBytes($f.FullName, $bajt); $ik++
                }
            }
        }
        Write-Host "Ikone s prozirnom pozadinom: $ik" -ForegroundColor Cyan
        Kraj "Stari izgled je postavljen. Originali su u data\UI\_NUI_original. Upali igru i pogledaj." "Green"
    } elseif ($Sta -eq "vrati") {
        if (-not (Test-Path -LiteralPath $bak)) { Kraj "Nema sacuvanih originala - nista nije mijenjano." "Yellow" }
        $n = 0
        Get-ChildItem -LiteralPath $bak -File | ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $ui $_.Name) -Force; $n++ }
        $ht = Join-Path (Split-Path -Parent $root) "data\HyperText"; $ib = Join-Path $ht "_ikone_original"
        if (Test-Path -LiteralPath $ib) { Get-ChildItem -LiteralPath $ib -File | ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $ht $_.Name) -Force; $n++ } }
        Kraj "Vracen je novi (originalni) izgled ($n slika)." "Green"
    } else { Kraj "Nepoznata naredba: $Sta" "Red" }
} catch { Kraj "GRESKA: $($_.Exception.Message)" "Red" }
