新版完整 Linux amd64 离线 Docker 交付：AXI、Vortex SIMT 与 CoralNPU RVV，包含源码、工具链、TinyLLM 及验收报告。

镜像 `zhongxing-storagestacked:offline-20261009-burst`。CoralNPU AXI256 接入默认使用 4 拍 INCR burst，并通过 1、2、4、8、16 拍的字节掩码、反压、重放和错误输入测试。Vortex 默认 TinyLLM 使用 8 个线程、2 个 warp。

412 个分块，每块 25,000,000 字节，最后一块 522,560 字节。仅核对文件名、大小、实际解包、Docker 导入和运行结果，无哈希校验。

克隆本仓库后执行 `bash download.sh`，自动下载分块并解包；已有全部分块时执行 `bash extract.sh`。解包后进入 `zhongxing-storagestacked-offline-20261009-burst/`，执行 `bash run.sh`。

完整回归和默认五项断网验收均通过。分块恢复后的镜像已实际导入 Docker 并通过工具检查，详见 `SPLIT_ACCEPTANCE.json`。

## 2026-10-10 客户兼容与源码同步

新增 `run-seccomp-check.sh` 和 `DOCKER_COMPATIBILITY.md`。Docker 20.10.0 客户
原先在编译时出现 `posix_spawn failed: Operation not permitted`，关闭本次容器的
seccomp 后已进入仿真。该脚本是临时兼容验证；长期应更新 Docker 和配套运行时，
再使用默认 `run.sh`。

制作方 Docker 29.1.3 上重新执行默认五项验收全部通过，详见
`RUNTIME_RECHECK.json`。`SECCOMP_REPRODUCTION.json` 记录相同镜像下的最小复现。
客户完整 SMOKE 的最终报告尚未提供，不把编译恢复记成完整验收通过。

三个源码仓库和中文讲解同步至当前工作区版本，提交号见 `CURRENT_SOURCES.json`。
原 412 个分块及镜像维持冻结快照；已有归档单独取得兼容脚本即可重试，无需重新下载镜像。
