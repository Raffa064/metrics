import colorful

function metrics/main() {
  metrics/file-metrics $@
  
  if git branch >/dev/null 2>&1; then
    metrics/git-metrics
  fi
}

function metrics/file-metrics() {
  local path
  local regex=".*"
  local file_ext="*"
  local exclude_dirs=()

  local opt
  while getopts "p:r:t:n:w:" opt; do
    case $opt in
      p) path="$OPTARG";;
      r) regex="$OPTARG";;
      t) file_ext="$OPTARG";;
      n) read -a exclude_dirs <<< "$OPTARG";;
      *) error "Invalid option"; exit;;
    esac
  done

  if [ -z "$path" ]; then
    path="$(pwd)"
  fi

  local exclude_exp
  for excluded in "${exclude_dirs[@]}"; do
    exclude_exp+=" -not -path '$excluded'"
  done

  local find_command="find $path -regex '$regex' -type f -name '*.$file_ext'$exclude_exp | xargs wc"

  local wcArgs=( 
    "-l lines"
    "-w words"
    "-m chars"
    "-c bytes"
  )

  echoe "${fy}File metrics"

  local arg
  for arg in "${wcArgs[@]}"; do
    local arg_flag
    local arg_name

    read arg_flag arg_name <<< "$arg"

    local result=$(eval "$find_command $arg_flag" | grep total)
    result=$(sed "s/total/$arg_name/" <<< "$result")
    echoe "  $fg*$Sr $result"
  done

}

function metrics/git-metrics() {
  echoe "${fr}Git metrics:"

  local commit_count=$(git log --pretty=%ad | wc -l)
  local branch_count=$(git branch | wc -l)
  local work_days=$(git log --pretty=%ad --date=format:%Y-%m-%d | uniq | wc -l)

  echoe "  $fg*$Sr $commit_count commits"
  echoe "  $fg*$Sr $branch_count branches"
  echoe "  $fg*$Sr $work_days days worked"
}
