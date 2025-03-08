import SwiftUI

class SudokuViewModel: ObservableObject {
    // Timer properties
    @Published var timerString: String = "00:00"
    private var timer: Timer?
    private var startTime: Date?
    private var isTimerRunning = false
    @Published var elapsedTime: Int = 0

    // Cell properties
    @Published var cells: [CellModel] = []
    private var initialCells: [CellModel] = [] // To store the initial puzzle state
    @Published var selectedCell: CellModel? {
        didSet {
            updateSelectedCell()
        }
    }
    @Published var cages: [KillerCage]? = nil  // New property for Killer mode cages

    @Published var isPencilMode: Bool = false
    
    @Published var isGameCompleted: Bool = false
    @Published var isGameOver: Bool = false
    
    let difficulty: Difficulty
    private var solutionGrid: [[Int]] = []
    
    init(difficulty: Difficulty) {
        self.difficulty = difficulty
    }

    // MARK: - Game Setup

    func startGame(difficulty: Difficulty) {
        // Generate puzzle based on difficulty
        let sudokuPuzzle = SudokuGenerator.generatePuzzle(difficulty: difficulty)
        self.cells = sudokuPuzzle.puzzle
        self.initialCells = self.cells // Save the initial state
        self.solutionGrid = sudokuPuzzle.solution
        self.isGameCompleted = false
        
        if difficulty == .killer {
                    self.cages = sudokuPuzzle.cages
                } else {
                    self.cages = nil
                }
        
        startTimer()
    }

    // MARK: - Cell Selection and Updates

    private func updateSelectedCell() {
        guard let selectedCell,
              let selectedIndex = cells.firstIndex(where: { $0.id == selectedCell.id }) else {
            // No cell is selected, reset highlights
            for index in cells.indices {
                cells[index].isSelected = false
                cells[index].isHighlighted = false
            }
            return
        }

        let selectedRow = selectedIndex / 9
        let selectedCol = selectedIndex % 9

        for index in cells.indices {
            let row = index / 9
            let col = index % 9
            let isSameRow = row == selectedRow
            let isSameCol = col == selectedCol
            let isSameBlock = (row / 3 == selectedRow / 3) && (col / 3 == selectedCol / 3)

            cells[index].isSelected = (cells[index].id == selectedCell.id)
            cells[index].isHighlighted = isSameRow || isSameCol || isSameBlock
        }
    }

    func enterNumber(_ number: Int?) {
        guard let selectedCell,
              let index = cells.firstIndex(where: { $0.id == selectedCell.id }) else { return }

        if cells[index].isEditable {
            if isPencilMode {
                // If the cell has a value, remove it before proceeding
                if cells[index].value != nil {
                    cells[index].value = nil
                    // Reset isIncorrect flag when the value is removed
                    if cells[index].isIncorrect {
                        cells[index].isIncorrect = false
                    }
                }

                // Handle pencil mode notes
                if let number {
                    if cells[index].notes.contains(number) {
                        cells[index].notes.removeAll { $0 == number }
                    } else {
                        cells[index].notes.append(number)
                        cells[index].notes.sort()
                    }
                }
            } else {
                // Regular mode: Set or delete the cell's value
                if let number {
                    cells[index].value = number
                    // Clear notes when a value is entered
                    cells[index].notes = []
                } else {
                    // Handle deletion
                    cells[index].value = nil
                }
                // Reset isIncorrect flag when a cell is edited
                if cells[index].isIncorrect {
                    cells[index].isIncorrect = false
                }
            }
            
            checkForCompletion(markCellsAsIncorrect: false)
            objectWillChange.send()
        }
    }

    // MARK: - Pencil Mode

    func togglePencilMode() {
        isPencilMode.toggle()
    }

    // MARK: - Puzzle Validation

    func checkPuzzle() {
        var hasError = false

        // Reset all isIncorrect flags
        for index in cells.indices {
            if cells[index].isEditable {
                cells[index].isIncorrect = false
            }
        }

        // Validate each cell
        for index in cells.indices {
            if !validateCell(at: index) {
                hasError = true
            }
        }
        if !hasError {
            checkForCompletion()
        }
    }

    @discardableResult
    private func validateCell(at index: Int, markAsIncorrect: Bool = true) -> Bool {
        guard let userValue = cells[index].value else {
            // If the cell is empty, it's not incorrect
            cells[index].isIncorrect = false
            return true
        }

        let row = index / 9
        let col = index % 9

        let solutionValue = solutionGrid[row][col]

        if userValue != solutionValue {
            // Mark the cell as incorrect
            if cells[index].isEditable && markAsIncorrect {
                cells[index].isIncorrect = true
            }
            return false
        } else {
            // The cell is correct
            if cells[index].isEditable {
                cells[index].isIncorrect = false
            }
            return true
        }
    }

    // Check if the puzzle is completely and correctly filled
    private func checkForCompletion(markCellsAsIncorrect: Bool = true) {
        for index in cells.indices {
            if !validateCell(at: index, markAsIncorrect: markCellsAsIncorrect) || cells[index].value == nil {
                // If any cell is invalid or empty, check if all cells are filled
                if cells.allSatisfy({ $0.value != nil }) {
                    // All cells are filled, but the puzzle is incorrect
                    isGameOver = true
                }
                return
            }
        }
        isGameOver = true
        isGameCompleted = true
        stopTimer()
        
    }

    // MARK: - Restart Puzzle

    func restartPuzzle() {
        self.cells = initialCells
        self.selectedCell = nil
        self.isGameCompleted = false
        self.isGameOver = false
        startTime = Date()
        timerString = "00:00"
        startTimer()
    }

    // MARK: - Timer Management

    private func startTimer() {
        startTime = Date()
        isTimerRunning = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            guard self.isTimerRunning else { return }
            self.elapsedTime = Int(Date().timeIntervalSince(self.startTime ?? Date()))
            self.timerString = String(format: "%02d:%02d", self.elapsedTime / 60, self.elapsedTime % 60)
        }
    }

    private func stopTimer() {
        isTimerRunning = false
        timer?.invalidate()
        if let startTime = startTime {
            self.elapsedTime = Int(Date().timeIntervalSince(startTime))
        }
    }

    // MARK: - Game Pause and Resume (Optional)

    func pauseGame() {
        isTimerRunning = false
    }

    func resumeGame() {
        isTimerRunning = true
    }
}
