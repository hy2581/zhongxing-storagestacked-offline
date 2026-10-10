#!/usr/bin/env bash
set -euo pipefail
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
image=${STORAGE_IMAGE:-zhongxing-storagestacked:offline-20261009-burst}
archive=$here/zhongxing-storagestacked-offline.tar.gz
if ! command -v docker >/dev/null; then
    echo '需要宿主机已安装并启动 Docker；无需安装项目依赖。' >&2; exit 1
fi
if ! docker info >/dev/null 2>&1; then echo '无法访问 Docker 服务。' >&2; exit 1; fi
if ! docker image inspect "$image" >/dev/null 2>&1; then
    if [[ ! -f $archive ]]; then echo "缺少镜像，请把 $archive 放在此脚本旁边。" >&2; exit 1; fi
    docker load --input "$archive"
fi
[[ $(docker image inspect "$image" --format '{{.Architecture}}') == amd64 ]] || { echo '镜像架构必须为 amd64。' >&2; exit 1; }
results=${STORAGE_RESULTS_DIR:-$here/results}
mkdir -p "$results"
results=$(cd -- "$results" && pwd)
args=("${@:-all}")
options=(--rm --init --pull=never --network=none --mount "type=bind,source=$results,target=/results")
if [[ ${1:-all} == shell && -t 0 && -t 1 ]]; then options+=(-it); fi
# Optional host inputs are mounted read-only and snapshotted by the project.
for ((i=0; i<${#args[@]}; i++)); do
    mount_name=
    if [[ ${args[i]} == --config && ( ${args[0]} == vortex || ${args[0]} == coralnpu ) ]]; then
        mount_name=config.json
    elif [[ ${args[i]} == --input && ${args[0]} == axi ]]; then
        mount_name=transactions.json
    fi
    if [[ -n $mount_name ]]; then
        ((i+1<${#args[@]})) || { echo "${args[i]} 缺少文件路径" >&2; exit 2; }
        input_path=$(realpath -- "${args[i+1]}")
        [[ -f $input_path ]] || { echo "输入文件不存在：$input_path" >&2; exit 2; }
        options+=(--mount "type=bind,source=$input_path,target=/input/$mount_name,readonly")
        args[i+1]=/input/$mount_name
    fi
done
# Bind mount ownership is handled in the container, including failed runs.
options+=(-e "DELIVERY_UID=$(id -u)" -e "DELIVERY_GID=$(id -g)")
exec docker run "${options[@]}" "$image" "${args[@]}"
