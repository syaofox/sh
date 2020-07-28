#!/bin/bash
# 部署到 github pages 脚本
# 错误时终止脚本
set -e
git pull

echo 'push to github'
#git init
git add -A

# Commit changes.
msg="sync `date`"
if [ $# -eq 1 ]
  then msg="$1"
fi
git commit -m "$msg"

git push 
