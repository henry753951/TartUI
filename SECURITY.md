# Security Policy

Please report security issues privately to the project owner through the
security-advisory feature of the GitHub repository. Do not include credentials,
private keys, VM images, or sensitive host information in a public issue.

TartUI intentionally relies on the host's normal OpenSSH trust policy. A change
that disables host authentication, bypasses `known_hosts`, or creates blanket
CIDR trust is not accepted as a convenience feature.
