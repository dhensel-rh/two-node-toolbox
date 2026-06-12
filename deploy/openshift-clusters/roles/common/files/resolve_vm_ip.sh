#!/usr/bin/env bash
# Resolve VM IP by checking the host's ARP/neighbor table first (works for both
# static and DHCP networking), then falling back to virsh DHCP leases.
# Dual-stack: prefer IPv4, then global IPv6 (skip link-local fe80:: and ULA fd00::).
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

# --- Primary: ARP/neighbor table lookup (works for static and DHCP networking) ---
MACS=$(virsh -c qemu:///system domiflist "$VM_NAME" | awk 'NR>2 && $5 != "" {print tolower($5)}')
for MAC in $MACS; do
  # Score candidates: prefer IPv4, then REACHABLE+router IPv6, then best available.
  # On IPv6, multiple addresses share a MAC (node IP, VIPs); scoring avoids picking a VIP.
  BEST=$(ip neigh | awk -v mac="$MAC" '
    BEGIN { m = tolower(mac); best_score = -1 }
    tolower($5) != m { next }
    /^fe80:/ || /^fd00:/ { next }
    {
      score = 0
      is_v4 = ($1 !~ /:/)
      if (is_v4) score += 10
      if (/router/) score += 2
      if ($NF == "REACHABLE") score += 1
      if (score > best_score) { best_score = score; best_ip = $1 }
    }
    END { if (best_ip != "") print best_ip }
  ')
  if [[ -n "$BEST" ]]; then
    echo "$BEST"
    exit 0
  fi
done

# --- Fallback: DHCP lease lookup (hostname-aware, dual-stack safe) ---

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
