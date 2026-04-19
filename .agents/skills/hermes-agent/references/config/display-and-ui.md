# 表示設定・スキン・ストリーミング

## 表示設定

```yaml
display:
  tool_progress: all            # off | new | all | verbose
  tool_progress_command: false  # /verbose コマンド有効化
  streaming: false
  show_reasoning: false
  show_cost: false
  bell_on_complete: false
  compact: false
  resume_display: full          # full | minimal
  tool_preview_length: 0        # 0=無制限
  busy_input_mode: "interrupt"  # interrupt | queue
  skin: default
  personality: "kawaii"
```

## ストリーミング（ゲートウェイ）

```yaml
streaming:
  enabled: true
  transport: edit               # edit | off
  edit_interval: 0.3
  buffer_threshold: 40
  cursor: " ▉"
```
