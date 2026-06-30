### Networking Notes

# Request Path

browser HTTPS :443
  -> ALB listener :443
    -> ALB target group HTTP :7070
      -> ECS task/container :7070
        -> Kestrel :7070

# VPC CIDR

10.0.0.0/24 provides:
- 256 IPs (10.0.0.1 to 10.0.0.254)
- Broadcast IP 10.0.0.255