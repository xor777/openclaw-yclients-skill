#!/usr/bin/env bash
set -euo pipefail

API_BASE="https://api.yclients.com/api/v1"

# Validate required env vars
for var in YCLIENTS_PARTNER_TOKEN YCLIENTS_USER_TOKEN YCLIENTS_COMPANY_ID; do
  if [[ -z "${!var:-}" ]]; then
    echo "Error: $var is not set" >&2
    exit 1
  fi
done

COMPANY_ID="$YCLIENTS_COMPANY_ID"

# Rate-limited API request
first_request=true
api_request() {
  if [[ "$first_request" == true ]]; then
    first_request=false
  else
    sleep 0.2
  fi
  curl -sS --fail \
    -H "Authorization: Bearer $YCLIENTS_PARTNER_TOKEN, User $YCLIENTS_USER_TOKEN" \
    -H "Accept: application/vnd.yclients.v2+json" \
    "$@"
}

# --- working-staff <date> ---
cmd_working_staff() {
  local date="${1:?Usage: yclients.sh working-staff <date>}"

  # Fetch all staff, filter out fired and hidden
  local staff_json
  staff_json=$(api_request "$API_BASE/staff/$COMPANY_ID")

  local active_staff
  active_staff=$(echo "$staff_json" | jq -c '[.data // . | .[] | select(.fired == 0 and .hidden == 0) | {id, name, specialization, position}]')

  local ids
  ids=$(echo "$active_staff" | jq -r '.[].id')

  if [[ -z "$ids" ]]; then
    echo "[]"
    return
  fi

  local result="[]"

  while IFS= read -r staff_id; do
    local schedule_json
    schedule_json=$(api_request "$API_BASE/schedule/$COMPANY_ID/$staff_id/$date/$date")

    local is_working
    is_working=$(echo "$schedule_json" | jq '[.data // . | .[] | select(.is_working == 1)] | length')

    if [[ "$is_working" -gt 0 ]]; then
      result=$(echo "$result" | jq --argjson staff "$(echo "$active_staff" | jq ".[] | select(.id == $staff_id)")" '. + [$staff]')
    fi
  done <<< "$ids"

  echo "$result" | jq .
}

# --- records <start_date> <end_date> [staff_id] ---
cmd_records() {
  local start_date="${1:?Usage: yclients.sh records <start_date> <end_date> [staff_id]}"
  local end_date="${2:?Usage: yclients.sh records <start_date> <end_date> [staff_id]}"
  local staff_id="${3:-}"

  # Fetch staff list for name lookup
  local staff_json
  staff_json=$(api_request "$API_BASE/staff/$COMPANY_ID")
  local staff_map
  staff_map=$(echo "$staff_json" | jq '[.data // . | .[] | {key: (.id | tostring), value: .name}] | from_entries')

  # Fetch services for clean duration lookup (service_id+staff_id → seance_length)
  local services_json
  services_json=$(api_request "$API_BASE/services/$COMPANY_ID")
  # Build map: "service_id:staff_id" → seance_length in seconds
  local duration_map
  duration_map=$(echo "$services_json" | jq '[.data // . | .[] | .id as $sid | .staff[]? | {key: "\($sid):\(.id)", value: .seance_length}] | from_entries')

  local url="$API_BASE/records/$COMPANY_ID?start_date=$start_date&end_date=$end_date&count=1000"
  if [[ -n "$staff_id" ]]; then
    url="$url&staff_id=$staff_id"
  fi

  local response
  response=$(api_request "$url")

  echo "$response" | jq --argjson staff_map "$staff_map" --argjson dur_map "$duration_map" '[.data // . | .[] | {
    id,
    staff_id,
    staff_name: ($staff_map[(.staff_id | tostring)] // "unknown"),
    datetime: .date,
    services: [.services[] | {title, cost}],
    duration_hours: (.staff_id as $sid | ([.services[] | $dur_map["\(.id):\($sid)"] // 0] | add) / 3600),
    slot_hours: (.seance_length / 3600),
    comment
  }]'
}

# --- Subcommand routing ---
case "${1:-}" in
  working-staff)
    shift
    cmd_working_staff "$@"
    ;;
  records)
    shift
    cmd_records "$@"
    ;;
  *)
    echo "Usage: yclients.sh <command> [args]" >&2
    echo "" >&2
    echo "Commands:" >&2
    echo "  working-staff <date>                        Staff working on a date" >&2
    echo "  records <start_date> <end_date> [staff_id]  Booking records for a period" >&2
    exit 1
    ;;
esac
