import Foundation

class SudokuGenerator {
    static func generatePuzzle(difficulty: Difficulty) -> SudokuPuzzle {
        // Generate a complete Sudoku grid
        let solutionGrid = generateCompleteGrid()
        
        // Remove numbers from the grid based on difficulty
        let numberOfCellsToRemove = difficulty.numberOfCellsToRemove()
        let puzzleGrid = removeNumbers(from: solutionGrid, count: numberOfCellsToRemove)
        
        // Convert the grid into CellModel objects
        let cells = puzzleGrid.flatMap { row in
            row.map { value in
                CellModel(value: value == 0 ? nil : value, isEditable: value == 0)
            }
        }
        
        // If Killer mode, generate cages.
        var cages: [KillerCage]? = nil
        if difficulty == .killer {
            cages = generateCages(for: solutionGrid)
        }
        
        return SudokuPuzzle(puzzle: cells, solution: solutionGrid, cages: cages)
    }
    
    private static func generateCompleteGrid() -> [[Int]] {
        var grid = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        _ = fillGrid(&grid)
        return grid
    }
    
    private static func fillGrid(_ grid: inout [[Int]]) -> Bool {
        for row in 0..<9 {
            for col in 0..<9 {
                if grid[row][col] == 0 {
                    var numbers = Array(1...9)
                    numbers.shuffle()
                    for number in numbers {
                        if isValid(number, atRow: row, column: col, in: grid) {
                            grid[row][col] = number
                            if fillGrid(&grid) {
                                return true
                            }
                            grid[row][col] = 0
                        }
                    }
                    return false
                }
            }
        }
        return true
    }
    
    private static func isValid(_ number: Int, atRow row: Int, column col: Int, in grid: [[Int]]) -> Bool {
        // Check if the number is not repeated in the row
        for x in 0..<9 {
            if grid[row][x] == number {
                return false
            }
        }
        
        // Check if the number is not repeated in the column
        for y in 0..<9 {
            if grid[y][col] == number {
                return false
            }
        }
        
        // Check if the number is not repeated in the 3x3 subgrid
        let startRow = (row / 3) * 3
        let startCol = (col / 3) * 3
        for x in startRow..<startRow + 3 {
            for y in startCol..<startCol + 3 {
                if grid[x][y] == number {
                    return false
                }
            }
        }
        
        return true
    }
    
    private static func removeNumbers(from grid: [[Int]], count: Int) -> [[Int]] {
        var grid = grid.map { $0.map { $0 } } // Deep copy of the grid
        var cellsToRemove = count
        
        while cellsToRemove > 0 {
            let row = Int.random(in: 0..<9)
            let col = Int.random(in: 0..<9)
            
            if grid[row][col] != 0 {
                let backup = grid[row][col]
                grid[row][col] = 0
                
                // Ensure that the puzzle still has a unique solution
                if hasUniqueSolution(grid) {
                    cellsToRemove -= 1
                } else {
                    grid[row][col] = backup
                }
            }
        }
        
        return grid
    }
    
    private static func hasUniqueSolution(_ grid: [[Int]]) -> Bool {
        var solutionCount = 0
        var gridCopy = grid
        _ = solve(&gridCopy, solutionCount: &solutionCount, maxSolutions: 2)
        return solutionCount == 1
    }
    
    private static func solve(_ grid: inout [[Int]], solutionCount: inout Int, maxSolutions: Int) -> Bool {
        if solutionCount >= maxSolutions {
            return true
        }
        
        for row in 0..<9 {
            for col in 0..<9 {
                if grid[row][col] == 0 {
                    for number in 1...9 {
                        if isValid(number, atRow: row, column: col, in: grid) {
                            grid[row][col] = number
                            if solve(&grid, solutionCount: &solutionCount, maxSolutions: maxSolutions) {
                                grid[row][col] = 0
                                return true
                            }
                            grid[row][col] = 0
                        }
                    }
                    return false
                }
            }
        }
        
        solutionCount += 1
        return false
    }
}

extension Difficulty {
    func numberOfCellsToRemove() -> Int {
        switch self {
        case .easy:
            return 35
        case .medium:
            return 46
        case .hard:
            return 55
        case .killer:
            return 55
        }
    }
}

extension SudokuGenerator {
    
    /// Generate killer cages from the solution grid.
    /// This example randomly creates between 4 and 8 cages with 2–4 cells each.
    static func generateCages(for solutionGrid: [[Int]]) -> [KillerCage] {
        var cages = [KillerCage]()
        // Track which cells have been assigned to a cage.
        var assigned = Array(repeating: Array(repeating: false, count: 9), count: 9)
        
        // Decide on a number of cages (this is arbitrary; adjust as needed)
        let numberOfCages = Int.random(in: 6...20)
        
        for _ in 0..<numberOfCages {
            // Find a random cell that is not yet assigned.
            var row = Int.random(in: 0..<9)
            var col = Int.random(in: 0..<9)
            var attempts = 0
            while assigned[row][col] && attempts < 100 {
                row = Int.random(in: 0..<9)
                col = Int.random(in: 0..<9)
                attempts += 1
            }
            // If all cells are assigned, break out.
            if assigned[row][col] { break }
            
            // Start a new cage with this cell.
            var cageCells = [(row: Int, col: Int)]()
            cageCells.append((row, col))
            assigned[row][col] = true
            
            // Randomly decide on a cage size between 2 and 7 cells.
            let cageSize = Int.random(in: 2...7)
            
            // Expand the cage by adding adjacent cells.
            while cageCells.count < cageSize {
                // Find neighbors of any cell in cageCells that are not yet assigned.
                var potentialNeighbors = [(Int, Int)]()
                for (r, c) in cageCells {
                    let deltas = [(-1,0), (1,0), (0,-1), (0,1)]
                    for (dr, dc) in deltas {
                        let nr = r + dr, nc = c + dc
                        if nr >= 0 && nr < 9 && nc >= 0 && nc < 9 && !assigned[nr][nc] {
                            // Avoid duplicates.
                            if !potentialNeighbors.contains(where: { $0 == (nr, nc) }) {
                                potentialNeighbors.append((nr, nc))
                            }
                        }
                    }
                }
                if potentialNeighbors.isEmpty { break }
                let randomNeighbor = potentialNeighbors.randomElement()!
                cageCells.append(randomNeighbor)
                assigned[randomNeighbor.0][randomNeighbor.1] = true
            }
            
            // Compute the cage sum using the solution grid.
            let cageSum = cageCells.reduce(0) { sum, pos in
                return sum + solutionGrid[pos.row][pos.col]
            }
            cages.append(KillerCage(cells: cageCells, sum: cageSum))
        }
        
        return cages
    }
}
