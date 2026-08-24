#!/usr/bin/env lslua
-- Generate a random Quadratic Assignment Problem (QAP) instance in LINGO format.
--
-- The story and the model shape follow prob/gen/qap_ohare.lng (assign planes
-- to gates so that transfer passengers walk as little as possible): same set
-- names, same variable names, same objective convention, so anything written
-- for that model reads these instances unchanged.
--
--   MIN = SUM over (I,J) with F(I,J) > 0 of F(I,J) * D(gate of I, gate of J)
--
-- F is generated upper-triangular by default, so each unordered pair of planes
-- is counted once (use --asym to draw both directions independently).

local lapp = require 'pl.lapp'  -- Penlight's lapp module for CLI parsing
local math = require 'math'

-- Command-line argument parsing with lapp
local args = lapp [[
Generate a random Quadratic Assignment Problem (planes to gates) in LINGO format.
  -n,--nplanes    (default 8)       Number of planes (facilities), N >= 2
  -m,--ngates     (default 0)       Number of gates (locations); 0 = same as N, else M >= N
  -d,--density    (default 0.75)    Fraction of plane pairs with nonzero transfer flow (0 < d <= 1)
  -f,--fmin       (default 1)       Minimum nonzero flow (integer >= 1)
  -F,--fmax       (default 40)      Maximum nonzero flow (integer >= fmin)
  -t,--dist       (default uniform) Gate distance model: uniform | euclid
  -l,--dmin       (default 10)      uniform: minimum distance between distinct gates (integer >= 1)
  -u,--dmax       (default 150)     uniform: maximum distance between distinct gates (integer >= dmin)
  -g,--grid       (default 150)     euclid: gates get distinct integer coordinates in [0,grid]^2
  -a,--asym                         Asymmetric flows: draw F(I,J) and F(J,I) independently
  -x,--fixid                        Debug: fix the identity assignment (plane I at gate I) in the model
  -s,--seed       (default 0)       Random seed (0 = use current time)
  -o,--output     (default "./prob/gen/qap.lng")  Output LINGO file name
  -v,--verbose                      Print the generated matrices
]]
-- NOTE: boolean flags must be written WITHOUT "(default false)".  Penlight's lapp
-- only recognizes the literal "true" as a boolean default; "false" comes back as
-- the string "false", which is truthy in Lua and makes the flag swallow the next
-- argument (e.g. "-x -o file" would eat "-o").

-- Validate inputs
local N = math.floor(args.nplanes)
local M = (args.ngates == 0) and N or math.floor(args.ngates)
if N < 2 then lapp.error("nplanes must be at least 2") end
if M < N then lapp.error("ngates must be 0 (= nplanes) or at least nplanes") end
if args.density <= 0 or args.density > 1 then lapp.error("density must be in (0, 1]") end
local FMIN, FMAX = math.floor(args.fmin), math.floor(args.fmax)
if FMIN < 1 then lapp.error("fmin must be at least 1") end
if FMAX < FMIN then lapp.error("fmax must be >= fmin") end
if args.dist ~= "uniform" and args.dist ~= "euclid" then lapp.error("dist must be 'uniform' or 'euclid'") end
local DMIN, DMAX = math.floor(args.dmin), math.floor(args.dmax)
if DMIN < 1 then lapp.error("dmin must be at least 1") end
if DMAX < DMIN then lapp.error("dmax must be >= dmin") end
local GRID = math.floor(args.grid)
if args.dist == "euclid" and (GRID + 1) * (GRID + 1) < M then
    lapp.error("grid too small to place " .. M .. " gates at distinct points; need (grid+1)^2 >= ngates")
end

-- Initialize random seed
local SEED = args.seed
if SEED == 0 then
    SEED = os.time()
    if args.verbose then print("Using random seed based on current time: " .. SEED) end
else
    if args.verbose then print("Using specified seed: " .. SEED) end
end
math.randomseed(SEED)

-- Generate the gate distance matrix D (M x M, symmetric, zero diagonal)
-- @return D as D[k][l], plus the coordinates table (euclid only, else nil)
local function generate_distances()
    local D = {}
    for k = 1, M do
        D[k] = {}
        for l = 1, M do D[k][l] = 0 end
    end
    local coords = nil
    if args.dist == "uniform" then
        -- Taillard "a"-style: independent uniform integers on the upper triangle
        for k = 1, M - 1 do
            for l = k + 1, M do
                local d = math.random(DMIN, DMAX)
                D[k][l], D[l][k] = d, d
            end
        end
    else
        -- Metric instance: gates at distinct integer points, rounded Euclidean distances
        coords = {}
        local used = {}
        for k = 1, M do
            local x, y, key
            repeat
                x, y = math.random(0, GRID), math.random(0, GRID)
                key = x * (GRID + 1) + y
            until not used[key]
            used[key] = true
            coords[k] = { x = x, y = y }
        end
        for k = 1, M - 1 do
            for l = k + 1, M do
                local dx, dy = coords[k].x - coords[l].x, coords[k].y - coords[l].y
                local d = math.floor(math.sqrt(dx * dx + dy * dy) + 0.5)
                if d < 1 then d = 1 end  -- distinct points, but rounding could still give 0
                D[k][l], D[l][k] = d, d
            end
        end
    end
    return D, coords
end

-- Generate the plane transfer-flow matrix F (N x N, zero diagonal)
-- Upper triangular unless --asym, in which case every ordered pair is drawn independently.
-- @return F as F[i][j], the number of nonzero entries, and the number of candidate pairs
local function generate_flows()
    local F = {}
    for i = 1, N do
        F[i] = {}
        for j = 1, N do F[i][j] = 0 end
    end
    local nz, npairs = 0, 0
    for i = 1, N do
        for j = 1, N do
            if i ~= j and (args.asym or i < j) then
                npairs = npairs + 1
                if math.random() < args.density then
                    F[i][j] = math.random(FMIN, FMAX)
                    nz = nz + 1
                end
            end
        end
    end
    if nz == 0 then
        -- Guarantee at least one bilinear term so the objective is not empty
        local i = math.random(1, N - 1)
        local j = math.random(i + 1, N)
        F[i][j] = math.random(FMIN, FMAX)
        nz = 1
    end
    return F, nz, npairs
end

-- Objective value of an assignment given as gate_of[i] = gate index of plane i
local function evaluate(F, D, gate_of)
    local obj = 0
    for i = 1, N do
        for j = 1, N do
            if F[i][j] > 0 then
                obj = obj + F[i][j] * D[gate_of[i]][gate_of[j]]
            end
        end
    end
    return obj
end

-- Write one matrix row as LINGO data, wrapping at cols_per_line numbers per physical line.
-- The row comment (if any) goes at the end of the row's last line; `last` closes the data item.
local function write_row(f, row, ncols, indent, cols_per_line, comment, last)
    local line = ""
    for c = 1, ncols do
        line = line .. string.format("%4d", row[c])
        if c % cols_per_line == 0 and c < ncols then
            f:write(indent .. line .. "\n")
            line = ""
        end
    end
    local tail = last and ";" or " "
    if comment then tail = tail .. "   ! " .. comment .. ";" end
    f:write(indent .. line .. tail .. "\n")
end

local function print_matrix(name, A, nrows, ncols)
    print(name .. ":")
    for r = 1, nrows do
        local parts = {}
        for c = 1, ncols do parts[c] = string.format("%4d", A[r][c]) end
        print("  " .. table.concat(parts, " "))
    end
end

-- Generate the instance
local D, coords = generate_distances()
local F, nz_flows, npairs = generate_flows()
local nz_dist = M * (M - 1)  -- off-diagonal distance entries (all positive by construction)
local identity = {}
for i = 1, N do identity[i] = i end
local obj_identity = evaluate(F, D, identity)

-- Write the LINGO model
local f = io.open(args.output, "w")
if not f then
    error("Could not open file " .. args.output .. " for writing")
end

f:write("MODEL:\n")
f:write("! Random Quadratic Assignment Problem (planes to gates) generated by lsgen_lingo_qap.lua\n")
f:write("(https://github.com/lindosystems/lindoapi-lua)\n")
f:write(string.format("  Parameters: nplanes=%d ngates=%d density=%g fmin=%d fmax=%d dist=%s", N, M, args.density, FMIN, FMAX, args.dist))
if args.dist == "uniform" then
    f:write(string.format(" dmin=%d dmax=%d", DMIN, DMAX))
else
    f:write(string.format(" grid=%d", GRID))
end
f:write(string.format(" asym=%s seed=%d\n", tostring(args.asym), SEED))
f:write(string.format("  Nonzero flows: %d of %d plane pairs, bilinear terms in objective: %d x %d = %d\n",
    nz_flows, npairs, nz_flows, nz_dist, nz_flows * nz_dist))
f:write(string.format("  Reference: the identity assignment (plane I at gate I) has objective %d", obj_identity))
if args.fixid then
    f:write("\n  DEBUG BUILD: the identity assignment is fixed below, so LINGO must report exactly that value")
end
f:write(";\n\n")

f:write("SETS:\n")
f:write(string.format("    PLANE /P1..P%d/: ;\n", N))
f:write(string.format("    GATE  /G1..G%d/: ;\n", M))
f:write("    PXP(PLANE, PLANE): F;    ! F(I,J) = transfer volume plane I -> plane J;\n")
f:write("    GXG(GATE, GATE):   D;    ! D(K,L) = walking distance gate K <-> gate L;\n")
f:write("    PXG(PLANE, GATE):  X;    ! X(I,K) = 1 if plane I is parked at gate K;\n")
f:write("ENDSETS\n\n")

local COLS_PER_LINE = 20
f:write("DATA:\n")
if coords then
    f:write("    ! Gate coordinates used to build D (rounded Euclidean distances);\n")
    for k = 1, M do
        f:write(string.format("    ! G%d = (%d, %d);\n", k, coords[k].x, coords[k].y))
    end
end
f:write(string.format("    ! Distance between gates (symmetric), one row per gate G1..G%d;\n", M))
f:write("    D =\n")
for k = 1, M do
    write_row(f, D[k], M, "        ", COLS_PER_LINE, "G" .. k, k == M)
end
f:write("\n")
f:write(string.format("    ! Transfer volume between planes (%s), one row per plane P1..P%d;\n",
    args.asym and "asymmetric" or "upper triangular", N))
f:write("    F =\n")
for i = 1, N do
    write_row(f, F[i], N, "        ", COLS_PER_LINE, "P" .. i, i == N)
end
f:write("ENDDATA\n\n")

f:write("! Objective: minimize total transfer walking distance.\n")
f:write("  For every pair of planes with transfer traffic, the distance walked\n")
f:write("  is the distance between the two gates they are assigned to, which is\n")
f:write("  picked out by the product X(I,K) * X(J,L);\n")
f:write("[OBJ] MIN = @SUM(PXP(I, J) | F(I, J) #GT# 0:\n")
f:write("                F(I, J) * @SUM(GXG(K, L): D(K, L) * X(I, K) * X(J, L)));\n\n")

f:write("! Each plane is assigned to exactly one gate;\n")
f:write("@FOR(PLANE(I): [RP]\n")
f:write("    @SUM(GATE(K): X(I, K)) = 1);\n\n")

if M == N then
    f:write("! Each gate receives exactly one plane;\n")
    f:write("@FOR(GATE(K): [RG]\n")
    f:write("    @SUM(PLANE(I): X(I, K)) = 1);\n\n")
else
    f:write("! Each gate receives at most one plane (more gates than planes);\n")
    f:write("@FOR(GATE(K): [RG]\n")
    f:write("    @SUM(PLANE(I): X(I, K)) <= 1);\n\n")
end

f:write("! Assignment variables are binary;\n")
f:write("@FOR(PXG(I, K): @BIN(X(I, K)));\n")

if args.fixid then
    f:write("\n! DEBUG: fix the identity assignment (plane I at gate I);\n")
    f:write("@FOR(PXG(I, K) | I #EQ# K: [FIX] X(I, K) = 1);\n")
end

f:write("END\n")
f:close()

-- Console output for confirmation
print("Generated LINGO file: " .. args.output)
print(string.format("Planes: %d  Gates: %d  Distance model: %s  Seed: %d", N, M, args.dist, SEED))
print(string.format("Nonzero flows: %d of %d pairs (density %g, range %d..%d)", nz_flows, npairs, args.density, FMIN, FMAX))
print(string.format("Bilinear objective terms: %d x %d = %d", nz_flows, nz_dist, nz_flows * nz_dist))
print(string.format("Identity assignment objective: %d%s", obj_identity, args.fixid and "  (fixed in model)" or ""))
if args.verbose then
    print_matrix("D (gate distances)", D, M, M)
    print_matrix("F (plane transfer flows)", F, N, N)
end
