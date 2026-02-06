# YCLIENTS Skill for OpenClaw

Skill для [OpenClaw](https://github.com/openclaw/openclaw) — интеграция с CRM-системой [YCLIENTS](https://www.yclients.com). Позволяет агенту получать данные о расписании мастеров и записях клиентов.

## Возможности

- **Рабочие мастера на дату** — список активных сотрудников, работающих в указанный день (уволенные и скрытые отсеиваются автоматически)
- **Записи за период** — список бронирований с именем мастера, услугами, чистой длительностью и длительностью слота (с техническим перерывом)

## Требования

- `curl`, `jq`
- Токены YCLIENTS API (partner token, user token, company ID)

## Установка

1. Склонируйте репозиторий в директорию skills:
   ```bash
   cd /path/to/openclaw
   git clone git@github.com:xor777/openclaw-yclients-skill.git skills/yclients
   ```

2. Пропишите настройки в OpenClaw:
   ```bash
   openclaw config set skills.entries.yclients.path "skills/yclients"
   openclaw config set skills.entries.yclients.env.YCLIENTS_PARTNER_TOKEN "ваш-partner-token"
   openclaw config set skills.entries.yclients.env.YCLIENTS_USER_TOKEN "ваш-user-token"
   openclaw config set skills.entries.yclients.env.YCLIENTS_COMPANY_ID "ваш-company-id"
   ```

3. Перезапустите агента

## Использование

### Рабочие мастера

```bash
scripts/yclients.sh working-staff 2026-02-10
```

Ответ:
```json
[
  {
    "id": 2874402,
    "name": "Анна",
    "specialization": "Массажист",
    "position": "Старший мастер"
  }
]
```

### Записи клиентов

```bash
# За период
scripts/yclients.sh records 2026-02-01 2026-02-28

# По конкретному мастеру
scripts/yclients.sh records 2026-02-01 2026-02-28 2874402
```

Ответ:
```json
[
  {
    "id": 1525419235,
    "staff_id": 2874402,
    "staff_name": "Анна",
    "datetime": "2026-02-06 20:30:00",
    "services": [
      { "title": "Релакс ойл - 1 час", "cost": 5300 }
    ],
    "duration_hours": 1,
    "slot_hours": 1.25,
    "comment": ""
  }
]
```

- `duration_hours` — чистая длительность услуги
- `slot_hours` — длительность слота с техническим перерывом

## API-запросы

| Команда | Запросов к API |
|---------|---------------|
| `working-staff` | 1 + N (N = кол-во активных сотрудников) |
| `records` | 3 (staff + services + records) |

Между запросами выдерживается пауза 200мс (rate-limit YCLIENTS — 5 req/sec).

## Лицензия

MIT
