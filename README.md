## Unifi CloudKey backups
Automatically upload your Unifi CloudKey backups to Dropbox.

TODO: Right now we upload every file every time and let Dropbox handle the de-duplication (mode:add). We should be de-duping here to lower bandwidth usage and improve performance. 

USAGE:

  1. Create a Dropbox app ("Unifi CloudKey") at https://www.dropbox.com/developers/apps/create.
  2. Create a folder ("/backups") for your app.
      * You can get the curl command, including the token, at https://www.dropbox.com/developers/documentation/http/documentation#files-create_folder.
      * Update that command with the path to the backup folder ('/backups'). It should look alot like this - 
```
$ curl -X POST https://api.dropboxapi.com/2/files/create_folder_v2 \
--header "Authorization: Bearer XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" \
--header "Content-Type: application/json" \
--data "{\"path\": \"/backups\",\"autorename\": false}"
```
Run it on the CloudKey. The response should look like this - 
```
{"metadata": {"name": "backups", "path_lower": "/backups", "path_display": "/backups", "id": "id:YYYYYYYYYYYYYYY"}}
```
  3. Get and chmod the backup script -
```
$ wget -O /usr/bin/CloudKey-Dropbox-backups.sh \
https://raw.githubusercontent.com/Gestas/Unifi-CloudKey-Dropbox-backups/master/CloudKey-Dropbox-backups.sh $$ \
chmod +x /usr/bin/CloudKey-Dropbox-backups.sh
```
  4. Add a task to cron. My CloudKey creates a backup everyday at 4PM so I run this upload script at 5 -
  ```
  $ crontab -e
  # Add - 
  0 17 * * * "/usr/bin/CloudKey-Dropbox-backups.sh <token>"
  ```
  **NOTE**: The token string should not include "Bearer"

You can run the script manually to make sure it works - 
```
$ CloudKey-Dropbox-backups.sh <token>
```
