#!/bin/sh

help_information() {
    echo "Usage: "
    echo ""
    echo -e "\033[1mOptions:\033[0m"
    echo ""
    echo -e "\033[1mFor server (device) connection:\033[0m"
    echo ""
    echo "-si,   --server-ip                    [requirement]"
    echo -e "\n\tIP address of device (server side)"
    echo""
    echo "-su,   --server-username              [optional, default:admin]"
    echo -e "\n\tUsername to login to device, need for session ID request"
    echo""
    echo "-sp,   --server-password              [optional, default: Gemtek%40123 (mean Gemtek@123)]"
    echo -e "\n\tPassword to login to device, need for session ID request"
    echo -e "\n\tReference for Percent-encoding URL: \e[4mhttps://developer.mozilla.org/en-US/docs/Glossary/Percent-encoding\e[0m"
    echo""

    echo -e "\033[1mFor debuglog.sh options:\033[0m"
    echo ""
    echo "-p,   --encode-password               [optional, default: Gemtek@123_<SN>]"
    echo -e "\n\tPassword to encode the delog log file output"
    echo""
    echo "-t,   --timestamp                     [optional, default: timestamp of device]"
    echo -e "\n\tFormat: %year%month%day_%hour%minute%second, Assign fixed timestamp for debug log file output"
    echo""
    echo "-i,   --info                          [optional, default: Full logs]"
    echo -e "\n\tAssign specific information for debug log file output"
    echo""
    echo "-h,   --help"
    echo -e "\n\tDisplay help message"
    echo ""
    echo ""
    echo "Available information (-i or --info option):"
    echo "  version_and_hardware_info : Information about hardware and system version."
    echo "  backup_config             : Backup configuration files."
    echo "  proc_file                 : Information from '/proc' folder."
    echo "  cpu_load_and_process      : Information about CPU and processes."
    echo "  interface_and_connection  : Information about network interfaces and connections."
    echo "  iptables_func             : NAT iptables information."
    echo "  system_logs               : System logs."
    echo "  general_logs              : General logs and configurations."
    echo "  memory                    : Information about memory and disk space."
    echo "  registers                 : Information about registers (to be updated)."
    echo "  switch_cli_func           : Information about XGMAC (to be updated)."
    echo "  ethtool_func              : Information about Ethernet network devices."
    echo "  wifi_logs                 : Information about Wifi configuration and status."
    echo ""
    echo -e "\033[1mExamples:\033[0m"
    echo "* Short version:"
    echo "sudo ./run_debug.sh -I 192.168.1.1 -U admin -P Gemtek%40123 -p GemtekUser -t 20240411_110530 -i \"version_and_hardware_info backup_config iptables_func\""
    echo ""
    echo "* Long version:"
    echo "sudo ./run_debug.sh --server-ip 192.168.1.1 --server-username admin --server-password Gemtek%40123 --encode-password GemtekUser --timestamp 20240411_110530 --info \"version_and_hardware_info backup_config iptables_func\""
    echo ""
}

HANDSHAKE_FOLDER="handshake"
LOG_FOLDER="debug_log"

# ...Scripts start...


# ============================
#       Parse arguments
# ============================

# Script starts to run here

# If no argument
if [ "$#" -eq 0 ]; then
    help_information
    exit 1
fi

# init param
SERVER_IP=""
SERVER_USERNAME="admin"
SERVER_PASSWORD="Gemtek%40123"
ENCODE_PASSWORD=""
TIMESTAMP=""
INFO=""

# Parse options & argument from input
while getopts ":I:U:P:p:t:i:h-:" opt; do
  case "${opt}" in
  # Long version
    # Options for server connection
    I)
        SERVER_IP="$OPTARG"
        ;;
    U)
        SERVER_USERNAME="$OPTARG"
        ;;
    P)
        SERVER_PASSWORD="$OPTARG"
        ;;
    
    # Option for debuglog.sh
    p)
        ENCODE_PASSWORD="$OPTARG"
        ;;    
    t)
        TIMESTAMP="$OPTARG"
        ;;    
    i)
        INFO="$OPTARG"
        ;;
    
    # helper
    h)
        help_information
        exit
        ;;  

    # Longer version
    -)
        case "${OPTARG}" in
            server-ip)
                SERVER_IP="$OPTARG"
                ;;
            server-username)
                SERVER_USERNAME="$OPTARG"
                ;;
            server-password)
                SERVER_PASSWORD="$OPTARG"
                ;;
            encode-password)
                ENCODE_PASSWORD="$OPTARG"
                ;;    
            timestamp)
                TIMESTAMP="$OPTARG"
                ;;    
            infor)
                INFO="$OPTARG"
                ;;
            help)
                help_information
                exit
                ;;  
        esac
        ;;

    # Error argument
    \?)
        echo "Invalid option: -$OPTARG"
        echo "sudo ./run_debug.sh -h for help"
        exit 1 # command not found
        ;;
    :)
        echo "Option -$OPTARG requires an argument."
        echo "sudo ./run_debug.sh -h for help"
        exit 1 # 
        ;;
    esac
done

echo "[INPUT] Server IP: $SERVER_IP"
echo "[INPUT] Username: $SERVER_USERNAME"
echo "[INPUT] Password: $SERVER_PASSWORD"
echo ""
echo "[INPUT] Password for encoding input: $ENCODE_PASSWORD"
echo "[INPUT] Timestamp input: $TIMESTAMP"
echo "[INPUT] Information require input: $INFO"
echo ""


# ============================
#       Init & parser
# ============================
SERVER_RESPONSE_FILE="$HANDSHAKE_FOLDER/server_response.txt"
SESSION_ID_FILE="$HANDSHAKE_FOLDER/session_id.txt"
TOKEN_RESPONSE_FILE="$HANDSHAKE_FOLDER/token_response.txt"
CSRF_TOKEN_FILE="$HANDSHAKE_FOLDER/csrf_token.txt"
RESULT_FILE="$HANDSHAKE_FOLDER/result.txt"

if [ ! -d $HANDSHAKE_FOLDER ]; then
    sudo mkdir $HANDSHAKE_FOLDER
else
    # Clear
    sudo rm $HANDSHAKE_FOLDER/*
fi

if [ ! -d $LOG_FOLDER ]; then
    sudo mkdir $LOG_FOLDER
fi


# ============================
#       Start session
# ============================
# === 1. Get sessionID
# --> Output: SERVER_RESPONSE_FILE
echo -e "[1.] Get SessionID"
GET_SESSION_ID_REQ="https://$SERVER_IP?username=$SERVER_USERNAME&password=$SERVER_PASSWORD"
echo ">>>>>Send request: $GET_SESSION_ID_REQ"
wget --no-check-certificate --auth-no-challenge --server-response --method GET --timeout=5 --tries=3 $GET_SESSION_ID_REQ 2>$SERVER_RESPONSE_FILE 1>/dev/null -O /dev/null
# Check if wget failed after number of tries
if [ $? -ne 0 ]; then
    echo "No response from $SERVER_IP. IP may be invalid or unreachable."
    exit 1
fi
echo -e "\t --> Success"


# === 2. Extract sessionID
# --> Output: SESSION_ID_FILE
grep 'Set-Cookie: Session-Id' $SERVER_RESPONSE_FILE | awk -F 'Session-Id=' '{print $2}' | cut -d ';' -f1 > $SESSION_ID_FILE

# === 3. Get csrf token from using sessionID, integrate with extract sessionID command
# --> Output: TOKEN_RESPONSE_FILE
echo -e "\n[2.] Get CSRF token"
GET_CSRF_TOKEN_REQ="https://$SERVER_IP/cgi/cgi_get?Objective=CSToken"
echo ">>>>> Send request: $GET_CSRF_TOKEN_REQ"
wget --no-check-certificate --auth-no-challenge --header "Cookie: Session-Id=$(cat $SESSION_ID_FILE)" --server-response --method GET --timeout=5 --tries=3 $GET_CSRF_TOKEN_REQ 2>$TOKEN_RESPONSE_FILE 1>/dev/null -O /dev/null

echo -e "\t --> Success"


# === 4. Extract csrf token
# --> Output: CSRF_TOKEN_FILE
grep 'X-Csrf-Token:' $TOKEN_RESPONSE_FILE | awk '{print $2}' > $CSRF_TOKEN_FILE


# === 5. Start to use any request -- running debug tool, timeout = 0 mean disable all timeout
# --> Output: RESULT_FILE
echo -e "\n[3.] Run debuglog.sh ... Please wait (about 1 minute) ..."
touch $RESULT_FILE
#Parse Params
PARAMS="?"
PARAMS+="enpwd=$ENCODE_PASSWORD"
PARAMS+="&time=$TIMESTAMP"
PARAMS+="&info=${INFO// /+}"
RUN_DEBUG_URL="https://$SERVER_IP/hidden/debug/debuglog.sh$PARAMS"

echo ">>>>> Send request: $RUN_DEBUG_URL"

# wget -q --no-check-certificate --auth-no-challenge --header "Cookie: Session-Id=$(cat $SESSION_ID_FILE)" --header "X-Requested-With: XMLHttpRequest" --header "X-Csrf-Token: $(cat $CSRF_TOKEN_FILE)" --server-response --method GET --timeout=0 "https://$SERVER_IP/debug/debuglog.sh" -O $RESULT_FILE >/dev/null 2>&1
curl -k -H "Cookie: Session-Id=$(cat $SESSION_ID_FILE)" -H "X-Requested-With: XMLHttpRequest" -H "X-Csrf-Token: $(cat $CSRF_TOKEN_FILE)" $RUN_DEBUG_URL -o $RESULT_FILE

echo "<<<<< Result:"
cat $RESULT_FILE
echo -e "\t --> Success"


# === 6. Get debug log file
echo -e "\n[4.] Get debug log file"
DEBUG_FILE=$(tail -n 1 $RESULT_FILE)
GET_DEBUG_LOG_FILE="https://$SERVER_IP/hidden/debug/output/$DEBUG_FILE"
echo ">>>>> Send request: $GET_DEBUG_LOG_FILE"

wget -q --show-progress --no-check-certificate --auth-no-challenge --header "Cookie: Session-Id=$(cat $SESSION_ID_FILE)" --header "X-Requested-With: XMLHttpRequest" --header "X-Csrf-Token: $(cat $CSRF_TOKEN_FILE)" --method GET --timeout=15 --tries=3 $GET_DEBUG_LOG_FILE

echo -e "\t --> Success"


# === 7. Extract serial number to decode the file
echo -e "\n[5.] Decode debug log"

SERIAL_NUMBER=$(echo "$DEBUG_FILE" | cut -d'_' -f2)
TAR_FILE=${DEBUG_FILE%.enc}
if [ -n "$ENCODE_PASSWORD" ]; then
    DECODE_PASSWORD=$ENCODE_PASSWORD
else
    DECODE_PASSWORD="Gemtek@123_$SERIAL_NUMBER"
fi
sudo bash -c "echo -n '$DECODE_PASSWORD' | openssl aes-256-cbc -d -a -pbkdf2 -in '$DEBUG_FILE' -out '$TAR_FILE' -pass stdin"

# Move tar file to right place and remove the encoded one
sudo rm $DEBUG_FILE
sudo mv $TAR_FILE $LOG_FOLDER
echo -e "\t --> Success"
echo -e "\t --> $TAR_FILE is stored in ./$LOG_FOLDER/"