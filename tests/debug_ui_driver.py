"""Exercise the native debugger through Neovim's terminal UI."""

import errno
import fcntl
import os
import pty
import re
import select
import signal
import struct
import subprocess
import sys
import termios
import time


master, slave = pty.openpty()
fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 55, 180, 0, 0))
command = (
    "lua local ok, err = pcall(dofile, 'tests/debug_workflow_runtime.lua'); "
    "if not ok then print(err); vim.cmd('cquit 1') end"
)
process = subprocess.Popen(
    ["nvim", "-u", "NONE", "-i", "NONE", "-c", "set nomore", "-c", command, "-c", "qa!"],
    stdin=slave, stdout=slave, stderr=slave, start_new_session=True,
    env=dict(os.environ, NVIM_LOG_FILE=f"/tmp/nvim-debug-ui-driver-{os.getpid()}.log"),
)
os.close(slave)
output = bytearray()
deadline = time.monotonic() + 120
try:
    while time.monotonic() < deadline:
        if select.select([master], [], [], 0.2)[0]:
            try:
                chunk = os.read(master, 65536)
            except OSError as error:
                if error.errno != errno.EIO:
                    raise
                break
            if not chunk:
                break
            output.extend(chunk)
        elif process.poll() is not None:
            break
    if process.poll() is None:
        process.wait(timeout=3)
except subprocess.TimeoutExpired:
    os.killpg(process.pid, signal.SIGTERM)
    process.wait(timeout=5)
finally:
    os.close(master)

text = re.sub(r"\x1b\[[0-?]*[ -/]*[@-~]", "", output.decode(errors="replace"))
seen = set()
for line in re.split(r"[\r\n]", text):
    line = line.strip()
    if any(line.startswith(token) for token in ("PASS gdb:", "PASS codelldb:", "PASS lldb-dap:", "PASS debug workspace", "Debugger runtime artifacts:", "DAP health report:")) and line not in seen:
        print(line)
        seen.add(line)
if process.returncode:
    print(text[-3000:], file=sys.stderr)
sys.exit(process.returncode or 0)
