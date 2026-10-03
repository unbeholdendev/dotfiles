Make a worktree for work that changes files.

Do the task with the least code that does it. Code you do not write cannot
break, and every line you do write is a line to keep. Prefer the smaller change
to the tidier one, delete before you add, and add no file, layer, option or
helper the task did not ask for.

Write plain. In a reply, a commit message or a document, say the thing and then
stop. Choose the short word, cut the word that can go, and break a rule of
grammar sooner than keep a sentence that is longer or less clear for it. A clear
fragment beats a correct sentence that hides the point.

Do not write comments. A line earns one only when it looks wrong, arbitrary, or
redundant, and then the comment gives that reason and nothing else, in one or
two lines. Never write what the code does, what a thing used to be, or a reason
the project's CLAUDE.md already holds. This covers comments inside code: a
docstring on a public function, a licence header and a generated-file marker are
not comments in this sense, and a project convention for them wins.

A CLAUDE.md answers to the same measure. It carries what an agent must not get
wrong, and no history, because git holds that.

After opening a PR on the self-hosted Forgejo, wait for the automated review.
Other hosts, such as GitHub, usually have none, so do not wait there. An 👀
reaction on the PR description means it started, and it stays after the review is posted, so the
signal that it is done is a review newer than your last push or tag. Poll for
that, and after 10 minutes stop and say so. Then weigh each comment: fix what is
right and worth the change, push, and reply to every comment with what you
changed or why you did not. Forgejo sends no webhook for a thread reply, so if
you left any unchanged, also post one PR comment, tagging @reviewer, that says
why for each. A push or a tag starts another review; wait for it the same way,
with the same 10 minutes, and repeat until a review asks for nothing you would
change.
