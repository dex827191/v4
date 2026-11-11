
#!/bin/bash

# ==============================
# PROFILE CONFIGURATION
# ==============================

rm -f /root/.profile

cat > /root/.profile <<'EOF'
if [ -n "$BASH_VERSION" ]; then
    if [ -f ~/.bashrc ]; then
        . ~/.bashrc
    fi
fi

mesg n || true
welcome
EOF

# ==============================
# CRON CONFIGURATION
# ==============================

setup_cron() {
    local cron_file="$1"
    local pekerjaan_cron="$2"

    if ! grep -Fq "$pekerjaan_cron" "$cron_file" 2>/dev/null; then
        echo "$pekerjaan_cron" > "$cron_file"
        chmod 644 "$cron_file"
    fi
}

setup_cron "/etc/cron.d/auto_update" \
"15 1 * * * root /usr/bin/auto_update"

setup_cron "/etc/cron.d/backup_otomatis" \
"15 23 * * * root /usr/bin/backupfile"

setup_cron "/etc/cron.d/delete_exp" \
"15 0 * * * root /usr/bin/xp"

# ==============================
# VERSION CHECK
# ==============================

cek_versi_baru() {
    versi_terbaru=$(curl -fsSL \
        https://raw.githubusercontent.com/dex827191/v4/main/update-cek) || {
        echo "Gagal mengambil versi terbaru."
        return 2
    }

    if [ -z "$versi_terbaru" ]; then
        echo "Versi terbaru kosong."
        return 2
    fi

    if [ ! -f /usr/bin/menu_version ]; then
        echo "1" > /usr/bin/menu_version
        echo "Version not found. Creating version 1."
    fi

    versi_saat_ini=$(cat /usr/bin/menu_version)

    if [[ "$versi_terbaru" != "$versi_saat_ini" ]]; then
        echo "Versi baru tersedia: $versi_terbaru"
        return 0
    else
        echo "Versi sudah up-to-date: $versi_saat_ini"
        return 1
    fi
}

# ==============================
# LOADING FUNCTION
# ==============================

fun_bar() {
    CMD="$1"
    rm -f /tmp/selesai_update

    (
        "$CMD" &&
        touch /tmp/selesai_update
    ) &
    PID=$!

    tput civis 2>/dev/null

    echo -ne "  Please Wait Loading ["

    while kill -0 "$PID" 2>/dev/null; do
        echo -ne "#"
        sleep 0.2
    done

    wait "$PID"
    RESULT=$?

    echo -e "]"

    tput cnorm 2>/dev/null

    if [ "$RESULT" -eq 0 ]; then
        echo "Update selesai."
    else
        echo "Update gagal."
    fi

    return "$RESULT"
}

# ==============================
# UPDATE FUNCTION
# ==============================

res1() {
    TMP_DIR=$(mktemp -d) || return 1

    echo "Mengunduh file update..."

    if ! curl -fL --retry 2 \
        https://raw.githubusercontent.com/dex827191/v4/main/Cdy/speedtest \
        -o "$TMP_DIR/speedtest"; then
        echo "Gagal mengunduh speedtest."
        rm -rf "$TMP_DIR"
        return 1
    fi

    if ! curl -fL --retry 2 \
        https://raw.githubusercontent.com/dex827191/v4/main/Cdy/menu.zip \
        -o "$TMP_DIR/menu.zip"; then
        echo "Gagal mengunduh menu.zip."
        rm -rf "$TMP_DIR"
        return 1
    fi

    mkdir -p "$TMP_DIR/extracted"

    echo "Memeriksa arsip ZIP..."

    if ! unzip -t "$TMP_DIR/menu.zip" >/dev/null 2>&1; then
        echo "ZIP tidak valid atau masih terenkripsi."
        rm -rf "$TMP_DIR"
        return 1
    fi

    echo "Mengekstrak file..."

    if ! unzip -oq "$TMP_DIR/menu.zip" -d "$TMP_DIR/extracted"; then
        echo "Ekstraksi gagal."
        rm -rf "$TMP_DIR"
        return 1
    fi

    if [ ! -d "$TMP_DIR/extracted/menu" ]; then
        echo "Folder menu tidak ditemukan dalam ZIP."
        rm -rf "$TMP_DIR"
        return 1
    fi

    # Install downloaded files
    install -m 755 "$TMP_DIR/speedtest" /usr/bin/speedtest

    cp -a "$TMP_DIR/extracted/menu/." /usr/bin/

    chmod +x /usr/bin/* 2>/dev/null

    # Update version after successful installation
    echo "$versi_terbaru" > /usr/bin/menu_version

    rm -rf "$TMP_DIR"

    # ==============================
    # TELEGRAM NOTIFICATION
    # ==============================

    if [ -f /etc/bot/.bot.db ]; then
        CHATID=$(grep -E "^#bot# " /etc/bot/.bot.db | cut -d ' ' -f 3)
        KEY=$(grep -E "^#bot# " /etc/bot/.bot.db | cut -d ' ' -f 2)

        if [ -n "$CHATID" ] && [ -n "$KEY" ]; then
            URL="https://api.telegram.org/bot${KEY}/sendMessage"

            TEXT="<code>◇━━━━━━━━━━━━━━◇</code>
<b>⚠️ UPDATE NOTIF ⚠️</b>
<code>◇━━━━━━━━━━━━━━◇</code>
<code>Auto Update Script Done</code>
<code>Versi : ${versi_terbaru}</code>
<code>◇━━━━━━━━━━━━━━◇</code>"

            curl -fsS --max-time 10 \
                -d "chat_id=$CHATID" \
                --data-urlencode "text=$TEXT" \
                -d "parse_mode=html" \
                "$URL" >/dev/null 2>&1
        fi
    fi

    return 0
}

# ==============================
# RUN UPDATE
# ==============================

jalankan_update() {
    cek_versi_baru
    STATUS=$?

    if [ "$STATUS" -eq 0 ]; then
        echo "Menjalankan update ke versi terbaru..."
        sleep 2
        fun_bar res1
    elif [ "$STATUS" -eq 1 ]; then
        echo "Tidak ada update yang diperlukan."
    else
        echo "Update dibatalkan karena gagal memeriksa versi."
        return 1
    fi
}

jalankan_update
