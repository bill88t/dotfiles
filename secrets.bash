scriptdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
encfile="$scriptdir/dotsecrets.bash.gpg"
plainfile="$scriptdir/dotsecrets.bash"

TMP="${TMPDIR:-/tmp}"

# Fallback if TMPDIR is set but unusable
[ -d "$TMP" ] && [ -w "$TMP" ] || TMP="/tmp"

decfile="$TMP/dotsecrets.$UID.bash"

GPGKEY="ECB6CC2EB44CEF708F41AF191BEF1BCEBA58EA33"

git_enc_config="$scriptdir/gitconfig.gpg"
git_plain_config="$scriptdir/gitconfig"
git_target_config="$HOME/.gitconfig"

git_enc_creds="$scriptdir/git-credentials.gpg"
git_plain_creds="$scriptdir/git-credentials"
git_target_creds="$HOME/.git-credentials"

_load_secrets() {
    if [ -f "$plainfile" ]; then
        . "$plainfile"
        return 0
    fi

    if [ -f "$decfile" ]; then
        . "$decfile"
        return 0
    fi

    if command -v okc-gpg >/dev/null 2>&1; then
        if okc-gpg --decrypt --output "$decfile" "$encfile" 2>/dev/null; then
            chmod 600 "$decfile"
            . "$decfile"
            return 0
        fi
    else
        if timeout 1 gpg --quiet --batch --yes \
            --passphrase '' \
            --pinentry-mode=loopback \
            --decrypt --output "$decfile" "$encfile" 2>/dev/null; then
                chmod 600 "$decfile"
                . "$decfile"
                return 0
            fi
    fi

    echo "WARNING: Secrets could not be loaded. (GPG key locked or unavailable)"
    return 1
}

secrets-reload() {
    if [ -f "$plainfile" ]; then
        . "$plainfile"
        return 0
    fi

    if [ -f "$decfile" ]; then
        . "$decfile"
        return 0
    fi

    if command -v okc-gpg >/dev/null 2>&1; then
        if okc-gpg --decrypt --output "$decfile" "$encfile"; then
            chmod 600 "$decfile"
            . "$decfile"
            return 0
        fi
    else
        if gpg --use-agent --try-secret-key "$GPGKEY" \
               --decrypt --output "$decfile" "$encfile"; then
            chmod 600 "$decfile"
            . "$decfile"
            return 0
        fi
    fi

    echo "WARNING: Failed to reload secrets. (GPG key locked or unavailable)"
    return 1
}

secrets-decrypt() {
    if [ -f "$plainfile" ]; then
        echo "ERROR: $plainfile already exists, refusing to overwrite"
        return 1
    fi
    if command -v okc-gpg >/dev/null 2>&1; then
        if okc-gpg --decrypt --output "$plainfile" "$encfile"; then
            chmod 600 "$plainfile"
            rm -f "$encfile"
            echo "NOTICE: Decrypted to $plainfile and removed $encfile"
            if [ -f "$decfile" ]; then
                rm "$decfile"
            fi
        else
            echo "ERROR: Failed to decrypt $encfile"
            return 1
        fi
    else
        if gpg --quiet --decrypt --output "$plainfile" "$encfile"; then
            chmod 600 "$plainfile"
            rm -f "$encfile"
            echo "NOTICE: Decrypted to $plainfile and removed $encfile"
            if [ -f "$decfile" ]; then
                rm "$decfile"
            fi
        else
            echo "ERROR: Failed to decrypt $encfile"
            return 1
        fi
    fi
}

secrets-encrypt() {
    if [ ! -f "$plainfile" ]; then
        echo "ERROR: $plainfile not found."
        return 1
    fi

    cp -v "$plainfile" "$decfile"
    if command -v okc-gpg >/dev/null 2>&1; then
        if okc-gpg --output "$encfile" --encrypt --recipient "$GPGKEY" "$plainfile"; then
            chmod 600 "$encfile"
            rm -f "$plainfile"
            echo "NOTICE: Encrypted to $encfile and removed $plainfile"
        else
            echo "ERROR: Failed to encrypt $plainfile"
            return 1
        fi
    else
        if gpg --yes --output "$encfile" --encrypt --recipient $GPGKEY "$plainfile"; then
            chmod 600 "$encfile"
            rm -f "$plainfile"
            echo "NOTICE: Encrypted to $encfile and removed $plainfile"
        else
            echo "ERROR: Failed to encrypt $plainfile"
            return 1
        fi
    fi
}

# Auto-load at shell startup
if [ -f "$plainfile" ] || [ -f "$encfile" ]; then
    _load_secrets || true
fi

git-secrets-install() {
    if [ -f "$git_enc_config" ]; then
        if gpg --quiet --decrypt --output "$git_target_config" "$git_enc_config"; then
            chmod 600 "$git_target_config"
            echo "NOTICE: Installed $git_target_config"
        else
            echo "ERROR: Failed to decrypt $git_enc_config"
            return 1
        fi
    fi

    if [ -f "$git_enc_creds" ]; then
        if gpg --quiet --decrypt --output "$git_target_creds" "$git_enc_creds"; then
            chmod 600 "$git_target_creds"
            echo "NOTICE: Installed $git_target_creds"
        else
            echo "ERROR: Failed to decrypt $git_enc_creds"
            return 1
        fi
    fi
}

git-secrets-decrypt() {
    if [ -f "$git_plain_config" ]; then
        echo "ERROR: $git_plain_config already exists, refusing to overwrite"
    elif [ -f "$git_enc_config" ]; then
        if gpg --quiet --decrypt --output "$git_plain_config" "$git_enc_config"; then
            chmod 600 "$git_plain_config"
            rm -f "$git_enc_config"
            echo "NOTICE: Decrypted to $git_plain_config and removed $git_enc_config"
        else
            echo "ERROR: Failed to decrypt $git_enc_config"
        fi
    fi

    if [ -f "$git_plain_creds" ]; then
        echo "ERROR: $git_plain_creds already exists, refusing to overwrite"
    elif [ -f "$git_enc_creds" ]; then
        if gpg --quiet --decrypt --output "$git_plain_creds" "$git_enc_creds"; then
            chmod 600 "$git_plain_creds"
            rm -f "$git_enc_creds"
            echo "NOTICE: Decrypted to $git_plain_creds and removed $git_enc_creds"
        else
            echo "ERROR: Failed to decrypt $git_enc_creds"
        fi
    fi
}

git-secrets-encrypt() {
    if [ -f "$git_plain_config" ]; then
        if gpg --yes --output "$git_enc_config" --encrypt --recipient "$GPGKEY" "$git_plain_config"; then
            chmod 600 "$git_enc_config"
            rm -f "$git_plain_config"
            echo "NOTICE: Encrypted to $git_enc_config and removed $git_plain_config"
        else
            echo "ERROR: Failed to encrypt $git_plain_config"
        fi
    fi

    if [ -f "$git_plain_creds" ]; then
        if gpg --yes --output "$git_enc_creds" --encrypt --recipient "$GPGKEY" "$git_plain_creds"; then
            chmod 600 "$git_enc_creds"
            rm -f "$git_plain_creds"
            echo "NOTICE: Encrypted to $git_enc_creds and removed $git_plain_creds"
        else
            echo "ERROR: Failed to encrypt $git_plain_creds"
        fi
    fi
}

l(){
    secrets-reload
}
