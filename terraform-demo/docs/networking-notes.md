### Networking Notes

# Request Path

browser HTTPS :443
  -> ALB listener :443
    -> ALB target group HTTP :7070
      -> ECS task/container :7070
        -> Kestrel :7070