using RoomJuggler

# the files "guests300.csv", "wishes300.csv", "rooms300.csv"
# need to be in the same directory as the julia process is started!
rjj = RoomJugglerJob("guests300.csv", "wishes300.csv", "rooms300.csv")

# if this is not getting all wishes fulfilled, uncomment the line below
# to use custom settings for juggling
juggle!(rjj)
# juggle!(rjj; config=JuggleConfig(n_iter=400, beta=0.9999, t_0=1, t_min=1e-8))

# exports "guests.csv" and the "report.txt"
#   guests.csv -> all guests and their rooms
#   report.txt -> overview of all wishes and all rooms
export_results("results", rjj)
# if the directory "results" exist, use
# export_results("results", rjj; force=true)
# to overwrite the existing files
