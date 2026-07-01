# CLAUDE.md

本文件是 monitor 项目的协作约定，对本仓库的所有工作生效。

# 宪法

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:

- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:

- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:

- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:

```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

# UI 风格

参考 @style.md

## 代码初始化与合并要求

1. **严禁直接提交或合并到 `main`**。所有代码改动必须通过 Pull Request 合入。
2. **严禁任何智能体（含主 agent）在主 checkout 里直接改代码**。所有代码改动一律在独立 git worktree + 独立分支里进行；主 checkout 只用于 Review、合并、部署等非编辑操作。理由：在共享主工作区直接改，破坏性 git 操作（如 `reset --hard`）会波及其它未提交内容（曾因此误删 `docs/backlog.md`）；隔离 worktree 让每份改动互不影响。
3. **PR 流程**：执行者（sub-agent 或主 agent）在自己的 worktree 写代码 → 提 PR → 由主 agent Review → 确认无误才合并。
4. **多个智能体并行写代码时，各自一个 git worktree**，隔离在独立分支与工作目录，互不干扰。
5. **单个 worktree / PR 的代码量**：不含测试代码，控制在400行以内。如何切分任务到这个区间，由主 agent 分工。
6. 远程仓库 `Hayden-Chang/monitor`（私有）。由于 github.com:443 被墙，git 走 SSH（key：`~/.ssh/id_ed25519_monitor`，已通过 `core.sshCommand` 固定）。

## Git 安全（破坏性操作）

1. **同步本地 main 只用 `git pull --ff-only`，禁止用 `git reset --hard` 做日常同步**。`--ff-only` 遇到本地改动会停下保护；`reset --hard` 会无条件清空工作区未提交改动（曾因此误删 `docs/backlog.md` 的未提交内容）。
2. **任何破坏性命令前先 `git status` 确认工作区干净**（`reset --hard`/`checkout -- `/`clean -fd` 等）。有 ` M`/`??` 未提交内容时先停，必要时先 `git stash` 或提交，再操作。
3. **重要内容不要长期裸放在工作区**（只改不提交）。未提交是 git 保护最弱的状态，随时可能被上述命令抹掉。私人、不入库的文件应明确 `.gitignore`，其余尽快提交。

## 测试要求

1. **修完 bug 必须新增测例**：每修复一个 bug，都要补一条能复现该 bug 的测试用例（先确认它在修复前会失败、修复后通过），随修复一起进同一个 PR。目的是锁死这个 bug 不再回归。
2. 新增功能也应带上对应测例（前端 vitest / e2e，后端 curl 或 pytest），覆盖正常路径与关键边界。
3. 测试代码不计入第 1 节的 400 行额度。
4. **合并门禁：最后一次「全套测试全绿」与合并之间，不能有任何代码改动**。即合并的代码必须与跑测试时的代码完全一致——所有 e2e 与全部 UT 必须全部通过，有任一失败禁止合并。

   - 不是「写几行就跑一次」：只要代码没再动，哪怕全绿后放置很久也能直接合并。
   - 全绿后哪怕只改一行（含 rebase / 解决冲突产生的改动），上一次测试即作废，必须重新跑完全部测试并全绿才能合并。
   - 把「跑全套测试」放在合并前的最后一步，跑完到合并之间不要再碰代码；期间有任何改动就重跑，全绿后立即合并。测试范围按类型区分：**前端 vitest UT、e2e、后端冒烟/pytest 一律跑全量**

## Bug 修复流程（`docs/bug.md`）

1. **Pick 前先认领，避免多 agent 冲突**：决定修 `docs/bug.md` 里某条 bug 时，先在该条目下加一行 `pick by <唯一编号>`，再开始动手。看到已有 `pick by <其他编号>` 的条目**不要动**，另挑未认领的。
2. **唯一编号用「带秒时间戳」**：格式 `YYYYMMDDHHMMSS`（本机 `date +%Y%m%d%H%M%S`）。不要用模型名——多个 agent 可能共用同一模型，会撞号。每个 agent 每次会话生成自己的时间戳编号。
3. 认领后按「代码初始化与合并要求」走 worktree + PR 流程，按「测试要求」补回归测例。

## 部署约定

0. **部署前先分清部署对象：分支代码还是主线（main）代码**。两者后果完全不同——部署 main 影响生产/共享状态，部署分支只是本地验证某个未合并改动。主 agent 接到「部署」指令时，**若用户没明确说部署哪个分支 / 是不是 main，必须先问清楚再动手，不许擅自假定**。`scripts/deploy-frontend.sh` 启动时会打印当前分支名，便于核对。

## 调度要求

1. 按任务**能否并行**来调度，**能并行的尽量并行**。
2. **尽可能多地派 subagent 同时干活**。
3. 有依赖关系的任务串行，相互独立的任务并行铺开

