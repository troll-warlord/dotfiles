# === Exports ===
export EDITOR=vim
export VISUAL=vim
export LANG=en_US.UTF-8

# === History ===
HISTFILE="${HOME}/.bash_history"
HISTSIZE=50000
HISTFILESIZE=50000
HISTCONTROL=ignoreboth:erasedups    # ignore duplicates and lines starting with space
HISTIGNORE="exit:clear:history:pwd"
HISTTIMEFORMAT="%F %T "             # record timestamp with each entry
shopt -s histappend

# === Colors ===
# \001/\002 are readline zero-width markers; required for correct line-length in PS1.
_C_GREEN=$'\001\e[32m\002'
_C_CYAN=$'\001\e[36m\002'
_C_YELLOW=$'\001\e[33m\002'
_C_MAGENTA=$'\001\e[35m\002'
_C_RED=$'\001\e[31m\002'
_C_RESET=$'\001\e[0m\002'

# === Prompt ===
# DEBUG trap fires before every command; _cmd_timer_started ensures only the first per cycle is timed.
_cmd_timer_started=0
_cmd_start=
_kube_config_mtime=0

_preexec_hook() {
    [[ -n "$COMP_LINE" ]] && return           # skip tab-completion
    (( _cmd_timer_started == 0 )) || return    # only record the first command
    _cmd_start=$SECONDS
    _cmd_timer_started=1
}

_build_prompt() {
    local captured_start=$_cmd_start   # capture before any subcommands overwrite it

    # Auto-refresh kube cache if ~/.kube/config was modified externally (e.g. aws eks update-kubeconfig)
    local current_mtime
    current_mtime=$(stat -c %Y "${HOME}/.kube/config" 2>/dev/null || echo 0)
    if [[ "$current_mtime" != "$_kube_config_mtime" ]]; then
        _kube_config_mtime=$current_mtime
        _refresh_kube_cache
    fi

    # Git branch
    local branch git_info=""
    branch=$(git symbolic-ref --short HEAD 2>/dev/null)
    [[ -n "$branch" ]] && git_info=" ${_C_YELLOW}(${branch})${_C_RESET}"

    # Execution duration
    local duration_info=""
    if [[ -n $captured_start ]]; then
        local duration=$(( SECONDS - captured_start ))
        if (( duration >= 3600 )); then
            duration_info=" ${_C_RED}took $(( duration / 3600 ))h$(( (duration % 3600) / 60 ))m$(( duration % 60 ))s${_C_RESET}"
        elif (( duration >= 60 )); then
            duration_info=" ${_C_YELLOW}took $(( duration / 60 ))m$(( duration % 60 ))s${_C_RESET}"
        elif (( duration >= 1 )); then
            duration_info=" ${_C_YELLOW}took ${duration}s${_C_RESET}"
        fi
    fi

    # Sync history across open terminals
    history -a; history -c; history -r

    PS1="\n${_C_GREEN}\u@\h${_C_RESET}${_kube_info} ${_C_CYAN}\w${_C_RESET}${git_info}${duration_info}\n\$ "

    _cmd_start=
    _cmd_timer_started=0   # re-arm trap for next user command - MUST be last statement
}
PROMPT_COMMAND="_build_prompt"

# === Utility functions ===

encode() { echo -n "$1" | base64; }
decode() { echo -n "$1" | base64 -d; }

# Show the currently active kubectl context (header + active row)
whereami() {
    kubectl config get-contexts | {
        head -1
        grep -F '*'
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
        local ctx ns
        ctx=$(kubectl config current-context 2>/dev/null)
        if [[ -n "$ctx" ]]; then
            ns=$(kubectl config view --minify --output 'jsonpath={..namespace}' 2>/dev/null)
            _kube_info=" ${_C_MAGENTA}[${ctx} | ${ns:-default}]${_C_RESET}"
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

alias ll="ls -lAh --color=auto"
alias la="ls -A --color=auto"
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias mkdir="mkdir -p"
alias grep="grep --color=auto"
alias df="df -h"
alias duh="du -sh"
alias ports="ss -tulnp"
alias myip="curl -s ifconfig.me"
alias reload="source ~/.bashrc.local"


# === Aliases - Project shortcuts ===

alias wh="whereami"
uk() { update_kubeconfig; _refresh_kube_cache; }

# === Startup ===
update_kubeconfig    # merge all kubeconfigs in ~/.kube into $KUBECONFIG
_refresh_kube_cache  # populate kube prompt info on shell start

# Enable timing trap AFTER startup so .bashrc sourcing itself doesn't count
trap '_preexec_hook' DEBUG

# === Pre-loaded history ===
# Commands injected into shell history on startup without being executed.
# Access them with Ctrl+R or the up arrow.
_load_preset_history() {
    local -a cmds=(
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
    for cmd in "${cmds[@]}"; do
        history -s "$cmd"
    done
}
_load_preset_history
unset -f _load_preset_history