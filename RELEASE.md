完整 Linux amd64 离线 Docker 交付，包含 AXI、Vortex SIMT 与 CoralNPU RVV 平台、工具链、源码及 TinyLLM。

412 个分块，每块 25,000,000 字节，最后一块 174,400 字节。文件核对仅使用名称、大小与实际解包、Docker 导入和运行结果。

推荐克隆本仓库后执行 `bash download.sh`，自动下载分块并解包。已有全部分块时执行 `bash extract.sh`；解包后进入 `zhongxing-storagestacked-offline-20261009/`，执行 `bash run.sh`。

镜像 `zhongxing-storagestacked:offline-20261009`：CoralNPU RVV FP32；Vortex 默认 LLM 使用 8 个线程、2 个 warp。一次完整回归、归档自动导入和默认五项断网验收全部通过。分块恢复后的镜像也已实际导入并通过工具检查，见 `SPLIT_ACCEPTANCE.json`。
