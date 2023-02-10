# Step-by-step Tutorial

This step-by-step tutorial supports possible users of this package with little or no programming experience in Julia.

## Installation of Julia

### Windows
Download & install Julia from the Windows Store: [apps.microsoft.com/store/detail/julia](https://apps.microsoft.com/store/detail/julia/9NJNWW8PVKMN?hl=de-de&gl=de&rtc=1)
This installs the Julia-installation manager `juliaup`.

#### How to check if the installation has worked?

Open the app *Windows PowerShell* and type the following commands. The output of the commands should be similar.

###### 1. Command: `juliaup`
```powershell
PS C:\Users\kfrb> juliaup
```
```powershell
The Julia Version Manager

Usage: juliaup <COMMAND>

Commands:
  default  Set the default Julia version
  add      Add a specific Julia version or channel to your system. Access via `julia +{channel}` i.e. `julia +1.6`
  link     Link an existing Julia binary to a custom channel name
  list     List all available channels
  update   Update all or a specific channel to the latest Julia version
  remove   Remove a Julia version from your system
  status   Show all installed Julia versions
  gc       Garbage collect uninstalled Julia versions
  config   Juliaup configuration
  self     Manage this juliaup installation
  help     Print this message or the help of the given subcommand(s)

Options:
  -h, --help     Print help information
  -V, --version  Print version information
```

###### 2. Command: `juliaup status`
```
PS C:\Users\kfrb> juliaup status
 Default  Channel  Version Update           Update
---------------------------------------------------
       *  release  1.8.5+0.x64.w64.mingw32  
```

!!! note "No release channel"
    If the output of `juliaup status` does not contain a `release` channel, you can add it manually by typing:
    ```
    juliaup add release
    ```

    If everything with the installation is correct, this should return an error:
    ```
    PS C:\Users\kfrb> juliaup add release
    Error: 'release' is already installed.
    ```


### MacOS & Linux
On MacOS and Linux you first have to open the app *Terminal*.
Type in the following command and follow the instructions to install the Julia-installation manager `juliaup`:
```
curl -fsSL https://install.julialang.org | sh
```

#### How to check if the installation has worked?
You can use the same commands as the Windows-users to check if the installation has succeded.

## Optional: Installation of VSCode
