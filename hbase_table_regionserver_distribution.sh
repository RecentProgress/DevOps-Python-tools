#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2018-07-11 19:36:23 +0100 (Wed, 11 Jul 2018)
#
#  https://github.com/harisekhon/pytools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage(){
    echo "usage: $0 <list of regionservers>"
    exit 1
}

port="${REGIONSERVER_PORT:-16030}"

if [ $# -lt 1 ]; then
    usage
fi

for server in $@; do
    echo "$server:"
    curl -s $server:$port/jmx |
    grep 'Namespace_.*_metric_getCount"[[:space:]]*:[[:space:]]*' |
    sed 's/.*_table_//; s/_region_.*//' |
    sort |
    uniq -c
    echo
done