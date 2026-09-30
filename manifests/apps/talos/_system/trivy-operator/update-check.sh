#!/bin/sh
# For every running image with critical CVEs, scan the newest tag of the same
# shape in its registry and push how many of those CVEs it no longer contains:
#
#   trivy_image_update_fixed_vulnerabilities{namespace, image_registry,
#     image_repository, image_tag, update_tag, severity="Critical"} <count>
#
# The shape is the tag with every digit run replaced by N, so 1.8.10-alpine
# only moves to another N.N.N-alpine tag, and rc/debug/sig tags are never
# picked. Floating tags (latest, 3.6) are compared against their own
# current digest, which catches rebuilds.
set -eu

SA=/var/run/secrets/kubernetes.io/serviceaccount
TRIVY_SERVER=http://trivy-service.trivy-system:4954
VM_IMPORT=http://vmsingle-vm-victoria-metrics-k8s-stack.victoriametrics.svc:8428/api/v1/import/prometheus

apk add --no-cache -q jq curl crane coreutils

work=$(mktemp -d)
failed=0

curl -sSf --cacert "$SA/ca.crt" -H "Authorization: Bearer $(cat "$SA/token")" \
  https://kubernetes.default.svc/apis/aquasecurity.github.io/v1alpha1/vulnerabilityreports \
  > "$work/reports.json"

# namespace, registry, repository, tag - one line per namespace using the image
jq -r '.items[]
  | select(.report.summary.criticalCount > 0 and (.report.artifact.tag // "") != "")
  | [.metadata.namespace, .report.registry.server, .report.artifact.repository, .report.artifact.tag]
  | @tsv' "$work/reports.json" | sort -u > "$work/targets"

shape() { printf '%s\n' "$1" | sed -E 's/[0-9]+/N/g'; }

# Listed once per repository: several tags of one repo may be running, and
# repos with per-commit tags (immich: 10k+) page into registry rate limits.
list_tags() {
  cache="$work/tags-$(printf '%s' "$1" | tr '/:' '__')"
  if [ ! -f "$cache" ]; then
    for attempt in 1 2 3; do
      crane ls --omit-digest-tags "$1" > "$cache.tmp" && break
      rm -f "$cache.tmp"
      sleep 60
    done
    [ -f "$cache.tmp" ] || return 1
    mv "$cache.tmp" "$cache"
  fi
  cat "$cache"
}

cut -f2-4 "$work/targets" | sort -u | while IFS="$(printf '\t')" read -r registry repository tag; do
  image="$registry/$repository"
  want=$(shape "$tag")

  if ! tags=$(list_tags "$image"); then
    echo "WARN: cannot list tags of $image" >&2
    echo fail >> "$work/failures"
    continue
  fi
  update_tag=$(printf '%s\n' "$tags" \
    | awk -v want="$want" '{ s = $0; gsub(/[0-9]+/, "N", s) } s == want' \
    | sort -V | tail -n1)
  # Never "update" to something sorting below the running tag.
  [ -n "$update_tag" ] && [ "$(printf '%s\n%s\n' "$tag" "$update_tag" | sort -V | tail -n1)" = "$update_tag" ] \
    || update_tag=$tag

  jq -r --arg r "$registry" --arg p "$repository" --arg t "$tag" '.items[].report
    | select(.registry.server == $r and .artifact.repository == $p and .artifact.tag == $t)
    | .vulnerabilities[] | select(.severity == "CRITICAL") | .vulnerabilityID' \
    "$work/reports.json" | sort -u > "$work/current"

  # No --ignore-unfixed: a CVE still present but unfixed in the update is not
  # fixed by updating.
  if ! trivy image --quiet --server "$TRIVY_SERVER" --image-src remote \
      --scanners vuln --severity CRITICAL --format json "$image:$update_tag" > "$work/update.json"; then
    echo "WARN: cannot scan $image:$update_tag" >&2
    echo fail >> "$work/failures"
    continue
  fi
  jq -r '.Results[]?.Vulnerabilities[]?.VulnerabilityID' "$work/update.json" | sort -u > "$work/update"

  fixed=$(comm -23 "$work/current" "$work/update" | wc -l)
  echo "$image:$tag -> $update_tag fixes $fixed of $(wc -l < "$work/current") critical CVE(s)"

  awk -F '\t' -v r="$registry" -v p="$repository" -v t="$tag" -v u="$update_tag" -v n="$fixed" \
    '$2 == r && $3 == p && $4 == t {
      printf "trivy_image_update_fixed_vulnerabilities{namespace=\"%s\",image_registry=\"%s\",image_repository=\"%s\",image_tag=\"%s\",update_tag=\"%s\",severity=\"Critical\"} %d\n", $1, r, p, t, u, n
    }' "$work/targets" >> "$work/metrics"
done

[ -s "$work/metrics" ] && curl -sSf --data-binary "@$work/metrics" "$VM_IMPORT"

# Fail the Job (-> KubeJobFailed) so a registry or scan problem is not silent.
[ ! -s "$work/failures" ] || failed=1
exit "$failed"
