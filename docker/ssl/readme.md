# Folder `/docker//ssl`

This folder is intended to store the **SSL certificates** required to run inside the docker container in order to allow an HTTPS deployment.

## Important
- Certificate files are **NOT versioned in git** for security reasons.
- This folder appears empty in the repository because `.key`, `.crt`, `.pem`, and `.p12` files are excluded via `.gitignore`.
- Each developer must place their own certificates here so that `ng serve` can use them.

## Expected usage
1. Copy the corresponding files into this folder:
   - `ssl.crt`
   - `ssl.key`
2. Make sure the paths configured in `/etc/nginx/conf.d/default.conf` point to these files, for example:
   ```json
   server {
      ssl_certificate /app/ssl/ssl.crt;
      ssl_certificate_key /app/ssl/ssl.key;
   }
