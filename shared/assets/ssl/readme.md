# Folder `/shared/assets/ssl`

This folder is intended to store the **local SSL certificates** required to run the Angular application in development mode with HTTPS.

## Important
- Certificate files are **NOT versioned in git** for security reasons.
- This folder appears empty in the repository because `.key`, `.crt`, `.pem`, and `.p12` files are excluded via `.gitignore`.
- Each developer must place their own certificates here so that `ng serve` can use them.

## Expected usage
1. Copy the corresponding files into this folder:
   - `mbonet.xyz.crt`
   - `mbonet.xyz.key`
2. Make sure the paths configured in `angular.json` point to these files, for example:
   ```json
   "sslKey": "shared/assets/ssl/mbonet.xyz.key",
   "sslCert": "shared/assets/ssl/mbonet.xyz.crt"
