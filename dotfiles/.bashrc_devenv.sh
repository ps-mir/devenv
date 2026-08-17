source ~/.devenv/scripts/git-prompt.sh
[ -f ~/nvm.sh ] && source ~/nvm.sh
[ -d /usr/local/go/bin ] && export PATH=$PATH:/usr/local/go/bin

export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SHOWUNTRACKEDFILES=1
export GIT_PS1_SHOWUPSTREAM="auto"
export GIT_PS1_SHOWCOLORHINTS=1

PS1='\u@\h:\w$(__git_ps1 " (%s)")\$ '

[ -f /usr/share/doc/fzf/examples/key-bindings.bash ] && source /usr/share/doc/fzf/examples/key-bindings.bash
[ -f /usr/share/doc/fzf/examples/completion.bash ] && source /usr/share/doc/fzf/examples/completion.bash
command -v zoxide &>/dev/null && eval "$(zoxide init bash)"

# Claude Code telemetry (OTLP -> local collector on :4317)
export CLAUDE_CODE_ENABLE_TELEMETRY=1
export CLAUDE_CODE_ENHANCED_TELEMETRY_BETA=1
export OTEL_METRICS_EXPORTER=otlp
export OTEL_LOGS_EXPORTER=otlp
export OTEL_TRACES_EXPORTER=otlp
export OTEL_EXPORTER_OTLP_PROTOCOL=grpc
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
# default metric export interval is 60s — too slow for a manual check, shrink it
export OTEL_METRIC_EXPORT_INTERVAL=5000
