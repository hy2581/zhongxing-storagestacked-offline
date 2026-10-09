# 三项目离线 Docker 分块包

本包包含 Linux amd64 完整 Docker 镜像、运行入口、源码、工具链、模型与验收文档。CoralNPU 启用 RVV，Vortex 的默认 LLM 使用 8 个 SIMT 线程。

推荐使用发布仓库中的下载脚本，自动下载后解包：

```bash
git clone https://github.com/hy2581/zhongxing-storagestacked-offline.git
cd zhongxing-storagestacked-offline
bash download.sh
cd downloads/zhongxing-storagestacked-offline-20261009
bash run.sh
```

下载支持续传，已完成且大小符合清单的分块会跳过。也可在 Release 页面手动下载。

下载全部 `zhongxing-storagestacked-offline-20261009.tar.part-*`、`PARTS.tsv` 和 `extract.sh`，放在同一个目录，然后执行：

```bash
bash extract.sh
cd zhongxing-storagestacked-offline-20261009
bash run.sh
```

可以用 `bash extract.sh /目标路径` 指定解压位置。已有交付目录不会被覆盖。脚本需要 Linux 上的 Bash、tar 和常用命令，不需要 Python。

共 412 块，每块 25,000,000 字节，最后一块 174,400 字节。清单只记录文件名和大小，不做哈希校验。脚本按清单顺序合并并解包，直接恢复完整交付目录，不额外保存合并后的大 tar 文件。镜像在交付目录中保持 gzip 压缩，首次运行 `bash run.sh` 自动导入，之后使用 `--pull=never --network=none` 运行。

预留解包、Docker 镜像导入与结果目录的空间：解包约 10.3 GB，镜像约 23.9 GB，另需数 GB 运行结果和 Docker 临时空间。`PACKAGE.json` 记录源码版本与文件大小；解包后的 `VALIDATION.json` 和 `ACCEPTANCE.json` 是本次制作方的实际验收摘要。

分块是一个外层 tar 的连续片段，不能逐块单独解压。Docker 镜像已压缩，外层不重复压缩。
