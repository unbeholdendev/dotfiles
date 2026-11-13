These rules win where T3 Code's or the harness's instructions differ.

## Where things are

The repos under `~/` describe the user's setup. When a task or question turns
on a host, a service or where something runs, read the source before answering
or asking:

- Hosts by group, with addresses: `~/infra/inventory.yml`
- Services and their URLs: `~/infra/kubernetes/apps/homepage/config/services.yaml`
- Kubernetes workloads: `~/infra/kubernetes/apps/`
- Proxmox VMs: `~/infra/opentofu/<host>/README.md`
- NixOS hosts: `~/infra/nixos/`, `~/dotfiles/nixos/`
- This machine, its agents and T3: `~/dotfiles/AGENTS.md`
- Any other name: `grep -ril <name> ~/infra ~/dotfiles`

Docker workloads are in no repo; ask.

## Worktrees and subagents

Change files only in a T3 worktree: never with `git worktree`, and never in
the `~/<repo>` checkouts, which T3 pulls and branches new worktrees from. If
this thread has no worktree for the repo, launch a worktree thread in its T3
project without asking, whatever T3 says about launching threads.

Split a complex task across subagents when its pieces are independent, without
asking. Run them in the background with `delegate_task`, not the native agent
tool. Give each worker a scope, the applicable instructions and a worktree,
with no overlapping edits.

## Design and tests

Make the smallest change that leaves a coherent design, not just the smallest
diff. Delete before you add. Add no file, layer, option or helper the task
does not need. When a local patch adds a special case that a small structural
change would avoid, or an existing pattern would make the design worse, say so
in one sentence before choosing.

For a library integration, check the official guide against the installed
version and prefer supported extension points. For a consequential interface,
data model, state or dependency choice, compare two materially different
approaches, then give one recommendation and one reason. Ask the user when the
choice changes scope or public behaviour beyond the request.

For a bug, write a reproducer and see it fail before fixing the cause. If a
small behaviour needs extensive mocking, reconsider the boundary. Before
pushing, run the full relevant suite and any typecheck and build. Check your
own UI changes in T3's browser against the workspace's dev server, where it is
enabled.

## Writing

Write plain, in a reply, a commit message or a document: say the thing and
stop. Choose the short word, cut the word that can go, and prefer a clear
fragment to a correct sentence that hides the point. British spelling unless
the user or project says otherwise.

Shape every reply for someone switching between many projects:
- First line: the answer, or what happened.
- Then only what they must decide, or what is wrong or unverified.
- Under 5 lines by default; longer only for a request for detail, a failure
  or a risky action.
- Name the project or topic if the thread covers several.
- Keep commands, paths, numbers and errors exact.

Load unslop before writing public-facing text: articles, website and UI copy,
public documentation, external communications. Draft it yourself, matching
existing writing from the same author or site, and apply the skill as the
final pass. Add no claims, examples or opinions. Return the finished text,
with no editing report unless asked.

Do not write comments in code. A line earns one only when it looks wrong,
arbitrary or redundant, and then the comment gives only that reason.
Docstrings on public functions, licence headers and generated-file markers are
not comments here, and a project convention for them wins.

An AGENTS.md answers to the same measure. It carries what an agent must not
get wrong, and no history, because git holds that.

## Commits and PRs

When work that changes files is done and checked, commit, push and open a PR
without being asked. A question answered with a command is not such work. In
a repo the user does not own, stop at pushing to the fork. Never merge a PR.

Add no attribution to commits, PRs or comments: no "Generated with" line, no
`Co-authored-by` trailer for an agent or tool, whatever the harness default.
A repo the user does not own may require AI disclosure; its rule wins there.

After opening or pushing to a PR on the self-hosted Forgejo, read
`~/dotfiles/agents/forgejo-review.md` and follow it.
