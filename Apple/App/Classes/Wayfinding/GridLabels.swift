nonisolated struct GridLabels {

    let values: [Int32]
    let count: Int

    /// Four-connected component labelling; labels start at 1 and 0 marks cells left out.
    static func label(_ mask: [Bool], rows: Int, columns: Int) -> GridLabels {
        var values = [Int32](repeating: 0, count: mask.count)
        var next: Int32 = 0
        var stack: [Int] = []
        for start in 0..<mask.count where mask[start] && values[start] == 0 {
            next += 1
            values[start] = next
            stack.append(start)
            while let index = stack.popLast() {
                let row = index / columns
                let column = index % columns
                if column > 0, mask[index - 1], values[index - 1] == 0 {
                    values[index - 1] = next
                    stack.append(index - 1)
                }
                if column < columns - 1, mask[index + 1], values[index + 1] == 0 {
                    values[index + 1] = next
                    stack.append(index + 1)
                }
                if row > 0, mask[index - columns], values[index - columns] == 0 {
                    values[index - columns] = next
                    stack.append(index - columns)
                }
                if row < rows - 1, mask[index + columns], values[index + columns] == 0 {
                    values[index + columns] = next
                    stack.append(index + columns)
                }
            }
        }
        return GridLabels(values: values, count: Int(next))
    }

    static func largestComponent(of mask: [Bool], rows: Int, columns: Int) -> [Bool] {
        let labels = label(mask, rows: rows, columns: columns)
        guard labels.count > 0 else { return mask }
        var area = [Int](repeating: 0, count: labels.count + 1)
        for value in labels.values where value > 0 {
            area[Int(value)] += 1
        }
        let largest = Int32(area.indices.dropFirst().max(by: { area[$0] < area[$1] }) ?? 1)
        return labels.values.map { $0 == largest }
    }

    static func reachableFromBorder(_ mask: [Bool], rows: Int, columns: Int) -> [Bool] {
        var reached = [Bool](repeating: false, count: mask.count)
        var stack: [Int] = []
        for row in 0..<rows {
            for column in 0..<columns
            where (row == 0 || column == 0 || row == rows - 1 || column == columns - 1) && mask[row * columns + column] {
                reached[row * columns + column] = true
                stack.append(row * columns + column)
            }
        }
        while let index = stack.popLast() {
            let row = index / columns
            let column = index % columns
            for (dy, dx) in [(0, 1), (1, 0), (0, -1), (-1, 0)] {
                let nextRow = row + dy
                let nextColumn = column + dx
                guard nextRow >= 0, nextRow < rows, nextColumn >= 0, nextColumn < columns else { continue }
                let next = nextRow * columns + nextColumn
                if mask[next] && !reached[next] {
                    reached[next] = true
                    stack.append(next)
                }
            }
        }
        return reached
    }

    /// Morphological closing with a straight line, which bridges gaps up to `length` cells
    /// along that direction and nowhere else.
    static func closeAlongLine(
        _ mask: [Bool], rows: Int, columns: Int, direction: (Int, Int), length: Int
    ) -> [Bool] {
        let reach = length / 2
        func sweep(_ input: [Bool], keepsWhenAny: Bool) -> [Bool] {
            var output = [Bool](repeating: false, count: input.count)
            for row in 0..<rows {
                for column in 0..<columns {
                    var any = false
                    var all = true
                    for step in -reach...reach {
                        let sampleRow = row + step * direction.0
                        let sampleColumn = column + step * direction.1
                        let value: Bool
                        if sampleRow >= 0, sampleRow < rows, sampleColumn >= 0, sampleColumn < columns {
                            value = input[sampleRow * columns + sampleColumn]
                        } else {
                            value = !keepsWhenAny
                        }
                        any = any || value
                        all = all && value
                    }
                    output[row * columns + column] = keepsWhenAny ? any : all
                }
            }
            return output
        }
        return sweep(sweep(mask, keepsWhenAny: true), keepsWhenAny: false)
    }
}
