fpath+=/opt/homebrew/share/zsh/site-functions
autoload -Uz compinit && compinit

# === Exports ===
export EDITOR=vim
export VISUAL=vim
export LANG=en_US.UTF-8

# === History ===
HISTFILE="${HOME}/.zsh_history"
HISTSIZE=50000          # lines kept in memory
SAVEHIST=50000          # lines written to HISTFILE

setopt HIST_IGNORE_DUPS       # skip duplicate of the previous entry
setopt HIST_IGNORE_ALL_DUPS   # remove older duplicate anywhere in history
setopt HIST_IGNORE_SPACE      # skip entries that start with a space
setopt HIST_REDUCE_BLANKS     # strip extra blanks before saving
setopt HIST_VERIFY            # show expanded history before executing
setopt SHARE_HISTORY          # share history across all open shells
setopt EXTENDED_HISTORY       # record timestamp and duration (:start:elapsed;cmd)

# Commands to exclude from history (prefix with a space, or add patterns here)
# Add any command you never want recorded, e.g. secrets, noisy one-liners.
# Example: HISTORY_IGNORE="(ls|ll|cd|pwd|exit|clear|history)"
HISTORY_IGNORE="(exit|clear|history|pwd)"

# === Prompt ===
# Two-line prompt showing: user@host | path | git branch | kube context
# Format: user@host ~/path (branch) [kube: ctx/ns] [took Xs]
#         %

# Enable vcs_info for Git branch info
autoload -Uz vcs_info

_kube_config_mtime=0

precmd() {
	vcs_info

	# Execution duration (only shown if >= 1s)
	if [[ -n $_cmd_start ]]; then
		local duration=$((SECONDS - _cmd_start))
		if ((duration >= 3600)); then
			_cmd_duration=" %F{red}took $((duration / 3600))h$(((duration % 3600) / 60))m$((duration % 60))s%f"
		elif ((duration >= 60)); then
			_cmd_duration=" %F{yellow}took $((duration / 60))m$((duration % 60))s%f"
		elif ((duration >= 1)); then
			_cmd_duration=" %F{yellow}took ${duration}s%f"
		else
			_cmd_duration=""
		fi
		unset _cmd_start
	else
		_cmd_duration=""
	fi

	# Auto-refresh kube cache if ~/.kube/config was modified externally (e.g. aws eks update-kubeconfig)
	local current_mtime
	current_mtime=$(stat -f %m "${HOME}/.kube/config" 2>/dev/null || echo 0)
	if [[ "$current_mtime" != "$_kube_config_mtime" ]]; then
		_kube_config_mtime=$current_mtime
		_refresh_kube_cache
	fi
}

preexec() {
	_cmd_start=$SECONDS
}

# Git branch format: (branch-name)
zstyle ':vcs_info:git:*' formats '(%b)'

setopt prompt_subst

# Prompt segments:
#   %F{green}%n@%m%f     - user@host in green
#   %F{cyan}%~%f         - current directory in cyan
#   %F{yellow}...%f      - git branch in yellow (empty when not in a repo)
#   $_kube_info          - kube context/namespace in magenta (empty when not set)
#   $_cmd_duration       - last command duration in yellow/red (empty for fast cmds)
PROMPT=$'\n''%F{green}%n@%m%f %F{cyan}%~%f %F{yellow}${vcs_info_msg_0_}%f${_kube_info}${_cmd_duration}
%# '

# === Utility functions ===

# base64 encode a string
encode() {
	echo -n $1 | base64
}

# base64 decode a string
decode() {
	echo -n $1 | base64 -D
}

# Show the currently active kubectl context (header + active row)
whereami() {
	kubectl config get-contexts | {
		head -1
		grep '*'
	}
}

# Build KUBECONFIG from all kubeconfig files in ~/.kube.
# Picks up .json, .yaml, and .yml files in addition to the default config.
update_kubeconfig() {
	export KUBECONFIG="${HOME}/.kube/config"
	for config in "${HOME}"/.kube/*.json "${HOME}"/.kube/*.yaml "${HOME}"/.kube/*.yml; do
		[[ -f "$config" ]] && export KUBECONFIG="$KUBECONFIG:$config"
	done
}

# Cache kubectl context/namespace - refresh only on context/namespace switch.
# Avoids spawning kubectl subprocesses on every prompt render.
_refresh_kube_cache() {
	if command -v kubectl &>/dev/null && [[ -f "${HOME}/.kube/config" ]]; then
		local ctx
		ctx=$(kubectl config current-context 2>/dev/null)
		if [[ -n "$ctx" ]]; then
			local ns
			ns=$(kubectl config view --minify --output 'jsonpath={..namespace}' 2>/dev/null)
			_kube_info=" %F{magenta}[${ctx} | ${ns:-default}]%f"
		else
			_kube_info=""
		fi
	else
		_kube_info=""
	fi
}

# === Aliases - kubectl ===
alias k="kubectl"
alias kk="kubectl -n kube-system"

# Context and namespace switching (ksc/ksn refresh the kube prompt cache)
alias kgc="kubectl config get-contexts"
ksc() { kubectl config use-context "$@"; _refresh_kube_cache; }
ksn() { kubectl config set-context --current --namespace "$@"; _refresh_kube_cache; }
alias kcc="kubectl config current-context"

# Get resources (a = all namespaces, w = wide output)
alias kpo="kubectl get pods"
alias kpoa="kubectl get pods -A"
alias kpow="kubectl get pods -A -o wide"
alias ksvc="kubectl get services"
alias ksvca="kubectl get services -A"
alias king="kubectl get ingress -A"
alias kpv="kubectl get pv"
alias kpvc="kubectl get pvc"
alias kpvca="kubectl get pvc -A"
alias kde="kubectl get deployments"
alias kdea="kubectl get deployments -A"
alias ksts="kubectl get statefulsets"
alias kstsa="kubectl get statefulsets -A"
alias kns="kubectl get namespaces"
alias kda="kubectl get daemonsets"
alias kdaa="kubectl get daemonsets -A"
alias kcm="kubectl get configmaps"
alias ksec="kubectl get secrets"
alias kno="kubectl get nodes"
alias know="kubectl get nodes -o wide"
alias kev="kubectl get events --sort-by='.lastTimestamp'"
alias keva="kubectl get events -A --sort-by='.lastTimestamp'"
alias kcrd="kubectl get crds"

# Describe resources
alias kd="kubectl describe"
alias kdp="kubectl describe pod"
alias kdd="kubectl describe deployment"
alias kds="kubectl describe service"
alias kdn="kubectl describe node"

# Logs
alias kl="kubectl logs"
alias klf="kubectl logs -f"
alias klp="kubectl logs -f --previous"

# Exec into a container
alias kex="kubectl exec -it"

# Apply and delete manifests
alias kaf="kubectl apply -f"
alias kdf="kubectl delete -f"
alias kdel="kubectl delete"

# Rollout management
alias krr="kubectl rollout restart deployment"
alias krs="kubectl rollout status deployment"
alias krh="kubectl rollout history deployment"

# Resource usage (requires metrics-server)
alias ktop="kubectl top pods -A"
alias kton="kubectl top nodes"

# Watch for live updates
alias kwpo="watch kubectl get pods"
alias kwpoa="watch kubectl get pods -A"
alias kwno="watch kubectl get nodes"


# === Aliases - Helm ===

alias hl="helm list -A"
alias hru="helm repo update"


# === Aliases - Git ===

alias gl="git log --oneline --graph --decorate -20"


# === Aliases - AWS ===

alias awsid="aws sts get-caller-identity"


# === Aliases - General shell ===

alias ll="ls -lAh"
alias la="ls -A"
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias mkdir="mkdir -p"
alias grep="grep --color=auto"
alias df="df -h"
alias duh="du -sh"
alias ports="lsof -iTCP -sTCP:LISTEN -n -P"
alias myip="curl -s ifconfig.me"
alias reload="source ~/.zshrc"


# === Aliases - Project shortcuts ===

alias wh="whereami"
uk() { update_kubeconfig; _refresh_kube_cache; }

# === Startup ===
update_kubeconfig    # merge all kubeconfigs in ~/.kube into $KUBECONFIG
_refresh_kube_cache  # populate kube prompt info on shell start

# === Pre-loaded history ===
# Commands injected into shell history on startup without being executed.
# Access them with Ctrl+R or the up arrow. Add one entry per line.
() {
  local -a preset_history=(
    # kubectl
    "kubectl get pods -A"
    "kubectl get nodes -o wide"
    "kubectl describe pod "
    "kubectl logs -f "
    "kubectl exec -it  -- /bin/bash"
    "kubectl apply -f "
    "kubectl delete pod  --force --grace-period=0"
    "kubectl config get-contexts"
    "kubectl config use-context "
    "kubectl config set-context --current --namespace "
    "kubectl rollout restart deployment "
    "kubectl top nodes"
    "kubectl top pods -A"

    # git
    "git fetch --all --prune"

    # AWS / EKS
    "aws sts get-caller-identity"
    "aws eks update-kubeconfig --region  --name "
    "aws s3 ls s3://"

    # helm
    "helm list -A"
    "helm status  -n "
    "helm history  -n "
    "helm upgrade --install  ./chart -f values.yaml -n "
    "helm upgrade --install  ./chart -f values.yaml -n  --dry-run"
    "helm rollback  0 -n "
    "helm uninstall  -n "
    "helm get values  -n "
    "helm get manifest  -n "
    "helm template  ./chart -f values.yaml"
    "helm repo add  "
    "helm repo update"
    "helm search repo "
    "helm show values "

    # ssh
    "ssh -i ~/.ssh/id_rsa "

    # Add your own commands below
  )

  for cmd in "${preset_history[@]}"; do
    print -s "$cmd"
  done
}