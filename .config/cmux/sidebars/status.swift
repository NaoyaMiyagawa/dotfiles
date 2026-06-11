// Default-style workspace list + Claude Code agent status.
//
// Field contract verified against cmux v0.64.14 (Sources/ContentView.swift,
// customSidebarWorkspaceValue). Agent state via claude-hooks:
//   latestPrompt set + unread == 0  -> working
//   latestPrompt set + unread  > 0  -> needs your input
//   latestPrompt nil + unread  > 0  -> finished, to review
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

// NOTE: `x != nil` never evaluates in this build (no nil literal in the
// evaluator) and only real Bools are truthy. `(expr) ? true : false` coerces
// a maybe-nil expression into a real Bool (nil condition -> false branch).
//
// "Running" is carried by workspace progress (set/cleared by the Claude
// hooks via `cmux set-progress --label working` / `clear-progress`), because
// latestPrompt is never cleared by cmux on turn end.
let workingList = workspaces.filter { (($0.progress.label.count > 0) ? true : false) && ($0.unread == 0) }
let waitingList = workspaces.filter { (($0.progress.label.count > 0) ? true : false) && ($0.unread > 0) }
let reviewList = workspaces.filter { (($0.progress.label.count > 0) ? false : true) && ($0.unread > 0) }

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
                Text("\(reviewList.count) to review")
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
        let active = (w.progress.label.count > 0) ? true : false
        let isWaiting = active && (w.unread > 0)
        let isWorking = active && (w.unread == 0)
        let toReview = !active && (w.unread > 0)
        let metaColor = sel ? "#DCE6FF" : "#9BA1AC"
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
                    if isWaiting || isWorking || toReview {
                        Text(isWaiting ? "🙋" : (isWorking ? "⏳" : "✅"))
                            .font(.system(size: 12))
                    }
                }

                // Agent status line.
                if isWaiting {
                    Text("● Claude needs your input")
                        .font(.system(size: 11))
                        .foregroundColor(sel ? "#FFD7D4" : "#FF6B61")
                        .lineLimit(1)
                } else if isWorking {
                    Text((w.latestPrompt.count > 0) ? "● working — \(w.latestPrompt)" : "● working…")
                        .font(.system(size: 11))
                        .foregroundColor(sel ? "#FFE3B8" : "#FFB340")
                        .lineLimit(1)
                        .truncationMode(.tail)
                } else if toReview {
                    Text("● finished — \(w.unread) new to review")
                        .font(.system(size: 11))
                        .foregroundColor(sel ? "#CFE5FF" : "#54A8FF")
                        .lineLimit(1)
                }

                // Last agent message, when cmux has one.
                if let m = w.latestMessage {
                    if !isWorking {
                        Text(m)
                            .font(.system(size: 11))
                            .foregroundColor(sel ? "#E8EEFF" : "#B8BDC6")
                            .lineLimit(2)
                            .truncationMode(.tail)
                    }
                }

                // branch• · ~/dir (branch in light purple)
                if let b = w.branch {
                    HStack(spacing: 4) {
                        Text("\(b)\(w.dirty == true ? "•" : "")")
                            .font(.system(size: 10))
                            .foregroundColor(sel ? "#E6D9FF" : "#B794F4")
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
                            .foregroundColor(sel ? "#DCE6FF"
                                : (pr.status == "open" ? "#3FB950"
                                    : (pr.status == "merged" ? "#A371F7" : "#F85149")))
                        Text("PR #\(pr.number)")
                            .font(.system(size: 10)).underline()
                            .foregroundColor(sel ? "#DCE6FF"
                                : (pr.status == "open" ? "#3FB950"
                                    : (pr.status == "merged" ? "#A371F7" : "#F85149")))
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
            }
            Spacer(minLength: 0)
        }
        .padding(6)
        .background(sel ? "#1E6FE8" : "clear")
        .cornerRadius(8)
        .onTapGesture { cmux("workspace.select", workspace_id: w.id) }
    }

    Spacer()
}
