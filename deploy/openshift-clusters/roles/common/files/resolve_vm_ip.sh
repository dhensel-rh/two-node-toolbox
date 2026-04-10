#!/usr/bin/env bash
# Resolve VM IP from virsh net-dhcp-leases. The same MAC can appear twice (anonymous
# DUID vs hostname); prefer the row whose Hostname matches this VM (e.g. master-0).
# Dual-stack leases can list both ipv4 and ipv6 for one MAC; prefer ipv4, then ipv6.
set -euo pipefail

VM_NAME="${1:?VM name required}"

# ostest_master_0 -> master-0; ostest_arbiter_0 -> arbiter-0; kcli e.g. *-ctlplane-0 -> ctlplane-0
EXPECTED_HOSTNAME=""
if [[ "$VM_NAME" =~ _(master|worker|arbiter)_([0-9]+)$ ]]; then
  EXPECTED_HOSTNAME="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}"
elif [[ "$VM_NAME" =~ -(ctlplane|arbiter)-?([0-9]*)$ ]]; then
  # Numberless kcli VMs (e.g. tnt-cluster-arbiter) have empty REMATCH[2]; DHCP host is "arbiter", not "arbiter-".
  if [[ -n "${BASH_REMATCH[2]}" ]]; then
    EXPECTED_HOSTNAME="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}"
  else
    EXPECTED_HOSTNAME="${BASH_REMATCH[1]}"
  fi
fi

INTERFACES=$(virsh -c qemu:///system domiflist "$VM_NAME" | awk 'NR>2 && $3 != "" && $5 != "" {print $3, tolower($5)}')

lease_ip_for_mac() {
  local LEASES="$1"
  local MAC="$2"
  local IP=""

  if [[ -n "$EXPECTED_HOSTNAME" ]]; then
    # awk filters by MAC (case-insensitive) so we never rely on grep exit status under set -euo pipefail.
    # $4 is Protocol (ipv4|ipv6); prefer ipv4 when both exist (dual-stack).
    for proto in ipv4 ipv6 ""; do
      IP=$(echo "$LEASES" | awk -v mac="$MAC" -v host="$EXPECTED_HOSTNAME" -v proto="$proto" '
        BEGIN { m = tolower(mac) }
        index(tolower($0), m) == 0 { next }
        proto != "" && $4 != proto { next }
        $6 == host {
          ip = $5
          sub(/\/.*/, "", ip)
          print ip
          exit
        }')
      [[ -n "$IP" ]] && break
    done
  fi
  if [[ -z "$IP" ]]; then
    for proto in ipv4 ipv6 ""; do
      IP=$(echo "$LEASES" | awk -v mac="$MAC" -v proto="$proto" '
        BEGIN { m = tolower(mac) }
        index(tolower($0), m) == 0 { next }
        proto != "" && $4 != proto { next }
        $6 != "-" {
          ip = $5
          sub(/\/.*/, "", ip)
          print ip
          exit
        }')
      [[ -n "$IP" ]] && break
    done
  fi
  if [[ -z "$IP" ]]; then
    for proto in ipv4 ipv6 ""; do
      IP=$(echo "$LEASES" | awk -v mac="$MAC" -v proto="$proto" '
        BEGIN { m = tolower(mac) }
        index(tolower($0), m) == 0 { next }
        proto != "" && $4 != proto { next }
        {
          ip = $5
          sub(/\/.*/, "", ip)
          print ip
          exit
        }')
      [[ -n "$IP" ]] && break
    done
  fi
  printf '%s' "$IP"
}

while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  NETWORK=$(echo "$line" | awk '{print $1}')
  MAC=$(echo "$line" | awk '{print $2}')

  LEASES=$(virsh -c qemu:///system net-dhcp-leases "$NETWORK" 2>/dev/null || true)
  [[ -z "$LEASES" ]] && continue

  IP=$(lease_ip_for_mac "$LEASES" "$MAC")
  if [[ -n "$IP" ]]; then
    echo "$IP"
    exit 0
  fi
done <<< "$INTERFACES"

exit 1
