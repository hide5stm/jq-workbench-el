select(.type == "result" and (.score | tonumber) >= 0.8)
| {path, score, action}
