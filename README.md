# dotfiles

Shell configuration for macOS (zsh) and Ubuntu/WSL (bash), plus a vim config.

| File      | Platform              | Install as        |
| --------- | --------------------- | ----------------- |
| `.zshrc`  | macOS (Apple Silicon) | `~/.zshrc`        |
| `.bashrc` | Ubuntu / WSL          | `~/.bashrc.local` |
| `.vimrc`  | macOS + Linux         | `~/.vimrc`        |

## Installation

```sh
git clone https://github.com/troll-warlord/dotfiles.git
cd dotfiles
```

### macOS

```sh
cp .zshrc ~/.zshrc
cp .vimrc ~/.vimrc
mkdir -p ~/.vim/undodir
source ~/.zshrc
```

### Ubuntu / WSL

```sh
cp .bashrc ~/.bashrc.local
cp .vimrc ~/.vimrc
mkdir -p ~/.vim/undodir
echo 'source ~/.bashrc.local' >> ~/.bashrc
source ~/.bashrc.local
```

## Prerequisites

| Tool      | Required for                     |
| --------- | -------------------------------- |
| `kubectl` | All `k*` aliases and kube prompt |
| `helm`    | `hl`, `hru`                      |
| `git`     | `gl`, prompt branch display      |
| `aws` CLI | `awsid`                          |

## Prompt

```sh
user@host [kube: context/namespace] ~/path (branch) took 3s
$
```

| Colour     | Segment                                                         |
| ---------- | --------------------------------------------------------------- |
| green      | user@host                                                       |
| cyan       | current directory                                               |
| yellow     | git branch (hidden outside repos)                               |
| magenta    | kube context/namespace (hidden when kubectl not configured)     |
| yellow/red | last command duration (hidden for fast commands, shown if ≥ 1s) |

The kube segment auto-refreshes whenever `~/.kube/config` is modified — so after `aws eks update-kubeconfig` the prompt updates on the next render with no manual step.

## Functions

| Command        | Description                                                          |
| -------------- | -------------------------------------------------------------------- |
| `ksc <ctx>`    | Switch kubectl context and refresh prompt                            |
| `ksn <ns>`     | Switch kubectl namespace and refresh prompt                          |
| `uk`           | Rebuild `KUBECONFIG` from all files in `~/.kube/` and refresh prompt |
| `wh`           | Show active kubectl context (header + active row)                    |
| `encode <str>` | base64 encode a string                                               |
| `decode <str>` | base64 decode a string                                               |

## Aliases

### kubectl

| Alias                         | Expands to                                 |
| ----------------------------- | ------------------------------------------ |
| `k`                           | `kubectl`                                  |
| `kk`                          | `kubectl -n kube-system`                   |
| `kgc` / `kcc`                 | config get-contexts / current-context      |
| `kpo` / `kpoa` / `kpow`       | get pods / all-ns / wide                   |
| `ksvc` / `ksvca`              | get services / all-ns                      |
| `kde` / `kdea`                | get deployments / all-ns                   |
| `ksts` / `kstsa`              | get statefulsets / all-ns                  |
| `kda` / `kdaa`                | get daemonsets / all-ns                    |
| `kpvc` / `kpvca`              | get PVCs / all-ns                          |
| `kpv`                         | get PersistentVolumes                      |
| `kns`                         | get namespaces                             |
| `kno` / `know`                | get nodes / wide                           |
| `king`                        | get ingress (all-ns)                       |
| `kcm` / `ksec` / `kcrd`       | get configmaps / secrets / CRDs            |
| `kev` / `keva`                | get events sorted by time / all-ns         |
| `kd`                          | `kubectl describe`                         |
| `kdp` / `kdd` / `kds` / `kdn` | describe pod / deployment / service / node |
| `kl` / `klf` / `klp`          | logs / follow / previous                   |
| `kex`                         | `kubectl exec -it`                         |
| `kaf` / `kdf` / `kdel`        | apply -f / delete -f / delete              |
| `krr` / `krs` / `krh`         | rollout restart / status / history         |
| `ktop` / `kton`               | top pods (all-ns) / top nodes              |
| `kwpo` / `kwpoa` / `kwno`     | watch pods / all-ns / nodes                |

### Other

| Alias       | Expands to                                                |
| ----------- | --------------------------------------------------------- |
| `hl`        | `helm list -A`                                            |
| `hru`       | `helm repo update`                                        |
| `gl`        | `git log --oneline --graph --decorate -20`                |
| `awsid`     | `aws sts get-caller-identity`                             |
| `ll` / `la` | `ls -lAh` / `ls -A`                                       |
| `ports`     | list listening TCP ports (`lsof` on macOS, `ss` on Linux) |
| `myip`      | show public IP via ifconfig.me                            |
| `reload`    | re-source the config file                                 |
| `wh`        | `whereami` (active kube context)                          |

## Preset history

Both files inject a curated set of commands into shell history at startup — available immediately via Ctrl+R without having typed them before. Covers kubectl, helm, AWS/EKS, git, and ssh.

To add your own entries, edit the preset history block at the bottom of the respective file.

## Vim

Works for both macOS and Linux. Run `mkdir -p ~/.vim/undodir` once after installing.

| Feature      | Detail                                                                         |
| ------------ | ------------------------------------------------------------------------------ |
| Indentation  | 4 spaces by default; 2 spaces for YAML, JSON, HTML, CSS, JS/TS                 |
| Syntax       | Enabled with filetype detection and per-language indent rules                  |
| Search       | Incremental + highlighted; `Esc Esc` to clear highlights                       |
| Mouse        | Enabled — scroll, click, visual select                                         |
| Clipboard    | Synced with system clipboard (`unnamed` on macOS, `unnamedplus` on Linux)      |
| Undo         | Persistent across sessions via `~/.vim/undodir`                                |
| Whitespace   | Tabs and trailing spaces made visible via `listchars`                          |
| Splits       | New splits open right / below                                                  |
| Line numbers | Absolute on current line, relative on all others (useful for `5j`/`10k` jumps) |
