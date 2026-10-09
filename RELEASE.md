新版完整 Linux amd64 离线 Docker 交付：AXI、Vortex SIMT 与 CoralNPU RVV，包含源码、工具链、TinyLLM 及验收报告。

镜像 `zhongxing-storagestacked:offline-20261009-burst`。CoralNPU AXI256 接入默认使用 4 拍 INCR burst，并通过 1、2、4、8、16 拍的字节掩码、反压、重放和错误输入测试。Vortex 默认 TinyLLM 使用 8 个线程、2 个 warp。

412 个分块，每块 25,000,000 字节，最后一块 522,560 字节。仅核对文件名、大小、实际解包、Docker 导入和运行结果，无哈希校验。

克隆本仓库后执行 `bash download.sh`，自动下载分块并解包；已有全部分块时执行 `bash extract.sh`。解包后进入 `zhongxing-storagestacked-offline-20261009-burst/`，执行 `bash run.sh`。

完整回归和默认五项断网验收均通过。分块恢复后的镜像已实际导入 Docker 并通过工具检查，详见 `SPLIT_ACCEPTANCE.json`。
