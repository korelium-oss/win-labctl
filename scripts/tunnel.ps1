# LAB Persistent Tunnel

$PORT = 2207   # CHANGE PER PC

while ($true) {
    ssh -N `
      -o ServerAliveInterval=30 `
      -o ServerAliveCountMax=3 `
      -o ExitOnForwardFailure=yes `
      -R $PORT`:localhost:22 `
      kora@korelium

    Start-Sleep 10
}
