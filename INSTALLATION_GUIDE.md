# Typebot Installation Script - מדריך שימוש

## 📋 מה זה?

סקריפט התקנה אוטומטי ומלא ל-Typebot על שרת Ubuntu חדש.
הסקריפט מתקין **הכל** מאפס - אין צורך בשום התקנה מוקדמת!

---

## 📦 מה הסקריפט מתקין?

### 1. אבטחה בסיסית
- ✅ שינוי פורט SSH ל-2222
- ✅ הגדרת UFW Firewall
- ✅ התקנת Fail2ban (הגנה מפני התקפות brute-force)

### 2. תשתית
- ✅ Docker & Docker Compose (latest)
- ✅ Nginx Reverse Proxy
- ✅ SSL Certificates (Cloudflare Origin)

### 3. Typebot Stack
- ✅ PostgreSQL 16 (Database)
- ✅ Redis (Cache)
- ✅ MinIO (S3 Storage)
- ✅ Typebot Builder
- ✅ Typebot Viewer

### 4. אופציונלי - Google Integrations
- ⚙️ Google Sheets (שמירת תשובות)
- ⚙️ Gmail (שליחת מיילים מהבוט)
- ⚙️ Google Fonts (פונטים מותאמים)
- ⚙️ Google OAuth (התחברות עם Google)

---

## 🚀 איך משתמשים בסקריפט?

### דרישות מקדימות

1. **שרת Ubuntu** (22.04 או חדש יותר)
   - נקי ללא התקנות קודמות
   - גישת root

2. **3 דומיינים** מצביעים ל-IP של השרת:
   - `typebot.example.com` (Builder)
   - `typebot-bot.example.com` (Viewer)
   - `minio.example.com` (MinIO Console)

3. **תעודות SSL** מ-Cloudflare:
   - Origin Certificate (PEM format)
   - Private Key (PEM format)
   - איפה מקבלים: Cloudflare Dashboard → SSL/TLS → Origin Server → Create Certificate

4. **SMTP Credentials**:
   - למייל Gmail: צור App Password (לא סיסמה רגילה)
   - Settings → Security → 2-Step Verification → App Passwords

5. **Google Credentials** (אופציונלי):
   - Google Cloud Console → APIs & Services → Credentials
   - OAuth 2.0 Client ID
   - API Key

---

## 📝 שלבי ההתקנה

### שלב 1: העלאת הסקריפט לשרת

```bash
# מהמחשב המקומי שלך:
scp install-typebot-complete.sh root@YOUR_SERVER_IP:/root/install.sh
```

### שלב 2: התחברות לשרת

```bash
ssh root@YOUR_SERVER_IP
```

### שלב 3: הרצת הסקריפט

```bash
cd /root
chmod +x install.sh
./install.sh
```

### שלב 4: מענה על השאלות

הסקריפט ישאל אותך שאלות אינטראקטיבית. הנה מה שהוא ישאל:

#### 📍 הגדרות דומיין
```
Enter Builder domain: typebot.example.com
Enter Viewer domain: typebot-bot.example.com
Enter MinIO domain: minio.example.com
```

#### 👤 הגדרות מנהל
```
Enter admin email: your@email.com
Disable user signup? yes
```

#### 📧 הגדרות SMTP
```
SMTP Host: smtp.gmail.com
SMTP Port: 587
SMTP Username: your@gmail.com
SMTP Password: [your app password]
SMTP From Email: your@gmail.com
```

#### 🔒 תעודות SSL
```
Paste your Cloudflare Origin Certificate:
[paste certificate and press Ctrl+D]

Paste your Cloudflare Private Key:
[paste key and press Ctrl+D]
```

#### 🔌 Google Integrations (אופציונלי)
```
Do you want to enable Google integrations? no/yes

If yes:
  Enable Google Sheets? yes/no
  Enable Gmail? yes/no
  Enable Google Fonts? yes/no
  Enable Google OAuth? yes/no

  Google OAuth Client ID: [your client id]
  Google OAuth Client Secret: [your secret]
  Google API Key: [your api key]
```

### שלב 5: המתן להתקנה

הסקריפט ייקח בין 5-10 דקות להתקנה מלאה.
הוא יציג progress בזמן אמת.

### שלב 6: סיום

בסוף ההתקנה תקבל מסך עם:
- ✅ URLs לגישה למערכת
- ✅ פרטי התחברות
- ⚠️ אזהרה על שינוי פורט SSH
- 📄 מיקום קובץ המידע המלא

---

## ⚠️ חשוב! אחרי ההתקנה

### 1. שמור את המידע

```bash
# הצג את כל המידע:
cat /opt/typebot/INSTALLATION_INFO.txt

# העתק את התוכן למקום מאובטח (password manager)
# אחר כך מחק את הקובץ:
rm /opt/typebot/INSTALLATION_INFO.txt
```

### 2. התחבר מחדש עם פורט 2222

```bash
# מהמחשב המקומי שלך:
ssh -p 2222 root@YOUR_SERVER_IP
```

הסשן הנוכחי שלך יישאר פעיל, אבל חיבורים חדשים חייבים דרך פורט 2222!

### 3. גישה ל-Typebot

1. פתח בדפדפן: `https://typebot.example.com`
2. הזן את המייל שלך
3. בדוק את תיבת הדואר
4. לחץ על הקישור (Email Magic Link)
5. התחבר והתחל ליצור בוטים!

---

## 🔧 פקודות שימושיות

### בדיקת סטטוס

```bash
cd /opt/typebot
docker compose ps
```

### צפייה בלוגים

```bash
# כל השירותים:
docker compose logs -f

# שירות ספציפי:
docker compose logs -f typebot-builder
docker compose logs -f typebot-viewer
```

### הפעלה מחדש

```bash
cd /opt/typebot
docker compose restart
```

### עצירה והפעלה

```bash
cd /opt/typebot
docker compose down
docker compose up -d
```

### עדכון לגרסה חדשה

```bash
cd /opt/typebot
docker compose pull
docker compose up -d
```

---

## 🛠️ פתרון בעיות

### Internal Server Error 500

אם אתה מקבל שגיאה 500, בדוק את לוגים:

```bash
cd /opt/typebot
docker compose logs typebot-builder --tail=50
docker compose logs typebot-viewer --tail=50
```

**בעיה נפוצה**: `DISABLE_SIGNUP` צריך להיות `true` או `false` (לא `yes` או `no`).

**פתרון**:
```bash
# בדוק את הערך:
grep DISABLE_SIGNUP /opt/typebot/.env

# אם הערך הוא "yes" או "no", תקן:
sed -i 's/^DISABLE_SIGNUP=yes$/DISABLE_SIGNUP=true/' /opt/typebot/.env
sed -i 's/^DISABLE_SIGNUP=no$/DISABLE_SIGNUP=false/' /opt/typebot/.env

# הפעל מחדש:
docker compose down && docker compose up -d
```

### הבוט לא נטען / שגיאה 502

```bash
# בדוק שכל השירותים רצים:
docker compose ps

# הפעל מחדש:
docker compose restart
```

### לא מקבל Email Magic Link

```bash
# בדוק את לוגים של Builder:
docker compose logs typebot-builder | grep -i smtp
docker compose logs typebot-builder | grep -i email

# ודא ש-SMTP מוגדר נכון:
cat .env | grep SMTP
```

### MinIO לא עובד

```bash
# בדוק סטטוס:
docker compose ps | grep minio

# הפעל מחדש:
docker compose restart typebot-minio
```

### Nginx Error

```bash
# בדוק הגדרות:
nginx -t

# הפעל מחדש:
systemctl restart nginx

# צפה בלוגים:
tail -f /var/log/nginx/error.log
```

---

## 📁 קבצים חשובים

| קובץ | מיקום | תיאור |
|------|-------|--------|
| Docker Compose | `/opt/typebot/docker-compose.yml` | הגדרות הקונטיינרים |
| Environment | `/opt/typebot/.env` | משתני סביבה וסיסמאות |
| SSL Certificates | `/etc/ssl/cloudflare/` | תעודות SSL |
| Nginx Config | `/etc/nginx/sites-available/typebot` | הגדרות Nginx |
| Installation Info | `/opt/typebot/INSTALLATION_INFO.txt` | מידע מלא על ההתקנה |

---

## 🔐 גיבוי

### גיבוי מהיר

```bash
cd /opt/typebot
docker compose down
tar -czf /root/typebot-backup-$(date +%Y%m%d).tar.gz \
    /opt/typebot \
    /etc/ssl/cloudflare \
    /etc/nginx/sites-available/typebot \
    /etc/nginx/sites-available/minio
docker compose up -d
```

### שחזור מגיבוי

```bash
cd /root
tar -xzf typebot-backup-YYYYMMDD.tar.gz -C /
cd /opt/typebot
docker compose up -d
```

---

## 📊 מה נשמר בגיבוי Docker Volumes?

- **db-data**: כל הנתונים של PostgreSQL (בוטים, משתמשים, תשובות)
- **redis-data**: Cache של Redis
- **minio-data**: כל הקבצים שהועלו (תמונות, קבצים, וכו')

---

## 🌐 שרת חדש - התקנה מהירה

רוצה להתקין על שרת חדש? פשוט:

1. הכן שרת Ubuntu חדש
2. הכן 3 דומיינים
3. העלה את הסקריפט
4. הרץ: `./install-typebot-complete.sh`
5. ענה על השאלות
6. סיימת!

**זמן התקנה משוער: 5-10 דקות**

---

## 💡 טיפים

### 1. תעד את הכל
שמור את כל הסיסמאות וה-secrets ב-password manager (למשל 1Password, Bitwarden)

### 2. גיבויים אוטומטיים
הגדר cron job לגיבויים יומיים:

```bash
0 2 * * * cd /opt/typebot && docker compose down && tar -czf /backups/typebot-$(date +\%Y\%m\%d).tar.gz /opt/typebot /etc/ssl/cloudflare && docker compose up -d
```

### 3. עדכונים
בדוק עדכונים פעם בחודש:

```bash
cd /opt/typebot
docker compose pull
docker compose up -d
```

### 4. ניטור
התקן Uptime Kuma או UptimeRobot לניטור זמינות:
- https://github.com/louislam/uptime-kuma

---

## 📞 תמיכה

- 📚 תיעוד רשמי: https://docs.typebot.io
- 💬 Discord: https://discord.gg/typebot
- 🐛 GitHub Issues: https://github.com/baptisteArno/typebot.io/issues

---

## ✅ Checklist לאחר התקנה

- [ ] Typebot Builder נגיש ועובד
- [ ] Typebot Viewer נגיש ועובד
- [ ] MinIO Console נגיש ועובד
- [ ] Email Magic Link עובד
- [ ] יכול להתחבר דרך SSH על פורט 2222
- [ ] שמרתי את קובץ INSTALLATION_INFO
- [ ] מחקתי את INSTALLATION_INFO מהשרת
- [ ] יצרתי גיבוי ראשוני
- [ ] בדקתי שהבוטים נשמרים
- [ ] העלאת קבצים עובדת (MinIO)

---

**🎉 מזל טוב! Typebot שלך מותקן ופועל!**

---

## 📂 מיקום הקבצים במחשב המקומי

הסקריפט שמור ב:
```
/Users/am/claude-project-full/install-typebot-complete.sh
```

קבצי הגיבוי שלך:
```
/Users/am/claude-project-full/ssl-cert.pem
/Users/am/claude-project-full/ssl-key.pem
```

**שמור את הקבצים האלה במקום מאובטח!**
