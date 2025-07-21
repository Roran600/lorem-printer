#!/bin/bash

# Lorem Ipsum generátor s paralelným portom + podpora súborov
# Použitie: ./lorem_printer.sh [počet_slov] [paralelný_port] alebo ./lorem_printer.sh -f súbor

# Predvolené hodnoty
DEFAULT_WORDS=50
DEFAULT_PORT="/dev/lp0"

# Funkcia na zobrazenie nápovedy
show_help() {
    echo "Použitie: $0 [MOŽNOSTI]"
    echo ""
    echo "MOŽNOSTI:"
    echo "  -w, --words POČET     Počet slov Lorem Ipsum textu (predvolené: $DEFAULT_WORDS)"
    echo "  -p, --port PORT       Paralelný port (predvolené: $DEFAULT_PORT)"
    echo "  -f, --file SÚBOR      Tlačiť obsah zo súboru namiesto generovania Lorem Ipsum"
    echo "  -n, --no-format       Neformátovať súbor (bez hlavičky/pätičky)"
    echo "  -e, --encoding KÓDOV  Kódovanie súboru (predvolené: UTF-8)"
    echo "  -h, --help           Zobrazí túto nápovedu"
    echo ""
    echo "REŽIMY:"
    echo "  1. Generovanie Lorem Ipsum:"
    echo "     $0 -w 100             Generuje 100 slov"
    echo "     $0 -w 200 -p /dev/lp1 Generuje 200 slov a pošle na /dev/lp1"
    echo ""
    echo "  2. Tlačenie zo súboru:"
    echo "     $0 -f dokument.txt    Tlačí obsah súboru"
    echo "     $0 -f text.txt -n     Tlačí bez formátovania"
    echo "     $0 -f text.txt -e ISO-8859-2  Tlačí s iným kódovaním"
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
        # Náhodný výber slova
        local random_index=$((RANDOM % ${#lorem_words[@]}))
        local word="${lorem_words[$random_index]}"

        # Prvé slovo vety s veľkým písmenom
        if [[ $current_line_words -eq 0 ]]; then
            word="$(tr '[:lower:]' '[:upper:]' <<< ${word:0:1})${word:1}"
        fi

        text+="$word"
        current_line_words=$((current_line_words + 1))

        # Pridanie interpunkcie a zalomenia riadkov
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

    # Kontrola existencie súboru
    if [[ ! -f "$file_path" ]]; then
        echo "Chyba: Súbor '$file_path' neexistuje!" >&2
        return 1
    fi

    # Kontrola čitateľnosti súboru
    if [[ ! -r "$file_path" ]]; then
        echo "Chyba: Nemáte oprávnenie na čítanie súboru '$file_path'!" >&2
        return 1
    fi

    # Kontrola veľkosti súboru
    local file_size=$(stat -f%z "$file_path" 2>/dev/null || stat -c%s "$file_path" 2>/dev/null)
    if [[ $file_size -eq 0 ]]; then
        echo "Upozornenie: Súbor '$file_path' je prázdny!" >&2
    elif [[ $file_size -gt 1048576 ]]; then  # 1MB
        echo "Upozornenie: Súbor '$file_path' je veľký ($(($file_size/1024))KB). Pokračovať? (y/N): " >&2
        read -n 1 -r
        echo "" >&2
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi

    # Načítanie obsahu s podporou kódovania
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

# Funkcia na kontrolu paralelného portu
check_parallel_port() {
    local port=$1

    if [[ ! -e "$port" ]]; then
        echo "Chyba: Paralelný port $port neexistuje!" >&2
        echo "Dostupné porty:" >&2
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

# Funkcia na formátovanie textu pre tlač
format_text_for_print() {
    local text="$1"
    local source_info="$2"
    local no_format="$3"

    if [[ "$no_format" == "true" ]]; then
        echo "$text"
    else
        local header="=== DOKUMENT PRE TLAČ ===\n"
        if [[ -n "$source_info" ]]; then
            header+="Zdroj: $source_info\n"
            header+="Dátum: $(date '+%d.%m.%Y %H:%M:%S')\n"
        fi
        header+="$(printf '=%.0s' {1..50})\n\n"

        local footer="\n\n$(printf '=%.0s' {1..50})\n"
        footer+="=== KONIEC DOKUMENTU ===\n\f"

        echo -e "${header}${text}${footer}"
    fi
}

# Funkcia na odoslanie textu na tlačiareň
send_to_printer() {
    local text="$1"
    local port="$2"

    echo "Odosielam text na tlačiareň cez $port..."

    # Odoslanie na tlačiareň
    if echo -e "$text" > "$port" 2>/dev/null; then
        echo "Text bol úspešne odoslaný na tlačiareň!"
    else
        echo "Chyba pri odosielaní na tlačiareň!" >&2
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
PORT=$DEFAULT_PORT
FILE_PATH=""
NO_FORMAT=false
ENCODING="UTF-8"

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
        -p|--port)
            if [[ -n "$2" ]]; then
                PORT="$2"
                shift 2
            else
                echo "Chyba: -p/--port vyžaduje argument!" >&2
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
if [[ -n "$FILE_PATH" ]] && [[ $WORDS -ne $DEFAULT_WORDS ]]; then
    echo "Upozornenie: Pri použití súboru sa parameter --words ignoruje." >&2
fi

if [[ $WORDS -lt 1 ]]; then
    echo "Chyba: Počet slov musí byť aspoň 1!" >&2
    exit 1
fi

# Hlavný program
echo "=== Lorem Ipsum generátor/tlačiareň pre paralelný port ==="

if [[ -n "$FILE_PATH" ]]; then
    echo "Režim: Tlačenie zo súboru"
    echo "Súbor: $FILE_PATH"
    echo "Kódovanie: $ENCODING"
    echo "Formátovanie: $([ "$NO_FORMAT" = true ] && echo "vypnuté" || echo "zapnuté")"
else
    echo "Režim: Generovanie Lorem Ipsum"
    echo "Počet slov: $WORDS"
fi

echo "Paralelný port: $PORT"
echo ""

# Kontrola paralelného portu
if ! check_parallel_port "$PORT"; then
    exit 1
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

    # Formátovanie textu
    final_text=$(format_text_for_print "$file_content" "$FILE_PATH" "$NO_FORMAT")
    source_info="súboru $FILE_PATH"
else
    echo "Generujem Lorem Ipsum text..."
    lorem_content=$(generate_lorem_ipsum "$WORDS")
    final_text=$(format_text_for_print "$lorem_content" "Lorem Ipsum generátor" "$NO_FORMAT")
    source_info="Lorem Ipsum generátora"
fi

# Zobrazenie náhľadu
show_preview "$final_text"

# Potvrdenie odoslania
read -p "Chcete odoslať tento text na tlačiareň? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    send_to_printer "$final_text" "$PORT"
else
    echo "Odoslanie zrušené."
    echo ""
    echo "Text môžete uložiť do súboru:"
    if [[ -n "$FILE_PATH" ]]; then
        echo "cp '$FILE_PATH' backup_$(basename "$FILE_PATH")"
    else
        echo "echo '$final_text' > lorem_ipsum_$(date +%Y%m%d_%H%M%S).txt"
    fi
fi
