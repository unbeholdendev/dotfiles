# Automated review on the self-hosted Forgejo

Every PR there gets an automated review. A push or a tag starts another.

Wait for it in the background so the conversation stays free: in T3 Code
where `tea whoami` succeeds, call `watch_pull_request` and end your turn;
otherwise start a command that exits when the review appears or after 10
minutes. An 👀 reaction on the PR description means the review started, and it
stays after the review is posted, so the signal that it is done is a review
newer than your last push or tag. Handle the result in the main session,
saying so if no review came within 10 minutes.

Weigh each comment: fix what is right and worth the change, push, and reply to
every comment with what you changed or why you did not. Use `tea`, and
`tea api` for what it lacks. `tea pr reply` fails there, so reply with
`tea comment`. Forgejo sends no webhook for a thread reply, so if you left any
comment unchanged, also post one PR comment, tagging @reviewer, that says why
for each.

Repeat until a review asks for nothing you would change.
