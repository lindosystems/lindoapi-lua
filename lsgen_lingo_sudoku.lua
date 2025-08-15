#!/usr/bin/env lslua
-- Lua script to generate randomized N×N Sudoku Lingo models using Penlight
-- Author: Claude
-- Note: This generates standard Sudoku where N must be a perfect square (4, 9, 16, 25, etc.)

local lapp = require 'pl.lapp'  -- Penlight's lapp module for CLI parsing
local math = require 'math'

-- Command-line argument parsing with lapp
local args = lapp [[
Generate a randomized N×N Sudoku puzzle in LINGO format.
  -n,--size       (default 9)     Grid size N (must be perfect square: 4, 9, 16, 25)
  -c,--clues      (default 0.3)   Clue density (0.2 = 20% of cells filled)
  -s,--seed       (default 0)     Random seed (0 = use current time)
  -o,--output     (default "./sudoku_puzzle.lng")  Output LINGO file name
  -v,--verbose    (default false) Verbose output showing puzzle generation steps
]]

-- Validate inputs
if args.size < 4 then lapp.error("size must be at least 4") end
if args.clues < 0.1 or args.clues > 0.8 then lapp.error("clues density must be between 0.1 and 0.8") end

-- Validate that N is a perfect square
local function validate_n(n)
    local sqrt_n = math.floor(math.sqrt(n))
    if sqrt_n * sqrt_n ~= n then
        lapp.error("size must be a perfect square (4, 9, 16, 25, etc.). Got: " .. n)
    end
    return sqrt_n
end

-- Validate size and get sqrt
local N = args.size
local SQRT_N = validate_n(N)
local CLUES_PERCENTAGE = args.clues
local OUTPUT_FILE = args.output
local VERBOSE = args.verbose

-- Initialize random seed
if args.seed == 0 then
    math.randomseed(os.time())
    if VERBOSE then print("Using random seed based on current time") end
else
    math.randomseed(args.seed)
    if VERBOSE then print("Using specified seed: " .. args.seed) end
end

-- Create empty N×N grid
local function create_empty_grid(n)
    local grid = {}
    for i = 1, n do
        grid[i] = {}
        for j = 1, n do
            grid[i][j] = 0
        end
    end
    return grid
end

-- Check if placing value at position (row, col) is valid
local function is_valid_placement(grid, row, col, value, n, sqrt_n)
    -- Check row constraint
    for c = 1, n do
        if grid[row][c] == value then
            return false
        end
    end
    
    -- Check column constraint
    for r = 1, n do
        if grid[r][col] == value then
            return false
        end
    end
    
    -- Check subgrid constraint
    local subgrid_row_start = math.floor((row - 1) / sqrt_n) * sqrt_n + 1
    local subgrid_col_start = math.floor((col - 1) / sqrt_n) * sqrt_n + 1
    
    for r = subgrid_row_start, subgrid_row_start + sqrt_n - 1 do
        for c = subgrid_col_start, subgrid_col_start + sqrt_n - 1 do
            if grid[r][c] == value then
                return false
            end
        end
    end
    
    return true
end

-- Get list of valid values for a position
local function get_valid_values(grid, row, col, n, sqrt_n)
    local valid = {}
    for value = 1, n do
        if is_valid_placement(grid, row, col, value, n, sqrt_n) then
            table.insert(valid, value)
        end
    end
    return valid
end

-- Shuffle array in place
local function shuffle_array(arr)
    for i = #arr, 2, -1 do
        local j = math.random(i)
        arr[i], arr[j] = arr[j], arr[i]
    end
end

-- Generate a complete valid Sudoku solution using backtracking
local function generate_complete_solution(grid, n, sqrt_n)
    -- Find first empty cell
    local empty_row, empty_col = nil, nil
    for r = 1, n do
        for c = 1, n do
            if grid[r][c] == 0 then
                empty_row, empty_col = r, c
                break
            end
        end
        if empty_row then break end
    end
    
    -- If no empty cell, solution is complete
    if not empty_row then
        return true
    end
    
    -- Get valid values and randomize order
    local valid_values = get_valid_values(grid, empty_row, empty_col, n, sqrt_n)
    shuffle_array(valid_values)
    
    -- Try each valid value
    for _, value in ipairs(valid_values) do
        grid[empty_row][empty_col] = value
        
        if generate_complete_solution(grid, n, sqrt_n) then
            return true
        end
        
        -- Backtrack
        grid[empty_row][empty_col] = 0
    end
    
    return false
end

-- Remove clues to create puzzle (simple random removal)
local function create_puzzle_from_solution(solution, n, clues_percentage)
    local puzzle = {}
    -- Deep copy solution
    for i = 1, n do
        puzzle[i] = {}
        for j = 1, n do
            puzzle[i][j] = solution[i][j]
        end
    end
    
    local total_cells = n * n
    local clues_to_keep = math.floor(total_cells * clues_percentage)
    local cells_to_remove = total_cells - clues_to_keep
    
    -- Create list of all positions
    local positions = {}
    for r = 1, n do
        for c = 1, n do
            table.insert(positions, {r, c})
        end
    end
    
    -- Randomly select positions to remove
    shuffle_array(positions)
    for i = 1, cells_to_remove do
        local row, col = positions[i][1], positions[i][2]
        puzzle[row][col] = 0
    end
    
    return puzzle
end

-- Generate Lingo model string
local function generate_lingo_model(puzzle, n, sqrt_n)
    local model = {}
    
    -- Header
    table.insert(model, "MODEL:")
    table.insert(model, "! Randomly generated " .. n .. "×" .. n .. " Sudoku Solver in LINGO")
    table.insert(model, "! Generated on: " .. os.date("%Y-%m-%d %H:%M:%S"))
    table.insert(model, "! Subgrid size: " .. sqrt_n .. "×" .. sqrt_n)
    table.insert(model, ";")
    
    -- Sets
    table.insert(model, "SETS:")
    table.insert(model, " DIM;")
    table.insert(model, " DD( DIM, DIM): X;")
    table.insert(model, " DDD( DIM, DIM, DIM): Y;")
    table.insert(model, "ENDSETS")
    table.insert(model, "")
    
    -- Data
    table.insert(model, "DATA:")
    table.insert(model, "  DIM = 1.." .. n .. ";")
    table.insert(model, "ENDDATA")
    table.insert(model, "")
    
    -- Variables comment
    table.insert(model, "! Variables:")
    table.insert(model, "!   X(i,j) = value in row i, col j of matrix,")
    table.insert(model, "!   Y(i,j,k) = 1 if X(i,j) = k;")
    table.insert(model, "")
    
    -- Pre-specified entries
    table.insert(model, "! Insert the pre-specified entries for this puzzle;")
    local clue_count = 0
    for r = 1, n do
        for c = 1, n do
            if puzzle[r][c] ~= 0 then
                table.insert(model, "   X(" .. r .. "," .. c .. ") = " .. puzzle[r][c] .. ";")
                clue_count = clue_count + 1
            end
        end
    end
    table.insert(model, "! Total clues: " .. clue_count .. " out of " .. (n*n) .. " cells")
    table.insert(model, "")
    
    -- Link X and Y constraints
    table.insert(model, "! Link X and Y;")
    table.insert(model, "   @FOR( dd(i,j):")
    table.insert(model, "     X(i,j) = @SUM(dim(k): k*y(i,j,k));")
    table.insert(model, " ! Must choose something for cell i,j;")
    table.insert(model, "    @SUM(dim(k): y(i,j,k)) = 1;")
    table.insert(model, " ! Make the Y's binary;")
    table.insert(model, "    @FOR(dim(k): @BIN(y(i,j,k)));")
    table.insert(model, "       );")
    table.insert(model, "")
    
    -- Row constraints
    table.insert(model, "! Force each number k to appear once in each column j;")
    table.insert(model, "   @FOR( dim(j):")
    table.insert(model, "     @FOR( dim(k):")
    table.insert(model, "       @SUM( dim(i): Y(i,j,k)) = 1;")
    table.insert(model, "       );  );")
    table.insert(model, "")
    
    -- Column constraints
    table.insert(model, "! Force each number k to appear once in each row i;")
    table.insert(model, "   @FOR( dim(i):")
    table.insert(model, "     @FOR( dim(k):")
    table.insert(model, "       @SUM( dim(j): Y(i,j,k)) = 1;")
    table.insert(model, "        ); );")
    table.insert(model, "")
    
    -- Subgrid constraints
    table.insert(model, "! Force each number k to appear once in each " .. sqrt_n .. "×" .. sqrt_n .. " subsquare;")
    table.insert(model, "   @FOR( dim(k):")
    
    -- Generate all subgrid constraints
    for subgrid_row = 0, sqrt_n - 1 do
        for subgrid_col = 0, sqrt_n - 1 do
            local start_row = subgrid_row * sqrt_n + 1
            local end_row = start_row + sqrt_n - 1
            local start_col = subgrid_col * sqrt_n + 1
            local end_col = start_col + sqrt_n - 1
            
            local position_desc = ""
            if subgrid_row == 0 then position_desc = "Upper "
            elseif subgrid_row == sqrt_n - 1 then position_desc = "Lower "
            else position_desc = "Middle " end
            
            if subgrid_col == 0 then position_desc = position_desc .. "left"
            elseif subgrid_col == sqrt_n - 1 then position_desc = position_desc .. "right"
            else position_desc = position_desc .. "middle" end
            
            table.insert(model, "     ! " .. position_desc .. " (rows " .. start_row .. "-" .. end_row .. ", cols " .. start_col .. "-" .. end_col .. ");")
            
            local condition = "i #gt#" .. (start_row - 1) .. " #and# i #le#" .. end_row .. " #and# j #gt#" .. (start_col - 1) .. " #and# j #le#" .. end_col
            table.insert(model, "     @SUM( dd(i,j) | " .. condition .. ": y(i,j,k)) = 1;")
        end
    end
    
    table.insert(model, "       );")
    table.insert(model, "")
    
    -- Solver section
    table.insert(model, "  CALC:")
    table.insert(model, "    @SET( 'TERSEO', 1);")
    table.insert(model, "    @SOLVE();")
    table.insert(model, " ! Write the solution in matrix form;")
    table.insert(model, "    @WRITE( @NEWLINE( 1), 25*' ', '" .. n .. "×" .. n .. " Sudoku Puzzle Solution', @NEWLINE( 1));")
    table.insert(model, "    @FOR( DIM( i):")
    table.insert(model, "       @FOR( DIM( j):")
    table.insert(model, "          @WRITE( @FORMAT( '8g', x( i, j)));")
    table.insert(model, "       );")
    table.insert(model, "       @WRITE( @NEWLINE( 1));")
    table.insert(model, "    );")
    table.insert(model, "  ENDCALC")
    table.insert(model, "")
    table.insert(model, "END")
    
    return table.concat(model, "\n")
end

-- Print puzzle in readable format
local function print_puzzle(puzzle, n, name)
    print("\n" .. name .. ":")
    print(string.rep("=", n * 2 + 1))
    for r = 1, n do
        local row_str = ""
        for c = 1, n do
            if puzzle[r][c] == 0 then
                row_str = row_str .. ". "
            else
                row_str = row_str .. puzzle[r][c] .. " "
            end
        end
        print(row_str)
    end
end

-- Main execution
local function main()
    if VERBOSE then
        print("Generating randomized " .. N .. "×" .. N .. " Sudoku Lingo model...")
        print("Configuration:")
        print("  Grid size: " .. N .. "×" .. N)
        print("  Subgrid size: " .. SQRT_N .. "×" .. SQRT_N)
        print("  Clue density: " .. string.format("%.1f%%", CLUES_PERCENTAGE * 100))
        print("  Output file: " .. OUTPUT_FILE)
    end
    
    -- Generate complete solution
    if VERBOSE then print("\nGenerating complete solution...") end
    local solution = create_empty_grid(N)
    
    if not generate_complete_solution(solution, N, SQRT_N) then
        error("Failed to generate complete solution")
    end
    
    if VERBOSE then
        print("Complete solution generated!")
        print_puzzle(solution, N, "Complete Solution")
    end
    
    -- Create puzzle by removing clues
    if VERBOSE then print("\nCreating puzzle by removing clues...") end
    local puzzle = create_puzzle_from_solution(solution, N, CLUES_PERCENTAGE)
    
    if VERBOSE then
        print_puzzle(puzzle, N, "Generated Puzzle")
    end
    
    -- Generate Lingo model
    local lingo_model = generate_lingo_model(puzzle, N, SQRT_N)
    
    -- Write to file
    local file = io.open(OUTPUT_FILE, "w")
    if not file then
        error("Could not open output file: " .. OUTPUT_FILE)
    end
    
    file:write(lingo_model)
    file:close()
    
    -- Statistics
    local clues = 0
    for r = 1, N do
        for c = 1, N do
            if puzzle[r][c] ~= 0 then
                clues = clues + 1
            end
        end
    end
    
    print("\nSudoku puzzle generated successfully!")
    print("Output file: " .. OUTPUT_FILE)
    print("Statistics:")
    print("  Grid size: " .. N .. "×" .. N)
    print("  Subgrid size: " .. SQRT_N .. "×" .. SQRT_N)
    print("  Total cells: " .. (N * N))
    print("  Clues provided: " .. clues)
    print("  Empty cells: " .. (N * N - clues))
    print("  Actual clue percentage: " .. string.format("%.1f%%", (clues / (N * N)) * 100))
    
    if VERBOSE then
        print("\n" .. string.rep("=", 60))
        print("GENERATED LINGO MODEL PREVIEW:")
        print(string.rep("=", 60))
        -- Show first 20 lines of the model
        local lines = {}
        for line in lingo_model:gmatch("[^\r\n]+") do
            table.insert(lines, line)
        end
        
        for i = 1, math.min(20, #lines) do
            print(lines[i])
        end
        
        if #lines > 20 then
            print("... (" .. (#lines - 20) .. " more lines)")
        end
    end
end

-- Execute main function
main()