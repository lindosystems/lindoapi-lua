#!/usr/bin/env lua

local lapp = require 'pl.lapp'  -- Penlight's lapp module for CLI parsing
local math = require 'math'

-- Command-line argument parsing with lapp
local args = lapp [[
Generate a QUBO model in LINGO format with random c and Q.
  -n,--nvars      (default 4)     Number of variables
  -d,--density    (default 0.5)   Density of Q matrix (0 to 1)
  -m,--method     (default 2)     Q generation method (1: shuffle, 2: probabilistic)
  -o,--output     (default "qubo.lng")  Output LINGO file name
]]

-- Validate inputs
if args.nvars < 1 then lapp.error("nvars must be at least 1") end
if args.density < 0 or args.density > 1 then lapp.error("density must be between 0 and 1") end
if args.method ~= 1 and args.method ~= 2 then lapp.error("method must be 1 or 2") end

-- Seed random number generator for reproducibility
math.randomseed(os.time())

-- Function to shuffle a table (Fisher-Yates shuffle)
local function shuffle(tbl)
    for i = #tbl, 2, -1 do
        local j = math.random(1, i)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
    return tbl
end

-- Function to write a table with 20 elements per row
local function write_with_cols(f, tbl, start, finish, indent, comment)
    local cols_per_row = 20
    for i = start, finish do
        f:write(string.format("%.2f", tbl[i]))
        if i < finish then f:write(", ") end
        if (i - start + 1) % cols_per_row == 0 and i < finish then
            f:write("\n" .. indent)
        end
    end
    if comment then
        f:write("  ! " .. comment .. ";\n")
    else
        f:write(";\n")
    end
end

-- Function to generate Q matrix
local function generate_q_matrix(nvars, density, method)
    local q = {}
    for i = 1, nvars * nvars do q[i] = 0.0 end  -- Initialize Q as all zeros
    local nz = 0
    if method == 1 then
        -- Method 1: Shuffle-Based Selection (considering upper and lower triangles, non-symmetric)
        local num_pairs = nvars * (nvars - 1)  -- Total off-diagonal pairs (i ~= j)
        local non_zero_count = math.floor(num_pairs * density)
        
        -- Generate all off-diagonal pairs (i ~= j)
        local pairs = {}
        for i = 1, nvars do
            for j = 1, nvars do
                if i ~= j then
                    table.insert(pairs, {i = i, j = j})
                end
            end
        end
        
        -- Shuffle and select non-zero positions
        shuffle(pairs)
        for k = 1, math.min(non_zero_count, #pairs) do
            local pair = pairs[k]
            local pos = (pair.i - 1) * nvars + pair.j
            q[pos] = math.random() * 4 - 2  -- Random float between -2 and 2
            q[pos] = tonumber(string.format("%.2f", q[pos]))
            nz = nz + 1
        end
    elseif method == 2 then
        -- Method 2: Probabilistic Assignment
        --density = density / 2
        for i = 1, nvars - 1 do
            for j = i + 1, nvars do
                if math.random() < density then
                    local pos = (i - 1) * nvars + j
                    q[pos] = math.random() * 4 - 2  -- Random float between -2 and 2
                    q[pos] = tonumber(string.format("%.2f", q[pos]))
                    nz = nz + 1
                end
                if math.random() < density then
                    local pos = (j - 1) * nvars + i
                    q[pos] = math.random() * 4 - 2  -- Random float between -2 and 2
                    q[pos] = tonumber(string.format("%.2f", q[pos]))
                    nz = nz + 1
                end                
            end
        end
    end
    
    return q, nz
end

-- Function to generate the QUBO model
local function generate_qubo_model(nvars, density, method, output_file)
    local f = io.open(output_file, "w")
    if not f then
        error("Could not open file " .. output_file .. " for writing")
    end

    f:write("MODEL:\n")
    f:write("! QUBO Model with Randomly Generated Q and c;\n\n")

    f:write("! Define sets;\n")
    f:write("SETS:\n")
    local vars = {}
    for i = 1, nvars do vars[i] = tostring(i) end
    f:write("    VARS / " .. table.concat(vars, ", ") .. " /: X, C;\n")
    f:write("    PAIRS(VARS, VARS): Q;\n")
    f:write("ENDSETS\n\n")

    f:write("! Objective: Minimize linear + quadratic terms (sum Q only for i < j);\n")
    f:write("MIN = @SUM(VARS(I): C(I) * X(I)) + \n")
    f:write("      @SUM(PAIRS(I,J):  Q(I,J) * X(I) * X(J));\n\n")

    f:write("! Binary constraint;\n")
    f:write("@FOR(VARS(I): @BIN(X(I)));\n\n")

    f:write("! Data section with randomly generated values;\n")
    f:write("DATA:\n")
    
    -- Generate and write C
    local c = {}
    for i = 1, nvars do
        c[i] = math.random() * 10 - 5
        c[i] = tonumber(string.format("%.2f", c[i]))
    end
    f:write("    ! Linear coefficients (c_i), random between -5 and 5;\n")
    f:write("    C = ")
    write_with_cols(f, c, 1, nvars, "        ")
    
    -- Generate and write Q
    local q, nz = generate_q_matrix(nvars, density, method)
    local method_desc = (method == 1) and "shuffle-based" or "probabilistic"
    f:write("    ! Quadratic coefficients (Q_ij), random between -2 and 2, density " .. density .. ", method " .. method_desc .. ", nz = " .. nz .. ";\n")
    f:write("    Q = ")
    for i = 1, nvars do
        local start = (i-1) * nvars + 1
        local finish = i * nvars
        if i > 1 then f:write("        ") end
        if i < nvars then
            write_with_cols(f, q, start, finish, "        ", "Row " .. i)
        else
            write_with_cols(f, q, start, finish, "        ")
        end
        
    end
    
    f:write("ENDDATA\n\n")
    f:write("END\n")

    f:close()
    print("Generated QUBO model in " .. output_file .. " with " .. nvars .. " variables, Q density " .. density .. ", method " .. method, "nz = " .. nz, "density = " .. density, "(d= " .. nz/(nvars*nvars) .. ")")
end

-- Execute with command-line args
generate_qubo_model(args.nvars, args.density, args.method, args.output)