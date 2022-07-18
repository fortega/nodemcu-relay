from datetime import datetime, date, timedelta
now = datetime.now().time()
uptime = timedelta(seconds=now.second, minutes=now.minute, hours=now.hour)

print(int(uptime.total_seconds()))