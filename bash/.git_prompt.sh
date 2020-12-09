# git functions for the bash prompt -------------
function getCurrentGitBranch() {
    # This is faster than `git rev-parse --abbrev-ref HEAD 2> /dev/null`
    # Timed our solution more that twice as fast than the previous one.

    git symbolic-ref --short HEAD 2> /dev/null
}

function getCurrentGitRef() {
    # This is slower that getCurrentGitBranch
    # Use it only if the first solution returned nothing
    git rev-parse --abbrev-ref --symbolic-full-name HEAD
}

function getCurrentGitTag() {
    # TODO : This is a long operation. We should optimize it
    git describe --tags --exact-match HEAD 2> /dev/null
}

function getCurrentCommitHash() {
    git rev-parse HEAD 2> /dev/null
}

function isHeadDetached() {
    git symbolic-ref -q HEAD > /dev/null
    if [[ "0" == "$?" ]]; then
        echo false
    else
        echo true
    fi
}

function getGitRepoRoot() {
    git rev-parse --show-toplevel 2> /dev/null
}

function isGitRepo() {
    if [[ "" == "$(getGitRepoRoot)" ]]; then
        echo false
    else
        echo true
    fi
}

function getNumberOfChangedFiles() {
    # This is slow. We must find a better way to do this
    echo "$(git status -s | wc -l)"
}

function getUpstreamCommitHash() {
    git rev-parse '@{upstream}' 2> /dev/null
}

function getBranchInfo() {
    # arg1 : branchName
    local branchName=$1
    git branch -v 2> /dev/null | grep "* $branchName"
}

function getSpecialState() {
    local gitRootDir="$(getGitRepoRoot)/.git"
    local specialState

    if [[ -d "$gitRootDir/rebase-merge" ]] || [[ -d "$gitRootDir/rebase-apply" ]]; then
        # Rebase is ongoing
        specialState=rebase
    elif [[ -f "$gitRootDir/MERGE_HEAD" ]]; then
        # Merge is ongoing
        specialState=merge
    elif [[ -f "$gitRootDir/CHERRY_PICK_HEAD" ]]; then
        # Cherry-pick is ongoing
        specialState=pick
    elif [[ -f "$gitRootDir/REVERT_HEAD" ]]; then
        # Revert is ongoing
        specialState=revert
    elif [[ -f "$gitRootDir/BISECT_LOG" ]]; then
        # Bisect is ongoing
        specialState=bisect
    fi

    echo $specialState
}

function buildBranchWithUpstream() {
    local branchName=$1

    local branchInfo=$(getBranchInfo $branchName)

    local AHEAD
    local BEHIND
    local commitStatus
    local result

    if [[ $branchInfo =~ (\[ahead ([0-9]*)) ]]; then
        AHEAD="${BASH_REMATCH[2]}"
    fi

    if [[ $branchInfo =~ (behind ([0-9]*)) ]]; then
        BEHIND="${BASH_REMATCH[2]}"
    fi

    if [[ ! -z "$AHEAD" ]]; then
        commitStatus="$AHEAD"↗
        if [[ ! -z "$BEHIND" ]]; then
            commitStatus="$commitStatus $BEHIND"↘︎ #2198 for down
        fi
    else
        if [[ ! -z "$BEHIND" ]]; then
            commitStatus="$BEHIND"↘︎
        fi
    fi

    result="$branchName"

    if [[ ! -z "$commitStatus" ]]; then
        result="$result | $commitStatus"
    fi

    result="($result)"     # Branch has an upstream

    echo $result
}

function parseGitBranch() {
    local branchName
    local upstream
    local isBranch

    # Get current branch name
    branchName=$(getCurrentGitBranch)

    # Check if the branch is empty
    if [[ "" == "$branchName" ]]; then
        # echo "[DEBUG] <parseGitBranch> BRANCH is empty"

        # Check for tag.
        local TAG=$(getCurrentGitTag)
        if [[ "" != "$TAG" ]]; then
            branchName="$TAG"
        else
            local isDetached

            # Check if we are detached
            if isDetached=$(isHeadDetached); then
                branchName='detached'
                # Or show the short hash
                # branchName='#'$(git rev-parse --short HEAD 2> /dev/null)
                # Or the long hash, with no leading '#'
                # branchName=$(git rev-parse HEAD 2> /dev/null)
            # else
                # This branch may be a tag
                # echo "[DEBUG] <parseGitBranch> Not detached"

                # This shouldn't happen
            fi
        fi
    else
        # This is a named branch.  (It might be local or remote.)
        upstream=$(getUpstreamCommitHash)
        isBranch=true
    fi

    # echo "[DEBUG] <parseGitBranch> Got branch $branchName"

    local result

    if [[ -n "$branchName" ]]; then
        local specialState=$(getSpecialState)

        if [[ -n "$specialState" ]]; then
            result="{$branchName\\$specialState}"
        elif [[ -n "$isBranch" && -n "$upstream" ]]; then
            # Comparing commits w/ upstream
            result=$(buildBranchWithUpstream $branchName)
        elif [[ -n "$isBranch" ]]; then
            result="[$branchName]"     # Branch has no upstream
        else
            result="<$branchName>"     # Detached
        fi
    fi

    echo $result
}

function uncommittedChangesIndicator() {
    local wordCount=$(getNumberOfChangedFiles)
    if [ "$wordCount" != "0" ]; then
        result="*"
    else
        result=""
    fi

    echo "$result"
}

function buildGitPrompt() {
    # Check if this is a git repository
    local isThisAGitRepository=$(isGitRepo)
    echo "[DEBUG] <buildGitPrompt> isThisAGitRepository ? $isThisAGitRepository"
    echo "[DEBUG] <buildGitPrompt> PWD : $PWD"
    if [[ "false" == "$(isGitRepo)" ]]; then
        # Do nothing.
        # If we dont exit the script quick,
        # we risk slowing down the prompt in non-git directories
        echo "\[\033[36m\]\u\[\033[m\]@\[\033[32m\]\h\[\033[m\]:\[\033[33;1m\]\W\[\033[36;1m\]\[\033[m\]\[\033[1m\]\\[\033[m\] \$ "
    else
        echo "\[\033[36m\]\u\[\033[m\]@\[\033[32m\]\h\[\033[m\]:\[\033[33;1m\]\W\[\033[36;1m\] \$(parseGitBranch)\[\033[m\]\[\033[1m\]\$(uncommittedChangesIndicator)\[\033[m\] \$ "
    fi
}


export GIT_DISCOVERY_ACROSS_FILESYSTEM=1

# Build the bash prompt -------------------------
PS1="$(buildGitPrompt)"
# PS1="\[\033[36m\]\u\[\033[m\]@\[\033[32m\]\h\[\033[m\]:\[\033[33;1m\]\W\[\033[36;1m\]\[\033[m\]\[\033[1m\]\\[\033[m\] \$ "
export PS1
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad
