#!/bin/bash

# Lorem Ipsum generátor s paralelným portom
# Použitie: ./lorem_printer.sh [počet_slov] [paralelný_port]

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
    echo "  -h, --help           Zobrazí túto nápovedu"
    echo ""
    echo "Príklady:"
    echo "  $0 -w 100             Generuje 100 slov"
    echo "  $0 -w 200 -p /dev/lp1 Generuje 200 slov a pošle na /dev/lp1"
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

# Funkcia na odoslanie textu na tlačiareň
send_to_printer() {
    local text="$1"
    local port="$2"
    
    echo "Odosielam text na tlačiareň cez $port..."
    
    # Pridanie hlavičky a pätičky
    local header="=== LOREM IPSUM TEXT ===\n"
    local footer="\n=== KONIEC TEXTU ===\n\f"  # \f = form feed (nová stránka)
    
    # Odoslanie na tlačiareň
    if echo -e "${header}${text}${footer}" > "$port" 2>/dev/null; then
        echo "Text bol úspešne odoslaný na tlačiareň!"
    else
        echo "Chyba pri odosielaní na tlačiareň!" >&2
        return 1
    fi
}

# Spracovanie argumentov
WORDS=$DEFAULT_WORDS
PORT=$DEFAULT_PORT

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

# Validácia počtu slov
if [[ $WORDS -lt 1 ]]; then
    echo "Chyba: Počet slov musí byť aspoň 1!" >&2
    exit 1
fi

# Hlavný program
echo "=== Lorem Ipsum generátor pre paralelný port ==="
echo "Počet slov: $WORDS"
echo "Paralelný port: $PORT"
echo ""

# Kontrola paralelného portu
if ! check_parallel_port "$PORT"; then
    exit 1
fi

# Generovanie textu
echo "Generujem Lorem Ipsum text..."
lorem_text=$(generate_lorem_ipsum "$WORDS")

# Zobrazenie náhľadu
echo ""
echo "=== NÁHĽAD TEXTU ==="
echo "$lorem_text" | head -5
if [[ $(echo "$lorem_text" | wc -l) -gt 5 ]]; then
    echo "..."
    echo "(celkovo $(echo "$lorem_text" | wc -l) riadkov)"
fi
echo ""

# Potvrdenie odoslania
read -p "Chcete odoslať tento text na tlačiareň? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    send_to_printer "$lorem_text" "$PORT"
else
    echo "Odoslanie zrušené."
    echo ""
    echo "Text môžete uložiť do súboru:"
    echo "echo '$lorem_text' > lorem_ipsum.txt"
fi