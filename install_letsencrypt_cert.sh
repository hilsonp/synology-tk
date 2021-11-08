# Your environment variables
CERTIFICATE_PATH=""

while getopts f: flag
do
    case "${flag}" in
        f) CERTIFICATE_PATH=${OPTARG};;
    esac
done

if [[ -z "${CERTIFICATE_PATH}" || ! -f "${CERTIFICATE_PATH}" ]]; then
    cat << __EO_HELP__

This script updates the Synology CRT with a renewed one then restarts services if needed.

You may use it in 2 ways:

1) With a share and a certificate name:
-s crt_share : Set Let's Encrypt share path (e.g. -s /volume1/LetsEncrypt)
-n crt_name :  Set Certificate name as displayed (case sensitive) on pfSense UI (e.g. -n Synology)

2) With the CRT full path:
-f crt_path : Set Let's Encrypt crt path (e.g. -f /volume1/docker/swag/etc/letsencrypt/live/my.domain.com/priv-fullchain-bundle.pem)

__EO_HELP__

    exit 1
fi

# Existing certificates are replaced below
DSM_MAJOR_VERSION=$([[ $(grep majorversion /etc/VERSION) =~ [0-9] ]] && echo ${BASH_REMATCH[0]})
DEFAULT_CERT_ROOT_DIR="/usr/syno/etc/certificate"
DEFAULT_ARCHIVE_CERT_DIR="${DEFAULT_CERT_ROOT_DIR}/_archive"
DEFAULT_ARCHIVE_CERT_NAME=${DEFAULT_ARCHIVE_CERT_DIR}/$(cat ${DEFAULT_ARCHIVE_CERT_DIR}/DEFAULT)
EXISTING_CERT_FOLDERS=$(find /usr/syno/etc/certificate -path */_archive/* -prune -o -name cert.pem -exec dirname '{}' \;)

_replacement_count=0
for _dir in ${EXISTING_CERT_FOLDERS} ${DEFAULT_ARCHIVE_CERT_NAME}; do
    echo "Replacing certificates from ${_dir}"
    _certs=$(find ${_dir} -name "cert.pem")
    for _cert in ${_certs}; do
        if [[ ${CERTIFICATE_PATH} -nt ${_cert} ]]; then
            echo "Replacing ${_cert} with ${CERTIFICATE_PATH}"
            cp -f ${CERTIFICATE_PATH} ${_cert}
            ((_replacement_count++))
        else
            echo "${_cert} skipped because it is not older than ${CERTIFICATE_PATH}"
        fi
    done
    echo
done

if [[ $_replacement_count -lt 1 ]]; then
    echo "No certificate updated."
    exit 0
else
    echo "$_replacement_count certificates updated. Restarting services."
    # Restart web server
    if [[ ${DSM_MAJOR_VERSION} == 6 ]]; then
        _svc_test_command="synoservicecfg --status"
        _svc_restart_command="synoservice --restart"
        _svcs="nginx nmbd smbd avahi pkgctl-WebStation.service"
    else
        _svc_test_command="systemctl is-active --quiet"
        _svc_restart_command="systemctl restart"
        _svcs="nginx pkg-synosamba-nmbd.service pkg-synosamba-smbd.service avahi pkgctl-WebStation.service"
    fi

    for _svc in $_svcs; do
        $_svc_test_command $_svc >/dev/null 2>&1
        if [[ $? -eq 0 ]]; then
            echo "Restarting service $_svc"
            ${_svc_restart_command} ${_svc}
        else
            echo "Service $_svc not running. Skipping."
        fi
    done
fi
exit 0