# Lorem-printer   

LOREM IPSUM GENERÁTOR PRE PARALELNÝ PORT
========================================

POPIS:
Bash skript na generovanie Lorem Ipsum textu nastaviteľnej dĺžky a jeho odoslanie 
cez paralelný port do tlačiarne.

HLAVNÉ FUNKCIE:
- Generovanie Lorem Ipsum textu s nastaviteľným počtom slov
- Kontrola existencie a oprávnení paralelného portu
- Formátovanie textu s hlavičkou, pätičkou a form feed
- Bezpečnostné kontroly s potvrdením pred tlačou
- Náhľad textu pred odoslaním
- Podrobná nápoveda a validácia argumentov

POUŽITIE:
./lorem_printer.sh [MOŽNOSTI]

MOŽNOSTI:
-w, --words POČET     Počet slov Lorem Ipsum textu (predvolené: 50)
-p, --port PORT       Paralelný port (predvolené: /dev/lp0)
-h, --help           Zobrazí nápovedu

PRÍKLADY POUŽITIA:
./lorem_printer.sh                    # Základné použitie (50 slov, /dev/lp0)
./lorem_printer.sh -w 200             # 200 slov
./lorem_printer.sh -w 100 -p /dev/lp1 # 100 slov na /dev/lp1
./lorem_printer.sh --help             # Zobrazenie nápovedy

INŠTALÁCIA:
1. Uložte skript do súboru (napr. lorem_printer.sh)
2. Nastavte spustiteľné oprávnenia: chmod +x lorem_printer.sh
3. Spustite skript

SYSTÉMOVÉ POŽIADAVKY:
- Linux/Unix systém s bash
- Paralelný port (/dev/lp0, /dev/lp1, atď.)
- Oprávnenia na zápis do paralelného portu
- Pripojená tlačiareň na paralelnom porte

OPRÁVNENIA:
Skript môže vyžadovať:
- Root oprávnenia, alebo
- Pridanie používateľa do skupiny 'lp': sudo usermod -a -G lp $USER

FUNKCIE SKRIPTU:
1. generate_lorem_ipsum() - Generuje Lorem Ipsum text zo slovníka
2. check_parallel_port() - Kontroluje existenciu a oprávnenia portu
3. send_to_printer() - Odošle formátovaný text na tlačiareň
4. show_help() - Zobrazí nápovedu

FORMÁTOVANIE VÝSTUPU:
- Automatické zalomenie riadkov (12 slov na riadok)
- Veľké písmeno na začiatku viet
- Interpunkcia na konci viet
- Hlavička: "=== LOREM IPSUM TEXT ==="
- Pätička: "=== KONIEC TEXTU ==="
- Form feed (\f) pre novú stránku

BEZPEČNOSTNÉ FUNKCIE:
- Validácia argumentov
- Kontrola existencie paralelného portu
- Kontrola oprávnení na zápis
- Potvrdenie pred odoslaním na tlačiareň
- Zobrazenie náhľadu textu

CHYBOVÉ HLÁSENIA:
- Neexistujúci paralelný port
- Nedostatočné oprávnenia
- Neplatné argumenty
- Chyby pri odosielaní na tlačiareň

PARALELNÉ PORTY:
Typické umiestnenia:
- /dev/lp0 (prvý paralelný port)
- /dev/lp1 (druhý paralelný port)
- /dev/parport0, /dev/parport1 (alternatívne názvy)

RIEŠENIE PROBLÉMOV:
1. Port neexistuje: Skontrolujte ls -la /dev/lp*
2. Nedostatočné oprávnenia: Spustite ako root alebo pridajte do skupiny lp
3. Tlačiareň nereaguje: Skontrolujte pripojenie a napájanie
4. Nesprávny formát: Skontrolujte kompatibilitu tlačiarne s plain textom

POZNÁMKY:
- Skript je optimalizovaný pre textové tlačiarne
- Lorem Ipsum slovník obsahuje 80+ slov
- Text je generovaný náhodne z dostupných slov
- Podporuje iba plain text výstup
- Form feed zabezpečuje vyhodenie stránky po tlači

