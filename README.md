<img src="docs/src/assets/logo.png" width="360" />

# RoomJuggler
|**Documentation**| **Build Status**|
|---|---|
| [![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://kfrb.github.io/RoomJuggler.jl/stable/) [![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://kfrb.github.io/RoomJuggler.jl/dev/) | [![Build Status](https://github.com/kfrb/RoomJuggler.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/kfrb/RoomJuggler.jl/actions/workflows/CI.yml?query=branch%3Amain) [![Coverage](https://codecov.io/gh/kfrb/RoomJuggler.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/kfrb/RoomJuggler.jl) |

A non-registered Julia package to solve a room occupancy problem with simulated annealing

## The room occupancy problem
Guests need to be assigned to gender-segregated rooms. The guests can make wishes with whom they share the same room.
`RoomJuggler.jl` optimizes the room occupancy and maximizes each guest's happiness to meet all their wishes.

## Installation
To install, use [Julia's built-in package manager](https://docs.julialang.org/en/v1/stdlib/Pkg/). Open the Julia REPL and type `]` to enter the package mode and install `RoomJuggler.jl` as follows:
```shell
pkg> add https://github.com/kfrb/RoomJuggler.jl
```

## Quick Start
First you need to specify the data. The data is stored in an Excel file with the `.xlsx` format. This Excel document must meet the following criteria:
* It has to contain one excel-sheet with the name `guests`. This sheet has to contain one column with the header `name` and one with `gender`, e.g.: 
    | name | gender |
    |---|---|
    | Martha Chung | F |
    | John Kinder | M |
    | Cami Horton | F |
    | $\vdots$ | $\vdots$ |
* It has to contain one excel-sheet with the name `rooms`. This sheet has to contain one column with the header `name`, one with `capacity`, and one with `gender`, e.g.: 
    | name | capacity | gender |
    |---|---|---|
    | room 1 | 3 | F |
    | room 2 | 4 | F |
    | room 3 | 2 | M |
    | $\vdots$ | $\vdots$ | $\vdots$ |
* It has to contain one excel-sheet with the name `wishes`. This sheet cannot have headings and has to include the wishes, one line per wish. The first column should be a wish specifier, e.g., an e-mail address. The guests that want to be in the same room are following each in its column, e.g.:
    | | | | |
    |---|---|---|---|
    | mark.white@test.com | Mark White      | John Kinder | |
    | co123@web.com       | Catherine Owens | Cami Horton | Barbara Brown |
    | $\vdots$ | | | |

To use `RoomJuggler.jl`, you need just four lines of code:
```julia
using RoomJuggler

# Read the Excel-file and create a `RoomJugglerJob`
rjj = RoomJugglerJob("data.xlsx")

# Optimize room occupancy in terms of the guest's happiness
juggle!(rjj)

# Export the results to a new Excel-file
report("report.xlsx", rjj)
```

