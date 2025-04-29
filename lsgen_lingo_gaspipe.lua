#!/usr/bin/env lslua

local lapp = require 'pl.lapp'  -- Penlight's lapp module for CLI parsing
local math = require 'math'

-- Command-line argument parsing with lapp
local args = lapp [[
Generate a LINGO model for gas pipeline optimization with quadratic costs.
  -s,--nsupply    (default 2)     Number of supply nodes
  -d,--ndemand    (default 3)     Number of demand nodes
  -o,--output     (default "./prog/gen/gas_opt.lng")  Output LINGO file name
]]

-- Seed random number generator for reproducibility
math.randomseed(os.time())

-- Function to generate the LINGO model
local function generate_lingo_model(nsupply, ndemand, output_file)
    -- Open file for writing
    local f = io.open(output_file, "w")
    if not f then
        error("Could not open file " .. output_file .. " for writing")
    end

    -- Write model header
    f:write("MODEL:\n")
    f:write("! Gas Pipeline Grid Optimization with Quadratic Costs;\n\n")

    -- Define sets
    f:write("! Define sets;\n")
    f:write("SETS:\n")
    -- Supply nodes (S1, S2, ..., Sn)
    local supply_nodes = {}
    for i = 1, nsupply do
        supply_nodes[i] = "S" .. i
    end
    f:write("    SUPPLY / " .. table.concat(supply_nodes, ", ") .. " /: S;\n")
    -- Demand nodes (D1, D2, ..., Dn)
    local demand_nodes = {}
    for i = 1, ndemand do
        demand_nodes[i] = "D" .. i
    end
    f:write("    DEMAND / " .. table.concat(demand_nodes, ", ") .. " /: D;\n")
    f:write("    LINKS(SUPPLY, DEMAND): COST, X;\n")
    f:write("    QUAD(SUPPLY, DEMAND, SUPPLY, DEMAND): Q;\n")
    f:write("ENDSETS\n\n")

    -- Objective function
    f:write("! Objective: Minimize linear + quadratic costs;\n")
    f:write("MIN = @SUM(LINKS(I,J): COST(I,J) * X(I,J)) + \n")
    f:write("      @SUM(QUAD(I,J,K,L): Q(I,J,K,L) * X(I,J) * X(K,L));\n\n")

    -- Constraints
    f:write("! Constraints;\n")
    f:write("! Supply constraint;\n")
    f:write("@FOR(SUPPLY(I): \n")
    f:write("    @SUM(DEMAND(J): X(I,J)) <= S(I)\n")
    f:write(");\n\n")
    f:write("! Demand constraint;\n")
    f:write("@FOR(DEMAND(J): \n")
    f:write("    @SUM(SUPPLY(I): X(I,J)) = D(J)\n")
    f:write(");\n\n")
    f:write("! Non-negativity;\n")
    f:write("@FOR(LINKS(I,J): X(I,J) >= 0);\n\n")

    -- Data section
    f:write("! Data section;\n")
    f:write("DATA:\n")
    
    -- Generate random supply data (30-60 range)
    local supply = {}
    for i = 1, nsupply do
        supply[i] = math.random(30, 60)
    end
    f:write("    ! Supply data;\n")
    f:write("    S = " .. table.concat(supply, ", ") .. ";\n\n")
    
    -- Generate random demand data (20-40 range), scaled to match total supply
    local demand = {}
    local total_supply = 0
    for i = 1, #supply do total_supply = total_supply + supply[i] end
    local total_demand = 0
    for i = 1, ndemand - 1 do
        demand[i] = math.random(20, 40)
        total_demand = total_demand + demand[i]
    end
    -- Last demand node balances supply and demand
    demand[ndemand] = total_supply - total_demand
    if demand[ndemand] < 20 or demand[ndemand] > 40 then
        -- Adjust if out of range (simple scaling)
        local scale = total_supply / total_demand
        for i = 1, ndemand - 1 do demand[i] = math.floor(demand[i] * scale) end
        demand[ndemand] = total_supply - sum(demand, 1, ndemand - 1)
    end

    f:write("    ! Demand data;\n")
    f:write("    D = " .. table.concat(demand, ", ") .. ";\n\n")	
    
    -- Generate random linear cost data (1-5 range)
    local costs = {}
    for i = 1, nsupply do
        for j = 1, ndemand do
            costs[(i-1)*ndemand + j] = math.random(1, 5)
        end
    end
    f:write("    ! Linear cost data;\n")
    --f:write("    COST = " .. table.concat(costs, ", ") .. ";\n")
    f:write("    COST = \n")

    for i = 1, nsupply - 1 do
        f:write("           " .. table.concat(costs, ", ", i*ndemand + 1, (i+1)*ndemand) .. ",\n")
    end
    f:write("           " .. table.concat(costs, ", ", (nsupply-1)*ndemand + 1, nsupply*ndemand) .. ";\n\n")
    
    -- Generate random quadratic cost data (0-0.1 range, 36 entries for 2x3, scaled for larger sizes)
    local nlinks = nsupply * ndemand
    local quad = {}
    for i = 1, nlinks * nlinks do
        quad[i] = math.random() * 0.1  -- Random between 0 and 0.1
    end
    f:write("    ! Quadratic cost data (" .. nlinks * nlinks .. " entries);\n")
    f:write("    Q = ")
    for i = 1, nlinks do
        local start = (i-1) * nlinks + 1
        local finish = i * nlinks
        if i < nlinks then
            f:write(table.concat(quad, ", ", start, finish) .. ",\n        ")
        else
            f:write(table.concat(quad, ", ", start, finish) .. ";\n")
        end
    end
    
    -- End data and model
    f:write("ENDDATA\n\n")
    f:write("END\n")

    -- Close file
    f:close()
    print("Generated LINGO model in " .. output_file)
end

-- Helper function to sum a table from start to finish
function sum(tbl, start, finish)
    local s = 0
    for i = start, finish do s = s + tbl[i] end
    return s
end

-- Execute with command-line args
generate_lingo_model(args.nsupply, args.ndemand, args.output)