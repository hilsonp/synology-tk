# synology-tk
Various scripts used to manage my synology

## install_letsencrypt_cert.sh
All credits go to https://github.com/thiagocrepaldi/homelab-utility-belt

This modified version installs Let's Encrypt certificates managed/renewed by a SWAG docker.

### Generate RSA private key
The SWAG docker generates under /volume1/docker/swag/etc/letsencrypt/live/my.domain.org/
- A certificate with the certification chain embedded: priv-fullchain-bundle.pem
- A private key: privkey.pem

DSM wants the private key in RSA format so let's transform it and store it in the same folder.
```
cd /volume1/docker/swag/etc/letsencrypt/live/my.domain.org/
openssl rsa -in privkey.pem -out privRSAKey.key
```
Download the priv-fullchain-bundle.pem and privRSAKey.key to your computer.

### Initial Let's Encrypt certificate installation
First install the Let's Encrypt certificates manually on the Synology:
In DSM
1. Control Panel >> Security >> Certificates and click on Add
2. Add a new certificate and click on Next.
3. Choose on Import a certificate and check Set as default certificate to replace the existing self-signed certificate and go to the Next step.
4. On the Private key field, click on Browse and select the generated privRSAKey.key. 
5. For the Certificate field, click on Browse and select your priv-fullchain-bundle.pem file. 
6. Leave Intermediate certificate blank as it is embedded into the priv-fullchain-bundle.pem and click on OK to finish.
7. Click on Configure, make sure your new certificate is selected for all Services and click on Ok button to save.

### Install the install_letsencrypt_cert.sh script onto the synology
```
mkdir -p ~/src/github/hilsonp/synology-tk
git clone https://github.com/hilsonp/synology-tk.git
```

### Create a scheduled job that will install the certificates when renewed 
1. Services >> Task Scheduler >> Create >> Scheduled task >> User-defined script
2. General.Task: Copy LetsEncrypt Certficate from SWAG
3. General.User: root
4. Schedule: Daily at 04:15
5. Run Command: `bash /volume1/homes/pierre/src/phi/github/hilsonp/synology-tk/install_letsencrypt_cert.sh -f /volume1/docker/swag/etc/letsencrypt/live/pierre.hilson.be/priv-fullchain-bundle.pem 2>&1`
6. Setup logs/mail to your liking
