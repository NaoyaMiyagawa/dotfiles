// Default-style workspace list + Claude Code agent status.
//
// Field contract verified against cmux v0.64.14 (customSidebarWorkspaceValue).
//
// Agent state is driven ENTIRELY by the workspace progress label, which the
// Claude Code hooks set/clear. cmux's own `unread_count` stays 0 for these
// workspaces (terminal output never bumps it — verified via the snapshot RPC),
// so it is useless as a signal; the label is the single source of truth:
//   progress.label == "working" -> ⏳ Claude is working   (UserPromptSubmit)
//   progress.label == "waiting" -> 🙋 needs your input     (Notification, non-idle)
//   progress.label == "done"    -> ✅ finished, FYI         (Stop)
//   progress.label == ""        -> idle / no agent          (SessionEnd, /clear)
// "done" persists after a turn ends — that is the whole point: a glanceable ✅
// that does NOT require your check. It is replaced by "working" on the next
// prompt, or wiped on close / /clear.
//
// Interpreter quirks (confirmed via screenshots):
// - no .frame(maxWidth: .infinity) on rows: expands vertically
// - no .primary/.secondary tokens: render too dark
// - no .background { } block form: the shape also renders as a sibling
//   ABOVE the row, wasting ~50px per row; use .background("#hex"/"clear")
// - Reorderable adds a leading gutter + row chrome; ForEach is compact
// - the host already pads content (12 h / 8 top), keep own padding minimal
// - ONLY uniform .padding(n) works; edge forms like .padding(.vertical, 5)
//   silently apply DEFAULT ~16px padding on ALL edges (RenderNodeView.swift)
// - string `==` works (see the pr.status comparisons below); there is no nil
//   literal and only real Bools are truthy, so guard a maybe-nil expression
//   with `(expr) ? true : false` (nil condition -> false branch).
let workingList = workspaces.filter { $0.progress.label == "working" }
let waitingList = workspaces.filter { $0.progress.label == "waiting" }
let reviewList = workspaces.filter { $0.progress.label == "done" }

VStack(alignment: .leading, spacing: 5) {

    // Status strip.
    HStack(spacing: 10) {
        if waitingList.count > 0 {
            HStack(spacing: 4) {
                Circle().fill("#FF453A").frame(width: 6, height: 6)
                Text("\(waitingList.count) needs you")
                    .font(.system(size: 10)).foregroundColor("#FF6B61")
            }
        }
        if workingList.count > 0 {
            HStack(spacing: 4) {
                Circle().fill("#FF9F0A").frame(width: 6, height: 6)
                Text("\(workingList.count) working")
                    .font(.system(size: 10)).foregroundColor("#FFB340")
            }
        }
        if reviewList.count > 0 {
            HStack(spacing: 4) {
                Circle().fill("#0A84FF").frame(width: 6, height: 6)
                Text("\(reviewList.count) done")
                    .font(.system(size: 10)).foregroundColor("#54A8FF")
            }
        }
        if waitingList.count == 0 && workingList.count == 0 && reviewList.count == 0 {
            Text("agents quiet")
                .font(.system(size: 10)).foregroundColor("#9A9FA8")
        }
        Spacer()
    }
    .padding(2)

    // Workspace list. Tap to select.
    ForEach(workspaces) { w in
        let sel = w.selected == true
        let lbl = w.progress.label
        let isWaiting = (lbl == "waiting")
        let isWorking = (lbl == "working")
        let isDone = (lbl == "done")
        let metaColor = "#9BA1AC"
        let dir = w.directory.hasPrefix("/Users/miyagawa")
            ? "~\(w.directory.dropFirst(15))"
            : w.directory

        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                // Title + unread badge.
                HStack(spacing: 5) {
                    Text(w.title)
                        .font(.system(size: 13)).fontWeight(.semibold)
                        .foregroundColor(sel ? "#FFFFFF" : "#E8EAEE")
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer(minLength: 4)
                    if w.unread > 0 {
                        Text("\(w.unread)")
                            .font(.system(size: 9)).bold()
                            .foregroundColor("#FFFFFF")
                            .padding(3)
                            .background(isWaiting ? "#FF453A" : "#0A84FF")
                            .cornerRadius(6)
                    }
                    if isWaiting || isWorking || isDone {
                        Text(isWaiting ? "🙋" : (isWorking ? "⏳" : "✅"))
                            .font(.system(size: 12))
                    }
                }

                // Agent status line.
                if isWaiting {
                    Text("● Claude needs your input")
                        .font(.system(size: 11))
                        .foregroundColor("#FF6B61")
                        .lineLimit(1)
                } else if isWorking {
                    Text((w.latestPrompt.count > 0) ? "● working — \(w.latestPrompt)" : "● working…")
                        .font(.system(size: 11))
                        .foregroundColor("#FFB340")
                        .lineLimit(1)
                        .truncationMode(.tail)
                } else if isDone {
                    Text("● finished — ready when you are")
                        .font(.system(size: 11))
                        .foregroundColor("#54A8FF")
                        .lineLimit(1)
                }

                // branch• · ~/dir (branch in light purple)
                if let b = w.branch {
                    HStack(spacing: 4) {
                        Text("\(b)\(w.dirty == true ? "•" : "")")
                            .font(.system(size: 10))
                            .foregroundColor("#B794F4")
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Text("· \(dir)")
                            .font(.system(size: 10))
                            .foregroundColor(metaColor)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }

                // PR line.
                if let pr = w.pr {
                    HStack(spacing: 4) {
                        Image(systemName: pr.status == "merged"
                            ? "arrow.triangle.merge"
                            : "smallcircle.filled.circle")
                            .font(.system(size: 8))
                            .foregroundColor(pr.status == "open" ? "#3FB950"
                                : (pr.status == "merged" ? "#A371F7" : "#F85149"))
                        Text("PR #\(pr.number)")
                            .font(.system(size: 10)).underline()
                            .foregroundColor(pr.status == "open" ? "#3FB950"
                                : (pr.status == "merged" ? "#A371F7" : "#F85149"))
                            .lineLimit(1)
                        Text("\(pr.status)\(pr.stale == true ? " · stale" : "")")
                            .font(.system(size: 10))
                            .foregroundColor(metaColor)
                            .lineLimit(1)
                    }

                    // PR title on its own line, bridged into the workspace
                    // description by bin/cmux-pr-titles (probe has no title).
                    // Invisible copy of the PR icon indents the title to align
                    // with "PR #" (edge .padding is broken in this interpreter).
                    if let d = w.description {
                        HStack(spacing: 4) {
                            Image(systemName: pr.status == "merged"
                                ? "arrow.triangle.merge"
                                : "smallcircle.filled.circle")
                                .font(.system(size: 8))
                                .opacity(0.0)
                            Text(d)
                                .font(.system(size: 10))
                                .foregroundColor(metaColor)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                }

                // Last submitted prompt, marked so it reads as "you asked
                // this" rather than agent output. Hidden while working since
                // the status line already shows the prompt.
                if let p = w.latestPrompt {
                    if !isWorking {
                        // HStack alignment is hardcoded to center in this
                        // interpreter; emulate top-align by nudging ">" up
                        // half a line when the prompt likely wraps (~48 chars
                        // per line at this width/font).
                        HStack(spacing: 4) {
                            Text(">")
                                .font(.system(size: 11)).bold()
                                .foregroundColor("#B794F4")
                                .offset(x: 0, y: (p.count > 48) ? -7.0 : 0.0)
                            Text(p)
                                .font(.system(size: 11))
                                .foregroundColor("#B8BDC6")
                                .lineLimit(2)
                                .truncationMode(.tail)
                        }
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(6)
        .background(sel ? "#1E6FE855" : "clear")
        .cornerRadius(8)
        .onTapGesture { cmux("workspace.select", workspace_id: w.id) }
    }

    Spacer()
}
