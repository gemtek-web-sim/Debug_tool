#!/bin/sh

help_information() {
    echo "Usage: sudo ./run_debug.sh -i <SERVER_IP_ADDRESS> -a <DEBUG_LOG_ARGUMENTS>"
    echo ""
    echo "Options:"
    echo "-i,[requirement]   --ip            :IP address of device"
    echo""
    echo "-a,[optional]      --arguments     :argument for debuglog tool, with specific arguments return corresponding response"
    echo ""
    echo "-h,                --help          :Display help message"
    echo ""
}

HANDSHAKE_FOLDER="handshake"
LOG_FOLDER="debug_log"

# ...Scripts start...


# ============================
#       Parse arrguments
# ============================
# Script starts to run here
if [ "$#" -eq 0 ]; then
    help_information
    exit 1
fi

while getopts "i:a:" opt; do
  case "${opt}" in
    i)
        SERVER_IP="$OPTARG"
        ;;
    a)
        DEBUG_ARGS="$OPTARG"
        ;;
    h)
        help_information
        exit 1
        ;;
    \?)
        echo "Invalid option: -$OPTARG"
        exit 1
        ;;
    :)
        echo "Option -$OPTARG requires an argument."
        exit 1
        ;;
    esac
done

echo "[INPUT] Server IP input: $SERVER_IP"
echo "[INPUT] Arguments input: $DEBUG_ARGS"
echo ""

# ============================
#       Start debug log
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

# 1. Get sessionID
# --> Output: SERVER_RESPONSE_FILE
curl -k --basic --head --request GET --max-time 5 --retry 5 "https://$SERVER_IP?username=admin&password=Gemtek%40123" -o $SERVER_RESPONSE_FILE

# Check if wget failed after number of tries
if [ $? -ne 0 ]; then
    echo "No response from $SERVER_IP. IP may be invalid or unreachable."
    exit 1
fi

# 2. Extract sessionID
# --> Output: SESSION_ID_FILE
grep 'Set-Cookie: Session-Id' $SERVER_RESPONSE_FILE | awk -F 'Session-Id=' '{print $2}' | cut -d ';' -f1 > $SESSION_ID_FILE

# 3. Get csrf token from using sessionID, integrate with extract sessionID command
# --> Output: TOKEN_RESPONSE_FILE
curl -k --basic --header "Cookie: Session-Id=$(cat $SESSION_ID_FILE)" --head --request GET --max-time 0 "https://$SERVER_IP/cgi/cgi_get?Objective=CSToken" 2>$TOKEN_RESPONSE_FILE -o /dev/null

# 4. Extract csrf token
# --> Output: CSRF_TOKEN_FILE
grep 'X-Csrf-Token:' $TOKEN_RESPONSE_FILE | awk '{print $2}' > $CSRF_TOKEN_FILE

# 5. Start to use any request -- running debug tool
# --> Output: RESULT_FILE
curl -k --basic --header "Cookie: Session-Id=$(cat $SESSION_ID_FILE)" --header "X-Requested-With: XMLHttpRequest" --header "X-Csrf-Token: $(cat $CSRF_TOKEN_FILE)" --head --request GET --max-time 0 "https://$SERVER_IP/debug/debuglog.sh" -o $RESULT_FILE

echo -e "\n>>> Result at running debug tool"
cat $RESULT_FILE

# 6. Get debug log file
echo -e "\n>>> Get debug log ..."
DEBUG_FILE=$(tail -n 1 $RESULT_FILE)

curl -k --basic --header "Cookie: Session-Id=$(cat $SESSION_ID_FILE)" --header "X-Requested-With: XMLHttpRequest" --header "X-Csrf-Token: $(cat $CSRF_TOKEN_FILE)" --head --request GET --max-time 0 "https://$SERVER_IP/debug/$DEBUG_FILE"

# 7. Extract serial number to decode the file
echo -e "\n>>> Decode debug log"

SERIAL_NUMBER=$(echo "$DEBUG_FILE" | cut -d'_' -f2)
TAR_FILE=${DEBUG_FILE%.enc}
sudo bash -c "echo -n 'Gemtek@123_$SERIAL_NUMBER' | openssl aes-256-cbc -d -a -pbkdf2 -in '$DEBUG_FILE' -out '$TAR_FILE' -pass stdin"

# Move tar file to right place and remove the encoded one
sudo rm $DEBUG_FILE
sudo mv $TAR_FILE $LOG_FOLDER