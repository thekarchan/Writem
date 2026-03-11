import SwiftUI

struct TableEditorPanelView: View {
    let markdown: String
    let onApplyMarkdown: (String) -> Void

    @State private var selectedTableLine: Int?
    @State private var draftTable: MarkdownTable?
    @State private var pasteError: String?

    private var tables: [MarkdownTable] {
        MarkdownTableService.tables(in: markdown)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tables")
                            .font(.title3.weight(.bold))
                        Text("Edit Markdown tables visually while keeping the document source native.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                if tables.isEmpty {
                    emptyState
                } else {
                    tablePicker
                    if let draftTable {
                        controls(for: draftTable)
                        tableGrid(for: draftTable)
                    }
                }

                if let pasteError {
                    Text(pasteError)
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }
            }
        }
        .onAppear {
            seedSelection()
        }
        .onChange(of: markdown) { _, _ in
            refreshSelection()
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("No Markdown tables found in this document.")
                .font(.headline)

            HStack(spacing: 12) {
                Button("Insert 3x3 Table") {
                    let table = MarkdownTable.empty(columns: 3, rows: 3)
                    onApplyMarkdown(MarkdownTableService.appending(table, to: markdown))
                    selectedTableLine = nil
                }

                Button("Paste Table from Clipboard") {
                    pasteTableFromClipboard()
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.72))
        )
    }

    private var tablePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Detected Tables")
                .font(.subheadline.weight(.semibold))
            Picker("Table", selection: Binding(
                get: { selectedTableLine ?? tables.first?.startLine ?? 0 },
                set: { newValue in
                    selectedTableLine = newValue
                    refreshSelection()
                }
            )) {
                ForEach(tables) { table in
                    Text("Table at line \(table.startLine)").tag(table.startLine)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private func controls(for table: MarkdownTable) -> some View {
        HStack(spacing: 12) {
            Button("Add Row") {
                var updated = table
                updated.addRow()
                apply(updated)
            }

            Button("Add Column") {
                var updated = table
                updated.addColumn()
                apply(updated)
            }

            Button("Paste over Selection") {
                pasteTableFromClipboard(replacing: table)
            }

            Spacer()

            if !table.rows.isEmpty {
                Button("Remove Last Row", role: .destructive) {
                    var updated = table
                    updated.removeRow(at: updated.rows.count - 1)
                    apply(updated)
                }
            }

            if table.headers.count > 1 {
                Button("Remove Last Column", role: .destructive) {
                    var updated = table
                    updated.removeColumn(at: updated.headers.count - 1)
                    apply(updated)
                }
            }
        }
        .buttonStyle(.bordered)
    }

    private func tableGrid(for table: MarkdownTable) -> some View {
        ScrollView(.horizontal, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 12) {
                alignmentRow(for: table)
                headerRow(for: table)
                ForEach(Array(table.rows.enumerated()), id: \.offset) { rowIndex, row in
                    dataRow(for: table, row: row, rowIndex: rowIndex)
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.72))
        )
    }

    private func alignmentRow(for table: MarkdownTable) -> some View {
        HStack(spacing: 10) {
            ForEach(Array(table.alignments.enumerated()), id: \.offset) { columnIndex, alignment in
                Menu(alignment.title) {
                    ForEach(MarkdownTable.ColumnAlignment.allCases) { option in
                        Button(option.title) {
                            var updated = table
                            updated.alignments[columnIndex] = option
                            apply(updated)
                        }
                    }
                }
                .frame(width: 160, alignment: .leading)
            }
        }
    }

    private func headerRow(for table: MarkdownTable) -> some View {
        HStack(spacing: 10) {
            ForEach(Array(table.headers.enumerated()), id: \.offset) { columnIndex, value in
                TextField("Header", text: Binding(
                    get: { value },
                    set: { newValue in
                        var updated = table
                        updated.headers[columnIndex] = newValue
                        apply(updated)
                    }
                ))
                .textFieldStyle(.roundedBorder)
                .frame(width: 160)
            }
        }
    }

    private func dataRow(for table: MarkdownTable, row: [String], rowIndex: Int) -> some View {
        HStack(spacing: 10) {
            ForEach(Array(row.enumerated()), id: \.offset) { columnIndex, value in
                TextField("Cell", text: Binding(
                    get: { value },
                    set: { newValue in
                        var updated = table
                        updated.rows[rowIndex][columnIndex] = newValue
                        apply(updated)
                    }
                ))
                .textFieldStyle(.roundedBorder)
                .frame(width: 160)
            }
        }
    }

    private func seedSelection() {
        if selectedTableLine == nil {
            selectedTableLine = tables.first?.startLine
        }
        refreshSelection()
    }

    private func refreshSelection() {
        if selectedTableLine == nil {
            selectedTableLine = tables.first?.startLine
        }

        if let selectedTableLine,
           let table = tables.first(where: { $0.startLine == selectedTableLine }) {
            draftTable = table
        } else {
            draftTable = tables.first
            selectedTableLine = tables.first?.startLine
        }
    }

    private func apply(_ table: MarkdownTable) {
        draftTable = table
        pasteError = nil
        if let updatedMarkdown = MarkdownTableService.replacing(table, in: markdown) {
            onApplyMarkdown(updatedMarkdown)
            selectedTableLine = table.startLine
        }
    }

    private func pasteTableFromClipboard(replacing table: MarkdownTable? = nil) {
        guard let string = ClipboardService.readString(),
              let parsed = MarkdownTable.fromDelimitedText(string, startLine: table?.startLine ?? 1) else {
            pasteError = "Clipboard does not contain tabular text."
            return
        }

        pasteError = nil

        if let table {
            var updated = parsed
            updated = MarkdownTable(
                startLine: table.startLine,
                endLine: table.endLine,
                headers: updated.headers,
                alignments: Array(repeating: .leading, count: updated.headers.count),
                rows: updated.rows
            )
            apply(updated)
        } else {
            onApplyMarkdown(MarkdownTableService.appending(parsed, to: markdown))
            selectedTableLine = nil
        }
    }
}
