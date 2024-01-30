cd /tmp/data_product

if [ "$1" ]; then
        DP="$1"
else
        echo "Missing argument. please provide DP name."
        exit 1
fi

/gravity-cli product ruleset delete ${DP} ${DP}Initialize -s gravity-nats:4222

/gravity-cli product ruleset delete ${DP} ${DP}Create -s gravity-nats:4222

/gravity-cli product ruleset delete ${DP} ${DP}Update -s gravity-nats:4222

/gravity-cli product ruleset delete ${DP} ${DP}Delete -s gravity-nats:4222

sleep 1
/gravity-cli product delete ${DP} -s gravity-nats:4222
