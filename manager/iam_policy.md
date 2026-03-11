# IAM access policy

## All users

Add tenancy level policy to enable all users to read gdir_info bucket

```text
Allow any-user to read objects in tenancy where target.bucket.name = 'gdir_info'
```
