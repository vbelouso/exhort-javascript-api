#!/bin/sh

manifest_file_path="$1"
output_file_path="$2"

printf "Analysing the stack. Please wait..\n\n"

# Getting stack analysis report using exhort Javascript CLI.
report=$(exhort-javascript-api stack $manifest_file_path 2>error.log)

exit_code=$?

if [ $exit_code != 0 ]
then
  # In case of failure save only exit code into output file.
  jq -n {} | \
  jq --arg exit_code "$exit_code" '. + {exit_code: $exit_code}' > \
  $output_file_path

  # Print stderr message to console
  error_message=$(sed -n '/^Error:/p' error.log)
  printf "\n[ERROR] Red Hat Dependency Analytics failed with exit code $exit_code.\n$error_message"
  exit 1
else
  # In case of success print details from report into console
  printf "Red Hat Dependency Analytics task is being executed.\n"
  printf "=%.0s" {1..50}
  printf "\nRed Hat Dependency Analytics Report\n"
  printf "=%.0s" {1..50}
  printf "\n"
  printf "Total Scanned Dependencies            :  %s \n" "$(jq -r '.summary.dependencies.scanned' <<< $report)"
  printf "Total Scanned Transitive Dependencies :  %s \n" "$(jq -r '.summary.dependencies.transitive' <<< $report)"
  printf "Total Vulnerabilities                 :  %s \n" "$(jq -r '.summary.vulnerabilities.total' <<< $report)"
  printf "Direct Vulnerable Dependencies        :  %s \n" "$(jq -r '.summary.vulnerabilities.direct' <<< $report)"

  provider_status=$(jq -rc '.summary.providerStatuses[] | select(.provider == "snyk")' <<< $report)
  message=$(echo $provider_status | jq -r '.message')
  printf "Snyk Provider Status                  : "
  printf "%+40s" $message $'\n'  | sed 's/  */ /g'
  printf "Critical Vulnerabilities              :  %s \n" "$(jq -r '.summary.vulnerabilities.critical' <<< $report)"
  printf "High Vulnerabilities                  :  %s \n" "$(jq -r '.summary.vulnerabilities.high' <<< $report)"
  printf "Medium Vulnerabilities                :  %s \n" "$(jq -r '.summary.vulnerabilities.medium' <<< $report)"
  printf "Low Vulnerabilities                   :  %s \n" "$(jq -r '.summary.vulnerabilities.low' <<< $report)"
  printf "=%.0s" {1..50}

  # Save report along with exit code into output file.
  jq -n {} | \
  jq --slurpfile report <(echo "$report") '. + {report: $report[0]}' | \
  jq --arg exit_code "$exit_code" '. + {exit_code: $exit_code}' > \
  $output_file_path

  printf "\nFull report is saved into file: $output_file_path"
  printf "\nTask is completed."
fi
