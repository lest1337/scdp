#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT_NAME="${0##*/}"

usage() {
    cat <<EOF
Usage: $SCRIPT_NAME [options]

Affiche l'adresse IP publique de cette machine (utile pour scdp recv).

Options:
  -c, --copy     Copie l'IP dans le presse-papiers (macOS: pbcopy)
  -s, --service  Service à utiliser (défaut: auto)
  -h, --help     Affiche cette aide

Services disponibles: ifconfig.me, ipify, icanhazip, ident.me
EOF
}

require_gum() {
    if ! command -v gum >/dev/null 2>&1; then
        echo "Erreur: gum n'est pas installé." >&2
        echo "Installation: brew install gum" >&2
        exit 1
    fi
}

fetch_ip() {
    local url="$1"
    curl -fsS --max-time 10 "$url" | tr -d '[:space:]'
}

fetch_with_service() {
    local service="$1"
    case "$service" in
        ifconfig.me) fetch_ip "https://ifconfig.me/ip" ;;
        ipify)       fetch_ip "https://api.ipify.org" ;;
        icanhazip)   fetch_ip "https://ipv4.icanhazip.com" ;;
        ident.me)    fetch_ip "https://v4.ident.me" ;;
        *)
            gum log --level error "Service inconnu: $service"
            exit 1
            ;;
    esac
}

fetch_auto() {
    local services=(ifconfig.me ipify icanhazip ident.me)
    local svc ip

    for svc in "${services[@]}"; do
        if ip="$(fetch_with_service "$svc" 2>/dev/null)" && [[ -n "$ip" ]]; then
            echo "$ip"
            return 0
        fi
    done
    return 1
}

copy_ip() {
    local ip="$1"
    if command -v pbcopy >/dev/null 2>&1; then
        printf '%s' "$ip" | pbcopy
        gum style --foreground 10 "Copié dans le presse-papiers."
        return 0
    elif command -v wl-copy >/dev/null 2>&1; then
        printf '%s' "$ip" | wl-copy
        gum style --foreground 10 "Copié dans le presse-papiers."
        return 0
    elif command -v xclip >/dev/null 2>&1; then
        printf '%s' "$ip" | xclip -selection clipboard
        gum style --foreground 10 "Copié dans le presse-papiers."
        return 0
    fi
    gum log --level warn "Aucun outil de copie trouvé (pbcopy, wl-copy, xclip)."
    return 1
}

main() {
    local do_copy=0
    local service="auto"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -c|--copy)    do_copy=1; shift ;;
            -s|--service) service="${2:?option --service requiert un argument}"; shift 2 ;;
            -h|--help)    usage; exit 0 ;;
            *)            gum log --level error "Option inconnue: $1"; usage; exit 1 ;;
        esac
    done

    require_gum

    gum style \
        --border double \
        --border-foreground 212 \
        --padding "0 2" \
        "scdp — IP publique"

    local ip
    if [[ "$service" == "auto" ]]; then
        if ! ip="$(gum spin --spinner dot --title "Récupération de l'IP publique..." -- bash -c '
            services=(ifconfig.me ipify icanhazip ident.me)
            for svc in "${services[@]}"; do
                case "$svc" in
                    ifconfig.me) url="https://ifconfig.me/ip" ;;
                    ipify)       url="https://api.ipify.org" ;;
                    icanhazip)   url="https://ipv4.icanhazip.com" ;;
                    ident.me)    url="https://v4.ident.me" ;;
                esac
                if ip=$(curl -fsS --max-time 10 "$url" 2>/dev/null | tr -d "[:space:]") && [[ -n "$ip" ]]; then
                    echo "$ip"
                    exit 0
                fi
            done
            exit 1
        ')"; then
            gum log --level error "Impossible de récupérer l'IP publique (réseau ou services indisponibles)."
            exit 2
        fi
    else
        if ! ip="$(gum spin --spinner dot --title "Interrogation de $service..." -- bash -c '
            fetch() { curl -fsS --max-time 10 "$1" | tr -d "[:space:]"; }
            case "$1" in
                ifconfig.me) fetch "https://ifconfig.me/ip" ;;
                ipify)       fetch "https://api.ipify.org" ;;
                icanhazip)   fetch "https://ipv4.icanhazip.com" ;;
                ident.me)    fetch "https://v4.ident.me" ;;
                *) exit 1 ;;
            esac
        ' _ "$service")"; then
            gum log --level error "Échec avec le service: $service"
            exit 2
        fi
    fi

    echo
    gum style --bold --foreground 212 "IP publique"
    gum format --type code <<<"$ip"
    echo

    gum style --foreground 240 \
        "Utilisation avec scdp :" \
        "  scdp recv 9000    # sur cette machine" \
        "  scdp send $ip 9000 \"message\"   # depuis l'autre machine"

    if [[ "$do_copy" -eq 1 ]]; then
        copy_ip "$ip" || true
    elif [[ -t 0 ]] && gum confirm --affirmative "Copier" --negative "Non" "Copier l'IP dans le presse-papiers ?"; then
        copy_ip "$ip" || true
    fi
}

main "$@"
