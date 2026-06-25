#!/usr/bin/env bash
#
# website_main_jp 単体パッケージング
#  1) index.html が参照する CDN アセットのうち assets/ に無いものだけダウンロード
#  2) CDN URL を相対パス（assets/…）に書き換えた index.html を生成
#  3) index.html + assets を kel_main_jp.zip に圧縮（アップロード用）
#
# 使い方: このファイルがある website_main_jp フォルダで →  bash pack.sh
# 必要: bash / curl / perl / zip（macОS 標準）
#
set -euo pipefail
cd "$(dirname "$0")"
CDN="https://d8j0ntlcm91z4.cloudfront.net/user_2zGT07hYZHYSKi8k0xgmL3CULL7/"

[ -f index.html ] || { echo "✗ index.html が見つかりません。website_main_jp フォルダで実行してください"; exit 1; }
mkdir -p assets

# 参照アセット一覧
REF="$(grep -oE 'hf_[0-9]{8}_[0-9]{6}_[0-9a-f-]+\.(png|mp4|webp|jpe?g)' index.html | sort -u)"
echo "▶ 参照アセット: $(printf '%s\n' "$REF" | grep -c .) 件"

# 1) 不足分のみダウンロード
miss=0
for f in $REF; do
  if [ ! -s "assets/$f" ]; then
    miss=$((miss+1)); printf '  ↓ %s ... ' "$f"
    if curl -fsSL "$CDN$f" -o "assets/$f"; then echo ok; else echo "失敗"; fi
  fi
done
[ "$miss" -eq 0 ] && echo "  すべて assets/ に揃っています（ダウンロード不要）"

# 2) 配布物を作成（参照アセットのみ + 相対パス化）
rm -rf dist && mkdir -p dist/assets
for f in $REF; do cp "assets/$f" "dist/assets/$f"; done
CDN="$CDN" perl -pe 's/\Q$ENV{CDN}\E/assets\//g' index.html > dist/index.html
echo "▶ dist/ を生成（index.html を assets/ 相対参照に書き換え済み）"

# 3) zip 圧縮
rm -f kel_main_jp.zip
( cd dist && zip -rq ../kel_main_jp.zip index.html assets )
echo "✅ 完成: $(pwd)/kel_main_jp.zip"
echo "   中身: index.html ＋ assets/（$(printf '%s\n' "$REF" | grep -c .) ファイル）"
echo "   ※ そのまま解凍してアップロード、または zip をホスティングにアップロードしてください。"
