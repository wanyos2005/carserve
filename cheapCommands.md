# Check the breakdown of Docker directory
sudo du -sh /var/lib/docker/* 2>/dev/null | sort -hr | head -10 #sort -hr

 Clean APT cache (safe, frees ~293MB immediately):

3. Remove unused volumes (if any exist that aren't attached):
docker volume lsdocker volume prune -f  # Only removes volumes not in use
4. Cl

# Also try pruning buildx cache
docker buildx prune -af

example:

ubuntu@ip-172-31-15-187:~$ sudo du -sh /var/lib/docker/overlay2
6.8G    /var/lib/docker/overlay2
ubuntu@ip-172-31-15-187:~$ sudo du -sh /var/lib/docker/image
12M     /var/lib/docker/image
ubuntu@ip-172-31-15-187:~$ sudo du -sh /var/lib/docker/containers
2.3M    /var/lib/docker/containers
ubuntu@ip-172-31-15-187:~$ sudo du -sh /var/lib/docker/volumes
66M     /var/lib/docker/volumes
ubuntu@ip-172-31-15-187:~$ sudo du -sh /var/lib/docker/buildkit
5.1M    /var/lib/docker/buildkit
ubuntu@ip-172-31-15-187:~$ docker buildx prune -af
ID                                              RECLAIMABLE     SIZE            LAST ACCESSED
5uiic4a0wxzrkrpcrpk7ao4s1                       true            190.3kB         24 hours ago
gr9twj3v0qz9mbdofk612zbuu                       true    53.55kB         25 hours ago
ogqjnvx4cgcmwfs1dg2t2inpd                       true    143.8kB         25 hours ago
mzqkpma2vkcfnt4nuqwg8gm0a                       true    16.32kB         25 hours ago
97g6qhk17rikhh8jelr8g9tro                       true    17.02kB         25 hours ago
jmt60m2wgir4bi03kwxquwy4w                       true    287.7kB         24 hours ago
yuzaukeohdpioeeywigz53hn4                       true    40.96kB         25 hours ago
sfja4m7hcwk4v57mpbgtiaf99                       true    133.2kB         25 hours ago
j9q96vc84alaghkcb9mkf8hif                       true    83.34MB         25 hours ago
47gd386qopy1t9q0jrfikx6ga                       true    85.53MB         25 hours ago
zdb3a3gwsyrp8x1u1msefct26                       true    959B            25 hours ago
oyr267oomiucydx8zzdpo2elr                       true    253.6MB         24 hours ago
k9iiko97uyxuqoatfcjwhgwvz                       true    96.59MB         25 hours ago
fpqy0jq9jkrjqp3xs21ijozwz                       true    254.1MB         24 hours ago
5c9u95o7ydgq2wvutnxventsk                       true    82.25MB         25 hours ago
1lzhvg1al8ktov2q084pomp9z                       true    1.013kB         25 hours ago
km2g8jg33bg80xgekg0ozn08a                       true    252B            25 hours ago
g4kvlupmh7zqy2oas7eyldbr8                       true    257B            25 hours ago
7vrt3jw7hp3yl2cuvbny2xy4z                       true    214B            25 hours ago
m6o2599ywyboja4sdlk29gwcc                       true    142.4kB         25 hours ago
aq303zqwsyxlvur6a9tf3qxwu                       true    397B            24 hours ago
vv610gtizkzye7t901fgz1dty                       true    79.3kB          25 hours ago
o59rg76naynyt3twkxnoc3tz6                       true    205B            25 hours ago
4ttx5dbo04di82gkh1gig2vgv                       true    380B            24 hours ago
r93e8toh51bh35bd84cnnpvug                       true    221.4MB         25 hours ago
10v0yz47wuavw6377ne2nh6gm                       true    87.23MB         25 hours ago
jo96z4k8k9myaym1h7pvk6520                       true    286.5MB         24 hours ago
3po0ej5io2ztgzycrxh4plts7                       true    28.06MB         24 hours ago
yz8ezm3jjirqhaplzmvjgnwgb                       true    279B            25 hours ago
84xghfqd055lvdpfrtblpzuif                       true    258B            25 hours ago
rkc6rqtt8menz207e5tjrxsjt                       true    210.6MB         24 hours ago
26aht6xwbhl2uah8lsre1jgtg                       true    15.56MB         25 hours ago
jnsnzh1bhjrp5eupv56mlnibt                       true    0B              24 hours ago
o7yjy0godo0rscb1w0unhkea9                       true    0B              24 hours ago
r3fbron3o99l0myjpuuge1ox3                       true    0B              25 hours ago
ze48ewoisivfzl7k0jtt8m6tw                       true    0B              25 hours ago
fdjf91qw7jbrwrfexhi9nvbxo                       true    0B              25 hours ago
Total:  1.706GB
ubuntu@ip-172-31-15-187:~$ docker system prune -a -f
Deleted Images:
deleted: sha256:46020540b59af76d8f77e3a2a3b4c794c2a1ad24961d4c164744fb2d05b64c48
deleted: sha256:f4097b9ad8a79b6a3d7d7cb829f7f84ffd2192d96add21363d8d138f30b819a4
deleted: sha256:0e73e0f5c894f8b832deb03be90384776b898d58a361083c1f5898907d30c792
deleted: sha256:f3b027898e166a2e902ab38124ed4db9ce9d72d1f70b83a68914be6b4f7a1374
deleted: sha256:9b94c347f56467b72c1f5642b851d01a26efaceb30d9078781afb6b8bd6fbf26
deleted: sha256:e31b7c6bb41b7e1c20b8940dec55d3d7c60bf66d64624e22a44e63234cd75057
deleted: sha256:51d8c8408e95773aae518e684b65de065effa85616469f77d913f4f36ce596e5
deleted: sha256:e450a325f2f6925b1d67d18bec5c1368a550f9779a414b11d1a08a5b1ec303e5
deleted: sha256:56d4882065f2a918e5448b6f5c204366a92ef367cdf789c4d77e189e6b6fb884
deleted: sha256:da1a382e5bff8aec2e2da8c848e78e4089c6662317de33cd7b50884879a6e41e
deleted: sha256:500b4ee9ed1c64b93691a6ccd9558de4c69fbdd3c97d72970fa15bd897b0322b
deleted: sha256:f7b7d5db72996bb6427203cdee4a916b3ae641c6cb18cbaaf99bc3b9430ea67b
deleted: sha256:d4918ca78576a537caa7b0c043051c8efc1796de33fee8724ee0fff4a1cabed9
deleted: sha256:88af9f575d6a9fa7b5a16120f2a18f8113bbe9c8345586c40d360ba3042572a1
deleted: sha256:db26c4e59bebcfa9acae6b53341063c603cbbc911bc2e3bac6edc8bdf0fbc686
deleted: sha256:dfb0b3d16d5c315aacf955587e75cfa9d9e65d6744dce0dc107cad0e56bf10d6
deleted: sha256:583c66ba990448f304385e3bf32295d3431a57d9ae446924da19a6256e1d8de5
deleted: sha256:8cb0e9a8e468f16e92dfed125f82f9010a7c4a771ef9ec021806f297ae338814
deleted: sha256:f91420e68a07766231185cdc55b7da14ce47fae1bdba44f872859fc4d438817c
deleted: sha256:79d5db50f2457635365b7212e8f8911a9f3f3522f52b6cc01c81579f52ac87b9
deleted: sha256:72d57f1006fb9d5fe3955ddff1338f911cb0b1058e1245417b19936f1f910918
deleted: sha256:2965596de30e5b05afe7018869603fbeb3b3bb604800f62b0a94d3fc84d17bfe
deleted: sha256:97433af1f6ee1b64e4a0752e3434adc7ea06ec87d77f89766cce7c0f123c3d14
deleted: sha256:5d372846c3070b7e914efb8a08b080a6806e297fb1c1205c285a0ab58dcd7463
deleted: sha256:3a92346af24b1bc6ec05a2f88a3fea36267c254946b489fe68da5ae9dd7875cb
deleted: sha256:2b171dfccbb97a676b9855ea3dc713b9483f7b48cc22dc7833e81868a1b4947b
deleted: sha256:c0b6ab3b953b7c891df56d4367ebadeb59fd677262474c5a9f5a6ce897abb00a
deleted: sha256:c8d85fd1290ddf88d89a685ecd89744ec9fb69cee0b1e39098aa846ee34a14d6
deleted: sha256:568230a6186229cde45cdaa44cc364703a98a316b3338323163b7d714905f81c
deleted: sha256:c628a4281e3da888f9a5a932c5ca6e762c59b3352f90612cc13ac577ed41d141
deleted: sha256:ccbbc91cda5b6627b90c6a29d67b0d74bd8850a722b79122d2404a0618124bb5
deleted: sha256:c51e2a48fb9ac182e20d0826307f3c241cda32bbb60df6847dd6a08cf6883489
deleted: sha256:ce8aae17a824fabcac4aab86ee4e6de20c4a2c31bc5a43e7d14a3f0570811299
deleted: sha256:ddbbb5fc872ae3d453d05441bda435488a1c4208d31ee197e38e73c5bce06ae0
deleted: sha256:0e00b55206f9ed65f5cfa1d27644c3ef5d01b72cfd10fef9e98834ce4aa6a6f2
deleted: sha256:f77cc11c006cf878d6ec370c0db355cc903a7953c616707cbb6778f3b303d317
deleted: sha256:63dc1a7b8a89c0bc5225ab030365ce66442441cd741b7125218a8e63e295e97d
deleted: sha256:0ea5302faacf6f5501ad5bcaa6f77f913b2373b067fdcaaf5d75949942da2606
deleted: sha256:b18f0b1650bd2055e36c9f73ba18e60ae5303d488abdab57bf95bb5ce26b0e96
deleted: sha256:5734e2798232045c05556210d127ec9e854d4e2eb5664951c345bff42ecb0bb7
deleted: sha256:1b44b5a3e06a9aae883e7bf25e45c100be0bb81a0e01b32de604f3ac44711634
deleted: sha256:53d204b3dc5ddbc129df4ce71996b8168711e211274c785de5e0d4eb68ec3851
deleted: sha256:93189fade70ab97a985f69cf229b541c7f52997469d03ebf4b27833116dfaa90
deleted: sha256:1bc2728227bfa0f665e0647a5ad808c7d85f2eed00b5fb4e2b689525caf361fc
deleted: sha256:640f56eed19ad0276d0793ae85a0ecca05823037cde456eee6384b2fe2b40174
deleted: sha256:4fe14649c0277688e8cbf8790e14fee317b77c3e310a20b922f1d4d36d4103d0
deleted: sha256:b0c3846447f222a81acc4913a0fb74fef318655755516b7d5baea7ec26380aa7
deleted: sha256:d7c5a94b8364da5a63dab5a3505a5d09d7deae5b6bed95c54d26d585011b19ef
deleted: sha256:9cd5e0e4b993ce55d7ec849ddf94678276a233764fcd332bc16abb45093a8f52
deleted: sha256:875892131961fd851075093b83d0a0fe35634ee7750c3f5fc5d9f58c2e55f298
deleted: sha256:b8569187780386a407c32681d43988b26a3c6d87f13c7154dbc927bc7426bf83
deleted: sha256:f50282dead8f87b9451790820fda28196ac4734b83805facc5fbe82b03b6ff2f
deleted: sha256:b70fb4061f869214778de6b0bf0f2f4bc089c211a0901e65851a14e0103a110d

Total reclaimed space: 1.75GB
ubuntu@ip-172-31-15-187:~$ sudo ls -lah /var/lib/docker/
total 64K
drwx--x--- 12 root root 4.0K Oct 31 11:31 .
drwxr-xr-x 45 root root 4.0K Oct 31 19:24 ..
drwx--x--x  5 root root 4.0K Oct 31 11:46 buildkit
drwx--x--- 15 root root 4.0K Nov  1 07:06 containers
-rw-------  1 root root   36 Oct 31 11:31 engine-id
drwx------  3 root root 4.0K Oct 31 11:31 image
drwxr-x---  3 root root 4.0K Oct 31 11:31 network
drwx--x--- 97 root root  16K Nov  1 12:20 overlay2
drwx------  3 root root 4.0K Oct 31 11:31 plugins
drwx------  2 root root 4.0K Oct 31 11:31 runtimes
drwx------  2 root root 4.0K Oct 31 11:31 swarm
drwx------  3 root root 4.0K Nov  1 00:41 tmp
drwx-----x  5 root root 4.0K Nov  1 00:41 volumes
ubuntu@ip-172-31-15-187:~$

checking current disk space:
df -h

check images currently used, docker images and docker ps
reduce system logs: sudo journalctl --vacuum-size=50M

ssh into ec2.  ssh -i "C:\Users\Peter Wanyonyi\Downloads\fastapi-key.pem.pem" ubuntu@16.16.143.243

# EC2 Instance Management (when console actions are greyed out due to IAM permissions)
# Start stopped EC2 instance via CLI (instance ID: i-0ec6c2b1be34e3c5f, region: eu-north-1)
aws ec2 start-instances --instance-ids i-0ec6c2b1be34e3c5f --region eu-north-1

# Check instance status
aws ec2 describe-instances --instance-ids i-0ec6c2b1be34e3c5f --region eu-north-1 --query 'Reservations[].Instances[].[InstanceId,State.Name,PublicIpAddress]' --output table

# Stop instance
aws ec2 stop-instances --instance-ids i-0ec6c2b1be34e3c5f --region eu-north-1

# Reboot instance
aws ec2 reboot-instances --instance-ids i-0ec6c2b1be34e3c5f --region eu-north-1

# Check your IAM permissions (what you can do with EC2)
aws iam get-user
aws iam list-attached-user-policies --user-name YOUR_USERNAME
aws iam get-policy-version --policy-arn arn:aws:iam::ACCOUNT_ID:policy/POLICY_NAME --version-id v1

# To fix IAM permissions, you need an admin to attach this policy (or create a custom one):
# AmazonEC2FullAccess (or create custom policy with ec2:StartInstances, ec2:StopInstances, etc.)

Run STATUS="Pending"
⏳ Waiting for SSM command to finish...
Current SSM status: Failed
===== 🧾 SSM Deployment Logs =====
--- Starting deployment on EC2 ---
--- Fixing git safe directory ownership ---
--- Pulling latest code from GitHub ---
Updating 66e3d01..01298fd
Fast-forward
 backend/social_service/main.py    |  34 ++++++---
 cheapCommands.md                  | 143 ++++++++++++++++++++++++++++++++++++++
 frontend/lib/services/config.dart |   2 +-
 3 files changed, 169 insertions(+), 10 deletions(-)
--- Building and running containers ---

----------ERROR-------
From https://github.com/wanyos2005/carserve
 * branch            main       -> FETCH_HEAD
   66e3d01..01298fd  main       -> origin/main
time="2025-11-01T17:46:15Z" level=warning msg="/home/ubuntu/carserve/docker-compose.aws.yml: the attribute `version` is obsolete, it will be ignored, please remove it to avoid potential confusion"
 booking-service Pulling 
 expenses-service Pulling 
 social-service Pulling 
 alert-service Pulling 
 postgres Pulling 
 insurance-service Pulling 
 service-provider Pulling 
 alert-worker Pulling 
 nginx Pulling 
 alert-beat Pulling 
 redis Pulling 
 user-service Pulling 
 vehicle-service Pulling 
 booking-service Pulled 
 social-service Pulled 
 expenses-service Pulled 
 alert-service Pulled 
 service-provider Pulled 
 vehicle-service Pulled 
 alert-beat Pulled 
 alert-worker Pulled 
 insurance-service Pulled 
 user-service Pulled 
 postgres Pulled 
 nginx Pulled 
 redis Pulled 
time="2025-11-01T17:46:17Z" level=warning msg="/home/ubuntu/carserve/docker-compose.aws.yml: the attribute `version` is obsolete, it will be ignored, please remove it to avoid potential confusion"
 Container carserve-postgres-1  Running
 Container carserve-redis-1  Running
 Container carserve-alert-beat-1  Running
 Container carserve-alert-worker-1  Running
 Container carserve-user-service-1  Running
 Container carserve-alert-service-1  Running
 Container carserve-booking-service-1  Running
 Container carserve-vehicle-service-1  Running
 Container carserve-service-provider-1  Running
 Container carserve-insurance-service-1  Running
 Container carserve-expenses-service-1  Running
 Container carserve-social-service-1  Running
 Container gateway  Running
unknown shorthand flag: 'y' in -y

Usage:  docker system prune [OPTIONS]

Run 'docker system prune --help' for more information
failed to run commands: exit status 125
❌ SSM deployment failed!
Error: Process completed with exit code 1.

"To fix the Docker buildx permission issue, run these commands on your EC2 instance:
# 1. Fix docker permissions
sudo chown -R ubuntu:ubuntu ~/.docker
# 1. Fix git permissions
sudo chown -R ubuntu:ubuntu ~/carserve/.gitsudo chown -R ubuntu:ubuntu ~/carserve

docker compose -f docker-compose.aws.yml build social-service"

docker compose -f docker-compose.aws.yml up -d social-service

docker compose -f docker-compose.aws.yml exec nginx nginx -s reload

to read a file:
cat ~/carserve/.env | grep JWT_SECRET_KEY

to edit the file, a line:
# Edit the  file to remove quotes
sed -i 's/JWop="npg_GHDT\/?envious"/JWT_SECRET_KEY=npg_U5VcT\/?envius/' ~/carserve/.env

confirm the content or variable of a docker container file:
docker compose -f docker-compose.aws.yml exec social-service env | grep secret key

building the apk and bundle:
flutter build apk --release //for unoffficial apk you can send to people inboxes to download

flutter build appbundle --release // for playstore

```alembic table migrations to production```

use this to check the migration versions of the vm container:
 docker compose -f docker-compose.aws.yml exec service-provider sh -lc "ls -1 alembic/versions"
e.g, it will list:
3167810ba581_tables_initialization.py
__pycache__

1. Align the DB to the migration that actually exists in the container:

docker compose -f docker-compose.aws.yml exec service-provider alembic stamp 3167810ba581
2. If you already committed/pushed a new migration for “a few table adjustments and a new table,” rebuild/restart service-provider so the container has it:

docker compose -f docker-compose.aws.yml build service-provider
docker compose -f docker-compose.aws.yml up -d service-provider
3.  If you can’t change code immediately, re-stamp the DB to a revision that exists
First confirm current DB version:
docker compose -f docker-compose.aws.yml exec postgres psql -U AdminDb -d car_platform -c "SELECT version_num FROM service_providers.alembic_version;"

If it returns c7cce0950acf which you dont have, set it to the initial revision you actually have:
docker compose -f docker-compose.aws.yml exec postgres psql -U AdminDb -d car_platform -c "UPDATE service_providers.alembic_version SET version_num='3167810ba581';"

then :
check the current state: docker compose -f docker-compose.aws.yml exec service-provider alembic current
then :
docker compose -f docker-compose.aws.yml exec service-provider alembic upgrade head

```example if the version is non existend```:
ubuntu@ip-172-31-15-187:~/carserve$ docker compose -f docker-compose.aws.yml exec postgres psql -U AdminDb -d car_platform -c "UPDATE alerts.alembic_version SET version_num='37f1fda05547';"
WARN[0000] /home/ubuntu/carserve/docker-compose.aws.yml: the attribute `version` is obsolete, it will be ignored, please remove it to avoid potential confusion
UPDATE 1
ubuntu@ip-172-31-15-187:~/carserve$ docker compose -f docker-compose.aws.yml exec alert-service alembic current
WARN[0000] /home/ubuntu/carserve/docker-compose.aws.yml: the attribute `version` is obsolete, it will be ignored, please remove it to avoid potential confusion
INFO  [alembic.runtime.migration] Context impl PostgresqlImpl.
INFO  [alembic.runtime.migration] Will assume transactional DDL.
37f1fda05547
ubuntu@ip-172-31-15-187:~/carserve$ docker compose -f docker-compose.aws.yml exec alert-service alembic upgrade head
WARN[0000] /home/ubuntu/carserve/docker-compose.aws.yml: the attribute `version` is obsolete, it will be ignored, please remove it to avoid potential confusion
INFO  [alembic.runtime.migration] Context impl PostgresqlImpl.
INFO  [alembic.runtime.migration] Will assume transactional DDL.
INFO  [alembic.runtime.migration] Running upgrade  -> 8a8549c1b995, initial tables
INFO  [alembic.runtime.migration] Running upgrade 37f1fda05547, 8a8549c1b995 -> ef5c394342e2, merge_initial_migrations
INFO  [alembic.runtime.migration] Running upgrade ef5c394342e2 -> 48d05b247c5c, add_rating_request_and_app_download_alert_types
ubuntu@ip-172-31-15-187:~/carserve$

```app download prompts email deleivery issues```

To see email delivery attempts for app-download prompts
SELECT nl.alert_id, a.user_id, a.type, nl.channel, nl.status, nl.error_message, nl.sent_at
FROM alerts.notification_logs nl
JOIN alerts.alerts a ON a.id = nl.alert_id
WHERE a.type = 'APP_DOWNLOAD_PROMPT' AND nl.channel = 'EMAIL'
ORDER BY nl.sent_at DESC
LIMIT 50;

or 

SELECT id, user_id, type, status, channels, created_at, sent_at, delivered_at, error_message
FROM alerts.alerts
WHERE type = 'APP_DOWNLOAD_PROMPT'
ORDER BY created_at DESC
LIMIT 20;

Command sequence to delete a user:
-- 1. Check the user first
SELECT * FROM users.tbl_auth WHERE id = 6 OR email = 'kwkitui@gmail.com';

-- 2. Delete the user
DELETE FROM users.tbl_auth WHERE id = 6;

-- Or by email:
-- DELETE FROM users.tbl_auth WHERE email = 'kwkitui@gmail.com';

-- 3. Verify deletion
SELECT * FROM users.tbl_auth WHERE id = 6 OR email = 'kwkitui@gmail.com';

```how to build the frontend apk```
cd frontend && flutter build apk --release