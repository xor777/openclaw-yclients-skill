---
name: yclients
description: Query YCLIENTS CRM for working staff schedules and booking records.
metadata:
  {
    "openclaw":
      {
        "emoji": "💇",
        "requires":
          {
            "bins": ["curl", "jq"],
            "env":
              [
                "YCLIENTS_PARTNER_TOKEN",
                "YCLIENTS_USER_TOKEN",
                "YCLIENTS_COMPANY_ID",
              ],
          },
      },
  }
---

# YCLIENTS Skill

Query staff schedules and booking records from YCLIENTS CRM.

## Setup

1. Get your partner token from YCLIENTS developer portal
2. Get your user token (via YCLIENTS auth flow)
3. Get your company ID from the YCLIENTS dashboard
4. Set environment variables:
   ```bash
   export YCLIENTS_PARTNER_TOKEN="your-partner-token"
   export YCLIENTS_USER_TOKEN="your-user-token"
   export YCLIENTS_COMPANY_ID="your-company-id"
   ```

## Commands

### Working staff on a date

Returns a JSON array of staff members who are active and working on the given date. Filters out fired and hidden staff, then checks each active staff member's schedule.

```bash
{baseDir}/scripts/yclients.sh working-staff 2026-02-10
```

### Booking records for a period

Returns a JSON array of booking records for the given date range. Optionally filter by staff ID.

```bash
# All records for a date range
{baseDir}/scripts/yclients.sh records 2026-02-01 2026-02-28

# Records for a specific staff member
{baseDir}/scripts/yclients.sh records 2026-02-01 2026-02-28 12345
```

## Notes

- Rate-limited: the script enforces 200ms delays between API requests
- Authentication uses dual-token format: `Bearer {partner_token}, User {user_token}`
- Output is always JSON (array of objects or empty array)
- The script exits with code 1 and prints errors to stderr on API failures
