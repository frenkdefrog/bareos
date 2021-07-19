#!/usr/bin/env bash

: "${WEBHOOK_URL:?WEBHOOK_URL needs to be set}"

job_type=$1
job_status=$2
job_client=$3
job_level=$4
job_name=$5
job_id=$6
color="#ff0015"

if [ "$job_status" = "OK" ] ;then
  color="#36a64f"
fi

msg_txt="$msg_icon: job_type $job_status of $job_client \
$job_level (${job_name})"

load_json()
{
    cat <<EOF
{
    "attachments": [
        {
            "fallback": "Biztonsági mentés eredménye - ${job_client}.",
            "color": "${color}",
	    "pretext": "A mentés lefutott a következő eredménnyel ($(date)):", 
	    "title": "BareOS JobID: ${job_id}",
            "title_link":"http://voldemort.webandservice.lan:9180/bareos-webui/job/details/${job_id}",
	    "fields": [
                {
                    "title": "Kliens:",
                    "value": "${job_client}",
                    "short": true 
                },
		{
		    "title": "Eredmény:",
		    "value": "${job_status}",
                    "short": true
		},
		{
                    "title": "Level:",
                    "value": "${job_level}",
                    "short": true
                },
		{
                    "title": "Job neve:",
                    "value": "${job_name}",
                    "short": true
                }


            ],
            "footer": "Slack API",
            "footer_icon": "https://platform.slack-edge.com/img/default_application_icon.png",
	    "ts": $(date +%s)	
        }
    ]
}
EOF
}

/usr/bin/curl -s -k -X POST \
    -H 'Content-Type: application/json' \
    -d "$(load_json)" \
    ${WEBHOOK_URL}
