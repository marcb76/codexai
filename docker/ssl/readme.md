# Folder `/docker/ssl`

This folder is intended to store the **local SSL certificates** required to run the backend/frontend in production (dokcer) HTTPS.

## Important
- Certificate files are **NOT versioned in git** for security reasons.
- This folder appears empty in the repository because `.key`, `.crt`, `.pem`, and `.p12` files are excluded via `.gitignore`.

## Expected usage
1. Copy the corresponding files into this folder:
   - `ssl.crt`
   - `ssl.key`
2. Make sure the paths configured in `node-express` and `nginx` point to these files.
