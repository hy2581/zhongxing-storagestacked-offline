#!/usr/bin/env bash
set -euo pipefail
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
base=https://github.com/hy2581/zhongxing-storagestacked-offline/releases/download/${STORAGE_RELEASE_TAG:-offline-20261009-burst}
destination=${1:-$here/downloads}
[[ $# -le 1 ]] || { echo '用法：bash download.sh [下载目录]' >&2; exit 2; }
command -v curl >/dev/null || { echo '需要 curl 下载文件。' >&2; exit 1; }
mkdir -p -- "$destination"
destination=$(cd -- "$destination" && pwd)
request() {
    local url=$1 target=$2 resume=${3:-0} attempt
    local options=(--http1.1 --fail --location --silent --show-error --connect-timeout 30)
    [[ $resume == 0 ]] || options+=(--continue-at -)
    for attempt in 1 2 3 4 5 6; do
        if curl "${options[@]}" "$url" -o "$target"; then return 0; fi
        [[ $attempt == 6 ]] && return 1
        printf '连接中断，准备第 %s 次重试……\n' "$attempt" >&2
        sleep "$((attempt*5))"
    done
}
for name in PARTS.tsv extract.sh PACKAGE.json SPLIT_ACCEPTANCE.json; do
    request "$base/$name" "$destination/$name.downloading"
    mv -- "$destination/$name.downloading" "$destination/$name"
done
IFS=$'\t' read -r first_name _ < "$destination/PARTS.tsv" || { echo '分块清单为空。' >&2; exit 1; }
bundle=${first_name%.tar.part-0000}
[[ $bundle =~ ^zhongxing-storagestacked-offline-[0-9]{8}(-[A-Za-z0-9._-]+)?$ && $first_name == "$bundle.tar.part-0000" ]] || {
    echo '分块清单的版本或首块名称无效。' >&2; exit 1;
}
fetch_part() {
    local name=$1 expected=$2 actual
    if [[ -f $destination/$name ]] && [[ $(stat -c '%s' -- "$destination/$name") == "$expected" ]]; then
        return
    fi
    printf '下载：%s\n' "$name"
    request "$base/$name" "$destination/$name.downloading" 1
    actual=$(stat -c '%s' -- "$destination/$name.downloading")
    [[ $actual == "$expected" ]] || { echo "下载大小不符：$name" >&2; return 1; }
    mv -- "$destination/$name.downloading" "$destination/$name"
}
workers=()
failed=0
while IFS=$'\t' read -r name bytes extra; do
    [[ $name == "$bundle.tar.part-"[0-9][0-9][0-9][0-9] && $bytes =~ ^[0-9]+$ && -z $extra ]] || {
        echo '分块清单格式错误。' >&2; exit 1;
    }
    fetch_part "$name" "$bytes" &
    workers+=("$!")
    if [[ ${#workers[@]} == 4 ]]; then
        for worker in "${workers[@]}"; do wait "$worker" || failed=1; done
        [[ $failed == 0 ]] || { echo '下载未完成；再次运行可继续下载。' >&2; exit 1; }
        workers=()
    fi
done < "$destination/PARTS.tsv"
for worker in "${workers[@]}"; do wait "$worker" || failed=1; done
[[ $failed == 0 ]] || { echo '下载未完成；再次运行可继续下载。' >&2; exit 1; }
bash "$destination/extract.sh" "$destination"
