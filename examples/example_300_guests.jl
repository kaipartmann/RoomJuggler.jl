using RoomJuggler

rjj = RoomJugglerJob("job_300_guests.xlsx")
juggle!(rjj)
report("report_job_300_guests.xlsx", rjj)
