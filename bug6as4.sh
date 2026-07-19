#!/bin/bash

addr=(
    "2001:0f70::" # VECTANT - ARTERIA Networks Corporation, JP
    "2001:0f74::" # VECTANT - ARTERIA Networks Corporation, JP
    "2400:2410::" # GIGAINFRA - SoftBank Corp., JP
    "2400:2650::" # GIGAINFRA - SoftBank Corp., JP
    "2400:4050::" # OCN - NTT DOCOMO BUSINESS,Inc., JP
    "2400:4150::" # OCN - NTT DOCOMO BUSINESS,Inc., JP
    "2401:4d40::" # CYBERHOME1 - FAMILY NET JAPAN INCORPORATED, JP
    "2401:4d44::" # CYBERHOME2 - FAMILY NET JAPAN INCORPORATED, JP
    "2404:7a80::" # BIGLOBE - BIGLOBE Inc., JP
    "2404:7a84::" # BIGLOBE - BIGLOBE Inc., JP
    "2405:6580::" # ASAHI-NET - Asahi Net, JP
    "2405:6584::" # ASAHI-NET - Asahi Net, JP
    "2406:ab48::" # GSS-NET - Digital Agency, JP
    "2406:ab4c::" # GSS-NET - Digital Agency, JP
    "2409:0010::" # MF-NATIVE6-E - INTERNET MULTIFEED CO., JP
    "2409:0250::" # MF-NATIVE6-W - INTERNET MULTIFEED CO., JP
    "240b:0010::" # KDDI - KDDI CORPORATION, JP
    "240b:0250::" # KDDI - KDDI CORPORATION, JP
    "240b:c0c4::" # RMNI-AS-AP - Rakuten Mobile Network, Inc., JP
    "240b:c0cc::" # RMNI-AS-AP - Rakuten Mobile Network, Inc., JP
)
for a in "${addr[@]}"; do
    python3 - "$a" <<'EOF'
import ipaddress, sys
ip = ipaddress.IPv6Address(sys.argv[1]).packed
print(".".join(map(str, ip[:4])))
EOF
done
