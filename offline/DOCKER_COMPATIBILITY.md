# Docker 20.10.0 编译失败与临时兼容入口

## 已定位的错误

2026-10-10 客户提供的编译日志在 Vortex 的 `vx_start.S` 处出现：

```text
clang++: fatal error: unable to execute command: posix_spawn failed: Operation not permitted
```

`make` 随后返回 2，外层 Python 才报告 `CalledProcessError`。客户提供的
`docker --version` 为 20.10.0；这条命令显示客户端版本，服务端版本需用
`sudo docker version` 查看。客户关闭本次容器的 seccomp 后已进入 `[2/3]`，
说明原来失败的编译阶段已通过；客户本次完整 SMOKE 的最终报告尚未提供。

镜像内 Vortex LLVM 使用独立的 glibc 2.34。制作方使用同一镜像编译最小
RV32 汇编程序：默认 Docker 29.1.3 策略通过；令 `clone3` 返回 `EPERM`
时复现相同的 `posix_spawn` 错误；令其返回 `ENOSYS` 时 glibc 回退并编译成功。
临时关闭 seccomp 的相同编译探针也通过。探针用于定位子进程创建问题，
不代替 SMOKE、LLM 或完整平台回归。

Docker 官方在 [20.10.10 发布记录](https://docs.docker.com/engine/release-notes/20.10/#201010)
中记录了默认 seccomp 对 `clone3` 的兼容支持；
[原始问题记录](https://github.com/moby/moby/issues/42680)说明 `EPERM` 会阻止 glibc 回退。

## 客户怎样重试

在包含原 `run.sh` 的离线包目录中，依次执行：

```bash
sudo cp run.sh run-seccomp-check.sh
sudo sed -i 's/--pull=never/--security-opt seccomp=unconfined --pull=never/' run-seccomp-check.sh
sudo bash run-seccomp-check.sh vortex smoke
```

也可以把发布仓库或 Release 附件中的 `run-seccomp-check.sh` 复制到原
`run.sh` 旁边，然后直接执行最后一行。这个入口保留原脚本，只为本次
容器关闭 seccomp，继续使用 `--pull=never --network=none`。
这是临时兼容验证，会减少该容器的系统调用隔离；长期应更新 Docker
和配套运行时组件，再使用原 `run.sh` 的默认策略。

`[1/3]` 是编译，`[2/3]` 是仿真，`[3/3]` 是计算与存储链路校验。
看到 `[2/3]` 表示编译成功，最终仍须看到 `PASS`，并确认结果
`summary.json` 中的 `passed` 为 `true`。仿真与波形校验可能持续数分钟。

SMOKE 通过后，执行默认五项验收：

```bash
sudo bash run-seccomp-check.sh
```

## 查看源码和中文文档

在宿主机离线包目录中执行：

```bash
sudo bash run-seccomp-check.sh shell
```

进入容器后：

```bash
ls
cd vortex_StorageStacked
ls
ls docs
```

工作区还包含 `axi_StorageStacked` 和 `coralnpu_StorageStacked`。
输入 `exit` 返回宿主机。容器退出后会删除，需保留的修改应写入 `/results`。

失败日志在宿主机原 `run.sh` 旁的 `results/<运行编号>/vortex/smoke/build.log`，
例如：

```bash
sudo tail -n 120 results/20261010-005824-3914f7e2/vortex/smoke/build.log
```

## 本次制作方复测

原镜像 `zhongxing-storagestacked:offline-20261009-burst` 在 Docker 29.1.3
默认策略下重新执行 `bash run.sh`，新运行编号
`20261010-010948-42c1906b`：AXI、Vortex SMOKE/LLM、CoralNPU SMOKE/LLM
五项均通过；两个 SMOKE 为 41 → 42，两个 LLM 均生成 `blu`。
本次复用已经导入的原镜像，没有重新导入归档，也没有重新执行 `test` 全回归。
28 个待发布的运行源码、配置及新源文件与本次验收镜像内文件逐字节比较一致。
这项比较不生成摘要算法值。

制作方默认五项通过、最小错误复现以及客户编译恢复分别记录，
不能将制作方通过或客户进入 `[2/3]` 写成客户完整验收通过。
