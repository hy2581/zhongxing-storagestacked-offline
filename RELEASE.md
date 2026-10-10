新版完整 Linux amd64 离线 Docker 交付：AXI、Vortex SIMT 与 CoralNPU RVV，包含源码、工具链、TinyLLM 及验收报告。

镜像 `zhongxing-storagestacked:offline-20261009-burst`。CoralNPU AXI256 接入默认使用 4 拍 INCR burst，并通过 1、2、4、8、16 拍的字节掩码、反压、重放和错误输入测试。Vortex 默认 TinyLLM 使用 8 个线程、2 个 warp。

412 个分块，每块 25,000,000 字节，最后一块 522,560 字节。仅核对文件名、大小、实际解包、Docker 导入和运行结果，无哈希校验。

克隆本仓库后执行 `bash download.sh`，自动下载分块并解包；已有全部分块时执行 `bash extract.sh`。解包后进入 `zhongxing-storagestacked-offline-20261009-burst/`，执行 `bash run.sh`。

完整回归和默认五项断网验收均通过。分块恢复后的镜像已实际导入 Docker 并通过工具检查，详见 `SPLIT_ACCEPTANCE.json`。

## 2026-10-10 正式 Docker 兼容修复

新版 `run.sh` 保留 Docker seccomp，使用 `docker-compat-entrypoint.py` 让 glibc
在旧 Docker 的 `clone3` 被拒绝时回退，修复 `posix_spawn failed: Operation not permitted`。
默认不关闭 seccomp，不需要手动修改启动命令。下载及解包自动安装最新启动补丁，
旧归档入口备份为 `run-original.sh`。

已解包用户单独下载 `run.sh`、`docker-compat-entrypoint.py`、`run-seccomp-check.sh` 和
`DOCKER_COMPATIBILITY.md`，放到离线包目录即可运行 `sudo bash run.sh vortex smoke`。
进入源码执行 `sudo bash run.sh shell`。`run-seccomp-check.sh` 仅保留为临时诊断入口。
原 412 个分块和大镜像没有重建或替换，无需重新下载。

制作方用模拟旧版拒绝行为的策略复现原错误，确认修复后编译成功，并验证其他
系统调用拒绝规则仍生效。模拟旧策略下完整 Vortex SMOKE 通过（41 → 42），
默认策略下 CoralNPU SMOKE 与 AXI 也通过，见 `DOCKER_FIX_VALIDATION.json`。
客户曾通过关闭 seccomp 越过编译阶段；客户完整报告及正式补丁实测仍待提供。
原镜像此前制作方默认五项复测通过，见 `RUNTIME_RECHECK.json`，不代替客户实测。
三个源码仓库和中文讲解的提交号见 `CURRENT_SOURCES.json`。
