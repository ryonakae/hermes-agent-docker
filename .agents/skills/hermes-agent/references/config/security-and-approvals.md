# セキュリティ・承認モード・ブロックリスト

## セキュリティ設定

```yaml
security:
  redact_secrets: true
  tirith_enabled: true
  website_blocklist:
    enabled: false
    domains: []

approvals:
  mode: manual                  # manual | smart | off
```
