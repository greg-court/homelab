### 0) Install the MinIO client

```bash
brew install minio/stable/mc || true
```

### 1) Set variables (fill in the two values)

```bash
ENDPOINT="https://truenas.internal:9000"
ROOT_USER="replaceme"
ROOT_PASS="replaceme"
```

### 2) Point `mc` at your TrueNAS MinIO (using root creds)

```bash
mc --insecure alias set truenas "$ENDPOINT" "$ROOT_USER" "$ROOT_PASS"
mc --insecure alias ls
```

### 3) Ensure the bucket exists

```bash
mc --insecure mb --ignore-existing truenas/longhorn
```

### 4) Create least-privilege policy + user for Longhorn

```bash
cat > longhorn-backup.json <<'JSON'
{
  "Version": "2012-10-17",
  "Statement": [
    {"Effect":"Allow","Action":["s3:ListBucket","s3:GetBucketLocation","s3:ListBucketMultipartUploads"],"Resource":["arn:aws:s3:::longhorn"]},
    {"Effect":"Allow","Action":["s3:PutObject","s3:GetObject","s3:DeleteObject","s3:AbortMultipartUpload","s3:ListMultipartUploadParts"],"Resource":["arn:aws:s3:::longhorn/*"]}
  ]
}
JSON

mc --insecure admin policy create truenas longhorn-backup longhorn-backup.json
SECRET="$(openssl rand -base64 32)"
mc --insecure admin user add truenas longhorn "$SECRET"
mc --insecure admin policy attach truenas longhorn-backup --user longhorn
echo "AWS_SECRET_ACCESS_KEY=$SECRET"
```

### 5) put the following JSON in AKV, replace the cert from TrueNAS Certificates

```json
{
  "AWS_ACCESS_KEY_ID": "longhorn",
  "AWS_SECRET_ACCESS_KEY": "",
  "AWS_ENDPOINTS": "https://truenas.internal:9000",
  "AWS_DEFAULT_REGION": "minio",
  "VIRTUAL_HOSTED_STYLE": "false",
  "AWS_CERT": "-----BEGIN CERTIFICATE-----\n<YOUR-CA-OR-SERVER-CERT-PEM>\n-----END CERTIFICATE-----\n"
}
```
