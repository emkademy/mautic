# Mautic Docker notes

The upstream Mautic image starts as root (it needs to bind to port 80) and only drops privileges to `www-data` for PHP work. If you run console commands with the default `docker compose exec` (which uses root), it can create root-owned cache/log files and you will see errors like `SES quota cache dir not writable`.

## Fresh install checklist
- Copy/adjust env: set database and RabbitMQ values in `.env`, and mail/SES values in `.mautic_env` (set `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_DEFAULT_REGION`, and `MAUTIC_MAILER_DSN=mautic+ses+api://<key>:<secret>@default?region=<region>`).
- Build and start: `docker compose up -d --build`
- Complete the Mautic web installer (http://localhost:8080). The init job will clear cache, reload plugins, and register Amazon SES automatically.
- One-time verification (after install):  
  `docker compose exec mautic_web php bin/console cache:clear --env=prod`
  `docker compose exec --user=www-data mautic_web php bin/console mautic:plugins:reload --env=prod`  
  `docker compose exec --user=www-data mautic_web php bin/console dbal:run-sql "SELECT name,bundle FROM plugins WHERE bundle='AmazonSesBundle'" --env=prod`

## Setup
- Start the stack: `docker compose up -d`
- The image’s entrypoint will set correct ownership on startup. If you ever see the cache error, either restart `mautic_web` (`docker compose restart mautic_web`) or run the manual fix below.

## If you see “SES quota cache dir not writable”
1) Fix ownership (run as root):  
   `docker compose exec mautic_web chown -R www-data:www-data /var/www/html/var/cache /var/www/html/var/logs`
2) Clear cache as www-data to regenerate files with the right owner:  
   `docker compose exec --user=www-data mautic_web php /var/www/html/bin/console cache:clear --env=prod`
3) Tail the prod log to confirm the errors stop:  
   `docker compose exec mautic_web tail -f /var/www/html/var/logs/prod-$(date -u +%Y-%m-%d).php`

## Manual fix (if permissions break)
```bash
docker compose exec mautic_web chown -R www-data:www-data /var/www/html/var/cache /var/www/html/var/logs
```

## Run console commands safely
Always run console commands as `www-data` to avoid recreating root-owned cache files:
```bash
docker compose exec --user=www-data mautic_web php /var/www/html/bin/console cache:clear
docker compose exec --user=www-data mautic_cron php /var/www/html/bin/console mautic:emails:send
docker compose exec --user=www-data mautic_worker php /var/www/html/bin/console mautic:queue:process
```
If you need an interactive shell, use: `docker compose exec --user=www-data mautic_web bash`.

## Contact export emails not arriving
Mautic’s GUI “Export contacts” can queue the export and only emails the download link after the scheduled export processor runs.
This stack enables that via `cron/mautic` (runs `mautic:contacts:scheduled_export` every 3 minutes).

To run it once manually:
```bash
docker compose exec --user=www-data mautic_web php /var/www/html/bin/console mautic:contacts:scheduled_export --env=prod
```
