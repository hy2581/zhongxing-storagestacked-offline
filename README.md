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

## Docker 20.10.0 编译失败

如果编译日志出现 `posix_spawn failed: Operation not permitted`，请阅读
[Docker 兼容说明](DOCKER_COMPATIBILITY.md)。在克隆仓库后自动下载并解包的目录中，
最新 `download.sh` 会把仓库中的兼容入口与说明自动复制到解包目录。已解包的旧目录可直接复制最新兼容入口：

```bash
cd downloads/zhongxing-storagestacked-offline-20261009-burst
cp ../../run-seccomp-check.sh .
sudo bash run-seccomp-check.sh vortex smoke
```

等待最终 `PASS` 后，用 `sudo bash run-seccomp-check.sh` 执行默认五项验收。
`sudo bash run-seccomp-check.sh shell` 进入容器，执行 `ls` 可看到三个项目；
`cd vortex_StorageStacked` 后执行 `ls docs` 查看中文文档，输入 `exit` 退出。
兼容脚本只对本次容器关闭 seccomp，继续断网且不拉取镜像。
默认 `run.sh` 保留原安全策略；长期应更新 Docker 和配套运行时。

已下载旧归档的用户也可以从同一 Release 单独下载 `run-seccomp-check.sh`，
放在原 `run.sh` 旁边使用。原 412 个分块及镜像是固定的 2026-10-09 快照；
2026-10-10 更新的是 GitHub 源码、中文文档、制作脚本、兼容入口和复测记录，
本次没有重建或替换已发布的大镜像。

## 最新源码与制作入口

三个项目与中文逐文件讲解分别维护在：

- [AXI 存储](https://github.com/hy2581/axi_StorageStacked)
- [Vortex SIMT](https://github.com/hy2581/vortex_StorageStacked)
- [CoralNPU RVV 与 AXI burst](https://github.com/hy2581/coralnpu_StorageStacked)
- [中文逐文件讲解](https://github.com/hy2581/StorageStacked-docs)

本次提交号见 [CURRENT_SOURCES.json](CURRENT_SOURCES.json)，冻结镜像的历史来源仍见
`PACKAGE.json`。制作脚本与 Dockerfile 位于 [offline/](offline/README.md)，
包括构建、验收、导出、分块、下载和上传入口。制作时需把三个已准备好工具和缓存的
项目及 `markdown/` 放在同一工作区，再把 `offline/`、根目录 `README.md` 和
`accept.sh` 放到该工作区；这些脚本不承担首次下载依赖的职责。

2026-10-10 在已导入原镜像上重新运行默认五项全部通过，两个 SMOKE 输出 `42`，
两个 LLM 输出 `blu`。没有重新导入镜像或重跑 `test` 全回归。
28 个待发布的运行源码、配置及新增源文件与复测镜像逐字节相同。
客户提供 Docker 客户端 20.10.0，并确认兼容入口已越过编译进入仿真；
客户完整验收仍以自己的最终 `summary.json` 为准。
