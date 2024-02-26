#!/usr/bin/env lua
--
--  Ported functions from zhelpers.h
--
--  Author: Robert G. Jakabosky <bobby@sharedrealm.com>
--

local format = string.format
local random = math.random
local floor = math.floor
local write = io.write

local zmq = require"lzmq"

-- check for LuaJIT2's FFI module
local has_ffi, ffi = pcall(require, "ffi")

function printf(fmt, ...)
    local res = write(format(fmt, ...))
    io.stdout:flush() 
    return res
end

function fprintf(file, fmt, ...)
    return file:write(format(fmt, ...))
end

function sprintf(fmt, ...)
  return (string.format(fmt, ...))
end

--  Provide random whole number from 0..(num-1)
function randof(num)
    return floor(random(0, num-1))
end

--  Receive 0MQ string from socket and convert into C string
--  Caller must free returned string. Returns NULL if the context
--  is being terminated.
function s_recv(socket)
    return socket:recv()
end

--  Convert C string to 0MQ string and send to socket
function s_send(socket, msg)
    return socket:send(msg)
end

--  Sends string as 0MQ string, as multipart non-terminal
function s_sendmore(socket, msg)
    return socket:send(msg, zmq.SNDMORE)
end

--  Receives all message parts from socket, prints neatly
--
function s_dump(socket)
    print("----------------------------------------")
    while true do
        --  Process all parts of the message
        local data = socket:recv()

        --  Dump the message as text or binary
        local is_text = true
        for i=1,#data do
            local c = data:byte(i)
            if (c < 32 or c > 127) then
                is_text = false
                break
            end
        end

        printf("[%03d] ", #data)
        if is_text then
            write(data)
        else
            for i=1,#data do
                printf("%02X", data:byte(i))
            end
        end
        printf("\n")

        --  Multipart detection
        if (socket:getopt(zmq.RCVMORE) == 0) then
            break      --  Last message part
        end
    end
end

--  Set simple random printable identity on socket
--
function s_set_id(socket)
    local identity = format("%04X-%04X", randof (0x10000), randof (0x10000))
    return socket:setopt(zmq.IDENTITY, identity)
end


--  Report 0MQ version number
--
function s_version()
    local major, minor, patch = unpack(zmq.version())
    printf ("Current 0MQ version is %d.%d.%d\n", major, minor, patch)
end

--  Require at least some specified version
function s_version_assert(want_major, want_minor)
    local major, minor, patch = unpack(zmq.version())
    if (major < want_major or (major == want_major and minor < want_minor)) then
        printf ("Current 0MQ version is %d.%d\n", major, minor)
        printf ("Application needs at least %d.%d - cannot continue\n",
            want_major, want_minor)
        os.exit(-1)
    end
end

-- try to get Lua socket module
local has_socket, socket = pcall(require, "socket")

--  Sleep for a number of milliseconds
if has_socket then
    function s_sleep(msecs)
        socket.sleep(msecs / 1000)
    end
else
    function s_sleep(msecs)
        os.execute("sleep " .. tostring(msecs / 1000))
    end
end
if has_ffi then
    function install_ffi_sleep()
        if ffi.os == "Windows" then
            ffi.cdef[[ void Sleep(int msg); ]]
            function s_sleep(msecs) return ffi.C.Sleep(msecs) end
        else
            ffi.cdef[[ int poll(struct pollfd *fds, unsigned long nfds, int timeout); ]]
            function s_sleep(msecs) return ffi.C.poll(nil, 0, msecs) end
        end
    end
    pcall(install_ffi_sleep)
end

--  Return current system clock as milliseconds
if socket then
    function s_clock()
        return socket.gettime() * 1000
    end
else
    printf("------ WARNING: Please install LuaSocket for a better clock source.")
    function s_clock()
        return os.time() * 1000
    end
end

--  Print formatted string to stdout, prefixed by date/time and
--  terminated with a newline.

function s_console(fmt, ...)
    write(os.date("%y-%m-%d %H:%M:%S "))
    printf(fmt, ...)
    print()
end


--  ---------------------------------------------------------------------
--  Signal handling
--
--  Call s_catch_signals() in your application at startup, and then exit 
--  your main loop if s_interrupted is ever 1. Works especially well with 
--  zmq_poll.

s_interrupted = false

function s_catch_signals()
end

function getchar()
  io.read(1)
end

function s_dump_str(str)
  --  Dump the message as text or binary
  local function is_text(data)
    for i=1, #data do
      local c = data:byte(i)
      if (c < 32 or c > 127) then
        return false
      end
    end
    return true
  end

  local result = sprintf("[%03d] ", #str)

  if is_text(str) then
    result = result .. str
  else
    for i=1, #str do
      result = result .. sprintf("%02X", str:byte(i))
    end
  end

  return result
end

function s_dump_msg(msg)
  print("----------------------------------------")
  --  Process all parts of the message
  for _, data in ipairs(msg) do
    print(s_dump_str(data))
  end
end

function s_dump(socket)
  local msg = socket:recv_all()
  s_dump_msg(msg)
end

function s_unwrap(msg)
  local frame = table.remove(msg, 1)
  if msg[1] and (#msg[1]==0) then
    table.remove(msg, 1)
  end
  return frame
end

function s_wrap(msg, frame)
  table.insert(msg, 1, "")
  table.insert(msg, 1, frame)
  return msg
end

