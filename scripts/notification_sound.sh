#!/bin/bash

# 通知音を再生するスクリプト
# macOSの場合はsayコマンドを使用
if [[ "$OSTYPE" == "darwin"* ]]; then
  say "処理が完了しました"
  # 別の方法としてafplayを使用することも可能
  # afplay /System/Library/Sounds/Glass.aiff
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # Linuxの場合はspd-sayやaplayなどを使用
  if command -v spd-say &> /dev/null; then
    spd-say "処理が完了しました"
  elif command -v aplay &> /dev/null; then
    # 適切な音声ファイルへのパスを指定する必要があります
    echo "Linuxでの通知音再生はシステムによって異なります"
  else
    echo "通知音を再生できるコマンドが見つかりませんでした"
  fi
else
  echo "このOSでの通知音再生方法は実装されていません"
fi

echo "処理が完了しました - $(date)"
