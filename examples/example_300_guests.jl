using RoomJuggler

rjj = RoomJugglerJob("job_300_guests.xlsx")
juggle!(rjj)
export_results("results", rjj)
