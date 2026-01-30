#!/usr/bin/env bash
# Install Fantasque Sans Mono Nerd Font
# Failures log warnings but don't break chezmoi apply

FONT_NAME="FantasqueSansMono"
NERD_FONTS_BASE_URL="https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts"

# All font variants
FONT_FILES=(
    "Regular/FantasqueSansMNerdFont-Regular.ttf"
    "Regular/FantasqueSansMNerdFontMono-Regular.ttf"
    "Regular/FantasqueSansMNerdFontPropo-Regular.ttf"
    "Bold/FantasqueSansMNerdFont-Bold.ttf"
    "Bold/FantasqueSansMNerdFontMono-Bold.ttf"
    "Bold/FantasqueSansMNerdFontPropo-Bold.ttf"
    "Italic/FantasqueSansMNerdFont-Italic.ttf"
    "Italic/FantasqueSansMNerdFontMono-Italic.ttf"
    "Italic/FantasqueSansMNerdFontPropo-Italic.ttf"
    "Bold-Italic/FantasqueSansMNerdFont-BoldItalic.ttf"
    "Bold-Italic/FantasqueSansMNerdFontMono-BoldItalic.ttf"
    "Bold-Italic/FantasqueSansMNerdFontPropo-BoldItalic.ttf"
)

warn() {
    echo "[WARN] $*" >&2
}

info() {
    echo "[INFO] $*"
}

# Determine font directory based on OS
get_font_dir() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "$HOME/Library/Fonts"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "$HOME/.local/share/fonts"
    else
        warn "Unsupported OS: $OSTYPE"
        return 1
    fi
}

# Download a single font file
download_font() {
    local font_path="$1"
    local dest_dir="$2"
    local filename
    filename=$(basename "$font_path")
    local dest_file="$dest_dir/$filename"
    local url="${NERD_FONTS_BASE_URL}/${FONT_NAME}/${font_path}"

    if [[ -f "$dest_file" ]]; then
        info "Already installed: $filename"
        return 0
    fi

    info "Downloading: $filename"
    if ! curl -fsSL --connect-timeout 10 --max-time 30 -o "$dest_file" "$url"; then
        warn "Failed to download: $filename"
        rm -f "$dest_file"  # Clean up partial download
        return 1
    fi

    return 0
}

main() {
    local font_dir
    if ! font_dir=$(get_font_dir); then
        warn "Could not determine font directory, skipping font installation"
        exit 0
    fi

    if ! command -v curl >/dev/null 2>&1; then
        warn "curl is required to download fonts, skipping font installation"
        exit 0
    fi

    # Create font directory if it doesn't exist
    if ! mkdir -p "$font_dir"; then
        warn "Could not create font directory: $font_dir"
        exit 0
    fi

    info "Installing Fantasque Sans Mono Nerd Font to: $font_dir"

    local success_count=0
    local fail_count=0

    for font_path in "${FONT_FILES[@]}"; do
        if download_font "$font_path" "$font_dir"; then
            ((success_count++))
        else
            ((fail_count++))
        fi
    done

    # Refresh font cache on Linux
    if [[ "$OSTYPE" == "linux-gnu"* ]] && command -v fc-cache >/dev/null 2>&1; then
        info "Refreshing font cache..."
        if ! fc-cache -f "$font_dir"; then
            warn "Failed to refresh font cache"
        fi
    fi

    info "Font installation complete: $success_count succeeded, $fail_count failed"

    if [[ $fail_count -gt 0 ]]; then
        warn "Some fonts failed to install. You may need to install them manually."
    fi

    # Always exit 0 so chezmoi continues
    exit 0
}

main
