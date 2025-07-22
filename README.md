# Lorem-printer   

Program slúžiaci na testovanie tlačiarní ktoré sa pripájajú cez paralelné a sériové rozhrania bez nutnosti použitia cups-u a cups driverov.

---

## 📦 Závislosti

Pre správne fungovanie programu je potrebné mať nainštalované nasledovné balíky:

-  Bash
- ``
- ``
- `` 
- 

---

## 💻 Popis príkazov


## Použitie

```bash
./lorem_printer.sh [MOŽNOSTI]
```

---

## MOŽNOSTI

| Prepínač / Parameter         | Popis                                                                 |
|-----------------------------|-----------------------------------------------------------------------|
| `-w`, `--words` **POČET**   | Počet slov Lorem Ipsum textu (predvolené: 50)                         |
| `-f`, `--file` **SÚBOR**    | Tlačiť obsah zo súboru namiesto generovania Lorem Ipsum               |
| `-n`, `--no-format`         | Neformátovať súbor (bez hlavičky/pätičky)                             |
| `-e`, `--encoding` **KÓDOV**| Kódovanie súboru (predvolené: UTF-8)                                  |

### Paralelný port

| Prepínač / Parameter         | Popis                                                                 |
|-----------------------------|-----------------------------------------------------------------------|
| `-p`, `--parallel` **PORT** | Paralelný port (predvolené: `/dev/lp0`)                               |

### Sériový port

| Prepínač / Parameter         | Popis                                                                 |
|-----------------------------|-----------------------------------------------------------------------|
| `-s`, `--serial` **PORT**   | Sériový port (napr. `/dev/ttyS0`, `/dev/ttyUSB0`)                     |
| `-b`, `--baud` **RÝCHLOSŤ** | Baud rate (predvolené: 9600)                                          |
| `--parity` **PARITA**       | Parita: `none`, `even`, `odd` (predvolené: none)                      |
| `--data-bits` **BITY**      | Dátové bity: 7, 8 (predvolené: 8)                                     |
| `--stop-bits` **BITY**      | Stop bity: 1, 2 (predvolené: 1)                                       |
| `--flow-control` **RIADENIE** | Riadenie toku: `none`, `hardware`, `software` (predvolené: none)     |

### Všeobecné

| Prepínač / Parameter         | Popis                                                                 |
|-----------------------------|-----------------------------------------------------------------------|
| `-t`, `--timeout` **SEKUNDY** | Timeout pre sériový port (predvolené: 5)                            |
| `-v`, `--verbose`           | Podrobný výstup                                                       |
| `-l`, `--list-ports`        | Zobrazí zoznam dostupných portov                                      |
| `-h`, `--help`              | Zobrazí túto nápovedu                                                 |

---

## Príklady

**Zoznam portov:**
```bash
./lorem_printer.sh --list-ports
```

**Paralelný port:**
```bash
./lorem_printer.sh -w 100 -p /dev/lp0
./lorem_printer.sh -f dokument.txt -p /dev/usb/lp0
```

**Sériový port:**
```bash
./lorem_printer.sh -w 200 -s /dev/ttyS0 -b 9600
./lorem_printer.sh -f text.txt -s /dev/ttyUSB0 -b 115200
./lorem_printer.sh -s /dev/ttyS1 -b 19200 --parity even --data-bits 7
```

**USB sériové adaptéry:**
```bash
./lorem_printer.sh -f dokument.txt -s /dev/ttyUSB0
./lorem_printer.sh -s /dev/ttyACM0 -b 38400
```
---

## 🖨️ Testované tlačiarne

Zoznam tlačiarní, na ktorých bol program úspešne otestovaný:

- Star Micronics SP200    @Roran60
- Epson TM-U220D          @Roran60
- Epson LX-400            @Roran60

---
