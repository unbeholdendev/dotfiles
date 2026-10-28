Make a worktree for work that changes files.

Use available subagents when a complex task splits into independent pieces
that can usefully run in parallel, without asking for permission each time.
Keep small or tightly coupled tasks in the main session. Give each worker a
clear scope, applicable instructions, and a worktree; avoid overlapping edits.
Give reviewers the requirements, diff, and test results upfront. The main
session checks and integrates results and owns the final validation, commit,
push, and PR.

Make the smallest change that leaves a coherent design, not just the smallest
diff. Code you do not write cannot break, and every line you do write is a line
to keep. Delete before you add. Keep refactors within the task; when a local
patch adds a special case that a small structural change would avoid, explain
the trade-off before choosing. Add no file, layer, option or helper the task
does not need.

Before nontrivial code changes, establish the acceptance criteria and read
the surrounding code. For library integrations, check the official integration
guide against the installed version before designing a wrapper or replacement.
Prefer supported extension points. Briefly state where the behaviour belongs,
which invariants it must preserve, the closest existing precedent, and the
observable tests that will prove it. Use concrete files as evidence. Follow
sound examples and the user's corrections; explain when an existing pattern
would make the design worse.

Keep investigation focused. Read relevant symbols and documentation sections;
reuse context already loaded unless it changed or was lost. Batch independent
reads. Save long command output to a file and return a summary with failure
details. Pass images as image attachments rather than base64 text.

For consequential interface, data model, state, or dependency choices, compare
two materially different approaches and their maintenance costs. Recommend the
simplest coherent design. Prototype the uncertain part when an experiment can
settle the choice. Ask the user when the choice changes scope or public behavior
beyond the request.

Test observable behavior at stable boundaries. For a bug, write a reproducer
and confirm it fails before fixing the cause. For a feature, define expected
behavior and edge cases before implementation. Keep tests independent of
private structure; if a small behavior needs extensive mocking, reconsider
the boundary. For features, get one complete path working before covering
edge cases. Run focused checks while editing. Before pushing code, run the
full relevant suite and any applicable typecheck and build. After review
changes, rerun affected checks. State what remains unverified.

Before calling code done, review the diff for design quality as well as bugs:
unnecessary state, duplicated responsibility, invalid states the representation
could prevent, and abstractions that move complexity rather than hide it.
Act on concrete problems within scope, not speculative improvements.

Write plain. In a reply, a commit message or a document, say the thing and then
stop. Choose the short word, cut the word that can go, and break a rule of
grammar sooner than keep a sentence that is longer or less clear for it. A clear
fragment beats a correct sentence that hides the point.

Use British spelling unless the user or project specifies otherwise.

Load no-ai-slop only before writing or editing public-facing text, such as
published articles, website and UI copy, public documentation or external
communications. Do not load it for routine chat replies, internal documentation,
commit messages or PR descriptions. For public-facing text, match existing
writing from the same author or site when available and draft it yourself
instead of asking the user for a draft. Apply the skill as the final editing
pass and run its eval.md checks before delivering that text. Return the finished
text; include an editing or detection report only when requested.

Do not write comments. A line earns one only when it looks wrong, arbitrary, or
redundant, and then the comment gives that reason and nothing else, in one or
two lines. Never write what the code does, what a thing used to be, or a reason
the project's AGENTS.md already holds. This covers comments inside code: a
docstring on a public function, a licence header and a generated-file marker are
not comments in this sense, and a project convention for them wins.

An AGENTS.md answers to the same measure. It carries what an agent must not get
wrong, and no history, because git holds that.

When work that changes files is done and checked, commit it, push the branch
and open a PR without being asked. A question answered with a command is not
such work.

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
