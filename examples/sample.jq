select(
  .type == "result"
  and .action == "no_match_unchanged"
  and (.score | tonumber) > 0.1
)
| {path, score, duration}
