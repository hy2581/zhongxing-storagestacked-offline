# 三项目离线 Docker 分块包

本包包含 Linux amd64 完整 Docker 镜像、运行入口、源码、工具链、模型与验收文档。CoralNPU 启用 RVV，AXI256 接入默认使用 4 拍 INCR burst，并通过 1、2、4、8、16 拍测试；Vortex 的默认 LLM 使用 8 个 SIMT 线程。

推荐克隆发布仓库后执行 `bash download.sh`，自动下载分块并解包：

```bash
git clone https://github.com/hy2581/zhongxing-storagestacked-offline.git
cd zhongxing-storagestacked-offline
bash download.sh
cd downloads/zhongxing-storagestacked-offline-20261009-burst
bash run.sh
```

下载默认使用单连接，支持续传，已完成且大小符合清单的分块会跳过。每 5 秒显示当前分块已下载的字节数和百分比；连续 60 秒传输速度低于 1 字节/秒会中止当前请求并重试，单次请求最多 900 秒。每个文件最多尝试 6 次。按 Ctrl+C 可停止下载并保留续传文件。

下载全部 `zhongxing-storagestacked-offline-20261009-burst.tar.part-*`、`PARTS.tsv` 和 `extract.sh`，放在同一个目录，然后执行：

```bash
bash extract.sh
cd zhongxing-storagestacked-offline-20261009-burst
bash run.sh
```

可以用 `bash extract.sh /目标路径` 指定解压位置。已有交付目录不会被覆盖。脚本需要 Linux 上的 Bash、tar 和常用命令，不需要 Python。

共 412 块，每块 25,000,000 字节，最后一块 522,560 字节。清单只记录文件名和大小，不做哈希校验。脚本按清单顺序合并并解包，直接恢复完整交付目录，不额外保存合并后的大 tar 文件。镜像在交付目录中保持 gzip 压缩，首次运行 `bash run.sh` 自动导入，之后使用 `--pull=never --network=none` 运行。

分块文件约 10.3 GB，解包后的交付目录约 10.3 GB，Docker 镜像约 23.9 GB；首次导入还会临时展开约 24 GB，默认验收会生成数 GiB 结果。下载目录、结果目录和 Docker 数据目录如果在同一块磁盘，建议至少预留 100 GB 可用空间；如果在不同磁盘，需要分别检查各自剩余空间。首次导入和默认验收可能耗时数十分钟。`PACKAGE.json` 记录源码版本与文件大小；解包后的 `VALIDATION.json` 和 `ACCEPTANCE.json` 是本次制作方的实际验收摘要。

分块是一个外层 tar 的连续片段，不能逐块单独解压。Docker 镜像已压缩，外层不重复压缩。

## 代理连接或续传失败

下载长时间没有进度时，先按 Ctrl+C 停止原来的脚本，再更新仓库并继续下载：

```bash
git pull --ff-only
bash download.sh
```

脚本保留大小正确的已完成分块；完整的 `.downloading` 文件直接接收，过大的临时文件重新下载，HTTP 416 或不支持 Range 时从头下载当前分块。错误提示会显示实际字节数、期望字节数和 HTTP 状态。`Proxy CONNECT aborted` 仍需检查客户端代理连接。

若进度字节数持续增加，说明正在下载；若一直不变且反复出现 `Proxy CONNECT aborted`，需要检查客户端代理到 GitHub 下载地址的连接。可用 `STORAGE_DOWNLOAD_JOBS=2 bash download.sh` 指定并发数（1..16）；超时分别由 `STORAGE_STALL_SECONDS` 和 `STORAGE_REQUEST_SECONDS` 设置，单位为秒。

## 运行环境与下载兼容性

宿主机需要 Linux x86_64、Bash、curl、GNU tar/coreutils，以及已启动且当前用户可访问的 Docker。下载脚本已用实际的 Bash 4.2 + curl 7.29 和 Bash 5.2 + curl 8.5 测试续传、大小错误、HTTP 416、停滞超时、中断清理和 HTTPS 代理跳转。旧版 curl 不支持的 `--http1.1` 参数会自动省略；TLS 证书验证保持开启。

克隆成功只说明仓库连接可用，Release 分块会跳转到文件下载地址，代理也需要允许这条连接。脚本的超时和重试不能保证被代理持续拒绝的地址可下载。客户机器最终以实际下载、解包，以及 `bash run.sh` 生成的 `summary.json` 中 `passed: true` 为验收依据。

制作方复核结果见 [CLIENT_VALIDATION.json](CLIENT_VALIDATION.json)。本次在空 Docker 环境中自动导入后，AXI、Vortex SMOKE/LLM、CoralNPU SMOKE/LLM 五项均通过，两个 SMOKE 输出 `42`，两个 LLM 输出 `blu`。本机首次导入和五项验收共约 41 分钟。公网实际下载 6 个分块，其余 406 个复用本地大小符合清单的分块后恢复完整交付包。此记录区分制作方验证和客户机器实际验收，客户系统与代理仍需实际确认。
