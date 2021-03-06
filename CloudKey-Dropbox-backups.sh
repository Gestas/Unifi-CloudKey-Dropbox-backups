#!/usr/bin/env bash
# See https://github.com/Gestas/Unifi-CloudKey-Dropbox-backups

set -o errexit
set -o pipefail

readonly TOKEN="$1"
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

### Optionally change these - 
readonly DEST_DIR="/backups"
readonly SRC_DIR="/data/autobackup"
readonly LOG_FILE="$SRC_DIR/cloudkey-backups-upload.log"


log() {
    local _now
    local _message

    _now="$(date --rfc-3339=seconds)"
    _message="$1"
    printf "%s\n" "$_now: $_message" >> "$LOG_FILE"
}

upload_backups() {
    local _f
    local _response_code

    # Upload the *.unf files
    for _f in "$SRC_DIR"/*.unf "$SRC_DIR"/*.json; do
        _response_code="$(do_upload "$_f" "add")"
        if [[ "$_response_code" -eq "200" ]]; then
            log "$_f uploaded to Dropbox."
        else 
            log "Backup of $_f failed to upload to Dropbox. Response code $_response_code"
            exit 1
        fi
    done

    # Upload the autobackup_meta.json file
    _f="$SRC_DIR/autobackup_meta.json"
    _response_code="$(do_upload "$_f" "overwrite")"
        if [[ "$_response_code" -eq "200" ]]; then
            log "$_f uploaded to Dropbox."
        else 
            log "Backup of $_f failed to upload to Dropbox. Response code $_response_code"
            exit 1
        fi
}

upload_log(){
    local _response_code

    _response_code="$(do_upload "$LOG_FILE" "overwrite")"
    if [[ "$_response_code" -ne "200" ]]; then
        printf "%s\n" "$_now: Unable to upload the log. Response code $_response_code"
        exit 1
    fi

}

do_upload() {
    local _f
    local _mode
    local _filename
    local _response_code

    _f="$1"
    _mode="$2"

    _filename="$(/usr/bin/basename "$_f")"
    _response_code=$(/usr/bin/curl -X POST -sL -w "%{http_code}" --output /dev/null https://content.dropboxapi.com/2/files/upload \
        --header "Authorization: Bearer $TOKEN" \
        --header "Dropbox-API-Arg: {\"path\": \"$DEST_DIR/$_filename\",\"mode\": \"$_mode\",\"autorename\": true,\"mute\": false,\"strict_conflict\": false}" \
        --header "Content-Type: application/octet-stream" \
        --data-binary @$_f)
    echo "$_response_code"
}

main() {
    printf "%s\n" "Starting $0"
    log "########## Starting upload ##########"
    upload_backups
    log "########## Complete #########"
    log " "
    /sbin/fsync "$LOG_FILE"
    upload_log
    printf "%s\n" "$0 complete"
    exit 0
}

main "$@"
