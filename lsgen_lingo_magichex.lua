#!/usr/bin/env lslua
--local Lindo = require("llindo_tabox")
local lapp = require 'pl.lapp' -- Penlight's lapp module for CLI parsing
local math = require 'math'

local N, BLK
local args = lapp [[
Generate a LINGO model for the magic hexagon problem.
   -n,--norder   (default 5)    Order of the hexagon (N > 2)
   -b,--block    (default 0)    Partition into block groups (0 for no block)
   -g,--debug    (default 0)    Debug mode (1 for debug, 0 for normal)
   -s,--ssym     (default 1)    Show symmetries to break
   -G,--gen      (default 0)    Generate all orders of hexagons up to N (starting from 3)
   -o,--outdir   (default "./prob/gen")  Output directory for generated files
]]

local block_groups = {"HRZ", "LLR", "ULR"}

-- Validate inputs
assert(args.norder > 2, "Order must be positive and greater than 2")
if args.gen > 0 then
    assert(args.gen > 2, "Order must be positive and greater than 2")
    for i = 3, args.gen do
        local cmd = string.format("lslua lsgen_lingo_magixhex.lua -n %d | tee %s/MagicHex%d_obj.lng", i,args.outdir,i)
        cmd:gsub("\r", ""):gsub("\n", "")
        print(cmd)
    end
    return
end


--- Function to print the hexagonal grid structure
-- @param hex is the hexagonal grid structure
local function print_hex_grid(hex)
    local N = math.floor((#hex + 1) / 2)
    local lines = {}
    table.insert(lines, string.format("! Honeycomb structure for order N=%d;", N))

    for r = 1, #hex do
        local row = hex[r]
        local indent_level = math.abs(N - r)
        local indent = string.rep("  ", indent_level)
        local line = "! " .. indent
        for _, val in ipairs(row) do
            if val ~= 0 then
                line = line .. string.format("%3d ", val)
            end
        end
        table.insert(lines, line)
    end
    table.insert(lines,"!;")

    print(table.concat(lines, "\n"))
end

-- Function to generate LLR and ULR diagonal sets for the magic hexagon problem
-- Builds the raw honeycomb layout with correct IDs for order N
local function build_honeycomb(N)
    local rows = {}
    local id = 1
    for r = 1, 2 * N - 1 do
        local len = N + math.min(r - 1, 2 * N - 1 - r)
        rows[r] = {}
        for i = 1, len do
            table.insert(rows[r], id)
            id = id + 1
        end
    end
    return rows
end

-- Pads the rows into a square matrix of size (2N-1) x (2N-1)
local function build_padded_matrix(rows, M)
    local matrix = {}
    for r = 1, M do
        matrix[r] = {}
        for c = 1, M do
            matrix[r][c] = 0
        end
    end
    return matrix
end

-- Wraps build_honeycomb and build_padded_matrix to produce the padded hex matrix
local function build_hex_grid(N, rows)
    local M = 2 * N - 1
    local rows = rows or build_honeycomb(N)
    local hex = build_padded_matrix(rows, M)

    -- Center rows in padded matrix
    for r = 1, M do
        local row = rows[r]
        local len = #row
        local offset = math.floor((M - len) / 2)
        for i = 1, len do
            hex[r][offset + i] = row[i]
        end
    end

    return hex
end

-- Shifts rows for LLR (upper rows to the right, lower stay left)
local function shift_rows_for_llr(rows, M, N)
    local matrix = build_padded_matrix(rows, M)
    for r = 1, #rows do
        local row = rows[r]
        local padding = r <= N and (M - #row) or 0
        for i = 1, #row do
            matrix[r][padding + i] = row[i]
        end
    end
    return matrix
end

-- Shifts rows for ULR (upper rows to the left, lower rows to the right)
local function shift_rows_for_ulr(rows, M, N)
    local matrix = build_padded_matrix(rows, M)
    for r = 1, #rows do
        local row = rows[r]
        local padding = r < N and 0 or (M - #row)
        for i = 1, #row do
            matrix[r][padding + i] = row[i]
        end
    end
    return matrix
end

-- Collects non-zero column values into diagonal groups
local function collect_columns(matrix, N)
    local M = #matrix
    local groups = {}
    for c = 1, M do
        local group = {}
        for r = 1, M do
            local val = matrix[r][c]
            if val ~= 0 then table.insert(group, val) end
        end
        if #group >= N then table.insert(groups, group) end
    end
    return groups
end

-- Main function using helpers
local function generate_diagonal_groups(N,rows)
    local M = 2 * N - 1
    local rows = rows or build_honeycomb(N)

    local matrix_llr = shift_rows_for_llr(rows, M, N)
    local matrix_ulr = shift_rows_for_ulr(rows, M, N)

    local llr = collect_columns(matrix_llr, N)
    local ulr = collect_columns(matrix_ulr, N)

    return llr, ulr
end

-- Generates the horizontal groups for the hexagon
-- Each row is a group, and the number of groups is 2N-1
local function generate_horizontal_groups(N)
    local hrz = {}
    local id = 1
    -- Top to middle rows
    for r = 1, N do
        local row = {}
        for c = 1, N + r - 1 do
            table.insert(row, id)
            id = id + 1
        end
        table.insert(hrz, row)
    end
    -- Bottom rows
    for r = N - 1, 1, -1 do
        local row = {}
        for c = 1, N + r - 1 do
            table.insert(row, id)
            id = id + 1
        end
        table.insert(hrz, row)
    end
    return hrz
end

-- Prints the groups for debugging
-- @param groups is a table of groups to print
local function print_groups(groups, label)
    for i, g in ipairs(groups) do
        io.write(string.format("%s%d: ", label, i))
        for _, v in ipairs(g) do
            io.write(v .. " ")
        end
        io.write("\n")
    end
end

-- Generates the LINGO model for the magic hexagon problem
-- @param N is the order of the hexagon
function generate_lingo_magic_hexagon(N)
    assert(N > 2, "N must be greater than 2")

    local function total_cells(N)
        return 3 * N * (N - 1) + 1        
    end
    
    -- Estimate of the magic sum for the hexagon
    -- Not all hexagons are magic with 1..(3N^2-3N+1)    
    local function magic_sum(N)
        local M = total_cells(N)
        local totalSum = M * (M + 1) / 2
        local numRowsPerDirection = 2 * N - 1
        local magicSum = totalSum / numRowsPerDirection
        return magicSum
    end
    
    local ncells = total_cells(N)
    local KSUM = "KSUM" 
    local KOFF = 0      
    local valset = {}
    for i = 1, ncells do table.insert(valset, i) end

    local lingo = {}
    table.insert(lingo, "MODEL:")
    table.insert(lingo, "SETS:")
    table.insert(lingo, "\tcell /1.." .. ncells .. "/:")
    table.insert(lingo, "\t\tvalasg;")
    table.insert(lingo, "\tvalset /1.." .. ncells .. "/;")
    if BLK==0 then
        table.insert(lingo, "\tcxv(cell,valset): z;")
    else
        table.insert(lingo, "\tcxv(cell,valset): zHRZ, zLLR, zLRL;")        
    end
    table.insert(lingo, "ENDSETS")

    table.insert(lingo, "! Variables: z(i,j) = 1 if cell i is assigned value j;")
    table.insert(lingo, "! Each value is assigned once;")
    if BLK==0 then
        table.insert(lingo, "@FOR(valset(j): @SUM(cell(i): z(i,j)) = 1;);")
        table.insert(lingo, "! Each cell gets a value;")
        table.insert(lingo, "@FOR(cell(i): @SUM(valset(j): z(i,j)) = 1; valasg(i) = @SUM(valset(j): (KOFF+j)*z(i,j)););")    
        table.insert(lingo, "! Binary constraints;")
        table.insert(lingo, "@FOR(cxv(i,j): @BIN(z(i,j)));")
        -- Add symmetry-breaking constraints and solver settings
        table.insert(lingo, "! Optional symmetry-breaking driver;")
        table.insert(lingo, "min= @sum( valset(j): j*z(KIDX,j));")        
    else
        for i=1,#block_groups do
            local tag = block_groups[i]
            table.insert(lingo, string.format("@FOR(valset(j): @SUM(cell(i): z%s(i,j)) = 1;);",tag))
            table.insert(lingo, "! Each cell gets a value;")
            table.insert(lingo, string.format("@FOR(cell(i): @SUM(valset(j): z%s(i,j)) = 1; valasg(i) = @SUM(valset(j): (KOFF+j)*z%s(i,j)););",tag,tag))    
            table.insert(lingo, "! Binary constraints;")
            table.insert(lingo, string.format("@FOR(cxv(i,j): @BIN(z%s(i,j)));",tag))
        end
        -- Block KSUMS should be equal
        for k=1,#block_groups-1 do
            local tag1 = block_groups[k]
            local tag2 = block_groups[k+1]
            table.insert(lingo, string.format("@FOR(cxv(i,j): z%s(i,j) - z%s(i,j) = 0; );",tag1,tag2))
        end                
        -- Add symmetry-breaking constraints and solver settings
        table.insert(lingo, "! Optional symmetry-breaking driver;")
        local tag1 = block_groups[1]
        local tag2 = block_groups[2]
        local tag3 = block_groups[3]
        table.insert(lingo, string.format("min= @sum( valset(j): j*z%s(KIDX,j)) + @sum( valset(j): j*z%s(KIDX,j)) + @sum( valset(j): j*z%s(KIDX,j));",tag1,tag2,tag3))
    end
    

    table.insert(lingo, "! There is lots of symmetry. Choose one of the solutions;")
    table.insert(lingo, "! There are 6xN rotations and 3 reflections;")    
    table.insert(lingo, "! To eliminate rotations, take cell(i), enumerate all positions in each rotation and add a constraint to use only one;")
    table.insert(lingo, "CALC:")
    table.insert(lingo, "\tKIDX = 6;")
    table.insert(lingo, string.format("\tKSUM = %d; %s",magic_sum(N),"!Comment out to make KSUM the variable to use in place off 'magic_sum(N);"))
    table.insert(lingo, string.format("\tKOFF = %d; %s",KOFF,"!Comment out to make KOFF the variable to offset for the values assigned in the hexagon, "))
    table.insert(lingo, string.format("                       Positive KOFF shifts values assigned from 1..(3N^2-3N+1) to (1+KOFF)..(3N^2-3N+1+KOFF)"))
    table.insert(lingo, string.format("                       If it is a variable (i.e. commented out from CALC), it should better be @free;"))
    table.insert(lingo, "\t!@SET('XSOLVR',14,0); !Remove comment to use external solver '14';")
    table.insert(lingo, "\t@SET('SOLVLG', 2);")
    table.insert(lingo, "\t!@SET('GLOBAL', 1); !Remove comment to activate global solver if KOFF is a variable;")
    table.insert(lingo, "ENDCALC")

    local function add_constraint(group, szgrp, i)
        local tag = string.format("%s%d", szgrp, i)
        local terms = {}
        local szvar = "z"
        local GRPSUM = KSUM
        if BLK > 0 then
            szvar = string.format("z%s", szgrp)
            GRPSUM = string.format("KSUM_%s", szgrp)
        end
        for _, cell in ipairs(group) do
            table.insert(terms, string.format("@SUM(valset(j): (j+KOFF)*%s(%d,j))", szvar,cell))
        end
        table.insert(lingo, string.format("[%s] %s = %s;", tag, table.concat(terms, " + "), GRPSUM))
    end

    -- Horizontal constraints
    for i, group in ipairs(generate_horizontal_groups(N)) do
        add_constraint(group, "HRZ" , i)
    end

    -- Diagonal constraints
    local llr, ulr = generate_diagonal_groups(N)
    for i, group in ipairs(llr) do
        add_constraint(group, "LLR" , i)
    end
    for i, group in ipairs(ulr) do
        add_constraint(group, "ULR" , i)
    end

    table.insert(lingo, "END")

    return table.concat(lingo, "\n")
end

-- Returns a string describing the honeycomb grid structure for order N
-- @param N is the order of the hexagon
-- @param ASG is an optional argument to show the assigned values in the grid
function describe_honeycomb(N, ASG)
    local description = {}
    local count = 1    
    table.insert(description, string.format("! Honeycomb structure for order N=%d;", N))
    -- Upper part of the hexagon
    for i = 1, N - 1 do
        local line = string.rep("  ", N - i)
        for j = 1, N - 1 + i do
            line = line .. string.format("%3d ", ASG and ASG[count] or count)
            count = count + 1
        end
        table.insert(description, line)
    end

    -- Middle line of the hexagon
    local line = ""
    for j = 1, 2 * N - 1 do
        line = line .. string.format("%3d ", ASG and ASG[count] or count)
        count = count + 1
    end
    table.insert(description, line)

    -- Lower part of the hexagon
    for i = N - 1, 1, -1 do
        local line = string.rep("  ", N - i)
        for j = 1, N - 1 + i do
            line = line .. string.format("%3d ", ASG and ASG[count] or count)
            count = count + 1
        end
        table.insert(description, line)
    end

    -- Prefix with comment character for LINGO
    for i, row in ipairs(description) do
        description[i] = "! " .. row
    end

    return table.concat(description, "\n")
end


-- Generates a description of the groups for the hexagon
-- @param N is the order of the hexagon
-- @return A string describing the groups in the hexagon
function describe_groups(N, hrz, llr, ulr)
    if not hrz then
        assert(llr==nil and ulr==nil, "All or none of the groups must be provided")
    end
    if not llr then
        assert(ulr==nil, "All or none of the groups must be provided")
        assert(hrz==nil, "All or none of the groups must be provided")
    end
    if not ulr then
        assert(hrz==nil, "All or none of the groups must be provided")
        assert(llr==nil, "All or none of the groups must be provided")
    end
    local hrz = hrz or generate_horizontal_groups(N)
    local llr_, ulr_ = generate_diagonal_groups(N)
    local llr = llr or llr_
    local ulr = ulr or ulr_
    local description = {}
    table.insert(description, string.format("! Groups for order N=%d;", N))
    table.insert(description, "!HRZ = Horizontal groups")
    for i, g in ipairs(hrz) do 
        --print("!HRZ" .. i, table.concat(g, ",")) 
        local line = string.format("!HRZ%02d: ", i)
        for j, cell in ipairs(g) do
            line = line .. string.format("%3d ", cell)
        end
        table.insert(description, line)
    end    
    table.insert(description,"!LLR = Lower Left to Right Diagonal")
    for i, g in ipairs(llr) do 
        --print("!LLR" .. i, table.concat(g, ",")) 
        local line = string.format("!LLR%02d: ", i)
        for j, cell in ipairs(g) do
            line = line .. string.format("%3d ", cell)
        end
        table.insert(description, line)
    end
    table.insert(description,"!ULR = Upper Left to Right Diagonal")
    for i, g in ipairs(ulr) do 
        --print("!ULR" .. i, table.concat(g, ",")) 
        local line = string.format("!ULR%02d: ", i)
        for j, cell in ipairs(g) do
            line = line .. string.format("%3d ", cell)
        end
        table.insert(description, line)
    end
    return table.concat(description, "\n")
end

-- Generate an assignment vector ASG for 60° clockwise rotation
-- Rotates the hexagon 60 degrees clockwise and reconstructs the padded matrix
local function rotate_hexagon_60(N)
    local M = 2 * N - 1

    -- Step 1: Get original diagonal and horizontal groups
    local hrz = generate_horizontal_groups(N)
    local llr, ulr = generate_diagonal_groups(N)

    -- Step 2: Compute new HRZ, LLR, ULR after rotation
    local new_llr, new_ulr, new_hrz = {}, {}, {}

    for i = 1, #hrz do
        new_llr[i] = {}
        for j = #hrz[i], 1, -1 do
            table.insert(new_llr[i], hrz[i][j])
        end
    end

    for i = 1, #llr do
        new_ulr[i] = {}
        for _, val in ipairs(llr[i]) do
            table.insert(new_ulr[i], val)
        end
    end

    for i = 1, #ulr do
        new_hrz[i] = {}
        for j = #ulr[i], 1, -1 do
            table.insert(new_hrz[i], ulr[i][j])
        end
    end

    -- Step 3: Build rotated matrix and ASG mapping
    local ASG = {}  -- ASG[new_id] = old_id
    local new_id = 1

    for r = 1, M do
        local row = new_hrz[r]
        local len = #row
        local offset = math.floor((M - len) / 2)
        for i = 1, len do
            local old_id = row[i]
            ASG[new_id] = old_id
            new_id = new_id + 1
        end
    end

    return new_hrz, new_llr, new_ulr, ASG
end

-- Applies an ASG (assignment) mapping to a given hex matrix
-- hex: padded matrix with original IDs
-- asg: table mapping old ID → new ID
-- returns: new hex matrix with reassigned IDs
local function apply_asg_to_hex(hex, asg)
    local M = #hex
    local new_hex = {}

    for r = 1, M do
        new_hex[r] = {}
        for c = 1, M do
            local val = hex[r][c]
            if val ~= 0 and asg[val] then
                new_hex[r][c] = asg[val]
            else
                new_hex[r][c] = 0
            end
        end
    end

    return new_hex
end

--- Extracts row groups from the hexagonal grid
-- @param hex is the hexagonal grid structure
function extract_row_groups(hex, N)
    local hrz, llr, ulr = {}, {}, {}
    -- string zeros
    local M = #hex
    local rows = {} -- zeroless rows
    for r = 1, M do
        local row = hex[r]
        local len = #row
        local new_row = {}
        for i = 1, len do
            if row[i] ~= 0 then
                table.insert(new_row, row[i])
            end
        end
        rows[r] = new_row
    end

    -- horizontal groups
    for r = 1, M do
        local row = rows[r]
        if #row > 0 then
            hrz[r] = {}
            for i = 1, #row do
                table.insert(hrz[r], row[i])
            end
        end
    end
    -- diagonal groups
    llr, ulr = generate_diagonal_groups(N, rows)

    return hrz, llr, ulr
end

-- Flip around horizontal axis (top-bottom)
local function flip_hrz(hex)
    local M = #hex
    local flipped = {}
    for r = 1, M do
        flipped[r] = {}
        for c = 1, M do
            flipped[r][c] = hex[M - r + 1][c]
        end
    end
    return flipped
end

-- Flip around LLR diagonal (bottom-left to top-right)
local function flip_llr(hex,asg)
    local flipped = apply_asg_to_hex(hex, asg)
    flipped = flip_hrz(flipped)
    return flipped
end

-- Flip around ULR diagonal (top-left to bottom-right)
local function flip_ulr(hex,asg)
    local flipped = apply_asg_to_hex(hex, asg)
    flipped = apply_asg_to_hex(flipped, asg)
    flipped = flip_hrz(flipped)
    return flipped
end

  
N = args.norder -- Get the order from command line arguments
BLK = args.block -- Get the block size from command line arguments
-- Generate the LINGO model for the magic hexagon problem
io.flush()
local model_text = generate_lingo_magic_hexagon(N)
print(model_text)

if args.debug > 0 then
    local desc_honeycomb_txt = describe_honeycomb(N)
    print(desc_honeycomb_txt .. "\n;")
    local desc_group_txt = describe_groups(N)
    print(desc_group_txt .. "\n;")
    io.flush()
end

if args.ssym > 0 then
    local flipper = {"|", "/", "-","\\", "|","-"}
    local hex = build_hex_grid(N)
    print("!Hex grid:")
    print_hex_grid(hex)
    local new_hrz, new_llr, new_ulr, asg = rotate_hexagon_60(N)
    for k=1,6 do
        hex = apply_asg_to_hex(hex, asg)
        print("! " .. string.rep(flipper[k], 20) .. ";")
        print("!Rotated original hex grid " .. k * 60 .. " degrees:")
        print_hex_grid(hex)        
        if args.debug> 1 then
            local hrz, llr, ulr = extract_row_groups(hex,N)
            local desc_group_txt = describe_groups(N,hrz, llr, ulr)
            print(desc_group_txt .. "\n;")
        end
    end
    io.flush()
    local flip_hrz = flip_hrz(hex)
    print("!Flipped across horizontal axis:")
    print_hex_grid(flip_hrz)
    if args.debug > 1 then
        local hrz, llr, ulr = extract_row_groups(flip_hrz,N)
        local desc_group_txt = describe_groups(N,hrz, llr, ulr)
        print(desc_group_txt .. "\n;")
    end
    io.flush()
    print("!Flipped across LLR diagonal:")
    local flip_llr = flip_llr(hex,asg)
    print_hex_grid(flip_llr)
    if args.debug > 1 then
        local hrz, llr, ulr = extract_row_groups(flip_llr,N)
        local desc_group_txt = describe_groups(N,hrz, llr, ulr)
        print(desc_group_txt .. "\n;")
    end
    io.flush()
    print("!Flipped accros ULR diagonal:")
    local flip_ulr = flip_ulr(hex,asg)
    print_hex_grid(flip_ulr)
    if args.debug > 1 then
        local hrz, llr, ulr = extract_row_groups(flip_ulr,N)
        local desc_group_txt = describe_groups(N,hrz, llr, ulr)
        print(desc_group_txt .. "\n;")
    end
    io.flush()
    print("!Symmetry breaking constraints:")
    print("! - Break N deg rotational symmetry, N=60, 120, 180, 240, 300")
    print("! - Break horizontal symmetry")
    print("! - Break LLR diagonal symmetry")
    print("! - Break ULR diagonal symmetry")
    print(";");
    print("!\t@FOR(cell(i):")
    print("!\t\t@FOR(cell(j) | i,j share the same position in any symmetric hexagon:")
    print("!\t\t\tvalasg(i) <> valasg(j) for all symmetry groups..")
    print("!\t\t);")
end

