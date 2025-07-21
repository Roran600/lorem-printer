#!/bin/bash

# Lorem Printer - paralelné + sériové porty + súbory
# Použitie: ./lorem_printer.sh [MOŽNOSTI]

# Predvolené hodnoty
DEFAULT_WORDS=50
DEFAULT_PARALLEL_PORT="/dev/lp0"
DEFAULT_SERIAL_PORT="/dev/ttyS0"
DEFAULT_BAUD_RATE=9600
DEFAULT_SERIAL_PARAMS="8N1"

# Funkcia na zobrazenie nápovedy
show_help() {
    echo "Použitie: $0 [MOŽNOSTI]"
    echo ""
    echo "MOŽNOSTI:"
    echo "  -w, --words POČET        Počet slov Lorem Ipsum textu (predvolené: $DEFAULT_WORDS)"
    echo "  -f, --file SÚBOR         Tlačiť obsah zo súboru namiesto generovania Lorem Ipsum"
    echo "  -n, --no-format          Neformátovať súbor (bez hlavičky/pätičky)"
    echo "  -e, --encoding KÓDOV     Kódovanie súboru (predvolené: UTF-8)"
    echo ""
    echo "PARALELNÝ PORT:"
    echo "  -p, --parallel PORT      Paralelný port (predvolené: $DEFAULT_PARALLEL_PORT)"
    echo ""
    echo "SÉRIOVÝ PORT:"
    echo "  -s, --serial PORT        Sériový port (napr. /dev/ttyS0, /dev/ttyUSB0)"
    echo "  -b, --baud RÝCHLOSŤ      Baud rate (predvolené: $DEFAULT_BAUD_RATE)"
    echo "  --parity PARITA          Parita: none, even, odd (predvolené: none)"
    echo "  --data-bits BITY         Dátové bity: 7, 8 (predvolené: 8)"
    echo "  --stop-bits BITY         Stop bity: 1, 2 (predvolené: 1)"
    echo "  --flow-control RIADENIE  Riadenie toku: none, hardware, software (predvolené: none)"
    echo ""
    echo "VŠEOBECNÉ:"
    echo "  -t, --timeout SEKUNDY    Timeout pre sériový port (predvolené: 5)"
    echo "  -v, --verbose            Podrobný výstup"
    echo "  -h, --help              Zobrazí túto nápovedu"
    echo ""
    echo "PRÍKLADY:"
    echo "  Paralelný port:"
    echo "    $0 -w 100 -p /dev/lp0"
    echo "    $0 -f dokument.txt -p /dev/lp1"
    echo ""
    echo "  Sériový port:"
    echo "    $0 -w 200 -s /dev/ttyS0 -b 9600"
    echo "    $0 -f text.txt -s /dev/ttyUSB0 -b 115200"
    echo "    $0 -s /dev/ttyS1 -b 19200 --parity even --data-bits 7"
    echo ""
    echo "  USB sériové adaptéry:"
    echo "    $0 -f dokument.txt -s /dev/ttyUSB0"
    echo "    $0 -s /dev/ttyACM0 -b 38400"
}

# Funkcia na generovanie Lorem Ipsum textu
generate_lorem_ipsum() {
    local word_count=$1
    local lorem_words=(
        "lorem" "ipsum" "dolor" "sit" "amet" "consectetur" "adipiscing" "elit"
        "sed" "do" "eiusmod" "tempor" "incididunt" "ut" "labore" "et" "dolore"
        "magna" "aliqua" "enim" "ad" "minim" "veniam" "quis" "nostrud"
        "exercitation" "ullamco" "laboris" "nisi" "aliquip" "ex" "ea" "commodo"
        "consequat" "duis" "aute" "irure" "in" "reprehenderit" "voluptate"
        "velit" "esse" "cillum" "fugiat" "nulla" "pariatur" "excepteur" "sint"
        "occaecat" "cupidatat" "non" "proident" "sunt" "culpa" "qui" "officia"
        "deserunt" "mollit" "anim" "id" "est" "laborum" "at" "vero" "eos"
        "accusamus" "accusantium" "doloremque" "laudantium" "totam" "rem"
        "aperiam" "eaque" "ipsa" "quae" "ab" "illo" "inventore" "veritatis"
        "et" "quasi" "architecto" "beatae" "vitae" "dicta" "sunt" "explicabo"
        "nemo" "ipsam" "voluptatem" "quia" "voluptas" "aspernatur" "aut"
        "odit" "fugit" "sed" "quia" "consequuntur" "magni" "dolores" "eos"
        "qui" "ratione" "sequi" "nesciunt" "neque" "porro" "quisquam"
    )
    
    local text=""
    local words_per_line=12
    local current_line_words=0
    
    for ((i=1; i<=word_count; i++)); do
        local random_index=$((RANDOM % ${#lorem_words[@]}))
        local word="${lorem_words[$random_index]}"
        
        if [[ $current_line_words -eq 0 ]]; then
            word="$(tr '[:lower:]' '[:upper:]' <<< ${word:0:1})${word:1}"
        fi
        
        text+="$word"
        current_line_words=$((current_line_words + 1))
        
        if [[ $current_line_words -eq $words_per_line ]] || [[ $i -eq $word_count ]]; then
            text+=". "
            if [[ $i -ne $word_count ]]; then
                text+="\n"
            fi
            current_line_words=0
        else
            text+=" "
        fi
    done
    
    echo -e "$text"
}

# Funkcia na načítanie textu zo súboru
load_file_content() {
    local file_path="$1"
    local encoding="$2"
    
    if [[ ! -f "$file_path" ]]; then
        echo "Chyba: Súbor '$file_path' neexistuje!" >&2
        return 1
    fi
    
    if [[ ! -r "$file_path" ]]; then
        echo "Chyba: Nemáte oprávnenie na čítanie súboru '$file_path'!" >&2
        return 1
    fi
    
    local file_size=$(stat -f%z "$file_path" 2>/dev/null || stat -c%s "$file_path" 2>/dev/null)
    if [[ $file_size -eq 0 ]]; then
        echo "Upozornenie: Súbor '$file_path' je prázdny!" >&2
    elif [[ $file_size -gt 1048576 ]]; then
        echo "Upozornenie: Súbor '$file_path' je veľký ($(($file_size/1024))KB). Pokračovať? (y/N): " >&2
        read -n 1 -r
        echo "" >&2
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    
    if command -v iconv >/dev/null 2>&1 && [[ "$encoding" != "UTF-8" ]]; then
        iconv -f "$encoding" -t UTF-8 "$file_path" 2>/dev/null || {
            echo "Chyba: Nepodarilo sa konvertovať kódovanie z $encoding!" >&2
            echo "Pokúšam sa načítať ako UTF-8..." >&2
            cat "$file_path"
        }
    else
        cat "$file_path"
    fi
}

# Funkcia na detekciu typu portu
detect_port_type() {
    local port="$1"
    
    if [[ "$port" =~ ^/dev/lp[0-9]+$ ]]; then
        echo "parallel"
    elif [[ "$port" =~ ^/dev/tty(S[0-9]+|USB[0-9]+|ACM[0-9]+|AMA[0-9]+)$ ]]; then
        echo "serial"
    else
        echo "unknown"
    fi
}

# Funkcia na kontrolu paralelného portu
check_parallel_port() {
    local port=$1
    
    if [[ ! -e "$port" ]]; then
        echo "Chyba: Paralelný port $port neexistuje!" >&2
        echo "Dostupné paralelné porty:" >&2
        ls -la /dev/lp* 2>/dev/null || echo "Žiadne paralelné porty neboli nájdené" >&2
        return 1
    fi
    
    if [[ ! -w "$port" ]]; then
        echo "Chyba: Nemáte oprávnenie na zápis do $port!" >&2
        echo "Skúste spustiť skript ako root alebo pridajte používateľa do skupiny lp:" >&2
        echo "sudo usermod -a -G lp \$USER" >&2
        return 1
    fi
    
    return 0
}

# Funkcia na kontrolu sériového portu
check_serial_port() {
    local port=$1
    
    if [[ ! -e "$port" ]]; then
        echo "Chyba: Sériový port $port neexistuje!" >&2
        echo "Dostupné sériové porty:" >&2
        ls -la /dev/tty{S,USB,ACM}* 2>/dev/null || echo "Žiadne sériové porty neboli nájdené" >&2
        return 1
    fi
    
    if [[ ! -r "$port" ]] || [[ ! -w "$port" ]]; then
        echo "Chyba: Nemáte oprávnenie na prístup k $port!" >&2
        echo "Skúste spustiť skript ako root alebo pridajte používateľa do skupiny dialout:" >&2
        echo "sudo usermod -a -G dialout \$USER" >&2
        return 1
    fi
    
    return 0
}

# Funkcia na konfiguráciu sériového portu
configure_serial_port() {
    local port="$1"
    local baud_rate="$2"
    local parity="$3"
    local data_bits="$4"
    local stop_bits="$5"
    local flow_control="$6"
    local verbose="$7"
    
    # Kontrola dostupnosti stty
    if ! command -v stty >/dev/null 2>&1; then
        echo "Chyba: Príkaz 'stty' nie je dostupný!" >&2
        return 1
    fi
    
    # Konverzia parametrov pre stty
    local stty_params="$baud_rate"
    
    # Dátové bity
    case "$data_bits" in
        7) stty_params+=" cs7" ;;
        8) stty_params+=" cs8" ;;
        *) echo "Chyba: Neplatné dátové bity: $data_bits" >&2; return 1 ;;
    esac
    
    # Parita
    case "$parity" in
        none) stty_params+=" -parenb" ;;
        even) stty_params+=" parenb -parodd" ;;
        odd) stty_params+=" parenb parodd" ;;
        *) echo "Chyba: Neplatná parita: $parity" >&2; return 1 ;;
    esac
    
    # Stop bity
    case "$stop_bits" in
        1) stty_params+=" -cstopb" ;;
        2) stty_params+=" cstopb" ;;
        *) echo "Chyba: Neplatné stop bity: $stop_bits" >&2; return 1 ;;
    esac
    
    # Riadenie toku
    case "$flow_control" in
        none) stty_params+=" -crtscts -ixon -ixoff" ;;
        hardware) stty_params+=" crtscts -ixon -ixoff" ;;
        software) stty_params+=" -crtscts ixon ixoff" ;;
        *) echo "Chyba: Neplatné riadenie toku: $flow_control" >&2; return 1 ;;
    esac
    
    # Ďalšie nastavenia
    stty_params+=" raw -echo"
    
    if [[ "$verbose" == "true" ]]; then
        echo "Konfigurujem sériový port $port s parametrami: $stty_params"
    fi
    
    # Aplikovanie nastavení
    if ! stty -F "$port" $stty_params 2>/dev/null; then
        echo "Chyba: Nepodarilo sa nakonfigurovať sériový port!" >&2
        return 1
    fi
    
    return 0
}

# Funkcia na formátovanie textu pre tlač
format_text_for_print() {
    local text="$1"
    local source_info="$2"
    local no_format="$3"
    local port_type="$4"
    
    if [[ "$no_format" == "true" ]]; then
        echo "$text"
    else
        local header="=== LOREM PRINTER ===\n"
        if [[ -n "$source_info" ]]; then
            header+="Zdroj: $source_info\n"
        fi
        header+="Port: $port_type\n"
        header+="Dátum: $(date '+%d.%m.%Y %H:%M:%S')\n"
        header+="$(printf '=%.0s' {1..50})\n\n"
        
        local footer="\n\n$(printf '=%.0s' {1..50})\n"
        footer+="=== KONIEC DOKUMENTU ===\n"
        
        # Pre sériové porty pridáme dodatočné riadenie
        if [[ "$port_type" == "serial" ]]; then
            footer+="\r\n\f"  # CR+LF + Form Feed
        else
            footer+="\f"  # Len Form Feed pre paralelné porty
        fi
        
        echo -e "${header}${text}${footer}"
    fi
}

# Funkcia na odoslanie textu na paralelný port
send_to_parallel_port() {
    local text="$1"
    local port="$2"
    local verbose="$3"
    
    if [[ "$verbose" == "true" ]]; then
        echo "Odosielam na paralelný port $port..."
    fi
    
    if echo -e "$text" > "$port" 2>/dev/null; then
        echo "Text bol úspešne odoslaný na paralelný port!"
        return 0
    else
        echo "Chyba pri odosielaní na paralelný port!" >&2
        return 1
    fi
}

# Funkcia na odoslanie textu na sériový port
send_to_serial_port() {
    local text="$1"
    local port="$2"
    local timeout="$3"
    local verbose="$4"
    
    if [[ "$verbose" == "true" ]]; then
        echo "Odosielam na sériový port $port s timeout $timeout sekúnd..."
    fi
    
    # Odoslanie s timeout
    if timeout "$timeout" bash -c "echo -e '$text' > '$port'" 2>/dev/null; then
        echo "Text bol úspešne odoslaný na sériový port!"
        
        # Krátke čakanie na dokončenie prenosu
        sleep 1
        return 0
    else
        echo "Chyba pri odosielaní na sériový port (možný timeout)!" >&2
        return 1
    fi
}

# Funkcia na zobrazenie náhľadu textu
show_preview() {
    local text="$1"
    local max_lines=10
    
    echo "=== NÁHĽAD TEXTU ==="
    local line_count=$(echo "$text" | wc -l)
    
    if [[ $line_count -le $max_lines ]]; then
        echo "$text"
    else
        echo "$text" | head -$max_lines
        echo "..."
        echo "(celkovo $line_count riadkov, $(echo "$text" | wc -w) slov)"
    fi
    echo ""
}

# Spracovanie argumentov
WORDS=$DEFAULT_WORDS
PARALLEL_PORT=""
SERIAL_PORT=""
FILE_PATH=""
NO_FORMAT=false
ENCODING="UTF-8"
BAUD_RATE=$DEFAULT_BAUD_RATE
PARITY="none"
DATA_BITS=8
STOP_BITS=1
FLOW_CONTROL="none"
TIMEOUT=5
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -w|--words)
            if [[ -n "$2" ]] && [[ "$2" =~ ^[0-9]+$ ]]; then
                WORDS="$2"
                shift 2
            else
                echo "Chyba: -w/--words vyžaduje číselný argument!" >&2
                exit 1
            fi
            ;;
        -p|--parallel)
            if [[ -n "$2" ]]; then
                PARALLEL_PORT="$2"
                shift 2
            else
                echo "Chyba: -p/--parallel vyžaduje argument!" >&2
                exit 1
            fi
            ;;
        -s|--serial)
            if [[ -n "$2" ]]; then
                SERIAL_PORT="$2"
                shift 2
            else
                echo "Chyba: -s/--serial vyžaduje argument!" >&2
                exit 1
            fi
            ;;
        -f|--file)
            if [[ -n "$2" ]]; then
                FILE_PATH="$2"
                shift 2
            else
                echo "Chyba: -f/--file vyžaduje cestu k súboru!" >&2
                exit 1
            fi
            ;;
        -b|--baud)
            if [[ -n "$2" ]] && [[ "$2" =~ ^[0-9]+$ ]]; then
                BAUD_RATE="$2"
                shift 2
            else
                echo "Chyba: -b/--baud vyžaduje číselný argument!" >&2
                exit 1
            fi
            ;;
        --parity)
            if [[ -n "$2" ]] && [[ "$2" =~ ^(none|even|odd)$ ]]; then
                PARITY="$2"
                shift 2
            else
                echo "Chyba: --parity musí byť none, even alebo odd!" >&2
                exit 1
            fi
            ;;
        --data-bits)
            if [[ -n "$2" ]] && [[ "$2" =~ ^[78]$ ]]; then
                DATA_BITS="$2"
                shift 2
            else
                echo "Chyba: --data-bits musí byť 7 alebo 8!" >&2
                exit 1
            fi
            ;;
        --stop-bits)
            if [[ -n "$2" ]] && [[ "$2" =~ ^[12]$ ]]; then
                STOP_BITS="$2"
                shift 2
            else
                echo "Chyba: --stop-bits musí byť 1 alebo 2!" >&2
                exit 1
            fi
            ;;
        --flow-control)
            if [[ -n "$2" ]] && [[ "$2" =~ ^(none|hardware|software)$ ]]; then
                FLOW_CONTROL="$2"
                shift 2
            else
                echo "Chyba: --flow-control musí byť none, hardware alebo software!" >&2
                exit 1
            fi
            ;;
        -t|--timeout)
            if [[ -n "$2" ]] && [[ "$2" =~ ^[0-9]+$ ]]; then
                TIMEOUT="$2"
                shift 2
            else
                echo "Chyba: -t/--timeout vyžaduje číselný argument!" >&2
                exit 1
            fi
            ;;
        -n|--no-format)
            NO_FORMAT=true
            shift
            ;;
        -e|--encoding)
            if [[ -n "$2" ]]; then
                ENCODING="$2"
                shift 2
            else
                echo "Chyba: -e/--encoding vyžaduje argument!" >&2
                exit 1
            fi
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Neznámy argument: $1" >&2
            show_help
            exit 1
            ;;
    esac
done

# Validácia argumentov
if [[ -z "$PARALLEL_PORT" ]] && [[ -z "$SERIAL_PORT" ]]; then
    echo "Chyba: Musíte špecifikovať buď paralelný (-p) alebo sériový (-s) port!" >&2
    exit 1
fi

if [[ -n "$PARALLEL_PORT" ]] && [[ -n "$SERIAL_PORT" ]]; then
    echo "Chyba: Nemôžete špecifikovať paralelný aj sériový port súčasne!" >&2
    exit 1
fi

if [[ -n "$FILE_PATH" ]] && [[ $WORDS -ne $DEFAULT_WORDS ]]; then
    echo "Upozornenie: Pri použití súboru sa parameter --words ignoruje." >&2
fi

if [[ $WORDS -lt 1 ]]; then
    echo "Chyba: Počet slov musí byť aspoň 1!" >&2
    exit 1
fi

# Určenie portu a typu
if [[ -n "$PARALLEL_PORT" ]]; then
    PORT="$PARALLEL_PORT"
    PORT_TYPE="parallel"
else
    PORT="$SERIAL_PORT"
    PORT_TYPE="serial"
fi

# Hlavný program
echo "=== Lorem Printer ==="

if [[ -n "$FILE_PATH" ]]; then
    echo "Režim: Tlačenie zo súboru"
    echo "Súbor: $FILE_PATH"
    echo "Kódovanie: $ENCODING"
else
    echo "Režim: Generovanie Lorem Ipsum"
    echo "Počet slov: $WORDS"
fi

echo "Port: $PORT ($PORT_TYPE)"
echo "Formátovanie: $([ "$NO_FORMAT" = true ] && echo "vypnuté" || echo "zapnuté")"

if [[ "$PORT_TYPE" == "serial" ]]; then
    echo "Sériové nastavenia: $BAUD_RATE baud, ${DATA_BITS}${PARITY:0:1}${STOP_BITS}, flow: $FLOW_CONTROL"
    echo "Timeout: $TIMEOUT sekúnd"
fi

echo ""

# Kontrola portu
if [[ "$PORT_TYPE" == "parallel" ]]; then
    if ! check_parallel_port "$PORT"; then
        exit 1
    fi
else
    if ! check_serial_port "$PORT"; then
        exit 1
    fi
    
    if ! configure_serial_port "$PORT" "$BAUD_RATE" "$PARITY" "$DATA_BITS" "$STOP_BITS" "$FLOW_CONTROL" "$VERBOSE"; then
        exit 1
    fi
fi

# Získanie textu
if [[ -n "$FILE_PATH" ]]; then
    echo "Načítavam obsah súboru..."
    if ! file_content=$(load_file_content "$FILE_PATH" "$ENCODING"); then
        exit 1
    fi
    
    if [[ -z "$file_content" ]]; then
        echo "Chyba: Súbor je prázdny alebo sa nepodarilo načítať obsah!" >&2
        exit 1
    fi
    
    final_text=$(format_text_for_print "$file_content" "$FILE_PATH" "$NO_FORMAT" "$PORT_TYPE")
    source_info="súboru $FILE_PATH"
else
    echo "Generujem Lorem Ipsum text..."
    lorem_content=$(generate_lorem_ipsum "$WORDS")
    final_text=$(format_text_for_print "$lorem_content" "Lorem Ipsum generátor" "$NO_FORMAT" "$PORT_TYPE")
    source_info="Lorem Ipsum generátora"
fi

# Zobrazenie náhľadu
show_preview "$final_text"

# Potvrdenie odoslania
read -p "Chcete odoslať tento text na tlačiareň? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [[ "$PORT_TYPE" == "parallel" ]]; then
        send_to_parallel_port "$final_text" "$PORT" "$VERBOSE"
    else
        send_to_serial_port "$final_text" "$PORT" "$TIMEOUT" "$VERBOSE"
    fi
else
    echo "Odoslanie zrušené."
    echo ""
    echo "Text môžete uložiť do súboru:"
    if [[ -n "$FILE_PATH" ]]; then
        echo "cp '$FILE_PATH' backup_$(basename "$FILE_PATH")"
    else
        echo "echo '$final_text' > output_$(date +%Y%m%d_%H%M%S).txt"
    fi
fi
